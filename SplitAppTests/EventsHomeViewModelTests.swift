import XCTest
@testable import SplitApp

@MainActor
final class EventsHomeViewModelTests: XCTestCase {
    func testParticipantsForLocalStoreDeduplicatesUsersWithTheSameID() {
        let sharedID = UUID()
        let event = Event(
            name: "Поездка",
            participants: [User(id: sharedID, name: "Илья", phoneNumber: "yandex:1")],
            users: [
                User(id: sharedID, name: "Илья", phoneNumber: "yandex:1"),
                User(id: UUID(), name: "Маша", phoneNumber: "yandex:2")
            ]
        )

        let participants = EventsHomeViewModel.participantsForLocalStore(from: event)

        XCTAssertEqual(participants.map(\.id), [sharedID, event.users[1].id])
    }

    func testCreateEventIgnoresConcurrentSecondSubmission() async {
        let service = CountingEventManagementService()
        let viewModel = EventsHomeViewModel(
            service: service,
            activeEventRepository: InMemoryActiveEventRepository()
        )

        async let first = viewModel.createEvent(name: "Поездка")
        async let second = viewModel.createEvent(name: "Поездка")
        _ = await (first, second)

        let callCount = await service.createEventCallCount
        XCTAssertEqual(callCount, 1)
    }
}

private actor CountingEventManagementService: EventManagementServiceProtocol {
    private(set) var createEventCallCount = 0

    func fetchHomeData() async throws -> EventsHomeData {
        EventsHomeData(balanceSummary: .init(totalBalance: 0, owedToYou: 0, youOwe: 0), events: [])
    }

    func fetchReceipts(eventId: UUID) async throws -> [ReceiptDTO] { [] }
    func fetchReceiptsPage(eventId: UUID, limit: Int, offset: Int) async throws -> PageResponse<ReceiptDTO> {
        PageResponse(items: [], limit: limit, offset: offset, total: 0)
    }
    func createReceipt(eventId: UUID, request: CreateReceiptRequest) async throws -> ReceiptDTO { fatalError("Unused") }
    func updateReceipt(id: UUID, request: UpdateReceiptRequest) async throws -> ReceiptDTO { fatalError("Unused") }
    func deleteReceipt(id: UUID) async throws {}
    func getReceiptImagePresignedURL(id: UUID) async throws -> URL { fatalError("Unused") }
    func updateEvent(id: UUID, request: UpdateEventRequest) async throws -> Event { fatalError("Unused") }
    func deleteEvent(id: UUID) async throws {}

    func createEvent(name: String) async throws -> Event {
        createEventCallCount += 1
        try await Task.sleep(for: .milliseconds(50))
        return Event(name: name)
    }
}

private actor InMemoryActiveEventRepository: ActiveEventRepository {
    private var id: UUID?

    func getActiveEventId() async -> UUID? { id }
    func setActiveEventId(_ id: UUID) async { self.id = id }
    func clearActiveEventId() async { id = nil }
}
