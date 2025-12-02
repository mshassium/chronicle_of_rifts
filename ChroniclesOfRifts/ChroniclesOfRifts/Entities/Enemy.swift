import SpriteKit

// MARK: - EnemyState Enum

/// Состояния врага для конечного автомата
enum EnemyState {
    case idle       // Стоит на месте
    case patrol     // Патрулирует между точками
    case chase      // Преследует игрока
    case attack     // Атакует
    case hurt       // Получил урон
    case dead       // Мёртв
}

// MARK: - EnemyConfig

/// Конфигурация параметров врага
struct EnemyConfig {
    let health: Int                     // Здоровье
    let damage: Int                     // Урон при контакте
    let moveSpeed: CGFloat              // Скорость движения (пикс/сек)
    let detectionRange: CGFloat         // Радиус обнаружения игрока
    let attackRange: CGFloat            // Радиус атаки
    let attackCooldown: TimeInterval    // Перезарядка атаки
    let scoreValue: Int                 // Очки за убийство
    let canBeStomped: Bool              // Можно ли убить прыжком сверху
    let knockbackResistance: CGFloat    // Сопротивление отбрасыванию (0-1)

    /// Конфигурация по умолчанию для базового врага
    static let `default` = EnemyConfig(
        health: 1,
        damage: 1,
        moveSpeed: 60,
        detectionRange: 200,
        attackRange: 40,
        attackCooldown: 1.0,
        scoreValue: 100,
        canBeStomped: true,
        knockbackResistance: 0.0
    )

    /// Конфигурация для культиста
    static let cultist = EnemyConfig(
        health: 1,
        damage: 1,
        moveSpeed: 80,
        detectionRange: 150,
        attackRange: 30,
        attackCooldown: 1.0,
        scoreValue: 10,
        canBeStomped: true,
        knockbackResistance: 0.0
    )

    /// Конфигурация для летающего глаза
    static let floatingEye = EnemyConfig(
        health: 1,
        damage: 1,
        moveSpeed: 100,
        detectionRange: 300,
        attackRange: 30,
        attackCooldown: 0.8,
        scoreValue: 100,
        canBeStomped: false,
        knockbackResistance: 0.0
    )
}

// MARK: - Enemy Class

/// Базовый класс врага
class Enemy: SKSpriteNode {

    // MARK: - Properties

    /// Тип врага (строковый идентификатор)
    let entityType: String

    /// Конфигурация врага
    let config: EnemyConfig

    /// Текущее состояние врага
    private(set) var currentState: EnemyState = .idle

    /// Направление, в которое смотрит враг
    private(set) var facingDirection: Direction = .right

    /// Текущая скорость врага
    private(set) var velocity: CGVector = .zero

    /// Находится ли враг на земле
    private(set) var isGrounded: Bool = false

    /// Текущее здоровье
    private(set) var currentHealth: Int

    /// Путь патрулирования
    var patrolPath: [CGPoint]?

    /// Текущий индекс в пути патрулирования
    private var currentPatrolIndex: Int = 0

    /// Ссылка на игрока (weak для избежания retain cycle)
    weak var targetPlayer: Player?

    // MARK: - Timers

    /// Таймер атаки (перезарядка)
    private var attackCooldownTimer: TimeInterval = 0

    /// Таймер состояния hurt
    private var hurtTimer: TimeInterval = 0
    private let hurtDuration: TimeInterval = 0.3

    /// Таймер ожидания в idle
    private var idleWaitTimer: TimeInterval = 0
    private let idleWaitDuration: TimeInterval = 1.0

    // MARK: - Animation

    /// Текущая проигрываемая анимация
    private var currentAnimation: String = ""

    /// Ключ для действия анимации
    private let animationKey = "enemyAnimation"

    // MARK: - Health Bar

    /// Индикатор здоровья (для врагов с HP > 1)
    private var healthBar: SKSpriteNode?
    private var healthBarBackground: SKSpriteNode?

    // MARK: - Physics Constants

    private let gravity: CGFloat = -980
    private let maxFallSpeed: CGFloat = -600

    // MARK: - Init

    /// Инициализация врага
    /// - Parameters:
    ///   - config: Конфигурация врага
    ///   - entityType: Тип врага (строковый идентификатор)
    init(config: EnemyConfig, entityType: String) {
        self.config = config
        self.entityType = entityType
        self.currentHealth = config.health

        // Размер по умолчанию (можно переопределить в подклассах)
        let defaultSize = CGSize(width: 32, height: 32)

        // Placeholder красного цвета для врагов
        let color = SKColor(red: 0.8, green: 0.2, blue: 0.2, alpha: 1.0)

        super.init(texture: nil, color: color, size: defaultSize)

        self.name = "enemy_\(entityType)"
        self.zPosition = 10

        setupPhysicsBody(size: defaultSize)
        setupHealthBar()
        subscribeToNotifications()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) не реализован")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Setup

    /// Настройка физического тела врага
    /// - Parameter size: Размер коллайдера
    func setupPhysicsBody(size: CGSize) {
        let colliderSize = CGSize(width: size.width * 0.8, height: size.height * 0.9)
        let physicsBody = SKPhysicsBody(rectangleOf: colliderSize)

        physicsBody.isDynamic = true
        physicsBody.allowsRotation = false
        physicsBody.friction = 0
        physicsBody.restitution = 0
        physicsBody.linearDamping = 0

        physicsBody.categoryBitMask = PhysicsCategory.enemy
        physicsBody.collisionBitMask = PhysicsCategory.ground
        physicsBody.contactTestBitMask = PhysicsCategory.player | PhysicsCategory.playerAttack

        self.physicsBody = physicsBody
    }

    /// Настройка индикатора здоровья
    private func setupHealthBar() {
        guard config.health > 1 else { return }

        let barWidth: CGFloat = size.width
        let barHeight: CGFloat = 4
        let yOffset: CGFloat = size.height / 2 + 8

        // Фон полоски здоровья
        healthBarBackground = SKSpriteNode(color: .darkGray, size: CGSize(width: barWidth, height: barHeight))
        healthBarBackground?.position = CGPoint(x: 0, y: yOffset)
        healthBarBackground?.zPosition = 50
        addChild(healthBarBackground!)

        // Полоска здоровья
        healthBar = SKSpriteNode(color: .green, size: CGSize(width: barWidth, height: barHeight))
        healthBar?.anchorPoint = CGPoint(x: 0, y: 0.5)
        healthBar?.position = CGPoint(x: -barWidth / 2, y: yOffset)
        healthBar?.zPosition = 51
        addChild(healthBar!)
    }

    /// Обновление индикатора здоровья
    private func updateHealthBar() {
        guard let healthBar = healthBar else { return }

        let healthPercent = CGFloat(currentHealth) / CGFloat(config.health)
        let barWidth = size.width * healthPercent

        healthBar.size.width = barWidth

        // Меняем цвет в зависимости от здоровья
        if healthPercent > 0.5 {
            healthBar.color = .green
        } else if healthPercent > 0.25 {
            healthBar.color = .yellow
        } else {
            healthBar.color = .red
        }
    }

    /// Подписка на уведомления
    private func subscribeToNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleEntityHit(_:)),
            name: .entityHit,
            object: nil
        )
    }

    // MARK: - Update

    /// Главный метод обновления, вызывается каждый кадр
    /// - Parameter deltaTime: Время с предыдущего кадра
    func update(deltaTime: TimeInterval) {
        guard currentState != .dead else { return }

        updateTimers(deltaTime: deltaTime)
        updateAI(deltaTime: deltaTime)
        applyGravity(deltaTime: deltaTime)
        clampVelocity()

        // Применяем скорость к позиции через физику
        physicsBody?.velocity = CGVector(dx: velocity.dx, dy: velocity.dy)

        updateFacingDirection()
    }

    /// Обновление таймеров
    private func updateTimers(deltaTime: TimeInterval) {
        // Attack cooldown
        if attackCooldownTimer > 0 {
            attackCooldownTimer -= deltaTime
        }

        // Hurt timer
        if currentState == .hurt {
            hurtTimer -= deltaTime
            if hurtTimer <= 0 {
                changeState(to: .idle)
            }
        }

        // Idle wait timer
        if currentState == .idle {
            idleWaitTimer -= deltaTime
        }
    }

    /// Обновление ИИ врага
    private func updateAI(deltaTime: TimeInterval) {
        switch currentState {
        case .idle:
            updateIdle(deltaTime: deltaTime)

        case .patrol:
            updatePatrol(deltaTime: deltaTime)

        case .chase:
            if let player = targetPlayer {
                updateChase(deltaTime: deltaTime, target: player)
            } else {
                changeState(to: .patrol)
            }

        case .attack:
            updateAttack(deltaTime: deltaTime)

        case .hurt, .dead:
            // В этих состояниях ИИ не обновляется
            velocity.dx = velocity.dx * 0.9 // Торможение
            break
        }
    }

    /// Обновление состояния idle
    private func updateIdle(deltaTime: TimeInterval) {
        velocity.dx = 0

        // Проверяем игрока в радиусе обнаружения
        if let player = detectPlayer() {
            targetPlayer = player
            changeState(to: .chase)
            return
        }

        // Переход к патрулированию после ожидания
        if patrolPath != nil && idleWaitTimer <= 0 {
            changeState(to: .patrol)
        }
    }

    /// Применение гравитации
    private func applyGravity(deltaTime: TimeInterval) {
        if !isGrounded {
            velocity.dy += gravity * CGFloat(deltaTime)
        }
    }

    /// Ограничение скорости
    private func clampVelocity() {
        if velocity.dy < maxFallSpeed {
            velocity.dy = maxFallSpeed
        }

        // Ограничение горизонтальной скорости
        let maxHorizontalSpeed = config.moveSpeed * 1.5
        velocity.dx = max(-maxHorizontalSpeed, min(maxHorizontalSpeed, velocity.dx))
    }

    // MARK: - State Machine

    /// Смена состояния врага
    /// - Parameter newState: Новое состояние
    func changeState(to newState: EnemyState) {
        guard canTransition(to: newState) else { return }
        guard newState != currentState else { return }

        onStateExit(currentState)
        currentState = newState
        onStateEnter(newState)

        playAnimation(for: newState)
    }

    /// Проверка возможности перехода в новое состояние
    /// - Parameter newState: Целевое состояние
    /// - Returns: true если переход разрешён
    func canTransition(to newState: EnemyState) -> Bool {
        switch (currentState, newState) {
        // Из dead никуда нельзя перейти
        case (.dead, _):
            return false

        // В dead можно перейти из любого состояния
        case (_, .dead):
            return true

        // В hurt можно перейти из любого состояния кроме dead
        case (_, .hurt):
            return currentState != .dead

        // Из hurt можно только в idle (после таймера)
        case (.hurt, .idle):
            return true
        case (.hurt, _):
            return false

        // Все остальные переходы разрешены
        default:
            return true
        }
    }

    /// Действия при входе в состояние
    /// - Parameter state: Новое состояние
    func onStateEnter(_ state: EnemyState) {
        switch state {
        case .idle:
            velocity.dx = 0
            idleWaitTimer = idleWaitDuration

        case .patrol:
            break

        case .chase:
            break

        case .attack:
            performAttack()

        case .hurt:
            hurtTimer = hurtDuration

        case .dead:
            velocity = .zero
            physicsBody?.velocity = .zero
            die()
        }
    }

    /// Действия при выходе из состояния
    /// - Parameter state: Покидаемое состояние
    func onStateExit(_ state: EnemyState) {
        switch state {
        case .attack:
            attackCooldownTimer = config.attackCooldown

        default:
            break
        }
    }

    // MARK: - Detection & AI

    /// Поиск игрока в радиусе обнаружения
    /// - Returns: Ссылка на игрока, если найден в радиусе
    func detectPlayer() -> Player? {
        guard let scene = scene else { return nil }

        for child in scene.children {
            if let gameLayer = child as? SKNode, gameLayer.name == "gameLayer" {
                for entity in gameLayer.children {
                    if let player = entity as? Player {
                        let distance = hypot(player.position.x - position.x, player.position.y - position.y)
                        if distance <= config.detectionRange && canSeePlayer(player) {
                            return player
                        }
                    }
                }
            }
            // Также проверяем если игрок напрямую в сцене
            if let player = child as? Player {
                let distance = hypot(player.position.x - position.x, player.position.y - position.y)
                if distance <= config.detectionRange && canSeePlayer(player) {
                    return player
                }
            }
        }

        return nil
    }

    /// Проверка видимости игрока (без препятствий)
    /// - Parameter player: Игрок
    /// - Returns: true если игрок виден
    func canSeePlayer(_ player: Player) -> Bool {
        // Базовая проверка - игрок должен быть примерно на том же уровне
        let verticalDiff = abs(player.position.y - position.y)
        let maxVerticalDiff: CGFloat = 100

        guard verticalDiff < maxVerticalDiff else { return false }

        // Проверяем, смотрит ли враг в сторону игрока
        let playerIsRight = player.position.x > position.x

        // Враг видит игрока если тот перед ним или враг в режиме преследования
        if currentState == .chase {
            return true
        }

        return (facingDirection == .right && playerIsRight) ||
               (facingDirection == .left && !playerIsRight)
    }

    /// Движение к точке
    /// - Parameter point: Целевая точка
    func moveTowards(point: CGPoint) {
        let direction = point.x > position.x ? 1.0 : -1.0
        velocity.dx = CGFloat(direction) * config.moveSpeed

        // Обновляем направление взгляда
        facingDirection = direction > 0 ? .right : .left
    }

    /// Разворот врага
    func turnAround() {
        facingDirection = facingDirection == .right ? .left : .right
        velocity.dx = -velocity.dx
    }

    /// Проверка края платформы
    /// - Returns: true если впереди край
    func checkEdge() -> Bool {
        guard let scene = scene else { return false }

        // Точка проверки перед врагом
        let checkOffset: CGFloat = facingDirection == .right ? size.width / 2 + 5 : -size.width / 2 - 5
        let checkPoint = CGPoint(x: position.x + checkOffset, y: position.y - size.height / 2 - 10)

        // Проверяем наличие земли под точкой
        let bodies = scene.physicsWorld.body(at: checkPoint)

        return bodies?.categoryBitMask != PhysicsCategory.ground
    }

    // MARK: - Patrol

    /// Обновление патрулирования
    func updatePatrol(deltaTime: TimeInterval) {
        // Проверяем игрока
        if let player = detectPlayer() {
            targetPlayer = player
            changeState(to: .chase)
            return
        }

        // Проверяем край платформы
        if checkEdge() {
            turnAround()
            return
        }

        // Движение к следующей точке патрулирования
        if let targetPoint = getNextPatrolPoint() {
            moveTowards(point: targetPoint)

            // Проверяем достижение точки
            let distance = abs(position.x - targetPoint.x)
            if distance < 10 {
                currentPatrolIndex = (currentPatrolIndex + 1) % (patrolPath?.count ?? 1)
                changeState(to: .idle)
            }
        } else {
            // Если нет пути, просто ходим туда-сюда
            velocity.dx = facingDirection == .right ? config.moveSpeed : -config.moveSpeed
        }
    }

    /// Получить следующую точку патрулирования
    /// - Returns: Следующая точка или nil
    func getNextPatrolPoint() -> CGPoint? {
        guard let path = patrolPath, !path.isEmpty else { return nil }
        return path[currentPatrolIndex]
    }

    // MARK: - Chase

    /// Обновление преследования
    func updateChase(deltaTime: TimeInterval, target: Player) {
        let distance = hypot(target.position.x - position.x, target.position.y - position.y)

        // Если игрок вне радиуса обнаружения, прекращаем преследование
        if distance > config.detectionRange * 1.5 {
            targetPlayer = nil
            changeState(to: .patrol)
            return
        }

        // Если в радиусе атаки - атакуем
        if distance <= config.attackRange && attackCooldownTimer <= 0 {
            changeState(to: .attack)
            return
        }

        // Иначе двигаемся к игроку
        moveTowards(point: target.position)

        // Проверяем край платформы - враги не падают с платформ при преследовании
        if checkEdge() {
            velocity.dx = 0
        }
    }

    // MARK: - Combat

    /// Выполнение атаки
    private func performAttack() {
        // Базовая реализация - контактный урон
        // Подклассы могут переопределить для дальнобойных атак

        // Возврат в idle после короткой паузы
        run(SKAction.sequence([
            SKAction.wait(forDuration: 0.3),
            SKAction.run { [weak self] in
                self?.changeState(to: .idle)
            }
        ]))
    }

    /// Обновление состояния атаки
    private func updateAttack(deltaTime: TimeInterval) {
        velocity.dx = 0
    }

    /// Обработка уведомления о попадании
    @objc private func handleEntityHit(_ notification: Notification) {
        // Проверяем, что попали именно в нас
        guard notification.object as? SKNode === self else { return }

        if let hitInfo = notification.userInfo?["hitInfo"] as? HitInfo {
            takeDamage(hitInfo)
        }
    }

    /// Получение урона
    /// - Parameter hitInfo: Информация об ударе
    func takeDamage(_ hitInfo: HitInfo) {
        guard currentState != .dead else { return }

        // Применяем урон
        currentHealth = max(0, currentHealth - hitInfo.damage)

        // Отбрасывание с учётом сопротивления
        let knockbackMultiplier = 1.0 - config.knockbackResistance
        velocity.dx = hitInfo.knockbackDirection * hitInfo.knockbackForce * knockbackMultiplier
        velocity.dy = hitInfo.knockbackForce * 0.3 * knockbackMultiplier

        // Визуальные эффекты
        playDamageEffects()
        updateHealthBar()

        // Проверка смерти
        if currentHealth <= 0 {
            changeState(to: .dead)
        } else {
            changeState(to: .hurt)
        }
    }

    /// Воспроизводит эффекты при получении урона
    private func playDamageEffects() {
        // Красная вспышка
        let originalColor = self.color
        run(SKAction.sequence([
            SKAction.colorize(with: .white, colorBlendFactor: 0.8, duration: 0.05),
            SKAction.colorize(with: originalColor, colorBlendFactor: 1.0, duration: 0.1)
        ]))
    }

    /// Смерть врага
    func die() {
        // Отключаем физику
        physicsBody?.isDynamic = false
        physicsBody?.categoryBitMask = 0
        physicsBody?.contactTestBitMask = 0

        // Анимация смерти
        let deathAnimation = SKAction.sequence([
            SKAction.group([
                SKAction.fadeOut(withDuration: 0.5),
                SKAction.scale(to: 0.5, duration: 0.5),
                SKAction.rotate(byAngle: CGFloat.pi, duration: 0.5)
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

    /// Нанесение контактного урона игроку
    /// - Parameter player: Игрок
    func dealContactDamage(to player: Player) {
        guard currentState != .dead && currentState != .hurt else { return }

        let knockbackDirection: CGFloat = player.position.x > position.x ? 1 : -1
        player.takeDamage(config.damage, knockbackDirection: knockbackDirection, knockbackForce: 200)
    }

    /// Обработка прыжка игрока сверху (stomp)
    /// - Parameter player: Игрок, который прыгнул на врага
    func handleStomp(by player: Player) {
        guard config.canBeStomped && currentState != .dead else { return }

        // Даём игроку отскок
        player.bounce()

        // Наносим урон врагу
        let stompHitInfo = HitInfo(
            damage: 1,
            knockbackForce: 0,
            knockbackDirection: 0,
            source: player
        )
        takeDamage(stompHitInfo)
    }

    // MARK: - Animation

    /// Проигрывает анимацию для текущего состояния
    func playAnimation(for state: EnemyState) {
        let animationName = getAnimationName(for: state)

        guard animationName != currentAnimation else { return }
        currentAnimation = animationName

        removeAction(forKey: animationKey)

        if let action = AnimationManager.shared.createAnimationAction(
            name: animationName,
            for: entityType
        ) {
            run(action, withKey: animationKey)
        }
    }

    /// Маппинг состояния на имя анимации
    func getAnimationName(for state: EnemyState) -> String {
        switch state {
        case .idle: return "idle"
        case .patrol: return "walk"
        case .chase: return "walk"
        case .attack: return "attack"
        case .hurt: return "hurt"
        case .dead: return "death"
        }
    }

    // MARK: - Ground Detection

    /// Установить состояние "на земле"
    /// - Parameter grounded: Находится ли враг на земле
    func setGrounded(_ grounded: Bool) {
        let wasGrounded = isGrounded
        isGrounded = grounded

        if grounded && !wasGrounded {
            velocity.dy = 0
        }
    }

    // MARK: - Helpers

    /// Обновление направления взгляда
    private func updateFacingDirection() {
        if velocity.dx > 0.1 {
            facingDirection = .right
            xScale = abs(xScale)
        } else if velocity.dx < -0.1 {
            facingDirection = .left
            xScale = -abs(xScale)
        }
    }

    /// Установка начального направления
    /// - Parameter direction: Направление взгляда
    func setFacingDirection(_ direction: Direction) {
        facingDirection = direction
        xScale = direction == .right ? abs(xScale) : -abs(xScale)
    }
}

// MARK: - Notifications

extension Notification.Name {
    /// Уведомление о смерти врага
    static let enemyDied = Notification.Name("enemyDied")
}
