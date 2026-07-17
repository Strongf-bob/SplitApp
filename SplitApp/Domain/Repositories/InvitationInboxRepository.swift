protocol InvitationInboxRepository {
    func listInvitations() async throws -> [EventInvitationInboxItem]
    func acceptInvitation(token: String) async throws
    func declineInvitation(token: String) async throws
}
