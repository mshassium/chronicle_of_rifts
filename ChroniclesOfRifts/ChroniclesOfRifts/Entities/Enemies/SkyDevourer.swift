import SpriteKit

/// Пожиратель Неба - летающий враг для уровня 6 (Море Осколков)
/// Летает кругами на высоте, пикирует на игрока
/// После промаха - оглушён на земле и уязвим для stomp
final class SkyDevourer: Enemy {

    // MARK: - State

    /// Состояния пожирателя
    private enum SkyDevourerState {
        case patrol         // Летает кругами/восьмёркой на высоте
        case prepareDive    // Подготовка к пике (выбирает точку над игроком)
        case dive           // Пикирует вниз
        case stunned        // Оглушён после удара о землю
        case grab           // Схватил игрока (опционально)
    }

    /// Текущее состояние
    private var devourerState: SkyDevourerState = .patrol

    // MARK: - Config

    /// Скорость полёта (патрулирование)
    private let flySpeed: CGFloat = 100

    /// Скорость пике
    private let diveSpeed: CGFloat = 300

    /// Радиус обнаружения
    private let detectionRadius: CGFloat = 200

    /// Время оглушения после промаха
    private let stunDuration: TimeInterval = 1.0

    /// Время подготовки к пике
    private let prepareDiveDuration: TimeInterval = 0.5

    /// Время захвата игрока
    private let grabDuration: TimeInterval = 2.0

    /// Урон от падения при захвате
    private let grabFallDamage: Int = 1

    /// Высота подъёма при захвате
    private let grabLiftHeight: CGFloat = 100

    // MARK: - Timers

    /// Таймер оглушения
    private var stunTimer: TimeInterval = 0

    /// Таймер подготовки к пике
    private var prepareDiveTimer: TimeInterval = 0

    /// Таймер захвата
    private var grabTimer: TimeInterval = 0

    /// Счётчик атак для освобождения
    private var escapeCounter: Int = 0

    /// Количество атак для освобождения
    private let escapeThreshold: Int = 3

    // MARK: - Patrol

    /// Начальная позиция Y для патрулирования
    private var patrolCenterY: CGFloat = 0

    /// Начальная позиция X для патрулирования
    private var patrolCenterX: CGFloat = 0

    /// Угол для паттерна полёта (восьмёрка)
    private var patrolAngle: CGFloat = 0

    /// Радиус патрулирования по X
    private let patrolRadiusX: CGFloat = 80

    /// Радиус патрулирования по Y
    private let patrolRadiusY: CGFloat = 30

    // MARK: - Dive

    /// Целевая точка пике
    private var diveTarget: CGPoint = .zero

    /// Начальная точка пике
    private var diveStartPosition: CGPoint = .zero

    /// Направление пике (нормализованный вектор)
    private var diveDirection: CGVector = .zero

    // MARK: - Visual

    /// Теневой спрайт под врагом при подготовке к пике
    private var diveShadow: SKSpriteNode?

    // MARK: - Movement

    /// Текущая скорость
    private var devourerVelocity: CGVector = .zero

    // MARK: - Grab

    /// Захваченный игрок
    private weak var grabbedPlayer: Player?

    /// Высота при захвате
    private var grabStartY: CGFloat = 0

    // MARK: - Init

    init() {
        let config = EnemyConfig(
            health: 2,
            damage: 1,
            moveSpeed: 100,
            detectionRange: 200,
            attackRange: 50,
            attackCooldown: 0.5,
            scoreValue: 30,
            canBeStomped: false, // Базово - нет, только когда stunned
            knockbackResistance: 0.3
        )

        super.init(config: config, entityType: "skyDevourer")

        // Размер птицы
        self.size = CGSize(width: 40, height: 24)

        setupVisual()
        setupPhysicsForFlying()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) не реализован")
    }

    // MARK: - Setup

    /// Настройка визуала
    private func setupVisual() {
        // Тёмно-серый цвет тела
        self.color = SKColor(red: 0.3, green: 0.3, blue: 0.35, alpha: 1.0)

        // Фиолетовые глаза
        let eyeSize = CGSize(width: 6, height: 6)
        let eyeColor = SKColor(red: 0.6, green: 0.2, blue: 0.8, alpha: 1.0)

        let leftEye = SKSpriteNode(color: eyeColor, size: eyeSize)
        leftEye.position = CGPoint(x: -8, y: 4)
        leftEye.zPosition = 1
        leftEye.name = "leftEye"
        addChild(leftEye)

        let rightEye = SKSpriteNode(color: eyeColor, size: eyeSize)
        rightEye.position = CGPoint(x: 8, y: 4)
        rightEye.zPosition = 1
        rightEye.name = "rightEye"
        addChild(rightEye)

        // "Крылья" - визуальные треугольники
        let wingColor = SKColor(red: 0.25, green: 0.25, blue: 0.3, alpha: 1.0)

        let leftWing = SKSpriteNode(color: wingColor, size: CGSize(width: 12, height: 8))
        leftWing.position = CGPoint(x: -16, y: 0)
        leftWing.zPosition = -1
        leftWing.name = "leftWing"
        addChild(leftWing)

        let rightWing = SKSpriteNode(color: wingColor, size: CGSize(width: 12, height: 8))
        rightWing.position = CGPoint(x: 16, y: 0)
        rightWing.zPosition = -1
        rightWing.name = "rightWing"
        addChild(rightWing)
    }

    /// Настройка физики для полёта
    private func setupPhysicsForFlying() {
        guard let body = physicsBody else { return }

        // Летающий враг не подвержен гравитации изначально
        body.affectedByGravity = false

        // Не сталкивается с землёй в воздухе
        body.collisionBitMask = 0
    }

    /// Установка начальной позиции патрулирования
    func setupPatrolPosition() {
        patrolCenterX = position.x
        patrolCenterY = position.y
    }

    // MARK: - Update

    override func update(deltaTime: TimeInterval) {
        guard currentState != .dead else { return }

        updateTimers(deltaTime: deltaTime)
        updateDevourerAI(deltaTime: deltaTime)
        updateWingAnimation(deltaTime: deltaTime)

        // Применяем скорость
        physicsBody?.velocity = devourerVelocity
    }

    /// Обновление таймеров
    private func updateTimers(deltaTime: TimeInterval) {
        if stunTimer > 0 {
            stunTimer -= deltaTime
        }

        if prepareDiveTimer > 0 {
            prepareDiveTimer -= deltaTime
        }

        if grabTimer > 0 {
            grabTimer -= deltaTime
        }

        // Угол патрулирования
        patrolAngle += CGFloat(deltaTime) * 1.5
    }

    /// Обновление AI
    private func updateDevourerAI(deltaTime: TimeInterval) {
        switch devourerState {
        case .patrol:
            updatePatrolState(deltaTime: deltaTime)

        case .prepareDive:
            updatePrepareDiveState(deltaTime: deltaTime)

        case .dive:
            updateDiveState(deltaTime: deltaTime)

        case .stunned:
            updateStunnedState(deltaTime: deltaTime)

        case .grab:
            updateGrabState(deltaTime: deltaTime)
        }
    }

    // MARK: - Patrol State

    /// Обновление патрулирования (полёт восьмёркой)
    private func updatePatrolState(deltaTime: TimeInterval) {
        // Паттерн "восьмёрка" (лемниската)
        let x = patrolCenterX + patrolRadiusX * sin(patrolAngle)
        let y = patrolCenterY + patrolRadiusY * sin(patrolAngle * 2)

        // Скорость к целевой точке
        let dx = x - position.x
        let dy = y - position.y

        devourerVelocity = CGVector(dx: dx * 3, dy: dy * 3)

        // Ограничиваем скорость
        let speed = hypot(devourerVelocity.dx, devourerVelocity.dy)
        if speed > flySpeed {
            devourerVelocity.dx = devourerVelocity.dx / speed * flySpeed
            devourerVelocity.dy = devourerVelocity.dy / speed * flySpeed
        }

        // Обновляем направление взгляда
        if devourerVelocity.dx > 0 {
            xScale = abs(xScale)
        } else if devourerVelocity.dx < 0 {
            xScale = -abs(xScale)
        }

        // Проверяем игрока
        if let player = detectPlayer() {
            targetPlayer = player
            transitionTo(.prepareDive)
        }
    }

    // MARK: - Prepare Dive State

    /// Подготовка к пике
    private func updatePrepareDiveState(deltaTime: TimeInterval) {
        // Замираем над игроком
        devourerVelocity = .zero

        // Обновляем позицию тени
        updateDiveShadow()

        if prepareDiveTimer <= 0 {
            transitionTo(.dive)
        }
    }

    // MARK: - Dive State

    /// Пике на игрока
    private func updateDiveState(deltaTime: TimeInterval) {
        // Движемся к цели с ускорением
        let dx = diveTarget.x - position.x
        let dy = diveTarget.y - position.y
        let distance = hypot(dx, dy)

        if distance > 10 {
            // Нормализованное направление
            diveDirection = CGVector(dx: dx / distance, dy: dy / distance)

            // Применяем скорость пике
            devourerVelocity = CGVector(
                dx: diveDirection.dx * diveSpeed,
                dy: diveDirection.dy * diveSpeed
            )

            // Поворот в направлении пике
            let angle = atan2(dy, dx)
            zRotation = angle - CGFloat.pi / 2

            // Проверяем столкновение с игроком
            if let player = targetPlayer {
                let playerDistance = hypot(player.position.x - position.x, player.position.y - position.y)
                if playerDistance < 30 {
                    // Попали в игрока - наносим урон или захватываем
                    if Bool.random() && devourerState != .grab {
                        // 50% шанс захвата
                        startGrab(player: player)
                    } else {
                        // Обычный урон
                        dealContactDamage(to: player)
                        transitionTo(.patrol)
                        resetRotation()
                    }
                    return
                }
            }
        } else {
            // Достигли цели - врезались в землю
            transitionTo(.stunned)
        }
    }

    // MARK: - Stunned State

    /// Оглушённое состояние после промаха
    private func updateStunnedState(deltaTime: TimeInterval) {
        // На земле - гравитация действует
        devourerVelocity.dx = 0

        if stunTimer <= 0 {
            // Восстанавливаемся
            transitionTo(.patrol)
        }
    }

    // MARK: - Grab State

    /// Состояние захвата игрока
    private func updateGrabState(deltaTime: TimeInterval) {
        guard let player = grabbedPlayer else {
            transitionTo(.patrol)
            return
        }

        // Поднимаем игрока вверх
        let targetY = grabStartY + grabLiftHeight
        if position.y < targetY {
            devourerVelocity = CGVector(dx: 0, dy: flySpeed * 0.8)
        } else {
            devourerVelocity = .zero
        }

        // Игрок следует за нами
        player.position = CGPoint(x: position.x, y: position.y - 30)

        // Проверяем освобождение по таймеру
        if grabTimer <= 0 {
            releasePlayer(withDamage: true)
        }
    }

    /// Начало захвата игрока
    private func startGrab(player: Player) {
        grabbedPlayer = player
        grabStartY = position.y
        grabTimer = grabDuration
        escapeCounter = 0

        // Отправляем уведомление о захвате
        NotificationCenter.default.post(
            name: .playerGrabbed,
            object: player,
            userInfo: ["grabber": self]
        )

        transitionTo(.grab)
        resetRotation()
    }

    /// Освобождение игрока
    /// - Parameter withDamage: true если игрок не успел вырваться
    private func releasePlayer(withDamage: Bool) {
        guard let player = grabbedPlayer else { return }

        if withDamage {
            // Бросаем игрока вниз
            player.takeDamage(grabFallDamage, knockbackDirection: 0, knockbackForce: 0)
        }

        // Уведомление об освобождении
        NotificationCenter.default.post(
            name: .playerReleased,
            object: player,
            userInfo: ["grabber": self]
        )

        grabbedPlayer = nil
        transitionTo(.patrol)
    }

    /// Игрок пытается вырваться (вызывается при атаке)
    func playerAttemptEscape() {
        guard devourerState == .grab else { return }

        escapeCounter += 1

        // Встряхивание
        run(SKAction.sequence([
            SKAction.moveBy(x: 5, y: 0, duration: 0.05),
            SKAction.moveBy(x: -10, y: 0, duration: 0.05),
            SKAction.moveBy(x: 5, y: 0, duration: 0.05)
        ]))

        if escapeCounter >= escapeThreshold {
            releasePlayer(withDamage: false)
        }
    }

    // MARK: - State Transitions

    /// Переход в новое состояние
    private func transitionTo(_ newState: SkyDevourerState) {
        guard newState != devourerState else { return }

        // Действия при выходе из текущего состояния
        onExitState(devourerState)

        devourerState = newState

        // Действия при входе в новое состояние
        onEnterState(newState)
    }

    /// Действия при выходе из состояния
    private func onExitState(_ state: SkyDevourerState) {
        switch state {
        case .prepareDive:
            removeDiveShadow()

        case .stunned:
            // Восстанавливаем полёт
            physicsBody?.affectedByGravity = false
            physicsBody?.collisionBitMask = 0

        case .dive:
            resetRotation()

        default:
            break
        }
    }

    /// Действия при входе в состояние
    private func onEnterState(_ state: SkyDevourerState) {
        switch state {
        case .patrol:
            // Восстанавливаем полёт
            physicsBody?.affectedByGravity = false
            physicsBody?.collisionBitMask = 0
            setupPatrolPosition()
            playAnimation(for: .idle)

        case .prepareDive:
            prepareDiveTimer = prepareDiveDuration

            // Выбираем точку пике
            if let player = targetPlayer {
                // Сначала летим к точке над игроком
                let targetX = player.position.x
                let targetY = position.y // Сохраняем высоту

                position = CGPoint(x: position.x, y: position.y)
                diveStartPosition = position

                // Целевая точка - игрок (или чуть ниже для земли)
                diveTarget = CGPoint(x: targetX, y: player.position.y - 20)
            }

            createDiveShadow()
            playAnimation(for: .attack)

        case .dive:
            // Включаем гравитацию для столкновения с землёй
            physicsBody?.collisionBitMask = PhysicsCategory.ground
            playAnimation(for: .attack)

        case .stunned:
            stunTimer = stunDuration
            devourerVelocity = .zero

            // На земле - гравитация действует
            physicsBody?.affectedByGravity = true
            physicsBody?.collisionBitMask = PhysicsCategory.ground

            // Визуальный эффект оглушения
            playStunnedEffect()
            playAnimation(for: .hurt)

        case .grab:
            physicsBody?.affectedByGravity = false
            physicsBody?.collisionBitMask = 0
            playAnimation(for: .idle)
        }
    }

    /// Сброс вращения
    private func resetRotation() {
        run(SKAction.rotate(toAngle: 0, duration: 0.2))
    }

    // MARK: - Visual Effects

    /// Создание тени при подготовке к пике
    private func createDiveShadow() {
        guard diveShadow == nil else { return }
        guard let parentNode = parent else { return }

        // Красная тень на земле
        let shadow = SKSpriteNode(color: SKColor(red: 1.0, green: 0.2, blue: 0.2, alpha: 0.5),
                                   size: CGSize(width: 30, height: 10))
        shadow.name = "diveShadow"
        shadow.zPosition = -10

        // Позиция тени - под целью
        if let player = targetPlayer {
            shadow.position = CGPoint(x: player.position.x, y: player.position.y - 20)
        }

        parentNode.addChild(shadow)
        diveShadow = shadow

        // Пульсация тени
        let pulse = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.8, duration: 0.2),
            SKAction.fadeAlpha(to: 0.4, duration: 0.2)
        ])
        shadow.run(SKAction.repeatForever(pulse))
    }

    /// Обновление позиции тени
    private func updateDiveShadow() {
        guard let shadow = diveShadow, let player = targetPlayer else { return }
        shadow.position = CGPoint(x: player.position.x, y: player.position.y - 20)
    }

    /// Удаление тени
    private func removeDiveShadow() {
        diveShadow?.removeFromParent()
        diveShadow = nil
    }

    /// Эффект оглушения
    private func playStunnedEffect() {
        // Звёздочки над головой
        let starsNode = SKNode()
        starsNode.name = "stunnedStars"
        starsNode.position = CGPoint(x: 0, y: size.height / 2 + 10)

        for i in 0..<3 {
            let star = SKSpriteNode(color: .yellow, size: CGSize(width: 5, height: 5))
            star.position = CGPoint(x: CGFloat(i - 1) * 10, y: 0)
            starsNode.addChild(star)
        }

        addChild(starsNode)

        // Вращение звёздочек
        let rotate = SKAction.rotate(byAngle: CGFloat.pi * 2, duration: 0.5)
        starsNode.run(SKAction.repeatForever(rotate))

        // Удаление после окончания оглушения
        run(SKAction.sequence([
            SKAction.wait(forDuration: stunDuration),
            SKAction.run { [weak starsNode] in
                starsNode?.removeFromParent()
            }
        ]))
    }

    /// Анимация крыльев
    private func updateWingAnimation(deltaTime: TimeInterval) {
        guard devourerState != .stunned else { return }

        let wingAngle = sin(patrolAngle * 8) * 0.3

        if let leftWing = childNode(withName: "leftWing") {
            leftWing.zRotation = wingAngle
        }
        if let rightWing = childNode(withName: "rightWing") {
            rightWing.zRotation = -wingAngle
        }
    }

    // MARK: - Detection

    /// Переопределение поиска игрока
    override func detectPlayer() -> Player? {
        guard let scene = scene else { return nil }

        for child in scene.children {
            if child.name == "gameLayer" {
                for entity in child.children {
                    if let player = entity as? Player {
                        let distance = hypot(player.position.x - position.x, player.position.y - position.y)
                        // Обнаруживаем только если игрок ниже или на одном уровне
                        if distance <= detectionRadius && player.position.y <= position.y + 50 {
                            return player
                        }
                    }
                }
            }
            if let player = child as? Player {
                let distance = hypot(player.position.x - position.x, player.position.y - position.y)
                if distance <= detectionRadius && player.position.y <= position.y + 50 {
                    return player
                }
            }
        }

        return nil
    }

    // MARK: - Combat

    /// Переопределение обработки stomp
    override func handleStomp(by player: Player) {
        // Stomp работает только в оглушённом состоянии
        guard devourerState == .stunned else {
            // Если не оглушён - наносим урон игроку
            dealContactDamage(to: player)
            return
        }

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

    // MARK: - Death

    override func die() {
        // Освобождаем игрока если захвачен
        if grabbedPlayer != nil {
            releasePlayer(withDamage: false)
        }

        // Удаляем тень
        removeDiveShadow()

        super.die()
    }
}

// MARK: - Notifications

extension Notification.Name {
    /// Игрок захвачен летающим врагом
    static let playerGrabbed = Notification.Name("playerGrabbed")

    /// Игрок освобождён от захвата
    static let playerReleased = Notification.Name("playerReleased")
}
