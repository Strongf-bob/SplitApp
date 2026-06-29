import Foundation

protocol EventManagementServiceProtocol {
    func fetchHomeData() async throws -> EventsHomeData
    func fetchReceipts(eventId: UUID) async throws -> [ReceiptDTO]
    func fetchReceiptsPage(eventId: UUID, limit: Int, offset: Int) async throws -> PageResponse<ReceiptDTO>
    func createReceipt(eventId: UUID, request: CreateReceiptRequest) async throws -> ReceiptDTO
    func updateReceipt(id: UUID, request: UpdateReceiptRequest) async throws -> ReceiptDTO
    func deleteReceipt(id: UUID) async throws
    func getReceiptImagePresignedURL(id: UUID) async throws -> URL
    func createEvent(name: String) async throws -> Event
    func updateEvent(id: UUID, request: UpdateEventRequest) async throws -> Event
    func deleteEvent(id: UUID) async throws
}

struct EventManagementService: EventManagementServiceProtocol {
    private let eventsRepository: any EventsRepository
    private let receiptsRepository: ReceiptsDataRepository
    private let balancesRepository: any BalancesRepository

    init(
        eventsRepository: any EventsRepository = EventsDataRepository(),
        receiptsRepository: ReceiptsDataRepository = ReceiptsDataRepository(),
        balancesRepository: any BalancesRepository = BalancesDataRepository()
    ) {
        self.eventsRepository = eventsRepository
        self.receiptsRepository = receiptsRepository
        self.balancesRepository = balancesRepository
    }

    func fetchHomeData() async throws -> EventsHomeData {
        let events = try await eventsRepository.listEvents(userId: nil)

        let balanceSummary = await calculateBalanceSummary(for: events)

        return EventsHomeData(
            balanceSummary: balanceSummary,
            events: events
        )
    }

    private func calculateBalanceSummary(for events: [Event]) async -> EventBalanceSummary {
        guard let currentUserId = await CurrentUserStore.shared.user?.id else {
            return EventBalanceSummary(totalBalance: 0, owedToYou: 0, youOwe: 0)
        }
        var owedToYou: Double = 0
        var youOwe: Double = 0

        await withTaskGroup(of: [EventBalance].self) { group in
            for event in events {
                group.addTask {
                    await (try? balancesRepository.getEventBalances(eventId: event.id)) ?? []
                }
            }
            for await balances in group {
                for balance in balances {
                    if balance.creditorId == currentUserId {
                        owedToYou += balance.amount
                    } else if balance.debitorId == currentUserId {
                        youOwe += balance.amount
                    }
                }
            }
        }

        return EventBalanceSummary(
            totalBalance: owedToYou - youOwe,
            owedToYou: owedToYou,
            youOwe: youOwe
        )
    }

    func fetchReceipts(eventId: UUID) async throws -> [ReceiptDTO] {
        try await receiptsRepository.listReceipts(eventId: eventId)
    }

    func fetchReceiptsPage(eventId: UUID, limit: Int, offset: Int) async throws -> PageResponse<ReceiptDTO> {
        try await receiptsRepository.listReceiptsPage(eventId: eventId, limit: limit, offset: offset)
    }

    func createReceipt(eventId: UUID, request: CreateReceiptRequest) async throws -> ReceiptDTO {
        try await receiptsRepository.createReceipt(eventId: eventId, request)
    }

    func updateReceipt(id: UUID, request: UpdateReceiptRequest) async throws -> ReceiptDTO {
        try await receiptsRepository.updateReceipt(id: id, request)
    }

    func deleteReceipt(id: UUID) async throws {
        try await receiptsRepository.deleteReceipt(id: id)
    }

    func getReceiptImagePresignedURL(id: UUID) async throws -> URL {
        try await receiptsRepository.getReceiptImagePresignedURL(id: id)
    }

    func createEvent(name: String) async throws -> Event {
        let command = CreateEventCommand(name: name)
        return try await eventsRepository.createEvent(command)
    }

    func updateEvent(id: UUID, request: UpdateEventRequest) async throws -> Event {
        let command = UpdateEventCommand(isClosed: request.isClosed, name: request.name)
        return try await eventsRepository.updateEvent(id: id, command)
    }

    func deleteEvent(id: UUID) async throws {
        try await eventsRepository.deleteEvent(id: id)
    }
}
