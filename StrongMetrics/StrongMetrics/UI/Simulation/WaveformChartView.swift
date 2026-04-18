// WaveformChartView.swift
// Custom Core Graphics chart views for RTP, volatility, and win distribution.

import UIKit

// MARK: - Win Distribution Bar Chart
class WinDistributionChart: UIView {

    var winDistribution: [Double: Int] = [:] { didSet { setNeedsDisplay() } }
    var accentColor: UIColor = AuraPalette.amethystBurst

    override func draw(_ rect: CGRect) {
        guard let ctx = UIGraphicsGetCurrentContext(), !winDistribution.isEmpty else { return }
        ctx.clear(rect)

        let sortedKeys = winDistribution.keys.sorted()
        let maxCount = winDistribution.values.max() ?? 1
        let barCount = sortedKeys.count
        let availW = rect.width - 40
        let barW = max(8, availW / CGFloat(barCount) - 4)
        let maxH = rect.height - 40

        for (i, key) in sortedKeys.enumerated() {
            let count = winDistribution[key] ?? 0
            let barH = maxH * CGFloat(count) / CGFloat(maxCount)
            let x = 20 + CGFloat(i) * (barW + 4)
            let y = rect.height - 24 - barH

            // Gradient bar
            let barRect = CGRect(x: x, y: y, width: barW, height: barH)
            let colors = accentColor.neonVariant.gradientCgColors as CFArray
            let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                      colors: colors, locations: [0, 1])!
            ctx.saveGState()
            let barPath = UIBezierPath(roundedRect: barRect, byRoundingCorners: [.topLeft, .topRight], cornerRadii: CGSize(width: 3, height: 3))
            ctx.addPath(barPath.cgPath)
            ctx.clip()
            ctx.drawLinearGradient(gradient, start: CGPoint(x: x, y: y + barH), end: CGPoint(x: x, y: y), options: [])
            ctx.restoreGState()

            // X label
            let label = key >= 1000 ? "\(Int(key/1000))kx" : "\(Int(key))x"
            let attrs: [NSAttributedString.Key: Any] = [
                .font: AuraTypeface.caption(8),
                .foregroundColor: AuraPalette.dimStar
            ]
            let labelSize = (label as NSString).size(withAttributes: attrs)
            let labelRect = CGRect(x: x + barW/2 - labelSize.width/2, y: rect.height - 20, width: labelSize.width, height: 12)
            (label as NSString).draw(in: labelRect, withAttributes: attrs)
        }

        // Axis line
        ctx.setStrokeColor(AuraPalette.subtleBorder.cgColor)
        ctx.setLineWidth(0.5)
        ctx.move(to: CGPoint(x: 20, y: rect.height - 24))
        ctx.addLine(to: CGPoint(x: rect.width - 10, y: rect.height - 24))
        ctx.strokePath()
    }
}

// MARK: - RTP Trend Line Chart
class RTPTrendLineChart: UIView {

    var rtpDataPoints: [Double] = [] { didSet { setNeedsDisplay() } }
    var targetRTP: Double = 0.96
    var lineColor: UIColor = AuraPalette.cobaltFlare

    override func draw(_ rect: CGRect) {
        guard let ctx = UIGraphicsGetCurrentContext(), rtpDataPoints.count > 1 else { return }
        ctx.clear(rect)

        let inset: CGFloat = 16
        let drawRect = rect.insetBy(dx: inset, dy: inset)

        // Draw target line
        let targetY = drawRect.maxY - drawRect.height * CGFloat(targetRTP)
        ctx.setStrokeColor(AuraPalette.prismaticGold.withAlphaComponent(0.5).cgColor)
        ctx.setLineWidth(1)
        ctx.setLineDash(phase: 0, lengths: [6, 4])
        ctx.move(to: CGPoint(x: drawRect.minX, y: targetY))
        ctx.addLine(to: CGPoint(x: drawRect.maxX, y: targetY))
        ctx.strokePath()
        ctx.setLineDash(phase: 0, lengths: [])

        // Draw RTP trend
        let n = rtpDataPoints.count
        let xStep = drawRect.width / CGFloat(n - 1)
        let minVal = max(0.5, rtpDataPoints.min() ?? 0.9)
        let maxVal = min(1.1, rtpDataPoints.max() ?? 1.0)
        let valRange = max(0.01, maxVal - minVal)

        func pointFor(_ i: Int) -> CGPoint {
            let x = drawRect.minX + CGFloat(i) * xStep
            let normalized = (rtpDataPoints[i] - minVal) / valRange
            let y = drawRect.maxY - drawRect.height * CGFloat(normalized)
            return CGPoint(x: x, y: y)
        }

        // Fill under curve
        let fillPath = UIBezierPath()
        fillPath.move(to: CGPoint(x: drawRect.minX, y: drawRect.maxY))
        fillPath.addLine(to: pointFor(0))
        for i in 1..<n {
            let p0 = pointFor(i - 1)
            let p1 = pointFor(i)
            let ctrl = CGPoint(x: (p0.x + p1.x) / 2, y: (p0.y + p1.y) / 2)
            fillPath.addQuadCurve(to: ctrl, controlPoint: CGPoint(x: (p0.x + ctrl.x) / 2, y: p0.y))
            fillPath.addQuadCurve(to: p1, controlPoint: CGPoint(x: (ctrl.x + p1.x) / 2, y: p1.y))
        }
        fillPath.addLine(to: CGPoint(x: drawRect.maxX, y: drawRect.maxY))
        fillPath.close()

        ctx.saveGState()
        ctx.addPath(fillPath.cgPath)
        ctx.clip()
        let fillColors = [lineColor.withAlphaComponent(0.3).cgColor, lineColor.withAlphaComponent(0).cgColor] as CFArray
        let fillGrad = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: fillColors, locations: [0, 1])!
        ctx.drawLinearGradient(fillGrad, start: CGPoint(x: 0, y: drawRect.minY), end: CGPoint(x: 0, y: drawRect.maxY), options: [])
        ctx.restoreGState()

        // Draw line
        let linePath = UIBezierPath()
        linePath.move(to: pointFor(0))
        for i in 1..<n {
            let p0 = pointFor(i - 1)
            let p1 = pointFor(i)
            let ctrl = CGPoint(x: (p0.x + p1.x) / 2, y: (p0.y + p1.y) / 2)
            linePath.addQuadCurve(to: ctrl, controlPoint: CGPoint(x: (p0.x + ctrl.x) / 2, y: p0.y))
            linePath.addQuadCurve(to: p1, controlPoint: CGPoint(x: (ctrl.x + p1.x) / 2, y: p1.y))
        }
        ctx.setStrokeColor(lineColor.cgColor)
        ctx.setLineWidth(2.5)
        ctx.addPath(linePath.cgPath)
        ctx.strokePath()

        // Data points
        for i in 0..<n where i % max(1, n / 20) == 0 {
            let p = pointFor(i)
            ctx.setFillColor(lineColor.cgColor)
            ctx.fillEllipse(in: CGRect(x: p.x - 2, y: p.y - 2, width: 4, height: 4))
        }
    }
}

// MARK: - Feel Score Gauge
class FeelScoreGaugeView: UIView {

    var burstScore: Double = 0 { didSet { setNeedsDisplay() } }
    var rhythmScore: Double = 0 { didSet { setNeedsDisplay() } }

    override func draw(_ rect: CGRect) {
        guard let ctx = UIGraphicsGetCurrentContext() else { return }
        ctx.clear(rect)

        drawGauge(ctx: ctx, rect: rect, score: burstScore, color: AuraPalette.emberCrimson,
                  label: "BURST", yOffset: 0)
        drawGauge(ctx: ctx, rect: rect, score: rhythmScore, color: AuraPalette.verdantPulse,
                  label: "RHYTHM", yOffset: rect.height / 2 + 4)
    }

    private func drawGauge(ctx: CGContext, rect: CGRect, score: Double, color: UIColor, label: String, yOffset: CGFloat) {
        let barRect = CGRect(x: 0, y: yOffset, width: rect.width, height: rect.height / 2 - 4)
        let inset: CGFloat = 12
        let gaugeRect = barRect.insetBy(dx: inset, dy: barRect.height * 0.25)

        // Background track
        let trackPath = UIBezierPath(roundedRect: gaugeRect, cornerRadius: gaugeRect.height / 2)
        ctx.setFillColor(AuraPalette.subtleBorder.cgColor)
        ctx.addPath(trackPath.cgPath)
        ctx.fillPath()

        // Filled portion
        let fillW = gaugeRect.width * CGFloat(max(0, min(1, score / 100)))
        if fillW > 0 {
            let fillRect = CGRect(x: gaugeRect.minX, y: gaugeRect.minY, width: fillW, height: gaugeRect.height)
            let fillPath = UIBezierPath(roundedRect: fillRect, cornerRadius: gaugeRect.height / 2)
            ctx.setFillColor(color.cgColor)
            ctx.addPath(fillPath.cgPath)
            ctx.fillPath()

            // Glow
            ctx.setShadow(offset: .zero, blur: 8, color: color.withAlphaComponent(0.8).cgColor)
            ctx.addPath(fillPath.cgPath)
            ctx.fillPath()
            ctx.setShadow(offset: .zero, blur: 0, color: UIColor.clear.cgColor)
        }

        // Label
        let labelAttrs: [NSAttributedString.Key: Any] = [
            .font: AuraTypeface.caption(9),
            .foregroundColor: AuraPalette.dimStar
        ]
        (label as NSString).draw(at: CGPoint(x: inset, y: barRect.minY + 2), withAttributes: labelAttrs)

        let scoreStr = String(format: "%.0f", score)
        let scoreAttrs: [NSAttributedString.Key: Any] = [
            .font: AuraTypeface.mono(12),
            .foregroundColor: color
        ]
        let scoreSize = (scoreStr as NSString).size(withAttributes: scoreAttrs)
        (scoreStr as NSString).draw(at: CGPoint(x: rect.width - scoreSize.width - inset, y: barRect.minY + 2), withAttributes: scoreAttrs)
    }
}

// MARK: - UIColor neon variant helper
extension UIColor {
    var neonVariant: NeonColorVariant { NeonColorVariant(base: self) }
}

struct NeonColorVariant {
    let base: UIColor
    var gradientCgColors: [CGColor] {
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        base.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        let lighter = UIColor(hue: h, saturation: max(0, s - 0.1), brightness: min(1, b + 0.2), alpha: a)
        let darker  = UIColor(hue: h, saturation: min(1, s + 0.1), brightness: max(0, b - 0.1), alpha: a)
        return [darker.cgColor, lighter.cgColor]
    }
}
