import XCTest
@testable import SplitApp

@MainActor
final class FriendInviteStoreTests: XCTestCase {
    func testAcceptURLStoresFriendInviteToken() {
        let storage = InMemoryFriendInviteStorage()
        let store = FriendInviteStore(secureStorage: storage)
        let token = String(repeating: "a", count: 43)

        XCTAssertTrue(store.accept(URL(string: "splitapp://friend-invite/\(token)")!))
        XCTAssertEqual(store.pendingToken, token)
    }

    func testAcceptURLRejectsMalformedOrUnrelatedURLs() {
        let store = FriendInviteStore(secureStorage: InMemoryFriendInviteStorage())

        XCTAssertFalse(store.accept(URL(string: "splitapp://friend-invite")!))
        XCTAssertFalse(store.accept(URL(string: "https://split-app.ru/friend-invite/token")!))
        XCTAssertFalse(store.accept(URL(string: "splitapp://events/token")!))
        XCTAssertFalse(store.accept(URL(string: "splitapp://friend-invite/too-short")!))
    }

    func testClearRemovesPersistedToken() {
        let storage = InMemoryFriendInviteStorage()
        let store = FriendInviteStore(secureStorage: storage)
        let token = String(repeating: "a", count: 43)
        _ = store.accept(URL(string: "splitapp://friend-invite/\(token)")!)

        store.clear()

        XCTAssertNil(store.pendingToken)
        XCTAssertNil(storage.get("friendInvite.pendingToken"))
    }
}

private final class InMemoryFriendInviteStorage: SecureStorage {
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
