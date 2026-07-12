import Foundation
import YandexLoginSDK

final class LogoutUseCase {
    private let secureStorage: SecureStorage
    private let appState: AppState
    private let currentUserStore: CurrentUserStore

    init(
        secureStorage: SecureStorage,
        appState: AppState,
        currentUserStore: CurrentUserStore = .shared
    ) {
        self.secureStorage = secureStorage
        self.appState = appState
        self.currentUserStore = currentUserStore
    }

    @MainActor
    func execute() {
        TokenStore.shared.clear()
        secureStorage.delete("refresh_token")
        currentUserStore.clear()

        do {
            try YandexLoginSDK.shared.logout()
        } catch {
            print("Ошибка logout SDK: \(error)")
        }

        appState.isLoggedIn = false
    }
}
