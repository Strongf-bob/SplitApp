import SwiftUI

struct EventsNavigationView: View {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var viewModel: EventsNavigationViewModel
    @StateObject private var inboxViewModel: InvitationInboxViewModel
    private let eventsRepository: any EventsRepository
    private let receiptsRepository: any ReceiptsRepository
    private let usersRepository: any UsersRepository
    private let friendsRepository: any FriendsRepository
    private let networkMonitor: NetworkMonitor
    private let showsCatalog: Bool

    init(
        service: EventManagementServiceProtocol,
        eventsRepository: any EventsRepository,
        receiptsRepository: any ReceiptsRepository,
        usersRepository: any UsersRepository,
        friendsRepository: any FriendsRepository,
        activeEventRepository: any ActiveEventRepository,
        networkMonitor: NetworkMonitor,
        showsCatalog: Bool = false,
        rules: EventsNavigationRules = .init()
    ) {
        self.eventsRepository = eventsRepository
        self.receiptsRepository = receiptsRepository
        self.usersRepository = usersRepository
        self.friendsRepository = friendsRepository
        self.networkMonitor = networkMonitor
        self.showsCatalog = showsCatalog
        _viewModel = StateObject(
            wrappedValue: EventsNavigationViewModel(
                service: service,
                activeEventRepository: activeEventRepository,
                rules: rules
            )
        )
        _inboxViewModel = StateObject(
            wrappedValue: InvitationInboxViewModel(repository: InvitationInboxDataRepository())
        )
    }

    var body: some View {
        NavigationStack(path: $viewModel.path) {
            Group {
                if showsCatalog {
                    EventsCatalogView(
                        viewModel: viewModel.homeViewModel,
                        onEventTap: { viewModel.handle(.eventSelected($0)) },
                        onCreateTap: { viewModel.handle(.createEventTapped) }
                    )
                } else {
                    EventsHomeView(
                        viewModel: viewModel.homeViewModel,
                        networkMonitor: networkMonitor,
                        hasUnreadInvitations: !inboxViewModel.invitations.isEmpty,
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
                        onCreateEventTap: {
                            viewModel.handle(.createEventTapped)
                        },
                        onInboxTap: {
                            viewModel.handle(.inboxTapped)
                        }
                    )
                }
            }
            .task {
                await viewModel.loadInitialDataIfNeeded()
                await inboxViewModel.load()
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
            .onChange(of: viewModel.path) { _, path in
                AppTabCenter.shared.setTabBarHidden(!path.isEmpty)
            }
            .navigationDestination(for: EventsNavigationRoute.self) { route in
                switch route {
                case .scanner:
                    CameraView(
                        viewModel: viewModel.scannerViewModel,
                        onCapture: { viewModel.path.append(.receiptPreview) }
                    )
                    .navigationBarBackButtonHidden(true)

                case .receiptPreview:
                    ReceiptPreviewView(
                        viewModel: viewModel.scannerViewModel,
                        onClose: {
                            if viewModel.path.last == .receiptPreview {
                                viewModel.path.removeLast()
                            }
                        },
                        onConfirm: { viewModel.handle(.scannerCaptureCompleted) }
                    )

                case .eventPicker:
                    EventPickerView(
                        viewModel: viewModel.homeViewModel,
                        friendsRepository: friendsRepository,
                        eventsRepository: eventsRepository,
                        onCreatePayment: { viewModel.createPayment(in: $0) }
                    )
                case .eventEditor:
                    EventEditorView(
                        viewModel: viewModel.homeViewModel,
                        friendsRepository: friendsRepository,
                        eventsRepository: eventsRepository,
                        onCreatePayment: { viewModel.createPayment(in: $0) }
                    )
                case .eventDetails:
                    EventsHomeView(
                        viewModel: viewModel.homeViewModel,
                        networkMonitor: networkMonitor,
                        hasUnreadInvitations: !inboxViewModel.invitations.isEmpty,
                        onScanTap: { viewModel.handle(.scanButtonTapped) },
                        onAddTap: { viewModel.handle(.addButtonTapped) },
                        onBillTap: { billId in
                            guard let eventId = viewModel.homeViewModel.currentEvent?.id else {
                                return
                            }
                            viewModel.handle(.receiptTapped(eventId: eventId, receiptId: billId))
                        },
                        onEventTap: { viewModel.handle(.currentEventTapped) },
                        onCreateEventTap: { viewModel.handle(.createEventTapped) },
                        onInboxTap: { viewModel.handle(.inboxTapped) },
                        showsNavigationBar: true
                    )
                case .inbox:
                    InboxView(viewModel: inboxViewModel, networkMonitor: networkMonitor)
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
        friendsRepository: FriendsDataRepository(),
        activeEventRepository: ActiveEventSelectionDataRepository(),
        networkMonitor: .shared
    )
}
