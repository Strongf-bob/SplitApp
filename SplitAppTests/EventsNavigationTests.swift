import XCTest
@testable import SplitApp

@MainActor
final class EventsNavigationTests: XCTestCase {
    func testSelectingCatalogEventSelectsItAndPushesEventDetails() async {
        let event = Event(name: "Поездка в такси")
        let viewModel = makeNavigationViewModel(event: event)
        await viewModel.loadInitialDataIfNeeded()

        guard let catalogEvent = viewModel.homeViewModel.latestEvents.first else {
            return XCTFail("Expected the catalog to contain the fixture event")
        }

        viewModel.handle(.eventSelected(catalogEvent))

        XCTAssertEqual(viewModel.path, [.eventDetails])
        XCTAssertEqual(viewModel.homeViewModel.currentEvent?.id, catalogEvent.id)
    }

    private func makeNavigationViewModel(event: Event) -> EventsNavigationViewModel {
        EventsNavigationViewModel(
            homeViewModel: EventsHomeViewModel(
                service: EventsNavigationServiceStub(event: event),
                activeEventRepository: EventsNavigationActiveEventRepositoryStub()
            ),
            scannerViewModel: ReceiptViewModel(),
            rules: .init()
        )
    }
}

private struct EventsNavigationServiceStub: EventManagementServiceProtocol {
    let event: Event

    func fetchHomeData() async throws -> EventsHomeData {
        EventsHomeData(
            balanceSummary: EventBalanceSummary(totalBalance: 0, owedToYou: 0, youOwe: 0),
            events: [event]
        )
    }

    func fetchReceipts(eventId: UUID) async throws -> [ReceiptDTO] { [] }
    func fetchReceiptsPage(eventId: UUID, limit: Int, offset: Int) async throws -> PageResponse<ReceiptDTO> {
        PageResponse(items: [], limit: limit, offset: offset, total: 0)
    }
    func createReceipt(eventId: UUID, request: CreateReceiptRequest) async throws -> ReceiptDTO { fatalError("Unused") }
    func updateReceipt(id: UUID, request: UpdateReceiptRequest) async throws -> ReceiptDTO { fatalError("Unused") }
    func deleteReceipt(id: UUID) async throws {}
    func getReceiptImagePresignedURL(id: UUID) async throws -> URL { fatalError("Unused") }
    func createEvent(name: String) async throws -> Event { fatalError("Unused") }
    func updateEvent(id: UUID, request: UpdateEventRequest) async throws -> Event { fatalError("Unused") }
    func deleteEvent(id: UUID) async throws {}
}

private final class EventsNavigationActiveEventRepositoryStub: ActiveEventRepository {
    func getActiveEventId() async -> UUID? { nil }
    func setActiveEventId(_ eventId: UUID) async {}
    func clearActiveEventId() async {}
}
