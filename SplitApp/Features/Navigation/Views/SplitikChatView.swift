import SwiftUI

struct SplitikChatView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var draft = ""
    @StateObject private var viewModel = SplitikChatViewModel()

    init(initialDraft: String = "") {
        _draft = State(initialValue: initialDraft)
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            if viewModel.messages.isEmpty {
                Spacer()
                VStack(spacing: 10) {
                    Image(systemName: "cpu")
                        .font(.system(size: 66, weight: .bold))
                        .foregroundStyle(AppTheme.accentDark)
                        .accessibilityHidden(true)
                    Text("Напишите первое сообщение.")
                    Text("Привет, я Сплитик, чем могу помочь?")
                }
                .font(.subheadline)
                .foregroundStyle(AppTheme.textTertiary)
                .multilineTextAlignment(.center)
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        ForEach(viewModel.messages) { message in
                            VStack(alignment: .leading, spacing: 8) {
                                Text(message.text)
                                    .padding(12)
                                    .foregroundStyle(message.role == .user ? .white : AppTheme.textPrimary)
                                    .background(message.role == .user ? AppTheme.accent : .white, in: RoundedRectangle(cornerRadius: 16))
                                    .frame(maxWidth: .infinity, alignment: message.role == .user ? .trailing : .leading)
                                ForEach(message.drafts) { draft in
                                    if let plan = draft.eventPlan {
                                        SplitikEventPlanCard(draft: draft, plan: plan) {
                                            Task { await viewModel.confirm(draft) }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(16)
                }
            }
            if viewModel.isSending {
                HStack(spacing: 8) {
                    ProgressView()
                        .controlSize(.small)
                    Text("Готовлю ответ")
                }
                .font(.subheadline.weight(.medium))
                .foregroundStyle(AppTheme.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Сплитик готовит ответ")
            }
            composer
                .padding(16)
        }
        .background(AppTheme.contentSurface.ignoresSafeArea())
    }

    private var header: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Label("Назад", systemImage: "chevron.left")
            }
            .buttonStyle(.plain)
            Spacer()
        }
        .font(.body.weight(.medium))
        .foregroundStyle(AppTheme.textSecondary)
        .padding(.horizontal, 20)
        .frame(height: 64)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white)
    }

    private var composer: some View {
        HStack(spacing: 10) {
            TextField("Сообщение...", text: $draft)
                .textFieldStyle(.plain)
                .padding(.horizontal, 16)
                .frame(height: 48)
                .background(AppTheme.cardBackground, in: Capsule())

            Button {
                let message = draft
                draft = ""
                Task { await viewModel.send(message) }
            } label: {
                Group {
                    if viewModel.isSending {
                        ProgressView()
                    } else {
                        Image(systemName: "arrow.up")
                    }
                }
                .font(.headline.weight(.bold))
                    .frame(width: 48, height: 48)
            }
            .buttonStyle(.borderedProminent)
            .tint(AppTheme.accent)
            .accessibilityLabel("Отправить сообщение Сплитику")
        }
        .alert("Сплитик", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("Понятно", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
}

private struct SplitikEventPlanCard: View {
    let draft: SplitikDraftDTO
    let plan: SplitikEventPlanDTO
    let onConfirm: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("План создания", systemImage: "sparkles")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(AppTheme.accent)
                Spacer()
                Text("Черновик")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(AppTheme.textSecondary)
            }
            Text(plan.name).font(.title3.weight(.bold)).foregroundStyle(AppTheme.textPrimary)
            Label("Участников: \(plan.participantIds.count + 1)", systemImage: "person.2.fill")
                .font(.subheadline.weight(.medium)).foregroundStyle(AppTheme.textSecondary)
            ForEach(Array(plan.receipts.enumerated()), id: \.offset) { _, receipt in
                HStack {
                    Label(receipt.title, systemImage: "receipt")
                    Spacer()
                    Text(money(receipt.amountKopecks)).fontWeight(.bold)
                }
                .font(.subheadline).foregroundStyle(AppTheme.textPrimary)
            }
            Button(action: onConfirm) {
                Label("Подтвердить план", systemImage: "checkmark.circle.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(AppTheme.accent)
            .accessibilityIdentifier("splitik-event-plan-confirm")
        }
        .padding(16)
        .background(AppTheme.cardBackground, in: RoundedRectangle(cornerRadius: 22))
        .overlay(RoundedRectangle(cornerRadius: 22).stroke(AppTheme.accent.opacity(0.18), lineWidth: 1))
    }

    private func money(_ kopecks: Int) -> String {
        String(format: "%.0f ₽", Double(kopecks) / 100)
    }
}

#Preview {
    SplitikChatView()
}
