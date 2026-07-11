import XCTest
@testable import SplitApp

@MainActor
final class LogoutUseCaseTests: XCTestCase {
    func testLogoutClearsTheCachedProfile() {
        CurrentUserStore.shared.updateFromAuth(
            User(
                id: UUID(),
                name: "Тестовый пользователь",
                phoneNumber: "yandex:test",
                email: "test@example.com"
            )
        )
        let storage = InMemorySecureStorage()
        storage.save("refresh-token", for: "refresh_token")
        let appState = AppState(isLoading: false, isLoggedIn: true)

        LogoutUseCase(secureStorage: storage, appState: appState).execute()

        XCTAssertNil(CurrentUserStore.shared.user)
        XCTAssertNil(storage.get("refresh_token"))
        XCTAssertFalse(appState.isLoggedIn)
    }
}

private final class InMemorySecureStorage: SecureStorage {
    private var values: [String: String] = [:]

    func save(_ value: String, for key: String) {
        values[key] = value
    }

    func get(_ key: String) -> String? {
        values[key]
    }

    func delete(_ key: String) {
        values[key] = nil
    }
}
