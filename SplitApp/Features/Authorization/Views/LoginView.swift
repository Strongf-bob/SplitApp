import SwiftUI

struct LoginView: View {
    @EnvironmentObject var appState: AppState
    @ObservedObject var viewModel: AuthViewModel
    @State private var isAuthorizing = false

    var body: some View {
        ZStack {
            AppTheme.figmaHero
                .ignoresSafeArea()
            VStack(spacing: 0) {
                Spacer()

                Text("Split.")
                    .font(.system(size: 64, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .accessibilityLabel("SplitApp")

                Text("Делите расходы вместе")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.78))
                    .padding(.top, 8)

                Spacer()

                SocialButton(
                    icon: "yandex",
                    backgroundColor: .white,
                    textColor: .black,
                    hasBorder: true,
                    title: "Войти через Яндекс"
                ) {
                    guard !isAuthorizing else { return }
                    isAuthorizing = true
                    Task {
                        let success = await viewModel.login()
                        if success {
                            appState.isLoggedIn = true
                        }
                        isAuthorizing = false
                    }
                }
                .disabled(isAuthorizing)
                .opacity(isAuthorizing ? 0.7 : 1)

                Text("Продолжая, вы соглашаетесь с условиями сервиса")
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.68))
                    .multilineTextAlignment(.center)
                    .padding(.top, 16)

                Color.clear
                    .frame(height: 32)
            }
            .padding(.horizontal, 24)
        }
    }
}
