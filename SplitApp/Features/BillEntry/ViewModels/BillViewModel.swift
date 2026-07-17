import Combine
import SwiftUI

@MainActor
final class BillViewModel: ObservableObject {
    enum Mode {
        case create(
            eventId: UUID?,
            scannedItems: [BillItem],
            receiptImageJPEGData: Data?
        )
        case edit(eventId: UUID, receiptId: UUID)

        var eventId: UUID? {
            switch self {
            case let .create(eventId, _, _):
                eventId
            case let .edit(eventId, _):
                eventId
            }
        }
    }

    @Published var items: [BillItem] = []
    @Published var participants: [Participant] = []
    @Published var isAddingItem = false
    @Published var selectedItemForAssignment: BillItem?
    @Published var receiptTitle = ""
    @Published var isLoading = false
    @Published var showParticipantPicker = false
    @Published var triggerAnimation = UUID()
    @Published private(set) var isSaving = false
    @Published var isUsingCachedData = false
    @Published private(set) var isNetworkAvailable: Bool
    @Published var loadErrorMessage: String?
    @Published var saveErrorMessage: String?
    @Published private(set) var saveNoticeMessage: String?

    let mode: Mode
    let eventsRepository: any EventsRepository
    let receiptsRepository: any ReceiptsRepository
    let usersRepository: any UsersRepository
    private let networkMonitor: NetworkMonitor
    let createReceiptIdempotencyKey = UUID().uuidString

    private var cancellables: Set<AnyCancellable> = []
    private var hasLoaded = false
    private var pendingImageUpload: (receiptId: UUID, imageJPEGData: Data)?

    var loadedEvent: Event?
    var loadedReceipt: Receipt?
    var payerId: UUID?
    var receiptImageJPEGData: Data?

    var total: Decimal {
        items.reduce(0) { $0 + $1.amount }
    }

    var isReadOnly: Bool {
        loadedEvent?.isClosed == true
    }

    var title: String {
        switch mode {
        case .create:
            "Добавление платежа"
        case .edit:
            "Просмотр чека"
        }
    }

    var statusMessage: String? {
        if let saveErrorMessage {
            return saveErrorMessage
        }
        if let loadErrorMessage, !items.isEmpty {
            return loadErrorMessage
        }
        if let saveDisabledReason {
            return saveDisabledReason
        }
        if isReadOnly {
            return "Событие закрыто. Чек доступен только для просмотра."
        }
        if isUsingCachedData {
            return "Показываем сохранённый чек. Для сохранения изменений нужен интернет."
        }
        return nil
    }

    var canSave: Bool {
        !isLoading
            && !isSaving
            && pendingImageUpload == nil
            && saveDisabledReason == nil
            && Self.hasValidContent(title: receiptTitle, items: items)
    }

    var saveButtonTitle: String {
        isSaving ? "Сохраняем..." : "Создать платёж"
    }

    var canRetryReceiptImageUpload: Bool {
        pendingImageUpload != nil && !isSaving
    }

    private var saveDisabledReason: String? {
        switch mode {
        case let .create(eventId, _, _) where eventId == nil:
            return "Сохранение доступно только внутри события."
        default:
            break
        }

        if !isNetworkAvailable {
            return "Без интернета сохранение пока недоступно."
        }

        if isReadOnly {
            return "Событие закрыто. Изменения недоступны."
        }

        return nil
    }

    init(
        mode: Mode,
        eventsRepository: any EventsRepository,
        receiptsRepository: any ReceiptsRepository,
        usersRepository: any UsersRepository,
        networkMonitor: NetworkMonitor
    ) {
        self.mode = mode
        self.eventsRepository = eventsRepository
        self.receiptsRepository = receiptsRepository
        self.usersRepository = usersRepository
        self.networkMonitor = networkMonitor
        isNetworkAvailable = networkMonitor.isConnected

        if case let .create(_, scannedItems, receiptImageJPEGData) = mode {
            items = scannedItems
            self.receiptImageJPEGData = receiptImageJPEGData
        }

        networkMonitor.$isConnected
            .receive(on: RunLoop.main)
            .sink { [weak self] isConnected in
                self?.isNetworkAvailable = isConnected
            }
            .store(in: &cancellables)
    }

    static func hasValidContent(title: String, items: [BillItem]) -> Bool {
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return false }
        guard !items.isEmpty else { return false }
        return items.allSatisfy {
            !$0.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                && $0.amount > 0
                && !$0.assignedTo.isEmpty
        }
    }

    func replaceScannedItems(_ scannedItems: [BillItem], imageData: Data?, assignedTo participants: [Participant]) {
        guard !isReadOnly else { return }
        items = scannedItems.map { item in
            var updated = item
            if updated.assignedTo.isEmpty {
                updated.assignedTo = participants
            }
            return updated
        }
        receiptImageJPEGData = imageData
    }

    func assignParticipantsToAllItems(_ selectedParticipants: [Participant]) {
        guard !isReadOnly else { return }
        for index in items.indices {
            items[index].assignedTo = selectedParticipants
        }
    }

    func load() async {
        guard !hasLoaded else { return }
        hasLoaded = true
        await reload()
    }

    func reload() async {
        loadErrorMessage = nil
        saveErrorMessage = nil

        switch mode {
        case let .create(eventId, scannedItems, receiptImageJPEGData):
            await loadCreateContext(
                eventId: eventId,
                scannedItems: scannedItems,
                receiptImageJPEGData: receiptImageJPEGData
            )
        case let .edit(eventId, receiptId):
            await loadEditContext(eventId: eventId, receiptId: receiptId)
        }
    }

    func addItem() {
        guard !isReadOnly else { return }
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            let newItem = BillItem(name: "", amount: 0, isEditing: true)
            items.append(newItem)
            isAddingItem = true
            triggerAnimation = UUID()
        }

        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }

    func removeItem(id: UUID) {
        guard !isReadOnly else { return }
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            items.removeAll { $0.id == id }
        }

        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
    }

    func updateItem(
        id: UUID,
        name: String? = nil,
        amount: Decimal? = nil,
        assignedTo: [Participant]? = nil
    ) {
        guard !isReadOnly else { return }
        guard let index = items.firstIndex(where: { $0.id == id }) else {
            return
        }

        if let name {
            items[index].name = name
        }
        if let amount {
            items[index].amount = amount
        }
        if let assignedTo {
            items[index].assignedTo = assignedTo
        }
    }

    func assignParticipant(to itemId: UUID, participant: Participant) {
        guard !isReadOnly else { return }
        guard let index = items.firstIndex(where: { $0.id == itemId }) else {
            return
        }

        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            items[index].assignedTo = [participant]
        }

        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }

    func toggleParticipant(to itemId: UUID, participant: Participant) {
        guard !isReadOnly else { return }
        guard let index = items.firstIndex(where: { $0.id == itemId }) else {
            return
        }

        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            if items[index].assignedTo.contains(where: { $0.id == participant.id }) {
                items[index].assignedTo.removeAll { $0.id == participant.id }
            } else {
                items[index].assignedTo.append(participant)
            }
        }

        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }

    func save() async -> Bool {
        saveErrorMessage = nil
        saveNoticeMessage = nil

        guard let eventId = mode.eventId else {
            saveErrorMessage = "Нужно открыть счёт из события, чтобы сохранить его на сервер."
            return false
        }

        guard canSave else {
            return false
        }

        guard Self.hasValidContent(title: receiptTitle, items: items) else {
            saveErrorMessage = "Заполни название, сумму и участников для каждой позиции."
            return false
        }

        guard let payerId = payerId ?? loadedEvent?.creatorId ?? participants.first?.id else {
            saveErrorMessage = "Не удалось определить плательщика для этого чека."
            return false
        }

        let request = makeReceiptRequest(payerId: payerId, items: items)

        isSaving = true
        defer { isSaving = false }

        do {
            try await ensureParticipantsInEvent(
                eventId: eventId,
                items: items,
                payerId: payerId
            )
            let outcome = try await persistReceipt(request, eventId: eventId)
            if let outcome,
               let imageUploadFailure = outcome.imageUploadFailure,
               let receiptImageJPEGData {
                pendingImageUpload = (
                    receiptId: outcome.receipt.id,
                    imageJPEGData: receiptImageJPEGData
                )
                saveNoticeMessage =
                    "Чек сохранён, но фото не загрузилось. Повторите загрузку или завершите без фото."
                print(
                    "[BillViewModel] op=save mode=image_upload_failed " +
                        "eventId=\(eventId) error=\(imageUploadFailure.localizedDescription)"
                )
                UINotificationFeedbackGenerator().notificationOccurred(.warning)
                return false
            }
            print("[BillViewModel] op=save mode=success eventId=\(eventId)")
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            return true
        } catch {
            print("[BillViewModel] op=save mode=failure eventId=\(eventId) error=\(error.localizedDescription)")
            saveErrorMessage = UserFacingErrorMapper.message(
                for: error,
                fallback: "Не удалось сохранить чек. Проверьте интернет и попробуйте снова."
            )
            return false
        }
    }

    func retryReceiptImageUpload() async -> Bool {
        guard let pendingImageUpload else { return false }

        isSaving = true
        defer { isSaving = false }

        do {
            _ = try await receiptsRepository.uploadReceiptImage(
                receiptId: pendingImageUpload.receiptId,
                imageJPEGData: pendingImageUpload.imageJPEGData
            )
            self.pendingImageUpload = nil
            saveNoticeMessage = nil
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            return true
        } catch {
            saveNoticeMessage = "Чек уже сохранён. Фото пока не загрузилось — попробуйте ещё раз позже."
            return false
        }
    }
}
