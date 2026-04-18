// YieldCalculator.swift
// Analytical RTP, volatility, and slot metrics calculator.

import Foundation

// MARK: - Yield Metrics (analytical, no Monte Carlo)
struct YieldMetrics {
    var analyticalRTP: Double
    var theoreticalHitRate: Double
    var varianceEstimate: Double
    var payoutCeiling: Double
    var paylineContributions: [String: Double] // Feature → RTP contribution
    var glyphContributions: [UUID: Double]     // Glyph → RTP contribution
    var volatilityBand: String
}

// MARK: - Yield Calculator
class YieldCalculator {
    static let shared = YieldCalculator()
    private init() {}

    // MARK: - Main analytical calculation
    func computeAnalyticalYield(project: VaultProject) -> YieldMetrics {
        let glyphs = project.glyphRegistry
        let layout = project.spoolLayout

        var baseRTP = 0.0
        var hitRate = 0.0
        var glyphContribs: [UUID: Double] = [:]
        var payoutCeiling = 0.0

        let cols = layout.spools.count
        let totalWeightPerSpool = layout.spools.map { spool -> Double in
            Double(spool.stripEntries.reduce(0) { $0 + $1.repetitions })
        }

        for glyph in glyphs where glyph.glyphCategory != .scatter {
            var contribution = 0.0

            for tier in glyph.payoutTiers {
                guard tier.matchCount >= 3 else { continue }
                let effectiveMatchCount = min(tier.matchCount, cols)
                guard effectiveMatchCount > 0 else { continue }
                // Probability of hitting this glyph on `matchCount` consecutive columns
                var probability = 1.0
                for c in 0..<effectiveMatchCount {
                    let spoolWeight = totalWeightPerSpool[c]
                    let glyphWeight = Double(layout.spools[c].weightFor(glyphId: glyph.riftId))
                    probability *= spoolWeight > 0 ? glyphWeight / spoolWeight : 0
                }
                // Remaining cols = non-matching
                for c in effectiveMatchCount..<cols {
                    let spoolWeight = totalWeightPerSpool[c]
                    let glyphWeight = Double(layout.spools[c].weightFor(glyphId: glyph.riftId))
                    let nonMatchProb = spoolWeight > 0 ? (spoolWeight - glyphWeight) / spoolWeight : 1.0
                    probability *= nonMatchProb
                }
                let lines = Double(layout.paylineCount > 0 ? layout.paylineCount : 20)
                let lineContrib = probability * tier.coinsAwarded / lines
                contribution += lineContrib

                if tier.coinsAwarded > payoutCeiling {
                    payoutCeiling = tier.coinsAwarded
                }
            }

            baseRTP += contribution
            glyphContribs[glyph.riftId] = contribution
        }

        // Scatter RTP contribution
        var scatterContrib = 0.0
        for glyph in glyphs where glyph.glyphCategory == .scatter {
            for tier in glyph.payoutTiers {
                guard tier.matchCount >= 3 else { continue }
                let prob = computeScatterProbability(glyph: glyph, layout: layout, count: tier.matchCount)
                scatterContrib += prob * tier.coinsAwarded
            }
            glyphContribs[glyph.riftId] = scatterContrib
        }
        baseRTP += scatterContrib

        // Hit rate estimation
        hitRate = estimateHitRate(glyphs: glyphs, layout: layout)

        // Variance estimate (simplified)
        let variance = estimateVariance(rtp: baseRTP, hitRate: hitRate, ceiling: payoutCeiling)

        // Volatility band
        let volBand = classifyVolatility(rtp: baseRTP, hitRate: hitRate, variance: variance)

        let paylineContribs: [String: Double] = [
            "Base Game": baseRTP - scatterContrib,
            "Scatter": scatterContrib
        ]

        return YieldMetrics(
            analyticalRTP: min(1.0, max(0, baseRTP)),
            theoreticalHitRate: hitRate,
            varianceEstimate: variance,
            payoutCeiling: payoutCeiling,
            paylineContributions: paylineContribs,
            glyphContributions: glyphContribs,
            volatilityBand: volBand
        )
    }

    // MARK: - Scatter probability
    private func computeScatterProbability(glyph: GlyphModel, layout: SpoolLayoutModel, count: Int) -> Double {
        let cols = layout.spools.count
        var totalProb = 0.0
        // C(cols, count) combinations of scatter positions
        let combinations = combinatorialPairs(n: cols, k: count)
        for combo in combinations {
            var prob = 1.0
            for c in 0..<cols {
                let spool = layout.spools[c]
                let total = Double(spool.stripEntries.reduce(0) { $0 + $1.repetitions })
                let wt = Double(spool.weightFor(glyphId: glyph.riftId))
                if combo.contains(c) {
                    prob *= total > 0 ? wt / total : 0
                } else {
                    prob *= total > 0 ? (total - wt) / total : 1
                }
            }
            totalProb += prob
        }
        return totalProb
    }

    private func combinatorialPairs(n: Int, k: Int) -> [[Int]] {
        guard k <= n, k > 0 else { return [] }
        var result: [[Int]] = []
        var combo = [Int](0..<k)
        result.append(combo)
        while true {
            var i = k - 1
            while i >= 0 && combo[i] == i + n - k { i -= 1 }
            if i < 0 { break }
            combo[i] += 1
            for j in (i+1)..<k { combo[j] = combo[j-1] + 1 }
            result.append(combo)
        }
        return result
    }

    // MARK: - Hit rate
    private func estimateHitRate(glyphs: [GlyphModel], layout: SpoolLayoutModel) -> Double {
        let cols = layout.spools.count
        guard cols >= 3 else { return 0 }

        // Probability of at least 3-of-a-kind on payline
        var noneHitProb = 1.0
        for glyph in glyphs where glyph.glyphCategory == .mundane {
            var pHit = 1.0
            for c in 0..<3 {
                let spool = layout.spools[c]
                let total = Double(spool.stripEntries.reduce(0) { $0 + $1.repetitions })
                let wt = Double(spool.weightFor(glyphId: glyph.riftId))
                pHit *= total > 0 ? wt / total : 0
            }
            let lines = Double(max(1, layout.paylineCount))
            noneHitProb *= max(0, 1.0 - pHit * lines)
        }
        return max(0, min(1, 1.0 - noneHitProb))
    }

    // MARK: - Variance
    private func estimateVariance(rtp: Double, hitRate: Double, ceiling: Double) -> Double {
        let avgWin = hitRate > 0 ? rtp / hitRate : 0
        let variance = hitRate * (1 - hitRate) * pow(avgWin, 2) + hitRate * pow(ceiling, 2) * 0.001
        return variance
    }

    // MARK: - Volatility classification
    private func classifyVolatility(rtp: Double, hitRate: Double, variance: Double) -> String {
        let normVar = min(1.0, variance / 1000.0)
        switch normVar {
        case 0..<0.2: return "Low Volatility"
        case 0.2..<0.5: return "Medium Volatility"
        case 0.5..<0.75: return "High Volatility"
        default: return "Very High Volatility"
        }
    }

    // MARK: - Heatmap Data
    struct HeatCell {
        var column: Int
        var row: Int
        var thermalIntensity: Double  // 0.0 – 1.0
        var dominantGlyphId: UUID?
    }

    func generateThermalHeatmap(project: VaultProject) -> [[HeatCell]] {
        let layout = project.spoolLayout
        let glyphs = project.glyphRegistry
        let cols = layout.spools.count
        let rows = layout.layoutPreset.rowCount

        var heatmap: [[HeatCell]] = []

        for c in 0..<cols {
            var colCells: [HeatCell] = []
            let spool = layout.spools[c]
            let totalWeight = Double(spool.stripEntries.reduce(0) { $0 + $1.repetitions })

            // Find highest-value glyph probability
            for r in 0..<rows {
                var maxValue = 0.0
                var dominantId: UUID?
                for entry in spool.stripEntries {
                    let prob = totalWeight > 0 ? Double(entry.repetitions) / totalWeight : 0
                    if let g = glyphs.first(where: { $0.riftId == entry.glyphId }) {
                        let value = prob * (g.payoutTiers.last?.coinsAwarded ?? 0)
                        if value > maxValue {
                            maxValue = value
                            dominantId = g.riftId
                        }
                    }
                }
                let intensity = min(1.0, maxValue / 100.0)
                colCells.append(HeatCell(column: c, row: r, thermalIntensity: intensity, dominantGlyphId: dominantId))
            }
            heatmap.append(colCells)
        }
        return heatmap
    }
}
