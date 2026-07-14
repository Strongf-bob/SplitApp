import XCTest
@testable import SplitApp

@MainActor
final class FriendInviteStoreTests: XCTestCase {
    func testAcceptURLStoresFriendInviteToken() {
        let defaults = UserDefaults(suiteName: "FriendInviteStoreTests.accept")!
        defaults.removePersistentDomain(forName: "FriendInviteStoreTests.accept")
        let store = FriendInviteStore(defaults: defaults)

        XCTAssertTrue(store.accept(URL(string: "splitapp://friend-invite/secure-token")!))
        XCTAssertEqual(store.pendingToken, "secure-token")
    }

    func testAcceptURLRejectsMalformedOrUnrelatedURLs() {
        let store = FriendInviteStore(defaults: .standard)

        XCTAssertFalse(store.accept(URL(string: "splitapp://friend-invite")!))
        XCTAssertFalse(store.accept(URL(string: "https://split-app.ru/friend-invite/token")!))
        XCTAssertFalse(store.accept(URL(string: "splitapp://events/token")!))
    }

    func testClearRemovesPersistedToken() {
        let defaults = UserDefaults(suiteName: "FriendInviteStoreTests.clear")!
        defaults.removePersistentDomain(forName: "FriendInviteStoreTests.clear")
        let store = FriendInviteStore(defaults: defaults)
        _ = store.accept(URL(string: "splitapp://friend-invite/secure-token")!)

        store.clear()

        XCTAssertNil(store.pendingToken)
        XCTAssertNil(defaults.string(forKey: "friendInvite.pendingToken"))
    }
}
