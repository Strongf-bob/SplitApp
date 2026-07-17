import SwiftUI

struct BillEntryView: View {
    @StateObject private var viewModel: BillViewModel
    @State private var receiptViewModel = ReceiptViewModel()
    @State private var selectedParticipants: [Participant] = []
    @State private var showsParticipantSheet = false
    @State private var showsReceiptFlow = false
    @State private var receiptPath: [ReceiptFlowStep] = []
    @State private var showsSplitik = false
    @State private var assignmentItemID: UUID?
    @FocusState private var isTitleFocused: Bool
    @Environment(\.dismiss) private var dismiss

    init(viewModel: BillViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.white.ignoresSafeArea()

                if viewModel.isLoading, viewModel.items.isEmpty {
                    ProgressView("Загрузка платежа...")
                } else if let error = viewModel.loadErrorMessage, viewModel.items.isEmpty {
                    loadError(error)
                } else {
                    editor
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .task {
                await viewModel.load()
                selectedParticipants = uniqueAssignedParticipants
            }
            .sheet(isPresented: $showsParticipantSheet) {
                ParticipantPickerSheet(
                    participants: viewModel.participants,
                    selectedParticipants: selectedParticipants,
                    onToggle: toggleParticipant,
                    onDone: {
                        if let assignmentItemID {
                            viewModel.updateItem(
                                id: assignmentItemID,
                                assignedTo: selectedParticipants
                            )
                        } else {
                            viewModel.assignParticipantsToAllItems(selectedParticipants)
                        }
                        self.assignmentItemID = nil
                        showsParticipantSheet = false
                    }
                )
                .presentationDetents([.medium, .large])
                .presentationCornerRadius(SplitAppDesignTokens.modalCornerRadius)
            }
            .fullScreenCover(isPresented: $showsReceiptFlow, onDismiss: { receiptPath = [] }) {
                receiptFlow
            }
            .fullScreenCover(isPresented: $showsSplitik) {
                SplitikChatView(
                    initialDraft: splitikDraft,
                    onBack: { showsSplitik = false }
                )
            }
        }
    }
}

private extension BillEntryView {
    var editor: some View {
        VStack(spacing: 0) {
            SplitAppModalHeader(
                title: viewModel.title,
                onClose: { dismiss() }
            )
            .padding(.horizontal, 16)
            .padding(.top, 8)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 12) {
                    titleField

                    SplitAppActionButton(
                        title: "Добавить чек",
                        isEnabled: !viewModel.isReadOnly && viewModel.items.isEmpty,
                        action: openReceiptScanner
                    )

                    SplitAppActionButton(
                        title: "Добавить позицию вручную",
                        isEnabled: !viewModel.isReadOnly,
                        action: {
                            viewModel.addItem(assignedTo: selectedParticipants)
                        }
                    )

                    SplitAppActionButton(
                        title: selectedParticipants.isEmpty ? "Добавить друзей" : "Добавить друзей · \(selectedParticipants.count)",
                        isEnabled: !viewModel.isReadOnly,
                        action: {
                            assignmentItemID = nil
                            selectedParticipants = uniqueAssignedParticipants
                            showsParticipantSheet = true
                        }
                    )

                    SplitAppActionButton(
                        title: viewModel.saveButtonTitle,
                        isEnabled: viewModel.canSave,
                        action: saveAndDismiss
                    )

                    SplitAppActionButton(
                        title: "Создать со Сплитиком",
                        isEnabled: !viewModel.isReadOnly && viewModel.items.isEmpty,
                        action: { showsSplitik = true }
                    )

                    if !viewModel.items.isEmpty {
                        receiptSummary
                    }

                    if let message = viewModel.statusMessage {
                        Text(message)
                            .font(.footnote.weight(.medium))
                            .foregroundStyle(viewModel.saveErrorMessage == nil ? AppTheme.textSecondary : Color.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    if let notice = viewModel.saveNoticeMessage {
                        Text(notice)
                            .font(.footnote.weight(.medium))
                            .foregroundStyle(AppTheme.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        SplitAppActionButton(
                            title: viewModel.isSaving ? "Загружаем фото..." : "Повторить загрузку фото",
                            isEnabled: viewModel.canRetryReceiptImageUpload,
                            action: retryImageUploadAndDismiss
                        )

                        Button("Готово без фото") { dismiss() }
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(AppTheme.pdfPrimaryBlue)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal, 32)
                .padding(.top, 18)
                .padding(.bottom, 40)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .overlay(alignment: .top) {
            Capsule()
                .fill(Color(hex: "#CCCCCC"))
                .frame(width: 36, height: 5)
                .padding(.top, 5)
                .accessibilityHidden(true)
        }
    }

    var titleField: some View {
        VStack(alignment: .leading, spacing: 9) {
            Text("Введите название платежа")
                .font(.system(size: 20, weight: .regular))
                .foregroundStyle(AppTheme.textPrimary)

            TextField("Название платежа", text: $viewModel.receiptTitle)
                .font(.system(size: 17, weight: .regular))
                .foregroundStyle(AppTheme.textPrimary)
                .focused($isTitleFocused)
                .disabled(viewModel.isReadOnly)
                .textInputAutocapitalization(.sentences)
                .submitLabel(.done)
                .frame(height: 57)
                .padding(.horizontal, 25)
                .overlay {
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(isTitleFocused ? AppTheme.pdfPrimaryBlue : AppTheme.textSecondary, lineWidth: 1)
                }
        }
    }

    var receiptSummary: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Позиции платежа")
                    .font(AppTypography.pdfCardTitle)
                Spacer()
                Text(NSDecimalNumber(decimal: viewModel.total).stringValue + " ₽")
                    .font(AppTypography.pdfCardTitle)
                    .monospacedDigit()
            }

            ForEach(viewModel.items) { item in
                BillItemRow(
                    item: item,
                    isReadOnly: viewModel.isReadOnly,
                    onAssign: {
                        assignmentItemID = item.id
                        selectedParticipants = item.assignedTo
                        showsParticipantSheet = true
                    },
                    onDelete: { viewModel.removeItem(id: item.id) },
                    onUpdate: { name, amount in
                        viewModel.updateItem(id: item.id, name: name, amount: amount)
                    }
                )
            }

            if !viewModel.isReadOnly {
                Button {
                    viewModel.addItem(assignedTo: selectedParticipants)
                } label: {
                    Label("Добавить позицию", systemImage: "plus.circle.fill")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(AppTheme.pdfPrimaryBlue)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(18)
        .background(AppTheme.disabledSurface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    func loadError(_ message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 40))
                .foregroundStyle(.orange)
            Text(message)
                .font(.body)
                .multilineTextAlignment(.center)
            SplitAppActionButton(title: "Закрыть", action: { dismiss() })
        }
        .padding(32)
    }

    var uniqueAssignedParticipants: [Participant] {
        var seen = Set<UUID>()
        return viewModel.items.flatMap(\.assignedTo).filter { seen.insert($0.id).inserted }
    }

    func toggleParticipant(_ participant: Participant) {
        if selectedParticipants.contains(where: { $0.id == participant.id }) {
            selectedParticipants.removeAll { $0.id == participant.id }
        } else {
            selectedParticipants.append(participant)
        }
    }

    func openReceiptScanner() {
        receiptPath = []
        showsReceiptFlow = true
    }

    var receiptFlow: some View {
        NavigationStack(path: $receiptPath) {
            CameraView(viewModel: receiptViewModel) {
                receiptPath.append(.preview)
            }
            .navigationDestination(for: ReceiptFlowStep.self) { _ in
                ReceiptPreviewView(
                    viewModel: receiptViewModel,
                    onClose: { showsReceiptFlow = false },
                    onConfirm: confirmReceipt
                )
            }
        }
    }

    func confirmReceipt() {
        let billItems = receiptViewModel.items.map {
            BillItem(name: $0.name, amount: $0.amount, assignedTo: selectedParticipants)
        }
        viewModel.replaceScannedItems(
            billItems,
            imageData: receiptViewModel.scannedReceiptImageJPEGData,
            assignedTo: selectedParticipants
        )
        showsReceiptFlow = false
    }

    var splitikDraft: String {
        let title = viewModel.receiptTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        return title.isEmpty
            ? "Помоги создать платёж и разделить расходы"
            : "Помоги создать платёж «\(title)» и разделить расходы"
    }

    func saveAndDismiss() {
        guard viewModel.canSave else { return }
        Task {
            if await viewModel.save() {
                dismiss()
            }
        }
    }

    func retryImageUploadAndDismiss() {
        Task {
            if await viewModel.retryReceiptImageUpload() {
                dismiss()
            }
        }
    }
}

private enum ReceiptFlowStep: Hashable {
    case preview
}

#Preview {
    let dependencies = AppDependencies.preview
    BillEntryView(
        viewModel: BillViewModel(
            mode: .create(eventId: nil, scannedItems: [], receiptImageJPEGData: nil),
            eventsRepository: dependencies.eventsRepository,
            receiptsRepository: dependencies.receiptsRepository,
            usersRepository: dependencies.usersRepository,
            networkMonitor: dependencies.networkMonitor
        )
    )
}
