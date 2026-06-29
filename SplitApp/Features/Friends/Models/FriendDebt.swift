import Foundation

enum DebtType {
    case owes
    case owedBy
}

struct FriendDebt: Identifiable {
    let id: UUID
    let eventId: UUID
    let friend: Friend
    let amount: Decimal
    let type: DebtType
    let senderId: UUID
    let receiverId: UUID
    let canSettle: Bool

    init(
        id: UUID = UUID(),
        eventId: UUID,
        friend: Friend,
        amount: Decimal,
        type: DebtType,
        senderId: UUID,
        receiverId: UUID,
        canSettle: Bool
    ) {
        self.id = id
        self.eventId = eventId
        self.friend = friend
        self.amount = amount
        self.type = type
        self.senderId = senderId
        self.receiverId = receiverId
        self.canSettle = canSettle
    }
}
