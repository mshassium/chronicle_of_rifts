import SpriteKit

/// Снаряд летающего глаза
/// Фиолетовый магический шар, летящий по прямой
final class EyeProjectile: SKSpriteNode {

    // MARK: - Properties

    /// Урон снаряда
    let damage: Int = 1

    /// Скорость полёта (пикселей/сек)
    private let flySpeed: CGFloat = 150

    /// Время жизни снаряда (сек)
    private let lifeTime: TimeInterval = 3.0

    /// Направление полёта (нормализованный вектор)
    private var direction: CGVector = .zero

    /// Таймер времени жизни
    private var lifeTimer: TimeInterval = 0

    /// Trail эффект
    private var trailEmitter: SKEmitterNode?

    // MARK: - Init

    /// Создать снаряд в указанном направлении
    /// - Parameters:
    ///   - direction: Направление полёта (будет нормализовано)
    init(direction: CGVector) {
        // Нормализуем направление
        let length = hypot(direction.dx, direction.dy)
        if length > 0 {
            self.direction = CGVector(dx: direction.dx / length, dy: direction.dy / length)
        }

        // Размер снаряда 8x8 пикселей
        let size = CGSize(width: 8, height: 8)

        // Фиолетовый цвет
        let color = SKColor(red: 0.6, green: 0.2, blue: 0.8, alpha: 1.0)

        super.init(texture: nil, color: color, size: size)

        self.name = "eyeProjectile"
        self.zPosition = 15

        setupPhysicsBody()
        setupVisual()
        setupTrailEffect()
        scheduleDestruction()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) не реализован")
    }

    deinit {
        trailEmitter?.removeFromParent()
    }

    // MARK: - Setup

    /// Настройка физического тела
    private func setupPhysicsBody() {
        let physicsBody = SKPhysicsBody(circleOfRadius: 4)

        physicsBody.isDynamic = true
        physicsBody.allowsRotation = false
        physicsBody.affectedByGravity = false
        physicsBody.friction = 0
        physicsBody.restitution = 0
        physicsBody.linearDamping = 0

        physicsBody.categoryBitMask = PhysicsCategory.enemyProjectile
        physicsBody.collisionBitMask = 0 // Не сталкивается ни с чем
        physicsBody.contactTestBitMask = PhysicsCategory.player |
                                          PhysicsCategory.ground |
                                          PhysicsCategory.playerAttack

        self.physicsBody = physicsBody
    }

    /// Настройка визуального отображения
    private func setupVisual() {
        // Внутреннее свечение (более яркий центр)
        let glowNode = SKSpriteNode(color: .white, size: CGSize(width: 4, height: 4))
        glowNode.alpha = 0.8
        glowNode.zPosition = 1
        addChild(glowNode)

        // Пульсация
        let pulse = SKAction.sequence([
            SKAction.scale(to: 1.2, duration: 0.15),
            SKAction.scale(to: 0.9, duration: 0.15)
        ])
        glowNode.run(SKAction.repeatForever(pulse))
    }

    /// Настройка trail эффекта
    private func setupTrailEffect() {
        // Создаём простой trail эффект из нод
        let trailAction = SKAction.repeatForever(SKAction.sequence([
            SKAction.run { [weak self] in
                self?.spawnTrailParticle()
            },
            SKAction.wait(forDuration: 0.05)
        ]))
        run(trailAction, withKey: "trail")
    }

    /// Создаёт частицу trail
    private func spawnTrailParticle() {
        guard let parent = self.parent else { return }

        let particle = SKSpriteNode(color: SKColor(red: 0.6, green: 0.2, blue: 0.8, alpha: 0.6),
                                    size: CGSize(width: 4, height: 4))
        particle.position = self.position
        particle.zPosition = self.zPosition - 1
        parent.addChild(particle)

        let fadeAndRemove = SKAction.sequence([
            SKAction.group([
                SKAction.fadeOut(withDuration: 0.2),
                SKAction.scale(to: 0.3, duration: 0.2)
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

    /// Обновление снаряда (вызывается каждый кадр)
    /// - Parameter deltaTime: Время с предыдущего кадра
    func update(deltaTime: TimeInterval) {
        // Применяем скорость
        let velocity = CGVector(
            dx: direction.dx * flySpeed,
            dy: direction.dy * flySpeed
        )
        physicsBody?.velocity = velocity
    }

    // MARK: - Collision

    /// Обработка столкновения
    /// - Parameter body: Физическое тело, с которым произошло столкновение
    func handleContact(with body: SKPhysicsBody) {
        // Проверяем, с чем столкнулись
        if body.categoryBitMask & PhysicsCategory.player != 0 {
            // Попадание в игрока - наносим урон
            if let player = body.node as? Player {
                let knockbackDirection: CGFloat = direction.dx > 0 ? 1 : -1
                player.takeDamage(damage, knockbackDirection: knockbackDirection, knockbackForce: 150)
            }
            destroy()
        } else if body.categoryBitMask & PhysicsCategory.playerAttack != 0 {
            // Уничтожен атакой игрока
            destroyByAttack()
        } else if body.categoryBitMask & PhysicsCategory.ground != 0 {
            // Столкновение с землёй
            destroy()
        }
    }

    // MARK: - Destruction

    /// Уничтожение снаряда
    func destroy() {
        removeAction(forKey: "trail")
        removeAction(forKey: "lifeTimer")

        // Простой эффект исчезновения
        let fadeOut = SKAction.sequence([
            SKAction.fadeOut(withDuration: 0.1),
            SKAction.removeFromParent()
        ])
        run(fadeOut)
    }

    /// Уничтожение атакой игрока (с эффектом)
    func destroyByAttack() {
        removeAction(forKey: "trail")
        removeAction(forKey: "lifeTimer")

        // Эффект разрушения
        if let parent = self.parent {
            for _ in 0..<5 {
                let particle = SKSpriteNode(color: SKColor(red: 0.6, green: 0.2, blue: 0.8, alpha: 1.0),
                                            size: CGSize(width: 3, height: 3))
                particle.position = self.position
                particle.zPosition = self.zPosition
                parent.addChild(particle)

                let randomAngle = CGFloat.random(in: 0...(2 * .pi))
                let randomSpeed = CGFloat.random(in: 50...100)
                let moveAction = SKAction.move(
                    by: CGVector(dx: cos(randomAngle) * randomSpeed * 0.3,
                                dy: sin(randomAngle) * randomSpeed * 0.3),
                    duration: 0.3
                )

                particle.run(SKAction.sequence([
                    SKAction.group([
                        moveAction,
                        SKAction.fadeOut(withDuration: 0.3)
                    ]),
                    SKAction.removeFromParent()
                ]))
            }
        }

        removeFromParent()
    }
}
