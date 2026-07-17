import Foundation
import YandexLoginSDK

@MainActor
final class LogoutUseCase {
    private let secureStorage: SecureStorage
    private let appState: AppState
    private let currentUserStore: CurrentUserStore
    private let friendInviteStore: FriendInviteStore
    private let appTabCenter: AppTabCenter

    init(
        secureStorage: SecureStorage,
        appState: AppState,
        currentUserStore: CurrentUserStore? = nil,
        friendInviteStore: FriendInviteStore? = nil,
        appTabCenter: AppTabCenter? = nil
    ) {
        self.secureStorage = secureStorage
        self.appState = appState
        self.currentUserStore = currentUserStore ?? .shared
        self.friendInviteStore = friendInviteStore ?? .shared
        self.appTabCenter = appTabCenter ?? .shared
    }

    func execute() {
        TokenStore.shared.clear()
        secureStorage.delete("refresh_token")
        currentUserStore.clear()
        friendInviteStore.clear()
        appTabCenter.resetShell()

        do {
            try YandexLoginSDK.shared.logout()
        } catch {
            print("Ошибка logout SDK: \(error)")
        }

        appState.isLoggedIn = false
    }
}
