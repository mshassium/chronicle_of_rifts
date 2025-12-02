import SpriteKit

// MARK: - BossState

/// Состояния босса
enum BossState {
    case idle           // Ожидание
    case attacking      // Выполнение атаки
    case transitioning  // Переход между фазами
    case vulnerable     // Окно уязвимости
    case defeated       // Побеждён
}

// MARK: - BossConfig

/// Конфигурация босса
struct BossConfig {
    let health: Int                     // Здоровье
    let damage: Int                     // Урон при контакте
    let moveSpeed: CGFloat              // Скорость движения
    let detectionRange: CGFloat         // Радиус обнаружения игрока
    let attackRange: CGFloat            // Радиус атаки
    let scoreValue: Int                 // Очки за победу
    let size: CGSize                    // Размер спрайта (боссы крупнее)

    /// Конфигурация по умолчанию
    static let `default` = BossConfig(
        health: 20,
        damage: 2,
        moveSpeed: 80,
        detectionRange: 400,
        attackRange: 100,
        scoreValue: 1000,
        size: CGSize(width: 96, height: 96)
    )
}

// MARK: - Boss Class

/// Базовый класс для боссов игры
class Boss: Enemy {

    // MARK: - Properties

    /// Имя босса для отображения в UI
    let bossName: String

    /// Фазы босса (упорядочены по healthThreshold от 1.0 до 0.0)
    private(set) var phases: [BossPhase] = []

    /// Индекс текущей фазы
    private(set) var currentPhaseIndex: Int = 0

    /// Текущее состояние босса
    private(set) var bossState: BossState = .idle

    /// Неуязвимость во время перехода между фазами
    private(set) var isInvulnerableDuringTransition: Bool = false

    /// Текущий выполняемый паттерн атаки
    private(set) var currentPattern: AttackPattern?

    /// Был ли босс обнаружен игроком
    private var hasBeenEncountered: Bool = false

    /// Таймер между атаками
    private var attackCooldownTimer: TimeInterval = 0
    private let baseAttackCooldown: TimeInterval = 1.5

    /// Конфигурация босса
    private let bossConfig: BossConfig

    // MARK: - Visual Elements

    /// Эффект ауры вокруг босса
    private var auraNode: SKShapeNode?

    /// Частицы ауры
    private var auraEmitter: SKEmitterNode?

    // MARK: - Arena

    /// Ссылка на арену босса (для закрытия/открытия выходов)
    weak var arena: BossArena?

    // MARK: - Init

    /// Инициализация босса
    /// - Parameters:
    ///   - bossName: Имя босса
    ///   - config: Конфигурация босса
    ///   - phases: Массив фаз босса
    init(bossName: String, config: BossConfig = .default, phases: [BossPhase] = []) {
        self.bossName = bossName
        self.bossConfig = config

        // Создаём конфигурацию врага на основе конфигурации босса
        let enemyConfig = EnemyConfig(
            health: config.health,
            damage: config.damage,
            moveSpeed: config.moveSpeed,
            detectionRange: config.detectionRange,
            attackRange: config.attackRange,
            attackCooldown: 1.0,
            scoreValue: config.scoreValue,
            canBeStomped: false,            // Боссов нельзя убить прыжком
            knockbackResistance: 0.8        // Высокое сопротивление отбрасыванию
        )

        super.init(config: enemyConfig, entityType: "Boss_\(bossName)")

        // Устанавливаем размер босса
        self.size = config.size
        setupPhysicsBody(size: config.size)

        // Настраиваем фазы
        self.phases = phases.sorted { $0.healthThreshold > $1.healthThreshold }

        // Визуальные эффекты
        setupBossVisuals()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) не реализован")
    }

    // MARK: - Setup

    /// Настройка визуальных эффектов босса
    private func setupBossVisuals() {
        // Цвет босса (тёмно-фиолетовый)
        self.color = SKColor(red: 0.4, green: 0.1, blue: 0.5, alpha: 1.0)

        // Создаём ауру
        setupAura()
    }

    /// Настройка ауры вокруг босса
    private func setupAura() {
        let auraRadius = max(size.width, size.height) * 0.7

        auraNode = SKShapeNode(circleOfRadius: auraRadius)
        auraNode?.strokeColor = .clear
        auraNode?.fillColor = SKColor.purple.withAlphaComponent(0.2)
        auraNode?.zPosition = -1
        auraNode?.name = "bossAura"

        if let aura = auraNode {
            addChild(aura)

            // Пульсация ауры
            let pulse = SKAction.sequence([
                SKAction.scale(to: 1.2, duration: 1.0),
                SKAction.scale(to: 1.0, duration: 1.0)
            ])
            aura.run(SKAction.repeatForever(pulse))
        }

        // Частицы ауры
        setupAuraParticles()
    }

    /// Настройка частиц ауры
    private func setupAuraParticles() {
        auraEmitter = SKEmitterNode()

        guard let emitter = auraEmitter else { return }

        emitter.particleBirthRate = 10
        emitter.particleLifetime = 2.0
        emitter.particleLifetimeRange = 0.5

        emitter.particleColor = .purple
        emitter.particleColorBlendFactor = 1.0
        emitter.particleBlendMode = .add

        emitter.particleSize = CGSize(width: 6, height: 6)
        emitter.particleScale = 1.0
        emitter.particleScaleSpeed = -0.3

        emitter.particleSpeed = 20
        emitter.particleSpeedRange = 10
        emitter.emissionAngleRange = .pi * 2

        emitter.particlePositionRange = CGVector(dx: size.width * 0.6, dy: size.height * 0.6)

        emitter.particleAlpha = 0.8
        emitter.particleAlphaSpeed = -0.4

        emitter.zPosition = -2

        addChild(emitter)
    }

    // MARK: - Phase Management

    /// Добавить фазу босса
    /// - Parameter phase: Фаза для добавления
    func addPhase(_ phase: BossPhase) {
        phases.append(phase)
        phases.sort { $0.healthThreshold > $1.healthThreshold }
    }

    /// Текущая фаза босса
    var currentPhase: BossPhase? {
        guard currentPhaseIndex < phases.count else { return nil }
        return phases[currentPhaseIndex]
    }

    /// Проверка необходимости перехода в следующую фазу
    func checkPhaseTransition() {
        guard bossState != .transitioning && bossState != .defeated else { return }

        let healthPercent = CGFloat(currentHealth) / CGFloat(config.health)

        // Ищем следующую фазу, порог которой мы пересекли
        for (index, phase) in phases.enumerated() {
            if index > currentPhaseIndex && healthPercent <= phase.healthThreshold {
                transitionToPhase(index)
                break
            }
        }
    }

    /// Переход в указанную фазу
    /// - Parameter index: Индекс фазы
    func transitionToPhase(_ index: Int) {
        guard index < phases.count && index != currentPhaseIndex else { return }

        bossState = .transitioning
        isInvulnerableDuringTransition = true

        // Прерываем текущую атаку
        currentPattern = nil
        removeAllActions()

        // Выход из текущей фазы
        currentPhase?.onExit(boss: self)

        // Анимация перехода
        let transitionAnimation = createPhaseTransitionAnimation()

        run(transitionAnimation) { [weak self] in
            guard let self = self else { return }

            self.currentPhaseIndex = index
            self.isInvulnerableDuringTransition = false
            self.bossState = .idle

            // Вход в новую фазу
            self.currentPhase?.onEnter(boss: self)
        }
    }

    /// Создание анимации перехода между фазами
    private func createPhaseTransitionAnimation() -> SKAction {
        // Остановка
        let stop = SKAction.run { [weak self] in
            self?.physicsBody?.velocity = .zero
        }

        // Подъём в воздух
        let rise = SKAction.moveBy(x: 0, y: 30, duration: 0.3)
        rise.timingMode = .easeOut

        // Вспышка
        let flash = SKAction.sequence([
            SKAction.colorize(with: .white, colorBlendFactor: 1.0, duration: 0.2),
            SKAction.colorize(withColorBlendFactor: 0, duration: 0.3)
        ])

        // Возврат
        let descend = SKAction.moveBy(x: 0, y: -30, duration: 0.2)
        descend.timingMode = .easeIn

        // Пауза неуязвимости
        let invulnerabilityPause = SKAction.wait(forDuration: 0.5)

        return SKAction.sequence([
            stop,
            rise,
            flash,
            invulnerabilityPause,
            descend
        ])
    }

    // MARK: - Attack Patterns

    /// Выбор следующего паттерна атаки
    /// - Returns: Выбранный паттерн или nil
    func selectNextPattern() -> AttackPattern? {
        guard let phase = currentPhase else { return nil }
        return phase.selectPattern(currentTime: CACurrentMediaTime())
    }

    /// Выполнение паттерна атаки
    /// - Parameter pattern: Паттерн для выполнения
    func executePattern(_ pattern: AttackPattern) {
        guard let target = targetPlayer, bossState == .idle else { return }

        bossState = .attacking
        currentPattern = pattern

        pattern.execute(target: target, boss: self) { [weak self] in
            guard let self = self else { return }

            self.currentPattern = nil
            self.bossState = .idle
            self.attackCooldownTimer = self.baseAttackCooldown
        }
    }

    /// Показать окно уязвимости
    /// - Parameter duration: Длительность окна уязвимости
    func showVulnerabilityWindow(duration: TimeInterval) {
        bossState = .vulnerable

        // Визуальный эффект уязвимости
        let vulnerableEffect = SKAction.sequence([
            SKAction.colorize(with: .yellow, colorBlendFactor: 0.5, duration: 0.2),
            SKAction.wait(forDuration: duration - 0.4),
            SKAction.colorize(withColorBlendFactor: 0, duration: 0.2)
        ])

        run(vulnerableEffect) { [weak self] in
            self?.bossState = .idle
        }
    }

    // MARK: - Update

    override func update(deltaTime: TimeInterval) {
        guard bossState != .defeated else { return }

        // Обновляем таймеры
        if attackCooldownTimer > 0 {
            attackCooldownTimer -= deltaTime
        }

        // Проверка обнаружения игрока
        if !hasBeenEncountered {
            if let player = detectPlayer() {
                encounterPlayer(player)
            }
        }

        // Логика ИИ босса
        if bossState == .idle && hasBeenEncountered {
            updateBossAI(deltaTime: deltaTime)
        }

        // Базовое обновление (движение, гравитация)
        if bossState != .transitioning {
            super.update(deltaTime: deltaTime)
        }
    }

    /// Обновление ИИ босса
    private func updateBossAI(deltaTime: TimeInterval) {
        guard let target = targetPlayer else { return }

        let distance = hypot(target.position.x - position.x, target.position.y - position.y)

        // Если в радиусе атаки и перезарядка прошла
        if distance <= config.attackRange && attackCooldownTimer <= 0 {
            if let pattern = selectNextPattern() {
                executePattern(pattern)
            }
        } else if distance <= config.detectionRange {
            // Двигаемся к игроку
            moveTowards(point: target.position)
        }
    }

    /// Первая встреча с игроком
    private func encounterPlayer(_ player: Player) {
        hasBeenEncountered = true
        targetPlayer = player

        // Закрываем арену
        arena?.closeArena()

        // Входим в первую фазу
        if let firstPhase = phases.first {
            firstPhase.onEnter(boss: self)
        }

        // Уведомление о встрече с боссом
        NotificationCenter.default.post(
            name: .bossEncountered,
            object: self,
            userInfo: ["bossName": bossName]
        )
    }

    // MARK: - Combat

    override func takeDamage(_ hitInfo: HitInfo) {
        // Игнорируем урон во время перехода между фазами
        guard !isInvulnerableDuringTransition else { return }
        guard bossState != .defeated else { return }

        super.takeDamage(hitInfo)

        // Проверяем переход фазы после получения урона
        checkPhaseTransition()
    }

    override func die() {
        guard bossState != .defeated else { return }

        bossState = .defeated

        // Останавливаем все действия
        removeAllActions()
        currentPattern = nil

        // Отключаем физику
        physicsBody?.isDynamic = false
        physicsBody?.categoryBitMask = 0
        physicsBody?.contactTestBitMask = 0

        // Открываем арену
        arena?.openArena()

        // Эпичная анимация смерти
        let deathAnimation = createBossDeathAnimation()

        run(deathAnimation) { [weak self] in
            guard let self = self else { return }

            // Уведомление о победе над боссом
            NotificationCenter.default.post(
                name: .bossDefeated,
                object: self,
                userInfo: [
                    "bossName": self.bossName,
                    "scoreValue": self.config.scoreValue
                ]
            )

            self.removeFromParent()
        }
    }

    /// Создание анимации смерти босса
    private func createBossDeathAnimation() -> SKAction {
        // Серия взрывов
        let explosionCount = 5
        var explosionActions: [SKAction] = []

        for _ in 0..<explosionCount {
            let explosion = SKAction.run { [weak self] in
                guard let self = self else { return }
                self.createExplosionEffect(at: CGPoint(
                    x: CGFloat.random(in: -self.size.width/3...self.size.width/3),
                    y: CGFloat.random(in: -self.size.height/3...self.size.height/3)
                ))
            }
            explosionActions.append(explosion)
            explosionActions.append(SKAction.wait(forDuration: 0.3))
        }

        // Финальный взрыв
        let finalExplosion = SKAction.run { [weak self] in
            self?.createExplosionEffect(at: .zero, isFinal: true)
        }

        // Исчезновение
        let fadeOut = SKAction.group([
            SKAction.fadeOut(withDuration: 0.5),
            SKAction.scale(to: 1.5, duration: 0.5)
        ])

        return SKAction.sequence(explosionActions + [finalExplosion, fadeOut])
    }

    /// Создание эффекта взрыва
    private func createExplosionEffect(at position: CGPoint, isFinal: Bool = false) {
        let explosion = SKShapeNode(circleOfRadius: isFinal ? 60 : 30)
        explosion.position = position
        explosion.fillColor = isFinal ? .orange : .yellow
        explosion.strokeColor = .clear
        explosion.zPosition = 100
        addChild(explosion)

        let expand = SKAction.scale(to: isFinal ? 3.0 : 2.0, duration: 0.3)
        let fadeOut = SKAction.fadeOut(withDuration: 0.3)
        let remove = SKAction.removeFromParent()

        explosion.run(SKAction.sequence([
            SKAction.group([expand, fadeOut]),
            remove
        ]))
    }

    // MARK: - Helper Methods

    /// Восстановление здоровья (для защитной фазы)
    /// Отправляет уведомление, которое должно обрабатываться в GameScene
    func heal(_ amount: Int) {
        NotificationCenter.default.post(
            name: .bossHealed,
            object: self,
            userInfo: ["healAmount": amount]
        )
    }

    /// Призыв миньонов (для защитной фазы)
    func summonMinions() {
        // Базовая реализация - переопределяется в конкретных боссах
        NotificationCenter.default.post(
            name: .bossSummonMinions,
            object: self,
            userInfo: ["bossPosition": position]
        )
    }

    /// Изменение цвета ауры
    func setAuraColor(_ color: SKColor) {
        auraNode?.fillColor = color.withAlphaComponent(0.2)
        auraEmitter?.particleColor = color
    }

    /// Проверка, атакует ли босс в данный момент
    var isAttacking: Bool {
        return bossState == .attacking
    }

    /// Проверка, уязвим ли босс
    var isVulnerable: Bool {
        return bossState == .vulnerable && !isInvulnerableDuringTransition
    }
}

// MARK: - BossArena

/// Протокол для арены босса
protocol BossArena: AnyObject {
    /// Закрыть выходы из арены
    func closeArena()

    /// Открыть выходы из арены
    func openArena()
}

// MARK: - Notifications

extension Notification.Name {
    /// Уведомление о встрече с боссом
    static let bossEncountered = Notification.Name("bossEncountered")

    /// Уведомление о победе над боссом
    static let bossDefeated = Notification.Name("bossDefeated")

    /// Уведомление о призыве миньонов боссом
    static let bossSummonMinions = Notification.Name("bossSummonMinions")

    /// Уведомление о лечении босса
    static let bossHealed = Notification.Name("bossHealed")
}
