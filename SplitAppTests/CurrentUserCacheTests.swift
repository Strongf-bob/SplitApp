import XCTest
@testable import SplitApp

@MainActor
final class CurrentUserCacheTests: XCTestCase {
    func testCacheRestoresSavedProfile() {
        let cache = InMemoryCurrentUserCache()
        let store = CurrentUserStore(cache: cache)
        let user = User(
            id: UUID(),
            name: "Алиса",
            phoneNumber: "yandex:1",
            avatarUrl: "/avatars/1"
        )

        store.updateFromAuth(user)
        store.clearInMemoryUser()

        XCTAssertEqual(store.restoreCachedUser()?.name, "Алиса")
        XCTAssertEqual(store.restoreCachedUser()?.avatarURL?.path, "/avatars/1")
    }

    func testClearRemovesSavedProfile() {
        let cache = InMemoryCurrentUserCache()
        let store = CurrentUserStore(cache: cache)
        store.updateFromAuth(User(id: UUID(), name: "Алиса", phoneNumber: "yandex:1"))

        store.clear()

        XCTAssertNil(store.restoreCachedUser())
    }

    func testCacheRestoresPaymentPhone() {
        let cache = InMemoryCurrentUserCache()
        let store = CurrentUserStore(cache: cache)
        store.updateFromAuth(
            User(
                id: UUID(),
                name: "Алиса",
                phoneNumber: "+79990000000",
                paymentPhone: "+79266243377"
            )
        )
        store.clearInMemoryUser()

        XCTAssertEqual(store.restoreCachedUser()?.paymentPhone, "+79266243377")
    }

    func testAccountPhoneIsNotUsedAsTransferPhone() {
        let cache = InMemoryCurrentUserCache()
        let store = CurrentUserStore(cache: cache)
        store.updateFromAuth(
            User(
                id: UUID(),
                name: "Алиса",
                phoneNumber: "+79990000000",
                paymentPhone: nil
            )
        )

        XCTAssertNil(store.user?.configuredPaymentPhone)
    }
}

private final class InMemoryCurrentUserCache: CurrentUserCaching {
    var value: CurrentUserData?

    func load() -> CurrentUserData? { value }
    func save(_ value: CurrentUserData) { self.value = value }
    func clear() { value = nil }
}
