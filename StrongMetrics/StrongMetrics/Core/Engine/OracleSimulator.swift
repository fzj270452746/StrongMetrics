// OracleSimulator.swift
// Monte Carlo simulation engine for slot math analysis.

import Foundation

// MARK: - Simulation Result
struct OracleRunResult {
    var totalSpins: Int
    var totalWagered: Double
    var totalReturned: Double
    var rtp: Double                    // Return-to-player percentage
    var hitRate: Double                // Win frequency
    var peakMultiplier: Double         // Biggest single-spin win
    var avgWinMultiplier: Double       // Average win when winning
    var maxConsecutiveDry: Int         // Longest losing streak
    var volatilityIndex: Double        // Normalized variance index
    var feelScoreBurst: Double         // Big-win "burst feel" 0-100
    var feelScoreRhythm: Double        // Cadence/pace feel 0-100
    var spinPayouts: [Double]          // Sample of individual payouts (first 5000)
    var winDistribution: [Double: Int] // Multiplier bucket → count
    var rtpByThousandSpins: [Double]   // RTP trend over time

    var formattedRTP: String { String(format: "%.2f%%", rtp * 100) }
    var formattedHitRate: String { String(format: "1 in %.1f", hitRate > 0 ? 1.0 / hitRate : 0) }
}

// MARK: - Oracle Simulator
class OracleSimulator {
    static let shared = OracleSimulator()
    private init() {}

    private var isCancelled = false

    func cancelRun() { isCancelled = true }

    // MARK: - Main Simulation Entry
    func precipitateSimulation(
        project: VaultProject,
        progressCallback: ((Double) -> Void)? = nil,
        completion: @escaping (OracleRunResult) -> Void
    ) {
        isCancelled = false
        let params = project.simulationParameters
        let glyphs = project.glyphRegistry
        let layout = project.spoolLayout
        let totalSpins = params.effectiveIterations
        let betPerSpin = params.betAmountPerSpin

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            var result = self.runMonteCarloLoop(
                glyphs: glyphs, layout: layout,
                totalSpins: totalSpins, betPerSpin: betPerSpin,
                progressCallback: progressCallback
            )
            DispatchQueue.main.async { completion(result) }
        }
    }

    // MARK: - Monte Carlo Core
    private func runMonteCarloLoop(
        glyphs: [GlyphModel],
        layout: SpoolLayoutModel,
        totalSpins: Int,
        betPerSpin: Double,
        progressCallback: ((Double) -> Void)?
    ) -> OracleRunResult {

        let columns = layout.spools.count
        let rows = layout.layoutPreset.rowCount
        let totalWagered = Double(totalSpins) * betPerSpin

        var totalReturned = 0.0
        var wins = 0
        var peakMultiplier = 0.0
        var sumWinMult = 0.0
        var currentDry = 0
        var maxDry = 0
        var spinPayouts: [Double] = []
        var winDistribution: [Double: Int] = [:]
        var rtpByThousand: [Double] = []
        var rollingReturn = 0.0

        let reportInterval = max(1, totalSpins / 100)

        for spinIdx in 0..<totalSpins {
            if isCancelled { break }

            // Spin the reels
            let grid = spinGrid(spools: layout.spools, glyphs: glyphs, rows: rows)
            let payout = evaluateGrid(grid: grid, glyphs: glyphs, layout: layout, bet: betPerSpin)

            totalReturned += payout
            rollingReturn += payout

            let mult = payout / betPerSpin
            if payout > 0 {
                wins += 1
                sumWinMult += mult
                peakMultiplier = max(peakMultiplier, mult)
                currentDry = 0
                let bucket = bucketMultiplier(mult)
                winDistribution[bucket, default: 0] += 1
            } else {
                currentDry += 1
                maxDry = max(maxDry, currentDry)
            }

            if spinIdx < 5000 { spinPayouts.append(payout / betPerSpin) }

            // Track RTP per 1000 spins
            if (spinIdx + 1) % 1000 == 0 {
                let rtpSnapshot = rollingReturn / (1000 * betPerSpin)
                rtpByThousand.append(rtpSnapshot)
                rollingReturn = 0
            }

            if spinIdx % reportInterval == 0 {
                progressCallback?(Double(spinIdx) / Double(totalSpins))
            }
        }

        let rtp = totalWagered > 0 ? totalReturned / totalWagered : 0
        let hitRate = totalSpins > 0 ? Double(wins) / Double(totalSpins) : 0
        let avgWin = wins > 0 ? sumWinMult / Double(wins) : 0

        // Compute volatility index
        let volatilityIdx = computeVolatilityIndex(payouts: spinPayouts, bet: betPerSpin)

        // Feel scores
        let burstScore = computeBurstScore(peakMult: peakMultiplier, winDist: winDistribution)
        let rhythmScore = computeRhythmScore(hitRate: hitRate, maxDry: maxDry)

        return OracleRunResult(
            totalSpins: totalSpins,
            totalWagered: totalWagered,
            totalReturned: totalReturned,
            rtp: rtp,
            hitRate: hitRate,
            peakMultiplier: peakMultiplier,
            avgWinMultiplier: avgWin,
            maxConsecutiveDry: maxDry,
            volatilityIndex: volatilityIdx,
            feelScoreBurst: burstScore,
            feelScoreRhythm: rhythmScore,
            spinPayouts: spinPayouts,
            winDistribution: winDistribution,
            rtpByThousandSpins: rtpByThousand
        )
    }

    // MARK: - Grid Spinner
    private func spinGrid(spools: [SpoolModel], glyphs: [GlyphModel], rows: Int) -> [[GlyphModel?]] {
        var grid: [[GlyphModel?]] = []
        for spool in spools {
            var col: [GlyphModel?] = []
            for _ in 0..<rows {
                col.append(randomGlyph(from: spool, registry: glyphs))
            }
            grid.append(col)
        }
        return grid
    }

    private func randomGlyph(from spool: SpoolModel, registry: [GlyphModel]) -> GlyphModel? {
        let totalWeight = spool.stripEntries.reduce(0) { $0 + $1.repetitions }
        guard totalWeight > 0 else { return nil }
        let roll = Int.random(in: 0..<totalWeight)
        var acc = 0
        for entry in spool.stripEntries {
            acc += entry.repetitions
            if roll < acc {
                return registry.first { $0.riftId == entry.glyphId }
            }
        }
        return registry.first
    }

    // MARK: - Grid Evaluator
    private func evaluateGrid(
        grid: [[GlyphModel?]],
        glyphs: [GlyphModel],
        layout: SpoolLayoutModel,
        bet: Double
    ) -> Double {
        let cols = grid.count
        guard cols > 0 else { return 0 }
        let rows = grid[0].count

        var totalPayout = 0.0

        // Ways-to-win evaluation
        if layout.waysToWin > 0 {
            totalPayout += evaluateWaysToWin(grid: grid, glyphs: glyphs, bet: bet)
        } else {
            // Payline evaluation (simplified: 20 paylines using standard patterns)
            totalPayout += evaluatePaylines(grid: grid, glyphs: glyphs, rows: rows, bet: bet)
        }

        // Scatter wins (appear anywhere)
        totalPayout += evaluateScatterWins(grid: grid, glyphs: glyphs, bet: bet)

        return totalPayout
    }

    private func evaluateWaysToWin(grid: [[GlyphModel?]], glyphs: [GlyphModel], bet: Double) -> Double {
        let cols = grid.count
        var payout = 0.0

        // Count occurrences of each non-wild glyph per column
        for glyph in glyphs where glyph.glyphCategory == .mundane || glyph.glyphCategory == .multiplier {
            var ways = 1
            var matchCols = 0

            for col in 0..<cols {
                let colGlyphs = grid[col].compactMap { $0 }
                let matchInCol = colGlyphs.filter { $0.riftId == glyph.riftId || $0.glyphCategory == .feralWild }.count
                if matchInCol > 0 {
                    ways *= matchInCol
                    matchCols += 1
                } else {
                    break
                }
            }

            if matchCols >= 3 {
                let mult = glyph.payoutTiers.first(where: { $0.matchCount == matchCols })?.coinsAwarded ?? 0
                payout += bet * mult * Double(ways) / 243.0
            }
        }
        return payout
    }

    private func evaluatePaylines(grid: [[GlyphModel?]], glyphs: [GlyphModel], rows: Int, bet: Double) -> Double {
        // Standard 20 paylines (simplified as horizontal rows + diagonals)
        let midRow = rows / 2
        let patterns: [[Int]] = (0..<rows).map { r in Array(repeating: r, count: grid.count) } +
            [Array(0..<grid.count).map { c in min(c, rows - 1) }] +
            [Array(0..<grid.count).map { c in max(0, rows - 1 - c) }]

        var totalPayout = 0.0
        for pattern in patterns {
            totalPayout += evaluateLine(grid: grid, pattern: pattern, glyphs: glyphs, bet: bet)
        }
        return totalPayout
    }

    private func evaluateLine(grid: [[GlyphModel?]], pattern: [Int], glyphs: [GlyphModel], bet: Double) -> Double {
        let cols = min(grid.count, pattern.count)
        guard cols > 0, pattern[0] < grid[0].count else { return 0 }

        let firstSymbol = grid[0][pattern[0]]
        var matchCount = 1
        var effectiveSymbol = firstSymbol

        // Find matching sequence
        for c in 1..<cols {
            guard pattern[c] < grid[c].count else { break }
            let sym = grid[c][pattern[c]]
            if sym?.riftId == effectiveSymbol?.riftId || sym?.glyphCategory == .feralWild {
                matchCount += 1
                if effectiveSymbol?.glyphCategory == .feralWild { effectiveSymbol = sym }
            } else if effectiveSymbol?.glyphCategory == .feralWild {
                matchCount += 1
                effectiveSymbol = sym
            } else {
                break
            }
        }

        guard matchCount >= 3, let glyph = effectiveSymbol else { return 0 }
        let mult = glyph.payoutTiers.first(where: { $0.matchCount == matchCount })?.coinsAwarded ?? 0
        return bet * mult
    }

    private func evaluateScatterWins(grid: [[GlyphModel?]], glyphs: [GlyphModel], bet: Double) -> Double {
        let scatterGlyphs = glyphs.filter { $0.glyphCategory == .scatter }
        var payout = 0.0
        for scatter in scatterGlyphs {
            let count = grid.flatMap { $0 }.filter { $0?.riftId == scatter.riftId }.count
            if count >= 3 {
                let mult = scatter.payoutTiers.first(where: { $0.matchCount == count })?.coinsAwarded ??
                           scatter.payoutTiers.last?.coinsAwarded ?? 0
                payout += bet * mult
            }
        }
        return payout
    }

    // MARK: - Analytics Helpers
    private func bucketMultiplier(_ mult: Double) -> Double {
        let thresholds: [Double] = [1, 2, 5, 10, 20, 50, 100, 200, 500, 1000]
        for t in thresholds where mult <= t { return t }
        return 1000
    }

    private func computeVolatilityIndex(payouts: [Double], bet: Double) -> Double {
        guard payouts.count > 1 else { return 0 }
        let mults = payouts.map { $0 > 0 ? $0 : 0 }
        let mean = mults.reduce(0, +) / Double(mults.count)
        let variance = mults.map { pow($0 - mean, 2) }.reduce(0, +) / Double(mults.count)
        let stdDev = sqrt(variance)
        return min(1.0, stdDev / 50.0) // Normalize to 0-1
    }

    private func computeBurstScore(peakMult: Double, winDist: [Double: Int]) -> Double {
        let jackpotWins = (winDist[200] ?? 0) + (winDist[500] ?? 0) + (winDist[1000] ?? 0)
        let totalWins = winDist.values.reduce(0, +)
        let jackpotRatio = totalWins > 0 ? Double(jackpotWins) / Double(totalWins) : 0
        let peakScore = min(1.0, log10(max(1, peakMult)) / 4.0)
        return (peakScore * 0.6 + jackpotRatio * 100 * 0.4) * 100
    }

    private func computeRhythmScore(hitRate: Double, maxDry: Int) -> Double {
        // Higher hitRate = better rhythm; shorter dry streaks = better rhythm
        let hitScore = min(1.0, hitRate * 3) // 33% hit rate = perfect
        let dryPenalty = min(1.0, Double(maxDry) / 100.0)
        return max(0, (hitScore - dryPenalty * 0.3)) * 100
    }
}
