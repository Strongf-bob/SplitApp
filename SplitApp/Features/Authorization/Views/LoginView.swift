import SwiftUI

struct LoginView: View {
    @EnvironmentObject var appState: AppState
    @ObservedObject var viewModel: AuthViewModel

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
                    Task {
                        let success = await viewModel.login()
                        if success {
                            appState.isLoggedIn = true
                        }
                    }
                }

                Text("Продолжая, вы соглашаетесь с условиями сервиса")
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.68))
                    .multilineTextAlignment(.center)
                    .padding(.top, 16)

                Spacer(minLength: 32)
            }
            .padding(.horizontal, 24)
        }
    }
}
