// TetherLineNode.swift
// SpriteKit shape node that draws bezier connection lines between Vortex nodes.

import SpriteKit
import UIKit

// MARK: - Tether Line (edge visualizer)
class TetherLineNode: SKShapeNode {

    var edgeModel: LatticeEdge
    private var particleTrail: SKEmitterNode?
    private var animPhase: CGFloat = 0

    init(edge: LatticeEdge, color: UIColor = AuraPalette.amethystBurst) {
        self.edgeModel = edge
        super.init()
        self.name = "edge_\(edge.edgeId.uuidString)"
        self.strokeColor = SKColor(color)
        self.lineWidth = 2.5
        self.fillColor = .clear
        self.zPosition = 0.5
        self.lineCap = .round
        self.alpha = 0.85

        // Animated glow
        let glow = SKShapeNode()
        glow.strokeColor = SKColor(color.withAlphaComponent(0.25))
        glow.lineWidth = 6
        glow.fillColor = .clear
        glow.zPosition = 0.4
        glow.name = "tether_glow"
        addChild(glow)
    }

    required init?(coder aDecoder: NSCoder) { fatalError() }

    // MARK: - Update path between two points
    func updateTrajectory(from start: CGPoint, to end: CGPoint) {
        let ctrl1 = CGPoint(x: start.x + (end.x - start.x) * 0.5, y: start.y)
        let ctrl2 = CGPoint(x: end.x - (end.x - start.x) * 0.5, y: end.y)

        let bez = UIBezierPath()
        bez.move(to: start)
        bez.addCurve(to: end, controlPoint1: ctrl1, controlPoint2: ctrl2)
        path = bez.cgPath

        // Update glow with same path
        if let glow = childNode(withName: "tether_glow") as? SKShapeNode {
            glow.path = bez.cgPath
        }
    }

    // MARK: - Animate "flowing" dashes
    func beginFlowAnimation(color: UIColor = AuraPalette.cobaltFlare) {
        let action = SKAction.repeatForever(
            SKAction.sequence([
                SKAction.customAction(withDuration: 0.05) { [weak self] _, _ in
                    self?.strokeColor = SKColor(color.withAlphaComponent(0.9))
                },
                SKAction.wait(forDuration: 0.05),
                SKAction.customAction(withDuration: 0.05) { [weak self] _, _ in
                    self?.strokeColor = SKColor(color.withAlphaComponent(0.6))
                },
                SKAction.wait(forDuration: 0.4)
            ])
        )
        run(action, withKey: "flowAnim")
    }

    func stopFlowAnimation() {
        removeAction(forKey: "flowAnim")
    }

    // MARK: - Highlight on hover/select
    func radiatePulse() {
        let scaleUp = SKAction.sequence([
            SKAction.run { [weak self] in self?.lineWidth = 4 },
            SKAction.wait(forDuration: 0.15),
            SKAction.run { [weak self] in self?.lineWidth = 2.5 }
        ])
        run(scaleUp)
    }
}

// MARK: - Draft tether (while dragging a new connection)
class DraftTetherNode: SKShapeNode {
    override init() {
        super.init()
        self.strokeColor = SKColor(AuraPalette.chartreuseGlow.withAlphaComponent(0.7))
        self.lineWidth = 2
        self.fillColor = .clear
        self.zPosition = 5
        self.lineCap = .round
        self.name = "draft_tether"

        // Pulse opacity animation to simulate "dashed" feel
        let pulse = SKAction.sequence([
            SKAction.fadeAlpha(to: 1.0, duration: 0.3),
            SKAction.fadeAlpha(to: 0.4, duration: 0.3)
        ])
        run(SKAction.repeatForever(pulse))
    }

    required init?(coder aDecoder: NSCoder) { fatalError() }

    func updateDraftPath(from start: CGPoint, to end: CGPoint) {
        let ctrl1 = CGPoint(x: start.x + (end.x - start.x) * 0.5, y: start.y)
        let ctrl2 = CGPoint(x: end.x - (end.x - start.x) * 0.5, y: end.y)
        let bez = UIBezierPath()
        bez.move(to: start)
        bez.addCurve(to: end, controlPoint1: ctrl1, controlPoint2: ctrl2)
        path = bez.cgPath
    }
}
