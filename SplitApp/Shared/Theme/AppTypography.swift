import SwiftUI

enum AppTypography {
    static let requiredFontNames = [
        "Montserrat-Regular",
        "Montserrat-Medium",
        "Montserrat-SemiBold",
        "Montserrat-Bold",
        "Montserrat-ExtraBold",
        "Roboto-Medium"
    ]

    static func montserrat(
        _ weight: MontserratWeight = .regular,
        size: CGFloat,
        relativeTo textStyle: Font.TextStyle = .body
    ) -> Font {
        .custom(weight.fontName, size: size, relativeTo: textStyle)
    }

    static func robotoMedium(
        size: CGFloat,
        relativeTo textStyle: Font.TextStyle = .body
    ) -> Font {
        .custom("Roboto-Medium", size: size, relativeTo: textStyle)
    }

    static let pdfDisplay = montserrat(.extraBold, size: 36, relativeTo: .largeTitle)
    static let pdfScreenTitle = montserrat(.bold, size: 25, relativeTo: .title2)
    static let pdfCardTitle = montserrat(.semibold, size: 20, relativeTo: .title3)
    static let pdfButton = montserrat(.semibold, size: 17, relativeTo: .headline)
    static let pdfBody = montserrat(.regular, size: 16, relativeTo: .body)

    enum MontserratWeight {
        case regular
        case medium
        case semibold
        case bold
        case extraBold

        fileprivate var fontName: String {
            switch self {
            case .regular: "Montserrat-Regular"
            case .medium: "Montserrat-Medium"
            case .semibold: "Montserrat-SemiBold"
            case .bold: "Montserrat-Bold"
            case .extraBold: "Montserrat-ExtraBold"
            }
        }
    }
}
