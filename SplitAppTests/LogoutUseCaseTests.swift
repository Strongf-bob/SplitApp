import XCTest
@testable import SplitApp

@MainActor
final class LogoutUseCaseTests: XCTestCase {
    func testLogoutClearsTheCachedProfile() {
        let cache = TestCurrentUserCache()
        let userStore = CurrentUserStore(cache: cache)
        userStore.updateFromAuth(
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

        LogoutUseCase(
            secureStorage: storage,
            appState: appState,
            currentUserStore: userStore
        ).execute()

        XCTAssertNil(userStore.user)
        XCTAssertNil(cache.load())
        XCTAssertNil(storage.get("refresh_token"))
        XCTAssertFalse(appState.isLoggedIn)
    }
}

private final class TestCurrentUserCache: CurrentUserCaching {
    private var value: CurrentUserData?

    func load() -> CurrentUserData? { value }
    func save(_ value: CurrentUserData) { self.value = value }
    func clear() { value = nil }
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
