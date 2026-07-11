import XCTest
@testable import SplitApp

@MainActor
final class EventsHomeViewModelTests: XCTestCase {
    func testParticipantsForLocalStoreDeduplicatesUsersWithTheSameID() {
        let sharedID = UUID()
        let event = Event(
            name: "Поездка",
            participants: [User(id: sharedID, name: "Илья", phoneNumber: "yandex:1")],
            users: [
                User(id: sharedID, name: "Илья", phoneNumber: "yandex:1"),
                User(id: UUID(), name: "Маша", phoneNumber: "yandex:2")
            ]
        )

        let participants = EventsHomeViewModel.participantsForLocalStore(from: event)

        XCTAssertEqual(participants.map(\.id), [sharedID, event.users[1].id])
    }
}
