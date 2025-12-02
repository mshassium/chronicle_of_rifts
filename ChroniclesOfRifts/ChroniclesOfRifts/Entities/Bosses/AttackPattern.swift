import SpriteKit

// MARK: - AttackPattern Protocol

/// Протокол для описания паттерна атаки босса
protocol AttackPattern: AnyObject {
    /// Название паттерна атаки
    var name: String { get }

    /// Длительность выполнения атаки
    var duration: TimeInterval { get }

    /// Время перезарядки после атаки
    var cooldown: TimeInterval { get }

    /// Время с момента последнего выполнения
    var lastExecutionTime: TimeInterval { get set }

    /// Выполнить атаку по цели
    /// - Parameters:
    ///   - target: Игрок-цель
    ///   - boss: Босс, выполняющий атаку
    ///   - completion: Колбэк завершения атаки
    func execute(target: Player, boss: Boss, completion: @escaping () -> Void)

    /// Проверка возможности выполнения атаки
    /// - Parameter currentTime: Текущее время
    /// - Returns: true если атака может быть выполнена
    func canExecute(currentTime: TimeInterval) -> Bool
}

// MARK: - Default Implementation

extension AttackPattern {
    func canExecute(currentTime: TimeInterval) -> Bool {
        return currentTime - lastExecutionTime >= cooldown
    }
}

// MARK: - BaseAttackPattern

/// Базовый класс для паттернов атак
class BaseAttackPattern: AttackPattern {
    let name: String
    let duration: TimeInterval
    let cooldown: TimeInterval
    var lastExecutionTime: TimeInterval = 0

    init(name: String, duration: TimeInterval, cooldown: TimeInterval) {
        self.name = name
        self.duration = duration
        self.cooldown = cooldown
    }

    func execute(target: Player, boss: Boss, completion: @escaping () -> Void) {
        // Базовая реализация - переопределяется в подклассах
        lastExecutionTime = CACurrentMediaTime()

        boss.run(SKAction.sequence([
            SKAction.wait(forDuration: duration),
            SKAction.run { completion() }
        ]))
    }
}

// MARK: - MeleeAttackPattern

/// Паттерн ближней атаки
class MeleeAttackPattern: BaseAttackPattern {
    let damage: Int
    let range: CGFloat
    let knockbackForce: CGFloat

    init(name: String = "Ближняя атака",
         duration: TimeInterval = 0.5,
         cooldown: TimeInterval = 1.0,
         damage: Int = 1,
         range: CGFloat = 60,
         knockbackForce: CGFloat = 300) {
        self.damage = damage
        self.range = range
        self.knockbackForce = knockbackForce
        super.init(name: name, duration: duration, cooldown: cooldown)
    }

    override func execute(target: Player, boss: Boss, completion: @escaping () -> Void) {
        lastExecutionTime = CACurrentMediaTime()

        // Анимация подготовки к атаке
        let prepareAction = SKAction.sequence([
            SKAction.moveBy(x: boss.facingDirection == .right ? -10 : 10, y: 0, duration: 0.1),
            SKAction.wait(forDuration: 0.1)
        ])

        // Рывок к игроку
        let dashAction = SKAction.run { [weak boss, weak target] in
            guard let boss = boss, let target = target else { return }

            let distance = target.position.x - boss.position.x
            if abs(distance) <= self.range {
                let knockbackDirection: CGFloat = distance > 0 ? 1 : -1
                target.takeDamage(self.damage, knockbackDirection: knockbackDirection, knockbackForce: self.knockbackForce)
            }
        }

        // Восстановление после атаки
        let recoverAction = SKAction.moveBy(x: boss.facingDirection == .right ? 10 : -10, y: 0, duration: 0.2)

        boss.run(SKAction.sequence([
            prepareAction,
            dashAction,
            recoverAction,
            SKAction.run { completion() }
        ]))
    }
}

// MARK: - ProjectileAttackPattern

/// Паттерн атаки снарядами
class ProjectileAttackPattern: BaseAttackPattern {
    let projectileCount: Int
    let projectileSpeed: CGFloat
    let projectileDamage: Int
    let spreadAngle: CGFloat // В радианах

    init(name: String = "Залп снарядов",
         duration: TimeInterval = 0.8,
         cooldown: TimeInterval = 2.0,
         projectileCount: Int = 3,
         projectileSpeed: CGFloat = 300,
         projectileDamage: Int = 1,
         spreadAngle: CGFloat = .pi / 6) {
        self.projectileCount = projectileCount
        self.projectileSpeed = projectileSpeed
        self.projectileDamage = projectileDamage
        self.spreadAngle = spreadAngle
        super.init(name: name, duration: duration, cooldown: cooldown)
    }

    override func execute(target: Player, boss: Boss, completion: @escaping () -> Void) {
        lastExecutionTime = CACurrentMediaTime()

        // Создаём снаряды
        let createProjectiles = SKAction.run { [weak boss, weak target] in
            guard let boss = boss, let target = target, let parent = boss.parent else { return }

            let direction = (target.position - boss.position).normalized()
            let baseAngle = atan2(direction.dy, direction.dx)

            for i in 0..<self.projectileCount {
                let angleOffset = self.spreadAngle * CGFloat(i - self.projectileCount / 2)
                let angle = baseAngle + angleOffset

                let velocity = CGVector(
                    dx: cos(angle) * self.projectileSpeed,
                    dy: sin(angle) * self.projectileSpeed
                )

                let projectile = BossProjectile(damage: self.projectileDamage, velocity: velocity)
                projectile.position = boss.position
                parent.addChild(projectile)
            }
        }

        boss.run(SKAction.sequence([
            SKAction.wait(forDuration: 0.2), // Подготовка
            createProjectiles,
            SKAction.wait(forDuration: duration - 0.2),
            SKAction.run { completion() }
        ]))
    }
}

// MARK: - AreaAttackPattern

/// Паттерн атаки по области
class AreaAttackPattern: BaseAttackPattern {
    let radius: CGFloat
    let damage: Int
    let warningDuration: TimeInterval

    init(name: String = "Удар по области",
         duration: TimeInterval = 1.5,
         cooldown: TimeInterval = 3.0,
         radius: CGFloat = 100,
         damage: Int = 2,
         warningDuration: TimeInterval = 0.8) {
        self.radius = radius
        self.damage = damage
        self.warningDuration = warningDuration
        super.init(name: name, duration: duration, cooldown: cooldown)
    }

    override func execute(target: Player, boss: Boss, completion: @escaping () -> Void) {
        lastExecutionTime = CACurrentMediaTime()

        guard let parent = boss.parent else {
            completion()
            return
        }

        // Индикатор опасной зоны
        let warningCircle = SKShapeNode(circleOfRadius: radius)
        warningCircle.position = target.position
        warningCircle.strokeColor = .red
        warningCircle.fillColor = SKColor.red.withAlphaComponent(0.2)
        warningCircle.lineWidth = 2
        warningCircle.zPosition = 5
        parent.addChild(warningCircle)

        let targetPosition = target.position

        // Мигание предупреждения
        let blinkAction = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.5, duration: 0.1),
            SKAction.fadeAlpha(to: 1.0, duration: 0.1)
        ])
        warningCircle.run(SKAction.repeat(blinkAction, count: Int(warningDuration / 0.2)))

        // Атака после предупреждения
        boss.run(SKAction.sequence([
            SKAction.wait(forDuration: warningDuration),
            SKAction.run { [weak self, weak target, weak warningCircle] in
                guard let self = self, let target = target else { return }

                // Визуальный эффект удара
                warningCircle?.fillColor = SKColor.red.withAlphaComponent(0.8)

                // Проверяем попадание
                let distance = hypot(target.position.x - targetPosition.x, target.position.y - targetPosition.y)
                if distance <= self.radius {
                    let knockbackDirection: CGFloat = target.position.x > targetPosition.x ? 1 : -1
                    target.takeDamage(self.damage, knockbackDirection: knockbackDirection, knockbackForce: 400)
                }
            },
            SKAction.wait(forDuration: 0.3),
            SKAction.run { warningCircle.removeFromParent() },
            SKAction.run { completion() }
        ]))
    }
}

// MARK: - BossProjectile

/// Снаряд босса
class BossProjectile: SKSpriteNode {
    private let damage: Int
    private let projectileVelocity: CGVector
    private let lifetime: TimeInterval = 5.0

    init(damage: Int, velocity: CGVector) {
        self.damage = damage
        self.projectileVelocity = velocity

        let color = SKColor.purple
        let size = CGSize(width: 12, height: 12)

        super.init(texture: nil, color: color, size: size)

        self.name = "bossProjectile"
        self.zPosition = 15

        setupPhysics()
        setupLifetime()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) не реализован")
    }

    private func setupPhysics() {
        let physicsBody = SKPhysicsBody(circleOfRadius: 6)
        physicsBody.isDynamic = true
        physicsBody.affectedByGravity = false
        physicsBody.allowsRotation = false

        physicsBody.categoryBitMask = PhysicsCategory.enemyProjectile
        physicsBody.collisionBitMask = PhysicsCategory.ground
        physicsBody.contactTestBitMask = PhysicsCategory.player | PhysicsCategory.ground

        physicsBody.velocity = projectileVelocity

        self.physicsBody = physicsBody
    }

    private func setupLifetime() {
        run(SKAction.sequence([
            SKAction.wait(forDuration: lifetime),
            SKAction.removeFromParent()
        ]))
    }

    /// Обработка столкновения с игроком
    func hitPlayer(_ player: Player) {
        let knockbackDirection: CGFloat = player.position.x > position.x ? 1 : -1
        player.takeDamage(damage, knockbackDirection: knockbackDirection, knockbackForce: 150)
        removeFromParent()
    }
}

// MARK: - CGPoint Extension

private extension CGPoint {
    static func - (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        return CGPoint(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
    }

    func normalized() -> CGVector {
        let length = sqrt(x * x + y * y)
        guard length > 0 else { return .zero }
        return CGVector(dx: x / length, dy: y / length)
    }
}
