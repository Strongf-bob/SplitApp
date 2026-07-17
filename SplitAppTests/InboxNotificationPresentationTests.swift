import XCTest
@testable import SplitApp

final class InboxNotificationPresentationTests: XCTestCase {
    func testIncomingShowsUnreadSyncWarningWhenOffline() {
        let notifications = InboxNotificationPresentation.incoming(isConnected: false)

        XCTAssertEqual(notifications.count, 1)
        XCTAssertEqual(notifications.first?.title, "Нет подключения к интернету")
        XCTAssertEqual(
            notifications.first?.message,
            "Синхронизация недоступна. Мы обновим данные, когда соединение появится."
        )
        XCTAssertEqual(notifications.first?.systemImage, "wifi.slash")
        XCTAssertTrue(notifications.first?.isUnread == true)
    }

    func testIncomingHasNoSyncWarningWhenOnline() {
        XCTAssertTrue(InboxNotificationPresentation.incoming(isConnected: true).isEmpty)
    }
}
