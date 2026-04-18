// GlyphModel.swift
// Core data model representing a single symbol (glyph) in the slot machine design tool.

import UIKit

// MARK: - Glyph Category
enum GlyphCategory: String, Codable, CaseIterable {
    case mundane   = "Standard"
    case feralWild = "Wild"
    case scatter   = "Scatter"
    case bonusTrigger = "Bonus Trigger"
    case freeSpin  = "Free Spin"
    case multiplier = "Multiplier"

    var auricColor: UIColor {
        switch self {
        case .mundane:      return AuraPalette.quartzTint
        case .feralWild:    return AuraPalette.prismaticGold
        case .scatter:      return AuraPalette.cobaltFlare
        case .bonusTrigger: return AuraPalette.emberCrimson
        case .freeSpin:     return AuraPalette.verdantPulse
        case .multiplier:   return AuraPalette.amethystBurst
        }
    }

    var glyphIconName: String {
        switch self {
        case .mundane:      return "star.fill"
        case .feralWild:    return "wand.and.rays"
        case .scatter:      return "sparkles"
        case .bonusTrigger: return "bolt.circle.fill"
        case .freeSpin:     return "arrow.clockwise.circle.fill"
        case .multiplier:   return "multiply.circle.fill"
        }
    }
}

// MARK: - Glyph Payout Table
struct GlyphPayoutTier: Codable {
    var matchCount: Int   // e.g. 3, 4, 5
    var coinsAwarded: Double
}

// MARK: - Glyph Model
class GlyphModel: Codable, ObservableObject {
    var riftId: UUID
    var appellationLabel: String   // Display name
    var glyphCategory: GlyphCategory
    var spawnProbability: Double   // 0.0 – 1.0
    var loadWeight: Int            // Reel strip weight
    var payoutTiers: [GlyphPayoutTier]
    var isAnchoredSticky: Bool     // Sticky feature
    var expansionCapable: Bool     // Expanding wild
    var stackedOccurrence: Bool    // Stacked symbol
    var specialRuleDescriptor: String

    // Derived
    var normalizedFrequency: Double { max(0.0001, min(1.0, spawnProbability)) }

    init(appellationLabel: String, glyphCategory: GlyphCategory = .mundane) {
        self.riftId = UUID()
        self.appellationLabel = appellationLabel
        self.glyphCategory = glyphCategory
        self.spawnProbability = 0.1
        self.loadWeight = 10
        self.payoutTiers = [
            GlyphPayoutTier(matchCount: 3, coinsAwarded: 5),
            GlyphPayoutTier(matchCount: 4, coinsAwarded: 15),
            GlyphPayoutTier(matchCount: 5, coinsAwarded: 50)
        ]
        self.isAnchoredSticky = false
        self.expansionCapable = false
        self.stackedOccurrence = false
        self.specialRuleDescriptor = ""
    }

    // Convenience factory
    static func makeDefaultGlyphSet() -> [GlyphModel] {
        let defs: [(String, GlyphCategory, Double, Int)] = [
            ("Diamond",  .mundane,      0.15, 15),
            ("Crown",    .mundane,      0.12, 12),
            ("Gem",      .mundane,      0.18, 18),
            ("Bar",      .mundane,      0.20, 20),
            ("Seven",    .mundane,      0.10, 10),
            ("Wildfire", .feralWild,    0.06,  6),
            ("Nova",     .scatter,      0.05,  5),
            ("Bonus",    .bonusTrigger, 0.04,  4),
            ("Spin+",    .freeSpin,     0.05,  5),
            ("x2",       .multiplier,   0.05,  5)
        ]
        return defs.map { (name, cat, prob, wt) in
            let g = GlyphModel(appellationLabel: name, glyphCategory: cat)
            g.spawnProbability = prob
            g.loadWeight = wt
            return g
        }
    }
}

// Equatable for UI diffing
extension GlyphModel: Equatable {
    static func == (lhs: GlyphModel, rhs: GlyphModel) -> Bool { lhs.riftId == rhs.riftId }
}
