import SpriteKit

/// Волна по земле — создаётся боссом Defiler при атаке JumpSlam
/// Движется горизонтально, нужно перепрыгнуть
final class GroundWave: SKSpriteNode {

    // MARK: - Properties

    /// Урон волны
    let damage: Int

    /// Скорость движения (пикселей/сек)
    private let moveSpeed: CGFloat = 200

    /// Время жизни волны (сек)
    private let lifeTime: TimeInterval = 2.0

    /// Направление движения (1 = вправо, -1 = влево)
    private let direction: CGFloat

    /// Высота волны (нужно перепрыгнуть)
    private static let waveHeight: CGFloat = 24

    /// Ширина волны
    private static let waveWidth: CGFloat = 32

    // MARK: - Init

    /// Создать волну
    /// - Parameters:
    ///   - direction: Направление движения (1 = вправо, -1 = влево)
    ///   - damage: Урон при контакте
    init(direction: CGFloat, damage: Int = 1) {
        self.direction = direction > 0 ? 1 : -1
        self.damage = damage

        // Размер волны
        let size = CGSize(width: GroundWave.waveWidth, height: GroundWave.waveHeight)

        // Фиолетовый цвет (скверна)
        let color = SKColor(red: 0.5, green: 0.2, blue: 0.6, alpha: 1.0)

        super.init(texture: nil, color: color, size: size)

        self.name = "groundWave"
        self.zPosition = 5

        // Anchor point внизу для правильного позиционирования на земле
        self.anchorPoint = CGPoint(x: 0.5, y: 0)

        setupPhysicsBody()
        setupVisual()
        scheduleDestruction()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) не реализован")
    }

    // MARK: - Setup

    /// Настройка физического тела
    private func setupPhysicsBody() {
        // Физическое тело немного меньше спрайта
        let bodySize = CGSize(width: size.width * 0.8, height: size.height * 0.8)
        let physicsBody = SKPhysicsBody(rectangleOf: bodySize, center: CGPoint(x: 0, y: bodySize.height / 2))

        physicsBody.isDynamic = true
        physicsBody.allowsRotation = false
        physicsBody.affectedByGravity = false
        physicsBody.friction = 0
        physicsBody.restitution = 0
        physicsBody.linearDamping = 0

        physicsBody.categoryBitMask = PhysicsCategory.enemyProjectile
        physicsBody.collisionBitMask = 0 // Проходит сквозь всё
        physicsBody.contactTestBitMask = PhysicsCategory.player | PhysicsCategory.ground

        self.physicsBody = physicsBody
    }

    /// Настройка визуального отображения
    private func setupVisual() {
        // Волнообразная форма из нескольких слоёв
        let innerWave = SKSpriteNode(color: SKColor(red: 0.7, green: 0.3, blue: 0.8, alpha: 0.8),
                                      size: CGSize(width: size.width * 0.6, height: size.height * 0.7))
        innerWave.position = CGPoint(x: 0, y: size.height * 0.35)
        innerWave.zPosition = 1
        addChild(innerWave)

        // Внутреннее яркое ядро
        let core = SKSpriteNode(color: SKColor(red: 0.9, green: 0.5, blue: 1.0, alpha: 0.9),
                                size: CGSize(width: size.width * 0.3, height: size.height * 0.4))
        core.position = CGPoint(x: 0, y: size.height * 0.3)
        core.zPosition = 2
        addChild(core)

        // Пульсация
        let pulse = SKAction.sequence([
            SKAction.scaleY(to: 1.1, duration: 0.1),
            SKAction.scaleY(to: 0.9, duration: 0.1)
        ])
        run(SKAction.repeatForever(pulse))

        // Частицы позади волны
        spawnTrailParticles()
    }

    /// Создание частиц следа
    private func spawnTrailParticles() {
        let trailAction = SKAction.repeatForever(SKAction.sequence([
            SKAction.run { [weak self] in
                self?.createTrailParticle()
            },
            SKAction.wait(forDuration: 0.05)
        ]))
        run(trailAction, withKey: "trail")
    }

    /// Создание одной частицы следа
    private func createTrailParticle() {
        guard let parent = self.parent else { return }

        let particle = SKSpriteNode(color: SKColor(red: 0.5, green: 0.2, blue: 0.6, alpha: 0.5),
                                    size: CGSize(width: 6, height: 6))
        // Позиция позади волны
        particle.position = CGPoint(
            x: self.position.x - direction * size.width * 0.3,
            y: self.position.y + CGFloat.random(in: 5...15)
        )
        particle.zPosition = self.zPosition - 1
        parent.addChild(particle)

        let fadeAndRemove = SKAction.sequence([
            SKAction.group([
                SKAction.fadeOut(withDuration: 0.2),
                SKAction.scale(to: 0.3, duration: 0.2),
                SKAction.moveBy(x: 0, y: 10, duration: 0.2)
            ]),
            SKAction.removeFromParent()
        ])
        particle.run(fadeAndRemove)
    }

    /// Запланировать уничтожение по истечении времени жизни
    private func scheduleDestruction() {
        let destroyAction = SKAction.sequence([
            SKAction.wait(forDuration: lifeTime),
            SKAction.run { [weak self] in
                self?.destroy()
            }
        ])
        run(destroyAction, withKey: "lifeTimer")
    }

    // MARK: - Update

    /// Обновление волны (вызывается каждый кадр)
    /// - Parameter deltaTime: Время с предыдущего кадра
    func update(deltaTime: TimeInterval) {
        // Применяем горизонтальную скорость
        let velocity = CGVector(dx: direction * moveSpeed, dy: 0)
        physicsBody?.velocity = velocity
    }

    // MARK: - Collision

    /// Обработка столкновения с игроком
    /// - Parameter player: Игрок
    func hitPlayer(_ player: Player) {
        let knockbackDirection: CGFloat = direction
        player.takeDamage(damage, knockbackDirection: knockbackDirection, knockbackForce: 250)
        // Волна продолжает движение после попадания
    }

    /// Обработка столкновения со стеной
    func hitWall() {
        destroy()
    }

    // MARK: - Destruction

    /// Уничтожение волны
    func destroy() {
        removeAction(forKey: "trail")
        removeAction(forKey: "lifeTimer")

        // Эффект рассеивания
        let fadeOut = SKAction.sequence([
            SKAction.group([
                SKAction.fadeOut(withDuration: 0.15),
                SKAction.scaleY(to: 0.2, duration: 0.15)
            ]),
            SKAction.removeFromParent()
        ])
        run(fadeOut)
    }
}
