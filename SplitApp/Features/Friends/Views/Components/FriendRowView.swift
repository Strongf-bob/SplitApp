import SwiftUI

struct FriendRowView: View {
    let friend: Friend

    var body: some View {
        HStack(spacing: 12) {
            Text(friend.name)
                .font(AppTypography.robotoMedium(size: 16, relativeTo: .body))
                .foregroundStyle(AppTheme.textPrimary)

            Spacer()
        }
        .padding(.horizontal, 17)
        .frame(minHeight: 58)
        .background(AppTheme.pdfSecondaryBlue, in: RoundedRectangle(cornerRadius: SplitAppDesignTokens.cardCornerRadius, style: .continuous))
    }
}
