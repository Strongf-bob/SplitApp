import CoreData
import Foundation

final class ReceiptsDataRepository: ReceiptsRepository {
    let apiClient: APIClient
    let coreDataStore: CoreDataStore

    init(apiClient: APIClient = .shared, coreDataStore: CoreDataStore = .shared) {
        self.apiClient = apiClient
        self.coreDataStore = coreDataStore
    }

    func createReceipt(eventId: UUID, _ request: CreateReceiptRequest) async throws -> ReceiptDTO {
        logOperation(
            operation: "create",
            mode: "start",
            context: "eventId=\(eventId)"
        )

        do {
            let dto: ReceiptDTO = try await apiClient.request(
                endpoint: CreateReceiptEndpoint(eventId: eventId),
                body: request
            )

            try await persistDTOToLocalStores(dto)

            logOperation(
                operation: "create",
                mode: "network_success",
                context: "eventId=\(eventId) receiptId=\(dto.id)"
            )
            logOperation(
                operation: "create",
                mode: "network_cache_upsert",
                context: "eventId=\(eventId) receiptId=\(dto.id)"
            )
            return dto
        } catch {
            guard isConnectivityFailure(error) else {
                throw error
            }

            let localDTO = makeLocalCreateReceiptDTO(
                eventId: eventId,
                request: request
            )

            do {
                try await persistDTOToLocalStores(localDTO)
                logOperation(
                    operation: "create",
                    mode: "local_fallback_success",
                    context: "eventId=\(eventId) receiptId=\(localDTO.id) networkError=\(error.localizedDescription)"
                )
                logOperation(
                    operation: "create",
                    mode: "local_only",
                    context: "eventId=\(eventId) receiptId=\(localDTO.id)"
                )
                return localDTO
            } catch {
                logOperation(
                    operation: "create",
                    mode: "network_failed_local_failed",
                    context: "eventId=\(eventId) error=\(error.localizedDescription)"
                )
                throw error
            }
        }
    }

    func listReceiptsPage(eventId: UUID, limit: Int = 50, offset: Int = 0) async throws -> PageResponse<ReceiptDTO> {
        logOperation(
            operation: "list",
            mode: "start",
            context: "eventId=\(eventId) limit=\(limit) offset=\(offset)"
        )

        do {
            let page: PageResponse<ReceiptDTO> = try await apiClient.request(
                endpoint: ListReceiptsEndpoint(eventId: eventId, limit: limit, offset: offset)
            )

            logOperation(
                operation: "list",
                mode: "network_success",
                context: "eventId=\(eventId) count=\(page.items.count) total=\(page.total)"
            )

            if page.items.isEmpty, offset == 0 {
                let localReceipts = LocalReceiptsStore.shared.getReceipts(for: eventId)
                if !localReceipts.isEmpty {
                    logOperation(
                        operation: "list",
                        mode: "local_fallback_success",
                        context: "eventId=\(eventId) count=\(localReceipts.count)"
                    )
                    return PageResponse(
                        items: localReceipts,
                        limit: limit,
                        offset: 0,
                        total: localReceipts.count
                    )
                }
            }

            try await coreDataStore.performBackground { [weak self] context in
                try self?.mergeReceiptsPage(page.items, in: context)
            }
            logOperation(
                operation: "list",
                mode: "network_cache_upsert",
                context: "eventId=\(eventId) count=\(page.items.count)"
            )
            return page
        } catch {
            let localReceipts = handleListReceiptsFallback(
                eventId: eventId,
                networkError: error
            )
            return PageResponse(
                items: offset == 0 ? localReceipts : [],
                limit: limit,
                offset: offset,
                total: offset == 0 ? localReceipts.count : offset
            )
        }
    }

    func listReceipts(eventId: UUID) async throws -> [ReceiptDTO] {
        try await fetchAllReceiptDTOs(eventId: eventId)
    }

    func updateReceipt(id: UUID, _ request: UpdateReceiptRequest) async throws -> ReceiptDTO {
        logOperation(
            operation: "update",
            mode: "start",
            context: "receiptId=\(id)"
        )

        do {
            let dto: ReceiptDTO = try await apiClient.request(endpoint: UpdateReceiptEndpoint(id: id), body: request)

            try await persistDTOToLocalStores(dto)

            logOperation(
                operation: "update",
                mode: "network_success",
                context: "receiptId=\(id)"
            )
            logOperation(
                operation: "update",
                mode: "network_cache_upsert",
                context: "receiptId=\(id)"
            )
            return dto
        } catch {
            guard isConnectivityFailure(error) else {
                throw error
            }

            return try await handleUpdateReceiptFallback(
                id: id,
                request: request,
                networkError: error
            )
        }
    }

    func createReceipt(eventId: UUID, _ command: CreateReceiptCommand) async throws -> ReceiptCreationOutcome {
        let request = CreateReceiptRequest(
            payerId: command.payerId,
            title: command.title,
            totalAmount: command.totalAmount,
            items: command.items.map(mapCreateReceiptItemCommand)
        )
        var dto: ReceiptDTO = try await apiClient.request(
            endpoint: CreateReceiptEndpoint(
                eventId: eventId,
                idempotencyKey: command.idempotencyKey
            ),
            body: request
        )

        await persistReceiptDTOWithoutBlockingUserFlow(dto)

        var imageUploadFailure: Error?
        if let receiptImageJPEGData = command.receiptImageJPEGData {
            do {
                let uploadResponse = try await uploadReceiptImageRequest(
                    receiptId: dto.id,
                    imageJPEGData: receiptImageJPEGData
                )
                dto = updateImageUrl(in: dto, imageUrl: uploadResponse.imageUrl)
                await persistReceiptDTOWithoutBlockingUserFlow(dto)
            } catch {
                imageUploadFailure = error
            }
        }

        return ReceiptCreationOutcome(
            receipt: mapToDomain(dto),
            imageUploadFailure: imageUploadFailure
        )
    }

    func getCachedReceipts(eventId: UUID) async throws -> [Receipt] {
        try await coreDataStore.performBackground { context in
            let fetchRequest: NSFetchRequest<CDReceipt> = CDReceipt.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "eventId == %@", eventId as CVarArg)
            fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \CDReceipt.createdAt, ascending: false)]
            let cdReceipts = try context.fetch(fetchRequest)
            return cdReceipts.map { self.mapToDomain($0) }
        }
    }

    func refreshReceipts(eventId: UUID) async throws -> [Receipt] {
        let dtos = try await fetchAllReceiptDTOs(eventId: eventId)
        try await coreDataStore.performBackground { [weak self] context in
            try self?.syncReceipts(dtos, eventId: eventId, in: context)
        }
        return try await getCachedReceipts(eventId: eventId)
    }

    func getCachedReceipt(id: UUID) async throws -> Receipt {
        try await coreDataStore.performBackground { context in
            let fetchRequest: NSFetchRequest<CDReceipt> = CDReceipt.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            fetchRequest.fetchLimit = 1
            guard let cdReceipt = try context.fetch(fetchRequest).first else {
                throw RepositoryError.notFound
            }
            return self.mapToDomain(cdReceipt)
        }
    }

    func getReceipt(id: UUID, eventId: UUID, policy: ReceiptFetchPolicy) async throws -> Receipt {
        switch policy {
        case .localOnly:
            return try await getCachedReceipt(id: id)
        case .refreshIfPossible:
            do {
                let receipts = try await refreshReceipts(eventId: eventId)
                if let receipt = receipts.first(where: { $0.id == id }) {
                    return receipt
                }
                throw RepositoryError.notFound
            } catch {
                do {
                    return try await getCachedReceipt(id: id)
                } catch {
                    throw RepositoryError.offlineNoCache
                }
            }
        }
    }

    func updateReceipt(id: UUID, _ command: UpdateReceiptCommand) async throws -> Receipt {
        let request = UpdateReceiptRequest(
            title: command.title,
            totalAmount: command.totalAmount,
            items: command.items?.map(mapCreateReceiptItemCommand)
        )
        let dto = try await updateReceipt(id: id, request)
        return mapToDomain(dto)
    }

    private func fetchAllReceiptDTOs(eventId: UUID, limit: Int = 50) async throws -> [ReceiptDTO] {
        var offset = 0
        var receipts: [ReceiptDTO] = []

        while true {
            let page = try await listReceiptsPage(eventId: eventId, limit: limit, offset: offset)
            receipts.append(contentsOf: page.items)

            guard page.hasMore, !page.items.isEmpty else {
                return receipts
            }
            offset = page.nextOffset
        }
    }
}
