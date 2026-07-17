import XCTest
@testable import SplitApp

@MainActor
final class EventsNavigationTests: XCTestCase {
    func testCreateEventActionOpensDedicatedEditor() {
        let rules = EventsNavigationRules()

        XCTAssertEqual(rules.route(for: .createEventTapped), .eventEditor)
    }

    func testCurrentEventActionStillOpensEventPicker() {
        let rules = EventsNavigationRules()

        XCTAssertEqual(rules.route(for: .currentEventTapped), .eventPicker)
    }

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

    func testCreatePaymentClearsNavigationAndPresentsNewPayment() {
        let event = Event(name: "Поездка")
        let viewModel = makeNavigationViewModel(event: event)
        viewModel.path = [.eventPicker]

        viewModel.createPayment(in: event.id)

        XCTAssertTrue(viewModel.path.isEmpty)
        guard case let .create(eventId, scannedItems, imageData) = viewModel.billEntryDestination?.mode else {
            return XCTFail("Expected a create-payment destination")
        }
        XCTAssertEqual(eventId, event.id)
        XCTAssertTrue(scannedItems.isEmpty)
        XCTAssertNil(imageData)
    }

    func testScannerPreviewConfirmationCreatesPaymentFromCapturedReceipt() async {
        let event = Event(name: "Поездка")
        let viewModel = makeNavigationViewModel(event: event)
        await viewModel.loadInitialDataIfNeeded()
        viewModel.scannerViewModel.items = [
            ScannedReceiptItem(name: "Такси", amount: 950)
        ]
        viewModel.scannerViewModel.scannedReceiptImageJPEGData = Data([1, 2, 3])

        viewModel.handle(.scanButtonTapped)
        viewModel.path.append(.receiptPreview)
        viewModel.handle(.scannerCaptureCompleted)

        XCTAssertEqual(viewModel.path, [.scanner, .receiptPreview])
        guard case let .create(eventID, items, imageData) = viewModel.billEntryDestination?.mode else {
            return XCTFail("Expected scanner confirmation to present payment editor")
        }
        XCTAssertEqual(eventID, event.id)
        XCTAssertEqual(items.map(\.name), ["Такси"])
        XCTAssertEqual(items.map(\.amount), [950])
        XCTAssertEqual(imageData, Data([1, 2, 3]))
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
