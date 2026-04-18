// PulseSimVC.swift
// Simulation panel — run Monte Carlo and display live results.

import UIKit

class PulseSimVC: UIViewController {

    // MARK: - Properties
    var vaultProject: VaultProject!
    private var latestResult: OracleRunResult?
    private var isRunning = false

    // UI
    private var scrollView: UIScrollView!
    private var contentStack: UIStackView!
    private var runButton: NeonButton!
    private var progressBar: UIProgressView!
    private var progressLabel: UILabel!
    private var cancelButton: NeonIconButton!

    // Metric cards
    private var rtpCard:      MetricCard!
    private var hitRateCard:  MetricCard!
    private var peakCard:     MetricCard!
    private var volatCard:    MetricCard!
    private var burstCard:    MetricCard!

    // Charts
    private var trendChart:  RTPTrendLineChart!
    private var distChart:   WinDistributionChart!
    private var feelGauge:   FeelScoreGaugeView!

    // Settings
    private var iterStepper: UISegmentedControl!

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        buildSimInterface()
    }

    // MARK: - Build UI
    private func buildSimInterface() {
        view.backgroundColor = AuraPalette.voidBlack

        // Header
        let headerView = buildHeader()
        headerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(headerView)

        // Scroll content
        scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        contentStack = UIStackView()
        contentStack.axis = .vertical
        contentStack.spacing = ManifoldSpacing.standard
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStack)

        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: view.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 120),

            scrollView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: ManifoldSpacing.standard),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: ManifoldSpacing.standard),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -ManifoldSpacing.standard),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -ManifoldSpacing.major),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -ManifoldSpacing.grand)
        ])

        buildMetricCards()
        buildChartSection()
        buildFeelSection()
    }

    private func buildHeader() -> UIView {
        let v = UIView()
        v.backgroundColor = AuraPalette.cosmicDeep

        // Title
        let title = UILabel()
        title.text = "Simulation Engine"
        title.font = AuraTypeface.display(20)
        title.textColor = AuraPalette.starWhite
        title.translatesAutoresizingMaskIntoConstraints = false
        v.addSubview(title)

        // Iteration selector
        iterStepper = UISegmentedControl(items: ["10K", "100K", "1M"])
        iterStepper.selectedSegmentIndex = 1
        iterStepper.selectedSegmentTintColor = AuraPalette.amethystBurst
        iterStepper.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
        iterStepper.setTitleTextAttributes([.foregroundColor: AuraPalette.dimStar], for: .normal)
        iterStepper.translatesAutoresizingMaskIntoConstraints = false
        v.addSubview(iterStepper)

        // Run button
        runButton = NeonButton()
        runButton.buttonTitle = "▶  Run"
        runButton.variant = .verdantGreen
        runButton.translatesAutoresizingMaskIntoConstraints = false
        v.addSubview(runButton)
        runButton.addTarget(self, action: #selector(runSimulation), for: .touchUpInside)

        // Progress
        progressBar = UIProgressView(progressViewStyle: .default)
        progressBar.progressTintColor = AuraPalette.cobaltFlare
        progressBar.trackTintColor = AuraPalette.stellarPanel
        progressBar.layer.cornerRadius = 2
        progressBar.isHidden = true
        progressBar.translatesAutoresizingMaskIntoConstraints = false
        v.addSubview(progressBar)

        progressLabel = UILabel()
        progressLabel.font = AuraTypeface.caption(11)
        progressLabel.textColor = AuraPalette.cobaltFlare
        progressLabel.isHidden = true
        progressLabel.translatesAutoresizingMaskIntoConstraints = false
        v.addSubview(progressLabel)

        cancelButton = NeonIconButton()
        cancelButton.configure(sfName: "stop.circle.fill", tint: AuraPalette.emberCrimson)
        cancelButton.backgroundColor = AuraPalette.nebulaCard
        cancelButton.layer.cornerRadius = 16
        cancelButton.isHidden = true
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        v.addSubview(cancelButton)
        cancelButton.addTarget(self, action: #selector(cancelSimulation), for: .touchUpInside)

        NSLayoutConstraint.activate([
            title.leadingAnchor.constraint(equalTo: v.leadingAnchor, constant: ManifoldSpacing.standard),
            title.topAnchor.constraint(equalTo: v.topAnchor, constant: ManifoldSpacing.standard),

            iterStepper.leadingAnchor.constraint(equalTo: v.leadingAnchor, constant: ManifoldSpacing.standard),
            iterStepper.topAnchor.constraint(equalTo: title.bottomAnchor, constant: ManifoldSpacing.minor),
            iterStepper.widthAnchor.constraint(equalToConstant: 180),
            iterStepper.heightAnchor.constraint(equalToConstant: 32),

            runButton.trailingAnchor.constraint(equalTo: v.trailingAnchor, constant: -ManifoldSpacing.standard),
            runButton.centerYAnchor.constraint(equalTo: iterStepper.centerYAnchor),
            runButton.widthAnchor.constraint(equalToConstant: 100),
            runButton.heightAnchor.constraint(equalToConstant: 38),

            progressBar.leadingAnchor.constraint(equalTo: v.leadingAnchor, constant: ManifoldSpacing.standard),
            progressBar.trailingAnchor.constraint(equalTo: cancelButton.leadingAnchor, constant: -ManifoldSpacing.minor),
            progressBar.bottomAnchor.constraint(equalTo: v.bottomAnchor, constant: -ManifoldSpacing.minor),
            progressBar.heightAnchor.constraint(equalToConstant: 6),

            progressLabel.leadingAnchor.constraint(equalTo: v.leadingAnchor, constant: ManifoldSpacing.standard),
            progressLabel.bottomAnchor.constraint(equalTo: progressBar.topAnchor, constant: -2),

            cancelButton.trailingAnchor.constraint(equalTo: v.trailingAnchor, constant: -ManifoldSpacing.standard),
            cancelButton.centerYAnchor.constraint(equalTo: progressBar.centerYAnchor),
            cancelButton.widthAnchor.constraint(equalToConstant: 32),
            cancelButton.heightAnchor.constraint(equalToConstant: 32)
        ])

        return v
    }

    private func buildMetricCards() {
        let cardRow1 = UIStackView()
        cardRow1.axis = .horizontal
        cardRow1.spacing = ManifoldSpacing.minor
        cardRow1.distribution = .fillEqually

        rtpCard = MetricCard(title: "RTP", value: "—", color: AuraPalette.amethystBurst)
        hitRateCard = MetricCard(title: "Hit Rate", value: "—", color: AuraPalette.cobaltFlare)
        peakCard = MetricCard(title: "Peak Win", value: "—", color: AuraPalette.prismaticGold)
        volatCard = MetricCard(title: "Volatility", value: "—", color: AuraPalette.emberCrimson)

        cardRow1.addArrangedSubview(rtpCard)
        cardRow1.addArrangedSubview(hitRateCard)

        let cardRow2 = UIStackView()
        cardRow2.axis = .horizontal
        cardRow2.spacing = ManifoldSpacing.minor
        cardRow2.distribution = .fillEqually
        cardRow2.addArrangedSubview(peakCard)
        cardRow2.addArrangedSubview(volatCard)

        [cardRow1, cardRow2].forEach {
            contentStack.addArrangedSubview($0)
            $0.heightAnchor.constraint(equalToConstant: 80).isActive = true
        }
    }

    private func buildChartSection() {
        // RTP Trend
        let trendHeader = sectionLabel("RTP Trend (per 1,000 spins)")
        contentStack.addArrangedSubview(trendHeader)

        trendChart = RTPTrendLineChart()
        trendChart.lineColor = AuraPalette.cobaltFlare
        trendChart.backgroundColor = AuraPalette.nebulaCard
        trendChart.layer.cornerRadius = ManifoldSpacing.cornerM
        trendChart.heightAnchor.constraint(equalToConstant: 160).isActive = true
        contentStack.addArrangedSubview(trendChart)

        // Win Distribution
        let distHeader = sectionLabel("Win Distribution")
        contentStack.addArrangedSubview(distHeader)

        distChart = WinDistributionChart()
        distChart.accentColor = AuraPalette.prismaticGold
        distChart.backgroundColor = AuraPalette.nebulaCard
        distChart.layer.cornerRadius = ManifoldSpacing.cornerM
        distChart.heightAnchor.constraint(equalToConstant: 160).isActive = true
        contentStack.addArrangedSubview(distChart)
    }

    private func buildFeelSection() {
        let feelHeader = sectionLabel("Feel Score™")
        contentStack.addArrangedSubview(feelHeader)

        let feelCard = UIView()
        feelCard.backgroundColor = AuraPalette.nebulaCard
        feelCard.layer.cornerRadius = ManifoldSpacing.cornerM
        feelCard.layer.borderWidth = ManifoldSpacing.borderW
        feelCard.layer.borderColor = AuraPalette.subtleBorder.cgColor
        feelCard.translatesAutoresizingMaskIntoConstraints = false
        contentStack.addArrangedSubview(feelCard)
        feelCard.heightAnchor.constraint(equalToConstant: 110).isActive = true

        feelGauge = FeelScoreGaugeView()
        feelGauge.translatesAutoresizingMaskIntoConstraints = false
        feelGauge.backgroundColor = .clear
        feelCard.addSubview(feelGauge)
        NSLayoutConstraint.activate([
            feelGauge.topAnchor.constraint(equalTo: feelCard.topAnchor, constant: ManifoldSpacing.standard),
            feelGauge.leadingAnchor.constraint(equalTo: feelCard.leadingAnchor, constant: ManifoldSpacing.standard),
            feelGauge.trailingAnchor.constraint(equalTo: feelCard.trailingAnchor, constant: -ManifoldSpacing.standard),
            feelGauge.bottomAnchor.constraint(equalTo: feelCard.bottomAnchor, constant: -ManifoldSpacing.standard)
        ])

        let descLabel = UILabel()
        descLabel.text = "Feel Score™ measures the subjective excitement level: Burst = big-win frequency, Rhythm = win cadence."
        descLabel.font = AuraTypeface.caption(11)
        descLabel.textColor = AuraPalette.ghostText
        descLabel.numberOfLines = 0
        contentStack.addArrangedSubview(descLabel)
    }

    private func sectionLabel(_ text: String) -> UILabel {
        let l = UILabel()
        l.text = text
        l.font = AuraTypeface.headline(14)
        l.textColor = AuraPalette.dimStar
        return l
    }

    // MARK: - Simulation
    @objc private func runSimulation() {
        guard !isRunning else { return }
        isRunning = true

        // Configure iterations
        let selIndex = iterStepper.selectedSegmentIndex
        switch selIndex {
        case 0: vaultProject.simulationParameters.rapidMode = true; vaultProject.simulationParameters.precisionMode = false
        case 2: vaultProject.simulationParameters.rapidMode = false; vaultProject.simulationParameters.precisionMode = true
        default: vaultProject.simulationParameters.rapidMode = false; vaultProject.simulationParameters.precisionMode = false
        }

        setLoadingState(true)

        OracleSimulator.shared.precipitateSimulation(
            project: vaultProject,
            progressCallback: { [weak self] progress in
                DispatchQueue.main.async {
                    self?.progressBar.setProgress(Float(progress), animated: true)
                    self?.progressLabel.text = String(format: "%.0f%% complete", progress * 100)
                }
            },
            completion: { [weak self] result in
                self?.isRunning = false
                self?.setLoadingState(false)
                self?.applySimulationResult(result)
            }
        )
    }

    @objc private func cancelSimulation() {
        OracleSimulator.shared.cancelRun()
        isRunning = false
        setLoadingState(false)
    }

    private func setLoadingState(_ loading: Bool) {
        runButton.isLoading = loading
        runButton.isHidden = loading
        cancelButton.isHidden = !loading
        progressBar.isHidden = !loading
        progressLabel.isHidden = !loading
        if loading { progressBar.setProgress(0, animated: false) }
    }

    private func applySimulationResult(_ result: OracleRunResult) {
        latestResult = result

        rtpCard.updateValue(result.formattedRTP, subtitle: "Target: \(String(format: "%.2f%%", vaultProject.rtpTarget * 100))")
        hitRateCard.updateValue(result.formattedHitRate, subtitle: "\(String(format: "%.1f%%", result.hitRate * 100)) win freq")
        peakCard.updateValue("\(Int(result.peakMultiplier))×", subtitle: "Avg win: \(String(format: "%.1f×", result.avgWinMultiplier))")
        volatCard.updateValue(String(format: "%.2f", result.volatilityIndex), subtitle: "Index (0–1)")

        trendChart.rtpDataPoints = Array(result.rtpByThousandSpins.prefix(100))
        trendChart.targetRTP = vaultProject.rtpTarget
        trendChart.setNeedsDisplay()

        distChart.winDistribution = result.winDistribution
        distChart.setNeedsDisplay()

        feelGauge.burstScore = result.feelScoreBurst
        feelGauge.rhythmScore = result.feelScoreRhythm
        feelGauge.setNeedsDisplay()

        // Flash RTP card if off-target
        let diff = abs(result.rtp - vaultProject.rtpTarget)
        if diff > 0.02 {
            PrismAlertView.showAlert(in: view, icon: "⚠️", title: "RTP Off-Target",
                                     body: "Simulated RTP \(result.formattedRTP) deviates from target by \(String(format: "%.2f%%", diff * 100)). Adjust symbol weights.",
                                     actions: [PrismAction(title: "OK", style: .primary)])
        }
    }
}

// MARK: - Metric Card
class MetricCard: UIView {
    private let titleLabel    = UILabel()
    private let valueLabel    = UILabel()
    private let subtitleLabel = UILabel()
    private let accentLine    = UIView()

    init(title: String, value: String, color: UIColor) {
        super.init(frame: .zero)
        backgroundColor = AuraPalette.nebulaCard
        layer.cornerRadius = ManifoldSpacing.cornerM
        layer.borderWidth = ManifoldSpacing.borderW
        layer.borderColor = color.withAlphaComponent(0.4).cgColor

        accentLine.backgroundColor = color
        accentLine.layer.cornerRadius = 2
        accentLine.translatesAutoresizingMaskIntoConstraints = false

        titleLabel.text = title
        titleLabel.font = AuraTypeface.caption(10)
        titleLabel.textColor = AuraPalette.ghostText
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        valueLabel.text = value
        valueLabel.font = AuraTypeface.mono(22)
        valueLabel.textColor = color
        valueLabel.adjustsFontSizeToFitWidth = true
        valueLabel.minimumScaleFactor = 0.7
        valueLabel.translatesAutoresizingMaskIntoConstraints = false

        subtitleLabel.font = AuraTypeface.caption(10)
        subtitleLabel.textColor = AuraPalette.dimStar
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false

        addSubview(accentLine)
        addSubview(titleLabel)
        addSubview(valueLabel)
        addSubview(subtitleLabel)

        NSLayoutConstraint.activate([
            accentLine.topAnchor.constraint(equalTo: topAnchor),
            accentLine.leadingAnchor.constraint(equalTo: leadingAnchor, constant: ManifoldSpacing.minor),
            accentLine.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -ManifoldSpacing.minor),
            accentLine.heightAnchor.constraint(equalToConstant: 3),

            titleLabel.topAnchor.constraint(equalTo: accentLine.bottomAnchor, constant: ManifoldSpacing.minor),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: ManifoldSpacing.minor),

            valueLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 2),
            valueLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: ManifoldSpacing.minor),
            valueLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -ManifoldSpacing.minor),

            subtitleLabel.topAnchor.constraint(equalTo: valueLabel.bottomAnchor),
            subtitleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: ManifoldSpacing.minor)
        ])
    }
    required init?(coder: NSCoder) { fatalError() }

    func updateValue(_ value: String, subtitle: String = "") {
        UIView.transition(with: valueLabel, duration: 0.3, options: .transitionCrossDissolve) {
            self.valueLabel.text = value
        }
        subtitleLabel.text = subtitle
    }
}
