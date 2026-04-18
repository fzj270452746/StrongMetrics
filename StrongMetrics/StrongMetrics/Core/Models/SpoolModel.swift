// SpoolModel.swift
// Data model for a single reel (spool) in the slot configuration.

import Foundation

// MARK: - Reel Layout Preset
enum SpoolLayoutPreset: String, Codable, CaseIterable {
    case canonical343 = "3-4-3"
    case standard344 = "3-4-4-4-3"
    case megaways = "Megaways"
    case hexagonal = "6×6"
    case infinite = "Infinite Reel"

    var columnCount: Int {
        switch self {
        case .canonical343:  return 3
        case .standard344:   return 5
        case .megaways:      return 6
        case .hexagonal:     return 6
        case .infinite:      return 5
        }
    }

    var rowCount: Int {
        switch self {
        case .canonical343:  return 3
        case .standard344:   return 4
        case .megaways:      return 7
        case .hexagonal:     return 6
        case .infinite:      return 5
        }
    }

    var displayLabel: String { rawValue }
}

// MARK: - Reel Strip Entry
struct SpoolStripEntry: Codable {
    var glyphId: UUID
    var repetitions: Int    // How many times this glyph appears in the physical strip
    var stopPositions: [Int] // Positions on the strip
}

// MARK: - Spool Model (Single Reel)
class SpoolModel: Codable, ObservableObject {
    var spoolId: UUID
    var columnIndex: Int
    var stripEntries: [SpoolStripEntry]
    var stripLengthOverride: Int     // 0 = auto-calculate
    var spinVelocityFactor: Double   // Aesthetic speed factor

    // Computed
    var totalStripLength: Int {
        if stripLengthOverride > 0 { return stripLengthOverride }
        return stripEntries.reduce(0) { $0 + $1.repetitions }
    }

    init(columnIndex: Int) {
        self.spoolId = UUID()
        self.columnIndex = columnIndex
        self.stripEntries = []
        self.stripLengthOverride = 32
        self.spinVelocityFactor = 1.0
    }

    func appendGlyph(glyphId: UUID, count: Int = 1) {
        if let idx = stripEntries.firstIndex(where: { $0.glyphId == glyphId }) {
            stripEntries[idx].repetitions += count
        } else {
            stripEntries.append(SpoolStripEntry(glyphId: glyphId, repetitions: count, stopPositions: []))
        }
    }

    func weightFor(glyphId: UUID) -> Int {
        stripEntries.first(where: { $0.glyphId == glyphId })?.repetitions ?? 0
    }
}

// MARK: - Reel Layout (all reels combined)
class SpoolLayoutModel: Codable, ObservableObject {
    var layoutId: UUID
    var layoutPreset: SpoolLayoutPreset
    var spools: [SpoolModel]
    var paylineCount: Int
    var waysToWin: Int          // 0 = paylines, >0 = ways
    var betAmountBase: Double
    var maxLinesActive: Int

    init(preset: SpoolLayoutPreset = .standard344) {
        self.layoutId = UUID()
        self.layoutPreset = preset
        self.paylineCount = 20
        self.waysToWin = 0
        self.betAmountBase = 1.0
        self.maxLinesActive = 20
        self.spools = (0..<preset.columnCount).map { SpoolModel(columnIndex: $0) }
    }

    static func makeDefaultLayout() -> SpoolLayoutModel {
        let layout = SpoolLayoutModel(preset: .standard344)
        let glyphs = GlyphModel.makeDefaultGlyphSet()
        let weights = [15, 12, 18, 20, 10, 6, 5, 4, 5, 5]
        for (spool) in layout.spools {
            for (i, g) in glyphs.enumerated() {
                spool.appendGlyph(glyphId: g.riftId, count: max(1, i < weights.count ? weights[i] : 5))
            }
        }
        return layout
    }
}
