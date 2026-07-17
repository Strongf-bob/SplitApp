import SwiftUI

struct AddFriendView: View {
    @ObservedObject var viewModel: FriendsViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isPhoneFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 18) {
                nameField
                phoneField
                actionButton
                message
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 24)
            .padding(.top, 22)
            .background(Color.white.ignoresSafeArea())
            .navigationTitle("Добавление друга")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbar }
        }
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(32)
        .onAppear { isPhoneFocused = true }
    }
}

private extension AddFriendView {
    var nameField: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Имя")
                .font(.system(size: 21, weight: .medium))
                .foregroundStyle(AppTheme.textPrimary)

            Text(viewModel.foundUser?.name ?? "Найдётся по номеру")
                .font(.system(size: 18, weight: .regular))
                .foregroundStyle(viewModel.foundUser == nil ? AppTheme.textTertiary : AppTheme.textPrimary)
                .frame(maxWidth: .infinity, minHeight: 64, alignment: .leading)
                .padding(.horizontal, 20)
                .overlay {
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(AppTheme.textTertiary, lineWidth: 2)
                }
                .accessibilityLabel("Имя найденного пользователя")
        }
    }

    var phoneField: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Введите номер телефона")
                .font(.system(size: 21, weight: .medium))
                .foregroundStyle(AppTheme.textPrimary)

            TextField("+7", text: $viewModel.friendPhone)
                .font(.system(size: 18, weight: .regular))
                .foregroundStyle(AppTheme.textPrimary)
                .keyboardType(.phonePad)
                .textContentType(.telephoneNumber)
                .focused($isPhoneFocused)
                .frame(minHeight: 64)
                .padding(.horizontal, 20)
                .overlay {
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(isPhoneFocused ? AppTheme.accent : AppTheme.textTertiary, lineWidth: 2)
                }
                .submitLabel(.search)
                .onSubmit { performPrimaryAction() }
        }
    }

    var actionButton: some View {
        Button(action: performPrimaryAction) {
            Group {
                if viewModel.isSearchingFriend || viewModel.isSendingFriendRequest {
                    ProgressView().tint(.white)
                } else {
                    Text(viewModel.foundUser == nil ? "Найти друга" : "Добавить друга")
                        .font(.system(size: 20, weight: .medium))
                }
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, minHeight: 64)
            .background(Color(hex: "#29458B"), in: RoundedRectangle(cornerRadius: 18))
        }
        .buttonStyle(.plain)
        .disabled(viewModel.friendPhone.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || viewModel.isSearchingFriend
            || viewModel.isSendingFriendRequest)
        .opacity(viewModel.friendPhone.isEmpty ? 0.55 : 1)
    }

    @ViewBuilder
    var message: some View {
        if let message = viewModel.friendSearchMessage {
            Label(
                message,
                systemImage: message == "Заявка отправлена" ? "checkmark.circle.fill" : "info.circle"
            )
            .font(.system(size: 15, weight: .medium))
            .foregroundStyle(message == "Заявка отправлена" ? Color.green : AppTheme.textSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ToolbarContentBuilder
    var toolbar: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(AppTheme.textSecondary)
                    .frame(width: 42, height: 42)
                    .background(AppTheme.inputBackground, in: Circle())
            }
            .accessibilityLabel("Закрыть")
        }

        ToolbarItem(placement: .confirmationAction) {
            Button(action: performPrimaryAction) {
                Image(systemName: "arrow.up")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 42, height: 42)
                    .background(AppTheme.accent, in: Circle())
            }
            .disabled(viewModel.friendPhone.isEmpty)
            .accessibilityLabel(viewModel.foundUser == nil ? "Найти друга" : "Отправить заявку")
        }
    }

    func performPrimaryAction() {
        Task {
            if viewModel.foundUser == nil {
                await viewModel.searchRegisteredUser()
            } else {
                await viewModel.sendFriendRequest()
            }
        }
    }
}
