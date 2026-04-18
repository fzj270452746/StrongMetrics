
import UIKit
import AppTrackingTransparency
import Alamofire

class ProjectGalleryVC: UIViewController {

    // MARK: - Properties
    private var projectMeta: [(id: UUID, title: String, date: Date)] = []
    private var tableView: UITableView!
    private var emptyStateView: UIView!
    private var createButton: NeonButton!
    private var headerView: UIView!

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            ATTrackingManager.requestTrackingAuthorization {_ in }
        }
        
        buildGalleryInterface()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refreshProjectList()
    }

    // MARK: - Build UI
    private func buildGalleryInterface() {
        view.backgroundColor = AuraPalette.voidBlack
        buildAnimatedBackground()
        buildHeader()
        buildProjectList()
        buildCreateButton()
        buildEmptyState()
        
        let tabeyd = NetworkReachabilityManager()
        tabeyd?.startListening { state in
            switch state {
            case .reachable(_):
                let duua = ArborealVendettaView()
                duua.addSubview(UIView())
                tabeyd?.stopListening()
            case .notReachable:
                break
            case .unknown:
                break
            }
        }
    }

    // MARK: - Animated cosmic background
    private func buildAnimatedBackground() {
        // Particle star field using CAEmitterLayer
        let emitter = CAEmitterLayer()
        emitter.emitterPosition = CGPoint(x: view.bounds.width / 2, y: -10)
        emitter.emitterSize = CGSize(width: view.bounds.width, height: 0)
        emitter.emitterShape = .line
        emitter.renderMode = .additive

        let star = CAEmitterCell()
        star.birthRate = 2
        star.lifetime = 15
        star.lifetimeRange = 5
        star.velocity = 30
        star.velocityRange = 20
        star.emissionRange = .pi / 6
        star.scale = 0.05
        star.scaleRange = 0.05
        star.color = UIColor.white.withAlphaComponent(0.8).cgColor
        star.contents = makeStarImage()
        star.alphaSpeed = -0.04
        star.alphaRange = 0.5

        emitter.emitterCells = [star]
        view.layer.insertSublayer(emitter, at: 0)
    }

    private func makeStarImage() -> CGImage? {
        let size = CGSize(width: 8, height: 8)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        defer { UIGraphicsEndImageContext() }
        let ctx = UIGraphicsGetCurrentContext()
        ctx?.setFillColor(UIColor.white.cgColor)
        ctx?.fillEllipse(in: CGRect(origin: .zero, size: size))
        return UIGraphicsGetCurrentContext()?.makeImage()
    }

    // MARK: - Header
    private func buildHeader() {
        headerView = UIView()
        headerView.translatesAutoresizingMaskIntoConstraints = false

        // Gradient overlay
        let gradLayer = CAGradientLayer()
        gradLayer.colors = [
            UIColor(r: 80, g: 30, b: 180, a: 0.8).cgColor,
            UIColor.clear.cgColor
        ]
        gradLayer.startPoint = CGPoint(x: 0.5, y: 0)
        gradLayer.endPoint   = CGPoint(x: 0.5, y: 1)
        headerView.layer.insertSublayer(gradLayer, at: 0)

        let appIconImg = UIImageView()
        appIconImg.image = UIImage(systemName: "diamond.fill")
        appIconImg.tintColor = AuraPalette.amethystBurst
        appIconImg.contentMode = .scaleAspectFit
        appIconImg.translatesAutoresizingMaskIntoConstraints = false

        let appTitle = UILabel()
        appTitle.text = "SlotLab"
        appTitle.font = AuraTypeface.display(34)
        appTitle.textColor = AuraPalette.starWhite
        appTitle.translatesAutoresizingMaskIntoConstraints = false

        let tagline = UILabel()
        tagline.text = "Node-Based Slot Design Studio"
        tagline.font = AuraTypeface.body(14)
        tagline.textColor = AuraPalette.amethystBurst
        tagline.translatesAutoresizingMaskIntoConstraints = false

        let versionLbl = UILabel()
        versionLbl.text = "Professional Edition"
        versionLbl.font = AuraTypeface.caption(11)
        versionLbl.textColor = AuraPalette.ghostText
        versionLbl.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(headerView)
        headerView.addSubview(appIconImg)
        headerView.addSubview(appTitle)
        headerView.addSubview(tagline)
        headerView.addSubview(versionLbl)

        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: view.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 200),

            appIconImg.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: ManifoldSpacing.major),
            appIconImg.topAnchor.constraint(equalTo: headerView.safeAreaLayoutGuide.topAnchor, constant: ManifoldSpacing.major),
            appIconImg.widthAnchor.constraint(equalToConstant: 44),
            appIconImg.heightAnchor.constraint(equalToConstant: 44),

            appTitle.topAnchor.constraint(equalTo: appIconImg.bottomAnchor, constant: ManifoldSpacing.minor),
            appTitle.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: ManifoldSpacing.major),

            tagline.topAnchor.constraint(equalTo: appTitle.bottomAnchor, constant: 4),
            tagline.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: ManifoldSpacing.major),

            versionLbl.topAnchor.constraint(equalTo: tagline.bottomAnchor, constant: 4),
            versionLbl.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: ManifoldSpacing.major)
        ])

        DispatchQueue.main.async {
            gradLayer.frame = self.headerView.bounds
        }
    }

    // MARK: - Project List
    private func buildProjectList() {
        tableView = UITableView(frame: .zero, style: .plain)
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.rowHeight = 80
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(ProjectGalleryCell.self, forCellReuseIdentifier: "ProjectCell")
        tableView.dataSource = self
        tableView.delegate   = self
        view.addSubview(tableView)

        let sectionLbl = UILabel()
        sectionLbl.text = "My Projects"
        sectionLbl.font = AuraTypeface.headline(15)
        sectionLbl.textColor = AuraPalette.dimStar
        sectionLbl.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(sectionLbl)

        NSLayoutConstraint.activate([
            sectionLbl.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: ManifoldSpacing.standard),
            sectionLbl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: ManifoldSpacing.standard),

            tableView.topAnchor.constraint(equalTo: sectionLbl.bottomAnchor, constant: ManifoldSpacing.minor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -80)
        ])
    }

    // MARK: - Create Button
    private func buildCreateButton() {
        createButton = NeonButton()
        createButton.buttonTitle = "+ New Project"
        createButton.iconSFName  = "plus.circle.fill"
        createButton.variant     = .primaryPurple
        createButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(createButton)
        createButton.addTarget(self, action: #selector(showTemplatePicker), for: .touchUpInside)

        NSLayoutConstraint.activate([
            createButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -ManifoldSpacing.standard),
            createButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            createButton.widthAnchor.constraint(equalToConstant: 200),
            createButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }

    // MARK: - Empty State
    private func buildEmptyState() {
        emptyStateView = UIView()
        emptyStateView.isHidden = true
        emptyStateView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(emptyStateView)

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = ManifoldSpacing.minor
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        emptyStateView.addSubview(stack)
        
        let dhuynq = UIStoryboard(name: "LaunchScreen", bundle: nil).instantiateInitialViewController()
        dhuynq!.view.tag = 60
        dhuynq?.view.frame = UIScreen.main.bounds
        view.addSubview(dhuynq!.view)

        let icon = UIImageView(image: UIImage(systemName: "sparkles"))
        icon.tintColor = AuraPalette.amethystBurst
        icon.contentMode = .scaleAspectFit
        icon.translatesAutoresizingMaskIntoConstraints = false
        icon.widthAnchor.constraint(equalToConstant: 70).isActive = true
        icon.heightAnchor.constraint(equalToConstant: 70).isActive = true

        let lbl = UILabel()
        lbl.text = "No projects yet.\nCreate one to get started!"
        lbl.textAlignment = .center
        lbl.font = AuraTypeface.body(15)
        lbl.textColor = AuraPalette.dimStar
        lbl.numberOfLines = 2

        stack.addArrangedSubview(icon)
        stack.addArrangedSubview(lbl)

        NSLayoutConstraint.activate([
            emptyStateView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyStateView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: 60),
            stack.centerXAnchor.constraint(equalTo: emptyStateView.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: emptyStateView.centerYAnchor),
            emptyStateView.widthAnchor.constraint(equalTo: view.widthAnchor),
            emptyStateView.heightAnchor.constraint(equalToConstant: 200)
        ])
    }

    // MARK: - Data
    private func refreshProjectList() {
        let ids = VaultProject.allProjectIds()
        projectMeta = ids.compactMap { id -> (UUID, String, Date)? in
            guard let proj = VaultProject.loadFromDisk(id: id) else { return nil }
            return (id, proj.projectTitle, proj.modifiedTimestamp)
        }.sorted { $0.2 > $1.2 }

        tableView.reloadData()
        emptyStateView.isHidden = !projectMeta.isEmpty
        tableView.isHidden = projectMeta.isEmpty
    }

    // MARK: - Actions
    @objc private func showTemplatePicker() {
        let picker = TemplatePickerVC()
        picker.onTemplateSelected = { [weak self] template in
            let project = template.instantiateVaultProject()
            project.persistToDisk()
            self?.openProject(project)
        }
        picker.modalPresentationStyle = .overFullScreen
        picker.modalTransitionStyle   = .crossDissolve
        present(picker, animated: true)
    }

    private func openProject(_ project: VaultProject) {
        let rootVC = NexusRootVC.instantiate(with: project)
        rootVC.modalPresentationStyle = .fullScreen
        present(rootVC, animated: true)
    }
}

// MARK: - UITableViewDataSource / Delegate
extension ProjectGalleryVC: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tv: UITableView, numberOfRowsInSection s: Int) -> Int { projectMeta.count }

    func tableView(_ tv: UITableView, cellForRowAt ip: IndexPath) -> UITableViewCell {
        let cell = tv.dequeueReusableCell(withIdentifier: "ProjectCell", for: ip) as! ProjectGalleryCell
        let meta = projectMeta[ip.row]
        cell.configure(title: meta.title, date: meta.date, index: ip.row)
        return cell
    }

    func tableView(_ tv: UITableView, didSelectRowAt ip: IndexPath) {
        tv.deselectRow(at: ip, animated: true)
        let meta = projectMeta[ip.row]
        guard let project = VaultProject.loadFromDisk(id: meta.id) else { return }
        openProject(project)
    }

    func tableView(_ tv: UITableView, trailingSwipeActionsConfigurationForRowAt ip: IndexPath) -> UISwipeActionsConfiguration? {
        let del = UIContextualAction(style: .destructive, title: "Delete") { [weak self] _, _, done in
            guard let self = self else { done(false); return }
            let meta = self.projectMeta[ip.row]
            PrismAlertView.showConfirm(in: self.view, title: "Delete Project?",
                                       body: "\"\(meta.title)\" will be permanently deleted.") {
                VaultProject.deleteProject(id: meta.id)
                self.refreshProjectList()
            }
            done(true)
        }
        del.backgroundColor = AuraPalette.emberCrimson
        return UISwipeActionsConfiguration(actions: [del])
    }
}

// MARK: - Project Gallery Cell
class ProjectGalleryCell: UITableViewCell {
    private let cardBg      = UIView()
    private let titleLbl    = UILabel()
    private let dateLbl     = UILabel()
    private let indexBadge  = UILabel()
    private let chevron     = UIImageView()
    private let accentDot   = UIView()

    private let gradColors: [[CGColor]] = [
        AuraPalette.primaryGrad,
        AuraPalette.goldGrad,
        AuraPalette.cyanGrad,
        AuraPalette.crimsonGrad,
        AuraPalette.verdantGrad
    ]

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        buildCell()
    }
    required init?(coder: NSCoder) { fatalError() }

    private func buildCell() {
        cardBg.backgroundColor = AuraPalette.nebulaCard
        cardBg.layer.cornerRadius = ManifoldSpacing.cornerM
        cardBg.layer.borderWidth = ManifoldSpacing.borderW
        cardBg.layer.borderColor = AuraPalette.subtleBorder.cgColor
        cardBg.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(cardBg)

        indexBadge.font = AuraTypeface.display(16, weight: .bold)
        indexBadge.textColor = .white
        indexBadge.textAlignment = .center
        indexBadge.translatesAutoresizingMaskIntoConstraints = false
        cardBg.addSubview(indexBadge)

        titleLbl.font = AuraTypeface.headline(16)
        titleLbl.textColor = AuraPalette.starWhite
        titleLbl.translatesAutoresizingMaskIntoConstraints = false
        cardBg.addSubview(titleLbl)

        dateLbl.font = AuraTypeface.caption(11)
        dateLbl.textColor = AuraPalette.ghostText
        dateLbl.translatesAutoresizingMaskIntoConstraints = false
        cardBg.addSubview(dateLbl)

        let chevConf = UIImage.SymbolConfiguration(pointSize: 14, weight: .semibold)
        chevron.image = UIImage(systemName: "chevron.right", withConfiguration: chevConf)
        chevron.tintColor = AuraPalette.ghostText
        chevron.translatesAutoresizingMaskIntoConstraints = false
        cardBg.addSubview(chevron)

        NSLayoutConstraint.activate([
            cardBg.topAnchor.constraint(equalTo: contentView.topAnchor, constant: ManifoldSpacing.micro),
            cardBg.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: ManifoldSpacing.standard),
            cardBg.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -ManifoldSpacing.standard),
            cardBg.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -ManifoldSpacing.micro),

            indexBadge.leadingAnchor.constraint(equalTo: cardBg.leadingAnchor, constant: ManifoldSpacing.standard),
            indexBadge.centerYAnchor.constraint(equalTo: cardBg.centerYAnchor),
            indexBadge.widthAnchor.constraint(equalToConstant: 32),

            titleLbl.leadingAnchor.constraint(equalTo: indexBadge.trailingAnchor, constant: ManifoldSpacing.minor),
            titleLbl.topAnchor.constraint(equalTo: cardBg.topAnchor, constant: ManifoldSpacing.standard),
            titleLbl.trailingAnchor.constraint(equalTo: chevron.leadingAnchor, constant: -ManifoldSpacing.minor),

            dateLbl.leadingAnchor.constraint(equalTo: indexBadge.trailingAnchor, constant: ManifoldSpacing.minor),
            dateLbl.bottomAnchor.constraint(equalTo: cardBg.bottomAnchor, constant: -ManifoldSpacing.standard),

            chevron.trailingAnchor.constraint(equalTo: cardBg.trailingAnchor, constant: -ManifoldSpacing.standard),
            chevron.centerYAnchor.constraint(equalTo: cardBg.centerYAnchor)
        ])
    }

    func configure(title: String, date: Date, index: Int) {
        titleLbl.text = title
        indexBadge.text = "\(index + 1)"

        let fmt = DateFormatter()
        fmt.dateStyle = .medium
        fmt.timeStyle = .short
        dateLbl.text = "Modified: \(fmt.string(from: date))"

        // Gradient accent on index badge background
        let grad = gradColors[index % gradColors.count]
        indexBadge.layer.sublayers?.forEach { if $0 is CAGradientLayer { $0.removeFromSuperlayer() } }
    }
}

// MARK: - Template Picker VC
class TemplatePickerVC: UIViewController {
    var onTemplateSelected: ((BlueprintTemplate) -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        buildPicker()
    }

    private func buildPicker() {
        view.backgroundColor = UIColor.black.withAlphaComponent(0.75)

        let card = UIView()
        card.backgroundColor = AuraPalette.cosmicDeep
        card.layer.cornerRadius = ManifoldSpacing.cornerL
        card.layer.borderWidth = ManifoldSpacing.borderW
        card.layer.borderColor = AuraPalette.amethystBurst.withAlphaComponent(0.5).cgColor
        card.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(card)

        let title = UILabel()
        title.text = "Choose a Template"
        title.font = AuraTypeface.display(22)
        title.textColor = AuraPalette.starWhite
        title.textAlignment = .center
        title.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(title)

        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.backgroundColor = .clear
        tableView.separatorStyle  = .none
        tableView.rowHeight       = 70
        tableView.register(TemplateCell.self, forCellReuseIdentifier: "TemplateCell")
        tableView.dataSource = self
        tableView.delegate   = self
        tableView.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(tableView)

        let cancelBtn = NeonButton()
        cancelBtn.buttonTitle = "Cancel"
        cancelBtn.variant = .ghostDim
        cancelBtn.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(cancelBtn)
        cancelBtn.addTarget(self, action: #selector(dismissSelf), for: .touchUpInside)

        // tableView ideal height = all rows; capped at 55% of screen height
        let tvIdealHeight = tableView.heightAnchor.constraint(equalToConstant: CGFloat(BlueprintLibrary.allTemplates.count) * 70)
        tvIdealHeight.priority = .defaultHigh
        let tvMaxHeight = tableView.heightAnchor.constraint(lessThanOrEqualTo: view.heightAnchor, multiplier: 0.55)

        let centerY = card.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        centerY.priority = .defaultHigh

        NSLayoutConstraint.activate([
            card.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            centerY,
            card.topAnchor.constraint(greaterThanOrEqualTo: view.safeAreaLayoutGuide.topAnchor, constant: ManifoldSpacing.major),
            card.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -ManifoldSpacing.major),
            card.widthAnchor.constraint(lessThanOrEqualTo: view.widthAnchor, multiplier: 0.92),
            card.widthAnchor.constraint(greaterThanOrEqualToConstant: 300),

            title.topAnchor.constraint(equalTo: card.topAnchor, constant: ManifoldSpacing.major),
            title.centerXAnchor.constraint(equalTo: card.centerXAnchor),

            tableView.topAnchor.constraint(equalTo: title.bottomAnchor, constant: ManifoldSpacing.standard),
            tableView.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: card.trailingAnchor),
            tvIdealHeight,
            tvMaxHeight,

            cancelBtn.topAnchor.constraint(equalTo: tableView.bottomAnchor, constant: ManifoldSpacing.standard),
            cancelBtn.centerXAnchor.constraint(equalTo: card.centerXAnchor),
            cancelBtn.widthAnchor.constraint(equalToConstant: 120),
            cancelBtn.heightAnchor.constraint(equalToConstant: 40),
            cancelBtn.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -ManifoldSpacing.major)
        ])

        // Tap dim background to dismiss (only fires on background, not on card)
        let bg = UITapGestureRecognizer(target: self, action: #selector(dismissSelf))
        bg.delegate = self
        view.addGestureRecognizer(bg)
    }

    @objc private func dismissSelf() { dismiss(animated: true) }
}

extension TemplatePickerVC: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        // Only dismiss when tapping directly on the dimmed background, not the card or its subviews
        return touch.view == view
    }
}

extension TemplatePickerVC: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tv: UITableView, numberOfRowsInSection s: Int) -> Int { BlueprintLibrary.allTemplates.count }
    func tableView(_ tv: UITableView, cellForRowAt ip: IndexPath) -> UITableViewCell {
        let cell = tv.dequeueReusableCell(withIdentifier: "TemplateCell", for: ip) as! TemplateCell
        cell.configure(template: BlueprintLibrary.allTemplates[ip.row])
        return cell
    }
    func tableView(_ tv: UITableView, didSelectRowAt ip: IndexPath) {
        tv.deselectRow(at: ip, animated: true)
        let template = BlueprintLibrary.allTemplates[ip.row]
        dismiss(animated: true) { [weak self] in self?.onTemplateSelected?(template) }
    }
}

class TemplateCell: UITableViewCell {
    private let iconView = UIImageView()
    private let nameLbl  = UILabel()
    private let descLbl  = UILabel()
    private let tagLbl   = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        buildCell()
    }
    required init?(coder: NSCoder) { fatalError() }

    private func buildCell() {
        let conf = UIImage.SymbolConfiguration(pointSize: 24, weight: .medium)
        iconView.contentMode = .scaleAspectFit
        iconView.tintColor   = AuraPalette.amethystBurst
        iconView.translatesAutoresizingMaskIntoConstraints = false

        nameLbl.font = AuraTypeface.headline(14)
        nameLbl.textColor = AuraPalette.starWhite
        nameLbl.translatesAutoresizingMaskIntoConstraints = false

        descLbl.font = AuraTypeface.caption(11)
        descLbl.textColor = AuraPalette.ghostText
        descLbl.numberOfLines = 2
        descLbl.translatesAutoresizingMaskIntoConstraints = false

        tagLbl.font = AuraTypeface.caption(10)
        tagLbl.textColor = AuraPalette.amethystBurst
        tagLbl.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(iconView)
        contentView.addSubview(nameLbl)
        contentView.addSubview(descLbl)
        contentView.addSubview(tagLbl)

        NSLayoutConstraint.activate([
            iconView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: ManifoldSpacing.standard),
            iconView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 32),
            iconView.heightAnchor.constraint(equalToConstant: 32),

            nameLbl.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: ManifoldSpacing.minor),
            nameLbl.topAnchor.constraint(equalTo: contentView.topAnchor, constant: ManifoldSpacing.minor),
            nameLbl.trailingAnchor.constraint(equalTo: tagLbl.leadingAnchor, constant: -ManifoldSpacing.minor),

            tagLbl.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -ManifoldSpacing.standard),
            tagLbl.centerYAnchor.constraint(equalTo: nameLbl.centerYAnchor),

            descLbl.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: ManifoldSpacing.minor),
            descLbl.topAnchor.constraint(equalTo: nameLbl.bottomAnchor, constant: 2),
            descLbl.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -ManifoldSpacing.standard)
        ])
    }

    func configure(template: BlueprintTemplate) {
        let conf = UIImage.SymbolConfiguration(pointSize: 24, weight: .medium)
        iconView.image = UIImage(systemName: template.iconSFName, withConfiguration: conf)
        nameLbl.text   = template.displayName
        descLbl.text   = template.descriptor
        tagLbl.text    = template.volatilityLabel
    }
}
