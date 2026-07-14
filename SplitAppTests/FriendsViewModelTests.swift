import XCTest
import SwiftUI
@testable import SplitApp

@MainActor
final class FriendsViewModelTests: XCTestCase {
    func testReloadSeparatesAcceptedFriendsRequestsAndEventDebts() async {
        let currentUserId = UUID()
        let acceptedPeer = user(name: "Алиса")
        let incomingPeer = user(name: "Борис")
        let outgoingPeer = user(name: "Вера")
        let eventOnlyPeer = user(name: "Глеб")
        let eventId = UUID()

        let accepted = friendship(
            requesterId: currentUserId,
            addresseeId: acceptedPeer.id,
            status: .accepted,
            peer: acceptedPeer
        )
        let incoming = friendship(
            requesterId: incomingPeer.id,
            addresseeId: currentUserId,
            status: .requested,
            peer: incomingPeer
        )
        let outgoing = friendship(
            requesterId: currentUserId,
            addresseeId: outgoingPeer.id,
            status: .requested,
            peer: outgoingPeer
        )
        let friendships = FriendsRepositorySpy(friendships: [accepted, incoming, outgoing])
        let balances = BalancesRepositorySpy(balances: [
            EventBalance(
                eventId: eventId,
                debitorId: currentUserId,
                creditorId: eventOnlyPeer.id,
                amount: 320
            )
        ])
        let viewModel = FriendsViewModel(
            friendsRepository: friendships,
            usersRepository: UsersRepositorySpy(users: [acceptedPeer, eventOnlyPeer]),
            balancesRepository: balances,
            paymentsRepository: PaymentsRepositorySpy(),
            activeEventRepository: ActiveEventRepositorySpy(eventId: eventId),
            currentUserProvider: { self.currentUser(id: currentUserId) }
        )

        await viewModel.reload()

        XCTAssertEqual(viewModel.friends.map(\.id), [acceptedPeer.id])
        XCTAssertEqual(viewModel.incomingRequests.map(\.id), [incoming.id])
        XCTAssertEqual(viewModel.outgoingRequests.map(\.id), [outgoing.id])
        XCTAssertEqual(viewModel.activeDebts.map(\.friend.id), [eventOnlyPeer.id])
    }

    func testAcceptRequestReloadsFriendshipState() async {
        let currentUserId = UUID()
        let requester = user(name: "Алиса")
        let request = friendship(
            requesterId: requester.id,
            addresseeId: currentUserId,
            status: .requested,
            peer: requester
        )
        let repository = FriendsRepositorySpy(friendships: [request])
        let viewModel = FriendsViewModel(
            friendsRepository: repository,
            usersRepository: UsersRepositorySpy(users: []),
            balancesRepository: BalancesRepositorySpy(balances: []),
            paymentsRepository: PaymentsRepositorySpy(),
            activeEventRepository: ActiveEventRepositorySpy(eventId: nil),
            currentUserProvider: { self.currentUser(id: currentUserId) }
        )

        await viewModel.reload()
        await viewModel.accept(request)

        XCTAssertEqual(repository.acceptedIDs, [request.id])
        XCTAssertEqual(viewModel.friends.map(\.id), [requester.id])
        XCTAssertTrue(viewModel.incomingRequests.isEmpty)
    }

    func testCreateAndAcceptInviteReloadFriendships() async {
        let currentUserId = UUID()
        let recipient = user(name: "Борис")
        let repository = FriendsRepositorySpy(friendships: [])
        repository.createdInvite = FriendInvite(
            id: UUID(),
            creator: user(name: "Я"),
            token: "secure-token",
            inviteURL: URL(string: "splitapp://friend-invite/secure-token")!,
            expiresAt: Date().addingTimeInterval(900)
        )
        repository.preview = FriendInvitePreview(
            id: UUID(),
            creator: recipient,
            expiresAt: Date().addingTimeInterval(900)
        )
        repository.acceptedInviteFriendship = friendship(
            requesterId: currentUserId,
            addresseeId: recipient.id,
            status: .accepted,
            peer: recipient
        )
        let viewModel = FriendsViewModel(
            friendsRepository: repository,
            usersRepository: UsersRepositorySpy(users: []),
            balancesRepository: BalancesRepositorySpy(balances: []),
            paymentsRepository: PaymentsRepositorySpy(),
            activeEventRepository: ActiveEventRepositorySpy(eventId: nil),
            currentUserProvider: { self.currentUser(id: currentUserId) }
        )

        await viewModel.createFriendInvite()
        await viewModel.loadFriendInvite(token: "secure-token")
        await viewModel.acceptFriendInvite(token: "secure-token")

        XCTAssertEqual(viewModel.inviteShareURL?.absoluteString, "splitapp://friend-invite/secure-token")
        XCTAssertEqual(viewModel.pendingInvitePreview?.creator.id, recipient.id)
        XCTAssertEqual(repository.previewedTokens, ["secure-token"])
        XCTAssertEqual(repository.acceptedInviteTokens, ["secure-token"])
        XCTAssertEqual(viewModel.friends.map(\.id), [recipient.id])
    }

    private func user(name: String) -> User {
        User(id: UUID(), name: name, phoneNumber: "79000000000")
    }

    private func currentUser(id: UUID) -> CurrentUser {
        CurrentUser(
            id: id,
            name: "Я",
            initials: "Я",
            avatarURL: nil,
            color: .green,
            email: nil,
            phoneNumber: nil
        )
    }

    private func friendship(
        requesterId: UUID,
        addresseeId: UUID,
        status: FriendshipStatus,
        peer: User
    ) -> Friendship {
        Friendship(
            id: UUID(),
            requesterId: requesterId,
            addresseeId: addresseeId,
            status: status,
            peer: peer
        )
    }
}

private final class FriendsRepositorySpy: FriendsRepository {
    var friendships: [Friendship]
    private(set) var acceptedIDs: [UUID] = []
    var createdInvite: FriendInvite?
    var preview: FriendInvitePreview?
    var acceptedInviteFriendship: Friendship?
    private(set) var previewedTokens: [String] = []
    private(set) var acceptedInviteTokens: [String] = []

    init(friendships: [Friendship]) {
        self.friendships = friendships
    }

    func listFriendships() async throws -> [Friendship] {
        friendships
    }

    func acceptFriendship(id: UUID) async throws -> Friendship {
        acceptedIDs.append(id)
        guard let index = friendships.firstIndex(where: { $0.id == id }) else {
            throw TestError.notFound
        }
        let accepted = Friendship(
            id: friendships[index].id,
            requesterId: friendships[index].requesterId,
            addresseeId: friendships[index].addresseeId,
            status: .accepted,
            peer: friendships[index].peer
        )
        friendships[index] = accepted
        return accepted
    }

    func rejectFriendship(id: UUID) async throws -> Friendship {
        throw TestError.notImplemented
    }

    func removeFriendship(id: UUID) async throws {}

    func createFriendInvite() async throws -> FriendInvite {
        guard let createdInvite else { throw TestError.notImplemented }
        return createdInvite
    }

    func previewFriendInvite(token: String) async throws -> FriendInvitePreview {
        previewedTokens.append(token)
        guard let preview else { throw TestError.notImplemented }
        return preview
    }

    func acceptFriendInvite(token: String) async throws -> Friendship {
        acceptedInviteTokens.append(token)
        guard let acceptedInviteFriendship else { throw TestError.notImplemented }
        friendships.append(acceptedInviteFriendship)
        return acceptedInviteFriendship
    }
}

private final class UsersRepositorySpy: UsersRepository {
    let users: [User]

    init(users: [User]) {
        self.users = users
    }

    func listUsers() async throws -> [User] { users }
    func getCachedUsers() async throws -> [User] { users }
}

private final class BalancesRepositorySpy: BalancesRepository {
    let balances: [EventBalance]

    init(balances: [EventBalance]) {
        self.balances = balances
    }

    func getEventBalances(eventId: UUID) async throws -> [EventBalance] { balances }
    func getCachedEventBalances(eventId: UUID) async throws -> [EventBalance] { balances }
}

private final class PaymentsRepositorySpy: PaymentsRepository {
    func listPayments(eventId: UUID) async throws -> [Payment] { [] }
    func createPayment(eventId: UUID, _ command: CreatePaymentCommand) async throws -> Payment { throw TestError.notImplemented }
    func updatePayment(id: UUID, _ command: UpdatePaymentCommand) async throws -> Payment { throw TestError.notImplemented }
}

private final class ActiveEventRepositorySpy: ActiveEventRepository {
    let eventId: UUID?

    init(eventId: UUID?) {
        self.eventId = eventId
    }

    func getActiveEventId() async -> UUID? { eventId }
    func setActiveEventId(_ eventId: UUID) async {}
    func clearActiveEventId() async {}
}

private enum TestError: Error {
    case notFound
    case notImplemented
}
