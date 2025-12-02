import SpriteKit

// MARK: - IceGolem

/// Ледяной Голем — медленный мощный враг для уровня 5 (Штормовые Пики)
/// Не отбрасывается при ударе, замедляет игрока при контакте
class IceGolem: Enemy {

    // MARK: - Constants

    /// Размер спрайта голема
    private static let spriteSize = CGSize(width: 48, height: 56)

    /// Цвет placeholder (голубой лёд)
    private static let placeholderColor = UIColor(red: 0.678, green: 0.847, blue: 0.902, alpha: 1.0) // #ADD8E6

    /// Конфигурация ледяного голема
    static let iceGolemConfig = EnemyConfig(
        health: 3,
        damage: 2,
        moveSpeed: 40,
        detectionRange: 100,
        attackRange: 50,
        attackCooldown: 2.0,
        scoreValue: 40,
        canBeStomped: false,
        knockbackResistance: 1.0
    )

    // MARK: - Slow Effect Constants

    /// Длительность замедления игрока
    private let slowDuration: TimeInterval = 2.0

    /// Множитель замедления (0.5 = 50% скорости)
    private let slowMultiplier: CGFloat = 0.5

    // MARK: - Attack Properties

    /// Время подготовки удара
    private let attackWindupTime: TimeInterval = 1.0

    /// Находится ли голем в фазе подготовки удара
    private var isWindingUp: Bool = false

    /// Радиус удара кулаком
    private let punchRadius: CGFloat = 60

    // MARK: - Visual Effects

    /// Эмиттер частиц снега
    private var snowEmitter: SKEmitterNode?

    /// Нода для ледяного следа
    private var iceTrailTimer: TimeInterval = 0
    private let iceTrailInterval: TimeInterval = 0.3

    // MARK: - Init

    /// Инициализация ледяного голема
    init() {
        super.init(config: IceGolem.iceGolemConfig, entityType: "iceGolem")

        // Устанавливаем правильный размер
        self.size = IceGolem.spriteSize
        self.color = IceGolem.placeholderColor

        // Перенастраиваем физическое тело под новый размер
        setupPhysicsBody(size: IceGolem.spriteSize)

        // Настраиваем визуальные эффекты
        setupSnowParticles()

        // Загружаем placeholder анимации
        AnimationManager.shared.preloadAnimations(for: "iceGolem")

        // Запускаем idle анимацию
        playAnimation(for: .idle)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) не реализован")
    }

    // MARK: - Setup

    /// Настройка частиц снега вокруг голема
    private func setupSnowParticles() {
        let emitter = SKEmitterNode()

        // Настройки частиц
        emitter.particleTexture = nil
        emitter.particleBirthRate = 15
        emitter.particleLifetime = 2.0
        emitter.particleLifetimeRange = 0.5

        emitter.particlePositionRange = CGVector(dx: size.width * 0.8, dy: size.height * 0.6)

        emitter.particleSpeed = 20
        emitter.particleSpeedRange = 10

        emitter.emissionAngle = CGFloat.pi * 1.5 // Вниз
        emitter.emissionAngleRange = CGFloat.pi * 0.5

        emitter.particleAlpha = 0.7
        emitter.particleAlphaRange = 0.3
        emitter.particleAlphaSpeed = -0.3

        emitter.particleScale = 0.3
        emitter.particleScaleRange = 0.2
        emitter.particleScaleSpeed = -0.1

        emitter.particleColor = SKColor(red: 0.9, green: 0.95, blue: 1.0, alpha: 1.0)
        emitter.particleColorBlendFactor = 1.0

        emitter.position = CGPoint(x: 0, y: size.height * 0.3)
        emitter.zPosition = -1

        addChild(emitter)
        snowEmitter = emitter
    }

    // MARK: - Update

    /// Переопределённый update для обработки ледяного следа
    override func update(deltaTime: TimeInterval) {
        super.update(deltaTime: deltaTime)

        // Создаём ледяной след при движении
        if currentState == .patrol || currentState == .chase {
            iceTrailTimer += deltaTime
            if iceTrailTimer >= iceTrailInterval {
                createIceTrail()
                iceTrailTimer = 0
            }
        }
    }

    // MARK: - Chase Override

    override func updateChase(deltaTime: TimeInterval, target: Player) {
        // Голем не ускоряется при преследовании — используем базовую скорость
        // Базовый класс уже использует config.moveSpeed, так что просто вызываем super

        super.updateChase(deltaTime: deltaTime, target: target)
    }

    // MARK: - State Machine Override

    override func onStateEnter(_ state: EnemyState) {
        switch state {
        case .attack:
            // Начинаем подготовку удара
            performPunchAttack()

        case .dead:
            // Останавливаем частицы при смерти
            snowEmitter?.particleBirthRate = 0

        default:
            break
        }

        super.onStateEnter(state)
    }

    // MARK: - Attack

    /// Выполнение удара кулаком с задержкой
    private func performPunchAttack() {
        isWindingUp = true

        // Эффект подготовки — поднимаем руку (отклонение назад)
        let windupAnimation = SKAction.sequence([
            SKAction.moveBy(x: facingDirection == .right ? -5 : 5, y: 3, duration: attackWindupTime * 0.7),
            SKAction.run { [weak self] in
                self?.executePunch()
            }
        ])

        run(windupAnimation, withKey: "punchWindup")
    }

    /// Исполнение удара
    private func executePunch() {
        isWindingUp = false

        // Быстрый удар вперёд
        let punchDirection: CGFloat = facingDirection == .right ? 1 : -1
        let punchAnimation = SKAction.sequence([
            SKAction.moveBy(x: punchDirection * 15, y: -3, duration: 0.1),
            SKAction.run { [weak self] in
                self?.createPunchHitbox()
                self?.createIceTrail()
            },
            SKAction.moveBy(x: punchDirection * -10, y: 0, duration: 0.2),
            SKAction.run { [weak self] in
                self?.changeState(to: .idle)
            }
        ])

        run(punchAnimation, withKey: "punchExecution")
    }

    /// Создание хитбокса удара
    private func createPunchHitbox() {
        guard let target = targetPlayer else { return }

        // Проверяем, находится ли игрок в радиусе удара
        let punchOffset: CGFloat = facingDirection == .right ? size.width / 2 + 20 : -size.width / 2 - 20
        let punchCenter = CGPoint(x: position.x + punchOffset, y: position.y)

        let distanceToPlayer = hypot(target.position.x - punchCenter.x, target.position.y - punchCenter.y)

        if distanceToPlayer <= punchRadius {
            // Наносим урон
            let knockbackDirection: CGFloat = target.position.x > position.x ? 1 : -1
            target.takeDamage(config.damage, knockbackDirection: knockbackDirection, knockbackForce: 300)
        }

        // Визуальный эффект удара
        createPunchEffect(at: punchCenter)
    }

    /// Создание визуального эффекта удара
    private func createPunchEffect(at position: CGPoint) {
        guard let parent = self.parent else { return }

        // Круг удара
        let impactCircle = SKShapeNode(circleOfRadius: punchRadius * 0.8)
        impactCircle.position = position
        impactCircle.fillColor = SKColor(red: 0.7, green: 0.9, blue: 1.0, alpha: 0.5)
        impactCircle.strokeColor = SKColor(red: 0.5, green: 0.8, blue: 1.0, alpha: 0.8)
        impactCircle.lineWidth = 3
        impactCircle.zPosition = 5

        parent.addChild(impactCircle)

        // Анимация исчезновения
        let fadeOut = SKAction.sequence([
            SKAction.group([
                SKAction.scale(to: 1.5, duration: 0.2),
                SKAction.fadeOut(withDuration: 0.2)
            ]),
            SKAction.removeFromParent()
        ])

        impactCircle.run(fadeOut)
    }

    // MARK: - Ice Trail

    /// Создание ледяного следа
    private func createIceTrail() {
        guard let parent = self.parent else { return }

        // Ледяной след под ногами
        let trailSize = CGSize(width: size.width * 0.6, height: 6)
        let trail = SKSpriteNode(color: SKColor(red: 0.7, green: 0.9, blue: 1.0, alpha: 0.6), size: trailSize)
        trail.position = CGPoint(x: position.x, y: position.y - size.height / 2 + 3)
        trail.zPosition = -5

        parent.addChild(trail)

        // Исчезновение следа
        let fadeOut = SKAction.sequence([
            SKAction.wait(forDuration: 1.5),
            SKAction.fadeOut(withDuration: 0.5),
            SKAction.removeFromParent()
        ])

        trail.run(fadeOut)
    }

    // MARK: - Contact Damage Override

    /// Нанесение контактного урона игроку с эффектом замедления
    override func dealContactDamage(to player: Player) {
        guard currentState != .dead && currentState != .hurt else { return }

        // Применяем замедление
        applySlowToPlayer(player)

        // Наносим урон
        let knockbackDirection: CGFloat = player.position.x > position.x ? 1 : -1
        player.takeDamage(config.damage, knockbackDirection: knockbackDirection, knockbackForce: 200)
    }

    /// Применение эффекта замедления к игроку
    private func applySlowToPlayer(_ player: Player) {
        // Визуальный эффект заморозки
        createFreezeEffect(on: player)

        // Отправляем уведомление для применения slow эффекта
        NotificationCenter.default.post(
            name: .playerSlowed,
            object: player,
            userInfo: [
                "duration": slowDuration,
                "multiplier": slowMultiplier
            ]
        )
    }

    /// Создание визуального эффекта заморозки на игроке
    private func createFreezeEffect(on player: Player) {
        // Голубой оттенок на игроке
        let freezeOverlay = SKSpriteNode(color: SKColor(red: 0.5, green: 0.8, blue: 1.0, alpha: 0.4), size: player.size)
        freezeOverlay.name = "freezeOverlay"
        freezeOverlay.zPosition = 50

        // Удаляем предыдущий оверлей если есть
        player.childNode(withName: "freezeOverlay")?.removeFromParent()

        player.addChild(freezeOverlay)

        // Анимация исчезновения эффекта
        let fadeSequence = SKAction.sequence([
            SKAction.wait(forDuration: slowDuration - 0.5),
            SKAction.fadeOut(withDuration: 0.5),
            SKAction.removeFromParent()
        ])

        freezeOverlay.run(fadeSequence)

        // Частицы льда вокруг игрока
        createIceParticlesOnPlayer(player)
    }

    /// Создание частиц льда вокруг игрока
    private func createIceParticlesOnPlayer(_ player: Player) {
        let emitter = SKEmitterNode()

        emitter.particleTexture = nil
        emitter.particleBirthRate = 20
        emitter.particleLifetime = 0.8
        emitter.particleLifetimeRange = 0.2

        emitter.particlePositionRange = CGVector(dx: player.size.width * 0.5, dy: player.size.height * 0.3)

        emitter.particleSpeed = 30
        emitter.particleSpeedRange = 15

        emitter.emissionAngle = CGFloat.pi * 0.5 // Вверх
        emitter.emissionAngleRange = CGFloat.pi * 0.5

        emitter.particleAlpha = 0.8
        emitter.particleAlphaSpeed = -0.8

        emitter.particleScale = 0.2
        emitter.particleScaleRange = 0.1

        emitter.particleColor = SKColor(red: 0.7, green: 0.9, blue: 1.0, alpha: 1.0)
        emitter.particleColorBlendFactor = 1.0

        emitter.position = .zero
        emitter.zPosition = 51
        emitter.name = "iceParticles"

        // Удаляем предыдущие частицы
        player.childNode(withName: "iceParticles")?.removeFromParent()

        player.addChild(emitter)

        // Останавливаем генерацию через время замедления
        emitter.run(SKAction.sequence([
            SKAction.wait(forDuration: slowDuration),
            SKAction.run { emitter.particleBirthRate = 0 },
            SKAction.wait(forDuration: 1.0),
            SKAction.removeFromParent()
        ]))
    }

    // MARK: - Stomp Override

    /// Голем не может быть убит прыжком сверху
    override func handleStomp(by player: Player) {
        // canBeStomped = false, но на всякий случай переопределяем
        // Игрок получает урон при попытке прыгнуть на голема
        dealContactDamage(to: player)

        // Небольшой отскок игрока
        player.bounce()
    }

    // MARK: - Death Override

    override func die() {
        // Останавливаем все эффекты
        snowEmitter?.particleBirthRate = 0
        removeAction(forKey: "punchWindup")
        removeAction(forKey: "punchExecution")

        // Отключаем физику
        physicsBody?.isDynamic = false
        physicsBody?.categoryBitMask = 0
        physicsBody?.contactTestBitMask = 0

        // Эффект разрушения — разлетающиеся осколки льда
        createShatterEffect()

        // Анимация смерти — медленное разрушение
        let deathAnimation = SKAction.sequence([
            SKAction.group([
                SKAction.fadeOut(withDuration: 0.8),
                SKAction.scale(to: 0.8, duration: 0.8)
            ]),
            SKAction.removeFromParent()
        ])

        run(deathAnimation)

        // Отправляем уведомление о смерти
        NotificationCenter.default.post(
            name: .enemyDied,
            object: self,
            userInfo: ["enemy": self, "scoreValue": config.scoreValue]
        )
    }

    /// Создание эффекта разрушения
    private func createShatterEffect() {
        guard let parent = self.parent else { return }

        // Создаём несколько осколков льда
        for _ in 0..<8 {
            let shardSize = CGSize(width: CGFloat.random(in: 8...16), height: CGFloat.random(in: 8...16))
            let shard = SKSpriteNode(color: IceGolem.placeholderColor, size: shardSize)

            shard.position = position
            shard.zPosition = 15

            parent.addChild(shard)

            // Случайное направление разлёта
            let angle = CGFloat.random(in: 0...(CGFloat.pi * 2))
            let distance = CGFloat.random(in: 30...80)
            let dx = cos(angle) * distance
            let dy = sin(angle) * distance + 50 // Немного вверх

            let shatterAnimation = SKAction.sequence([
                SKAction.group([
                    SKAction.moveBy(x: dx, y: dy, duration: 0.5),
                    SKAction.rotate(byAngle: CGFloat.random(in: -CGFloat.pi...CGFloat.pi), duration: 0.5),
                    SKAction.fadeOut(withDuration: 0.5)
                ]),
                SKAction.removeFromParent()
            ])

            shard.run(shatterAnimation)
        }
    }
}
