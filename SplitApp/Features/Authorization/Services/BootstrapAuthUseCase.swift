import Foundation

enum BootstrapAuthResult: Equatable {
    case authenticated
    case unauthenticated
}

final class BootstrapAuthUseCase {
    private let storage: SecureStorage
    private let refresh: () async throws -> Void

    init(
        storage: SecureStorage,
        refresh: @escaping () async throws -> Void = {
            try await APIClient.shared.refreshAccessTokenIfNeeded()
        }
    ) {
        self.storage = storage
        self.refresh = refresh
    }

    func execute() async -> BootstrapAuthResult {
        guard storage.get("refresh_token") != nil else {
            return .unauthenticated
        }

        do {
            try await refresh()
            return .authenticated
        } catch {
            storage.delete("refresh_token")
            TokenStore.shared.clear()
            return .unauthenticated
        }
    }
}
