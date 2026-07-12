import Foundation

protocol CurrentUserCaching: AnyObject {
    func load() -> CurrentUserData?
    func save(_ value: CurrentUserData)
    func clear()
}

final class UserDefaultsCurrentUserCache: CurrentUserCaching {
    private let defaults: UserDefaults
    private let key: String

    init(defaults: UserDefaults = .standard, key: String = "currentUser") {
        self.defaults = defaults
        self.key = key
    }

    func load() -> CurrentUserData? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(CurrentUserData.self, from: data)
    }

    func save(_ value: CurrentUserData) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        defaults.set(data, forKey: key)
    }

    func clear() {
        defaults.removeObject(forKey: key)
    }
}
