import XCTest
@testable import SplitApp

final class SplitikMessageRequestTests: XCTestCase {
    func testEncodesProductionMessageContract() throws {
        let request = SplitikMessageRequest(message: "Помоги разделить ужин", sessionId: nil)

        let data = try JSONEncoder().encode(request)
        let payload = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        XCTAssertEqual(payload?["message"] as? String, "Помоги разделить ужин")
        XCTAssertEqual(payload?["mode"] as? String, "general")
        XCTAssertEqual(payload?["locale"] as? String, "ru-RU")
        XCTAssertEqual(payload?["timezone"] as? String, "Europe/Moscow")
    }
}
