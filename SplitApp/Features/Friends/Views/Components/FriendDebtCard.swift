import SwiftUI

struct FriendDebtCard: View {
    let debt: FriendDebt
    let isSettling: Bool
    let onSettle: () -> Void

    @State private var isPressed = false

    var body: some View {
        GlassCard(padding: 16) {
            HStack(spacing: 12) {
                FriendAvatar(friend: debt.friend, size: 56)

                VStack(alignment: .leading, spacing: 4) {
                    Text(debt.friend.name)
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundStyle(AppTheme.textPrimary)

                    HStack(spacing: 4) {
                        Text(debt.type == .owedBy ? "Должен вам" : "Вы должны")
                            .font(.system(size: 15, weight: .regular, design: .rounded))
                            .foregroundStyle(debt.type == .owedBy ? Color.green : Color.red)

                        Text("₽\(NSDecimalNumber(decimal: debt.amount).stringValue)")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundStyle(debt.type == .owedBy ? Color.green : Color.red)
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
                                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                                }
                            }
                            .frame(minWidth: 72, minHeight: 34)
                            .foregroundStyle(AppTheme.accent)
                            .background(AppTheme.accent.opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    )
                    .disabled(isSettling)
                    .buttonStyle(PlainButtonStyle())
                    .scaleEffect(isPressed ? 0.95 : 1.0)
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { _ in
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                    isPressed = true
                                }
                            }
                            .onEnded { _ in
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                    isPressed = false
                                }
                            }
                    )
                } else {
                    Text("Ожидаем")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(AppTheme.textSecondary)
                        .frame(minWidth: 72, minHeight: 34)
                        .background(AppTheme.surfaceOverlay)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .onTapGesture {
            hideKeyboard()
        }
    }
}
