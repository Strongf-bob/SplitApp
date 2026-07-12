import Combine
import SwiftUI

struct CurrentUser {
    let id: UUID
    let name: String
    let initials: String
    let avatarURL: URL?
    let color: Color
    let email: String?
    let phoneNumber: String?
}

@MainActor
final class CurrentUserStore: ObservableObject {
    static let shared = CurrentUserStore()

    @Published var user: CurrentUser?
    private let cache: CurrentUserCaching

    init(cache: CurrentUserCaching = UserDefaultsCurrentUserCache()) {
        self.cache = cache
    }

    func updateFromAuth(_ authUser: User) {
        let initials = makeInitials(from: authUser.name)
        let avatarURL = authUser.avatarURL

        user = CurrentUser(
            id: authUser.id,
            name: authUser.name,
            initials: initials,
            avatarURL: avatarURL,
            color: Color(hex: "#7CB342"),
            email: authUser.email,
            phoneNumber: authUser.phoneNumber
        )

        saveToCache()
    }

    @discardableResult
    func restoreCachedUser() -> CurrentUser? {
        guard let decoded = cache.load() else { return nil }

        user = CurrentUser(
            id: decoded.id,
            name: decoded.name,
            initials: decoded.initials,
            avatarURL: User.resolveAvatarURL(decoded.avatarURLString),
            color: Color(hex: "#7CB342"),
            email: decoded.email,
            phoneNumber: decoded.phoneNumber
        )
        return user
    }

    func clearInMemoryUser() {
        user = nil
    }

    func clear() {
        clearInMemoryUser()
        cache.clear()
    }

    private func saveToCache() {
        guard let user else { return }
        cache.save(CurrentUserData(
            id: user.id,
            name: user.name,
            initials: user.initials,
            avatarURLString: user.avatarURL?.absoluteString,
            email: user.email,
            phoneNumber: user.phoneNumber
        ))
    }

    private func makeInitials(from name: String) -> String {
        let components = name.split(separator: " ")
        if components.count >= 2 {
            let first = components[0].prefix(1).uppercased()
            let second = components[1].prefix(1).uppercased()
            return first + second
        } else if let first = components.first {
            return String(first.prefix(2).uppercased())
        }
        return "?"
    }
}

struct CurrentUserData: Codable {
    let id: UUID
    let name: String
    let initials: String
    let avatarURLString: String?
    let email: String?
    let phoneNumber: String?
}

extension CurrentUser {
    func toParticipant() -> Participant {
        Participant(
            id: id,
            name: name,
            initials: initials,
            color: color,
            avatarURL: avatarURL
        )
    }
}

extension CurrentUserStore {
    func toParticipant() -> Participant? {
        user?.toParticipant()
    }
}
