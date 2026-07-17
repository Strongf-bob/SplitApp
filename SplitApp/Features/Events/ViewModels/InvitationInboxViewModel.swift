import Combine
import Foundation

@MainActor
final class InvitationInboxViewModel: ObservableObject {
    @Published private(set) var invitations: [EventInvitationInboxItem] = []
    @Published private(set) var isLoading = false
    @Published private(set) var updatingIDs: Set<UUID> = []
    @Published private(set) var errorMessage: String?
    @Published private(set) var successMessage: String?

    private let repository: any InvitationInboxRepository

    init(repository: any InvitationInboxRepository) {
        self.repository = repository
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            invitations = try await repository.listInvitations()
        } catch is CancellationError {
            return
        } catch {
            errorMessage = "Не удалось загрузить приглашения. Проверьте интернет и попробуйте снова."
        }
    }

    func accept(_ invitation: EventInvitationInboxItem) async {
        await update(invitation, successMessage: "Приглашение принято") {
            try await repository.acceptInvitation(token: invitation.token)
        }
    }

    func decline(_ invitation: EventInvitationInboxItem) async {
        await update(invitation, successMessage: "Приглашение отклонено") {
            try await repository.declineInvitation(token: invitation.token)
        }
    }

    private func update(
        _ invitation: EventInvitationInboxItem,
        successMessage: String,
        operation: () async throws -> Void
    ) async {
        guard !updatingIDs.contains(invitation.id) else { return }
        updatingIDs.insert(invitation.id)
        errorMessage = nil
        self.successMessage = nil
        defer { updatingIDs.remove(invitation.id) }

        do {
            try await operation()
            invitations.removeAll { $0.id == invitation.id }
            self.successMessage = successMessage
        } catch {
            errorMessage = "Не удалось обработать приглашение. Попробуйте ещё раз."
        }
    }
}
