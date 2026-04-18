// LatticeNodeModel.swift
// Data model for nodes on the visual canvas (node graph editor).

import UIKit

// MARK: - Lattice Node Type
enum LatticeNodeKind: String, Codable, CaseIterable {
    case glyphSource    = "Symbol"
    case reelGroup      = "Reel Group"
    case featureMech    = "Feature"
    case bonusTrigger   = "Bonus"
    case freeSpinRoute  = "Free Spin"
    case multiplierNode = "Multiplier"
    case paylineBlock   = "Payline"
    case conditionFork  = "Condition"
    case outputSink     = "Output"
    case commentNote    = "Note"

    var accentChroma: UIColor {
        switch self {
        case .glyphSource:    return AuraPalette.amethystBurst
        case .reelGroup:      return AuraPalette.cobaltFlare
        case .featureMech:    return AuraPalette.verdantPulse
        case .bonusTrigger:   return AuraPalette.emberCrimson
        case .freeSpinRoute:  return AuraPalette.prismaticGold
        case .multiplierNode: return AuraPalette.verdantPulse
        case .paylineBlock:   return AuraPalette.cobaltFlare
        case .conditionFork:  return AuraPalette.chartreuseGlow
        case .outputSink:     return AuraPalette.quartzTint
        case .commentNote:    return AuraPalette.quartzTint
        }
    }

    var iconSFName: String {
        switch self {
        case .glyphSource:    return "suit.diamond.fill"
        case .reelGroup:      return "square.grid.3x3.fill"
        case .featureMech:    return "gearshape.fill"
        case .bonusTrigger:   return "bolt.circle.fill"
        case .freeSpinRoute:  return "arrow.clockwise.circle.fill"
        case .multiplierNode: return "multiply.circle.fill"
        case .paylineBlock:   return "line.diagonal"
        case .conditionFork:  return "arrow.triangle.branch"
        case .outputSink:     return "flag.fill"
        case .commentNote:    return "note.text"
        }
    }
}

// MARK: - Port (Connection Point)
struct LatticePort: Codable {
    enum Flow: String, Codable { case inbound, outbound }
    var portId: UUID
    var flow: Flow
    var portLabel: String
    var connectedEdgeIds: [UUID]

    init(flow: Flow, label: String) {
        self.portId = UUID()
        self.flow = flow
        self.portLabel = label
        self.connectedEdgeIds = []
    }
}

// MARK: - Lattice Node
class LatticeNode: Codable, ObservableObject {
    var nodeId: UUID
    var nodeKind: LatticeNodeKind
    var inscriptionLabel: String       // Display name
    var canvasPosition: CGPoint        // Position on canvas
    var inboundPorts: [LatticePort]
    var outboundPorts: [LatticePort]
    var payloadData: [String: String]  // Arbitrary key-value configuration
    var isCollapsed: Bool
    var isSelected: Bool = false

    init(kind: LatticeNodeKind, label: String, at position: CGPoint = .zero) {
        self.nodeId = UUID()
        self.nodeKind = kind
        self.inscriptionLabel = label
        self.canvasPosition = position
        self.isCollapsed = false
        self.payloadData = [:]
        self.inboundPorts = []
        self.outboundPorts = []
        self.populatePorts()
    }

    private func populatePorts() {
        switch nodeKind {
        case .glyphSource:
            outboundPorts = [LatticePort(flow: .outbound, label: "Symbol Out")]
        case .reelGroup:
            inboundPorts = [LatticePort(flow: .inbound, label: "Symbols In")]
            outboundPorts = [LatticePort(flow: .outbound, label: "Reel Out")]
        case .featureMech:
            inboundPorts = [LatticePort(flow: .inbound, label: "Trigger")]
            outboundPorts = [LatticePort(flow: .outbound, label: "Effect")]
        case .bonusTrigger:
            inboundPorts = [LatticePort(flow: .inbound, label: "Trigger")]
            outboundPorts = [LatticePort(flow: .outbound, label: "Bonus Game")]
        case .freeSpinRoute:
            inboundPorts = [LatticePort(flow: .inbound, label: "Trigger")]
            outboundPorts = [LatticePort(flow: .outbound, label: "Spins"), LatticePort(flow: .outbound, label: "Retrigger")]
        case .multiplierNode:
            inboundPorts = [LatticePort(flow: .inbound, label: "Win In")]
            outboundPorts = [LatticePort(flow: .outbound, label: "Multiplied Out")]
        case .conditionFork:
            inboundPorts = [LatticePort(flow: .inbound, label: "Input")]
            outboundPorts = [LatticePort(flow: .outbound, label: "True"), LatticePort(flow: .outbound, label: "False")]
        case .paylineBlock:
            inboundPorts = [LatticePort(flow: .inbound, label: "Reels")]
            outboundPorts = [LatticePort(flow: .outbound, label: "Wins")]
        case .outputSink:
            inboundPorts = [LatticePort(flow: .inbound, label: "Result")]
        case .commentNote:
            break
        }
    }

    // MARK: Codable
    enum CodingKeys: String, CodingKey {
        case nodeId, nodeKind, inscriptionLabel, canvasPositionX, canvasPositionY
        case inboundPorts, outboundPorts, payloadData, isCollapsed
    }

    required init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        nodeId = try c.decode(UUID.self, forKey: .nodeId)
        nodeKind = try c.decode(LatticeNodeKind.self, forKey: .nodeKind)
        inscriptionLabel = try c.decode(String.self, forKey: .inscriptionLabel)
        let x = try c.decode(CGFloat.self, forKey: .canvasPositionX)
        let y = try c.decode(CGFloat.self, forKey: .canvasPositionY)
        canvasPosition = CGPoint(x: x, y: y)
        inboundPorts = try c.decode([LatticePort].self, forKey: .inboundPorts)
        outboundPorts = try c.decode([LatticePort].self, forKey: .outboundPorts)
        payloadData = try c.decode([String: String].self, forKey: .payloadData)
        isCollapsed = try c.decode(Bool.self, forKey: .isCollapsed)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(nodeId, forKey: .nodeId)
        try c.encode(nodeKind, forKey: .nodeKind)
        try c.encode(inscriptionLabel, forKey: .inscriptionLabel)
        try c.encode(canvasPosition.x, forKey: .canvasPositionX)
        try c.encode(canvasPosition.y, forKey: .canvasPositionY)
        try c.encode(inboundPorts, forKey: .inboundPorts)
        try c.encode(outboundPorts, forKey: .outboundPorts)
        try c.encode(payloadData, forKey: .payloadData)
        try c.encode(isCollapsed, forKey: .isCollapsed)
    }
}

// MARK: - Lattice Edge (Connection)
class LatticeEdge: Codable {
    var edgeId: UUID
    var originNodeId: UUID
    var originPortId: UUID
    var destinNodeId: UUID
    var destinPortId: UUID

    init(originNode: UUID, originPort: UUID, destinNode: UUID, destinPort: UUID) {
        self.edgeId = UUID()
        self.originNodeId = originNode
        self.originPortId = originPort
        self.destinNodeId = destinNode
        self.destinPortId = destinPort
    }
}

// MARK: - Lattice Graph (all nodes + edges)
class LatticeGraph: Codable, ObservableObject {
    var graphId: UUID
    var nodes: [LatticeNode]
    var edges: [LatticeEdge]
    var canvasViewportOffset: CGPoint
    var canvasZoomScale: CGFloat

    init() {
        self.graphId = UUID()
        self.nodes = []
        self.edges = []
        self.canvasViewportOffset = .zero
        self.canvasZoomScale = 1.0
    }

    func addNode(_ node: LatticeNode) { nodes.append(node) }

    func removeNode(id: UUID) {
        nodes.removeAll { $0.nodeId == id }
        edges.removeAll { $0.originNodeId == id || $0.destinNodeId == id }
    }

    func addEdge(_ edge: LatticeEdge) { edges.append(edge) }

    func removeEdge(id: UUID) { edges.removeAll { $0.edgeId == id } }

    func edgesFor(nodeId: UUID) -> [LatticeEdge] {
        edges.filter { $0.originNodeId == nodeId || $0.destinNodeId == nodeId }
    }

    static func makeInitialGraph() -> LatticeGraph {
        let g = LatticeGraph()
        let wild = LatticeNode(kind: .glyphSource, label: "Wild Symbol", at: CGPoint(x: 100, y: 150))
        let scatter = LatticeNode(kind: .glyphSource, label: "Scatter", at: CGPoint(x: 100, y: 300))
        let reel = LatticeNode(kind: .reelGroup, label: "Reel Grid 5×4", at: CGPoint(x: 340, y: 200))
        let freeSpin = LatticeNode(kind: .freeSpinRoute, label: "Free Spin ×10", at: CGPoint(x: 580, y: 300))
        let bonus = LatticeNode(kind: .bonusTrigger, label: "Bonus Game", at: CGPoint(x: 580, y: 150))
        let output = LatticeNode(kind: .outputSink, label: "Result Sink", at: CGPoint(x: 820, y: 225))
        [wild, scatter, reel, freeSpin, bonus, output].forEach { g.addNode($0) }

        // Wire scatter → freeSpin
        if let srcPort = scatter.outboundPorts.first, let dstPort = freeSpin.inboundPorts.first {
            g.addEdge(LatticeEdge(originNode: scatter.nodeId, originPort: srcPort.portId,
                                  destinNode: freeSpin.nodeId, destinPort: dstPort.portId))
        }
        // Wire freeSpin → output
        if let srcPort = freeSpin.outboundPorts.first, let dstPort = output.inboundPorts.first {
            g.addEdge(LatticeEdge(originNode: freeSpin.nodeId, originPort: srcPort.portId,
                                  destinNode: output.nodeId, destinPort: dstPort.portId))
        }
        return g
    }

    // MARK: Codable
    enum CodingKeys: String, CodingKey {
        case graphId, nodes, edges, vpOffsetX, vpOffsetY, canvasZoomScale
    }
    required init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        graphId = try c.decode(UUID.self, forKey: .graphId)
        nodes = try c.decode([LatticeNode].self, forKey: .nodes)
        edges = try c.decode([LatticeEdge].self, forKey: .edges)
        let ox = try c.decode(CGFloat.self, forKey: .vpOffsetX)
        let oy = try c.decode(CGFloat.self, forKey: .vpOffsetY)
        canvasViewportOffset = CGPoint(x: ox, y: oy)
        canvasZoomScale = try c.decode(CGFloat.self, forKey: .canvasZoomScale)
    }
    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(graphId, forKey: .graphId)
        try c.encode(nodes, forKey: .nodes)
        try c.encode(edges, forKey: .edges)
        try c.encode(canvasViewportOffset.x, forKey: .vpOffsetX)
        try c.encode(canvasViewportOffset.y, forKey: .vpOffsetY)
        try c.encode(canvasZoomScale, forKey: .canvasZoomScale)
    }
}
