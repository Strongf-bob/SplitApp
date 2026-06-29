import Foundation

struct ReceiptDTO: Codable, Identifiable {
    let id: UUID
    let eventId: UUID
    let payerId: UUID
    let title: String?
    let totalAmount: Double
    let createdAt: Date
    let updatedAt: Date
    let items: [ReceiptItemDTO]
    let imageUrl: String?

    enum CodingKeys: String, CodingKey {
        case id, title, items
        case eventId = "event_id"
        case payerId = "payer_id"
        case totalAmount = "total_amount"
        case totalAmountKopecks = "total_amount_kopecks"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case imageUrl = "image_url"
    }

    init(
        id: UUID,
        eventId: UUID,
        payerId: UUID,
        title: String?,
        totalAmount: Double,
        createdAt: Date,
        updatedAt: Date,
        items: [ReceiptItemDTO],
        imageUrl: String?
    ) {
        self.id = id
        self.eventId = eventId
        self.payerId = payerId
        self.title = title
        self.totalAmount = totalAmount
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.items = items
        self.imageUrl = imageUrl
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        eventId = try container.decode(UUID.self, forKey: .eventId)
        payerId = try container.decode(UUID.self, forKey: .payerId)
        title = try container.decodeIfPresent(String.self, forKey: .title)
        if let totalAmountKopecks = try container.decodeIfPresent(Int.self, forKey: .totalAmountKopecks) {
            totalAmount = Double(totalAmountKopecks) / 100
        } else {
            totalAmount = try container.decodeLosslessDouble(forKey: .totalAmount)
        }
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        items = try container.decode([ReceiptItemDTO].self, forKey: .items)
        imageUrl = try container.decodeIfPresent(String.self, forKey: .imageUrl)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(eventId, forKey: .eventId)
        try container.encode(payerId, forKey: .payerId)
        try container.encodeIfPresent(title, forKey: .title)
        try container.encode(totalAmount, forKey: .totalAmount)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
        try container.encode(items, forKey: .items)
        try container.encodeIfPresent(imageUrl, forKey: .imageUrl)
    }
}

struct ReceiptItemDTO: Codable, Identifiable {
    let id: UUID
    let receiptId: UUID
    let name: String?
    let cost: Double
    let shareItems: [ShareItemDTO]

    enum CodingKeys: String, CodingKey {
        case id, name, cost
        case costKopecks = "cost_kopecks"
        case receiptId = "receipt_id"
        case shareItems = "share_items"
    }

    init(
        id: UUID,
        receiptId: UUID,
        name: String?,
        cost: Double,
        shareItems: [ShareItemDTO]
    ) {
        self.id = id
        self.receiptId = receiptId
        self.name = name
        self.cost = cost
        self.shareItems = shareItems
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let id = try container.decode(UUID.self, forKey: .id)
        let receiptId = try container.decode(UUID.self, forKey: .receiptId)
        let name = try container.decodeIfPresent(String.self, forKey: .name)
        let cost: Double
        if let costKopecks = try container.decodeIfPresent(Int.self, forKey: .costKopecks) {
            cost = Double(costKopecks) / 100
        } else {
            cost = try container.decodeLosslessDouble(forKey: .cost)
        }

        if let userIds = try? container.decode([UUID].self, forKey: .shareItems) {
            self.init(
                id: id,
                receiptId: receiptId,
                name: name,
                cost: cost,
                shareItems: Self.makeNormalizedShareItems(
                    for: userIds,
                    receiptItemId: id
                )
            )
            return
        }

        self.init(
            id: id,
            receiptId: receiptId,
            name: name,
            cost: cost,
            shareItems: try container.decode([ShareItemDTO].self, forKey: .shareItems)
        )
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(receiptId, forKey: .receiptId)
        try container.encodeIfPresent(name, forKey: .name)
        try container.encode(cost, forKey: .cost)
        try container.encode(shareItems, forKey: .shareItems)
    }

    private static func makeNormalizedShareItems(
        for userIds: [UUID],
        receiptItemId: UUID
    ) -> [ShareItemDTO] {
        guard !userIds.isEmpty else { return [] }

        let scale = 1_000_000
        let baseScaled = scale / userIds.count
        let lastScaled = scale - baseScaled * (userIds.count - 1)

        return userIds.enumerated().map { index, userId in
            ShareItemDTO(
                id: UUID(),
                receiptItemId: receiptItemId,
                userId: userId,
                shareValue: Double(index == userIds.count - 1 ? lastScaled : baseScaled) / Double(scale)
            )
        }
    }
}

struct ShareItemDTO: Codable, Identifiable {
    let id: UUID
    let receiptItemId: UUID
    let userId: UUID
    let shareValue: Double

    enum CodingKeys: String, CodingKey {
        case id
        case receiptItemId = "receipt_item_id"
        case userId = "user_id"
        case shareValue = "share_value"
    }

    init(id: UUID, receiptItemId: UUID, userId: UUID, shareValue: Double) {
        self.id = id
        self.receiptItemId = receiptItemId
        self.userId = userId
        self.shareValue = shareValue
    }

    // Server returns share_items as plain UUID strings (e.g. ["uuid1", "uuid2"])
    init(from decoder: Decoder) throws {
        if let userId = try? decoder.singleValueContainer().decode(UUID.self) {
            self.userId = userId
            self.id = UUID()
            self.receiptItemId = UUID()
            self.shareValue = 1.0
        } else {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.id = try container.decode(UUID.self, forKey: .id)
            self.receiptItemId = try container.decode(UUID.self, forKey: .receiptItemId)
            self.userId = try container.decode(UUID.self, forKey: .userId)
            self.shareValue = try container.decodeLosslessDouble(forKey: .shareValue)
        }
    }
}

struct CreateReceiptRequest: Encodable {
    let payerId: UUID
    let title: String?
    let totalAmount: Double
    let items: [CreateReceiptItemRequest]

    enum CodingKeys: String, CodingKey {
        case title, items
        case payerId = "payer_id"
        case totalAmountKopecks = "total_amount_kopecks"
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(payerId, forKey: .payerId)
        try container.encodeIfPresent(title, forKey: .title)
        try container.encode(Int((totalAmount * 100).rounded()), forKey: .totalAmountKopecks)
        try container.encode(items, forKey: .items)
    }
}

struct CreateReceiptItemRequest: Encodable {
    let name: String?
    let cost: Double
    let shareItems: [CreateShareItemRequest]

    enum CodingKeys: String, CodingKey {
        case name
        case costKopecks = "cost_kopecks"
        case splitMode = "split_mode"
        case shareItems = "share_items"
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(name, forKey: .name)
        try container.encode(Int((cost * 100).rounded()), forKey: .costKopecks)
        try container.encode("custom", forKey: .splitMode)
        try container.encode(shareItems, forKey: .shareItems)
    }
}

struct CreateShareItemRequest: Encodable {
    let userId: UUID
    let shareValue: Double

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case shareValue = "share_value"
    }
}

struct UpdateReceiptRequest: Encodable {
    let title: String?
    let totalAmount: Double?
    let items: [CreateReceiptItemRequest]?

    enum CodingKeys: String, CodingKey {
        case title, items
        case totalAmountKopecks = "total_amount_kopecks"
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(title, forKey: .title)
        if let totalAmount {
            try container.encode(Int((totalAmount * 100).rounded()), forKey: .totalAmountKopecks)
        }
        try container.encodeIfPresent(items, forKey: .items)
    }
}

struct ReceiptImageUploadResponseDTO: Codable {
    let imageUrl: String

    enum CodingKeys: String, CodingKey {
        case imageUrl = "image_url"
    }
}

struct ReceiptImagePresignedURLResponseDTO: Codable {
    let imageUrl: String

    enum CodingKeys: String, CodingKey {
        case imageUrl = "image_url"
    }
}
