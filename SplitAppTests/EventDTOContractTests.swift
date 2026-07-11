import XCTest
@testable import SplitApp

final class EventDTOContractTests: XCTestCase {
    func testDecodesProductionEventWithParticipantMemberships() throws {
        let data = Data("""
        {
          "id":"7de59471-0a10-4e7e-b39d-028352908dfa",
          "creator_id":"727b23af-6e81-4aba-8542-c81f0c18635b",
          "name":"Поездка в такси",
          "is_closed":false,
          "participants":[{
            "id":"44d78871-155b-45ed-b121-7abc4d89facd",
            "event_id":"7de59471-0a10-4e7e-b39d-028352908dfa",
            "user_id":"727b23af-6e81-4aba-8542-c81f0c18635b",
            "role":"creator",
            "status":"active",
            "joined_at":"2026-07-08T21:14:11.115000Z",
            "removed_at":null
          }],
          "created_at":"2026-07-08T21:14:11.115000Z",
          "updated_at":"2026-07-08T21:14:11.115000Z"
        }
        """.utf8)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let dto = try decoder.decode(EventDTO.self, from: data)

        XCTAssertEqual(dto.participantUserIds.count, 1)
        XCTAssertEqual(dto.participantUserIds.first?.uuidString.lowercased(), "727b23af-6e81-4aba-8542-c81f0c18635b")
    }
}
