import Foundation

enum UserFacingErrorMapper {
    static func message(for error: Error, fallback: String) -> String {
        if let networkError = error as? NetworkError {
            return networkError.errorDescription ?? fallback
        }

        if let repositoryError = error as? RepositoryError {
            return repositoryError.errorDescription ?? fallback
        }

        return fallback
    }
}
