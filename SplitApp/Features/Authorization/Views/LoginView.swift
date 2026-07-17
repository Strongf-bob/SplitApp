import SwiftUI

struct LoginView: View {
    @EnvironmentObject var appState: AppState
    @ObservedObject var viewModel: AuthViewModel
    @State private var isAuthorizing = false

    var body: some View {
        ZStack {
            Color(hex: "#1F387C").ignoresSafeArea()
            VStack(spacing: 0) {
                Spacer()

                Image("asset-0da481f91365")
                    .resizable()
                    .interpolation(.none)
                    .scaledToFit()
                    .frame(width: 144, height: 147)
                    .accessibilityHidden(true)

                Text("Split.")
                    .font(AppTypography.montserrat(.extraBold, size: 88, relativeTo: .largeTitle))
                    .foregroundStyle(.white)
                    .accessibilityLabel("SplitApp")

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
                    .font(AppTypography.montserrat(.bold, size: 12, relativeTo: .footnote))
                    .foregroundStyle(Color(hex: "#7988B0"))
                    .multilineTextAlignment(.center)
                    .padding(.top, 16)

                Color.clear
                    .frame(height: 22)
            }
            .padding(.horizontal, 24)
        }
    }
}
