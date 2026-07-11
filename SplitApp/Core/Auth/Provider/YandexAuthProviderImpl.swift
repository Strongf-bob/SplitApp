import Foundation
import UIKit
import YandexLoginSDK

enum AuthError: Error {
    case invalidToken
    case loginAlreadyInProgress
}

final class YandexAuthProviderImpl: YandexAuthProvider {
    private var continuation: CheckedContinuation<UserSessionToken, Error>?
    private let vcProvider: ViewControllerProvider

    init(vcProvider: ViewControllerProvider) {
        self.vcProvider = vcProvider
        YandexLoginSDK.shared.add(observer: self)
    }

    deinit {
        YandexLoginSDK.shared.remove(observer: self)
    }

    func login(from _: UIViewController) async throws
        -> UserSessionToken {
        guard let viewContollerProvider = vcProvider.rootViewController else {
            throw AuthError.invalidToken
        }
        guard continuation == nil else {
            throw AuthError.loginAlreadyInProgress
        }

        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation

            do {
                try YandexLoginSDK.shared.authorize(with: viewContollerProvider)
            } catch {
                self.completeLogin(with: .failure(error))
            }
        }
    }

    private func completeLogin(with result: Result<UserSessionToken, any Error>) {
        guard let continuation else {
            return
        }

        self.continuation = nil

        switch result {
        case let .success(token):
            continuation.resume(returning: token)

        case let .failure(error):
            continuation.resume(throwing: error)
        }
    }
}

extension YandexAuthProviderImpl: YandexLoginSDKObserver {
    func didFinishLogin(with result: Result<LoginResult, any Error>) {
        switch result {
        case let .success(data):
            let authToken = UserSessionToken(
                jwt: data.jwt,
                token: data.token
            )
            completeLogin(with: .success(authToken))

        case let .failure(error):
            completeLogin(with: .failure(error))
            print("Ошибка входа: \(error.localizedDescription)")
        }
    }
}
