import SwiftUI

struct GlassButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(
            action: {
                action()
            },
            label: {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(AppTheme.accentForeground)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 52)
                    .background(AppTheme.accentGradient)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
            }
        )
        .buttonStyle(.plain)
        .accessibilityAddTraits(.isButton)
    }
}
