import Combine
import Foundation
import SwiftUI

@MainActor
class FriendsViewModel: ObservableObject {
    @Published var friends: [Friend] = []
    @Published var debts: [FriendDebt] = []
    @Published var searchText: String = ""
    @Published private(set) var isLoading = false
    @Published private(set) var settlingDebtIds: Set<UUID> = []
    @Published private(set) var errorMessage: String?
    @Published private(set) var offlineMessage: String?

    private let friendsRepository: any FriendsRepository
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
        balancesRepository: any BalancesRepository,
        paymentsRepository: any PaymentsRepository,
        activeEventRepository: any ActiveEventRepository,
        currentUserProvider: @escaping @MainActor () -> CurrentUser? = { CurrentUserStore.shared.user }
    ) {
        self.friendsRepository = friendsRepository
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
                errorMessage = "Не удалось определить текущего пользователя. Войдите в аккаунт еще раз."
                return
            }

            guard let eventId = await activeEventRepository.getActiveEventId() else {
                let users = try await friendsRepository.listRemoteFriends()
                friends = users
                    .filter { $0.id != currentUser.id }
                    .map(Self.mapUserToFriend)
                debts = []
                offlineMessage = "Выберите событие, чтобы увидеть долги по нему."
                return
            }

            async let usersFetch = friendsRepository.listRemoteFriends()
            async let balancesFetch = balancesRepository.getEventBalances(eventId: eventId)

            let users = try await usersFetch
            let balances = try await balancesFetch
            let friendsById = Dictionary(uniqueKeysWithValues: users.map { ($0.id, Self.mapUserToFriend($0)) })

            friends = users
                .filter { $0.id != currentUser.id }
                .map(Self.mapUserToFriend)
            debts = Self.mapBalancesToDebts(
                balances,
                eventId: eventId,
                currentUserId: currentUser.id,
                friendsById: friendsById
            )
        } catch {
            errorMessage = "Не удалось загрузить друзей и долги. Проверьте интернет и попробуйте снова."
            friends = []
            debts = []
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
