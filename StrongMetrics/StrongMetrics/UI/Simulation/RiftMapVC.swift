// RiftMapVC.swift
// Volatility heatmap view — visualizes reel/symbol risk distribution.

import UIKit

class RiftMapVC: UIViewController {

    // MARK: - Properties
    var vaultProject: VaultProject!
    private var heatmapData: [[YieldCalculator.HeatCell]] = []

    private var heatmapView: RiftHeatmapView!
    private var legendView: UIView!
    private var metricsStack: UIStackView!
    private var analyticalMetrics: YieldMetrics?

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        buildRiftInterface()
        computeHeatmap()
    }

    // MARK: - Build UI
    private func buildRiftInterface() {
        view.backgroundColor = AuraPalette.voidBlack

        let headerStack = UIStackView()
        headerStack.axis = .vertical
        headerStack.spacing = ManifoldSpacing.micro
        headerStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(headerStack)

        let titleLbl = UILabel()
        titleLbl.text = "Volatility Heatmap"
        titleLbl.font = AuraTypeface.display(20)
        titleLbl.textColor = AuraPalette.starWhite

        let subtitleLbl = UILabel()
        subtitleLbl.text = "Thermal intensity = win value probability"
        subtitleLbl.font = AuraTypeface.caption(12)
        subtitleLbl.textColor = AuraPalette.dimStar

        headerStack.addArrangedSubview(titleLbl)
        headerStack.addArrangedSubview(subtitleLbl)

        // Heatmap
        heatmapView = RiftHeatmapView()
        heatmapView.translatesAutoresizingMaskIntoConstraints = false
        heatmapView.backgroundColor = AuraPalette.nebulaCard
        heatmapView.layer.cornerRadius = ManifoldSpacing.cornerL
        heatmapView.layer.borderWidth = ManifoldSpacing.borderW
        heatmapView.layer.borderColor = AuraPalette.subtleBorder.cgColor
        heatmapView.clipsToBounds = true
        view.addSubview(heatmapView)

        // Legend
        legendView = buildLegend()
        legendView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(legendView)

        // Analytics section
        let analyticsHeader = UILabel()
        analyticsHeader.text = "Analytical Estimates"
        analyticsHeader.font = AuraTypeface.headline(15)
        analyticsHeader.textColor = AuraPalette.dimStar
        analyticsHeader.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(analyticsHeader)

        metricsStack = UIStackView()
        metricsStack.axis = .vertical
        metricsStack.spacing = ManifoldSpacing.minor
        metricsStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(metricsStack)

        // Refresh button
        let refreshBtn = NeonButton()
        refreshBtn.buttonTitle = "Recompute"
        refreshBtn.iconSFName = "arrow.clockwise"
        refreshBtn.variant = .cyanOutline
        refreshBtn.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(refreshBtn)
        refreshBtn.addTarget(self, action: #selector(computeHeatmap), for: .touchUpInside)

        NSLayoutConstraint.activate([
            headerStack.topAnchor.constraint(equalTo: view.topAnchor, constant: ManifoldSpacing.standard),
            headerStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: ManifoldSpacing.standard),
            headerStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -ManifoldSpacing.standard),

            heatmapView.topAnchor.constraint(equalTo: headerStack.bottomAnchor, constant: ManifoldSpacing.standard),
            heatmapView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: ManifoldSpacing.standard),
            heatmapView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -ManifoldSpacing.standard),
            heatmapView.heightAnchor.constraint(equalToConstant: 200),

            legendView.topAnchor.constraint(equalTo: heatmapView.bottomAnchor, constant: ManifoldSpacing.minor),
            legendView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            legendView.heightAnchor.constraint(equalToConstant: 24),

            analyticsHeader.topAnchor.constraint(equalTo: legendView.bottomAnchor, constant: ManifoldSpacing.major),
            analyticsHeader.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: ManifoldSpacing.standard),

            metricsStack.topAnchor.constraint(equalTo: analyticsHeader.bottomAnchor, constant: ManifoldSpacing.minor),
            metricsStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: ManifoldSpacing.standard),
            metricsStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -ManifoldSpacing.standard),

            refreshBtn.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -ManifoldSpacing.standard),
            refreshBtn.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            refreshBtn.widthAnchor.constraint(equalToConstant: 160),
            refreshBtn.heightAnchor.constraint(equalToConstant: 44)
        ])
    }

    private func buildLegend() -> UIView {
        let container = UIView()
        let gradLayer = CAGradientLayer()
        gradLayer.colors = [
            UIColor(r: 0, g: 80, b: 160).cgColor,
            UIColor(r: 0, g: 200, b: 100).cgColor,
            UIColor(r: 255, g: 214, b: 0).cgColor,
            UIColor(r: 255, g: 100, b: 0).cgColor,
            UIColor(r: 255, g: 30, b: 80).cgColor
        ]
        gradLayer.startPoint = CGPoint(x: 0, y: 0.5)
        gradLayer.endPoint   = CGPoint(x: 1, y: 0.5)
        gradLayer.cornerRadius = 4
        container.layer.addSublayer(gradLayer)

        let lowLabel = UILabel()
        lowLabel.text = "Low"
        lowLabel.font = AuraTypeface.caption(10)
        lowLabel.textColor = AuraPalette.dimStar
        lowLabel.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(lowLabel)

        let highLabel = UILabel()
        highLabel.text = "High Risk"
        highLabel.font = AuraTypeface.caption(10)
        highLabel.textColor = AuraPalette.dimStar
        highLabel.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(highLabel)

        NSLayoutConstraint.activate([
            lowLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            lowLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            highLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            highLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            container.widthAnchor.constraint(equalToConstant: 240)
        ])

        DispatchQueue.main.async {
            gradLayer.frame = CGRect(x: 30, y: 5, width: 180, height: 14)
        }

        return container
    }

    // MARK: - Compute
    @objc private func computeHeatmap() {
        let heatmap = YieldCalculator.shared.generateThermalHeatmap(project: vaultProject)
        heatmapData = heatmap
        heatmapView.heatmapData = heatmap
        heatmapView.setNeedsDisplay()

        let metrics = YieldCalculator.shared.computeAnalyticalYield(project: vaultProject)
        analyticalMetrics = metrics
        updateMetricsDisplay(metrics)
    }

    private func updateMetricsDisplay(_ metrics: YieldMetrics) {
        metricsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        let rows: [(String, String, UIColor)] = [
            ("Analytical RTP", String(format: "%.3f%%", metrics.analyticalRTP * 100), AuraPalette.amethystBurst),
            ("Theoretical Hit Rate", String(format: "%.2f%%", metrics.theoreticalHitRate * 100), AuraPalette.cobaltFlare),
            ("Payout Ceiling", String(format: "%.0f×", metrics.payoutCeiling), AuraPalette.prismaticGold),
            ("Volatility Band", metrics.volatilityBand, AuraPalette.emberCrimson),
            ("Variance Estimate", String(format: "%.4f", metrics.varianceEstimate), AuraPalette.verdantPulse)
        ]

        for (label, value, color) in rows {
            let row = buildMetricRow(label: label, value: value, color: color)
            metricsStack.addArrangedSubview(row)
        }
    }

    private func buildMetricRow(label: String, value: String, color: UIColor) -> UIView {
        let row = UIView()
        row.backgroundColor = AuraPalette.nebulaCard
        row.layer.cornerRadius = ManifoldSpacing.cornerS
        row.layer.borderWidth = 0.5
        row.layer.borderColor = color.withAlphaComponent(0.3).cgColor
        row.translatesAutoresizingMaskIntoConstraints = false
        row.heightAnchor.constraint(equalToConstant: 40).isActive = true

        let lbl = UILabel()
        lbl.text = label
        lbl.font = AuraTypeface.body(13)
        lbl.textColor = AuraPalette.dimStar
        lbl.translatesAutoresizingMaskIntoConstraints = false

        let valLbl = UILabel()
        valLbl.text = value
        valLbl.font = AuraTypeface.mono(14)
        valLbl.textColor = color
        valLbl.translatesAutoresizingMaskIntoConstraints = false

        let dot = UIView()
        dot.backgroundColor = color
        dot.layer.cornerRadius = 4
        dot.translatesAutoresizingMaskIntoConstraints = false

        row.addSubview(dot)
        row.addSubview(lbl)
        row.addSubview(valLbl)

        NSLayoutConstraint.activate([
            dot.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: ManifoldSpacing.minor),
            dot.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            dot.widthAnchor.constraint(equalToConstant: 8),
            dot.heightAnchor.constraint(equalToConstant: 8),

            lbl.leadingAnchor.constraint(equalTo: dot.trailingAnchor, constant: ManifoldSpacing.minor),
            lbl.centerYAnchor.constraint(equalTo: row.centerYAnchor),

            valLbl.trailingAnchor.constraint(equalTo: row.trailingAnchor, constant: -ManifoldSpacing.standard),
            valLbl.centerYAnchor.constraint(equalTo: row.centerYAnchor)
        ])

        return row
    }
}

// MARK: - Rift Heatmap View (custom drawing)
class RiftHeatmapView: UIView {

    var heatmapData: [[YieldCalculator.HeatCell]] = [] { didSet { setNeedsDisplay() } }

    override func draw(_ rect: CGRect) {
        guard let ctx = UIGraphicsGetCurrentContext(), !heatmapData.isEmpty else { return }
        ctx.clear(rect)

        let cols = heatmapData.count
        let rows = heatmapData[0].count
        let cellW = rect.width / CGFloat(cols)
        let cellH = rect.height / CGFloat(rows)
        let padding: CGFloat = 2

        for (c, col) in heatmapData.enumerated() {
            for (r, cell) in col.enumerated() {
                let x = CGFloat(c) * cellW + padding
                let y = rect.height - CGFloat(r + 1) * cellH + padding
                let w = cellW - padding * 2
                let h = cellH - padding * 2

                let cellRect = CGRect(x: x, y: y, width: w, height: h)
                let cellPath = UIBezierPath(roundedRect: cellRect, cornerRadius: 6)

                let color = thermalColor(for: cell.thermalIntensity)
                ctx.setFillColor(color.cgColor)
                ctx.addPath(cellPath.cgPath)
                ctx.fillPath()

                // Glow for high-intensity cells
                if cell.thermalIntensity > 0.7 {
                    ctx.setShadow(offset: .zero, blur: 12, color: color.withAlphaComponent(0.8).cgColor)
                    ctx.setFillColor(color.withAlphaComponent(0.3).cgColor)
                    ctx.addPath(cellPath.cgPath)
                    ctx.fillPath()
                    ctx.setShadow(offset: .zero, blur: 0, color: UIColor.clear.cgColor)
                }

                // Column header (first row)
                if r == 0 {
                    let label = "R\(c + 1)"
                    let attrs: [NSAttributedString.Key: Any] = [
                        .font: AuraTypeface.caption(9),
                        .foregroundColor: AuraPalette.ghostText
                    ]
                    (label as NSString).draw(at: CGPoint(x: x + 4, y: y + h - 14), withAttributes: attrs)
                }
            }
        }
    }

    private func thermalColor(for intensity: Double) -> UIColor {
        let t = max(0, min(1, intensity))
        if t < 0.25 {
            // Cool blue → teal
            let s = t / 0.25
            return UIColor(r: Int(0 + s*0), g: Int(80 + s*100), b: Int(160 + s*(-60)))
        } else if t < 0.5 {
            // Teal → green
            let s = (t - 0.25) / 0.25
            return UIColor(r: Int(s * 100), g: Int(180 + s*50), b: Int(100 + s*(-100)))
        } else if t < 0.75 {
            // Green → gold
            let s = (t - 0.5) / 0.25
            return UIColor(r: Int(100 + s*155), g: Int(230 - s*16), b: Int(s * 10))
        } else {
            // Gold → crimson
            let s = (t - 0.75) / 0.25
            return UIColor(r: Int(255), g: Int(214 - s*184), b: Int(10 - s*10 + s*80))
        }
    }
}
