import Foundation

struct SplitikMessageRequest: Encodable {
    let message: String
    let sessionId: UUID?
    let mode = "general"
    let locale = "ru-RU"
    let timezone = "Europe/Moscow"

    enum CodingKeys: String, CodingKey {
        case message
        case sessionId = "session_id"
        case mode, locale, timezone
    }
}

struct SplitikMessageResponse: Decodable {
    let sessionId: UUID
    let assistantMessage: String

    enum CodingKeys: String, CodingKey {
        case sessionId = "session_id"
        case assistantMessage = "assistant_message"
    }
}
