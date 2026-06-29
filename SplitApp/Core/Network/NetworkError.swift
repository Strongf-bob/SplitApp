import Foundation

enum NetworkError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int, detail: String?)
    case decodingError(Error)
    case unauthorized
    case noData
    case noRefreshToken

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            "Не удалось подготовить запрос."
        case .invalidResponse:
            "Сервер вернул некорректный ответ."
        case let .httpError(statusCode, detail):
            if (500...599).contains(statusCode) {
                "Сервер временно недоступен. Попробуйте позже."
            } else if statusCode == 404 {
                "Данные не найдены. Обновите экран и попробуйте снова."
            } else if statusCode == 403 {
                "Недостаточно прав для этого действия."
            } else {
                detail?.isEmpty == false ? detail : "Не удалось выполнить запрос."
            }
        case .decodingError:
            "Не удалось обработать ответ сервера."
        case .unauthorized:
            "Сессия истекла. Войдите в аккаунт еще раз."
        case .noData:
            "Сервер не вернул данные."
        case .noRefreshToken:
            "Сессия истекла. Войдите в аккаунт еще раз."
        }
    }
}
