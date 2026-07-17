import Foundation
import Combine

enum FriendInviteLink {
    static func make(phone: String) -> URL? {
        let normalizedPhone = SearchUsersEndpoint.normalizePhone(phone)
        guard normalizedPhone.count >= 11 else { return nil }

        var components = URLComponents()
        components.scheme = "splitapp"
        components.host = "friends"
        components.path = "/add"
        components.queryItems = [URLQueryItem(name: "phone", value: normalizedPhone)]
        return components.url
    }

    static func phone(from url: URL) -> String? {
        guard url.scheme == "splitapp", url.host == "friends", url.path == "/add" else {
            return nil
        }
        return URLComponents(url: url, resolvingAgainstBaseURL: false)?
            .queryItems?
            .first { $0.name == "phone" }?
            .value
    }
}

@MainActor
final class FriendInviteLinkCenter: ObservableObject {
    static let shared = FriendInviteLinkCenter()

    @Published private(set) var pendingPhone: String?

    func handle(_ url: URL) {
        pendingPhone = FriendInviteLink.phone(from: url)
    }

    func consume() -> String? {
        defer { pendingPhone = nil }
        return pendingPhone
    }
}
