// FluxCanvasScene.swift
// Main SpriteKit scene for the node-based canvas editor.

import SpriteKit
import UIKit

// MARK: - Flux Canvas Delegate
protocol FluxCanvasSceneDelegate: AnyObject {
    func fluxSceneNodeSelected(_ node: LatticeNode?)
    func fluxSceneEdgeCreated(_ edge: LatticeEdge)
    func fluxSceneEdgeRemoved(_ edgeId: UUID)
    func fluxSceneRequestNodeMenu(for node: LatticeNode, at screenPoint: CGPoint)
}

// MARK: - Flux Canvas Scene
class FluxCanvasScene: SKScene {

    // MARK: - State
    weak var fluxDelegate: FluxCanvasSceneDelegate?
    private(set) var latticeGraph: LatticeGraph
    private var nodeSprites: [UUID: VortexNodeSprite] = [:]
    private var edgeSprites: [UUID: TetherLineNode] = [:]
    private var draftTether: DraftTetherNode?
    private var draftOriginPort: (nodeId: UUID, portId: UUID)?
    private var selectedNodeId: UUID?
    private var canvasCam: SKCameraNode!

    // Grid
    private var gridLayer: SKNode!

    // Canvas pan (single-finger on empty area)
    private var isPanningCanvas = false
    private var panStartTouchPos: CGPoint = .zero
    private var panStartCamPos: CGPoint = .zero

    // MARK: - Init
    init(size: CGSize, graph: LatticeGraph) {
        self.latticeGraph = graph
        super.init(size: size)
    }

    required init?(coder aDecoder: NSCoder) { fatalError() }

    // MARK: - Scene setup
    override func didMove(to view: SKView) {
        backgroundColor = SKColor(UIColor(r: 11, g: 11, b: 30))
        scaleMode = .resizeFill

        setupCamera()
        renderInfiniteGrid()
        renderAllNodes()
        renderAllEdges()
    }

    private func setupCamera() {
        canvasCam = SKCameraNode()
        canvasCam.position = CGPoint(x: frame.midX, y: frame.midY)
        addChild(canvasCam)
        camera = canvasCam

        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        view?.addGestureRecognizer(pinch)
    }

    @objc private func handlePinch(_ gr: UIPinchGestureRecognizer) {
        guard gr.state == .changed else { return }
        let newScale = max(0.3, min(3.0, canvasCam.xScale / gr.scale))
        canvasCam.setScale(newScale)
        gr.scale = 1.0
    }

    // MARK: - Infinite Grid
    private func renderInfiniteGrid() {
        gridLayer = SKNode()
        gridLayer.zPosition = -10
        addChild(gridLayer)

        let gridSize: CGFloat = 40
        let gridExtent: CGFloat = 4000
        let gridColor = SKColor(UIColor(r: 40, g: 40, b: 80, a: 0.5))

        var x = -gridExtent
        while x <= gridExtent {
            let line = SKShapeNode()
            let path = CGMutablePath()
            path.move(to: CGPoint(x: x, y: -gridExtent))
            path.addLine(to: CGPoint(x: x, y: gridExtent))
            line.path = path
            line.strokeColor = gridColor
            line.lineWidth = x.truncatingRemainder(dividingBy: 200) == 0 ? 1.0 : 0.5
            gridLayer.addChild(line)
            x += gridSize
        }

        var y = -gridExtent
        while y <= gridExtent {
            let line = SKShapeNode()
            let path = CGMutablePath()
            path.move(to: CGPoint(x: -gridExtent, y: y))
            path.addLine(to: CGPoint(x: gridExtent, y: y))
            line.path = path
            line.strokeColor = gridColor
            line.lineWidth = y.truncatingRemainder(dividingBy: 200) == 0 ? 1.0 : 0.5
            gridLayer.addChild(line)
            y += gridSize
        }
    }

    // MARK: - Render graph
    private func renderAllNodes() {
        for node in latticeGraph.nodes {
            spawnNodeSprite(for: node)
        }
    }

    private func renderAllEdges() {
        for edge in latticeGraph.edges {
            spawnEdgeSprite(for: edge)
        }
    }

    // MARK: - Node management
    func spawnNodeSprite(for model: LatticeNode) {
        let sprite = VortexNodeSprite(model: model)
        sprite.vortexDelegate = self
        nodeSprites[model.nodeId] = sprite
        addChild(sprite)

        // Entrance animation
        sprite.alpha = 0
        sprite.setScale(0.7)
        let appear = SKAction.group([
            SKAction.fadeIn(withDuration: 0.3),
            SKAction.scale(to: 1.0, duration: 0.3)
        ])
        sprite.run(appear)
    }

    func addLatticeNode(_ model: LatticeNode) {
        latticeGraph.addNode(model)
        spawnNodeSprite(for: model)
    }

    func removeLatticeNode(id: UUID) {
        // Collect edge IDs connected to this node BEFORE removing from graph
        let connectedEdgeIds = edgeSprites.keys.filter { edgeId in
            latticeGraph.edges.first { $0.edgeId == edgeId }.map {
                $0.originNodeId == id || $0.destinNodeId == id
            } ?? false
        }
        connectedEdgeIds.forEach { removeEdge(id: $0) }

        if let sprite = nodeSprites[id] {
            let dismiss = SKAction.sequence([
                SKAction.group([
                    SKAction.fadeOut(withDuration: 0.2),
                    SKAction.scale(to: 0.5, duration: 0.2)
                ]),
                SKAction.removeFromParent()
            ])
            sprite.run(dismiss)
            nodeSprites.removeValue(forKey: id)
        }
        latticeGraph.removeNode(id: id)
    }

    // MARK: - Edge management
    func spawnEdgeSprite(for edge: LatticeEdge) {
        guard let originNode = nodeSprites[edge.originNodeId],
              let destinNode = nodeSprites[edge.destinNodeId],
              let originPort = originNode.latticeModel.outboundPorts.first(where: { $0.portId == edge.originPortId }),
              let destinPort = destinNode.latticeModel.inboundPorts.first(where: { $0.portId == edge.destinPortId }) else { return }

        let accentColor = AuraPalette.latticeNodeAccent(for: originNode.latticeModel.nodeKind)
        let tether = TetherLineNode(edge: edge, color: accentColor)

        // Calculate positions
        let startPos = originNode.position + portOffset(originNode.latticeModel, port: originPort)
        let endPos   = destinNode.position + portOffset(destinNode.latticeModel, port: destinPort)
        tether.updateTrajectory(from: startPos, to: endPos)
        tether.beginFlowAnimation(color: accentColor)

        edgeSprites[edge.edgeId] = tether
        insertChild(tether, at: 0)
    }

    func removeEdge(id: UUID) {
        if let sprite = edgeSprites[id] {
            sprite.run(SKAction.sequence([SKAction.fadeOut(withDuration: 0.15), SKAction.removeFromParent()]))
            edgeSprites.removeValue(forKey: id)
        }
        latticeGraph.removeEdge(id: id)
    }

    private func portOffset(_ model: LatticeNode, port: LatticePort) -> CGPoint {
        let isOut = port.flow == .outbound
        let totalPorts = isOut ? model.outboundPorts.count : model.inboundPorts.count
        let idx = (isOut ? model.outboundPorts : model.inboundPorts).firstIndex(where: { $0.portId == port.portId }) ?? 0
        let spacing: CGFloat = 90.0 / CGFloat(totalPorts + 1)
        let yOff = CGFloat(22) - spacing * CGFloat(idx + 1)
        return CGPoint(x: isOut ? 90 : -90, y: yOff)
    }

    // MARK: - Update edges in real-time
    func refreshEdgePositions() {
        for (edgeId, tetherSprite) in edgeSprites {
            guard let edge = latticeGraph.edges.first(where: { $0.edgeId == edgeId }),
                  let originNode = nodeSprites[edge.originNodeId],
                  let destinNode = nodeSprites[edge.destinNodeId],
                  let originPort = originNode.latticeModel.outboundPorts.first(where: { $0.portId == edge.originPortId }),
                  let destinPort = destinNode.latticeModel.inboundPorts.first(where: { $0.portId == edge.destinPortId }) else { continue }

            let startPos = originNode.position + portOffset(originNode.latticeModel, port: originPort)
            let endPos   = destinNode.position + portOffset(destinNode.latticeModel, port: destinPort)
            tetherSprite.updateTrajectory(from: startPos, to: endPos)
        }
    }

    // MARK: - Touch handling (scene-level: handles canvas pan on empty area)
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let loc = touch.location(in: self)
        let hitNode = atPoint(loc)
        // Walk up tree to check if we hit a VortexNodeSprite
        var current: SKNode? = hitNode
        var hitVortex = false
        while let node = current {
            if node is VortexNodeSprite { hitVortex = true; break }
            current = node.parent
        }
        if hitVortex {
            // Let the node handle it — do nothing here
            isPanningCanvas = false
        } else {
            // Start canvas pan
            isPanningCanvas = true
            panStartTouchPos = loc
            panStartCamPos = canvasCam.position
            deselectAll()
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isPanningCanvas, let touch = touches.first else { return }
        let loc = touch.location(in: self)
        let delta = CGPoint(x: loc.x - panStartTouchPos.x, y: loc.y - panStartTouchPos.y)
        canvasCam.position = CGPoint(
            x: panStartCamPos.x - delta.x,
            y: panStartCamPos.y - delta.y
        )
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        isPanningCanvas = false
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        isPanningCanvas = false
        cancelDraftConnection()
    }

    // MARK: - Connection draft
    private var draftOriginPoint: CGPoint?

    private func beginDraftConnection(fromVortex: VortexNodeSprite, portId: UUID, at point: CGPoint) {
        draftOriginPort = (nodeId: fromVortex.latticeModel.nodeId, portId: portId)
        draftOriginPoint = point

        let draft = DraftTetherNode()
        draftTether = draft
        addChild(draft)
    }

    private func updateDraftConnection(to point: CGPoint) {
        draftTether?.updateDraftPath(from: draftOriginPoint ?? point, to: point)
    }

    private func tryFinalizeConnection(at scenePoint: CGPoint) {
        // Hit-test for an inbound PortSprite at the release point
        let hitNode = atPoint(scenePoint)
        var current: SKNode? = hitNode
        var foundPort: PortSprite?
        var foundVortex: VortexNodeSprite?
        while let node = current {
            if let ps = node as? PortSprite, !ps.isOutbound { foundPort = ps }
            if let v = node as? VortexNodeSprite { foundVortex = v }
            current = node.parent
        }
        if let port = foundPort, let vortex = foundVortex, let origin = draftOriginPort {
            finalizeConnection(toVortex: vortex, destinPortId: port.portId, origin: origin)
        }
        cancelDraftConnection()
    }

    private func finalizeConnection(toVortex: VortexNodeSprite, destinPortId: UUID, origin: (nodeId: UUID, portId: UUID)) {
        guard origin.nodeId != toVortex.latticeModel.nodeId else { return }
        let edge = LatticeEdge(originNode: origin.nodeId, originPort: origin.portId,
                               destinNode: toVortex.latticeModel.nodeId, destinPort: destinPortId)
        latticeGraph.addEdge(edge)
        spawnEdgeSprite(for: edge)
        fluxDelegate?.fluxSceneEdgeCreated(edge)
    }

    private func cancelDraftConnection() {
        draftTether?.removeFromParent()
        draftTether = nil
        draftOriginPort = nil
        draftOriginPoint = nil
    }

    // MARK: - Selection
    private func deselectAll() {
        selectedNodeId = nil
        nodeSprites.values.forEach { $0.isVortexSelected = false }
        fluxDelegate?.fluxSceneNodeSelected(nil)
    }

    // MARK: - Update loop
    override func update(_ currentTime: TimeInterval) {
        refreshEdgePositions()
    }

    // MARK: - Camera reset
    func resetCameraToFitAll() {
        guard !nodeSprites.isEmpty else { return }
        let positions = nodeSprites.values.map { $0.position }
        let minX = positions.map { $0.x }.min()! - 150
        let maxX = positions.map { $0.x }.max()! + 150
        let minY = positions.map { $0.y }.min()! - 100
        let maxY = positions.map { $0.y }.max()! + 100

        let cx = (minX + maxX) / 2
        let cy = (minY + maxY) / 2
        let sceneW = frame.width
        let sceneH = frame.height
        let scaleX = (maxX - minX) / sceneW
        let scaleY = (maxY - minY) / sceneH
        let newScale = max(0.4, min(2.0, max(scaleX, scaleY) * 1.1))

        let move = SKAction.move(to: CGPoint(x: cx, y: cy), duration: 0.4)
        let scale = SKAction.scale(to: newScale, duration: 0.4)
        canvasCam.run(SKAction.group([move, scale]))
    }
}

// MARK: - VortexNodeDelegate
extension FluxCanvasScene: VortexNodeDelegate {
    func vortexNodeDidSelect(_ node: VortexNodeSprite) {
        deselectAll()
        selectedNodeId = node.latticeModel.nodeId
        node.isVortexSelected = true
        fluxDelegate?.fluxSceneNodeSelected(node.latticeModel)
    }

    func vortexNodeDidDrag(_ node: VortexNodeSprite, to position: CGPoint) {
        refreshEdgePositions()
    }

    func vortexNodeDidBeginConnection(_ node: VortexNodeSprite, fromPort: UUID) {
        guard let portSp = node.portSprite(for: fromPort) else { return }
        let worldPos = node.convert(portSp.position, to: self)
        draftOriginPort = (nodeId: node.latticeModel.nodeId, portId: fromPort)
        draftOriginPoint = worldPos
        let draft = DraftTetherNode()
        draftTether = draft
        addChild(draft)
        draft.updateDraftPath(from: worldPos, to: worldPos)
    }

    func vortexNodeConnectionMoved(_ node: VortexNodeSprite, to scenePoint: CGPoint) {
        draftTether?.updateDraftPath(from: draftOriginPoint ?? scenePoint, to: scenePoint)
    }

    func vortexNodeConnectionEnded(_ node: VortexNodeSprite, at scenePoint: CGPoint) {
        tryFinalizeConnection(at: scenePoint)
    }

    func vortexNodeConnectionCancelled(_ node: VortexNodeSprite) {
        cancelDraftConnection()
    }

    func vortexNodeDidRequestDelete(_ node: VortexNodeSprite) {
        removeLatticeNode(id: node.latticeModel.nodeId)
    }
}

// MARK: - CGPoint arithmetic
extension CGPoint {
    static func + (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        CGPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
    }
}
