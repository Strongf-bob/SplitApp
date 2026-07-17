final class InvitationInboxDataRepository: InvitationInboxRepository {
    private let apiClient: APIClient

    init(apiClient: APIClient = .shared) {
        self.apiClient = apiClient
    }

    func listInvitations() async throws -> [EventInvitationInboxItem] {
        var offset = 0
        var invitations: [EventInvitationInboxItem] = []

        while true {
            let page: PageResponse<EventInvitationInboxItem> = try await apiClient.request(
                endpoint: ListEventInvitationsEndpoint(offset: offset)
            )
            invitations.append(contentsOf: page.items)
            guard page.hasMore, !page.items.isEmpty else {
                return invitations
            }
            offset = page.nextOffset
        }
    }

    func acceptInvitation(token: String) async throws {
        try await apiClient.requestVoid(endpoint: AcceptEventInvitationEndpoint(token: token))
    }

    func declineInvitation(token: String) async throws {
        try await apiClient.requestVoid(endpoint: DeclineEventInvitationEndpoint(token: token))
    }
}
