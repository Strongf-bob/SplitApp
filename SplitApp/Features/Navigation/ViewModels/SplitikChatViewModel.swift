import Combine
import Foundation

@MainActor
final class SplitikChatViewModel: ObservableObject {
    struct Message: Identifiable {
        enum Role { case user, assistant }
        let id = UUID()
        let role: Role
        let text: String
    }

    @Published private(set) var messages: [Message] = []
    @Published private(set) var isSending = false
    @Published var errorMessage: String?

    private var sessionId: UUID?
    private let apiClient: APIClient

    init(apiClient: APIClient? = nil) {
        self.apiClient = apiClient ?? .shared
    }

    func send(_ text: String) async {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !isSending else { return }

        messages.append(Message(role: .user, text: trimmed))
        isSending = true
        defer { isSending = false }

        do {
            let response: SplitikMessageResponse = try await apiClient.request(
                endpoint: SplitikMessageEndpoint(),
                body: SplitikMessageRequest(message: trimmed, sessionId: sessionId)
            )
            sessionId = response.sessionId
            messages.append(Message(role: .assistant, text: response.assistantMessage))
        } catch {
            errorMessage = UserFacingErrorMapper.message(
                for: error,
                fallback: "Не удалось получить ответ Сплитика. Попробуйте ещё раз."
            )
        }
    }
}
