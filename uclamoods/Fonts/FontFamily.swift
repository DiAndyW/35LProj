import SwiftUI

/// Defines font families and their weights.
struct FontFamily {
    /// First font family: CustomFont
    enum CustomFont {
        enum Weight: String {
            case regular = "Gambetta-Variable"
            case bold = "CustomFont-Bold"
        }

        /// Returns a SwiftUI Font for the specified weight and size, with fallback to system font.
        static func font(weight: Weight, size: CGFloat) -> Font {
            let uiFont = UIFont(name: weight.rawValue, size: size) ?? UIFont.systemFont(ofSize: size, weight: weight.uiFontWeight)
            return Font(uiFont)
        }

        /// Returns a Dynamic Type-compatible SwiftUI Font for the specified weight and text style.
        static func dynamicFont(weight: Weight, textStyle: Font.TextStyle, maximumPointSize: CGFloat? = nil) -> Font {
            let uiFont = UIFont(name: weight.rawValue, size: textStyle.defaultSize) ?? UIFont.systemFont(ofSize: textStyle.defaultSize, weight: weight.uiFontWeight)
            let metrics = UIFontMetrics(forTextStyle: textStyle.uiTextStyle)
            let scaledFont = maximumPointSize != nil ? metrics.scaledFont(for: uiFont, maximumPointSize: maximumPointSize!) : metrics.scaledFont(for: uiFont)
            return Font(scaledFont)
        }
    }

    /// Second font family: AnotherFont
    enum AnotherFont {
        enum Weight: String {
            case light = "AnotherFont-Light"
            case medium = "AnotherFont-Medium"
        }

        /// Returns a SwiftUI Font for the specified weight and size, with fallback to system font.
        static func font(weight: Weight, size: CGFloat) -> Font {
            let uiFont = UIFont(name: weight.rawValue, size: size) ?? UIFont.systemFont(ofSize: size, weight: weight.uiFontWeight)
            return Font(uiFont)
        }

        /// Returns a Dynamic Type-compatible SwiftUI Font for the specified weight and text style.
        static func dynamicFont(weight: Weight, textStyle: Font.TextStyle, maximumPointSize: CGFloat? = nil) -> Font {
            let uiFont = UIFont(name: weight.rawValue, size: textStyle.defaultSize) ?? UIFont.systemFont(ofSize: textStyle.defaultSize, weight: weight.uiFontWeight)
            let metrics = UIFontMetrics(forTextStyle: textStyle.uiTextStyle)
            let scaledFont = maximumPointSize != nil ? metrics.scaledFont(for: uiFont, maximumPointSize: maximumPointSize!) : metrics.scaledFont(for: uiFont)
            return Font(scaledFont)
        }
    }
}

/// Maps UI roles to specific font styles and sizes for SwiftUI.
enum Typography {
    case title
    case subtitle
    case body
    case caption

    /// Returns a static SwiftUI Font for the typography style.
    var font: Font {
        switch self {
        case .title:
            return FontFamily.CustomFont.font(weight: .bold, size: 28)
        case .subtitle:
            return FontFamily.AnotherFont.font(weight: .medium, size: 20)
        case .body:
            return FontFamily.CustomFont.font(weight: .regular, size: 16)
        case .caption:
            return FontFamily.AnotherFont.font(weight: .light, size: 12)
        }
    }

    /// Returns a Dynamic Type-compatible SwiftUI Font for the typography style.
    var dynamicFont: Font {
        switch self {
        case .title:
            return FontFamily.CustomFont.dynamicFont(weight: .bold, textStyle: .title)
        case .subtitle:
            return FontFamily.AnotherFont.dynamicFont(weight: .medium, textStyle: .subheadline)
        case .body:
            return FontFamily.CustomFont.dynamicFont(weight: .regular, textStyle: .body)
        case .caption:
            return FontFamily.AnotherFont.dynamicFont(weight: .light, textStyle: .caption)
        }
    }
}

// MARK: - Helpers
extension FontFamily.CustomFont.Weight {
    /// Maps CustomFont weights to UIKit font weights for fallback.
    var uiFontWeight: UIFont.Weight {
        switch self {
        case .regular: return .regular
        case .bold: return .bold
        }
    }
}

extension FontFamily.AnotherFont.Weight {
    /// Maps AnotherFont weights to UIKit font weights for fallback.
    var uiFontWeight: UIFont.Weight {
        switch self {
        case .light: return .light
        case .medium: return .medium
        }
    }
}

extension Font.TextStyle {
    /// Maps SwiftUI TextStyle to UIKit TextStyle for Dynamic Type.
    var uiTextStyle: UIFont.TextStyle {
        switch self {
        case .largeTitle: return .largeTitle
        case .title: return .title1
        case .title2: return .title2
        case .title3: return .title3
        case .headline: return .headline
        case .subheadline: return .subheadline
        case .body: return .body
        case .callout: return .callout
        case .footnote: return .footnote
        case .caption: return .caption1
        case .caption2: return .caption2
        @unknown default: return .body
        }
    }

    /// Provides default sizes for SwiftUI TextStyles (approximate, for fallback).
    var defaultSize: CGFloat {
        switch self {
        case .largeTitle: return 34
        case .title: return 28
        case .title2: return 22
        case .title3: return 20
        case .headline: return 17
        case .subheadline: return 15
        case .body: return 17
        case .callout: return 16
        case .footnote: return 13
        case .caption: return 12
        case .caption2: return 11
        @unknown default: return 17
        }
    }
}

extension Typography {
    /// Utility to log available fonts for debugging.
    static func logAvailableFonts() {
        for family in UIFont.familyNames.sorted() {
            print("[FontFamily]: \(family): \(UIFont.fontNames(forFamilyName: family).sorted())")
        }
    }
}
