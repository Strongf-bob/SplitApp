import SwiftUI

struct FriendDebtCard: View {
    let debt: FriendDebt
    let isSettling: Bool
    let onSettle: () -> Void

    var body: some View {
        GlassCard(padding: 16) {
            HStack(spacing: 12) {
                FriendAvatar(friend: debt.friend, size: 56)

                VStack(alignment: .leading, spacing: 4) {
                    Text(debt.friend.name)
                    .font(.body.weight(.semibold))
                        .foregroundStyle(AppTheme.textPrimary)

                    HStack(spacing: 4) {
                        Text(debt.type == .owedBy ? "Должен вам" : "Вы должны")
                            .font(.subheadline)
                            .foregroundStyle(debt.type == .owedBy ? Color.green : AppTheme.textSecondary)

                        Text("₽\(NSDecimalNumber(decimal: debt.amount).stringValue)")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(debt.type == .owedBy ? Color.green : AppTheme.textPrimary)
                            .monospacedDigit()
                    }
                }

                Spacer()

                if debt.canSettle {
                    Button(
                        action: {
                            hideKeyboard()
                            onSettle()
                        },
                        label: {
                            Group {
                                if isSettling {
                                    ProgressView()
                                        .controlSize(.small)
                                } else {
                                    Text("Закрыть")
                                        .font(.subheadline.weight(.semibold))
                                }
                            }
                            .frame(minWidth: 72, minHeight: 34)
                            .foregroundStyle(AppTheme.accent)
                            .background(AppTheme.surfaceOverlay)
                            .clipShape(Capsule())
                        }
                    )
                    .disabled(isSettling)
                    .buttonStyle(.plain)
                } else {
                    Text("Ожидаем")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppTheme.textSecondary)
                        .frame(minWidth: 72, minHeight: 34)
                        .background(AppTheme.surfaceOverlay)
                        .clipShape(Capsule())
                }
            }
        }
        .onTapGesture {
            hideKeyboard()
        }
    }
}
