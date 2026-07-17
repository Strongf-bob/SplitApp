import SwiftUI
import XCTest
@testable import SplitApp

@MainActor
final class PaymentEditorPresentationTests: XCTestCase {
    func testEmptyPaymentCannotBeCreated() {
        XCTAssertFalse(BillViewModel.hasValidContent(title: "", items: []))
    }

    func testPaymentRequiresTitleAmountAndAssignedParticipant() {
        let participant = Participant(name: "Алексей", initials: "А", color: .blue)
        let completeItem = BillItem(name: "Ужин", amount: 1_500, assignedTo: [participant])

        XCTAssertFalse(BillViewModel.hasValidContent(title: "", items: [completeItem]))
        XCTAssertFalse(BillViewModel.hasValidContent(
            title: "Ужин",
            items: [BillItem(name: "Ужин", amount: 1_500)]
        ))
        XCTAssertTrue(BillViewModel.hasValidContent(title: "Ужин", items: [completeItem]))
    }
}
