// VaultProject.swift
// Top-level project model that holds all slot design data.

import Foundation

// MARK: - Vault Project (main project container)
class VaultProject: Codable, ObservableObject {
    var vaultId: UUID
    var projectTitle: String
    var modifiedTimestamp: Date
    var createdTimestamp: Date

    // Sub-models
    var glyphRegistry: [GlyphModel]
    var spoolLayout: SpoolLayoutModel
    var latticeGraph: LatticeGraph
    var simulationParameters: SimulationParameters
    var bonusGameDescriptor: BonusGameDescriptor

    // Metadata
    var templateTag: String
    var rtpTarget: Double             // Target RTP e.g. 0.96
    var volatilityTarget: VolatilityBand
    var notesMarkdown: String

    enum VolatilityBand: String, Codable, CaseIterable {
        case glacial = "Low"
        case temperate = "Medium"
        case volcanic = "High"
        case supernova = "Very High"

        var numericMidpoint: Double {
            switch self { case .glacial: return 0.2; case .temperate: return 0.5; case .volcanic: return 0.75; case .supernova: return 0.95 }
        }
    }

    init(title: String = "New Slot Project") {
        self.vaultId = UUID()
        self.projectTitle = title
        self.modifiedTimestamp = Date()
        self.createdTimestamp = Date()
        self.glyphRegistry = GlyphModel.makeDefaultGlyphSet()
        self.spoolLayout = SpoolLayoutModel.makeDefaultLayout()
        self.latticeGraph = LatticeGraph.makeInitialGraph()
        self.simulationParameters = SimulationParameters()
        self.bonusGameDescriptor = BonusGameDescriptor()
        self.templateTag = "Custom"
        self.rtpTarget = 0.96
        self.volatilityTarget = .temperate
        self.notesMarkdown = ""
    }

    func persistToDisk() {
        guard let data = try? JSONEncoder().encode(self) else { return }
        let url = VaultProject.persistenceURL(for: vaultId)
        try? data.write(to: url)
        modifiedTimestamp = Date()
    }

    static func loadFromDisk(id: UUID) -> VaultProject? {
        let url = persistenceURL(for: id)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(VaultProject.self, from: data)
    }

    static func persistenceURL(for id: UUID) -> URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent("\(id.uuidString).vaultproj")
    }

    static func allProjectIds() -> [UUID] {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let files = (try? FileManager.default.contentsOfDirectory(at: docs, includingPropertiesForKeys: nil)) ?? []
        return files.compactMap { url -> UUID? in
            guard url.pathExtension == "vaultproj" else { return nil }
            return UUID(uuidString: url.deletingPathExtension().lastPathComponent)
        }
    }

    static func deleteProject(id: UUID) {
        try? FileManager.default.removeItem(at: persistenceURL(for: id))
    }
}

// MARK: - Simulation Parameters
struct SimulationParameters: Codable {
    var iterationCount: Int = 100_000
    var betAmountPerSpin: Double = 1.0
    var rapidMode: Bool = false    // 10k spins
    var precisionMode: Bool = false // 1M spins

    var effectiveIterations: Int {
        if rapidMode { return 10_000 }
        if precisionMode { return 1_000_000 }
        return iterationCount
    }
}

// MARK: - Bonus Game Descriptor
struct BonusGameDescriptor: Codable {
    enum BonusKind: String, Codable, CaseIterable {
        case pickReveal = "Pick & Reveal"
        case spinWheel  = "Spin Wheel"
        case freeSpin   = "Free Spin"
        case holdSpin   = "Hold & Spin"
        case climbLadder = "Climb Ladder"
    }

    var bonusKind: BonusKind = .pickReveal
    var rewardEntries: [WheelSegment] = []
    var freeSpinCount: Int = 10
    var stickyWildEnabled: Bool = false
    var multiplierProgression: [Double] = [2, 3, 5, 10]
    var pickCount: Int = 3
    var pickRewardRange: ClosedRange<Double> = 5...200

    enum CodingKeys: String, CodingKey {
        case bonusKind, rewardEntries, freeSpinCount, stickyWildEnabled
        case multiplierProgression, pickCount, pickMin, pickMax
    }
    init() {}
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        bonusKind = try c.decode(BonusKind.self, forKey: .bonusKind)
        rewardEntries = try c.decode([WheelSegment].self, forKey: .rewardEntries)
        freeSpinCount = try c.decode(Int.self, forKey: .freeSpinCount)
        stickyWildEnabled = try c.decode(Bool.self, forKey: .stickyWildEnabled)
        multiplierProgression = try c.decode([Double].self, forKey: .multiplierProgression)
        pickCount = try c.decode(Int.self, forKey: .pickCount)
        let mn = try c.decode(Double.self, forKey: .pickMin)
        let mx = try c.decode(Double.self, forKey: .pickMax)
        pickRewardRange = mn...mx
    }
    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(bonusKind, forKey: .bonusKind)
        try c.encode(rewardEntries, forKey: .rewardEntries)
        try c.encode(freeSpinCount, forKey: .freeSpinCount)
        try c.encode(stickyWildEnabled, forKey: .stickyWildEnabled)
        try c.encode(multiplierProgression, forKey: .multiplierProgression)
        try c.encode(pickCount, forKey: .pickCount)
        try c.encode(pickRewardRange.lowerBound, forKey: .pickMin)
        try c.encode(pickRewardRange.upperBound, forKey: .pickMax)
    }
}

struct WheelSegment: Codable {
    var segmentLabel: String
    var rewardMultiplier: Double
    var probabilityWeight: Double
    var isJackpot: Bool
}
