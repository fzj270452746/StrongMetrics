// FluxCanvasVC.swift
// Main canvas view controller hosting the SpriteKit node editor.

import UIKit
import SpriteKit

// MARK: - Flux Canvas View Controller
class FluxCanvasVC: UIViewController {

    // MARK: - Properties
    var vaultProject: VaultProject!
    private var canvasView: SKView!
    private var fluxScene: FluxCanvasScene!

    // Side panel
    private var palettePanel: NodePalettePanel!
    private var inspectorPanel: NodeInspectorPanel!
    private var paletteVisible = true

    private var modeTabBar: ModeSwitchTabBar!

    // Fab
    private var fitButton: NeonIconButton!
    private var addNodeButton: NeonButton!
    private var clearAllButton: NeonIconButton!

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        precondition(vaultProject != nil, "VaultProject must be set before loading FluxCanvasVC")
        buildCanvasInterface()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        showConnectionHint()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        canvasView.frame = view.bounds
        fluxScene.size = view.bounds.size
    }

    // MARK: - Build Interface
    private func buildCanvasInterface() {
        view.backgroundColor = AuraPalette.voidBlack

        // SpriteKit canvas (full screen)
        canvasView = SKView(frame: view.bounds)
        canvasView.backgroundColor = .clear
        canvasView.ignoresSiblingOrder = true
        canvasView.allowsTransparency = true
        canvasView.showsFPS = false
        canvasView.showsNodeCount = false
        view.addSubview(canvasView)

        fluxScene = FluxCanvasScene(size: view.bounds.size, graph: vaultProject.latticeGraph)
        fluxScene.fluxDelegate = self
        canvasView.presentScene(fluxScene)

        buildPalettePanel()
        buildInspectorPanel()
        buildFloatingButtons()
    }

    // MARK: - Palette Panel (left side)
    private func buildPalettePanel() {
        palettePanel = NodePalettePanel()
        palettePanel.translatesAutoresizingMaskIntoConstraints = false
        palettePanel.paletteDelegate = self
        view.addSubview(palettePanel)

        NSLayoutConstraint.activate([
            palettePanel.topAnchor.constraint(equalTo: view.topAnchor, constant: ManifoldSpacing.minor),
            palettePanel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: ManifoldSpacing.minor),
            palettePanel.widthAnchor.constraint(equalToConstant: 80),
            palettePanel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -80)
        ])
    }

    // MARK: - Inspector Panel (right bottom)
    private func buildInspectorPanel() {
        inspectorPanel = NodeInspectorPanel()
        inspectorPanel.translatesAutoresizingMaskIntoConstraints = false
        inspectorPanel.isHidden = true
        view.addSubview(inspectorPanel)

        NSLayoutConstraint.activate([
            inspectorPanel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -ManifoldSpacing.minor),
            inspectorPanel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -ManifoldSpacing.standard),
            inspectorPanel.widthAnchor.constraint(equalToConstant: 200),
            inspectorPanel.heightAnchor.constraint(equalToConstant: 240)
        ])
    }

    // MARK: - Floating Buttons
    private func buildFloatingButtons() {
        // Fit-to-screen button
        fitButton = NeonIconButton()
        fitButton.configure(sfName: "arrow.up.left.and.arrow.down.right", tint: AuraPalette.cobaltFlare)
        fitButton.backgroundColor = AuraPalette.cosmicDeep
        fitButton.layer.cornerRadius = 22
        fitButton.layer.borderWidth = 1
        fitButton.layer.borderColor = AuraPalette.cobaltFlare.withAlphaComponent(0.4).cgColor
        fitButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(fitButton)

        fitButton.addTarget(self, action: #selector(fitToScreen), for: .touchUpInside)

        // Add node button
        addNodeButton = NeonButton()
        addNodeButton.buttonTitle = "+ Add Node"
        addNodeButton.iconSFName = "plus.circle.fill"
        addNodeButton.variant = .primaryPurple
        addNodeButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(addNodeButton)
        addNodeButton.addTarget(self, action: #selector(presentNodePicker), for: .touchUpInside)

        // Clear button
        clearAllButton = NeonIconButton()
        clearAllButton.configure(sfName: "trash.fill", tint: AuraPalette.emberCrimson)
        clearAllButton.backgroundColor = AuraPalette.cosmicDeep
        clearAllButton.layer.cornerRadius = 22
        clearAllButton.layer.borderWidth = 1
        clearAllButton.layer.borderColor = AuraPalette.emberCrimson.withAlphaComponent(0.4).cgColor
        clearAllButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(clearAllButton)
        clearAllButton.addTarget(self, action: #selector(confirmClearAll), for: .touchUpInside)

        NSLayoutConstraint.activate([
            fitButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -ManifoldSpacing.standard),
            fitButton.topAnchor.constraint(equalTo: view.topAnchor, constant: ManifoldSpacing.standard),
            fitButton.widthAnchor.constraint(equalToConstant: 44),
            fitButton.heightAnchor.constraint(equalToConstant: 44),

            clearAllButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -ManifoldSpacing.standard),
            clearAllButton.topAnchor.constraint(equalTo: fitButton.bottomAnchor, constant: ManifoldSpacing.minor),
            clearAllButton.widthAnchor.constraint(equalToConstant: 44),
            clearAllButton.heightAnchor.constraint(equalToConstant: 44),

            addNodeButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            addNodeButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -ManifoldSpacing.minor),
            addNodeButton.widthAnchor.constraint(equalToConstant: 160),
            addNodeButton.heightAnchor.constraint(equalToConstant: 46)
        ])
    }

    // MARK: - Actions
    @objc private func fitToScreen() {
        fluxScene.resetCameraToFitAll()
    }

    // MARK: - Connection hint
    private var hintDismissed = false
    private func showConnectionHint() {
        guard !hintDismissed, vaultProject.latticeGraph.nodes.count >= 2 else { return }
        hintDismissed = true

        let toast = UIView()
        toast.backgroundColor = AuraPalette.cosmicDeep.withAlphaComponent(0.95)
        toast.layer.cornerRadius = 12
        toast.layer.borderWidth = 1
        toast.layer.borderColor = AuraPalette.amethystBurst.withAlphaComponent(0.6).cgColor
        toast.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(toast)

        let icon = UIImageView(image: UIImage(systemName: "arrow.triangle.branch",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 14, weight: .semibold)))
        icon.tintColor = AuraPalette.amethystBurst
        icon.translatesAutoresizingMaskIntoConstraints = false

        let lbl = UILabel()
        lbl.text = "Drag from a green port → blue port to connect nodes"
        lbl.font = AuraTypeface.caption(12)
        lbl.textColor = AuraPalette.starWhite
        lbl.numberOfLines = 2
        lbl.translatesAutoresizingMaskIntoConstraints = false

        toast.addSubview(icon)
        toast.addSubview(lbl)
        NSLayoutConstraint.activate([
            toast.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            toast.bottomAnchor.constraint(equalTo: addNodeButton.topAnchor, constant: -12),
            toast.widthAnchor.constraint(lessThanOrEqualTo: view.widthAnchor, multiplier: 0.85),

            icon.leadingAnchor.constraint(equalTo: toast.leadingAnchor, constant: 12),
            icon.centerYAnchor.constraint(equalTo: toast.centerYAnchor),
            icon.widthAnchor.constraint(equalToConstant: 20),

            lbl.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: 8),
            lbl.trailingAnchor.constraint(equalTo: toast.trailingAnchor, constant: -12),
            lbl.topAnchor.constraint(equalTo: toast.topAnchor, constant: 10),
            lbl.bottomAnchor.constraint(equalTo: toast.bottomAnchor, constant: -10)
        ])

        toast.alpha = 0
        toast.transform = CGAffineTransform(translationX: 0, y: 20)
        UIView.animate(withDuration: 0.4, delay: 0.3, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5, options: []) {
            toast.alpha = 1
            toast.transform = .identity
        }
        UIView.animate(withDuration: 0.4, delay: 4.5, options: []) {
            toast.alpha = 0
        } completion: { _ in toast.removeFromSuperview() }
    }

    @objc private func presentNodePicker() {
        let picker = NodeKindPickerVC()
        picker.onNodeKindSelected = { [weak self] kind in
            guard let self = self else { return }
            let centerPos = CGPoint(x: self.fluxScene.size.width / 2, y: self.fluxScene.size.height / 2)
            let node = LatticeNode(kind: kind, label: kind.rawValue, at: centerPos)
            self.vaultProject.latticeGraph.addNode(node)
            self.fluxScene.addLatticeNode(node)
        }
        picker.modalPresentationStyle = .overFullScreen
        picker.modalTransitionStyle = .crossDissolve
        present(picker, animated: true)
    }

    @objc private func confirmClearAll() {
        PrismAlertView.showConfirm(in: view, title: "Clear Canvas?",
                                   body: "All nodes and connections will be removed.") { [weak self] in
            guard let self = self else { return }
            let ids = self.vaultProject.latticeGraph.nodes.map { $0.nodeId }
            ids.forEach { self.fluxScene.removeLatticeNode(id: $0) }
        }
    }
}

// MARK: - FluxCanvasSceneDelegate
extension FluxCanvasVC: FluxCanvasSceneDelegate {
    func fluxSceneNodeSelected(_ node: LatticeNode?) {
        if let node = node {
            inspectorPanel.configure(with: node)
            showInspector(true)
        } else {
            showInspector(false)
        }
    }

    func fluxSceneEdgeCreated(_ edge: LatticeEdge) {
        vaultProject.latticeGraph.addEdge(edge)
    }

    func fluxSceneEdgeRemoved(_ edgeId: UUID) {
        vaultProject.latticeGraph.removeEdge(id: edgeId)
    }

    func fluxSceneRequestNodeMenu(for node: LatticeNode, at screenPoint: CGPoint) {}

    private func showInspector(_ show: Bool) {
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5) {
            self.inspectorPanel.isHidden = !show
            self.inspectorPanel.alpha = show ? 1 : 0
            self.inspectorPanel.transform = show ? .identity : CGAffineTransform(translationX: 30, y: 0)
        }
    }
}

// MARK: - NodePalettePanelDelegate
extension FluxCanvasVC: NodePalettePanelDelegate {
    func palettePanelDidSelectKind(_ kind: LatticeNodeKind) {
        let sceneCenter = CGPoint(x: fluxScene.size.width / 2 + CGFloat.random(in: -80...80),
                                  y: fluxScene.size.height / 2 + CGFloat.random(in: -60...60))
        let node = LatticeNode(kind: kind, label: kind.rawValue, at: sceneCenter)
        vaultProject.latticeGraph.addNode(node)
        fluxScene.addLatticeNode(node)
    }
}

// MARK: - Node Palette Panel
protocol NodePalettePanelDelegate: AnyObject {
    func palettePanelDidSelectKind(_ kind: LatticeNodeKind)
}

class NodePalettePanel: UIView {
    weak var paletteDelegate: NodePalettePanelDelegate?
    private var scrollView = UIScrollView()
    private var stackView  = UIStackView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        buildPalette()
    }
    required init?(coder: NSCoder) { fatalError() }

    private func buildPalette() {
        backgroundColor = AuraPalette.cosmicDeep.withAlphaComponent(0.92)
        layer.cornerRadius = ManifoldSpacing.cornerM
        layer.borderWidth = ManifoldSpacing.borderW
        layer.borderColor = AuraPalette.subtleBorder.cgColor
        clipsToBounds = true

        let header = UILabel()
        header.text = "Nodes"
        header.font = AuraTypeface.caption(11)
        header.textColor = AuraPalette.dimStar
        header.textAlignment = .center
        header.translatesAutoresizingMaskIntoConstraints = false
        addSubview(header)

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = false
        addSubview(scrollView)

        stackView.axis = .vertical
        stackView.spacing = ManifoldSpacing.minor
        stackView.alignment = .center
        stackView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(stackView)

        NSLayoutConstraint.activate([
            header.topAnchor.constraint(equalTo: topAnchor, constant: ManifoldSpacing.minor),
            header.leadingAnchor.constraint(equalTo: leadingAnchor),
            header.trailingAnchor.constraint(equalTo: trailingAnchor),
            header.heightAnchor.constraint(equalToConstant: 20),

            scrollView.topAnchor.constraint(equalTo: header.bottomAnchor, constant: ManifoldSpacing.minor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: ManifoldSpacing.micro),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -ManifoldSpacing.micro),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -ManifoldSpacing.minor),

            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])

        for kind in LatticeNodeKind.allCases {
            let btn = buildPaletteButton(kind: kind)
            stackView.addArrangedSubview(btn)
            btn.widthAnchor.constraint(equalToConstant: 60).isActive = true
            btn.heightAnchor.constraint(equalToConstant: 60).isActive = true
        }
    }

    private func buildPaletteButton(kind: LatticeNodeKind) -> UIView {
        let container = UIControl()
        container.backgroundColor = AuraPalette.latticeNodeAccent(for: kind).withAlphaComponent(0.15)
        container.layer.cornerRadius = 12
        container.layer.borderWidth = 1
        container.layer.borderColor = AuraPalette.latticeNodeAccent(for: kind).withAlphaComponent(0.4).cgColor
        container.translatesAutoresizingMaskIntoConstraints = false

        let imgConf = UIImage.SymbolConfiguration(pointSize: 18, weight: .semibold)
        let iconImg = UIImageView(image: UIImage(systemName: kind.iconSFName, withConfiguration: imgConf))
        iconImg.tintColor = AuraPalette.latticeNodeAccent(for: kind)
        iconImg.contentMode = .scaleAspectFit
        iconImg.translatesAutoresizingMaskIntoConstraints = false

        let label = UILabel()
        label.text = String(kind.rawValue.prefix(5))
        label.font = AuraTypeface.caption(8)
        label.textColor = AuraPalette.dimStar
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(iconImg)
        container.addSubview(label)
        NSLayoutConstraint.activate([
            iconImg.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            iconImg.topAnchor.constraint(equalTo: container.topAnchor, constant: 8),
            iconImg.widthAnchor.constraint(equalToConstant: 22),
            iconImg.heightAnchor.constraint(equalToConstant: 22),

            label.topAnchor.constraint(equalTo: iconImg.bottomAnchor, constant: 4),
            label.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 2),
            label.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -2)
        ])

        container.addTarget(self, action: #selector(paletteButtonTapped(_:)), for: .touchUpInside)
        container.accessibilityLabel = kind.rawValue
        return container
    }

    @objc private func paletteButtonTapped(_ sender: UIControl) {
        guard let label = sender.accessibilityLabel,
              let kind = LatticeNodeKind(rawValue: label) else { return }
        // Pulse animation
        UIView.animate(withDuration: 0.1, animations: { sender.transform = CGAffineTransform(scaleX: 0.9, y: 0.9) }) { _ in
            UIView.animate(withDuration: 0.2, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.5, options: []) {
                sender.transform = .identity
            }
        }
        paletteDelegate?.palettePanelDidSelectKind(kind)
    }
}

// MARK: - Node Inspector Panel
class NodeInspectorPanel: UIView {
    private let titleLabel    = UILabel()
    private let kindLabel     = UILabel()
    private let idLabel       = UILabel()
    private let portCountLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        buildInspector()
    }
    required init?(coder: NSCoder) { fatalError() }

    private func buildInspector() {
        backgroundColor = AuraPalette.nebulaCard.withAlphaComponent(0.96)
        layer.cornerRadius = ManifoldSpacing.cornerM
        layer.borderWidth = ManifoldSpacing.borderW
        layer.borderColor = AuraPalette.amethystBurst.withAlphaComponent(0.5).cgColor

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = ManifoldSpacing.minor
        stack.alignment = .leading
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        let header = UILabel()
        header.text = "INSPECTOR"
        header.font = AuraTypeface.caption(10)
        header.textColor = AuraPalette.amethystBurst
        header.letterSpacing(1.5)

        for (label, color) in [(titleLabel, AuraPalette.starWhite),
                               (kindLabel, AuraPalette.dimStar),
                               (idLabel, AuraPalette.ghostText),
                               (portCountLabel, AuraPalette.dimStar)] {
            label.font = AuraTypeface.body(12)
            label.textColor = color
            label.numberOfLines = 2
        }
        titleLabel.font = AuraTypeface.headline(14)

        [header, titleLabel, kindLabel, portCountLabel, idLabel].forEach { stack.addArrangedSubview($0) }

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor, constant: ManifoldSpacing.standard),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: ManifoldSpacing.standard),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -ManifoldSpacing.standard),
            stack.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -ManifoldSpacing.standard)
        ])
    }

    func configure(with node: LatticeNode) {
        titleLabel.text = node.inscriptionLabel
        kindLabel.text = "Type: \(node.nodeKind.rawValue)"
        portCountLabel.text = "Ports: \(node.inboundPorts.count) in · \(node.outboundPorts.count) out"
        idLabel.text = "ID: \(node.nodeId.uuidString.prefix(8))..."
    }
}

// MARK: - UILabel letter spacing helper
extension UILabel {
    @discardableResult
    func letterSpacing(_ spacing: CGFloat) -> UILabel {
        guard let text = self.text else { return self }
        let attr = NSMutableAttributedString(string: text)
        attr.addAttribute(.kern, value: spacing, range: NSRange(location: 0, length: text.count))
        self.attributedText = attr
        return self
    }
}

// MARK: - Node Kind Picker VC (overlay)
class NodeKindPickerVC: UIViewController {
    var onNodeKindSelected: ((LatticeNodeKind) -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        buildPicker()
    }

    private func buildPicker() {
        view.backgroundColor = UIColor.black.withAlphaComponent(0.7)

        let card = UIView()
        card.backgroundColor = AuraPalette.cosmicDeep
        card.layer.cornerRadius = ManifoldSpacing.cornerL
        card.layer.borderWidth = ManifoldSpacing.borderW
        card.layer.borderColor = AuraPalette.amethystBurst.withAlphaComponent(0.5).cgColor
        card.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(card)

        let titleLbl = UILabel()
        titleLbl.text = "Add Node"
        titleLbl.font = AuraTypeface.display(20)
        titleLbl.textColor = AuraPalette.starWhite
        titleLbl.textAlignment = .center
        titleLbl.translatesAutoresizingMaskIntoConstraints = false

        let grid = UICollectionView(frame: .zero, collectionViewLayout: makeGridLayout())
        grid.backgroundColor = .clear
        grid.register(NodeKindCell.self, forCellWithReuseIdentifier: "NodeKindCell")
        grid.dataSource = self
        grid.delegate   = self
        grid.translatesAutoresizingMaskIntoConstraints = false

        card.addSubview(titleLbl)
        card.addSubview(grid)

        NSLayoutConstraint.activate([
            card.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            card.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            card.widthAnchor.constraint(lessThanOrEqualTo: view.widthAnchor, multiplier: 0.9),
            card.widthAnchor.constraint(greaterThanOrEqualToConstant: 300),

            titleLbl.topAnchor.constraint(equalTo: card.topAnchor, constant: ManifoldSpacing.major),
            titleLbl.centerXAnchor.constraint(equalTo: card.centerXAnchor),

            grid.topAnchor.constraint(equalTo: titleLbl.bottomAnchor, constant: ManifoldSpacing.standard),
            grid.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: ManifoldSpacing.standard),
            grid.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -ManifoldSpacing.standard),
            grid.heightAnchor.constraint(equalToConstant: 320),
            grid.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -ManifoldSpacing.major)
        ])

        let tapDismiss = UITapGestureRecognizer(target: self, action: #selector(dismissSelf))
        view.addGestureRecognizer(tapDismiss)
    }

    private func makeGridLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: 80, height: 80)
        layout.minimumInteritemSpacing = ManifoldSpacing.minor
        layout.minimumLineSpacing = ManifoldSpacing.minor
        return layout
    }

    @objc private func dismissSelf() { dismiss(animated: true) }
}

extension NodeKindPickerVC: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ cv: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        LatticeNodeKind.allCases.count
    }
    func collectionView(_ cv: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = cv.dequeueReusableCell(withReuseIdentifier: "NodeKindCell", for: indexPath) as! NodeKindCell
        cell.configure(kind: LatticeNodeKind.allCases[indexPath.item])
        return cell
    }
    func collectionView(_ cv: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let kind = LatticeNodeKind.allCases[indexPath.item]
        dismiss(animated: true) { [weak self] in self?.onNodeKindSelected?(kind) }
    }
}

class NodeKindCell: UICollectionViewCell {
    private let iconView  = UIImageView()
    private let label     = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.layer.cornerRadius = 12
        contentView.layer.borderWidth = 1
        contentView.clipsToBounds = true

        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false
        label.font = AuraTypeface.caption(10)
        label.textColor = AuraPalette.dimStar
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(iconView)
        contentView.addSubview(label)
        NSLayoutConstraint.activate([
            iconView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            iconView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            iconView.widthAnchor.constraint(equalToConstant: 28),
            iconView.heightAnchor.constraint(equalToConstant: 28),
            label.topAnchor.constraint(equalTo: iconView.bottomAnchor, constant: 6),
            label.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 4),
            label.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -4)
        ])
    }
    required init?(coder: NSCoder) { fatalError() }

    func configure(kind: LatticeNodeKind) {
        let accent = AuraPalette.latticeNodeAccent(for: kind)
        contentView.backgroundColor = accent.withAlphaComponent(0.12)
        contentView.layer.borderColor = accent.withAlphaComponent(0.4).cgColor
        let conf = UIImage.SymbolConfiguration(pointSize: 22, weight: .semibold)
        iconView.image = UIImage(systemName: kind.iconSFName, withConfiguration: conf)
        iconView.tintColor = accent
        label.text = kind.rawValue
    }
}
