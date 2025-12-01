import SpriteKit

/// Базовый класс для всех коллекционных предметов
class Collectible: SKSpriteNode {

    // MARK: - Properties

    /// Тип предмета
    let type: CollectibleType

    /// Уникальный идентификатор (для страниц хроник и чекпоинтов)
    let id: String?

    /// Был ли предмет собран
    private(set) var isCollected: Bool = false

    // MARK: - Visual

    /// Эффект парения
    private var floatAction: SKAction?

    /// Эффект свечения
    private var glowNode: SKShapeNode?

    // MARK: - Init

    init(type: CollectibleType, id: String? = nil) {
        self.type = type
        self.id = id

        let size = Self.sizeFor(type)
        let color = Self.colorFor(type)

        super.init(texture: nil, color: color, size: size)

        self.name = "collectible_\(type.rawValue)"

        setupPhysics()
        setupVisuals()
        startAnimations()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Configuration

    private static func sizeFor(_ type: CollectibleType) -> CGSize {
        switch type {
        case .manaCrystal: return CGSize(width: 16, height: 24)
        case .healthPickup: return CGSize(width: 24, height: 24)
        case .chroniclePage: return CGSize(width: 20, height: 28)
        case .checkpoint: return CGSize(width: 32, height: 48)
        }
    }

    private static func colorFor(_ type: CollectibleType) -> UIColor {
        switch type {
        case .manaCrystal: return UIColor(red: 0.5, green: 0.8, blue: 1.0, alpha: 1.0)  // Голубой
        case .healthPickup: return UIColor(red: 1.0, green: 0.3, blue: 0.3, alpha: 1.0)  // Красный
        case .chroniclePage: return UIColor(red: 1.0, green: 0.9, blue: 0.6, alpha: 1.0)  // Пергамент
        case .checkpoint: return UIColor(red: 0.8, green: 0.6, blue: 1.0, alpha: 1.0)  // Фиолетовый
        }
    }

    // MARK: - Setup

    private func setupPhysics() {
        // Checkpoint имеет большой триггер
        let triggerSize = type == .checkpoint
            ? CGSize(width: 48, height: 64)
            : CGSize(width: size.width + 8, height: size.height + 8)

        physicsBody = SKPhysicsBody(rectangleOf: triggerSize)
        physicsBody?.isDynamic = false
        physicsBody?.categoryBitMask = PhysicsCategory.collectible
        physicsBody?.contactTestBitMask = PhysicsCategory.player
        physicsBody?.collisionBitMask = 0
    }

    private func setupVisuals() {
        // Эффект свечения
        let glowSize = CGSize(width: size.width * 1.5, height: size.height * 1.5)
        glowNode = SKShapeNode(ellipseOf: glowSize)
        glowNode?.fillColor = Self.colorFor(type).withAlphaComponent(0.3)
        glowNode?.strokeColor = .clear
        glowNode?.zPosition = -1
        glowNode?.blendMode = .add
        addChild(glowNode!)

        // Особый визуал для checkpoint
        if type == .checkpoint {
            setupCheckpointVisual()
        }
    }

    private func setupCheckpointVisual() {
        // Столб чекпоинта
        let pillar = SKSpriteNode(color: UIColor.darkGray, size: CGSize(width: 8, height: 48))
        pillar.position = .zero
        pillar.zPosition = -1
        addChild(pillar)

        // Кристалл наверху
        let crystal = SKSpriteNode(color: color, size: CGSize(width: 16, height: 16))
        crystal.position = CGPoint(x: 0, y: 20)
        addChild(crystal)

        // Скрываем основной спрайт
        self.color = .clear
    }

    // MARK: - Animations

    private func startAnimations() {
        // Парение вверх-вниз
        if type != .checkpoint {
            let floatUp = SKAction.moveBy(x: 0, y: 4, duration: 0.5)
            floatUp.timingMode = .easeInEaseOut
            let floatDown = floatUp.reversed()
            floatAction = SKAction.repeatForever(SKAction.sequence([floatUp, floatDown]))
            run(floatAction!, withKey: "float")
        }

        // Пульсация свечения
        let pulseGrow = SKAction.scale(to: 1.2, duration: 0.8)
        let pulseShrink = SKAction.scale(to: 0.9, duration: 0.8)
        let pulse = SKAction.repeatForever(SKAction.sequence([pulseGrow, pulseShrink]))
        glowNode?.run(pulse)
    }

    // MARK: - Collection

    /// Собрать предмет
    /// - Parameter collector: Узел, который собирает предмет (обычно Player)
    func collect(by collector: SKNode) {
        guard !isCollected else { return }
        isCollected = true

        // Остановить анимации
        removeAction(forKey: "float")

        // Эффект сбора
        playCollectEffect()

        // Уведомление
        NotificationCenter.default.post(
            name: .collectibleCollected,
            object: self,
            userInfo: ["collector": collector, "type": type, "id": id as Any]
        )
    }

    private func playCollectEffect() {
        // Анимация сбора
        let collectAction = SKAction.sequence([
            SKAction.group([
                SKAction.scale(to: 1.5, duration: 0.15),
                SKAction.fadeOut(withDuration: 0.15),
                SKAction.move(by: CGVector(dx: 0, dy: 20), duration: 0.15)
            ]),
            SKAction.removeFromParent()
        ])

        run(collectAction)

        // Частицы
        spawnCollectParticles()
    }

    private func spawnCollectParticles() {
        guard let parent = parent else { return }

        // Создаём несколько частиц
        for _ in 0..<8 {
            let particle = SKSpriteNode(color: Self.colorFor(type), size: CGSize(width: 4, height: 4))
            particle.position = position
            particle.zPosition = 100

            let angle = CGFloat.random(in: 0...CGFloat.pi * 2)
            let distance: CGFloat = CGFloat.random(in: 30...60)
            let targetPos = CGPoint(
                x: position.x + cos(angle) * distance,
                y: position.y + sin(angle) * distance
            )

            let particleAction = SKAction.sequence([
                SKAction.group([
                    SKAction.move(to: targetPos, duration: 0.3),
                    SKAction.fadeOut(withDuration: 0.3),
                    SKAction.scale(to: 0.1, duration: 0.3)
                ]),
                SKAction.removeFromParent()
            ])

            parent.addChild(particle)
            particle.run(particleAction)
        }
    }

    // MARK: - Checkpoint specific

    /// Активировать чекпоинт (визуальное изменение)
    func activateCheckpoint() {
        guard type == .checkpoint else { return }

        // Меняем цвет на активный
        glowNode?.fillColor = UIColor.green.withAlphaComponent(0.5)

        // Эффект активации
        let pulse = SKAction.sequence([
            SKAction.scale(to: 2.0, duration: 0.2),
            SKAction.scale(to: 1.0, duration: 0.2)
        ])
        glowNode?.run(pulse)
    }
}

// MARK: - Notification

extension Notification.Name {
    static let collectibleCollected = Notification.Name("collectibleCollected")
}
