import SwiftUI

struct ParticipantPickerSheet: View {
    let participants: [Participant]
    let selectedParticipants: [Participant]
    let onToggle: (Participant) -> Void
    let onDone: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    private var filteredParticipants: [Participant] {
        guard !searchText.isEmpty else { return participants }
        return participants.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    private func isSelected(_ participant: Participant) -> Bool {
        selectedParticipants.contains(where: { $0.id == participant.id })
    }

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            VStack(spacing: 20) {
                HStack {
                    Text("Выбор друзей")
                        .font(AppTypography.montserrat(.bold, size: 24, relativeTo: .title2))
                        .foregroundStyle(AppTheme.textPrimary)
                    Spacer()
                    Button(
                        action: { onDone() },
                        label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 24))
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                    )
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)

                SearchBar(searchText: $searchText)
                    .padding(.horizontal, 20)

                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredParticipants, id: \.id) { participant in
                            let selected = isSelected(participant)
                            Button(
                                action: {
                                    onToggle(participant)
                                },
                                label: {
                                    HStack(spacing: 16) {
                                        ParticipantAvatar(participant: participant, size: 48)

                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(participant.name)
                                                .font(AppTheme.fontBodyBold)
                                                .foregroundStyle(selected ? .white : AppTheme.textPrimary)
                                        }

                                        Spacer()

                                        Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                                            .font(.system(size: 22, weight: .semibold))
                                            .foregroundStyle(selected ? .white : AppTheme.textTertiary)
                                            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selected)
                                    }
                                    .padding(16)
                                    .background(selected ? Color(hex: "#4C6096") : AppTheme.cardBackground)
                                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                                            .stroke(
                                                selected ? Color(hex: "#4C6096") : AppTheme.cardBorder,
                                                lineWidth: selected ? 1.5 : 1
                                            )
                                    )
                                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selected)
                                }
                            )
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal, 20)
                }

                VStack(spacing: 12) {
                    Button(
                        action: { onDone() },
                        label: {
                            HStack(spacing: 8) {
                                if !selectedParticipants.isEmpty {
                                    Text("Готово (\(selectedParticipants.count))")
                                        .font(AppTheme.fontBodyBold)
                                } else {
                                    Text("Готово")
                                        .font(AppTheme.fontBodyBold)
                                }
                            }
                            .foregroundStyle(AppTheme.accentForeground)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                AppTheme.accentGradient
                            )
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusLarge))
                            .shadow(color: AppTheme.accent.opacity(0.25), radius: 12, x: 0, y: 4)
                        }
                    )
                    .buttonStyle(PlainButtonStyle())

                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
    }
}
