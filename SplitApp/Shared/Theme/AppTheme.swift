import SwiftUI
import UIKit

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
        dynamicColor(light: "#315EF5", dark: "#9DB4FF")
    }

    static var accentDark: Color {
        dynamicColor(light: "#2449CC", dark: "#C5D1FF")
    }

    static var accentGradient: LinearGradient {
        LinearGradient(
            colors: [
                dynamicColor(light: "#315EF5", dark: "#9DB4FF"),
                dynamicColor(light: "#2348C7", dark: "#6F8CFF")
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
        dynamicColor(light: "#67708A", dark: "#B6C0DC")
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
        dynamicColor(light: "#F5F5F7", dark: "#11182A")
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

    static let fontHeader: Font = .headline.weight(.semibold)
    static let fontBody: Font = .body
    static let fontBodyBold: Font = .body.weight(.semibold)
    static let fontTitle: Font = .title3.weight(.bold)
    static let fontLargeTitle: Font = .largeTitle.weight(.bold)
}
