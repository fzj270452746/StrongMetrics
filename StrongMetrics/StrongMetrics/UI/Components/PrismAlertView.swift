// PrismAlertView.swift
// Custom, design-forward alert overlay replacing system UIAlertController.

import UIKit

// MARK: - Alert Action
struct PrismAction {
    enum PrismStyle { case primary, secondary, destructive, ghost }
    var title: String
    var style: PrismStyle
    var handler: (() -> Void)?
}

// MARK: - Prism Alert View
class PrismAlertView: UIView {

    // MARK: - Subviews
    private let backdropBlur   = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialDark))
    private let cardView       = UIView()
    private let iconContainer  = UIView()
    private let iconLabel      = UILabel()
    private let titleLabel     = UILabel()
    private let bodyLabel      = UILabel()
    private let buttonStack    = UIStackView()
    private let glowRing       = UIView()

    private var dismissOnTap   = true
    private var actions: [PrismAction] = []

    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        crystallizeLayout()
    }
    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Layout
    private func crystallizeLayout() {
        backgroundColor = UIColor.black.withAlphaComponent(0.7)
        isUserInteractionEnabled = true

        // Backdrop
        addSubview(backdropBlur)
        backdropBlur.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            backdropBlur.topAnchor.constraint(equalTo: topAnchor),
            backdropBlur.leadingAnchor.constraint(equalTo: leadingAnchor),
            backdropBlur.trailingAnchor.constraint(equalTo: trailingAnchor),
            backdropBlur.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        // Card
        cardView.translatesAutoresizingMaskIntoConstraints = false
        cardView.backgroundColor = AuraPalette.cosmicDeep
        cardView.layer.cornerRadius = ManifoldSpacing.cornerL
        cardView.layer.borderWidth = ManifoldSpacing.borderW
        cardView.layer.borderColor = AuraPalette.amethystBurst.withAlphaComponent(0.6).cgColor
        cardView.clipsToBounds = true
        addSubview(cardView)

        NSLayoutConstraint.activate([
            cardView.centerXAnchor.constraint(equalTo: centerXAnchor),
            cardView.centerYAnchor.constraint(equalTo: centerYAnchor),
            cardView.widthAnchor.constraint(lessThanOrEqualTo: widthAnchor, multiplier: 0.88),
            cardView.widthAnchor.constraint(greaterThanOrEqualToConstant: 280)
        ])

        // Inner gradient overlay
        let gradLayer = CAGradientLayer()
        gradLayer.colors = [
            UIColor(r: 60, g: 30, b: 120, a: 0.6).cgColor,
            UIColor(r: 10, g: 10, b: 40, a: 0.3).cgColor
        ]
        gradLayer.frame = CGRect(x: 0, y: 0, width: 300, height: 300)
        gradLayer.cornerRadius = ManifoldSpacing.cornerL
        cardView.layer.insertSublayer(gradLayer, at: 0)

        // Icon
        iconContainer.translatesAutoresizingMaskIntoConstraints = false
        iconContainer.backgroundColor = AuraPalette.amethystBurst.withAlphaComponent(0.2)
        iconContainer.layer.cornerRadius = 30
        iconContainer.layer.borderWidth = 1.5
        iconContainer.layer.borderColor = AuraPalette.amethystBurst.cgColor
        cardView.addSubview(iconContainer)

        iconLabel.translatesAutoresizingMaskIntoConstraints = false
        iconLabel.font = AuraTypeface.display(28)
        iconLabel.textAlignment = .center
        iconLabel.text = "⚡"
        iconContainer.addSubview(iconLabel)

        // Title
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = AuraTypeface.display(20)
        titleLabel.textColor = AuraPalette.starWhite
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0
        cardView.addSubview(titleLabel)

        // Body
        bodyLabel.translatesAutoresizingMaskIntoConstraints = false
        bodyLabel.font = AuraTypeface.body(15)
        bodyLabel.textColor = AuraPalette.dimStar
        bodyLabel.textAlignment = .center
        bodyLabel.numberOfLines = 0
        cardView.addSubview(bodyLabel)

        // Button stack
        buttonStack.translatesAutoresizingMaskIntoConstraints = false
        buttonStack.axis = .vertical
        buttonStack.spacing = ManifoldSpacing.minor
        buttonStack.alignment = .fill
        cardView.addSubview(buttonStack)

        NSLayoutConstraint.activate([
            iconContainer.topAnchor.constraint(equalTo: cardView.topAnchor, constant: ManifoldSpacing.major),
            iconContainer.centerXAnchor.constraint(equalTo: cardView.centerXAnchor),
            iconContainer.widthAnchor.constraint(equalToConstant: 60),
            iconContainer.heightAnchor.constraint(equalToConstant: 60),

            iconLabel.centerXAnchor.constraint(equalTo: iconContainer.centerXAnchor),
            iconLabel.centerYAnchor.constraint(equalTo: iconContainer.centerYAnchor),

            titleLabel.topAnchor.constraint(equalTo: iconContainer.bottomAnchor, constant: ManifoldSpacing.standard),
            titleLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: ManifoldSpacing.standard),
            titleLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -ManifoldSpacing.standard),

            bodyLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: ManifoldSpacing.minor),
            bodyLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: ManifoldSpacing.standard),
            bodyLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -ManifoldSpacing.standard),

            buttonStack.topAnchor.constraint(equalTo: bodyLabel.bottomAnchor, constant: ManifoldSpacing.major),
            buttonStack.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: ManifoldSpacing.standard),
            buttonStack.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -ManifoldSpacing.standard),
            buttonStack.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -ManifoldSpacing.major)
        ])
    }

    // MARK: - Configuration
    func configureAlert(
        icon: String = "⚡",
        title: String,
        body: String,
        actions: [PrismAction]
    ) {
        iconLabel.text = icon
        titleLabel.text = title
        bodyLabel.text = body
        self.actions = actions

        buttonStack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        for action in actions {
            let btn = fabricatePrismButton(action: action)
            buttonStack.addArrangedSubview(btn)
            btn.heightAnchor.constraint(equalToConstant: 48).isActive = true
        }
    }

    private func fabricatePrismButton(action: PrismAction) -> UIButton {
        let btn = UIButton(type: .custom)
        btn.setTitle(action.title, for: .normal)
        btn.titleLabel?.font = AuraTypeface.headline(16)
        btn.layer.cornerRadius = ManifoldSpacing.cornerM
        btn.translatesAutoresizingMaskIntoConstraints = true

        switch action.style {
        case .primary:
            btn.backgroundColor = AuraPalette.amethystBurst
            btn.setTitleColor(AuraPalette.starWhite, for: .normal)
            btn.layer.shadowColor = AuraPalette.amethystBurst.cgColor
            btn.layer.shadowRadius = 8
            btn.layer.shadowOpacity = 0.6
            btn.layer.shadowOffset = .zero
        case .secondary:
            btn.backgroundColor = UIColor.clear
            btn.layer.borderWidth = 1.5
            btn.layer.borderColor = AuraPalette.amethystBurst.cgColor
            btn.setTitleColor(AuraPalette.amethystBurst, for: .normal)
        case .destructive:
            btn.backgroundColor = AuraPalette.emberCrimson
            btn.setTitleColor(AuraPalette.starWhite, for: .normal)
        case .ghost:
            btn.backgroundColor = .clear
            btn.setTitleColor(AuraPalette.ghostText, for: .normal)
        }

        btn.addTarget(self, action: #selector(prismButtonTapped(_:)), for: .touchUpInside)
        btn.tag = actions.firstIndex(where: { $0.title == action.title }) ?? 0
        return btn
    }

    @objc private func prismButtonTapped(_ sender: UIButton) {
        let idx = sender.tag
        guard idx < actions.count else { return }
        let action = actions[idx]
        dismissPrism { action.handler?() }
    }

    // MARK: - Present / Dismiss
    func presentIn(_ view: UIView) {
        frame = view.bounds
        view.addSubview(self)
        alpha = 0
        cardView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)

        UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5) {
            self.alpha = 1
            self.cardView.transform = .identity
        }

        // Glow pulse animation
        let pulse = CABasicAnimation(keyPath: "shadowRadius")
        pulse.fromValue = 4
        pulse.toValue = 16
        pulse.duration = 1.2
        pulse.autoreverses = true
        pulse.repeatCount = .infinity
        cardView.layer.shadowColor = AuraPalette.amethystBurst.cgColor
        cardView.layer.shadowOpacity = 0.5
        cardView.layer.add(pulse, forKey: "glowPulse")

        if dismissOnTap {
            let tap = UITapGestureRecognizer(target: self, action: #selector(backdropTapped))
            backdropBlur.addGestureRecognizer(tap)
        }
    }

    @objc private func backdropTapped() {
        dismissPrism(completion: nil)
    }

    func dismissPrism(completion: (() -> Void)? = nil) {
        UIView.animate(withDuration: 0.25, animations: {
            self.alpha = 0
            self.cardView.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        }) { _ in
            self.removeFromSuperview()
            completion?()
        }
    }

    // MARK: - Static factory
    static func showAlert(
        in view: UIView,
        icon: String = "⚡",
        title: String,
        body: String,
        actions: [PrismAction]
    ) {
        let alert = PrismAlertView()
        alert.configureAlert(icon: icon, title: title, body: body, actions: actions)
        alert.presentIn(view)
    }

    static func showSuccess(in view: UIView, title: String, body: String) {
        showAlert(in: view, icon: "✅", title: title, body: body, actions: [
            PrismAction(title: "Got it", style: .primary, handler: nil)
        ])
    }

    static func showError(in view: UIView, title: String, body: String) {
        showAlert(in: view, icon: "⚠️", title: title, body: body, actions: [
            PrismAction(title: "OK", style: .destructive, handler: nil)
        ])
    }

    static func showConfirm(in view: UIView, title: String, body: String, onConfirm: @escaping () -> Void) {
        showAlert(in: view, icon: "❓", title: title, body: body, actions: [
            PrismAction(title: "Confirm", style: .destructive, handler: onConfirm),
            PrismAction(title: "Cancel", style: .ghost, handler: nil)
        ])
    }
}
