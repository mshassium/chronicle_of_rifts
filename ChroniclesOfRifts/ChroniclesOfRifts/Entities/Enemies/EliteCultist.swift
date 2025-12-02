import SpriteKit

/// Элитный культист — магический враг для уровня 7
/// Кастует магические снаряды и телепортируется при угрозе
final class EliteCultist: Enemy {

    // MARK: - EliteCultist State

    /// Внутренние состояния элитного культиста
    private enum EliteCultistState {
        case patrol         // Патрулирование
        case alert          // Обнаружил игрока
        case casting        // Кастует заклинание
        case attack         // Выпускает снаряд
        case teleportStart  // Начало телепортации (delay)
        case teleporting    // В процессе телепорта
        case retreat        // Отступление после телепорта
    }

    /// Текущее внутреннее состояние
    private var cultistState: EliteCultistState = .patrol

    // MARK: - Constants

    /// Размер спрайта
    private static let spriteSize = CGSize(width: 24, height: 36)

    /// Цвет placeholder (тёмно-фиолетовый)
    private static let placeholderColor = UIColor(red: 0.4, green: 0.1, blue: 0.5, alpha: 1.0)

    /// Золотой акцент
    private static let accentColor = UIColor(red: 0.85, green: 0.65, blue: 0.2, alpha: 1.0)

    // MARK: - Config

    /// Радиус обнаружения
    private let detectionRadius: CGFloat = 180

    /// Минимальная дистанция (триггер телепорта)
    private let minSafeDistance: CGFloat = 60

    /// Дальность телепорта
    private let teleportRange: CGFloat = 100

    /// Кулдаун телепорта
    private let teleportCooldown: TimeInterval = 3.0

    /// Delay перед телепортом (можно прервать уроном)
    private let teleportDelay: TimeInterval = 0.2

    /// Время каста перед выстрелом
    private let castTime: TimeInterval = 0.5

    /// Скорость снаряда (медленнее чем у FloatingEye)
    private let projectileSpeed: CGFloat = 100

    /// Интервал между атаками
    private let attackInterval: TimeInterval = 2.5

    // MARK: - Timers

    /// Таймер телепорта (кулдаун)
    private var teleportTimer: TimeInterval = 0

    /// Таймер каста
    private var castTimer: TimeInterval = 0

    /// Таймер атаки
    private var attackTimer: TimeInterval = 0

    /// Таймер задержки телепорта
    private var teleportDelayTimer: TimeInterval = 0

    // MARK: - Visual

    /// Нода эффекта "!"
    private var alertIndicator: SKLabelNode?

    /// Эффект каста (светящиеся руки)
    private var castingEffect: SKSpriteNode?

    /// Послеобраз при телепорте
    private var afterImage: SKSpriteNode?

    /// Золотая накидка (визуальный акцент)
    private var capeNode: SKSpriteNode?

    // MARK: - Projectile Tracking

    /// Активные снаряды
    private var activeProjectiles: [CultistProjectile] = []

    // MARK: - Bounds

    /// Границы уровня для телепорта
    var levelBounds: CGRect = .zero

    // MARK: - Init

    init() {
        let config = EnemyConfig(
            health: 2,
            damage: 1,
            moveSpeed: 90,
            detectionRange: 180,
            attackRange: 150,
            attackCooldown: 2.5,
            scoreValue: 35,
            canBeStomped: true,
            knockbackResistance: 0.0
        )

        super.init(config: config, entityType: "eliteCultist")

        // Устанавливаем размер
        self.size = EliteCultist.spriteSize
        self.color = EliteCultist.placeholderColor

        // Настраиваем физику
        setupPhysicsBody(size: EliteCultist.spriteSize)

        // Настраиваем визуал
        setupVisual()

        // Загружаем анимации
        AnimationManager.shared.preloadAnimations(for: "eliteCultist")

        // Запускаем idle
        playAnimation(for: .idle)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) не реализован")
    }

    // MARK: - Setup

    /// Настройка визуального отображения
    private func setupVisual() {
        // Золотая накидка (акцент)
        let cape = SKSpriteNode(color: EliteCultist.accentColor, size: CGSize(width: 20, height: 8))
        cape.position = CGPoint(x: 0, y: 8)
        cape.zPosition = -1
        addChild(cape)
        self.capeNode = cape

        // Светящиеся глаза
        let leftEye = SKSpriteNode(color: .magenta, size: CGSize(width: 3, height: 3))
        leftEye.position = CGPoint(x: -4, y: 8)
        leftEye.zPosition = 1
        leftEye.name = "leftEye"
        addChild(leftEye)

        let rightEye = SKSpriteNode(color: .magenta, size: CGSize(width: 3, height: 3))
        rightEye.position = CGPoint(x: 4, y: 8)
        rightEye.zPosition = 1
        rightEye.name = "rightEye"
        addChild(rightEye)

        // Пульсация глаз
        let eyePulse = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.5, duration: 0.5),
            SKAction.fadeAlpha(to: 1.0, duration: 0.5)
        ])
        leftEye.run(SKAction.repeatForever(eyePulse))
        rightEye.run(SKAction.repeatForever(SKAction.sequence([
            SKAction.wait(forDuration: 0.25),
            eyePulse
        ])))
    }

    // MARK: - Update

    override func update(deltaTime: TimeInterval) {
        guard currentState != .dead else { return }

        // Обновляем таймеры
        updateCultistTimers(deltaTime: deltaTime)

        // Обновляем AI
        updateCultistAI(deltaTime: deltaTime)

        // Обновляем снаряды
        updateProjectiles(deltaTime: deltaTime)

        // Вызываем базовый update для физики
        super.update(deltaTime: deltaTime)
    }

    /// Обновление таймеров
    private func updateCultistTimers(deltaTime: TimeInterval) {
        if teleportTimer > 0 {
            teleportTimer -= deltaTime
        }
        if castTimer > 0 {
            castTimer -= deltaTime
        }
        if attackTimer > 0 {
            attackTimer -= deltaTime
        }
        if teleportDelayTimer > 0 {
            teleportDelayTimer -= deltaTime
        }
    }

    /// Обновление AI
    private func updateCultistAI(deltaTime: TimeInterval) {
        let playerDistance = distanceToPlayer()

        switch cultistState {
        case .patrol:
            updatePatrolBehavior(deltaTime: deltaTime)

            // Обнаружение игрока
            if playerDistance <= detectionRadius {
                if let player = detectPlayer() {
                    targetPlayer = player
                    transitionTo(.alert)
                }
            }

        case .alert:
            // Показываем "!" и готовимся
            if alertIndicator == nil {
                showAlertEffect()
            }

            // После короткой паузы — решаем что делать
            run(SKAction.sequence([
                SKAction.wait(forDuration: 0.3),
                SKAction.run { [weak self] in
                    self?.decideNextAction()
                }
            ]), withKey: "alertDecision")

        case .casting:
            // Стоим на месте, кастуем
            if castTimer <= 0 {
                transitionTo(.attack)
            }

            // Если игрок слишком близко — телепортируемся
            if playerDistance < minSafeDistance && teleportTimer <= 0 {
                cancelCast()
                transitionTo(.teleportStart)
            }

        case .attack:
            shoot()
            transitionTo(.patrol)

        case .teleportStart:
            // Начинаем задержку телепорта
            if teleportDelayTimer <= 0 {
                transitionTo(.teleporting)
            }

        case .teleporting:
            // Выполняем телепорт
            performTeleport()
            transitionTo(.retreat)

        case .retreat:
            // После телепорта — кратко отступаем, затем атакуем
            updateRetreatBehavior(deltaTime: deltaTime)

            if playerDistance > minSafeDistance * 1.5 {
                if attackTimer <= 0 {
                    transitionTo(.casting)
                } else {
                    transitionTo(.patrol)
                }
            }
        }
    }

    /// Решение следующего действия
    private func decideNextAction() {
        let playerDistance = distanceToPlayer()

        hideAlertEffect()

        // Если игрок слишком близко — телепортируемся
        if playerDistance < minSafeDistance && teleportTimer <= 0 {
            transitionTo(.teleportStart)
        }
        // Иначе — кастуем
        else if attackTimer <= 0 {
            transitionTo(.casting)
        } else {
            transitionTo(.patrol)
        }
    }

    /// Обновление патрулирования
    private func updatePatrolBehavior(deltaTime: TimeInterval) {
        // Используем базовое поведение патрулирования
        // но проверяем игрока с нашим радиусом

        if checkEdge() {
            turnAround()
        }

        // Простое хождение
        let speed = config.moveSpeed
        let direction: CGFloat = facingDirection == .right ? 1 : -1
        physicsBody?.velocity.dx = direction * speed
    }

    /// Обновление отступления
    private func updateRetreatBehavior(deltaTime: TimeInterval) {
        guard let playerPos = targetPlayer?.position else {
            transitionTo(.patrol)
            return
        }

        // Двигаемся от игрока
        let direction: CGFloat = position.x > playerPos.x ? 1 : -1
        physicsBody?.velocity.dx = direction * config.moveSpeed * 0.5
    }

    /// Переход в новое состояние
    private func transitionTo(_ newState: EliteCultistState) {
        guard newState != cultistState else { return }

        // Очистка предыдущего состояния
        removeAction(forKey: "alertDecision")

        cultistState = newState

        switch newState {
        case .patrol:
            playAnimation(for: .patrol)

        case .alert:
            playAnimation(for: .idle)

        case .casting:
            castTimer = castTime
            playAnimation(for: .idle)
            showCastingEffect()

        case .attack:
            attackTimer = attackInterval
            hideCastingEffect()
            playAnimation(for: .attack)

        case .teleportStart:
            teleportDelayTimer = teleportDelay
            playAnimation(for: .idle)
            showTeleportChargeEffect()

        case .teleporting:
            teleportTimer = teleportCooldown

        case .retreat:
            playAnimation(for: .patrol)
        }
    }

    // MARK: - Combat

    /// Выстрел магическим снарядом
    private func shoot() {
        guard let playerPos = targetPlayer?.position else { return }
        guard let parentNode = self.parent else { return }

        // Направление к игроку
        let dx = playerPos.x - position.x
        let dy = playerPos.y - position.y
        let direction = CGVector(dx: dx, dy: dy)

        // Создаём снаряд
        let projectile = CultistProjectile(direction: direction, speed: projectileSpeed)
        projectile.position = CGPoint(x: position.x, y: position.y + 5)
        parentNode.addChild(projectile)

        // Отслеживаем снаряд
        activeProjectiles.append(projectile)

        // Эффект отдачи
        let recoilDirection: CGFloat = dx > 0 ? -1 : 1
        run(SKAction.sequence([
            SKAction.moveBy(x: recoilDirection * 3, y: 0, duration: 0.05),
            SKAction.moveBy(x: recoilDirection * -3, y: 0, duration: 0.1)
        ]))
    }

    /// Отмена каста
    private func cancelCast() {
        castTimer = 0
        hideCastingEffect()
    }

    /// Обновление снарядов
    private func updateProjectiles(deltaTime: TimeInterval) {
        // Удаляем уничтоженные снаряды
        activeProjectiles.removeAll { $0.parent == nil }

        // Обновляем активные
        for projectile in activeProjectiles {
            projectile.update(deltaTime: deltaTime)
        }
    }

    // MARK: - Teleport

    /// Выполнение телепорта
    private func performTeleport() {
        // Создаём послеобраз на текущей позиции
        createAfterImage()

        // Находим безопасную позицию для телепорта
        let newPosition = findTeleportPosition()

        // Эффект исчезновения
        let fadeOut = SKAction.fadeOut(withDuration: 0.1)
        let move = SKAction.move(to: newPosition, duration: 0)
        let fadeIn = SKAction.fadeIn(withDuration: 0.15)

        run(SKAction.sequence([fadeOut, move, fadeIn]))

        // Эффект появления
        run(SKAction.sequence([
            SKAction.wait(forDuration: 0.1),
            SKAction.run { [weak self] in
                self?.showAppearEffect()
            }
        ]))
    }

    /// Поиск позиции для телепорта
    private func findTeleportPosition() -> CGPoint {
        guard let playerPos = targetPlayer?.position else {
            return position
        }

        // Направление от игрока
        let dx = position.x - playerPos.x
        let directionSign: CGFloat = dx > 0 ? 1 : -1

        // Случайное смещение в радиусе телепорта
        let randomOffset = CGFloat.random(in: teleportRange * 0.5...teleportRange)
        let randomY = CGFloat.random(in: -20...20)

        var newX = position.x + directionSign * randomOffset
        var newY = position.y + randomY

        // Ограничиваем границами уровня
        if levelBounds != .zero {
            let margin: CGFloat = 30
            newX = max(levelBounds.minX + margin, min(levelBounds.maxX - margin, newX))
            newY = max(levelBounds.minY + margin, min(levelBounds.maxY - margin, newY))
        }

        return CGPoint(x: newX, y: newY)
    }

    /// Создание послеобраза
    private func createAfterImage() {
        guard let parentNode = self.parent else { return }

        // Копируем внешний вид
        let afterImage = SKSpriteNode(color: EliteCultist.placeholderColor.withAlphaComponent(0.6),
                                      size: self.size)
        afterImage.position = self.position
        afterImage.xScale = self.xScale
        afterImage.zPosition = self.zPosition - 1
        parentNode.addChild(afterImage)

        // Анимация исчезновения послеобраза
        let fadeAndRemove = SKAction.sequence([
            SKAction.group([
                SKAction.fadeOut(withDuration: 0.5),
                SKAction.scale(to: 1.2, duration: 0.5)
            ]),
            SKAction.removeFromParent()
        ])
        afterImage.run(fadeAndRemove)
    }

    /// Эффект появления после телепорта
    private func showAppearEffect() {
        guard let parentNode = self.parent else { return }

        // Магическая вспышка
        let flash = SKSpriteNode(color: .magenta, size: CGSize(width: 40, height: 40))
        flash.position = self.position
        flash.alpha = 0.8
        flash.zPosition = self.zPosition - 1
        parentNode.addChild(flash)

        let flashAnimation = SKAction.sequence([
            SKAction.group([
                SKAction.fadeOut(withDuration: 0.2),
                SKAction.scale(to: 2.0, duration: 0.2)
            ]),
            SKAction.removeFromParent()
        ])
        flash.run(flashAnimation)
    }

    // MARK: - Visual Effects

    /// Показать эффект "!" над головой
    private func showAlertEffect() {
        guard alertIndicator == nil else { return }

        let indicator = SKLabelNode(text: "!")
        indicator.fontName = "Helvetica-Bold"
        indicator.fontSize = 14
        indicator.fontColor = EliteCultist.accentColor
        indicator.position = CGPoint(x: 0, y: size.height / 2 + 10)
        indicator.zPosition = 100
        indicator.name = "alertIndicator"

        addChild(indicator)
        alertIndicator = indicator

        // Анимация появления
        indicator.setScale(0)
        indicator.run(SKAction.sequence([
            SKAction.scale(to: 1.3, duration: 0.1),
            SKAction.scale(to: 1.0, duration: 0.05)
        ]))
    }

    /// Скрыть эффект "!"
    private func hideAlertEffect() {
        alertIndicator?.removeFromParent()
        alertIndicator = nil
    }

    /// Показать эффект каста
    private func showCastingEffect() {
        guard castingEffect == nil else { return }

        // Светящиеся руки
        let effect = SKSpriteNode(color: .magenta, size: CGSize(width: 30, height: 10))
        effect.position = CGPoint(x: 0, y: -5)
        effect.alpha = 0.6
        effect.zPosition = 2
        addChild(effect)
        castingEffect = effect

        // Пульсация
        let pulse = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.9, duration: 0.15),
            SKAction.fadeAlpha(to: 0.4, duration: 0.15)
        ])
        effect.run(SKAction.repeatForever(pulse))

        // Частицы
        let particleAction = SKAction.repeatForever(SKAction.sequence([
            SKAction.run { [weak self] in
                self?.spawnCastParticle()
            },
            SKAction.wait(forDuration: 0.1)
        ]))
        effect.run(particleAction, withKey: "castParticles")
    }

    /// Скрыть эффект каста
    private func hideCastingEffect() {
        castingEffect?.removeAllActions()
        castingEffect?.removeFromParent()
        castingEffect = nil
    }

    /// Создание частицы каста
    private func spawnCastParticle() {
        guard let parentNode = self.parent else { return }

        let particle = SKSpriteNode(color: .magenta, size: CGSize(width: 4, height: 4))
        particle.position = CGPoint(
            x: position.x + CGFloat.random(in: -10...10),
            y: position.y + CGFloat.random(in: -5...5)
        )
        particle.alpha = 0.8
        particle.zPosition = self.zPosition + 1
        parentNode.addChild(particle)

        let floatUp = SKAction.moveBy(x: 0, y: 20, duration: 0.4)
        let fadeOut = SKAction.fadeOut(withDuration: 0.4)

        particle.run(SKAction.sequence([
            SKAction.group([floatUp, fadeOut]),
            SKAction.removeFromParent()
        ]))
    }

    /// Эффект заряда телепорта
    private func showTeleportChargeEffect() {
        // Мерцание
        let blink = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.3, duration: 0.05),
            SKAction.fadeAlpha(to: 1.0, duration: 0.05)
        ])
        run(SKAction.repeat(blink, count: 2), withKey: "teleportCharge")
    }

    // MARK: - Helper

    /// Расстояние до игрока
    private func distanceToPlayer() -> CGFloat {
        guard let playerPos = targetPlayer?.position else { return .infinity }
        return hypot(position.x - playerPos.x, position.y - playerPos.y)
    }

    /// Override detectPlayer для собственного радиуса
    override func detectPlayer() -> Player? {
        guard let scene = scene else { return nil }

        for child in scene.children {
            if child.name == "gameLayer" {
                for entity in child.children {
                    if let player = entity as? Player {
                        let distance = hypot(player.position.x - position.x, player.position.y - position.y)
                        if distance <= detectionRadius {
                            return player
                        }
                    }
                }
            }
            if let player = child as? Player {
                let distance = hypot(player.position.x - position.x, player.position.y - position.y)
                if distance <= detectionRadius {
                    return player
                }
            }
        }

        return nil
    }

    // MARK: - Damage Override

    override func takeDamage(_ hitInfo: HitInfo) {
        guard currentState != .dead else { return }

        // Прерываем телепорт если в delay фазе
        if cultistState == .teleportStart {
            teleportDelayTimer = 0
            removeAction(forKey: "teleportCharge")
            transitionTo(.patrol)
        }

        // Прерываем каст
        if cultistState == .casting {
            cancelCast()
        }

        // Скрываем эффекты
        hideAlertEffect()
        hideCastingEffect()

        super.takeDamage(hitInfo)
    }

    // MARK: - Death

    override func die() {
        // Уничтожаем снаряды
        for projectile in activeProjectiles {
            projectile.destroy()
        }
        activeProjectiles.removeAll()

        // Скрываем эффекты
        hideAlertEffect()
        hideCastingEffect()

        super.die()
    }

    // MARK: - Stomp Override

    override func handleStomp(by player: Player) {
        guard config.canBeStomped && currentState != .dead else { return }

        // Даём отскок
        player.bounce()

        // Эффект сплющивания
        playSquashEffect()

        // Урон
        let stompHitInfo = HitInfo(
            damage: 1,
            knockbackForce: 0,
            knockbackDirection: 0,
            source: player
        )
        takeDamage(stompHitInfo)
    }

    /// Эффект сплющивания
    private func playSquashEffect() {
        removeAllActions()

        let squash = SKAction.group([
            SKAction.scaleX(to: 1.5, duration: 0.1),
            SKAction.scaleY(to: 0.3, duration: 0.1)
        ])

        let fadeAndRemove = SKAction.sequence([
            SKAction.wait(forDuration: 0.2),
            SKAction.fadeOut(withDuration: 0.3),
            SKAction.removeFromParent()
        ])

        run(SKAction.sequence([squash, fadeAndRemove]))
    }
}

// MARK: - CultistProjectile

/// Магический снаряд элитного культиста
/// Тёмно-фиолетовый медленный снаряд
final class CultistProjectile: SKSpriteNode {

    // MARK: - Properties

    /// Урон снаряда
    let damage: Int = 1

    /// Скорость полёта
    private let flySpeed: CGFloat

    /// Время жизни
    private let lifeTime: TimeInterval = 4.0

    /// Направление полёта
    private var direction: CGVector = .zero

    // MARK: - Init

    init(direction: CGVector, speed: CGFloat = 100) {
        self.flySpeed = speed

        // Нормализуем направление
        let length = hypot(direction.dx, direction.dy)
        if length > 0 {
            self.direction = CGVector(dx: direction.dx / length, dy: direction.dy / length)
        }

        // Размер 10x10
        let size = CGSize(width: 10, height: 10)

        // Тёмно-фиолетовый цвет
        let color = SKColor(red: 0.5, green: 0.1, blue: 0.6, alpha: 1.0)

        super.init(texture: nil, color: color, size: size)

        self.name = "cultistProjectile"
        self.zPosition = 15

        setupPhysicsBody()
        setupVisual()
        setupTrailEffect()
        scheduleDestruction()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) не реализован")
    }

    // MARK: - Setup

    private func setupPhysicsBody() {
        let physicsBody = SKPhysicsBody(circleOfRadius: 5)

        physicsBody.isDynamic = true
        physicsBody.allowsRotation = false
        physicsBody.affectedByGravity = false
        physicsBody.friction = 0
        physicsBody.restitution = 0
        physicsBody.linearDamping = 0

        physicsBody.categoryBitMask = PhysicsCategory.enemyProjectile
        physicsBody.collisionBitMask = 0
        physicsBody.contactTestBitMask = PhysicsCategory.player |
                                          PhysicsCategory.ground |
                                          PhysicsCategory.playerAttack

        self.physicsBody = physicsBody
    }

    private func setupVisual() {
        // Внутреннее свечение
        let glow = SKSpriteNode(color: .magenta, size: CGSize(width: 5, height: 5))
        glow.alpha = 0.9
        glow.zPosition = 1
        addChild(glow)

        // Пульсация
        let pulse = SKAction.sequence([
            SKAction.scale(to: 1.3, duration: 0.2),
            SKAction.scale(to: 0.8, duration: 0.2)
        ])
        glow.run(SKAction.repeatForever(pulse))
    }

    private func setupTrailEffect() {
        let trailAction = SKAction.repeatForever(SKAction.sequence([
            SKAction.run { [weak self] in
                self?.spawnTrailParticle()
            },
            SKAction.wait(forDuration: 0.06)
        ]))
        run(trailAction, withKey: "trail")
    }

    private func spawnTrailParticle() {
        guard let parent = self.parent else { return }

        let particle = SKSpriteNode(color: SKColor(red: 0.5, green: 0.1, blue: 0.6, alpha: 0.5),
                                    size: CGSize(width: 5, height: 5))
        particle.position = self.position
        particle.zPosition = self.zPosition - 1
        parent.addChild(particle)

        let fadeAndRemove = SKAction.sequence([
            SKAction.group([
                SKAction.fadeOut(withDuration: 0.25),
                SKAction.scale(to: 0.2, duration: 0.25)
            ]),
            SKAction.removeFromParent()
        ])
        particle.run(fadeAndRemove)
    }

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

    func update(deltaTime: TimeInterval) {
        let velocity = CGVector(
            dx: direction.dx * flySpeed,
            dy: direction.dy * flySpeed
        )
        physicsBody?.velocity = velocity
    }

    // MARK: - Collision

    func handleContact(with body: SKPhysicsBody) {
        if body.categoryBitMask & PhysicsCategory.player != 0 {
            if let player = body.node as? Player {
                let knockbackDirection: CGFloat = direction.dx > 0 ? 1 : -1
                player.takeDamage(damage, knockbackDirection: knockbackDirection, knockbackForce: 150)
            }
            destroy()
        } else if body.categoryBitMask & PhysicsCategory.playerAttack != 0 {
            destroyByAttack()
        } else if body.categoryBitMask & PhysicsCategory.ground != 0 {
            destroy()
        }
    }

    // MARK: - Destruction

    func destroy() {
        removeAction(forKey: "trail")
        removeAction(forKey: "lifeTimer")

        let fadeOut = SKAction.sequence([
            SKAction.fadeOut(withDuration: 0.1),
            SKAction.removeFromParent()
        ])
        run(fadeOut)
    }

    func destroyByAttack() {
        removeAction(forKey: "trail")
        removeAction(forKey: "lifeTimer")

        // Эффект разрушения
        if let parent = self.parent {
            for _ in 0..<6 {
                let particle = SKSpriteNode(color: SKColor(red: 0.5, green: 0.1, blue: 0.6, alpha: 1.0),
                                            size: CGSize(width: 4, height: 4))
                particle.position = self.position
                particle.zPosition = self.zPosition
                parent.addChild(particle)

                let randomAngle = CGFloat.random(in: 0...(2 * .pi))
                let randomSpeed = CGFloat.random(in: 40...80)
                let moveAction = SKAction.move(
                    by: CGVector(dx: cos(randomAngle) * randomSpeed * 0.3,
                                dy: sin(randomAngle) * randomSpeed * 0.3),
                    duration: 0.35
                )

                particle.run(SKAction.sequence([
                    SKAction.group([
                        moveAction,
                        SKAction.fadeOut(withDuration: 0.35)
                    ]),
                    SKAction.removeFromParent()
                ]))
            }
        }

        removeFromParent()
    }
}
