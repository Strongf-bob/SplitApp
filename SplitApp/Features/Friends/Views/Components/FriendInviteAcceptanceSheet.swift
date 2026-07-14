import SwiftUI

struct FriendInviteAcceptanceSheet: View {
    let invite: FriendInvitePreview
    let isAccepting: Bool
    let errorMessage: String?
    let onDecline: () -> Void
    let onAccept: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.badge.plus")
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(AppTheme.accent)

            VStack(spacing: 8) {
                Text("Добавить друга?")
                    .font(.system(size: 24, weight: .bold, design: .rounded))

                Text("\(invite.creator.name) приглашает вас в SplitApp.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(AppTheme.textSecondary)

                Text("Ссылка действует до \(invite.expiresAt.formatted(date: .omitted, time: .shortened)).")
                    .font(.footnote)
                    .foregroundStyle(AppTheme.textSecondary)
            }

            Button(action: onAccept) {
                Group {
                    if isAccepting {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Добавить в друзья")
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .disabled(isAccepting)

            if let errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            }

            Button("Не сейчас", action: onDecline)
                .foregroundStyle(AppTheme.textSecondary)
                .disabled(isAccepting)
        }
        .padding(24)
        .presentationDetents([.medium])
    }
}
