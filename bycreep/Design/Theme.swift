import SwiftUI
import UIKit

// MARK: - Palette

enum Theme {
    static let bg = Color(hex: 0x070708)
    static let surface = Color(hex: 0x111113)
    static let surfaceElevated = Color(hex: 0x17171A)
    static let surfaceSoft = Color(hex: 0x1E1E22)

    static let text = Color.white
    static let secondary = Color.white.opacity(0.58)
    static let tertiary = Color.white.opacity(0.34)

    static let stroke = Color.white.opacity(0.08)
    static let strokeStrong = Color.white.opacity(0.18)

    static let red = Color(hex: 0xFF2D2D)
    static let deepRed = Color(hex: 0xC20016)
    static let redSoft = Color(hex: 0xFF2D2D).opacity(0.13)

    static let radius: CGFloat = 24
    static let cardPadding: CGFloat = 18

    static let heroGradient = LinearGradient(
        colors: [Color(hex: 0x241012), Color(hex: 0x101012)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let redGradient = LinearGradient(
        colors: [Color(hex: 0xFF3B30), Color(hex: 0xB80016)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - Typography

enum ByFont {
    static func display(_ size: CGFloat) -> Font {
        .system(size: size, weight: .black, design: .default)
    }

    static func heavy(_ size: CGFloat) -> Font {
        .system(size: size, weight: .heavy, design: .default)
    }

    static func bold(_ size: CGFloat) -> Font {
        .system(size: size, weight: .bold, design: .default)
    }

    static func semibold(_ size: CGFloat) -> Font {
        .system(size: size, weight: .semibold, design: .default)
    }

    static func regular(_ size: CGFloat) -> Font {
        .system(size: size, weight: .regular, design: .default)
    }

    static func mono(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }

    static let label = Font.system(size: 11, weight: .bold, design: .default)
    static let micro = Font.system(size: 10, weight: .semibold, design: .default)
}

// MARK: - Color helpers

extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        let red = Double((hex >> 16) & 0xFF) / 255
        let green = Double((hex >> 8) & 0xFF) / 255
        let blue = Double(hex & 0xFF) / 255
        self.init(.sRGB, red: red, green: green, blue: blue, opacity: opacity)
    }
}

extension UIColor {
    convenience init(hex: UInt32) {
        let red = CGFloat((hex >> 16) & 0xFF) / 255
        let green = CGFloat((hex >> 8) & 0xFF) / 255
        let blue = CGFloat(hex & 0xFF) / 255
        self.init(red: red, green: green, blue: blue, alpha: 1)
    }
}

// MARK: - Background

struct ByBackground: View {
    var body: some View {
        ZStack {
            Theme.bg
            RadialGradient(
                colors: [Theme.red.opacity(0.075), .clear],
                center: .topTrailing,
                startRadius: 10,
                endRadius: 420
            )
        }
        .ignoresSafeArea()
    }
}
