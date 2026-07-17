import XCTest
@testable import SplitApp

final class InvitationInboxEndpointTests: XCTestCase {
    func testListEndpointUsesInboxRouteAndPagination() {
        let endpoint = ListEventInvitationsEndpoint(limit: 25, offset: 50)

        XCTAssertEqual(endpoint.path, "/api/invites")
        XCTAssertEqual(endpoint.method, .GET)
        XCTAssertEqual(endpoint.queryItems, [
            URLQueryItem(name: "limit", value: "25"),
            URLQueryItem(name: "offset", value: "50")
        ])
    }

    func testInvitationActionsUseTokenRoutes() {
        XCTAssertEqual(
            AcceptEventInvitationEndpoint(token: "abc-123").path,
            "/api/invites/abc-123/accept"
        )
        XCTAssertEqual(
            DeclineEventInvitationEndpoint(token: "abc-123").path,
            "/api/invites/abc-123/decline"
        )
    }
}

@MainActor
final class InvitationInboxViewModelTests: XCTestCase {
    func testLoadPublishesServerInvitations() async {
        let invitation = makeInvitation()
        let repository = InvitationInboxRepositorySpy(invitations: [invitation])
        let viewModel = InvitationInboxViewModel(repository: repository)

        await viewModel.load()

        XCTAssertEqual(viewModel.invitations, [invitation])
        XCTAssertNil(viewModel.errorMessage)
    }

    func testAcceptRemovesInvitationAndReportsAcceptedEvent() async {
        let invitation = makeInvitation()
        let repository = InvitationInboxRepositorySpy(invitations: [invitation])
        let viewModel = InvitationInboxViewModel(repository: repository)

        await viewModel.load()
        await viewModel.accept(invitation)

        XCTAssertEqual(repository.acceptedTokens, [invitation.token])
        XCTAssertTrue(viewModel.invitations.isEmpty)
        XCTAssertEqual(viewModel.successMessage, "Приглашение принято")
    }

    func testDeclineRemovesInvitation() async {
        let invitation = makeInvitation()
        let repository = InvitationInboxRepositorySpy(invitations: [invitation])
        let viewModel = InvitationInboxViewModel(repository: repository)

        await viewModel.load()
        await viewModel.decline(invitation)

        XCTAssertEqual(repository.declinedTokens, [invitation.token])
        XCTAssertTrue(viewModel.invitations.isEmpty)
    }

    private func makeInvitation() -> EventInvitationInboxItem {
        EventInvitationInboxItem(
            id: UUID(),
            token: "invite-token",
            eventId: UUID(),
            eventName: "Поездка в Сочи",
            createdBy: UUID(),
            creatorName: "Алиса",
            expiresAt: Date().addingTimeInterval(3600),
            createdAt: Date()
        )
    }
}

private final class InvitationInboxRepositorySpy: InvitationInboxRepository {
    var invitations: [EventInvitationInboxItem]
    private(set) var acceptedTokens: [String] = []
    private(set) var declinedTokens: [String] = []

    init(invitations: [EventInvitationInboxItem]) {
        self.invitations = invitations
    }

    func listInvitations() async throws -> [EventInvitationInboxItem] {
        invitations
    }

    func acceptInvitation(token: String) async throws {
        acceptedTokens.append(token)
    }

    func declineInvitation(token: String) async throws {
        declinedTokens.append(token)
    }
}
