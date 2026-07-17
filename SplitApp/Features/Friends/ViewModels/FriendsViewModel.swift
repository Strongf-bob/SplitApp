import Combine
import Foundation
import SwiftUI

@MainActor
class FriendsViewModel: ObservableObject {
    @Published var friends: [Friend] = []
    @Published var debts: [FriendDebt] = []
    @Published private(set) var incomingRequests: [Friendship] = []
    @Published private(set) var outgoingRequests: [Friendship] = []
    @Published var searchText: String = ""
    @Published var friendPhone: String = "" {
        didSet {
            if friendPhone != oldValue {
                foundUser = nil
                friendSearchMessage = nil
            }
        }
    }
    @Published private(set) var foundUser: User?
    @Published private(set) var isSearchingFriend = false
    @Published private(set) var isSendingFriendRequest = false
    @Published private(set) var friendSearchMessage: String?
    @Published private(set) var isLoading = false
    @Published private(set) var settlingDebtIds: Set<UUID> = []
    @Published private(set) var updatingFriendshipIds: Set<UUID> = []
    @Published private(set) var errorMessage: String?
    @Published private(set) var offlineMessage: String?

    private let friendsRepository: any FriendsRepository
    private let usersRepository: any UsersRepository
    private let balancesRepository: any BalancesRepository
    private let paymentsRepository: any PaymentsRepository
    private let activeEventRepository: any ActiveEventRepository
    private let currentUserProvider: @MainActor () -> CurrentUser?
    private var hasLoaded = false

    var activeDebts: [FriendDebt] {
        debts.filter { $0.amount > 0 }
    }

    var filteredFriends: [Friend] {
        if searchText.isEmpty {
            return friends
        }
        return friends.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    init(
        friendsRepository: any FriendsRepository,
        usersRepository: any UsersRepository,
        balancesRepository: any BalancesRepository,
        paymentsRepository: any PaymentsRepository,
        activeEventRepository: any ActiveEventRepository,
        currentUserProvider: @escaping @MainActor () -> CurrentUser? = { CurrentUserStore.shared.user }
    ) {
        self.friendsRepository = friendsRepository
        self.usersRepository = usersRepository
        self.balancesRepository = balancesRepository
        self.paymentsRepository = paymentsRepository
        self.activeEventRepository = activeEventRepository
        self.currentUserProvider = currentUserProvider
    }

    func load() async {
        guard !hasLoaded else { return }
        hasLoaded = true
        await reload()
    }

    func reload() async {
        isLoading = true
        errorMessage = nil
        offlineMessage = nil
        defer { isLoading = false }

        do {
            guard let currentUser = currentUserProvider() else {
                friends = []
                debts = []
                incomingRequests = []
                outgoingRequests = []
                errorMessage = "Не удалось определить текущего пользователя. Войдите в аккаунт еще раз."
                return
            }

            let friendships = try await friendsRepository.listFriendships()
            apply(friendships: friendships, currentUserId: currentUser.id)

            guard let eventId = await activeEventRepository.getActiveEventId() else {
                debts = []
                offlineMessage = "Выберите событие, чтобы увидеть долги по нему."
                return
            }

            async let usersFetch = usersRepository.listUsers()
            async let balancesFetch = balancesRepository.getEventBalances(eventId: eventId)

            let users = try await usersFetch
            let balances = try await balancesFetch
            let friendsById = Dictionary(uniqueKeysWithValues: users.map { ($0.id, Self.mapUserToFriend($0)) })

            debts = Self.mapBalancesToDebts(
                balances,
                eventId: eventId,
                currentUserId: currentUser.id,
                friendsById: friendsById
            )
        } catch {
            errorMessage = "Не удалось загрузить друзей и долги. Проверьте интернет и попробуйте снова."
            debts = []
        }
    }

    func accept(_ friendship: Friendship) async {
        await update(friendship) {
            _ = try await self.friendsRepository.acceptFriendship(id: friendship.id)
        }
    }

    func reject(_ friendship: Friendship) async {
        await update(friendship) {
            _ = try await self.friendsRepository.rejectFriendship(id: friendship.id)
        }
    }

    func remove(_ friendship: Friendship) async {
        await update(friendship) {
            try await self.friendsRepository.removeFriendship(id: friendship.id)
        }
    }

    func searchRegisteredUser() async {
        let normalizedPhone = SearchUsersEndpoint.normalizePhone(friendPhone)
        guard normalizedPhone.count >= 11 else {
            foundUser = nil
            friendSearchMessage = "Введите полный номер телефона"
            return
        }

        isSearchingFriend = true
        foundUser = nil
        friendSearchMessage = nil
        defer { isSearchingFriend = false }

        do {
            let currentUserId = currentUserProvider()?.id
            foundUser = try await usersRepository.searchUsers(query: friendPhone)
                .first { $0.id != currentUserId }
            if foundUser == nil {
                friendSearchMessage = "Пользователь с таким номером не найден"
            }
        } catch is CancellationError {
            return
        } catch {
            friendSearchMessage = "Не удалось выполнить поиск. Проверьте интернет и попробуйте снова."
        }
    }

    func sendFriendRequest() async {
        guard let foundUser, !isSendingFriendRequest else { return }
        isSendingFriendRequest = true
        friendSearchMessage = nil
        defer { isSendingFriendRequest = false }

        do {
            _ = try await friendsRepository.createFriendRequest(userId: foundUser.id)
            self.foundUser = nil
            friendPhone = ""
            friendSearchMessage = "Заявка отправлена"
            await reload()
        } catch {
            friendSearchMessage = "Не удалось отправить заявку. Возможно, она уже существует."
        }
    }

    func settleDebt(_ debt: FriendDebt) async {
        guard !settlingDebtIds.contains(debt.id) else { return }
        guard debt.canSettle else {
            errorMessage = "Этот долг должен закрыть другой участник."
            return
        }

        settlingDebtIds.insert(debt.id)
        errorMessage = nil
        defer {
            settlingDebtIds.remove(debt.id)
        }

        do {
            let command = CreatePaymentCommand(
                senderId: debt.senderId,
                receiverId: debt.receiverId,
                amount: NSDecimalNumber(decimal: debt.amount).doubleValue
            )
            _ = try await paymentsRepository.createPayment(eventId: debt.eventId, command)
            await reload()
        } catch {
            errorMessage = "Не удалось закрыть долг. Проверьте интернет и попробуйте снова."
        }
    }
}

private extension FriendsViewModel {
    static let avatarColors: [Color] = [
        Color(hex: "#FFB5A7"),
        Color(hex: "#A7D8FF"),
        Color(hex: "#D4C5F9"),
        Color(hex: "#C9F7F5"),
        Color(hex: "#FADCB6"),
        Color(hex: "#C8F4CC")
    ]

    static func mapUserToFriend(_ user: User) -> Friend {
        Friend(
            id: user.id,
            name: user.name,
            initials: makeInitials(from: user.name),
            color: makeStableColor(for: user.id),
            avatarURL: user.avatarURL
        )
    }

    func apply(friendships: [Friendship], currentUserId: UUID) {
        friends = friendships.compactMap { friendship in
            guard friendship.status == .accepted,
                  let peer = friendship.peer
            else {
                return nil
            }
            return Self.mapUserToFriend(peer)
        }
        .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }

        incomingRequests = friendships.filter {
            $0.status == .requested && $0.addresseeId == currentUserId && $0.peer != nil
        }
        outgoingRequests = friendships.filter {
            $0.status == .requested && $0.requesterId == currentUserId && $0.peer != nil
        }
    }

    func update(
        _ friendship: Friendship,
        operation: () async throws -> Void
    ) async {
        guard !updatingFriendshipIds.contains(friendship.id) else { return }
        updatingFriendshipIds.insert(friendship.id)
        errorMessage = nil
        defer { updatingFriendshipIds.remove(friendship.id) }

        do {
            try await operation()
            await reload()
        } catch {
            errorMessage = "Не удалось обновить заявку в друзья. Проверьте интернет и попробуйте снова."
        }
    }

    static func mapBalancesToDebts(
        _ balances: [EventBalance],
        eventId: UUID,
        currentUserId: UUID,
        friendsById: [UUID: Friend]
    ) -> [FriendDebt] {
        balances.compactMap { balance in
            guard balance.amount > 0 else { return nil }

            if balance.debitorId == currentUserId,
               let friend = friendsById[balance.creditorId] {
                return FriendDebt(
                    id: balance.creditorId,
                    eventId: eventId,
                    friend: friend,
                    amount: Decimal(balance.amount),
                    type: .owes,
                    senderId: currentUserId,
                    receiverId: balance.creditorId,
                    canSettle: true
                )
            }

            if balance.creditorId == currentUserId,
               let friend = friendsById[balance.debitorId] {
                return FriendDebt(
                    id: balance.debitorId,
                    eventId: eventId,
                    friend: friend,
                    amount: Decimal(balance.amount),
                    type: .owedBy,
                    senderId: balance.debitorId,
                    receiverId: currentUserId,
                    canSettle: false
                )
            }

            return nil
        }
        .sorted { lhs, rhs in
            if lhs.amount == rhs.amount {
                return lhs.friend.name.localizedCaseInsensitiveCompare(rhs.friend.name) == .orderedAscending
            }
            return lhs.amount > rhs.amount
        }
    }

    static func makeInitials(from name: String) -> String {
        let parts = name
            .split(separator: " ")
            .filter { !$0.isEmpty }

        if parts.count >= 2 {
            let first = String(parts[0].prefix(1))
            let second = String(parts[1].prefix(1))
            return (first + second).uppercased()
        }

        return String(name.prefix(2)).uppercased()
    }

    static func makeStableColor(for id: UUID) -> Color {
        let normalized = id.uuidString.replacingOccurrences(of: "-", with: "")
        let checksum = normalized.unicodeScalars.reduce(0) { partialResult, scalar in
            partialResult + Int(scalar.value)
        }
        let index = checksum % avatarColors.count
        return avatarColors[index]
    }
}
