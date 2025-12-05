import SpriteKit

/// Тип перехода между уровнями
enum TransitionType {
    case portal   // Магический портал (светящийся)
    case door     // Обычная дверь
    case path     // Тропа (просто выход за край)
}

/// Выход с уровня - точка перехода на следующий уровень
class LevelExit: SKSpriteNode {

    // MARK: - Properties

    /// ID следующего уровня
    let nextLevelId: Int

    /// Активен ли выход
    private(set) var isActive: Bool = true

    /// Требуется ли ключ для активации
    var requiresKey: Bool = false

    /// ID требуемого ключа
    var keyId: String?

    /// Тип перехода
    let transitionType: TransitionType

    /// Предотвращает повторный вход в портал
    private var isEntering: Bool = false

    // MARK: - Visual Components

    /// Основной портал/дверь
    private var portalSprite: SKSpriteNode!

    /// Свечение портала
    private var glowNode: SKShapeNode!

    /// Частицы вокруг портала
    private var particleEmitter: SKEmitterNode?

    /// Индикатор направления (стрелка)
    private var arrowIndicator: SKSpriteNode?

    // MARK: - Colors

    private let portalColor = UIColor(red: 0.3, green: 0.5, blue: 0.9, alpha: 1.0)
    private let portalGlowColor = UIColor(red: 0.4, green: 0.6, blue: 1.0, alpha: 0.6)
    private let doorColor = UIColor(red: 0.4, green: 0.25, blue: 0.15, alpha: 1.0)
    private let pathColor = UIColor(red: 0.3, green: 0.7, blue: 0.4, alpha: 0.5)
    private let inactiveColor = UIColor(red: 0.3, green: 0.3, blue: 0.35, alpha: 0.7)

    // MARK: - Initialization

    init(nextLevelId: Int, transitionType: TransitionType = .portal) {
        self.nextLevelId = nextLevelId
        self.transitionType = transitionType

        let size = CGSize(width: 48, height: 64)
        super.init(texture: nil, color: .clear, size: size)

        self.name = "levelExit_\(nextLevelId)"

        setupVisuals()
        setupPhysics()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupVisuals() {
        switch transitionType {
        case .portal:
            setupPortalVisuals()
        case .door:
            setupDoorVisuals()
        case .path:
            setupPathVisuals()
        }

        // Общая стрелка-индикатор для всех типов
        setupArrowIndicator()
    }

    private func setupPortalVisuals() {
        // Основное тело портала - овал
        let portalSize = CGSize(width: 40, height: 56)
        portalSprite = SKSpriteNode(color: portalColor, size: portalSize)
        portalSprite.position = .zero
        portalSprite.zPosition = 0

        // Скругление через shape
        let shapeNode = SKShapeNode(ellipseOf: portalSize)
        shapeNode.fillColor = portalColor
        shapeNode.strokeColor = portalGlowColor
        shapeNode.lineWidth = 3
        shapeNode.glowWidth = 5
        shapeNode.zPosition = 0
        addChild(shapeNode)

        // Свечение вокруг портала
        let glowSize = CGSize(width: 60, height: 76)
        glowNode = SKShapeNode(ellipseOf: glowSize)
        glowNode.fillColor = portalGlowColor.withAlphaComponent(0.3)
        glowNode.strokeColor = .clear
        glowNode.zPosition = -1
        glowNode.blendMode = .add
        addChild(glowNode)

        // Анимация пульсации
        startPulseAnimation()

        // Частицы
        if let particles = createPortalParticles() {
            particles.position = .zero
            particles.zPosition = 1
            addChild(particles)
            particleEmitter = particles
        }
    }

    private func setupDoorVisuals() {
        // Дверная рама
        let frameSize = CGSize(width: 44, height: 60)
        let frame = SKSpriteNode(color: UIColor(red: 0.2, green: 0.15, blue: 0.1, alpha: 1.0), size: frameSize)
        frame.zPosition = -1
        addChild(frame)

        // Сама дверь
        let doorSize = CGSize(width: 36, height: 52)
        portalSprite = SKSpriteNode(color: doorColor, size: doorSize)
        portalSprite.zPosition = 0
        addChild(portalSprite)

        // Ручка двери
        let handle = SKShapeNode(circleOfRadius: 3)
        handle.fillColor = UIColor(red: 0.7, green: 0.6, blue: 0.2, alpha: 1.0)
        handle.strokeColor = .clear
        handle.position = CGPoint(x: 12, y: 0)
        handle.zPosition = 1
        addChild(handle)

        // Небольшое свечение над дверью
        glowNode = SKShapeNode(rectOf: CGSize(width: 30, height: 4), cornerRadius: 2)
        glowNode.fillColor = UIColor(red: 1.0, green: 0.9, blue: 0.5, alpha: 0.8)
        glowNode.strokeColor = .clear
        glowNode.position = CGPoint(x: 0, y: 34)
        glowNode.zPosition = 2
        glowNode.blendMode = .add
        addChild(glowNode)
    }

    private func setupPathVisuals() {
        // Светящаяся тропа/стрелка
        let pathSize = CGSize(width: 32, height: 48)
        portalSprite = SKSpriteNode(color: pathColor, size: pathSize)
        portalSprite.alpha = 0.7
        portalSprite.zPosition = 0
        addChild(portalSprite)

        // Мягкое свечение
        glowNode = SKShapeNode(rectOf: CGSize(width: 40, height: 56), cornerRadius: 8)
        glowNode.fillColor = pathColor.withAlphaComponent(0.3)
        glowNode.strokeColor = .clear
        glowNode.zPosition = -1
        glowNode.blendMode = .add
        addChild(glowNode)

        // Анимация затухания
        let fade = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.4, duration: 1.0),
            SKAction.fadeAlpha(to: 0.7, duration: 1.0)
        ])
        portalSprite.run(SKAction.repeatForever(fade))
    }

    private func setupArrowIndicator() {
        // Простая стрелка вверх
        let arrowSize = CGSize(width: 16, height: 12)
        arrowIndicator = SKSpriteNode(color: .white, size: arrowSize)
        arrowIndicator?.position = CGPoint(x: 0, y: size.height / 2 + 20)
        arrowIndicator?.alpha = 0.8
        arrowIndicator?.zPosition = 10

        if let arrow = arrowIndicator {
            addChild(arrow)

            // Анимация подъёма-опускания
            let bob = SKAction.sequence([
                SKAction.moveBy(x: 0, y: 8, duration: 0.6),
                SKAction.moveBy(x: 0, y: -8, duration: 0.6)
            ])
            bob.timingMode = .easeInEaseOut
            arrow.run(SKAction.repeatForever(bob))
        }
    }

    private func setupPhysics() {
        // Триггерная зона для входа
        let triggerSize = CGSize(width: 40, height: 56)
        physicsBody = SKPhysicsBody(rectangleOf: triggerSize)
        physicsBody?.isDynamic = false
        physicsBody?.categoryBitMask = PhysicsCategory.trigger
        physicsBody?.contactTestBitMask = PhysicsCategory.player
        physicsBody?.collisionBitMask = 0
    }

    // MARK: - Animations

    private func startPulseAnimation() {
        guard transitionType == .portal else { return }

        // Пульсация свечения
        let pulseGrow = SKAction.scale(to: 1.15, duration: 1.2)
        let pulseShrink = SKAction.scale(to: 0.95, duration: 1.2)
        pulseGrow.timingMode = .easeInEaseOut
        pulseShrink.timingMode = .easeInEaseOut
        let pulse = SKAction.repeatForever(SKAction.sequence([pulseGrow, pulseShrink]))
        glowNode?.run(pulse, withKey: "pulse")
    }

    private func createPortalParticles() -> SKEmitterNode? {
        let emitter = SKEmitterNode()

        // Текстура частицы
        let particleTexture = createParticleTexture()
        emitter.particleTexture = particleTexture

        // Настройки эмиттера
        emitter.particleBirthRate = 15
        emitter.numParticlesToEmit = 0 // Бесконечно
        emitter.particleLifetime = 2.0
        emitter.particleLifetimeRange = 0.5

        // Размер частиц
        emitter.particleSize = CGSize(width: 6, height: 6)
        emitter.particleScaleRange = 0.5
        emitter.particleScaleSpeed = -0.2

        // Движение - вращение вокруг портала
        emitter.emissionAngle = 0
        emitter.emissionAngleRange = .pi * 2
        emitter.particleSpeed = 20
        emitter.particleSpeedRange = 10

        // Позиция спавна - по краю овала
        emitter.particlePositionRange = CGVector(dx: 25, dy: 35)

        // Цвет и прозрачность
        emitter.particleColor = portalGlowColor
        emitter.particleColorBlendFactor = 1.0
        emitter.particleAlpha = 0.7
        emitter.particleAlphaSpeed = -0.3

        // Блендинг
        emitter.particleBlendMode = .add

        return emitter
    }

    private func createParticleTexture() -> SKTexture {
        let size = CGSize(width: 8, height: 8)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
            let cgContext = context.cgContext
            cgContext.setFillColor(UIColor.white.cgColor)
            cgContext.fillEllipse(in: CGRect(origin: .zero, size: size))
        }
        return SKTexture(image: image)
    }

    // MARK: - Activation

    /// Установить активность выхода
    /// - Parameter active: Активен ли выход
    func setActive(_ active: Bool) {
        isActive = active

        if active {
            // Восстанавливаем нормальный вид
            alpha = 1.0
            portalSprite?.color = transitionType == .portal ? portalColor : (transitionType == .door ? doorColor : pathColor)
            particleEmitter?.particleBirthRate = 15
            arrowIndicator?.isHidden = false
        } else {
            // Делаем неактивным
            alpha = 0.6
            portalSprite?.color = inactiveColor
            particleEmitter?.particleBirthRate = 0
            arrowIndicator?.isHidden = true
        }
    }

    /// Попытка входа игрока в выход
    /// - Parameter player: Игрок
    func enter(player: Player) {
        // Проверки
        guard isActive else {
            showMessage("ВЫХОД НЕАКТИВЕН")
            return
        }

        guard !isEntering else { return }

        if requiresKey {
            // TODO: Проверить наличие ключа у игрока
            // if !player.hasKey(keyId) {
            //     showMessage("ТРЕБУЕТСЯ КЛЮЧ")
            //     return
            // }
        }

        isEntering = true

        // Запускаем анимацию входа
        playEnterAnimation(player: player) { [weak self] in
            self?.triggerLevelTransition()
        }
    }

    /// Анимация входа игрока в портал
    private func playEnterAnimation(player: Player, completion: @escaping () -> Void) {
        // Остановить движение игрока
        player.physicsBody?.velocity = .zero
        player.physicsBody?.isDynamic = false

        // Плавное перемещение игрока к центру портала
        let moveToCenter = SKAction.move(to: convert(.zero, to: player.parent!), duration: 0.3)
        moveToCenter.timingMode = .easeInEaseOut

        // Уменьшение и затухание игрока
        let scaleDown = SKAction.scale(to: 0.1, duration: 0.5)
        let fadeOut = SKAction.fadeOut(withDuration: 0.5)
        let disappear = SKAction.group([scaleDown, fadeOut])

        // Эффект вспышки портала
        let flashNode = SKShapeNode(ellipseOf: CGSize(width: 80, height: 100))
        flashNode.fillColor = portalGlowColor
        flashNode.strokeColor = .clear
        flashNode.blendMode = .add
        flashNode.zPosition = 50
        flashNode.alpha = 0
        addChild(flashNode)

        let flashIn = SKAction.fadeAlpha(to: 0.8, duration: 0.2)
        let flashOut = SKAction.sequence([
            SKAction.wait(forDuration: 0.4),
            SKAction.fadeOut(withDuration: 0.3),
            SKAction.removeFromParent()
        ])
        flashNode.run(SKAction.sequence([flashIn, flashOut]))

        // Звуковой эффект (TODO: добавить звук)
        // AudioManager.shared.playSound("portal_enter")

        // Последовательность анимаций игрока
        player.run(SKAction.sequence([
            moveToCenter,
            disappear,
            SKAction.run {
                completion()
            }
        ]))
    }

    /// Запуск перехода на следующий уровень
    private func triggerLevelTransition() {
        // Очищаем чекпоинт при переходе на новый уровень
        GameManager.shared.clearCheckpoint()

        // Уведомление о завершении уровня
        NotificationCenter.default.post(
            name: .levelExitTriggered,
            object: self,
            userInfo: ["nextLevelId": nextLevelId]
        )

        // Переход через SceneManager
        SceneManager.shared.loadLevel(nextLevelId)
    }

    /// Показать сообщение над порталом
    private func showMessage(_ text: String) {
        let label = SKLabelNode(text: text)
        label.fontName = "AvenirNext-Bold"
        label.fontSize = 14
        label.fontColor = .white
        label.position = CGPoint(x: 0, y: size.height / 2 + 40)
        label.zPosition = 100
        label.alpha = 0
        addChild(label)

        let appear = SKAction.fadeIn(withDuration: 0.2)
        let wait = SKAction.wait(forDuration: 1.0)
        let disappear = SKAction.fadeOut(withDuration: 0.3)
        let remove = SKAction.removeFromParent()

        label.run(SKAction.sequence([appear, wait, disappear, remove]))
    }
}

// MARK: - Notification.Name

extension Notification.Name {
    static let levelExitTriggered = Notification.Name("levelExitTriggered")
}
