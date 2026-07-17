import SwiftUI
import YandexLoginSDK

@main
struct SplitAppApp: App {
    private let dependencies = AppDependencies.live

    @StateObject private var appState = AppState()
    @State private var isShowingLaunchScreen = true
    @State private var launchStartedAt = Date()
    private let viewModel: AuthViewModel

    init() {
        do {
            try YandexLoginSDK.shared.activate(
                with: YandexOAuthConfiguration.clientID
            )
        } catch {
            print("Ошибка SDK: \(error)")
        }

        let vcProvider = DefaultViewControllerProvider()
        let storage = KeychainStorage()
        let yandexProvider = YandexAuthProviderImpl(vcProvider: vcProvider)
        let repository = AuthRepositoryImpl(yandex: yandexProvider)
        let serviceBackend = AuthServiceBackend()
        let service = AuthServicesImpl(
            repository: repository,
            serviceBackend: serviceBackend,
            secureStorage: storage
        )

        let useCase = LoginUseCase(
            service: service,
            secureStorage: storage
        )

        self.viewModel = AuthViewModel(
            vcProvider: vcProvider,
            useCase: useCase
        )
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                Group {
                    if appState.isLoading {
                        ProgressView()
                    } else if appState.isLoggedIn {
                        ContentView(dependencies: dependencies, appState: appState)
                    } else {
                        LoginView(viewModel: viewModel)
                    }
                }

                if isShowingLaunchScreen {
                    SplitLaunchView()
                        .transition(.opacity)
                        .zIndex(1)
                }
            }
            .onOpenURL { url in
                guard !FriendInviteStore.shared.accept(url) else {
                    return
                }

                do {
                    try YandexLoginSDK.shared.handleOpenURL(url)
                    print("URL успешно передан в SDK")
                } catch {
                    print("SDK не смог обработать URL: \(error)")
                }
            }
            .task {
                await bootstrap()
                let remainingDuration = SplitLaunchPresentation.remainingDuration(since: launchStartedAt)
                if remainingDuration > 0 {
                    try? await Task.sleep(for: .seconds(remainingDuration))
                }

                withAnimation(.easeOut(duration: 0.12)) {
                    isShowingLaunchScreen = false
                }
            }
            .environmentObject(appState)
            .preferredColorScheme(AppAppearance.preferredColorScheme)
            .onOpenURL(perform: handleOpenURL)
        }
    }

    private func handleOpenURL(_ url: URL) {
        if FriendInviteLink.phone(from: url) != nil {
            FriendInviteLinkCenter.shared.handle(url)
            return
        }

        do {
            try YandexLoginSDK.shared.handleOpenURL(url)
        } catch {
            print("Не удалось обработать входящую ссылку: \(error)")
        }
    }

    private func bootstrap() async {
        let storage = KeychainStorage()

        guard storage.get("refresh_token") != nil else {
            TokenStore.shared.clear()
            await MainActor.run {
                CurrentUserStore.shared.clear()
                appState.isLoggedIn = false
                appState.isLoading = false
            }
            return
        }

        let restoredUser = await MainActor.run {
            CurrentUserStore.shared.restoreCachedUser()
        }
        let result = await BootstrapAuthUseCase(storage: storage).execute()

        switch result {
        case .authenticated:
            if restoredUser == nil {
                do {
            let currentUserDTO: UserDTO = try await APIClient.shared.request(
                endpoint: CurrentUserEndpoint()
            )
                    await MainActor.run {
                        CurrentUserStore.shared.updateFromAuth(
                            UserMapper.mapToDomain(dto: currentUserDTO)
                        )
                    }
                } catch {
                    storage.delete("refresh_token")
                    TokenStore.shared.clear()
                    await MainActor.run {
                        CurrentUserStore.shared.clear()
                        appState.isLoggedIn = false
                        appState.isLoading = false
                    }
                    return
                }
            }
            await MainActor.run {
                appState.isLoggedIn = true
                appState.isLoading = false
            }

        case .unauthenticated:
            await MainActor.run {
                CurrentUserStore.shared.clear()
                appState.isLoggedIn = false
                appState.isLoading = false
            }
        }
    }
}
