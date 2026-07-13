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

    func testDecodesPendingEventBundleDraft() throws {
        let data = Data("""
        {
          "session_id": "11111111-1111-1111-1111-111111111111",
          "assistant_message": "Подготовил план.",
          "drafts": [{
            "id": "22222222-2222-2222-2222-222222222222",
            "type": "create_event_bundle",
            "status": "pending",
            "payload": {
              "name": "Поездка в такси",
              "participant_ids": ["33333333-3333-3333-3333-333333333333"],
              "receipts": [{"title": "Такси", "amount_kopecks": 20000}]
            }
          }]
        }
        """.utf8)

        let response = try JSONDecoder().decode(SplitikMessageResponse.self, from: data)

        XCTAssertEqual(response.drafts.first?.type, "create_event_bundle")
        XCTAssertEqual(response.drafts.first?.status, "pending")
        XCTAssertEqual(response.drafts.first?.eventPlan?.name, "Поездка в такси")
        XCTAssertEqual(response.drafts.first?.eventPlan?.receipts.first?.amountKopecks, 20000)
    }

    func testRendersAssistantMarkdownWithoutSyntaxMarkers() {
        let rendered = SplitikMarkdownRenderer.render("**Итого**\\n\\n- Такси")

        XCTAssertEqual(String(rendered.characters), "Итого\\n\\n- Такси")
    }
}
