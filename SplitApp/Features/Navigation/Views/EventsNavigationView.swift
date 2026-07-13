import SwiftUI

struct EventsNavigationView: View {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var viewModel: EventsNavigationViewModel
    private let eventsRepository: any EventsRepository
    private let receiptsRepository: any ReceiptsRepository
    private let usersRepository: any UsersRepository
    private let networkMonitor: NetworkMonitor
    private let showsCatalog: Bool

    init(
        service: EventManagementServiceProtocol,
        eventsRepository: any EventsRepository,
        receiptsRepository: any ReceiptsRepository,
        usersRepository: any UsersRepository,
        activeEventRepository: any ActiveEventRepository,
        networkMonitor: NetworkMonitor,
        showsCatalog: Bool = false,
        rules: EventsNavigationRules = .init()
    ) {
        self.eventsRepository = eventsRepository
        self.receiptsRepository = receiptsRepository
        self.usersRepository = usersRepository
        self.networkMonitor = networkMonitor
        self.showsCatalog = showsCatalog
        _viewModel = StateObject(
            wrappedValue: EventsNavigationViewModel(
                service: service,
                activeEventRepository: activeEventRepository,
                rules: rules
            )
        )
    }

    var body: some View {
        NavigationStack(path: $viewModel.path) {
            Group {
                if showsCatalog {
                    EventsCatalogView(
                        viewModel: viewModel.homeViewModel,
                        onEventTap: { viewModel.handle(.eventSelected($0)) }
                    )
                } else {
                    EventsHomeView(
                        viewModel: viewModel.homeViewModel,
                        onScanTap: { viewModel.handle(.scanButtonTapped) },
                        onAddTap: { viewModel.handle(.addButtonTapped) },
                        onBillTap: { billId in
                            guard let eventId = viewModel.homeViewModel.currentEvent?.id else {
                                return
                            }
                            viewModel.handle(.receiptTapped(eventId: eventId, receiptId: billId))
                        },
                        onEventTap: {
                            viewModel.handle(.currentEventTapped)
                        },
                        onInboxTap: {
                            viewModel.handle(.inboxTapped)
                        }
                    )
                }
            }
            .task {
                await viewModel.loadInitialDataIfNeeded()
            }
            .onAppear {
                Task {
                    await viewModel.refreshData()
                }
            }
            .onChange(of: scenePhase) { _, newPhase in
                guard newPhase == .active else { return }
                Task {
                    await viewModel.refreshData()
                }
            }
            .navigationDestination(for: EventsNavigationRoute.self) { route in
                switch route {
                case .scanner:
                    CameraView(
                        viewModel: viewModel.scannerViewModel,
                        onCapture: { viewModel.handle(.scannerCaptureCompleted) }
                    )
                    .navigationBarBackButtonHidden(true)

                case .eventPicker:
                    EventPickerView(viewModel: viewModel.homeViewModel)
                case .eventDetails:
                    EventsHomeView(
                        viewModel: viewModel.homeViewModel,
                        onScanTap: { viewModel.handle(.scanButtonTapped) },
                        onAddTap: { viewModel.handle(.addButtonTapped) },
                        onBillTap: { billId in
                            guard let eventId = viewModel.homeViewModel.currentEvent?.id else {
                                return
                            }
                            viewModel.handle(.receiptTapped(eventId: eventId, receiptId: billId))
                        },
                        onEventTap: { viewModel.handle(.currentEventTapped) },
                        onInboxTap: { viewModel.handle(.inboxTapped) },
                        showsNavigationBar: true
                    )
                case .inbox:
                    InboxView()
                }
            }
        }
        .fullScreenCover(
            item: $viewModel.billEntryDestination,
            onDismiss: {
                Task { @MainActor in
                    await viewModel.refreshData()
                    viewModel.didFinishBillEntry()
                }
            },
            content: { destination in
                let billViewModel = BillViewModel(
                    mode: destination.mode,
                    eventsRepository: eventsRepository,
                    receiptsRepository: receiptsRepository,
                    usersRepository: usersRepository,
                    networkMonitor: networkMonitor
                )
                BillEntryView(viewModel: billViewModel)
            }
        )
    }
}

#Preview {
    EventsNavigationView(
        service: EventManagementService(eventsRepository: EventsDataRepository()),
        eventsRepository: EventsDataRepository(),
        receiptsRepository: ReceiptsDataRepository(),
        usersRepository: UsersDataRepository(),
        activeEventRepository: ActiveEventSelectionDataRepository(),
        networkMonitor: .shared
    )
}
