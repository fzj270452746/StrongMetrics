// NexusRootVC.swift
// Main project workspace — hosts all mode panels in a unified layout.

import UIKit
import SpriteKit

class NexusRootVC: UIViewController {

    // MARK: - Properties
    var vaultProject: VaultProject!

    // Child VCs
    private var canvasVC:    FluxCanvasVC!
    private var lobeEditorVC: LobeEditorVC!
    private var bonusVC:     NexusBonusVC!
    private var simVC:       PulseSimVC!
    private var riftMapVC:   RiftMapVC!

    // UI
    private var tabBar:      ModeSwitchTabBar!
    private var contentContainer: UIView!
    private var currentMode: AppCoreMode = .build

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        precondition(vaultProject != nil, "VaultProject must be set")
        buildRootInterface()
        instantiateChildVCs()
        activateMode(.build)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        vaultProject.persistToDisk()
    }

    // MARK: - Build Root
    private func buildRootInterface() {
        view.backgroundColor = AuraPalette.voidBlack

        // Back button (top-left)
        let backBtn = NeonIconButton()
        backBtn.configure(sfName: "chevron.left", size: 16, tint: AuraPalette.cobaltFlare)
        backBtn.backgroundColor = AuraPalette.cosmicDeep
        backBtn.layer.cornerRadius = 18
        backBtn.layer.borderWidth = 1
        backBtn.layer.borderColor = AuraPalette.cobaltFlare.withAlphaComponent(0.35).cgColor
        backBtn.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(backBtn)
        backBtn.addTarget(self, action: #selector(handleBack), for: .touchUpInside)

        // Tab bar (top)
        tabBar = ModeSwitchTabBar()
        tabBar.tabDelegate = self
        tabBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tabBar)

        // Content container
        contentContainer = UIView()
        contentContainer.translatesAutoresizingMaskIntoConstraints = false
        contentContainer.backgroundColor = .clear
        view.addSubview(contentContainer)

        NSLayoutConstraint.activate([
            backBtn.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: ManifoldSpacing.standard),
            backBtn.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 6),
            backBtn.widthAnchor.constraint(equalToConstant: 36),
            backBtn.heightAnchor.constraint(equalToConstant: 36),

            tabBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tabBar.leadingAnchor.constraint(equalTo: backBtn.trailingAnchor, constant: ManifoldSpacing.minor),
            tabBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tabBar.heightAnchor.constraint(equalToConstant: 50),

            contentContainer.topAnchor.constraint(equalTo: tabBar.bottomAnchor),
            contentContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            contentContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            contentContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    @objc private func handleBack() {
        vaultProject.persistToDisk()
        dismiss(animated: true)
    }

    // MARK: - Instantiate child VCs
    private func instantiateChildVCs() {
        canvasVC = FluxCanvasVC()
        canvasVC.vaultProject = vaultProject

        lobeEditorVC = LobeEditorVC()
        lobeEditorVC.vaultProject = vaultProject

        bonusVC = NexusBonusVC()
        bonusVC.vaultProject = vaultProject

        simVC = PulseSimVC()
        simVC.vaultProject = vaultProject

        riftMapVC = RiftMapVC()
        riftMapVC.vaultProject = vaultProject

        [canvasVC, lobeEditorVC, bonusVC, simVC, riftMapVC].forEach { vc in
            addChild(vc!)
            contentContainer.addSubview(vc!.view)
            vc!.view.frame = contentContainer.bounds
            vc!.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            vc!.didMove(toParent: self)
            vc!.view.isHidden = true
        }
    }

    // MARK: - Mode Activation
    private func activateMode(_ mode: AppCoreMode) {
        let allVCs: [UIViewController] = [canvasVC, lobeEditorVC, bonusVC, simVC, riftMapVC]
        let targetVC = allVCs[mode.rawValue]

        // Animate transition
        let outgoing = allVCs.first(where: { !$0.view.isHidden && $0 !== targetVC })

        targetVC.view.alpha = 0
        targetVC.view.isHidden = false

        UIView.animate(withDuration: 0.25, animations: {
            outgoing?.view.alpha = 0
            targetVC.view.alpha = 1
        }) { _ in
            outgoing?.view.isHidden = true
            outgoing?.view.alpha = 1
        }

        tabBar.selectMode(mode, animated: true)
        currentMode = mode
    }
}

// MARK: - ModeSwitchTabBarDelegate
extension NexusRootVC: ModeSwitchTabBarDelegate {
    func tabBarDidSelectMode(_ mode: AppCoreMode) {
        guard mode != currentMode else { return }
        activateMode(mode)
    }
}

// MARK: - NexusRootVC Factory
extension NexusRootVC {
    static func instantiate(with project: VaultProject) -> NexusRootVC {
        let vc = NexusRootVC()
        vc.vaultProject = project
        return vc
    }
}
