import SwiftUI

struct ProfileScreenView: View {
    @State private var notificationsEnabled: Bool
    @State private var bluetoothEnabled = false
    @State private var showsChatNotice = false
    @ObservedObject var viewModel: ProfileViewModel

    init(
        viewModel: ProfileViewModel,
        notificationsEnabled: Bool = true
    ) {
        self.viewModel = viewModel
        _notificationsEnabled = State(initialValue: notificationsEnabled)
    }

    var body: some View {
        ZStack {
            AppTheme.figmaHero
                .ignoresSafeArea()

            if viewModel.isLoading, viewModel.profileModel == nil {
                ProgressView()
                    .scaleEffect(1.5)
            } else if let model = viewModel.profileModel {
                VStack(spacing: 0) {
                    Text("Профиль")
                        .font(AppTypography.montserrat(.extraBold, size: 36, relativeTo: .largeTitle))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 24)
                        .padding(.top, 18)
                        .padding(.bottom, 20)

                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 20) {
                            sectionTitle("ПРОФИЛЬ")
                            userCard(model: model)
                            sectionTitle("РАЗРЕШЕНИЯ")
                            permissions
                            sectionTitle("ДАННЫЕ")
                            dataActions
                            logoutButton
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 24)
                        .padding(.bottom, 100)
                    }
                    .background(
                        AppTheme.contentSurface,
                        in: UnevenRoundedRectangle(topLeadingRadius: 28, topTrailingRadius: 28)
                    )
                    .background(AppTheme.contentSurface.ignoresSafeArea(edges: .bottom))
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

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundStyle(AppTheme.textTertiary)
            .padding(.horizontal, 4)
    }

    private var permissions: some View {
        VStack(spacing: 10) {
            permissionRow("Bluetooth", icon: "bluetooth", isOn: $bluetoothEnabled)
            permissionRow("Уведомления", icon: "bell", isOn: $notificationsEnabled)
        }
    }

    private func permissionRow(_ title: String, icon: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .frame(width: 32, height: 32)
                .background(AppTheme.inputBackground, in: RoundedRectangle(cornerRadius: 12))
                .foregroundStyle(AppTheme.textSecondary)
            Text(title)
                .font(.body)
                .foregroundStyle(AppTheme.textPrimary)
            Spacer()
            Toggle(title, isOn: isOn)
                .labelsHidden()
                .tint(AppTheme.textPrimary)
        }
        .padding(.horizontal, 16)
        .frame(minHeight: 58)
        .background(AppTheme.cardBackground, in: RoundedRectangle(cornerRadius: 16))
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
