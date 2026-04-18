// NexusBonusVC.swift
// Bonus game builder — configure Pick, Wheel, Free Spin, Hold & Spin bonus mechanics.

import UIKit
import SpriteKit

class NexusBonusVC: UIViewController {

    // MARK: - Properties
    var vaultProject: VaultProject!
    private var bonusDescriptor: BonusGameDescriptor { vaultProject.bonusGameDescriptor }

    // UI
    private var scrollView: UIScrollView!
    private var contentStack: UIStackView!
    private var bonusTypeSelector: UISegmentedControl!
    private var previewCard: BonusPreviewCard!
    private var configPanel: UIView!

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        buildNexusInterface()
        refreshBonusTypeUI()
    }

    // MARK: - Build UI
    private func buildNexusInterface() {
        view.backgroundColor = AuraPalette.voidBlack

        let header = makeHeader()
        header.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(header)

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
            header.topAnchor.constraint(equalTo: view.topAnchor),
            header.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            header.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            header.heightAnchor.constraint(equalToConstant: 120),

            scrollView.topAnchor.constraint(equalTo: header.bottomAnchor, constant: ManifoldSpacing.minor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: ManifoldSpacing.standard),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -ManifoldSpacing.standard),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -ManifoldSpacing.grand),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -ManifoldSpacing.grand)
        ])

        // Preview
        previewCard = BonusPreviewCard()
        previewCard.heightAnchor.constraint(equalToConstant: 220).isActive = true
        contentStack.addArrangedSubview(previewCard)

        // Config
        contentStack.addArrangedSubview(sectionLabel("Configuration"))
        configPanel = UIView()
        configPanel.translatesAutoresizingMaskIntoConstraints = false
        contentStack.addArrangedSubview(configPanel)

        buildConfigPanel()

        // Save button
        let saveBtn = NeonButton()
        saveBtn.buttonTitle = "Save Bonus Config"
        saveBtn.variant = .goldAccent
        saveBtn.heightAnchor.constraint(equalToConstant: 46).isActive = true
        saveBtn.addTarget(self, action: #selector(saveBonusConfig), for: .touchUpInside)
        contentStack.addArrangedSubview(saveBtn)
    }

    private func makeHeader() -> UIView {
        let v = UIView()
        v.backgroundColor = AuraPalette.cosmicDeep

        let titleLbl = UILabel()
        titleLbl.text = "Bonus Builder"
        titleLbl.font = AuraTypeface.display(20)
        titleLbl.textColor = AuraPalette.starWhite
        titleLbl.translatesAutoresizingMaskIntoConstraints = false
        v.addSubview(titleLbl)

        // Bonus type selector
        let kinds = BonusGameDescriptor.BonusKind.allCases.map { $0.rawValue }
        bonusTypeSelector = UISegmentedControl(items: kinds)
        bonusTypeSelector.selectedSegmentIndex = BonusGameDescriptor.BonusKind.allCases.firstIndex(of: vaultProject.bonusGameDescriptor.bonusKind) ?? 0
        bonusTypeSelector.selectedSegmentTintColor = AuraPalette.emberCrimson
        bonusTypeSelector.setTitleTextAttributes([.foregroundColor: UIColor.white, .font: AuraTypeface.caption(10)], for: .normal)
        bonusTypeSelector.setTitleTextAttributes([.foregroundColor: UIColor.white, .font: AuraTypeface.caption(10)], for: .selected)
        bonusTypeSelector.addTarget(self, action: #selector(bonusTypeSelectorChanged), for: .valueChanged)
        bonusTypeSelector.translatesAutoresizingMaskIntoConstraints = false
        v.addSubview(bonusTypeSelector)

        NSLayoutConstraint.activate([
            titleLbl.leadingAnchor.constraint(equalTo: v.leadingAnchor, constant: ManifoldSpacing.standard),
            titleLbl.topAnchor.constraint(equalTo: v.topAnchor, constant: ManifoldSpacing.standard),
            bonusTypeSelector.leadingAnchor.constraint(equalTo: v.leadingAnchor, constant: ManifoldSpacing.standard),
            bonusTypeSelector.trailingAnchor.constraint(equalTo: v.trailingAnchor, constant: -ManifoldSpacing.standard),
            bonusTypeSelector.bottomAnchor.constraint(equalTo: v.bottomAnchor, constant: -ManifoldSpacing.standard),
            bonusTypeSelector.heightAnchor.constraint(equalToConstant: 36)
        ])

        return v
    }

    private func buildConfigPanel() {
        configPanel.backgroundColor = AuraPalette.nebulaCard
        configPanel.layer.cornerRadius = ManifoldSpacing.cornerM
        configPanel.translatesAutoresizingMaskIntoConstraints = false
        configPanel.heightAnchor.constraint(greaterThanOrEqualToConstant: 120).isActive = true
        refreshBonusConfigView()
    }

    // MARK: - Refresh per bonus type
    @objc private func bonusTypeSelectorChanged() {
        let idx = bonusTypeSelector.selectedSegmentIndex
        let kind = BonusGameDescriptor.BonusKind.allCases[idx]
        vaultProject.bonusGameDescriptor.bonusKind = kind
        refreshBonusTypeUI()
    }

    private func refreshBonusTypeUI() {
        previewCard.configure(bonusKind: vaultProject.bonusGameDescriptor.bonusKind)
        refreshBonusConfigView()
    }

    private func refreshBonusConfigView() {
        configPanel.subviews.forEach { $0.removeFromSuperview() }

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = ManifoldSpacing.minor
        stack.translatesAutoresizingMaskIntoConstraints = false
        configPanel.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: configPanel.topAnchor, constant: ManifoldSpacing.standard),
            stack.leadingAnchor.constraint(equalTo: configPanel.leadingAnchor, constant: ManifoldSpacing.standard),
            stack.trailingAnchor.constraint(equalTo: configPanel.trailingAnchor, constant: -ManifoldSpacing.standard),
            stack.bottomAnchor.constraint(equalTo: configPanel.bottomAnchor, constant: -ManifoldSpacing.standard)
        ])

        switch vaultProject.bonusGameDescriptor.bonusKind {
        case .freeSpin:
            buildFreeSpinConfig(stack: stack)
        case .spinWheel:
            buildWheelConfig(stack: stack)
        case .pickReveal:
            buildPickConfig(stack: stack)
        case .holdSpin:
            buildHoldSpinConfig(stack: stack)
        case .climbLadder:
            buildLadderConfig(stack: stack)
        }
    }

    // MARK: - Free Spin Config
    private func buildFreeSpinConfig(stack: UIStackView) {
        let countLabel = makeConfigLabel("Free Spin Count: \(vaultProject.bonusGameDescriptor.freeSpinCount)")
        let countSlider = UISlider()
        countSlider.minimumValue = 5
        countSlider.maximumValue = 50
        countSlider.value = Float(vaultProject.bonusGameDescriptor.freeSpinCount)
        countSlider.tintColor = AuraPalette.verdantPulse
        countSlider.addTarget(self, action: #selector(freeSpinCountChanged(_:)), for: .valueChanged)

        let stickyLabel = makeConfigLabel("Sticky Wild")
        let stickySwitch = UISwitch()
        stickySwitch.isOn = vaultProject.bonusGameDescriptor.stickyWildEnabled
        stickySwitch.onTintColor = AuraPalette.verdantPulse
        stickySwitch.addTarget(self, action: #selector(stickyWildToggled(_:)), for: .valueChanged)

        let stickyRow = UIStackView()
        stickyRow.addArrangedSubview(stickyLabel)
        stickyRow.addArrangedSubview(stickySwitch)

        [countLabel, countSlider, stickyRow].forEach { stack.addArrangedSubview($0) }
        countSlider.heightAnchor.constraint(equalToConstant: 32).isActive = true
    }

    // MARK: - Wheel Config
    private func buildWheelConfig(stack: UIStackView) {
        let header = makeConfigLabel("Wheel Segments (reward : weight)")
        stack.addArrangedSubview(header)

        let defaultSegments: [WheelSegment] = vaultProject.bonusGameDescriptor.rewardEntries.isEmpty ?
            [WheelSegment(segmentLabel: "5×", rewardMultiplier: 5, probabilityWeight: 30, isJackpot: false),
             WheelSegment(segmentLabel: "10×", rewardMultiplier: 10, probabilityWeight: 20, isJackpot: false),
             WheelSegment(segmentLabel: "25×", rewardMultiplier: 25, probabilityWeight: 15, isJackpot: false),
             WheelSegment(segmentLabel: "50×", rewardMultiplier: 50, probabilityWeight: 10, isJackpot: false),
             WheelSegment(segmentLabel: "JACKPOT", rewardMultiplier: 500, probabilityWeight: 2, isJackpot: true)] :
            vaultProject.bonusGameDescriptor.rewardEntries

        if vaultProject.bonusGameDescriptor.rewardEntries.isEmpty {
            vaultProject.bonusGameDescriptor.rewardEntries = defaultSegments
        }

        for (i, seg) in (vaultProject.bonusGameDescriptor.rewardEntries).enumerated() {
            let row = buildWheelSegmentRow(seg, index: i)
            stack.addArrangedSubview(row)
        }
    }

    private func buildWheelSegmentRow(_ seg: WheelSegment, index: Int) -> UIView {
        let row = UIView()
        row.backgroundColor = seg.isJackpot ? AuraPalette.prismaticGold.withAlphaComponent(0.15) : AuraPalette.stellarPanel
        row.layer.cornerRadius = ManifoldSpacing.cornerS
        row.translatesAutoresizingMaskIntoConstraints = false
        row.heightAnchor.constraint(equalToConstant: 40).isActive = true

        let nameLbl = UILabel()
        nameLbl.text = seg.segmentLabel
        nameLbl.font = AuraTypeface.headline(13)
        nameLbl.textColor = seg.isJackpot ? AuraPalette.prismaticGold : AuraPalette.starWhite
        nameLbl.translatesAutoresizingMaskIntoConstraints = false

        let rewardLbl = UILabel()
        rewardLbl.text = "\(Int(seg.rewardMultiplier))× — Wt:\(Int(seg.probabilityWeight))"
        rewardLbl.font = AuraTypeface.mono(11)
        rewardLbl.textColor = AuraPalette.dimStar
        rewardLbl.translatesAutoresizingMaskIntoConstraints = false

        row.addSubview(nameLbl)
        row.addSubview(rewardLbl)
        NSLayoutConstraint.activate([
            nameLbl.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: ManifoldSpacing.minor),
            nameLbl.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            rewardLbl.trailingAnchor.constraint(equalTo: row.trailingAnchor, constant: -ManifoldSpacing.minor),
            rewardLbl.centerYAnchor.constraint(equalTo: row.centerYAnchor)
        ])
        return row
    }

    // MARK: - Pick Config
    private func buildPickConfig(stack: UIStackView) {
        let pickCountLabel = makeConfigLabel("Pick Count: \(vaultProject.bonusGameDescriptor.pickCount)")
        let pickSlider = UISlider()
        pickSlider.minimumValue = 1
        pickSlider.maximumValue = 10
        pickSlider.value = Float(vaultProject.bonusGameDescriptor.pickCount)
        pickSlider.tintColor = AuraPalette.emberCrimson
        pickSlider.addTarget(self, action: #selector(pickCountChanged(_:)), for: .valueChanged)

        let rangeLabel = makeConfigLabel("Reward Range: \(Int(vaultProject.bonusGameDescriptor.pickRewardRange.lowerBound))× – \(Int(vaultProject.bonusGameDescriptor.pickRewardRange.upperBound))×")

        [pickCountLabel, pickSlider, rangeLabel].forEach { stack.addArrangedSubview($0) }
        pickSlider.heightAnchor.constraint(equalToConstant: 32).isActive = true
    }

    // MARK: - Hold & Spin Config
    private func buildHoldSpinConfig(stack: UIStackView) {
        let desc = makeConfigLabel("Hold & Spin: Collect money symbols during 3-life respins. Each money symbol resets lives to 3.")
        desc.numberOfLines = 3
        let jpLabel = makeConfigLabel("Jackpots: Mini · Minor · Major · Grand (×50 / ×200 / ×1000 / ×5000)")
        jpLabel.numberOfLines = 2
        jpLabel.textColor = AuraPalette.prismaticGold
        [desc, jpLabel].forEach { stack.addArrangedSubview($0) }
    }

    // MARK: - Ladder Config
    private func buildLadderConfig(stack: UIStackView) {
        let desc = makeConfigLabel("Climb Ladder: Ascend rungs collecting multipliers. Collect or gamble at each step.")
        desc.numberOfLines = 2
        stack.addArrangedSubview(desc)
        for (i, mult) in vaultProject.bonusGameDescriptor.multiplierProgression.enumerated() {
            let rung = makeConfigLabel("Rung \(i+1): \(Int(mult))×")
            stack.addArrangedSubview(rung)
        }
    }

    // MARK: - Slider targets
    @objc private func freeSpinCountChanged(_ slider: UISlider) {
        let val = Int(slider.value)
        vaultProject.bonusGameDescriptor.freeSpinCount = val
        refreshBonusConfigView()
    }
    @objc private func stickyWildToggled(_ sw: UISwitch) {
        vaultProject.bonusGameDescriptor.stickyWildEnabled = sw.isOn
    }
    @objc private func pickCountChanged(_ slider: UISlider) {
        vaultProject.bonusGameDescriptor.pickCount = Int(slider.value)
        refreshBonusConfigView()
    }

    // MARK: - Save
    @objc private func saveBonusConfig() {
        vaultProject.persistToDisk()
        PrismAlertView.showSuccess(in: view, title: "Bonus Saved", body: "Configuration persisted to project.")
    }

    // MARK: - Helpers
    private func makeConfigLabel(_ text: String) -> UILabel {
        let lbl = UILabel()
        lbl.text = text
        lbl.font = AuraTypeface.body(13)
        lbl.textColor = AuraPalette.dimStar
        lbl.numberOfLines = 1
        return lbl
    }

    private func sectionLabel(_ text: String) -> UILabel {
        let l = UILabel()
        l.text = text
        l.font = AuraTypeface.headline(14)
        l.textColor = AuraPalette.dimStar
        return l
    }
}

// MARK: - Bonus Preview Card
class BonusPreviewCard: UIView {
    private let titleLabel    = UILabel()
    private let descLabel     = UILabel()
    private let iconView      = UIImageView()
    private let gradLayer     = CAGradientLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.cornerRadius = ManifoldSpacing.cornerL
        clipsToBounds = true

        gradLayer.cornerRadius = ManifoldSpacing.cornerL
        layer.insertSublayer(gradLayer, at: 0)

        titleLabel.font = AuraTypeface.display(22)
        titleLabel.textColor = AuraPalette.starWhite
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        descLabel.font = AuraTypeface.body(14)
        descLabel.textColor = AuraPalette.dimStar
        descLabel.numberOfLines = 3
        descLabel.translatesAutoresizingMaskIntoConstraints = false

        iconView.contentMode = .scaleAspectFit
        iconView.tintColor = UIColor.white.withAlphaComponent(0.3)
        iconView.translatesAutoresizingMaskIntoConstraints = false

        addSubview(iconView)
        addSubview(titleLabel)
        addSubview(descLabel)

        NSLayoutConstraint.activate([
            iconView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -ManifoldSpacing.standard),
            iconView.centerYAnchor.constraint(equalTo: centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 100),
            iconView.heightAnchor.constraint(equalToConstant: 100),

            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: ManifoldSpacing.major),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -20),

            descLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: ManifoldSpacing.major),
            descLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: ManifoldSpacing.minor),
            descLabel.trailingAnchor.constraint(equalTo: iconView.leadingAnchor, constant: -ManifoldSpacing.minor)
        ])
    }
    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradLayer.frame = bounds
    }

    func configure(bonusKind: BonusGameDescriptor.BonusKind) {
        titleLabel.text = bonusKind.rawValue

        let conf = UIImage.SymbolConfiguration(pointSize: 80, weight: .thin)
        switch bonusKind {
        case .pickReveal:
            gradLayer.colors = AuraPalette.crimsonGrad
            descLabel.text = "Reveal hidden prizes behind tiles. Each pick shows a multiplier or a jackpot."
            iconView.image = UIImage(systemName: "square.grid.3x3.fill", withConfiguration: conf)
        case .spinWheel:
            gradLayer.colors = AuraPalette.goldGrad
            descLabel.text = "Spin the wheel of fortune to land on multiplied rewards or jackpots."
            iconView.image = UIImage(systemName: "circle.dotted", withConfiguration: conf)
        case .freeSpin:
            gradLayer.colors = AuraPalette.verdantGrad
            descLabel.text = "Spin for free with special rules: sticky wilds, progressive multipliers, retriggers."
            iconView.image = UIImage(systemName: "arrow.clockwise.circle.fill", withConfiguration: conf)
        case .holdSpin:
            gradLayer.colors = AuraPalette.cyanGrad
            descLabel.text = "Money symbols lock in place as you respin, collecting coins and jackpots."
            iconView.image = UIImage(systemName: "lock.rotation", withConfiguration: conf)
        case .climbLadder:
            gradLayer.colors = AuraPalette.primaryGrad
            descLabel.text = "Collect or gamble as you climb the reward ladder, multiplying wins at each rung."
            iconView.image = UIImage(systemName: "chart.bar.fill", withConfiguration: conf)
        }
        gradLayer.startPoint = CGPoint(x: 0, y: 0.5)
        gradLayer.endPoint   = CGPoint(x: 1, y: 0.5)
    }
}
