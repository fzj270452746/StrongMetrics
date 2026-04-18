// ModeSwitchTabBar.swift
// Custom animated top tab bar for switching between Build / Symbols / Bonus / Simulate / Analyze modes.

import UIKit

// MARK: - Mode
enum AppCoreMode: Int, CaseIterable {
    case build    = 0
    case symbols  = 1
    case bonus    = 2
    case simulate = 3
    case analyze  = 4

    var displayTitle: String {
        switch self {
        case .build:    return "Build"
        case .symbols:  return "Symbols"
        case .bonus:    return "Bonus"
        case .simulate: return "Simulate"
        case .analyze:  return "Analyze"
        }
    }

    var sfIconName: String {
        switch self {
        case .build:    return "square.on.square.intersection.dashed"
        case .symbols:  return "suit.diamond.fill"
        case .bonus:    return "bolt.circle.fill"
        case .simulate: return "play.circle.fill"
        case .analyze:  return "waveform.path.ecg"
        }
    }

    var tintColor: UIColor {
        switch self {
        case .build:    return AuraPalette.amethystBurst
        case .symbols:  return AuraPalette.cobaltFlare
        case .bonus:    return AuraPalette.emberCrimson
        case .simulate: return AuraPalette.verdantPulse
        case .analyze:  return AuraPalette.prismaticGold
        }
    }
}

// MARK: - Delegate
protocol ModeSwitchTabBarDelegate: AnyObject {
    func tabBarDidSelectMode(_ mode: AppCoreMode)
}

// MARK: - Mode Switch Tab Bar
class ModeSwitchTabBar: UIView {

    weak var tabDelegate: ModeSwitchTabBarDelegate?
    private(set) var currentMode: AppCoreMode = .build

    private var tabButtons: [UIControl] = []
    private let indicatorView = UIView()
    private let scrollView = UIScrollView()

    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        buildTabInterface()
    }
    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Build
    private func buildTabInterface() {
        backgroundColor = AuraPalette.cosmicDeep

        // Bottom border
        let border = UIView()
        border.backgroundColor = AuraPalette.subtleBorder
        border.translatesAutoresizingMaskIntoConstraints = false
        addSubview(border)
        NSLayoutConstraint.activate([
            border.leadingAnchor.constraint(equalTo: leadingAnchor),
            border.trailingAnchor.constraint(equalTo: trailingAnchor),
            border.bottomAnchor.constraint(equalTo: bottomAnchor),
            border.heightAnchor.constraint(equalToConstant: 0.5)
        ])

        scrollView.showsHorizontalScrollIndicator = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        let tabWidth: CGFloat = max(UIScreen.main.bounds.width / 5, 80)

        // Active indicator pill (frame-based, moves via selectMode)
        indicatorView.backgroundColor = AppCoreMode.build.tintColor.withAlphaComponent(0.25)
        indicatorView.layer.cornerRadius = 10
        scrollView.addSubview(indicatorView)

        for (i, mode) in AppCoreMode.allCases.enumerated() {
            let btn = buildTabButton(mode: mode)
            btn.translatesAutoresizingMaskIntoConstraints = false
            scrollView.addSubview(btn)
            tabButtons.append(btn)

            NSLayoutConstraint.activate([
                btn.topAnchor.constraint(equalTo: scrollView.frameLayoutGuide.topAnchor),
                btn.bottomAnchor.constraint(equalTo: scrollView.frameLayoutGuide.bottomAnchor),
                btn.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: CGFloat(i) * tabWidth),
                btn.widthAnchor.constraint(equalToConstant: tabWidth)
            ])
        }

        // content height = frame height (no vertical scroll); width drives horizontal scrolling
        let totalWidth = tabWidth * CGFloat(AppCoreMode.allCases.count)
        NSLayoutConstraint.activate([
            scrollView.contentLayoutGuide.heightAnchor.constraint(equalTo: scrollView.frameLayoutGuide.heightAnchor),
            scrollView.contentLayoutGuide.widthAnchor.constraint(equalToConstant: totalWidth)
        ])

        // Position indicator at initial tab
        indicatorView.frame = CGRect(x: 8, y: 6, width: 72, height: 36)

        selectMode(.build, animated: false)
    }

    private func buildTabButton(mode: AppCoreMode) -> UIControl {
        let btn = UIControl()
        btn.tag = mode.rawValue

        let iconView = UIImageView()
        let conf = UIImage.SymbolConfiguration(pointSize: 14, weight: .semibold)
        iconView.image = UIImage(systemName: mode.sfIconName, withConfiguration: conf)
        iconView.tintColor = AuraPalette.ghostText
        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.tag = 100

        let label = UILabel()
        label.text = mode.displayTitle
        label.font = AuraTypeface.caption(10)
        label.textColor = AuraPalette.ghostText
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        label.tag = 200

        btn.addSubview(iconView)
        btn.addSubview(label)

        NSLayoutConstraint.activate([
            iconView.centerXAnchor.constraint(equalTo: btn.centerXAnchor),
            iconView.topAnchor.constraint(equalTo: btn.topAnchor, constant: 8),
            iconView.widthAnchor.constraint(equalToConstant: 20),
            iconView.heightAnchor.constraint(equalToConstant: 20),

            label.topAnchor.constraint(equalTo: iconView.bottomAnchor, constant: 2),
            label.centerXAnchor.constraint(equalTo: btn.centerXAnchor)
        ])

        btn.addTarget(self, action: #selector(tabButtonTapped(_:)), for: .touchUpInside)
        return btn
    }

    @objc private func tabButtonTapped(_ sender: UIControl) {
        guard let mode = AppCoreMode(rawValue: sender.tag) else { return }
        selectMode(mode, animated: true)
        tabDelegate?.tabBarDidSelectMode(mode)
    }

    // MARK: - Select Mode
    func selectMode(_ mode: AppCoreMode, animated: Bool) {
        currentMode = mode
        let tabW = max(UIScreen.main.bounds.width / 5, 80)
        let targetX = CGFloat(mode.rawValue) * tabW + 8
        let accent = mode.tintColor

        let animBlock = {
            self.indicatorView.frame.origin.x = targetX
            self.indicatorView.frame.size.width = tabW - 16
            self.indicatorView.backgroundColor = accent.withAlphaComponent(0.2)

            for (i, btn) in self.tabButtons.enumerated() {
                let isSelected = i == mode.rawValue
                if let icon = btn.viewWithTag(100) as? UIImageView {
                    icon.tintColor = isSelected ? accent : AuraPalette.ghostText
                }
                if let lbl = btn.viewWithTag(200) as? UILabel {
                    lbl.textColor = isSelected ? accent : AuraPalette.ghostText
                    lbl.font = isSelected ? AuraTypeface.caption(10).withWeight(.semibold) : AuraTypeface.caption(10)
                }
                btn.transform = isSelected ? CGAffineTransform(scaleX: 1.05, y: 1.05) : .identity
            }
        }

        if animated {
            UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5, animations: animBlock)
        } else {
            animBlock()
        }
    }
}

extension UIFont {
    func withWeight(_ weight: UIFont.Weight) -> UIFont {
        UIFont.systemFont(ofSize: pointSize, weight: weight)
    }
}
