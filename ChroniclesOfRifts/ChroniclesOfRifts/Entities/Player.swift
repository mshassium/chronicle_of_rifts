import SpriteKit

// MARK: - PlayerState Enum

/// Состояния персонажа для конечного автомата
enum PlayerState {
    case idle       // Стоит на месте
    case walking    // Ходьба
    case jumping    // Прыжок вверх
    case falling    // Падение вниз
    case attacking  // Атака мечом
    case hurt       // Получение урона (кратковременно)
    case dead       // Смерть
}

// MARK: - PlayerConfig

/// Конфигурация физических параметров игрока
struct PlayerConfig {
    static let moveSpeed: CGFloat = 200       // пикселей/сек
    static let jumpForce: CGFloat = 450       // импульс прыжка
    static let gravity: CGFloat = -980        // гравитация
    static let maxFallSpeed: CGFloat = -600   // макс. скорость падения
    static let groundFriction: CGFloat = 0.85 // трение при остановке
    static let airControl: CGFloat = 0.7      // контроль в воздухе (множитель)

    // Продвинутая механика прыжка
    static let maxJumpHoldTime: TimeInterval = 0.2   // макс. время удержания прыжка
    static let coyoteTime: TimeInterval = 0.1        // время "койота" после схода с платформы
    static let jumpBufferTime: TimeInterval = 0.1    // буфер прыжка перед приземлением
    static let jumpCutMultiplier: CGFloat = 0.5      // множитель при раннем отпускании прыжка

    // Боевые параметры
    static let attackDuration: TimeInterval = 0.3    // длительность атаки
    static let attackCooldownTime: TimeInterval = 0.4 // перезарядка атаки
    static let hurtDuration: TimeInterval = 0.3      // длительность состояния hurt
    static let invulnerabilityDuration: TimeInterval = 1.5 // неуязвимость после урона

    // Размеры
    static let spriteSize = CGSize(width: 32, height: 64)      // размер спрайта
    static let colliderSize = CGSize(width: 24, height: 48)    // размер коллайдера
}

// MARK: - Player Class

/// Класс игрока - главный персонаж игры Каэль
final class Player: SKSpriteNode {

    // MARK: - State

    /// Текущее состояние персонажа
    private(set) var currentState: PlayerState = .idle

    /// Направление, в которое смотрит персонаж
    private(set) var facingDirection: Direction = .right

    // MARK: - Movement

    /// Текущая скорость персонажа
    private(set) var velocity: CGVector = .zero

    /// Находится ли персонаж на земле
    private var isGrounded: Bool = false

    /// Направление ввода от -1 (влево) до 1 (вправо)
    private var inputDirection: CGFloat = 0

    // MARK: - Jump Mechanics

    /// Удерживается ли кнопка прыжка
    private var isJumpHeld: Bool = false

    /// Время удержания кнопки прыжка
    private var jumpHoldTime: TimeInterval = 0

    /// Время с момента последнего касания земли (для coyote time)
    private var timeSinceGrounded: TimeInterval = 0

    /// Буфер прыжка - время до обнуления
    private var jumpBufferTime: TimeInterval = 0

    /// Был ли уже выполнен прыжок (для предотвращения повторного coyote jump)
    private var hasJumped: Bool = false

    // MARK: - Combat

    /// Таймер перезарядки атаки
    private var attackCooldown: TimeInterval = 0

    /// Таймер состояния атаки
    private var attackTimer: TimeInterval = 0

    /// Таймер состояния получения урона
    private var hurtTimer: TimeInterval = 0

    // MARK: - Health

    /// Максимальное здоровье
    var maxHealth: Int = 3

    /// Текущее здоровье
    private(set) var currentHealth: Int = 3

    /// Неуязвим ли персонаж (после получения урона)
    private(set) var isInvulnerable: Bool = false

    /// Таймер неуязвимости
    private var invulnerabilityTimer: TimeInterval = 0

    // MARK: - Attack Hitbox

    /// Компонент ближней атаки
    private var currentMeleeAttack: MeleeAttack?

    // MARK: - Animation

    /// Текущая проигрываемая анимация
    private var currentAnimation: String = ""

    /// Ключ для действия анимации
    private let animationKey = "playerAnimation"

    // MARK: - Init

    /// Инициализация игрока
    init() {
        // Создаём placeholder спрайт золотистого цвета для Каэля
        let color = SKColor(red: 1.0, green: 0.843, blue: 0.0, alpha: 1.0) // #FFD700
        super.init(texture: nil, color: color, size: PlayerConfig.spriteSize)

        self.name = "player"
        self.zPosition = 10

        setupPhysicsBody()
        setupInitialState()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) не реализован")
    }

    // MARK: - Setup

    /// Настройка физического тела персонажа
    private func setupPhysicsBody() {
        let physicsBody = SKPhysicsBody(rectangleOf: PlayerConfig.colliderSize)

        physicsBody.isDynamic = true
        physicsBody.allowsRotation = false
        physicsBody.friction = 0
        physicsBody.restitution = 0
        physicsBody.linearDamping = 0

        physicsBody.categoryBitMask = PhysicsCategory.player
        physicsBody.collisionBitMask = PhysicsCategory.ground
        physicsBody.contactTestBitMask = PhysicsCategory.enemy |
                                          PhysicsCategory.collectible |
                                          PhysicsCategory.hazard |
                                          PhysicsCategory.trigger

        self.physicsBody = physicsBody
    }

    /// Настройка начального состояния
    private func setupInitialState() {
        currentHealth = maxHealth
        currentState = .idle
        facingDirection = .right
        velocity = .zero
        isGrounded = false

        // Запускаем начальную анимацию
        currentAnimation = ""
        playAnimation(for: .idle)
    }

    // MARK: - Update

    /// Главный метод обновления, вызывается каждый кадр
    /// - Parameter deltaTime: Время с предыдущего кадра
    func update(deltaTime: TimeInterval) {
        guard currentState != .dead else { return }

        updateTimers(deltaTime: deltaTime)
        updateMovement(deltaTime: deltaTime)
        updateJump(deltaTime: deltaTime)
        applyGravity(deltaTime: deltaTime)
        clampVelocity()

        // Применяем скорость к позиции через физику
        physicsBody?.velocity = CGVector(dx: velocity.dx, dy: velocity.dy)

        updateFacingDirection()
        updateStateFromPhysics()
    }

    /// Обновление движения по горизонтали
    private func updateMovement(deltaTime: TimeInterval) {
        guard currentState != .hurt && currentState != .dead else {
            // При получении урона или смерти нет управления
            velocity.dx *= PlayerConfig.groundFriction
            return
        }

        let targetSpeed = inputDirection * PlayerConfig.moveSpeed

        if isGrounded {
            // На земле - полный контроль
            velocity.dx = targetSpeed

            // Применяем трение при остановке
            if abs(inputDirection) < 0.1 {
                velocity.dx *= PlayerConfig.groundFriction
            }
        } else {
            // В воздухе - частичный контроль
            let airSpeed = targetSpeed * PlayerConfig.airControl
            velocity.dx = velocity.dx * (1 - PlayerConfig.airControl) + airSpeed
        }

        // Обновляем состояние walking/idle
        if currentState != .jumping && currentState != .falling && currentState != .attacking {
            if abs(inputDirection) > 0.1 {
                changeState(to: .walking)
            } else {
                changeState(to: .idle)
            }
        }
    }

    /// Обновление логики прыжка
    private func updateJump(deltaTime: TimeInterval) {
        // Variable Jump Height - при удержании кнопки прыжка
        if isJumpHeld && currentState == .jumping && velocity.dy > 0 {
            jumpHoldTime += deltaTime

            // Прекращаем поддержку прыжка после максимального времени
            if jumpHoldTime >= PlayerConfig.maxJumpHoldTime {
                isJumpHeld = false
            }
        }

        // Jump Buffer - проверяем при приземлении
        if isGrounded && jumpBufferTime > 0 {
            performJump()
            jumpBufferTime = 0
        }
    }

    /// Обновление таймеров
    private func updateTimers(deltaTime: TimeInterval) {
        // Coyote time - время с момента схода с платформы
        if !isGrounded {
            timeSinceGrounded += deltaTime
        } else {
            timeSinceGrounded = 0
            hasJumped = false
        }

        // Jump buffer
        if jumpBufferTime > 0 {
            jumpBufferTime -= deltaTime
        }

        // Attack cooldown
        if attackCooldown > 0 {
            attackCooldown -= deltaTime
        }

        // Attack timer
        if currentState == .attacking {
            attackTimer -= deltaTime
            if attackTimer <= 0 {
                endAttack()
            }
        }

        // Hurt timer
        if currentState == .hurt {
            hurtTimer -= deltaTime
            if hurtTimer <= 0 {
                changeState(to: isGrounded ? .idle : .falling)
            }
        }

        // Invulnerability timer
        if isInvulnerable {
            invulnerabilityTimer -= deltaTime

            if invulnerabilityTimer <= 0 {
                isInvulnerable = false
                stopInvulnerabilityEffect()
            }
        }
    }

    // MARK: - Visual Effects

    /// Ключ для действия мигания
    private let invulnerabilityBlinkKey = "invulnerabilityBlink"

    /// Запускает эффект мигания при неуязвимости
    private func startInvulnerabilityEffect() {
        let blink = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.3, duration: 0.1),
            SKAction.fadeAlpha(to: 1.0, duration: 0.1)
        ])
        run(SKAction.repeatForever(blink), withKey: invulnerabilityBlinkKey)
    }

    /// Останавливает эффект мигания при неуязвимости
    private func stopInvulnerabilityEffect() {
        removeAction(forKey: invulnerabilityBlinkKey)
        alpha = 1.0
    }

    /// Применение гравитации
    private func applyGravity(deltaTime: TimeInterval) {
        if !isGrounded {
            velocity.dy += PlayerConfig.gravity * CGFloat(deltaTime)
        }
    }

    /// Ограничение скорости
    private func clampVelocity() {
        // Ограничиваем скорость падения
        if velocity.dy < PlayerConfig.maxFallSpeed {
            velocity.dy = PlayerConfig.maxFallSpeed
        }

        // Ограничиваем горизонтальную скорость
        let maxHorizontalSpeed = PlayerConfig.moveSpeed * 1.5
        velocity.dx = max(-maxHorizontalSpeed, min(maxHorizontalSpeed, velocity.dx))
    }

    /// Обновление состояния на основе физики
    private func updateStateFromPhysics() {
        guard currentState != .attacking && currentState != .hurt && currentState != .dead else {
            return
        }

        if !isGrounded {
            if velocity.dy > 0 {
                changeState(to: .jumping)
            } else {
                changeState(to: .falling)
            }
        }
    }

    // MARK: - State Machine

    /// Смена состояния персонажа
    /// - Parameter newState: Новое состояние
    private func changeState(to newState: PlayerState) {
        guard canTransition(to: newState) else { return }
        guard newState != currentState else { return }

        onStateExit(currentState)
        currentState = newState
        onStateEnter(newState)

        // Запускаем анимацию для нового состояния
        playAnimation(for: newState)
    }

    /// Проверка возможности перехода в новое состояние
    /// - Parameter newState: Целевое состояние
    /// - Returns: true если переход разрешён
    private func canTransition(to newState: PlayerState) -> Bool {
        switch (currentState, newState) {
        // Из dead никуда нельзя перейти
        case (.dead, _):
            return false

        // В dead можно перейти из любого состояния
        case (_, .dead):
            return true

        // В hurt можно перейти если не неуязвим
        case (_, .hurt):
            return !isInvulnerable

        // Из hurt можно только в idle или falling (после таймера)
        case (.hurt, .idle), (.hurt, .falling):
            return true
        case (.hurt, _):
            return false

        // Из attacking можно только после окончания атаки
        case (.attacking, _):
            return attackTimer <= 0

        // Все остальные переходы разрешены
        default:
            return true
        }
    }

    /// Действия при входе в состояние
    /// - Parameter state: Новое состояние
    private func onStateEnter(_ state: PlayerState) {
        switch state {
        case .idle:
            // Остановка анимаций движения
            break

        case .walking:
            // Запуск анимации ходьбы
            break

        case .jumping:
            // Запуск анимации прыжка
            break

        case .falling:
            // Запуск анимации падения
            break

        case .attacking:
            attackTimer = PlayerConfig.attackDuration
            createMeleeAttack()

        case .hurt:
            hurtTimer = PlayerConfig.hurtDuration
            // Небольшой отброс назад
            let knockbackDirection: CGFloat = facingDirection == .right ? -1 : 1
            velocity.dx = knockbackDirection * 100
            velocity.dy = 150

        case .dead:
            // Остановка всего движения
            velocity = .zero
            physicsBody?.velocity = .zero

            // Запуск callback после завершения анимации смерти
            let deathDuration = 6 * 0.12 // 6 кадров по 0.12 сек
            run(SKAction.sequence([
                SKAction.wait(forDuration: deathDuration),
                SKAction.run { [weak self] in
                    self?.onDeathAnimationComplete()
                }
            ]))
        }
    }

    /// Действия при выходе из состояния
    /// - Parameter state: Покидаемое состояние
    private func onStateExit(_ state: PlayerState) {
        switch state {
        case .attacking:
            removeMeleeAttack()

        case .hurt:
            // Активируем неуязвимость после hurt
            isInvulnerable = true
            invulnerabilityTimer = PlayerConfig.invulnerabilityDuration
            startInvulnerabilityEffect()

        default:
            break
        }
    }

    // MARK: - Input

    /// Установить направление движения
    /// - Parameter direction: Значение от -1 (влево) до 1 (вправо)
    func setInputDirection(_ direction: CGFloat) {
        inputDirection = max(-1, min(1, direction))
    }

    /// Выполнить прыжок
    func jump() {
        // Проверяем возможность прыжка
        let canJumpFromGround = isGrounded
        let canCoyoteJump = !hasJumped && timeSinceGrounded < PlayerConfig.coyoteTime

        if canJumpFromGround || canCoyoteJump {
            performJump()
        } else {
            // Jump buffer - запоминаем нажатие прыжка
            jumpBufferTime = PlayerConfig.jumpBufferTime
        }

        isJumpHeld = true
    }

    /// Выполнение прыжка
    private func performJump() {
        guard currentState != .dead && currentState != .hurt else { return }

        velocity.dy = PlayerConfig.jumpForce
        isGrounded = false
        hasJumped = true
        jumpHoldTime = 0
        changeState(to: .jumping)
    }

    /// Отпустить кнопку прыжка (для variable jump height)
    func releaseJump() {
        if isJumpHeld && velocity.dy > 0 {
            // Обрезаем прыжок при раннем отпускании
            velocity.dy *= PlayerConfig.jumpCutMultiplier
        }
        isJumpHeld = false
    }

    /// Выполнить атаку
    func attack() {
        guard currentState != .dead && currentState != .hurt else { return }
        guard attackCooldown <= 0 else { return }

        changeState(to: .attacking)
        attackCooldown = PlayerConfig.attackCooldownTime
    }

    // MARK: - Combat

    /// Создание компонента ближней атаки с использованием MeleeAttack
    private func createMeleeAttack() {
        let meleeAttack = MeleeAttack(config: .playerSword, owner: self)
        addChild(meleeAttack)
        meleeAttack.execute(direction: facingDirection)
        currentMeleeAttack = meleeAttack
    }

    /// Удаление компонента ближней атаки
    private func removeMeleeAttack() {
        currentMeleeAttack?.removeFromParent()
        currentMeleeAttack = nil
    }

    /// Завершение атаки
    private func endAttack() {
        removeMeleeAttack()

        // Возвращаемся в соответствующее состояние
        if isGrounded {
            changeState(to: abs(inputDirection) > 0.1 ? .walking : .idle)
        } else {
            changeState(to: velocity.dy > 0 ? .jumping : .falling)
        }
    }

    /// Нанести урон игроку
    /// - Parameters:
    ///   - amount: Количество урона
    ///   - knockbackDirection: Направление отбрасывания (-1 влево, 1 вправо)
    ///   - knockbackForce: Сила отбрасывания
    func takeDamage(_ amount: Int, knockbackDirection: CGFloat = 0, knockbackForce: CGFloat = 200) {
        // Проверка неуязвимости
        guard !isInvulnerable && currentState != .dead else { return }

        // Применить урон
        currentHealth = max(0, currentHealth - amount)

        // Отбрасывание
        velocity.dx = knockbackDirection * knockbackForce
        velocity.dy = knockbackForce * 0.5  // Небольшой подброс

        // Эффекты
        playDamageEffects()

        // Проверка смерти
        if currentHealth <= 0 {
            die()
        } else {
            // Переход в состояние hurt
            changeState(to: .hurt)

            // Временная неуязвимость
            startInvulnerability()
        }

        // Уведомление
        NotificationCenter.default.post(name: .playerDamaged, object: self, userInfo: ["health": currentHealth])
    }

    /// Воспроизводит эффекты при получении урона
    private func playDamageEffects() {
        // Тряска камеры (через уведомление)
        NotificationCenter.default.post(name: .requestCameraShake, object: nil, userInfo: ["intensity": 5.0, "duration": 0.2])

        // Красная вспышка
        let flashNode = SKSpriteNode(color: .red, size: size)
        flashNode.alpha = 0.5
        flashNode.zPosition = 50
        addChild(flashNode)

        flashNode.run(SKAction.sequence([
            SKAction.fadeOut(withDuration: 0.2),
            SKAction.removeFromParent()
        ]))
    }

    /// Начинает период неуязвимости после получения урона
    private func startInvulnerability() {
        isInvulnerable = true
        invulnerabilityTimer = PlayerConfig.invulnerabilityDuration
        startInvulnerabilityEffect()
    }

    /// Восстановить здоровье
    /// - Parameter amount: Количество восстанавливаемого здоровья
    func heal(_ amount: Int) {
        currentHealth = min(currentHealth + amount, maxHealth)
    }

    /// Смерть персонажа
    func die() {
        guard currentState != .dead else { return }

        changeState(to: .dead)

        // Остановить физику игрока
        physicsBody?.velocity = .zero
        physicsBody?.isDynamic = false

        // Уведомление о смерти
        NotificationCenter.default.post(name: .playerDied, object: self)
    }

    /// Отскок (при прыжке на врага)
    func bounce() {
        velocity.dy = PlayerConfig.jumpForce * 0.7
        isGrounded = false
        changeState(to: .jumping)
    }

    /// Callback после завершения анимации смерти
    private func onDeathAnimationComplete() {
        guard currentState == .dead else { return }

        // Уведомляем о завершении анимации смерти (обрабатывается в GameScene)
        NotificationCenter.default.post(name: .playerDeathAnimationComplete, object: self)
    }

    // MARK: - Animation

    /// Проигрывает анимацию для текущего состояния
    private func playAnimation(for state: PlayerState) {
        let animationName = animationNameFor(state)

        // Не перезапускать ту же анимацию
        guard animationName != currentAnimation else { return }
        currentAnimation = animationName

        // Остановить предыдущую
        removeAction(forKey: animationKey)

        // Получить и запустить новую
        if let action = AnimationManager.shared.createAnimationAction(
            name: animationName,
            for: "player"
        ) {
            run(action, withKey: animationKey)
        }
    }

    /// Маппинг состояния на имя анимации
    private func animationNameFor(_ state: PlayerState) -> String {
        switch state {
        case .idle: return "idle"
        case .walking: return "walk"
        case .jumping: return "jump"
        case .falling: return "fall"
        case .attacking: return "attack"
        case .hurt: return "hurt"
        case .dead: return "death"
        }
    }

    // MARK: - Ground Detection

    /// Установить состояние "на земле"
    /// - Parameter grounded: Находится ли персонаж на земле
    func setGrounded(_ grounded: Bool) {
        let wasGrounded = isGrounded
        isGrounded = grounded

        // При приземлении
        if grounded && !wasGrounded {
            // Сбрасываем вертикальную скорость
            velocity.dy = 0

            // Меняем состояние если были в воздухе
            if currentState == .jumping || currentState == .falling {
                changeState(to: abs(inputDirection) > 0.1 ? .walking : .idle)
            }
        }
    }

    // MARK: - Helpers

    /// Обновление направления взгляда персонажа
    private func updateFacingDirection() {
        if inputDirection > 0.1 {
            facingDirection = .right
            xScale = abs(xScale)
        } else if inputDirection < -0.1 {
            facingDirection = .left
            xScale = -abs(xScale)
        }
    }

    /// Сброс персонажа в начальное состояние
    func reset() {
        setupInitialState()
        isInvulnerable = false
        invulnerabilityTimer = 0
        attackCooldown = 0
        jumpBufferTime = 0
        timeSinceGrounded = 0
        stopInvulnerabilityEffect()
    }
}

// MARK: - Notifications

extension Notification.Name {
    /// Уведомление о получении урона игроком
    static let playerDamaged = Notification.Name("playerDamaged")

    /// Уведомление о смерти игрока
    static let playerDied = Notification.Name("playerDied")

    /// Уведомление о завершении анимации смерти
    static let playerDeathAnimationComplete = Notification.Name("playerDeathAnimationComplete")

    /// Запрос тряски камеры
    static let requestCameraShake = Notification.Name("requestCameraShake")
}
