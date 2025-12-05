import SpriteKit

/// Чекпоинт - точка сохранения прогресса на уровне
class Checkpoint: SKSpriteNode {

    // MARK: - Properties

    /// Уникальный идентификатор чекпоинта
    let checkpointId: String

    /// Активирован ли чекпоинт
    private(set) var isActivated: Bool = false

    /// Смещение позиции респавна (игрок появляется чуть выше чекпоинта)
    let respawnOffset: CGPoint = CGPoint(x: 0, y: 32)

    // MARK: - Visual Components

    /// Столб чекпоинта
    private var pillar: SKSpriteNode!

    /// Кристалл на вершине
    private var crystal: SKSpriteNode!

    /// Эффект свечения
    private var glowNode: SKShapeNode!

    /// Частицы активного чекпоинта
    private var activeParticles: SKEmitterNode?

    // MARK: - Colors

    private let inactiveColor = UIColor(red: 0.4, green: 0.4, blue: 0.5, alpha: 1.0)
    private let activeColor = UIColor(red: 0.3, green: 0.9, blue: 0.4, alpha: 1.0)
    private let pillarColor = UIColor(red: 0.25, green: 0.25, blue: 0.3, alpha: 1.0)

    // MARK: - Initialization

    init(id: String) {
        self.checkpointId = id

        let size = CGSize(width: 32, height: 48)
        super.init(texture: nil, color: .clear, size: size)

        self.name = "checkpoint_\(id)"

        setupVisuals()
        setupPhysics()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupVisuals() {
        // Столб чекпоинта
        pillar = SKSpriteNode(color: pillarColor, size: CGSize(width: 8, height: 40))
        pillar.position = CGPoint(x: 0, y: -4)
        pillar.zPosition = 0
        addChild(pillar)

        // Кристалл на вершине
        crystal = SKSpriteNode(color: inactiveColor, size: CGSize(width: 16, height: 16))
        crystal.position = CGPoint(x: 0, y: 20)
        crystal.zRotation = .pi / 4 // Повёрнут на 45 градусов
        crystal.zPosition = 1
        addChild(crystal)

        // Эффект свечения
        let glowSize = CGSize(width: 24, height: 24)
        glowNode = SKShapeNode(ellipseOf: glowSize)
        glowNode.fillColor = inactiveColor.withAlphaComponent(0.3)
        glowNode.strokeColor = .clear
        glowNode.position = CGPoint(x: 0, y: 20)
        glowNode.zPosition = -1
        glowNode.blendMode = .add
        addChild(glowNode)

        // Анимация пульсации неактивного чекпоинта
        startIdleAnimation()
    }

    private func setupPhysics() {
        // Триггерная зона для активации
        let triggerSize = CGSize(width: 48, height: 64)
        physicsBody = SKPhysicsBody(rectangleOf: triggerSize)
        physicsBody?.isDynamic = false
        physicsBody?.categoryBitMask = PhysicsCategory.collectible
        physicsBody?.contactTestBitMask = PhysicsCategory.player
        physicsBody?.collisionBitMask = 0
    }

    // MARK: - Animations

    private func startIdleAnimation() {
        // Медленная пульсация свечения
        let pulseGrow = SKAction.scale(to: 1.1, duration: 1.0)
        let pulseShrink = SKAction.scale(to: 0.9, duration: 1.0)
        pulseGrow.timingMode = .easeInEaseOut
        pulseShrink.timingMode = .easeInEaseOut
        let pulse = SKAction.repeatForever(SKAction.sequence([pulseGrow, pulseShrink]))
        glowNode.run(pulse, withKey: "pulse")
    }

    // MARK: - Activation

    /// Активировать чекпоинт
    /// - Parameter player: Игрок, активировавший чекпоинт
    func activate(by player: Player) {
        // Проверяем, что чекпоинт ещё не активирован
        guard !isActivated else { return }
        isActivated = true

        // Меняем визуал на активный
        crystal.color = activeColor
        glowNode.fillColor = activeColor.withAlphaComponent(0.5)

        // Проигрываем анимацию активации
        playActivationAnimation()

        // Добавляем частицы
        if let particles = createActiveParticles() {
            particles.position = CGPoint(x: 0, y: 20)
            particles.zPosition = 2
            addChild(particles)
            activeParticles = particles
        }

        // Сохраняем чекпоинт в GameManager
        saveCheckpoint()

        // Отправляем уведомление
        NotificationCenter.default.post(
            name: .checkpointActivated,
            object: self,
            userInfo: ["checkpointId": checkpointId, "position": position]
        )
    }

    private func playActivationAnimation() {
        // Яркая вспышка
        let flash = SKSpriteNode(color: activeColor, size: CGSize(width: 64, height: 64))
        flash.position = CGPoint(x: 0, y: 20)
        flash.zPosition = 10
        flash.blendMode = .add
        addChild(flash)

        let flashAction = SKAction.sequence([
            SKAction.group([
                SKAction.scale(to: 2.0, duration: 0.3),
                SKAction.fadeOut(withDuration: 0.3)
            ]),
            SKAction.removeFromParent()
        ])
        flash.run(flashAction)

        // Кристалл "прыгает" и увеличивается
        let crystalAction = SKAction.sequence([
            SKAction.group([
                SKAction.moveBy(x: 0, y: 10, duration: 0.15),
                SKAction.scale(to: 1.3, duration: 0.15)
            ]),
            SKAction.group([
                SKAction.moveBy(x: 0, y: -10, duration: 0.15),
                SKAction.scale(to: 1.0, duration: 0.15)
            ])
        ])
        crystal.run(crystalAction)

        // Свечение становится ярче
        glowNode.removeAction(forKey: "pulse")
        let newPulse = SKAction.repeatForever(SKAction.sequence([
            SKAction.scale(to: 1.3, duration: 0.8),
            SKAction.scale(to: 1.0, duration: 0.8)
        ]))
        glowNode.run(newPulse, withKey: "pulse")
    }

    private func createActiveParticles() -> SKEmitterNode? {
        // Создаём программные частицы
        let emitter = SKEmitterNode()

        // Форма частицы - квадрат
        let particleTexture = createParticleTexture()
        emitter.particleTexture = particleTexture

        // Настройки эмиттера
        emitter.particleBirthRate = 8
        emitter.numParticlesToEmit = 0 // Бесконечно
        emitter.particleLifetime = 1.5
        emitter.particleLifetimeRange = 0.5

        // Размер частиц
        emitter.particleSize = CGSize(width: 4, height: 4)
        emitter.particleScaleRange = 0.5
        emitter.particleScaleSpeed = -0.3

        // Движение
        emitter.emissionAngle = .pi / 2 // Вверх
        emitter.emissionAngleRange = .pi / 4
        emitter.particleSpeed = 30
        emitter.particleSpeedRange = 10

        // Позиция спавна
        emitter.particlePositionRange = CGVector(dx: 10, dy: 5)

        // Цвет и прозрачность
        emitter.particleColor = activeColor
        emitter.particleColorBlendFactor = 1.0
        emitter.particleAlpha = 0.8
        emitter.particleAlphaSpeed = -0.5

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

    private func saveCheckpoint() {
        // Получаем позицию респавна (с учётом offset)
        let respawnPosition = CGPoint(
            x: position.x + respawnOffset.x,
            y: position.y + respawnOffset.y
        )

        // Сохраняем в GameManager
        GameManager.shared.setCheckpoint(
            position: respawnPosition,
            levelId: GameManager.shared.currentLevel
        )
    }

    /// Получить позицию респавна
    func getRespawnPosition() -> CGPoint {
        return CGPoint(
            x: position.x + respawnOffset.x,
            y: position.y + respawnOffset.y
        )
    }
}

// MARK: - Notification.Name

extension Notification.Name {
    static let checkpointActivated = Notification.Name("checkpointActivated")
}
