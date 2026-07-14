import Combine
import Foundation

@MainActor
final class FriendInviteStore: ObservableObject {
    static let shared = FriendInviteStore()

    @Published private(set) var pendingToken: String?

    private let secureStorage: SecureStorage
    private let pendingTokenKey = "friendInvite.pendingToken"

    init(secureStorage: SecureStorage = KeychainStorage()) {
        self.secureStorage = secureStorage
        pendingToken = secureStorage.get(pendingTokenKey)
    }

    @discardableResult
    func accept(_ url: URL) -> Bool {
        let pathComponents = url.pathComponents

        guard url.scheme == "splitapp",
              url.host == "friend-invite",
              pathComponents.count == 2,
              let token = pathComponents.last,
              !token.isEmpty,
              token != "/",
              token.range(of: "^[A-Za-z0-9_-]{43}$", options: .regularExpression) != nil else {
            return false
        }

        pendingToken = token
        secureStorage.save(token, for: pendingTokenKey)
        return true
    }

    func clear() {
        pendingToken = nil
        secureStorage.delete(pendingTokenKey)
    }
}
