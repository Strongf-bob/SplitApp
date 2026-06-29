import Foundation

struct PageResponse<T: Decodable>: Decodable {
    let items: [T]
    let limit: Int
    let offset: Int
    let total: Int

    init(items: [T], limit: Int, offset: Int, total: Int) {
        self.items = items
        self.limit = limit
        self.offset = offset
        self.total = total
    }

    var nextOffset: Int {
        offset + items.count
    }

    var hasMore: Bool {
        nextOffset < total
    }
}
