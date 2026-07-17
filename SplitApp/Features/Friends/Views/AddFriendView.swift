import SwiftUI

struct AddFriendView: View {
    @ObservedObject var viewModel: FriendsViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isPhoneFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                SplitAppModalHeader(
                    title: "Добавление друга",
                    onClose: { dismiss() },
                    canPerformPrimary: canSubmit,
                    onPrimary: performPrimaryAction
                )
                .padding(.horizontal, 16)
                .padding(.top, 8)

                VStack(alignment: .leading, spacing: 18) {
                    nameField
                    phoneField
                    actionButton
                    message
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 32)
                .padding(.top, 18)
            }
            .background(Color.white.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
        }
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(SplitAppDesignTokens.modalCornerRadius)
        .onAppear { isPhoneFocused = true }
    }
}

private extension AddFriendView {
    var nameField: some View {
        outlinedField(
            title: "Имя",
            value: viewModel.foundUser?.name ?? "Пример: Иван",
            isPlaceholder: viewModel.foundUser == nil
        )
        .accessibilityLabel("Имя найденного пользователя")
    }

    var phoneField: some View {
        VStack(alignment: .leading, spacing: 9) {
            Text("Введите номер телефона")
                .font(.system(size: 20, weight: .regular))
                .foregroundStyle(AppTheme.textPrimary)

            TextField("+ 7", text: $viewModel.friendPhone)
                .font(.system(size: 17))
                .foregroundStyle(AppTheme.textPrimary)
                .keyboardType(.phonePad)
                .textContentType(.telephoneNumber)
                .focused($isPhoneFocused)
                .frame(minHeight: 57)
                .padding(.horizontal, 25)
                .overlay {
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(isPhoneFocused ? AppTheme.pdfPrimaryBlue : AppTheme.textSecondary, lineWidth: 1)
                }
                .submitLabel(.search)
                .onSubmit { performPrimaryAction() }
        }
    }

    func outlinedField(title: String, value: String, isPlaceholder: Bool) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            Text(title)
                .font(.system(size: 20, weight: .regular))
                .foregroundStyle(AppTheme.textPrimary)

            Text(value)
                .font(.system(size: 17))
                .foregroundStyle(isPlaceholder ? AppTheme.textSecondary : AppTheme.textPrimary)
                .frame(maxWidth: .infinity, minHeight: 57, alignment: .leading)
                .padding(.horizontal, 25)
                .overlay {
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(AppTheme.textSecondary, lineWidth: 1)
                }
        }
    }

    var actionButton: some View {
        SplitAppActionButton(
            title: viewModel.foundUser == nil ? "Найти друга" : "Добавить друга",
            isEnabled: canSubmit,
            action: performPrimaryAction
        )
    }

    @ViewBuilder
    var message: some View {
        if viewModel.isSearchingFriend || viewModel.isSendingFriendRequest {
            ProgressView(viewModel.isSearchingFriend ? "Ищем пользователя..." : "Отправляем заявку...")
                .font(.system(size: 15))
        } else if let message = viewModel.friendSearchMessage {
            Label(
                message,
                systemImage: message == "Заявка отправлена" ? "checkmark.circle.fill" : "info.circle"
            )
            .font(.system(size: 15, weight: .medium))
            .foregroundStyle(message == "Заявка отправлена" ? AppTheme.success : AppTheme.textSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    var canSubmit: Bool {
        !viewModel.friendPhone.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !viewModel.isSearchingFriend
            && !viewModel.isSendingFriendRequest
    }

    func performPrimaryAction() {
        guard canSubmit else { return }
        Task {
            if viewModel.foundUser == nil {
                await viewModel.searchRegisteredUser()
            } else {
                await viewModel.sendFriendRequest()
            }
        }
    }
}
