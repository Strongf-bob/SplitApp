import Combine
import Foundation

@MainActor
final class SplitikChatViewModel: ObservableObject {
    struct Message: Identifiable {
        enum Role { case user, assistant }
        let id = UUID()
        let role: Role
        let text: String
        let drafts: [SplitikDraftDTO]

        init(role: Role, text: String, drafts: [SplitikDraftDTO] = []) {
            self.role = role
            self.text = text
            self.drafts = drafts
        }
    }

    @Published private(set) var messages: [Message] = []
    @Published private(set) var isSending = false
    @Published var errorMessage: String?

    private var sessionId: UUID?
    private let apiClient: APIClient

    init(apiClient: APIClient? = nil) {
        self.apiClient = apiClient ?? .shared
    }

    func loadHistory() async {
        guard !isSending else { return }

        do {
            let session: SplitikSessionDTO = try await apiClient.request(
                endpoint: CurrentSplitikSessionEndpoint()
            )
            sessionId = session.id
            messages = session.messages.flatMap { message in
                [
                    Message(role: .user, text: message.userMessage),
                    Message(role: .assistant, text: message.assistantMessage),
                ]
            }
        } catch let NetworkError.httpError(statusCode: 404, _) {
            sessionId = nil
            messages = []
        } catch {
            errorMessage = UserFacingErrorMapper.message(
                for: error,
                fallback: "Не удалось загрузить историю Сплитика."
            )
        }
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
            messages.append(Message(role: .assistant, text: response.assistantMessage, drafts: response.drafts))
        } catch {
            errorMessage = UserFacingErrorMapper.message(
                for: error,
                fallback: "Не удалось получить ответ Сплитика. Попробуйте ещё раз."
            )
        }
    }

    func confirm(_ draft: SplitikDraftDTO) async {
        guard !isSending, draft.status == "pending" else { return }
        isSending = true
        defer { isSending = false }
        do {
            let _: SplitikDraftCommitResponse = try await apiClient.request(
                endpoint: SplitikDraftCommitEndpoint(draftId: draft.id),
                body: nil
            )
            messages.append(Message(role: .assistant, text: "План подтверждён. Событие и платежи созданы."))
        } catch {
            errorMessage = UserFacingErrorMapper.message(for: error, fallback: "Не удалось подтвердить план.")
        }
    }
}
