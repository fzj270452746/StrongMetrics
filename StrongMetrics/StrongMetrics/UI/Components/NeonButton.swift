// NeonButton.swift
// Custom glowing neon-style button with gradient, glow effect and tap animations.

import UIKit

// MARK: - Neon Button Style
enum NeonButtonVariant {
    case primaryPurple
    case goldAccent
    case cyanOutline
    case crimsonDanger
    case ghostDim
    case verdantGreen
}

// MARK: - Neon Button
class NeonButton: UIControl {

    // MARK: - Properties
    private let gradLayer = CAGradientLayer()
    private let glowLayer = CALayer()
    private let titleLabel = UILabel()
    private let iconView   = UIImageView()
    private let hStack     = UIStackView()

    var variant: NeonButtonVariant = .primaryPurple { didSet { applyVariantStyling() } }
    var buttonTitle: String = "" { didSet { titleLabel.text = buttonTitle } }
    var iconSFName: String? { didSet { applyIcon() } }
    var isLoading: Bool = false { didSet { toggleLoadingState() } }

    private let spinner = UIActivityIndicatorView(style: .medium)

    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        buildHierarchy()
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Build
    private func buildHierarchy() {
        layer.cornerRadius = ManifoldSpacing.cornerM
        clipsToBounds = false

        // Glow shadow
        layer.shadowOffset = .zero
        layer.shadowRadius = 10
        layer.shadowOpacity = 0

        // Gradient fill
        gradLayer.cornerRadius = ManifoldSpacing.cornerM
        layer.insertSublayer(gradLayer, at: 0)

        // Horizontal stack for icon + title
        hStack.axis = .horizontal
        hStack.spacing = ManifoldSpacing.minor
        hStack.alignment = .center
        hStack.isUserInteractionEnabled = false
        hStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(hStack)

        iconView.contentMode = .scaleAspectFit
        iconView.tintColor = AuraPalette.starWhite
        iconView.isHidden = true

        titleLabel.font = AuraTypeface.headline(16)
        titleLabel.textColor = AuraPalette.starWhite
        titleLabel.textAlignment = .center

        hStack.addArrangedSubview(iconView)
        hStack.addArrangedSubview(titleLabel)

        NSLayoutConstraint.activate([
            hStack.centerXAnchor.constraint(equalTo: centerXAnchor),
            hStack.centerYAnchor.constraint(equalTo: centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 20),
            iconView.heightAnchor.constraint(equalToConstant: 20)
        ])

        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.hidesWhenStopped = true
        spinner.color = AuraPalette.starWhite
        addSubview(spinner)
        NSLayoutConstraint.activate([
            spinner.centerXAnchor.constraint(equalTo: centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])

        addTarget(self, action: #selector(touchDownHandler), for: .touchDown)
        addTarget(self, action: #selector(touchUpHandler), for: [.touchUpInside, .touchUpOutside, .touchCancel])
        addTarget(self, action: #selector(fireAction), for: .touchUpInside)

        applyVariantStyling()
    }

    // MARK: - Layout
    override func layoutSubviews() {
        super.layoutSubviews()
        gradLayer.frame = bounds
        gradLayer.cornerRadius = layer.cornerRadius
    }

    // MARK: - Variant Styling
    private func applyVariantStyling() {
        switch variant {
        case .primaryPurple:
            gradLayer.colors = AuraPalette.primaryGrad
            layer.shadowColor = AuraPalette.amethystBurst.cgColor
            layer.borderWidth = 0
            titleLabel.textColor = AuraPalette.starWhite

        case .goldAccent:
            gradLayer.colors = AuraPalette.goldGrad
            layer.shadowColor = AuraPalette.prismaticGold.cgColor
            titleLabel.textColor = UIColor(r: 20, g: 15, b: 0)

        case .cyanOutline:
            gradLayer.colors = [UIColor.clear.cgColor, UIColor.clear.cgColor]
            layer.borderWidth = 1.5
            layer.borderColor = AuraPalette.cobaltFlare.cgColor
            layer.shadowColor = AuraPalette.cobaltFlare.cgColor
            titleLabel.textColor = AuraPalette.cobaltFlare

        case .crimsonDanger:
            gradLayer.colors = AuraPalette.crimsonGrad
            layer.shadowColor = AuraPalette.emberCrimson.cgColor
            titleLabel.textColor = AuraPalette.starWhite

        case .ghostDim:
            gradLayer.colors = [UIColor.clear.cgColor, UIColor.clear.cgColor]
            layer.borderWidth = 0
            layer.shadowColor = UIColor.clear.cgColor
            titleLabel.textColor = AuraPalette.ghostText
            layer.shadowOpacity = 0

        case .verdantGreen:
            gradLayer.colors = AuraPalette.verdantGrad
            layer.shadowColor = AuraPalette.verdantPulse.cgColor
            titleLabel.textColor = UIColor(r: 0, g: 30, b: 10)
        }

        gradLayer.startPoint = CGPoint(x: 0, y: 0)
        gradLayer.endPoint = CGPoint(x: 1, y: 1)
    }

    private func applyIcon() {
        guard let name = iconSFName else {
            iconView.isHidden = true
            return
        }
        let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .semibold)
        iconView.image = UIImage(systemName: name, withConfiguration: config)
        iconView.tintColor = titleLabel.textColor
        iconView.isHidden = false
    }

    // MARK: - Touch Animations
    @objc private func touchDownHandler() {
        UIView.animate(withDuration: 0.1) {
            self.transform = CGAffineTransform(scaleX: 0.96, y: 0.96)
        }
        layer.shadowOpacity = 0.8
        layer.shadowRadius = 16
    }

    @objc private func touchUpHandler() {
        UIView.animate(withDuration: 0.2, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.5, options: []) {
            self.transform = .identity
        }
        layer.shadowOpacity = 0.4
        layer.shadowRadius = 10
    }

    @objc private func fireAction() {
        // Ripple flash
        let flash = UIView(frame: bounds)
        flash.backgroundColor = UIColor.white.withAlphaComponent(0.2)
        flash.layer.cornerRadius = layer.cornerRadius
        insertSubview(flash, aboveSubview: hStack)
        UIView.animate(withDuration: 0.3, animations: { flash.alpha = 0 }) { _ in flash.removeFromSuperview() }
    }

    // MARK: - Loading State
    private func toggleLoadingState() {
        if isLoading {
            spinner.startAnimating()
            hStack.isHidden = true
        } else {
            spinner.stopAnimating()
            hStack.isHidden = false
        }
        isEnabled = !isLoading
    }

    // MARK: - Override isEnabled
    override var isEnabled: Bool {
        didSet {
            UIView.animate(withDuration: 0.2) {
                self.alpha = self.isEnabled ? 1.0 : 0.5
            }
        }
    }
}

// MARK: - Icon-only circular button
class NeonIconButton: UIControl {
    private let imageView  = UIImageView()
    private let glowLayer  = CALayer()
    var glowColor: UIColor = AuraPalette.amethystBurst { didSet { updateGlow() } }

    override init(frame: CGRect) {
        super.init(frame: frame)
        buildHierarchy()
    }
    required init?(coder: NSCoder) { fatalError() }

    func configure(sfName: String, size: CGFloat = 20, tint: UIColor = AuraPalette.starWhite) {
        let config = UIImage.SymbolConfiguration(pointSize: size, weight: .semibold)
        imageView.image = UIImage(systemName: sfName, withConfiguration: config)
        imageView.tintColor = tint
        glowColor = tint
    }

    private func buildHierarchy() {
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.isUserInteractionEnabled = false
        addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            imageView.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.55),
            imageView.heightAnchor.constraint(equalTo: heightAnchor, multiplier: 0.55)
        ])
        layer.shadowOffset = .zero
        layer.shadowRadius = 8
        layer.shadowOpacity = 0.5
        layer.shadowColor = AuraPalette.amethystBurst.cgColor

        addTarget(self, action: #selector(touchDown), for: .touchDown)
        addTarget(self, action: #selector(touchUp), for: [.touchUpInside, .touchUpOutside, .touchCancel])
    }

    private func updateGlow() {
        layer.shadowColor = glowColor.cgColor
        imageView.tintColor = glowColor
    }

    @objc private func touchDown() {
        UIView.animate(withDuration: 0.1) { self.transform = CGAffineTransform(scaleX: 0.9, y: 0.9) }
    }

    @objc private func touchUp() {
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.5, options: []) {
            self.transform = .identity
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = bounds.width / 2
    }
}
