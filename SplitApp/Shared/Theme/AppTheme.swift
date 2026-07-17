import SwiftUI
import UIKit

enum AppAppearance {
    static let preferredColorScheme: ColorScheme = .light
}

enum SplitAppDesignTokens {
    static let primaryBlueHex = "#1F387C"
    static let secondaryBlueHex = "#4C6096"
    static let tertiaryBlueHex = "#7988B0"
    static let disabledSurfaceHex = "#F2F2F2"
    static let secondaryTextHex = "#999999"
    static let successHex = "#4AB783"

    static let cardCornerRadius: CGFloat = 21
    static let modalCornerRadius: CGFloat = 32
}

enum AppTheme {
    private static func dynamicColor(light: String, dark: String) -> Color {
        Color(
            uiColor: UIColor { traitCollection in
                let hex = traitCollection.userInterfaceStyle == .dark ? dark : light
                return UIColor(Color(hex: hex))
            }
        )
    }

    static var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [
                dynamicColor(light: "#F7F8FC", dark: "#0B1020"),
                dynamicColor(light: "#F7F8FC", dark: "#0B1020")
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    static var backgroundRadialGlow: RadialGradient {
        RadialGradient(
            colors: [
                dynamicColor(light: "#1A5B6CFF", dark: "#162D4CA6"),
                .clear
            ],
            center: .topTrailing,
            startRadius: 20,
            endRadius: 460
        )
    }

    static var accent: Color {
        dynamicColor(light: SplitAppDesignTokens.primaryBlueHex, dark: "#9DB4FF")
    }

    static var accentDark: Color {
        dynamicColor(light: "#182D67", dark: "#C5D1FF")
    }

    static var accentGradient: LinearGradient {
        LinearGradient(
            colors: [
                dynamicColor(light: "#315EF5", dark: "#9DB4FF"),
                dynamicColor(light: SplitAppDesignTokens.primaryBlueHex, dark: "#6F8CFF")
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    static var accentForeground: Color {
        dynamicColor(light: "#FFFFFF", dark: "#0B1020")
    }

    static var textPrimary: Color {
        dynamicColor(light: "#141B2D", dark: "#F5F7FF")
    }

    static var textSecondary: Color {
        dynamicColor(light: SplitAppDesignTokens.secondaryTextHex, dark: "#B6C0DC")
    }

    static var textTertiary: Color {
        dynamicColor(light: "#8A93AA", dark: "#8290B1")
    }

    static var cardBackground: Color {
        dynamicColor(light: "#FFFFFF", dark: "#161E33")
    }

    static var cardBorder: Color {
        dynamicColor(light: "#E4E8F2", dark: "#2B3855")
    }

    static var cardShadow: Color {
        dynamicColor(light: "#120E1830", dark: "#55000000")
    }

    static var surfaceOverlay: Color {
        dynamicColor(light: "#0B315EF5", dark: "#1A9DB4FF")
    }

    static var inputBackground: Color {
        dynamicColor(light: "#F0F2F8", dark: "#1D2740")
    }

    static var inputBackgroundFocused: Color {
        dynamicColor(light: "#E6EBFF", dark: "#263456")
    }

    static var dividerHighlight: Color {
        dynamicColor(light: "#E4E8F2", dark: "#2B3855")
    }

    static var avatarStroke: Color {
        dynamicColor(light: "#FFFFFF", dark: "#2B3855")
    }

    static var tabBarBackground: Color {
        dynamicColor(light: "#FAFBFF", dark: "#11182A")
    }

    static var figmaHero: LinearGradient {
        LinearGradient(
            colors: [
                dynamicColor(light: "#1F387C", dark: "#142754"),
                dynamicColor(light: "#29498F", dark: "#193266")
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var contentSurface: Color {
        dynamicColor(light: SplitAppDesignTokens.disabledSurfaceHex, dark: "#11182A")
    }

    static var pdfPrimaryBlue: Color {
        dynamicColor(light: SplitAppDesignTokens.primaryBlueHex, dark: "#9DB4FF")
    }

    static var pdfSecondaryBlue: Color {
        dynamicColor(light: SplitAppDesignTokens.secondaryBlueHex, dark: "#7387BE")
    }

    static var pdfTertiaryBlue: Color {
        dynamicColor(light: SplitAppDesignTokens.tertiaryBlueHex, dark: "#8797C3")
    }

    static var disabledSurface: Color {
        dynamicColor(light: SplitAppDesignTokens.disabledSurfaceHex, dark: "#242B3D")
    }

    static var success: Color {
        dynamicColor(light: SplitAppDesignTokens.successHex, dark: "#64CCA0")
    }

    static var tabGlassTint: Color {
        dynamicColor(light: "#4A5565", dark: "#334155")
    }

    static let cornerRadius: CGFloat = 20
    static let cornerRadiusSmall: CGFloat = 12
    static let cornerRadiusLarge: CGFloat = 20

    static let paddingSmall: CGFloat = 8
    static let paddingMedium: CGFloat = 16
    static let paddingLarge: CGFloat = 20

    static let fontHeader = AppTypography.montserrat(.semibold, size: 17, relativeTo: .headline)
    static let fontBody = AppTypography.montserrat(size: 17, relativeTo: .body)
    static let fontBodyBold = AppTypography.montserrat(.semibold, size: 17, relativeTo: .body)
    static let fontTitle = AppTypography.montserrat(.bold, size: 20, relativeTo: .title3)
    static let fontLargeTitle = AppTypography.montserrat(.bold, size: 34, relativeTo: .largeTitle)
}
