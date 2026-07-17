import SwiftUI

struct SplitikChatView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var draft = ""
    @StateObject private var viewModel = SplitikChatViewModel()
    @FocusState private var isComposerFocused: Bool
    private let onBack: (() -> Void)?

    private let bottomAnchor = "splitik-chat-bottom"

    init(initialDraft: String = "", onBack: (() -> Void)? = nil) {
        _draft = State(initialValue: initialDraft)
        self.onBack = onBack
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            conversation
        }
        .background(Color.white.ignoresSafeArea())
        .safeAreaInset(edge: .bottom, spacing: 0) {
            composer
        }
        .task {
            await viewModel.loadHistory()
        }
        .onAppear {
            AppTabCenter.shared.setTabBarHidden(true)
        }
        .onDisappear {
            AppTabCenter.shared.setTabBarHidden(false)
        }
    }

    private var scrollState: SplitikChatScrollState {
        SplitikChatScrollState(
            messageCount: viewModel.messages.count,
            isComposerFocused: isComposerFocused,
            isSending: viewModel.isSending
        )
    }

    private var conversation: some View {
        ScrollViewReader { proxy in
            Group {
                if viewModel.messages.isEmpty, !viewModel.isSending {
                    emptyState
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(viewModel.messages) { message in
                                messageRow(message)
                            }

                            if viewModel.isSending {
                                loadingRow
                            }

                            Color.clear
                                .frame(height: 1)
                                .id(bottomAnchor)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 20)
                    }
                    .scrollDismissesKeyboard(.interactively)
                }
            }
            .onChange(of: scrollState) { previous, current in
                guard current.shouldScrollToBottom(comparedTo: previous) else { return }
                scrollToBottom(using: proxy)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image("asset-0da481f91365")
                .resizable()
                .interpolation(.none)
                .scaledToFit()
                .frame(width: 108, height: 110)
                .accessibilityHidden(true)
            VStack(spacing: 6) {
                Text("Привет, я Сплитик.\nЧем могу помочь?")
                    .font(AppTypography.robotoMedium(size: 24, relativeTo: .title3))
                    .foregroundStyle(AppTheme.textPrimary)
            }
            .multilineTextAlignment(.center)
            Spacer()
        }
        .padding(32)
        .offset(y: -30)
    }

    private func messageRow(_ message: SplitikChatViewModel.Message) -> some View {
        HStack(alignment: .bottom, spacing: 10) {
            if message.role == .user {
                Spacer(minLength: 52)
            } else {
                Image(systemName: "sparkles")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(AppTheme.accent)
                    .frame(width: 30, height: 30)
                    .background(AppTheme.inputBackground, in: Circle())
                    .accessibilityHidden(true)
            }

            VStack(alignment: .leading, spacing: 10) {
                messageText(for: message)
                    .font(.body)
                    .lineSpacing(3)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .foregroundStyle(message.role == .user ? AppTheme.accentForeground : AppTheme.textPrimary)
                    .background(messageBubbleBackground(for: message), in: RoundedRectangle(cornerRadius: 18))
                    .overlay {
                        if message.role == .assistant {
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(AppTheme.cardBorder, lineWidth: 1)
                        }
                    }

                ForEach(message.drafts) { draft in
                    if let plan = draft.eventPlan {
                        SplitikEventPlanCard(draft: draft, plan: plan) {
                            Task { await viewModel.confirm(draft) }
                        }
                    }
                }
            }

            if message.role == .assistant {
                Spacer(minLength: 36)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func messageBubbleBackground(for message: SplitikChatViewModel.Message) -> Color {
        message.role == .user ? AppTheme.accent : AppTheme.cardBackground
    }

    private var loadingRow: some View {
        HStack(spacing: 10) {
            Image(systemName: "sparkles")
                .font(.caption.weight(.bold))
                .foregroundStyle(AppTheme.accent)
                .frame(width: 30, height: 30)
                .background(AppTheme.inputBackground, in: Circle())
                .accessibilityHidden(true)
            HStack(spacing: 8) {
                ProgressView()
                    .controlSize(.small)
                Text("Готовлю ответ")
            }
            .font(.subheadline.weight(.medium))
            .foregroundStyle(AppTheme.textSecondary)
            .padding(.horizontal, 14)
            .frame(height: 44)
            .background(AppTheme.cardBackground, in: Capsule())
            .overlay(Capsule().stroke(AppTheme.cardBorder, lineWidth: 1))
            Spacer()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Сплитик готовит ответ")
    }

    @ViewBuilder
    private func messageText(for message: SplitikChatViewModel.Message) -> some View {
        if message.role == .assistant {
            SplitikMarkdownText(markdown: message.text)
        } else {
            Text(message.text)
        }
    }

    private var header: some View {
        HStack {
            Button {
                if let onBack {
                    onBack()
                } else {
                    AppTabCenter.shared.setTabBarHidden(false)
                    AppTabCenter.shared.select(.home)
                }
            } label: {
                Label("Назад", systemImage: "chevron.left")
            }
            .buttonStyle(.plain)
            Spacer()
        }
        .font(.system(size: 24, weight: .regular))
        .foregroundStyle(AppTheme.textPrimary)
        .padding(.horizontal, 21)
        .frame(height: 70)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
    }

    private var composer: some View {
        HStack(spacing: 10) {
            TextField("Сообщение...", text: $draft)
                .textFieldStyle(.plain)
                .padding(.horizontal, 22)
                .frame(height: 62)
                .background(Color.white, in: Capsule())
                .overlay(Capsule().stroke(AppTheme.pdfPrimaryBlue, lineWidth: 2))
                .focused($isComposerFocused)
                .submitLabel(.send)
                .onSubmit(sendDraft)

            Button(action: sendDraft) {
                Group {
                    if viewModel.isSending {
                        ProgressView()
                    } else {
                        Image(systemName: "arrow.up")
                    }
                }
                .font(.headline.weight(.bold))
                    .foregroundStyle(canSend ? Color.white : AppTheme.pdfPrimaryBlue)
                    .frame(width: 62, height: 62)
                    .background(canSend ? AppTheme.pdfPrimaryBlue : Color.white, in: Circle())
                    .overlay(Circle().stroke(AppTheme.pdfPrimaryBlue, lineWidth: 2))
            }
            .buttonStyle(.plain)
            .disabled(!canSend)
            .accessibilityLabel("Отправить сообщение Сплитику")
        }
        .padding(.horizontal, 21)
        .padding(.top, 8)
        .padding(.bottom, 18)
        .background(Color.white)
        .alert("Сплитик", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("Понятно", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    private var canSend: Bool {
        !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !viewModel.isSending
    }

    private func sendDraft() {
        guard canSend else { return }
        let message = draft
        draft = ""
        Task { await viewModel.send(message) }
    }

    private func scrollToBottom(using proxy: ScrollViewProxy) {
        Task { @MainActor in
            await Task.yield()
            if reduceMotion {
                proxy.scrollTo(bottomAnchor, anchor: .bottom)
            } else {
                withAnimation(.easeOut(duration: 0.2)) {
                    proxy.scrollTo(bottomAnchor, anchor: .bottom)
                }
            }
        }
    }
}

struct SplitikChatScrollState: Equatable {
    let messageCount: Int
    let isComposerFocused: Bool
    let isSending: Bool

    func shouldScrollToBottom(comparedTo previous: Self) -> Bool {
        messageCount != previous.messageCount
            || (isComposerFocused && !previous.isComposerFocused)
            || (isSending && !previous.isSending)
    }
}

enum SplitikMarkdownRenderer {
    static func render(_ markdown: String) -> AttributedString {
        (try? AttributedString(markdown: markdown)) ?? AttributedString(markdown)
    }
}

private struct SplitikMarkdownText: View {
    let markdown: String

    var body: some View {
        Text(SplitikMarkdownRenderer.render(markdown))
            .textSelection(.enabled)
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
