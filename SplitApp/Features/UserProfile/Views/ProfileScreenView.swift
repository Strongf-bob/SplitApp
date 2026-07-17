import SwiftUI

struct ProfileScreenView: View {
    @State private var showsChatNotice = false
    @ObservedObject var viewModel: ProfileViewModel

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            if viewModel.isLoading, viewModel.profileModel == nil {
                ProgressView()
                    .scaleEffect(1.5)
            } else if let model = viewModel.profileModel {
                VStack(spacing: 0) {
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 20) {
                            designProfileHeader(model: model)
                            contactCard(model: model)
                            VStack(alignment: .leading, spacing: 20) {
                                sectionTitle("ДАННЫЕ")
                                dataActions
                                logoutButton
                            }
                            .padding(.top, 300)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 22)
                        .padding(.bottom, 100)
                    }
                    .background(Color.white)
                }
            } else {
                VStack(spacing: 16) {
                    Text("Не удалось загрузить профиль")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(AppTheme.textSecondary)
                    Button("Попробовать снова") {
                        Task {
                            await viewModel.loadProfile()
                        }
                    }
                }
            }
        }
        .task {
            await viewModel.loadProfile()
        }
    }

    private func userCard(model: ProfileScreenModel) -> some View {
        ProfileCardView(
            initials: model.initials,
            name: model.name,
            email: model.email,
            avatarURL: model.avatarURL
        )
    }

    private func designProfileHeader(model: ProfileScreenModel) -> some View {
        VStack(spacing: 10) {
            AsyncImage(url: model.avatarURL) { phase in
                if case let .success(image) = phase {
                    image.resizable().scaledToFill()
                } else {
                    ZStack {
                        Circle().fill(Color(hex: "#1F387C"))
                        Text(model.initials)
                            .font(AppTypography.montserrat(.bold, size: 26, relativeTo: .title2))
                            .foregroundStyle(.white)
                    }
                }
            }
            .frame(width: 100, height: 100)
            .clipShape(Circle())

            Text(model.name)
                .font(AppTypography.robotoMedium(size: 24, relativeTo: .title2))
                .foregroundStyle(AppTheme.textPrimary)
        }
        .frame(maxWidth: .infinity)
    }

    private func contactCard(model: ProfileScreenModel) -> some View {
        let phone = CurrentUserStore.shared.user?.phoneNumber ?? "Не указан"
        return VStack(alignment: .leading, spacing: 10) {
            Text("Данные")
                .font(AppTypography.montserrat(.semibold, size: 25, relativeTo: .title2))
            contactValue(label: "Телефон", value: phone)
            contactValue(label: "Почта", value: model.email)
            contactValue(label: "Данные для перевода", value: phone)
        }
        .foregroundStyle(.white)
        .padding(22)
        .frame(maxWidth: .infinity, minHeight: 308, alignment: .topLeading)
        .background(Color(hex: "#7988B0"), in: RoundedRectangle(cornerRadius: 22))
    }

    private func contactValue(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label)
                .font(AppTypography.montserrat(.semibold, size: 16, relativeTo: .subheadline))
            Text(value)
                .font(AppTypography.montserrat(.semibold, size: 20, relativeTo: .headline))
                .textSelection(.enabled)
        }
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundStyle(AppTheme.textTertiary)
            .padding(.horizontal, 4)
    }

    private var dataActions: some View {
        Button {
            showsChatNotice = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "trash")
                    .frame(width: 32, height: 32)
                    .background(AppTheme.inputBackground, in: RoundedRectangle(cornerRadius: 12))
                Text("Удалить все чаты")
                Spacer()
                Image(systemName: "chevron.right")
            }
            .font(.body)
            .foregroundStyle(AppTheme.textPrimary)
            .padding(.horizontal, 16)
            .frame(minHeight: 72)
            .background(AppTheme.cardBackground, in: RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
        .alert("История чатов", isPresented: $showsChatNotice) {
            Button("Понятно", role: .cancel) {}
        } message: {
            Text("История Сплитика пока не сохраняется на сервере, поэтому удалять нечего.")
        }
    }

    private var logoutButton: some View {
        Button("Выйти из аккаунта", role: .destructive) {
            viewModel.logout()
        }
        .frame(maxWidth: .infinity, minHeight: 48)
    }
}
