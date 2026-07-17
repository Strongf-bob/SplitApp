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

    func testPaymentRejectsMixedValidAndInvalidItems() {
        let participant = Participant(name: "Алексей", initials: "А", color: .blue)
        let validItem = BillItem(name: "Ужин", amount: 1_500, assignedTo: [participant])
        let invalidItem = BillItem(name: "", amount: 0, assignedTo: [])

        XCTAssertFalse(
            BillViewModel.hasValidContent(
                title: "Ужин",
                items: [validItem, invalidItem]
            )
        )
    }

    func testViewModelReusesIdempotencyKeyAcrossSaveAttempts() {
        let dependencies = AppDependencies.preview
        let participant = Participant(name: "Алексей", initials: "А", color: .blue)
        let item = BillItem(name: "Ужин", amount: 1_500, assignedTo: [participant])
        let viewModel = BillViewModel(
            mode: .create(eventId: UUID(), scannedItems: [item], receiptImageJPEGData: nil),
            eventsRepository: dependencies.eventsRepository,
            receiptsRepository: dependencies.receiptsRepository,
            usersRepository: dependencies.usersRepository,
            networkMonitor: dependencies.networkMonitor
        )

        let first = viewModel.makeReceiptRequest(payerId: participant.id, items: [item])
        let second = viewModel.makeReceiptRequest(payerId: participant.id, items: [item])

        XCTAssertEqual(first.idempotencyKey, second.idempotencyKey)
    }

    func testManualPaymentItemUsesSelectedParticipants() {
        let dependencies = AppDependencies.preview
        let participant = Participant(name: "Алексей", initials: "А", color: .blue)
        let viewModel = BillViewModel(
            mode: .create(eventId: UUID(), scannedItems: [], receiptImageJPEGData: nil),
            eventsRepository: dependencies.eventsRepository,
            receiptsRepository: dependencies.receiptsRepository,
            usersRepository: dependencies.usersRepository,
            networkMonitor: dependencies.networkMonitor
        )

        viewModel.addItem(assignedTo: [participant])

        XCTAssertEqual(viewModel.items.count, 1)
        XCTAssertEqual(viewModel.items.first?.assignedTo.map(\.id), [participant.id])
    }

    func testEditorUsesPaymentTerminology() {
        let dependencies = AppDependencies.preview
        let viewModel = BillViewModel(
            mode: .edit(eventId: UUID(), receiptId: UUID()),
            eventsRepository: dependencies.eventsRepository,
            receiptsRepository: dependencies.receiptsRepository,
            usersRepository: dependencies.usersRepository,
            networkMonitor: dependencies.networkMonitor
        )

        XCTAssertEqual(viewModel.title, "Просмотр платежа")
    }
}
