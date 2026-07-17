import Foundation

struct CreateReceiptCommand {
    let payerId: UUID
    let title: String?
    let totalAmount: Double
    let items: [CreateReceiptItemCommand]
    let receiptImageJPEGData: Data?
    let idempotencyKey: String

    init(
        payerId: UUID,
        title: String?,
        totalAmount: Double,
        items: [CreateReceiptItemCommand],
        receiptImageJPEGData: Data?,
        idempotencyKey: String = UUID().uuidString
    ) {
        self.payerId = payerId
        self.title = title
        self.totalAmount = totalAmount
        self.items = items
        self.receiptImageJPEGData = receiptImageJPEGData
        self.idempotencyKey = idempotencyKey
    }
}

struct CreateReceiptItemCommand {
    let name: String?
    let cost: Double
    let shareItems: [CreateShareItemCommand]
}

struct CreateShareItemCommand {
    let userId: UUID
    let shareValue: Double
}

struct UpdateReceiptCommand {
    let title: String?
    let totalAmount: Double?
    let items: [CreateReceiptItemCommand]?
}
