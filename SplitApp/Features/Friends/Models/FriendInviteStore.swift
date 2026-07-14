import Combine
import Foundation

@MainActor
final class FriendInviteStore: ObservableObject {
    static let shared = FriendInviteStore()

    @Published private(set) var pendingToken: String?

    private let defaults: UserDefaults
    private let pendingTokenKey = "friendInvite.pendingToken"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        pendingToken = defaults.string(forKey: pendingTokenKey)
    }

    @discardableResult
    func accept(_ url: URL) -> Bool {
        let pathComponents = url.pathComponents

        guard url.scheme == "splitapp",
              url.host == "friend-invite",
              pathComponents.count == 2,
              let token = pathComponents.last,
              !token.isEmpty,
              token != "/" else {
            return false
        }

        pendingToken = token
        defaults.set(token, forKey: pendingTokenKey)
        return true
    }

    func clear() {
        pendingToken = nil
        defaults.removeObject(forKey: pendingTokenKey)
    }
}
