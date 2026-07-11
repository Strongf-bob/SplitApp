import SwiftUI

struct InboxView: View {
    @State private var selection = 0

    var body: some View {
        ZStack {
            AppTheme.figmaHero.ignoresSafeArea()
            VStack(spacing: 0) {
                Text("Уведомления")
                    .font(.system(size: 36, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24)
                    .padding(.top, 18)
                    .padding(.bottom, 20)

                VStack(spacing: 18) {
                    Picker("Уведомления", selection: $selection) {
                        Text("Входящие").tag(0)
                        Text("Прочитанные").tag(1)
                    }
                    .pickerStyle(.segmented)

                    ContentUnavailableView(
                        selection == 0 ? "Новых уведомлений нет" : "Прочитанных уведомлений нет",
                        systemImage: selection == 0 ? "tray" : "checkmark.circle",
                        description: Text("Приглашения и напоминания появятся здесь, когда сервер начнёт их отдавать.")
                    )
                    .foregroundStyle(AppTheme.textSecondary)
                    Spacer()
                }
                .padding(20)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(AppTheme.contentSurface, in: UnevenRoundedRectangle(topLeadingRadius: 28, topTrailingRadius: 28))
            }
        }
        .navigationBarHidden(true)
    }
}
