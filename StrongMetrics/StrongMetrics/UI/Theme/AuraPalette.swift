// AuraPalette.swift
// Complete design system: colors, fonts, spacing constants.

import UIKit

// MARK: - Aura Color Palette
struct AuraPalette {

    // MARK: - Backgrounds
    static let voidBlack        = UIColor(r: 11, g: 11, b: 30)
    static let cosmicDeep       = UIColor(r: 18, g: 18, b: 48)
    static let nebulaCard       = UIColor(r: 24, g: 24, b: 64, a: 0.95)
    static let stellarPanel     = UIColor(r: 32, g: 32, b: 80, a: 0.92)
    static let glassSheet       = UIColor(r: 40, g: 40, b: 100, a: 0.6)

    // MARK: - Neon Accents
    static let amethystBurst    = UIColor(r: 148, g: 82, b: 236)      // Main purple
    static let cobaltFlare      = UIColor(r: 64, g: 180, b: 255)      // Bright blue
    static let prismaticGold    = UIColor(r: 255, g: 214, b: 0)       // Gold/yellow
    static let emberCrimson     = UIColor(r: 255, g: 60, b: 100)      // Hot pink-red
    static let verdantPulse     = UIColor(r: 0, g: 230, b: 120)       // Green
    static let chartreuseGlow   = UIColor(r: 180, g: 255, b: 50)      // Lime
    static let quartzTint       = UIColor(r: 160, g: 160, b: 220)     // Muted lavender

    // MARK: - Text
    static let starWhite        = UIColor(r: 238, g: 238, b: 255)
    static let dimStar          = UIColor(r: 150, g: 150, b: 200)
    static let ghostText        = UIColor(r: 100, g: 100, b: 150)

    // MARK: - Borders
    static let radiantBorder    = UIColor(r: 148, g: 82, blue: 236, alpha: 0.7)
    static let subtleBorder     = UIColor(r: 80, g: 80, blue: 140, alpha: 0.4)

    // MARK: - Gradients
    static let primaryGrad: [CGColor] = [
        UIColor(r: 100, g: 40, b: 200).cgColor,
        UIColor(r: 40, g: 140, b: 255).cgColor
    ]
    static let goldGrad: [CGColor] = [
        UIColor(r: 255, g: 140, b: 0).cgColor,
        UIColor(r: 255, g: 214, b: 0).cgColor
    ]
    static let crimsonGrad: [CGColor] = [
        UIColor(r: 200, g: 20, b: 80).cgColor,
        UIColor(r: 255, g: 80, b: 30).cgColor
    ]
    static let cyanGrad: [CGColor] = [
        UIColor(r: 0, g: 180, b: 255).cgColor,
        UIColor(r: 0, g: 240, b: 220).cgColor
    ]
    static let verdantGrad: [CGColor] = [
        UIColor(r: 0, g: 200, b: 100).cgColor,
        UIColor(r: 100, g: 255, b: 50).cgColor
    ]

    // MARK: - Node colors by category
    static func nodeAccent(for category: GlyphCategory) -> UIColor {
        switch category {
        case .mundane:      return quartzTint
        case .feralWild:    return cobaltFlare
        case .scatter:      return prismaticGold
        case .bonusTrigger: return emberCrimson
        case .freeSpin:     return verdantPulse
        case .multiplier:   return chartreuseGlow
        }
    }

    static func nodeGradient(for category: GlyphCategory) -> [CGColor] {
        switch category {
        case .mundane:      return primaryGrad
        case .feralWild:    return cyanGrad
        case .scatter:      return goldGrad
        case .bonusTrigger: return crimsonGrad
        case .freeSpin:     return verdantGrad
        case .multiplier:   return verdantGrad
        }
    }

    static func latticeNodeAccent(for kind: LatticeNodeKind) -> UIColor {
        switch kind {
        case .glyphSource:    return amethystBurst
        case .reelGroup:      return cobaltFlare
        case .featureMech:    return verdantPulse
        case .bonusTrigger:   return emberCrimson
        case .freeSpinRoute:  return prismaticGold
        case .multiplierNode: return chartreuseGlow
        case .paylineBlock:   return cobaltFlare
        case .conditionFork:  return chartreuseGlow
        case .outputSink:     return quartzTint
        case .commentNote:    return ghostText
        }
    }
}

// MARK: - UIColor convenience init
extension UIColor {
    convenience init(r: Int, g: Int, b: Int, a: CGFloat = 1.0) {
        self.init(red: CGFloat(r)/255, green: CGFloat(g)/255, blue: CGFloat(b)/255, alpha: a)
    }
    convenience init(r: Int, g: Int, blue: Int, alpha: CGFloat) {
        self.init(red: CGFloat(r)/255, green: CGFloat(g)/255, blue: CGFloat(blue)/255, alpha: alpha)
    }
}

// MARK: - Font System
struct AuraTypeface {
    static func display(_ size: CGFloat, weight: UIFont.Weight = .bold) -> UIFont {
        UIFont.systemFont(ofSize: adaptiveFontSize(size), weight: weight)
    }
    static func headline(_ size: CGFloat) -> UIFont {
        UIFont.systemFont(ofSize: adaptiveFontSize(size), weight: .semibold)
    }
    static func body(_ size: CGFloat) -> UIFont {
        UIFont.systemFont(ofSize: adaptiveFontSize(size), weight: .regular)
    }
    static func caption(_ size: CGFloat) -> UIFont {
        UIFont.systemFont(ofSize: adaptiveFontSize(size), weight: .medium)
    }
    static func mono(_ size: CGFloat) -> UIFont {
        UIFont.monospacedDigitSystemFont(ofSize: adaptiveFontSize(size), weight: .medium)
    }

    private static func adaptiveFontSize(_ base: CGFloat) -> CGFloat {
        let screenWidth = UIScreen.main.bounds.width
        let scaleFactor = min(1.2, max(0.85, screenWidth / 390))
        return base * scaleFactor
    }
}

// MARK: - Spacing
struct ManifoldSpacing {
    static let micro: CGFloat    = 4
    static let minor: CGFloat    = 8
    static let standard: CGFloat = 16
    static let major: CGFloat    = 24
    static let grand: CGFloat    = 32
    static let cornerS: CGFloat  = 8
    static let cornerM: CGFloat  = 14
    static let cornerL: CGFloat  = 20
    static let cornerXL: CGFloat = 28
    static let borderW: CGFloat  = 1.5

    static var adaptivePad: CGFloat {
        UIScreen.main.bounds.width > 400 ? standard : minor
    }
}

// MARK: - Screen Helpers
struct ScreenManifold {
    static var width: CGFloat  { UIScreen.main.bounds.width }
    static var height: CGFloat { UIScreen.main.bounds.height }
    static var isSmall: Bool   { width < 375 }
    static var isLarge: Bool   { width >= 414 }

    static var safeAreaInsets: UIEdgeInsets {
        UIApplication.shared.windows.first?.safeAreaInsets ?? .zero
    }
}

// MARK: - CAGradientLayer Helper
extension CAGradientLayer {
    static func auraGradient(colors: [CGColor], startPoint: CGPoint = CGPoint(x: 0, y: 0), endPoint: CGPoint = CGPoint(x: 1, y: 1)) -> CAGradientLayer {
        let layer = CAGradientLayer()
        layer.colors = colors
        layer.startPoint = startPoint
        layer.endPoint = endPoint
        return layer
    }
}
