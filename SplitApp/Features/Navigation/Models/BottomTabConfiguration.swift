import SwiftUI
import Combine

enum BottomTabID: String, Hashable {
    case home
    case friends
    case splitik
    case events
}

@MainActor
final class AppTabCenter: ObservableObject {
    static let shared = AppTabCenter()

    @Published private(set) var requestedTab: BottomTabID?
    @Published private(set) var isProfilePresented = false

    func select(_ tab: BottomTabID) {
        requestedTab = tab
    }

    func consume() {
        requestedTab = nil
    }

    func openProfile() {
        isProfilePresented = true
    }

    func closeProfile() {
        isProfilePresented = false
    }
}

struct BottomTabItem: Identifiable {
    let id: BottomTabID
    let title: String
    let systemImage: String
    let makeView: () -> AnyView

    init(
        id: BottomTabID,
        title: String,
        systemImage: String,
        @ViewBuilder makeView: @escaping () -> some View
    ) {
        self.id = id
        self.title = title
        self.systemImage = systemImage
        self.makeView = { AnyView(makeView()) }
    }
}

struct BottomTabConfiguration {
    let items: [BottomTabItem]
    let initialTab: BottomTabID
    let makeProfileView: () -> AnyView

    init(
        items: [BottomTabItem],
        initialTab: BottomTabID = .events,
        @ViewBuilder makeProfileView: @escaping () -> some View
    ) {
        self.items = items
        self.initialTab = initialTab
        self.makeProfileView = { AnyView(makeProfileView()) }
    }
}

extension BottomTabConfiguration {
    @MainActor
    static func makeDefault(with dependencies: AppDependencies, appState: AppState) -> BottomTabConfiguration {
        let storage = KeychainStorage()
        let logoutUseCase = LogoutUseCase(secureStorage: storage, appState: appState)
        let profileVM = ProfileViewModel(
            usersRepository: dependencies.usersRepository,
            eventsRepository: dependencies.eventsRepository,
            logoutUseCase: logoutUseCase
        )
        let eventsView = { (showsCatalog: Bool) in
            EventsNavigationView(
                service: dependencies.eventManagementService,
                eventsRepository: dependencies.eventsRepository,
                receiptsRepository: dependencies.receiptsRepository,
                usersRepository: dependencies.usersRepository,
                friendsRepository: dependencies.friendsRepository,
                activeEventRepository: dependencies.activeEventRepository,
                networkMonitor: dependencies.networkMonitor,
                showsCatalog: showsCatalog
            )
        }

        return BottomTabConfiguration(
            items: [
                BottomTabItem(
                    id: .home,
                    title: "Главная",
                    systemImage: "house.fill"
                ) {
                    eventsView(false)
                },
                BottomTabItem(
                    id: .friends,
                    title: "Друзья",
                    systemImage: "person.2"
                ) {
                    FriendsView(
                        friendsRepository: dependencies.friendsRepository,
                        usersRepository: dependencies.usersRepository,
                        balancesRepository: dependencies.balancesRepository,
                        paymentsRepository: dependencies.paymentsRepository,
                        activeEventRepository: dependencies.activeEventRepository,
                        networkMonitor: dependencies.networkMonitor
                    )
                },
                BottomTabItem(
                    id: .splitik,
                    title: "Сплитик",
                    systemImage: "sparkles"
                ) {
                    SplitikChatView()
                },
                BottomTabItem(
                    id: .events,
                    title: "События",
                    systemImage: "calendar"
                ) {
                    eventsView(true)
                }
            ],
            initialTab: .home,
            makeProfileView: {
                ProfileScreenView(viewModel: profileVM)
            }
        )
    }

    @MainActor
    static var preview: BottomTabConfiguration {
        makeDefault(with: .preview, appState: AppState(isLoggedIn: true))
    }
}
