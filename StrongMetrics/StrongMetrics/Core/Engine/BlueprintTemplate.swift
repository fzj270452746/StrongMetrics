// BlueprintTemplate.swift
// Predefined slot game design templates.

import Foundation

// MARK: - Blueprint Template
struct BlueprintTemplate {
    var templateTag: String
    var displayName: String
    var iconSFName: String
    var descriptor: String
    var rtpRange: ClosedRange<Double>
    var volatilityLabel: String
    var featureHighlights: [String]

    // Factory method to create a VaultProject from this template
    func instantiateVaultProject() -> VaultProject {
        let project = VaultProject(title: displayName)
        project.templateTag = templateTag
        project.rtpTarget = rtpRange.upperBound
        // Apply template-specific configs
        templateConfigurator(project)
        return project
    }

    private let templateConfigurator: (VaultProject) -> Void

    init(
        tag: String,
        name: String,
        icon: String,
        desc: String,
        rtp: ClosedRange<Double>,
        volatility: String,
        highlights: [String],
        configurator: @escaping (VaultProject) -> Void = { _ in }
    ) {
        self.templateTag = tag
        self.displayName = name
        self.iconSFName = icon
        self.descriptor = desc
        self.rtpRange = rtp
        self.volatilityLabel = volatility
        self.featureHighlights = highlights
        self.templateConfigurator = configurator
    }
}

// MARK: - Template Library
struct BlueprintLibrary {
    static let allTemplates: [BlueprintTemplate] = [
        .blankCanvas,
        .classicFruiter,
        .megawaysEngine,
        .holdAndSpin,
        .cascadeReels,
        .pragmaticStyle,
        .buyBonusSlot,
        .clusterPays
    ]

    static func templateForTag(_ tag: String) -> BlueprintTemplate? {
        allTemplates.first { $0.templateTag == tag }
    }
}

extension BlueprintTemplate {

    // MARK: - Blank Canvas
    static let blankCanvas = BlueprintTemplate(
        tag: "blank",
        name: "Blank Canvas",
        icon: "rectangle.dashed",
        desc: "Start from scratch with a clean slate.",
        rtp: 0.90...0.97,
        volatility: "Custom",
        highlights: ["No preset mechanics", "Full configuration freedom"]
    )

    // MARK: - Classic Fruiter
    static let classicFruiter = BlueprintTemplate(
        tag: "classic_fruit",
        name: "Classic Fruiter",
        icon: "circles.hexagonpath.fill",
        desc: "Traditional 3×3 reel with 9 paylines. Perfect for casual play.",
        rtp: 0.94...0.96,
        volatility: "Low",
        highlights: ["3×3 Grid", "9 Paylines", "Wild substitute", "Simple multiplier"],
        configurator: { project in
            project.spoolLayout = SpoolLayoutModel(preset: .canonical343)
            project.rtpTarget = 0.95
            project.volatilityTarget = .glacial
        }
    )

    // MARK: - Megaways Engine
    static let megawaysEngine = BlueprintTemplate(
        tag: "megaways",
        name: "Megaways Engine",
        icon: "squareshape.split.2x2.dotted",
        desc: "Variable-row reels up to 117,649 ways. Maximum excitement.",
        rtp: 0.95...0.97,
        volatility: "Very High",
        highlights: ["6 Reels", "Up to 117,649 Ways", "Cascading wins", "Free Spins multiplier ladder"],
        configurator: { project in
            project.spoolLayout = SpoolLayoutModel(preset: .megaways)
            project.rtpTarget = 0.965
            project.volatilityTarget = .supernova
            project.bonusGameDescriptor.bonusKind = .freeSpin
            project.bonusGameDescriptor.freeSpinCount = 12
        }
    )

    // MARK: - Hold & Spin
    static let holdAndSpin = BlueprintTemplate(
        tag: "hold_spin",
        name: "Hold & Spin",
        icon: "lock.rotation",
        desc: "Money symbols collect during bonus phase. Popular high-volatility mechanic.",
        rtp: 0.95...0.96,
        volatility: "High",
        highlights: ["Money symbol collection", "3-life respins", "Mini / Minor / Major / Grand jackpot", "6×5 Grid"],
        configurator: { project in
            project.spoolLayout = SpoolLayoutModel(preset: .hexagonal)
            project.rtpTarget = 0.955
            project.volatilityTarget = .volcanic
            project.bonusGameDescriptor.bonusKind = .holdSpin
        }
    )

    // MARK: - Cascade Reels
    static let cascadeReels = BlueprintTemplate(
        tag: "cascade",
        name: "Cascade Reels",
        icon: "chevron.compact.down",
        desc: "Winning symbols explode and new ones fall in for chain reactions.",
        rtp: 0.95...0.97,
        volatility: "Medium-High",
        highlights: ["Cascade on every win", "Multiplier progression", "5×5 Grid", "Cluster pays"],
        configurator: { project in
            project.spoolLayout = SpoolLayoutModel(preset: .infinite)
            project.rtpTarget = 0.96
            project.volatilityTarget = .volcanic
        }
    )

    // MARK: - Pragmatic Style
    static let pragmaticStyle = BlueprintTemplate(
        tag: "pragmatic",
        name: "Pragmatic Style",
        icon: "p.circle.fill",
        desc: "5×3 layout with 20 paylines and a scatter-triggered free spins round.",
        rtp: 0.95...0.97,
        volatility: "Medium",
        highlights: ["5×4 Grid", "20 Paylines", "10 Free Spins", "Sticky Wild"],
        configurator: { project in
            project.spoolLayout = SpoolLayoutModel(preset: .standard344)
            project.rtpTarget = 0.965
            project.volatilityTarget = .temperate
            project.bonusGameDescriptor.bonusKind = .freeSpin
            project.bonusGameDescriptor.freeSpinCount = 10
            project.bonusGameDescriptor.stickyWildEnabled = true
        }
    )

    // MARK: - Buy Bonus Slot
    static let buyBonusSlot = BlueprintTemplate(
        tag: "buy_bonus",
        name: "Buy Bonus",
        icon: "cart.fill",
        desc: "Players can directly purchase the bonus round. High volatility design.",
        rtp: 0.95...0.97,
        volatility: "Very High",
        highlights: ["Bonus purchase mechanic", "Ultra-rare bonus trigger", "Massive multiplier ceiling", "5×3 Grid"],
        configurator: { project in
            project.spoolLayout = SpoolLayoutModel(preset: .standard344)
            project.rtpTarget = 0.965
            project.volatilityTarget = .supernova
            project.bonusGameDescriptor.bonusKind = .freeSpin
            project.bonusGameDescriptor.freeSpinCount = 15
        }
    )

    // MARK: - Cluster Pays
    static let clusterPays = BlueprintTemplate(
        tag: "cluster",
        name: "Cluster Pays",
        icon: "dot.arrowtriangles.up.right.down.left.bitrianglesquare",
        desc: "Wins from clusters of 5+ matching symbols. No traditional paylines.",
        rtp: 0.95...0.97,
        volatility: "High",
        highlights: ["7×7 Grid", "Cluster mechanic", "Symbol explosion", "Wild bomb"],
        configurator: { project in
            project.spoolLayout = SpoolLayoutModel(preset: .hexagonal)
            project.rtpTarget = 0.96
            project.volatilityTarget = .volcanic
        }
    )
}
