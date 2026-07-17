import SwiftUI

struct SearchBar: View {
    @Binding var searchText: String
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(AppTheme.textTertiary.opacity(0.6))

            TextField("Поиск своих друзей", text: $searchText)
                .font(AppTypography.robotoMedium(size: 16, relativeTo: .body))
                .foregroundStyle(AppTheme.textPrimary)
                .focused($isFocused)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)

            if !searchText.isEmpty {
                Button(
                    action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            searchText = ""
                        }
                    },
                    label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(AppTheme.textTertiary.opacity(0.6))
                    }
                )
                .buttonStyle(PlainButtonStyle())
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, 24)
        .frame(height: 58)
        .background(
            RoundedRectangle(cornerRadius: SplitAppDesignTokens.cardCornerRadius, style: .continuous)
                .fill(Color.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: SplitAppDesignTokens.cardCornerRadius, style: .continuous)
                .stroke(isFocused ? AppTheme.pdfPrimaryBlue : Color(hex: "#EDEDED"), lineWidth: 2)
        )
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isFocused)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: searchText.isEmpty)
    }
}
