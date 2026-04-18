// LobeEditorVC.swift
// Symbol (Glyph) editor — create and configure individual symbols with probabilities and payouts.

import UIKit

class LobeEditorVC: UIViewController {

    // MARK: - Properties
    var vaultProject: VaultProject!
    private var glyphList: [GlyphModel] = []
    private var selectedGlyph: GlyphModel?

    private var tableView: UITableView!
    private var detailCard: GlyphDetailCard!
    private var addButton: NeonButton!
    private var emptyStateView: UIView!

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        glyphList = vaultProject.glyphRegistry
        buildLobeInterface()
        refreshGlyphList()
    }

    // MARK: - Build UI
    private func buildLobeInterface() {
        view.backgroundColor = AuraPalette.voidBlack

        // Header
        let header = buildSectionHeader(title: "Symbol Library", subtitle: "\(glyphList.count) symbols defined")
        header.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(header)

        // Table
        tableView = UITableView(frame: .zero, style: .plain)
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.rowHeight = 72
        tableView.register(GlyphTableCell.self, forCellReuseIdentifier: "GlyphCell")
        tableView.dataSource = self
        tableView.delegate   = self
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)

        // Detail card
        detailCard = GlyphDetailCard()
        detailCard.translatesAutoresizingMaskIntoConstraints = false
        detailCard.isHidden = true
        detailCard.onSave = { [weak self] in self?.saveGlyphEdits() }
        view.addSubview(detailCard)

        // Add button
        addButton = NeonButton()
        addButton.buttonTitle = "+ New Symbol"
        addButton.iconSFName = "plus.circle.fill"
        addButton.variant = .verdantGreen
        addButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(addButton)
        addButton.addTarget(self, action: #selector(addNewGlyph), for: .touchUpInside)

        // Empty state
        emptyStateView = buildEmptyState()
        emptyStateView.translatesAutoresizingMaskIntoConstraints = false
        emptyStateView.isHidden = true
        view.addSubview(emptyStateView)

        NSLayoutConstraint.activate([
            header.topAnchor.constraint(equalTo: view.topAnchor),
            header.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            header.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            header.heightAnchor.constraint(equalToConstant: 60),

            tableView.topAnchor.constraint(equalTo: header.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: addButton.topAnchor, constant: -ManifoldSpacing.minor),

            addButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -ManifoldSpacing.standard),
            addButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            addButton.widthAnchor.constraint(equalToConstant: 180),
            addButton.heightAnchor.constraint(equalToConstant: 46),

            detailCard.topAnchor.constraint(equalTo: header.bottomAnchor, constant: ManifoldSpacing.minor),
            detailCard.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: ManifoldSpacing.minor),
            detailCard.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -ManifoldSpacing.minor),
            detailCard.heightAnchor.constraint(equalToConstant: 340),

            emptyStateView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyStateView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    private func buildSectionHeader(title: String, subtitle: String) -> UIView {
        let container = UIView()
        container.backgroundColor = .clear

        let titleLbl = UILabel()
        titleLbl.text = title
        titleLbl.font = AuraTypeface.display(18)
        titleLbl.textColor = AuraPalette.starWhite
        titleLbl.translatesAutoresizingMaskIntoConstraints = false

        let subtitleLbl = UILabel()
        subtitleLbl.text = subtitle
        subtitleLbl.font = AuraTypeface.caption(12)
        subtitleLbl.textColor = AuraPalette.dimStar
        subtitleLbl.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(titleLbl)
        container.addSubview(subtitleLbl)

        NSLayoutConstraint.activate([
            titleLbl.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: ManifoldSpacing.standard),
            titleLbl.topAnchor.constraint(equalTo: container.topAnchor, constant: ManifoldSpacing.standard),
            subtitleLbl.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: ManifoldSpacing.standard),
            subtitleLbl.topAnchor.constraint(equalTo: titleLbl.bottomAnchor, constant: 2)
        ])

        return container
    }

    private func buildEmptyState() -> UIView {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = ManifoldSpacing.minor
        stack.alignment = .center

        let icon = UIImageView(image: UIImage(systemName: "sparkles"))
        icon.tintColor = AuraPalette.amethystBurst
        icon.contentMode = .scaleAspectFit
        icon.translatesAutoresizingMaskIntoConstraints = false
        icon.widthAnchor.constraint(equalToConstant: 60).isActive = true
        icon.heightAnchor.constraint(equalToConstant: 60).isActive = true

        let label = UILabel()
        label.text = "No symbols yet.\nTap + to add your first."
        label.font = AuraTypeface.body(15)
        label.textColor = AuraPalette.dimStar
        label.numberOfLines = 2
        label.textAlignment = .center

        stack.addArrangedSubview(icon)
        stack.addArrangedSubview(label)
        return stack
    }

    // MARK: - Actions
    @objc private func addNewGlyph() {
        let newGlyph = GlyphModel(appellationLabel: "New Symbol \(glyphList.count + 1)")
        vaultProject.glyphRegistry.append(newGlyph)
        glyphList = vaultProject.glyphRegistry
        tableView.reloadData()
        selectGlyph(newGlyph)
    }

    private func selectGlyph(_ glyph: GlyphModel) {
        selectedGlyph = glyph
        detailCard.configure(glyph: glyph)
        showDetailCard(true)
    }

    private func showDetailCard(_ show: Bool) {
        UIView.animate(withDuration: 0.35, delay: 0, usingSpringWithDamping: 0.85, initialSpringVelocity: 0.5) {
            self.detailCard.isHidden = !show
            self.detailCard.alpha = show ? 1 : 0
        }
    }

    private func saveGlyphEdits() {
        vaultProject.glyphRegistry = glyphList
        glyphList = vaultProject.glyphRegistry
        tableView.reloadData()
        PrismAlertView.showSuccess(in: view, title: "Saved", body: "Symbol configuration updated.")
    }

    private func refreshGlyphList() {
        emptyStateView.isHidden = !glyphList.isEmpty
        tableView.isHidden = glyphList.isEmpty
        tableView.reloadData()
    }
}

// MARK: - UITableViewDataSource / Delegate
extension LobeEditorVC: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tv: UITableView, numberOfRowsInSection s: Int) -> Int { glyphList.count }

    func tableView(_ tv: UITableView, cellForRowAt ip: IndexPath) -> UITableViewCell {
        let cell = tv.dequeueReusableCell(withIdentifier: "GlyphCell", for: ip) as! GlyphTableCell
        cell.configure(glyph: glyphList[ip.row])
        return cell
    }

    func tableView(_ tv: UITableView, didSelectRowAt ip: IndexPath) {
        tv.deselectRow(at: ip, animated: true)
        selectGlyph(glyphList[ip.row])
    }

    func tableView(_ tv: UITableView, trailingSwipeActionsConfigurationForRowAt ip: IndexPath) -> UISwipeActionsConfiguration? {
        let del = UIContextualAction(style: .destructive, title: "Delete") { [weak self] _, _, done in
            guard let self = self else { done(false); return }
            PrismAlertView.showConfirm(in: self.view, title: "Delete Symbol?", body: "This cannot be undone.") {
                self.glyphList.remove(at: ip.row)
                self.vaultProject.glyphRegistry = self.glyphList
                tv.deleteRows(at: [ip], with: .automatic)
                self.refreshGlyphList()
            }
            done(true)
        }
        del.backgroundColor = AuraPalette.emberCrimson
        return UISwipeActionsConfiguration(actions: [del])
    }
}

// MARK: - Glyph Table Cell
class GlyphTableCell: UITableViewCell {
    private let accentBar   = UIView()
    private let iconView    = UIImageView()
    private let nameLabel   = UILabel()
    private let categoryTag = UILabel()
    private let probLabel   = UILabel()
    private let weightLabel = UILabel()
    private let cardBg      = UIView()

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

        accentBar.layer.cornerRadius = 2
        accentBar.translatesAutoresizingMaskIntoConstraints = false
        cardBg.addSubview(accentBar)

        let imgConf = UIImage.SymbolConfiguration(pointSize: 22, weight: .semibold)
        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false
        cardBg.addSubview(iconView)

        nameLabel.font = AuraTypeface.headline(15)
        nameLabel.textColor = AuraPalette.starWhite
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        cardBg.addSubview(nameLabel)

        categoryTag.font = AuraTypeface.caption(10)
        categoryTag.layer.cornerRadius = 6
        categoryTag.layer.masksToBounds = true
        categoryTag.textAlignment = .center
        categoryTag.translatesAutoresizingMaskIntoConstraints = false
        cardBg.addSubview(categoryTag)

        probLabel.font = AuraTypeface.mono(12)
        probLabel.textColor = AuraPalette.cobaltFlare
        probLabel.translatesAutoresizingMaskIntoConstraints = false
        cardBg.addSubview(probLabel)

        weightLabel.font = AuraTypeface.mono(12)
        weightLabel.textColor = AuraPalette.dimStar
        weightLabel.translatesAutoresizingMaskIntoConstraints = false
        cardBg.addSubview(weightLabel)

        NSLayoutConstraint.activate([
            cardBg.topAnchor.constraint(equalTo: contentView.topAnchor, constant: ManifoldSpacing.micro),
            cardBg.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: ManifoldSpacing.standard),
            cardBg.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -ManifoldSpacing.standard),
            cardBg.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -ManifoldSpacing.micro),

            accentBar.leadingAnchor.constraint(equalTo: cardBg.leadingAnchor),
            accentBar.topAnchor.constraint(equalTo: cardBg.topAnchor, constant: ManifoldSpacing.minor),
            accentBar.bottomAnchor.constraint(equalTo: cardBg.bottomAnchor, constant: -ManifoldSpacing.minor),
            accentBar.widthAnchor.constraint(equalToConstant: 4),

            iconView.leadingAnchor.constraint(equalTo: accentBar.trailingAnchor, constant: ManifoldSpacing.minor),
            iconView.centerYAnchor.constraint(equalTo: cardBg.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 30),
            iconView.heightAnchor.constraint(equalToConstant: 30),

            nameLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: ManifoldSpacing.minor),
            nameLabel.topAnchor.constraint(equalTo: cardBg.topAnchor, constant: ManifoldSpacing.minor),

            categoryTag.leadingAnchor.constraint(equalTo: nameLabel.trailingAnchor, constant: ManifoldSpacing.minor),
            categoryTag.centerYAnchor.constraint(equalTo: nameLabel.centerYAnchor),
            categoryTag.widthAnchor.constraint(greaterThanOrEqualToConstant: 50),
            categoryTag.heightAnchor.constraint(equalToConstant: 18),

            probLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: ManifoldSpacing.minor),
            probLabel.bottomAnchor.constraint(equalTo: cardBg.bottomAnchor, constant: -ManifoldSpacing.minor),

            weightLabel.trailingAnchor.constraint(equalTo: cardBg.trailingAnchor, constant: -ManifoldSpacing.standard),
            weightLabel.centerYAnchor.constraint(equalTo: cardBg.centerYAnchor)
        ])
    }

    func configure(glyph: GlyphModel) {
        let accent = glyph.glyphCategory.auricColor
        accentBar.backgroundColor = accent

        let conf = UIImage.SymbolConfiguration(pointSize: 20, weight: .semibold)
        iconView.image = UIImage(systemName: glyph.glyphCategory.glyphIconName, withConfiguration: conf)
        iconView.tintColor = accent

        nameLabel.text = glyph.appellationLabel

        categoryTag.text = "  \(glyph.glyphCategory.rawValue)  "
        categoryTag.textColor = accent
        categoryTag.backgroundColor = accent.withAlphaComponent(0.15)
        categoryTag.layer.borderWidth = 0.5
        categoryTag.layer.borderColor = accent.withAlphaComponent(0.4).cgColor

        probLabel.text = String(format: "%.1f%% spawn", glyph.spawnProbability * 100)
        weightLabel.text = "Wt: \(glyph.loadWeight)"
    }
}

// MARK: - Glyph Detail Card
class GlyphDetailCard: UIView {
    private var currentGlyph: GlyphModel?
    var onSave: (() -> Void)?

    private let nameField       = buildTextField(placeholder: "Symbol Name")
    private let probabilitySlider = UISlider()
    private let probValueLabel    = UILabel()
    private let weightField       = buildTextField(placeholder: "Weight (e.g. 10)")
    private let categorySelector  = UISegmentedControl()
    private var payoutFields: [UITextField] = []

    private static func buildTextField(placeholder: String) -> UITextField {
        let tf = UITextField()
        tf.backgroundColor = AuraPalette.stellarPanel
        tf.textColor = AuraPalette.starWhite
        tf.font = AuraTypeface.body(15)
        tf.layer.cornerRadius = ManifoldSpacing.cornerS
        tf.layer.borderWidth = 0.5
        tf.layer.borderColor = AuraPalette.subtleBorder.cgColor
        tf.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 1))
        tf.leftViewMode = .always
        tf.attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [.foregroundColor: AuraPalette.ghostText]
        )
        return tf
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        buildDetailUI()
    }
    required init?(coder: NSCoder) { fatalError() }

    private func buildDetailUI() {
        backgroundColor = AuraPalette.nebulaCard
        layer.cornerRadius = ManifoldSpacing.cornerL
        layer.borderWidth = ManifoldSpacing.borderW
        layer.borderColor = AuraPalette.amethystBurst.withAlphaComponent(0.5).cgColor

        let scroll = UIScrollView()
        scroll.translatesAutoresizingMaskIntoConstraints = false
        scroll.showsVerticalScrollIndicator = false
        addSubview(scroll)
        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: topAnchor, constant: ManifoldSpacing.standard),
            scroll.leadingAnchor.constraint(equalTo: leadingAnchor, constant: ManifoldSpacing.standard),
            scroll.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -ManifoldSpacing.standard),
            scroll.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -ManifoldSpacing.standard)
        ])

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = ManifoldSpacing.minor
        stack.translatesAutoresizingMaskIntoConstraints = false
        scroll.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: scroll.topAnchor),
            stack.leadingAnchor.constraint(equalTo: scroll.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: scroll.trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: scroll.bottomAnchor),
            stack.widthAnchor.constraint(equalTo: scroll.widthAnchor)
        ])

        // Name
        stack.addArrangedSubview(makeRowLabel("Symbol Name"))
        stack.addArrangedSubview(nameField)
        nameField.heightAnchor.constraint(equalToConstant: 38).isActive = true

        // Probability
        let probRow = UIStackView()
        probRow.spacing = ManifoldSpacing.minor
        probRow.alignment = .center
        probValueLabel.font = AuraTypeface.mono(14)
        probValueLabel.textColor = AuraPalette.cobaltFlare
        probValueLabel.widthAnchor.constraint(equalToConstant: 50).isActive = true
        probabilitySlider.minimumValue = 0.01
        probabilitySlider.maximumValue = 0.99
        probabilitySlider.tintColor = AuraPalette.amethystBurst
        probabilitySlider.addTarget(self, action: #selector(sliderChanged), for: .valueChanged)
        probRow.addArrangedSubview(probabilitySlider)
        probRow.addArrangedSubview(probValueLabel)
        stack.addArrangedSubview(makeRowLabel("Spawn Probability"))
        stack.addArrangedSubview(probRow)

        // Weight
        stack.addArrangedSubview(makeRowLabel("Strip Weight"))
        stack.addArrangedSubview(weightField)
        weightField.heightAnchor.constraint(equalToConstant: 38).isActive = true

        // Save button
        let saveBtn = NeonButton()
        saveBtn.buttonTitle = "Save Symbol"
        saveBtn.variant = .primaryPurple
        saveBtn.translatesAutoresizingMaskIntoConstraints = false
        saveBtn.heightAnchor.constraint(equalToConstant: 44).isActive = true
        saveBtn.addTarget(self, action: #selector(saveSymbol), for: .touchUpInside)
        stack.addArrangedSubview(saveBtn)
    }

    private func makeRowLabel(_ text: String) -> UILabel {
        let lbl = UILabel()
        lbl.text = text
        lbl.font = AuraTypeface.caption(11)
        lbl.textColor = AuraPalette.dimStar
        return lbl
    }

    func configure(glyph: GlyphModel) {
        currentGlyph = glyph
        nameField.text = glyph.appellationLabel
        probabilitySlider.value = Float(glyph.spawnProbability)
        weightField.text = "\(glyph.loadWeight)"
        probValueLabel.text = String(format: "%.0f%%", glyph.spawnProbability * 100)
    }

    @objc private func sliderChanged() {
        let val = Double(probabilitySlider.value)
        currentGlyph?.spawnProbability = val
        probValueLabel.text = String(format: "%.0f%%", val * 100)
    }

    @objc private func saveSymbol() {
        guard let g = currentGlyph else { return }
        if let name = nameField.text, !name.isEmpty { g.appellationLabel = name }
        if let wt = Int(weightField.text ?? "") { g.loadWeight = wt }
        onSave?()
    }
}
