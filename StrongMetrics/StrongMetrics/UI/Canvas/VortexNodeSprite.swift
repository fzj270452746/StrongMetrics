// VortexNodeSprite.swift
// SpriteKit node representing a single design element on the canvas.

import SpriteKit
import UIKit

// MARK: - Vortex Node Delegate
protocol VortexNodeDelegate: AnyObject {
    func vortexNodeDidSelect(_ node: VortexNodeSprite)
    func vortexNodeDidDrag(_ node: VortexNodeSprite, to position: CGPoint)
    func vortexNodeDidBeginConnection(_ node: VortexNodeSprite, fromPort: UUID)
    func vortexNodeConnectionMoved(_ node: VortexNodeSprite, to scenePoint: CGPoint)
    func vortexNodeConnectionEnded(_ node: VortexNodeSprite, at scenePoint: CGPoint)
    func vortexNodeConnectionCancelled(_ node: VortexNodeSprite)
    func vortexNodeDidRequestDelete(_ node: VortexNodeSprite)
}

// MARK: - Port Sprite
class PortSprite: SKShapeNode {
    var portId: UUID
    var isOutbound: Bool
    var portLabel: String

    init(port: LatticePort, radius: CGFloat = 7) {
        self.portId = port.portId
        self.isOutbound = port.flow == .outbound
        self.portLabel = port.portLabel
        super.init()
        let path = CGMutablePath()
        path.addEllipse(in: CGRect(x: -radius, y: -radius, width: radius*2, height: radius*2))
        self.path = path
        self.fillColor = isOutbound ? UIColor(r: 0, g: 230, b: 120) : UIColor(r: 64, g: 180, b: 255)
        self.strokeColor = SKColor.white.withAlphaComponent(0.8)
        self.lineWidth = 1.5
        self.zPosition = 10
        self.name = "port_\(portId.uuidString)"
    }
    required init?(coder aDecoder: NSCoder) { fatalError() }
}

// MARK: - Vortex Node Sprite (main canvas node)
class VortexNodeSprite: SKNode {

    // MARK: - Properties
    private(set) var latticeModel: LatticeNode
    weak var vortexDelegate: VortexNodeDelegate?

    // Visual components
    private let bodyNode      = SKShapeNode()
    private let headerStrip   = SKShapeNode()
    private let titleNode     = SKLabelNode()
    private let subtitleNode  = SKLabelNode()
    private let iconNode      = SKLabelNode()
    private let glowNode      = SKShapeNode()
    private var portSprites:  [PortSprite] = []
    private var dragStartPos: CGPoint = .zero

    // Sizing
    private let nodeWidth: CGFloat  = 180
    private let nodeHeight: CGFloat = 110
    private let headerH: CGFloat    = 36
    private let portRadius: CGFloat = 7

    // State
    var isVortexSelected: Bool = false {
        didSet { updateSelectionVisuals() }
    }
    private var isConnectionDragging = false

    // MARK: - Init
    init(model: LatticeNode) {
        self.latticeModel = model
        super.init()
        self.position = model.canvasPosition
        self.name = "node_\(model.nodeId.uuidString)"
        self.zPosition = 1
        self.isUserInteractionEnabled = true
        tessellateBody()
        tessellateHeader()
        tessellateText()
        tessellatePorts()
        radiateGlowEffect()
    }

    required init?(coder aDecoder: NSCoder) { fatalError() }

    // MARK: - Body construction
    private func tessellateBody() {
        let rect = CGRect(x: -nodeWidth/2, y: -nodeHeight/2, width: nodeWidth, height: nodeHeight)
        let path = UIBezierPath(roundedRect: rect, cornerRadius: 14).cgPath

        bodyNode.path = path
        bodyNode.fillColor = SKColor(UIColor(r: 20, g: 18, b: 55))
        bodyNode.strokeColor = SKColor(accentColor)
        bodyNode.lineWidth = 1.5
        bodyNode.zPosition = 1
        addChild(bodyNode)
    }

    private func tessellateHeader() {
        let rect = CGRect(x: -nodeWidth/2, y: nodeHeight/2 - headerH, width: nodeWidth, height: headerH)
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: [.topLeft, .topRight], cornerRadii: CGSize(width: 14, height: 14)).cgPath

        headerStrip.path = path
        headerStrip.fillColor = SKColor(accentColor.withAlphaComponent(0.8))
        headerStrip.strokeColor = .clear
        headerStrip.zPosition = 2
        addChild(headerStrip)
    }

    private func tessellateText() {
        // Icon
        iconNode.text = latticeModel.nodeKind.iconSFName.isEmpty ? "◆" : nodeKindIcon
        iconNode.fontSize = 13
        iconNode.fontName = "SF Pro Display"
        iconNode.fontColor = SKColor.white
        iconNode.horizontalAlignmentMode = .left
        iconNode.verticalAlignmentMode = .center
        iconNode.position = CGPoint(x: -nodeWidth/2 + 10, y: nodeHeight/2 - headerH/2)
        iconNode.zPosition = 3
        addChild(iconNode)

        // Title
        titleNode.text = latticeModel.inscriptionLabel
        titleNode.fontSize = 12
        titleNode.fontName = "SF Pro Display-Semibold"
        titleNode.fontColor = SKColor.white
        titleNode.horizontalAlignmentMode = .left
        titleNode.verticalAlignmentMode = .center
        titleNode.position = CGPoint(x: -nodeWidth/2 + 28, y: nodeHeight/2 - headerH/2)
        titleNode.zPosition = 3
        addChild(titleNode)

        // Subtitle (node kind label)
        subtitleNode.text = latticeModel.nodeKind.rawValue
        subtitleNode.fontSize = 10
        subtitleNode.fontName = "SF Pro"
        subtitleNode.fontColor = SKColor.white.withAlphaComponent(0.6)
        subtitleNode.horizontalAlignmentMode = .left
        subtitleNode.verticalAlignmentMode = .center
        subtitleNode.position = CGPoint(x: -nodeWidth/2 + 10, y: nodeHeight/2 - headerH - 18)
        subtitleNode.zPosition = 3
        addChild(subtitleNode)
    }

    private func tessellatePorts() {
        let totalIn = latticeModel.inboundPorts.count
        let totalOut = latticeModel.outboundPorts.count

        // Inbound ports (left side)
        for (i, port) in latticeModel.inboundPorts.enumerated() {
            let sprite = PortSprite(port: port)
            let spacing = nodeHeight / CGFloat(totalIn + 1)
            let yPos = nodeHeight/2 - headerH - spacing * CGFloat(i + 1)
            sprite.position = CGPoint(x: -nodeWidth/2, y: yPos)
            addChild(sprite)
            portSprites.append(sprite)

            let label = SKLabelNode(text: port.portLabel)
            label.fontSize = 8
            label.fontColor = SKColor.white.withAlphaComponent(0.5)
            label.horizontalAlignmentMode = .left
            label.verticalAlignmentMode = .center
            label.position = CGPoint(x: -nodeWidth/2 + 12, y: yPos)
            label.zPosition = 4
            addChild(label)
        }

        // Outbound ports (right side)
        for (i, port) in latticeModel.outboundPorts.enumerated() {
            let sprite = PortSprite(port: port)
            let spacing = nodeHeight / CGFloat(totalOut + 1)
            let yPos = nodeHeight/2 - headerH - spacing * CGFloat(i + 1)
            sprite.position = CGPoint(x: nodeWidth/2, y: yPos)
            addChild(sprite)
            portSprites.append(sprite)

            let label = SKLabelNode(text: port.portLabel)
            label.fontSize = 8
            label.fontColor = SKColor.white.withAlphaComponent(0.5)
            label.horizontalAlignmentMode = .right
            label.verticalAlignmentMode = .center
            label.position = CGPoint(x: nodeWidth/2 - 12, y: yPos)
            label.zPosition = 4
            addChild(label)
        }
    }

    private func radiateGlowEffect() {
        let rect = CGRect(x: -nodeWidth/2 - 4, y: -nodeHeight/2 - 4, width: nodeWidth + 8, height: nodeHeight + 8)
        let path = UIBezierPath(roundedRect: rect, cornerRadius: 17).cgPath
        glowNode.path = path
        glowNode.fillColor = .clear
        glowNode.strokeColor = SKColor(accentColor.withAlphaComponent(0.0))
        glowNode.lineWidth = 2
        glowNode.zPosition = 0
        addChild(glowNode)
    }

    // MARK: - Helpers
    private var accentColor: UIColor { AuraPalette.latticeNodeAccent(for: latticeModel.nodeKind) }

    private var nodeKindIcon: String {
        switch latticeModel.nodeKind {
        case .glyphSource:    return "◈"
        case .reelGroup:      return "▦"
        case .featureMech:    return "⚙"
        case .bonusTrigger:   return "⚡"
        case .freeSpinRoute:  return "↻"
        case .multiplierNode: return "✕"
        case .paylineBlock:   return "╌"
        case .conditionFork:  return "⑂"
        case .outputSink:     return "⚑"
        case .commentNote:    return "✎"
        }
    }

    func portSprite(for portId: UUID) -> PortSprite? {
        portSprites.first { $0.portId == portId }
    }

    func worldPositionFor(portId: UUID) -> CGPoint? {
        guard let ps = portSprite(for: portId) else { return nil }
        return scene?.convertPoint(toView: convert(ps.position, to: scene!)) ?? nil
    }

    // MARK: - Selection visuals
    private func updateSelectionVisuals() {
        if isVortexSelected {
            bodyNode.strokeColor = SKColor(AuraPalette.starWhite)
            bodyNode.lineWidth = 2.5
            glowNode.strokeColor = SKColor(accentColor.withAlphaComponent(0.6))
            let pulseOut = SKAction.sequence([
                SKAction.customAction(withDuration: 0) { node, _ in
                    (node as? SKShapeNode)?.lineWidth = 2
                },
                SKAction.wait(forDuration: 0.8),
                SKAction.customAction(withDuration: 0) { node, _ in
                    (node as? SKShapeNode)?.lineWidth = 4
                },
                SKAction.wait(forDuration: 0.8)
            ])
            glowNode.run(SKAction.repeatForever(pulseOut), withKey: "selectionPulse")
            run(SKAction.scale(to: 1.03, duration: 0.15))
        } else {
            bodyNode.strokeColor = SKColor(accentColor)
            bodyNode.lineWidth = 1.5
            glowNode.strokeColor = .clear
            glowNode.removeAction(forKey: "selectionPulse")
            run(SKAction.scale(to: 1.0, duration: 0.1))
        }
    }

    // MARK: - Model sync
    func synchronizePosition() {
        latticeModel.canvasPosition = position
    }

    // MARK: - Touch handling
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, let scene = scene else { return }
        let locInNode = touch.location(in: self)
        dragStartPos = touch.location(in: scene)

        // Check if tapping an outbound port
        if let hit = atPoint(locInNode) as? PortSprite, hit.isOutbound {
            isConnectionDragging = true
            vortexDelegate?.vortexNodeDidBeginConnection(self, fromPort: hit.portId)
            return
        }
        vortexDelegate?.vortexNodeDidSelect(self)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, let scene = scene else { return }
        let scenePoint = touch.location(in: scene)

        if isConnectionDragging {
            vortexDelegate?.vortexNodeConnectionMoved(self, to: scenePoint)
            return
        }

        let delta = CGPoint(x: scenePoint.x - dragStartPos.x, y: scenePoint.y - dragStartPos.y)
        position = CGPoint(x: position.x + delta.x, y: position.y + delta.y)
        dragStartPos = scenePoint
        synchronizePosition()
        vortexDelegate?.vortexNodeDidDrag(self, to: position)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, let scene = scene else { return }
        if isConnectionDragging {
            isConnectionDragging = false
            vortexDelegate?.vortexNodeConnectionEnded(self, at: touch.location(in: scene))
        }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        if isConnectionDragging {
            isConnectionDragging = false
            vortexDelegate?.vortexNodeConnectionCancelled(self)
        }
    }
}

// MARK: - SKColor from UIColor helper
extension SKColor {
    convenience init(_ uiColor: UIColor) {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        self.init(red: r, green: g, blue: b, alpha: a)
    }
}
