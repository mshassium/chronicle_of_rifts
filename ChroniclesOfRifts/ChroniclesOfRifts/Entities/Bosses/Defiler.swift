import SpriteKit

// MARK: - DefilerConfig

/// Конфигурация босса Defiler
struct DefilerConfig {
    static let health: Int = 100
    static let contactDamage: Int = 1
    static let attackDamage: Int = 1
    static let size = CGSize(width: 48, height: 64)
    static let baseSpeed: CGFloat = 80
    static let phase2SpeedMultiplier: CGFloat = 1.3

    // Cooldowns
    static let jumpSlamCooldown: TimeInterval = 3.0
    static let slashComboCooldown: TimeInterval = 4.0
    static let summonMinionsCooldown: TimeInterval = 8.0

    // Combat
    static let maxMinions: Int = 4
    static let minionsPerSummon: Int = 2
    static let slashComboWindow: TimeInterval = 0.3
    static let postComboPause: TimeInterval = 1.0
}

// MARK: - Defiler Boss

/// Defiler — первый босс игры (уровень 1)
/// Бывший страж, обращённый тьмой. Друг детства Каэля.
/// Обучающий босс — учит механикам боссов
final class Defiler: Boss {

    // MARK: - Properties

    /// Количество активных миньонов
    private var activeMinionsCount: Int = 0

    /// Находится ли босс во второй фазе
    private var isPhase2: Bool = false

    /// Таймер для JumpSlam
    private var jumpSlamCooldownTimer: TimeInterval = 0

    /// Таймер для SlashCombo
    private var slashComboCooldownTimer: TimeInterval = 0

    /// Таймер для SummonMinions
    private var summonMinionsCooldownTimer: TimeInterval = 0

    /// Границы арены
    var arenaBounds: CGRect = .zero

    // MARK: - Dialog

    /// Диалог перед боем
    static let preDialogue = "Каэль... прости... я не могу... контролировать..."

    /// Диалог при переходе в фазу 2
    static let phase2Dialogue = "БОЛЬШЕ! СИЛЫ!"

    /// Диалог при смерти
    static let deathDialogue = "Спасибо... друг..."

    // MARK: - Init

    init() {
        // Конфигурация босса
        let bossConfig = BossConfig(
            health: DefilerConfig.health,
            damage: DefilerConfig.contactDamage,
            moveSpeed: DefilerConfig.baseSpeed,
            detectionRange: 400,
            attackRange: 150,
            scoreValue: 500,
            size: DefilerConfig.size
        )

        // Создаём фазы
        let phase1 = DefilerPhase1()
        let phase2 = DefilerPhase2()

        super.init(bossName: "Осквернитель", config: bossConfig, phases: [phase1, phase2])

        // Настраиваем визуал
        setupDefilerVisuals()

        // Подписываемся на уведомления о смерти миньонов
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMinionDied(_:)),
            name: .enemyDied,
            object: nil
        )
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) не реализован")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Setup

    /// Настройка визуальных эффектов Defiler
    private func setupDefilerVisuals() {
        // Тёмно-серый с фиолетовыми прожилками
        self.color = SKColor(red: 0.3, green: 0.25, blue: 0.35, alpha: 1.0)

        // Добавляем "прожилки скверны"
        addCorruptionVeins()

        // Светящиеся глаза
        addGlowingEyes()

        // Меняем цвет ауры
        setAuraColor(SKColor(red: 0.5, green: 0.2, blue: 0.6, alpha: 1.0))
    }

    /// Добавление прожилок скверны
    private func addCorruptionVeins() {
        // Вертикальные прожилки
        for i in 0..<3 {
            let vein = SKSpriteNode(
                color: SKColor(red: 0.6, green: 0.2, blue: 0.8, alpha: 0.6),
                size: CGSize(width: 2, height: size.height * 0.4)
            )
            vein.position = CGPoint(
                x: -size.width * 0.2 + CGFloat(i) * size.width * 0.2,
                y: 0
            )
            vein.zPosition = 1
            vein.name = "vein_\(i)"
            addChild(vein)

            // Пульсация прожилок
            let pulse = SKAction.sequence([
                SKAction.fadeAlpha(to: 0.3, duration: 0.5 + Double(i) * 0.2),
                SKAction.fadeAlpha(to: 0.8, duration: 0.5 + Double(i) * 0.2)
            ])
            vein.run(SKAction.repeatForever(pulse))
        }
    }

    /// Добавление светящихся глаз
    private func addGlowingEyes() {
        let eyeColor = SKColor(red: 0.7, green: 0.3, blue: 1.0, alpha: 1.0)
        let eyeSize = CGSize(width: 4, height: 4)
        let eyeY = size.height * 0.25

        // Левый глаз
        let leftEye = SKSpriteNode(color: eyeColor, size: eyeSize)
        leftEye.position = CGPoint(x: -6, y: eyeY)
        leftEye.zPosition = 2
        leftEye.name = "leftEye"
        addChild(leftEye)

        // Правый глаз
        let rightEye = SKSpriteNode(color: eyeColor, size: eyeSize)
        rightEye.position = CGPoint(x: 6, y: eyeY)
        rightEye.zPosition = 2
        rightEye.name = "rightEye"
        addChild(rightEye)

        // Свечение глаз
        let glow = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.5, duration: 0.3),
            SKAction.fadeAlpha(to: 1.0, duration: 0.3)
        ])
        leftEye.run(SKAction.repeatForever(glow))
        rightEye.run(SKAction.repeatForever(SKAction.sequence([
            SKAction.wait(forDuration: 0.15),
            glow
        ])))
    }

    // MARK: - Update

    override func update(deltaTime: TimeInterval) {
        super.update(deltaTime: deltaTime)

        // Обновляем кулдауны
        if jumpSlamCooldownTimer > 0 {
            jumpSlamCooldownTimer -= deltaTime
        }
        if slashComboCooldownTimer > 0 {
            slashComboCooldownTimer -= deltaTime
        }
        if summonMinionsCooldownTimer > 0 {
            summonMinionsCooldownTimer -= deltaTime
        }
    }

    // MARK: - Phase Transition

    /// Переход во вторую фазу
    func enterPhase2() {
        guard !isPhase2 else { return }
        isPhase2 = true

        // Вспышка и крик
        playPhase2TransitionEffect()

        // Показать диалог
        NotificationCenter.default.post(
            name: .bossDialogue,
            object: self,
            userInfo: ["dialogue": Defiler.phase2Dialogue]
        )
    }

    /// Эффект перехода во вторую фазу
    private func playPhase2TransitionEffect() {
        // Интенсивная вспышка
        let flash = SKAction.sequence([
            SKAction.colorize(with: .white, colorBlendFactor: 1.0, duration: 0.1),
            SKAction.colorize(with: SKColor(red: 0.7, green: 0.3, blue: 1.0, alpha: 1.0), colorBlendFactor: 0.5, duration: 0.2),
            SKAction.colorize(withColorBlendFactor: 0, duration: 0.3)
        ])

        // Взрыв частиц
        let burst = SKAction.run { [weak self] in
            self?.createPhase2Burst()
        }

        // Увеличение и тряска
        let shake = SKAction.sequence([
            SKAction.scale(to: 1.3, duration: 0.1),
            SKAction.moveBy(x: 5, y: 0, duration: 0.05),
            SKAction.moveBy(x: -10, y: 0, duration: 0.05),
            SKAction.moveBy(x: 10, y: 0, duration: 0.05),
            SKAction.moveBy(x: -5, y: 0, duration: 0.05),
            SKAction.scale(to: 1.0, duration: 0.1)
        ])

        run(SKAction.group([flash, burst, shake]))

        // Запрос тряски камеры
        NotificationCenter.default.post(
            name: .requestCameraShake,
            object: nil,
            userInfo: ["intensity": 10.0, "duration": 0.5]
        )

        // Меняем цвет глаз на более яркий
        childNode(withName: "leftEye")?.run(SKAction.colorize(with: .magenta, colorBlendFactor: 1.0, duration: 0.3))
        childNode(withName: "rightEye")?.run(SKAction.colorize(with: .magenta, colorBlendFactor: 1.0, duration: 0.3))

        // Усиливаем ауру
        setAuraColor(SKColor(red: 0.8, green: 0.2, blue: 0.8, alpha: 1.0))
    }

    /// Создание взрыва частиц при переходе в фазу 2
    private func createPhase2Burst() {
        guard let parent = self.parent else { return }

        for _ in 0..<20 {
            let particle = SKSpriteNode(
                color: SKColor(red: 0.7, green: 0.3, blue: 1.0, alpha: 1.0),
                size: CGSize(width: 8, height: 8)
            )
            particle.position = self.position
            particle.zPosition = self.zPosition + 10
            parent.addChild(particle)

            let randomAngle = CGFloat.random(in: 0...(2 * .pi))
            let randomDistance = CGFloat.random(in: 80...150)
            let targetPoint = CGPoint(
                x: cos(randomAngle) * randomDistance,
                y: sin(randomAngle) * randomDistance
            )

            let moveAction = SKAction.move(by: CGVector(dx: targetPoint.x, dy: targetPoint.y), duration: 0.4)
            moveAction.timingMode = .easeOut

            particle.run(SKAction.sequence([
                SKAction.group([
                    moveAction,
                    SKAction.fadeOut(withDuration: 0.4),
                    SKAction.scale(to: 0.3, duration: 0.4)
                ]),
                SKAction.removeFromParent()
            ]))
        }
    }

    // MARK: - Attack Patterns

    /// Выполнить JumpSlam атаку
    func performJumpSlam(target: Player, completion: @escaping () -> Void) {
        guard jumpSlamCooldownTimer <= 0 else {
            completion()
            return
        }

        jumpSlamCooldownTimer = DefilerConfig.jumpSlamCooldown

        let targetPosition = target.position

        // Подготовка к прыжку
        let prepareAction = SKAction.sequence([
            SKAction.scaleY(to: 0.8, duration: 0.2),
            SKAction.wait(forDuration: 0.1)
        ])

        // Прыжок к игроку
        let jumpHeight: CGFloat = 150
        let jumpDuration: TimeInterval = 0.5

        let jumpUp = SKAction.moveBy(x: 0, y: jumpHeight, duration: jumpDuration * 0.4)
        jumpUp.timingMode = .easeOut

        let moveToTarget = SKAction.moveTo(x: targetPosition.x, duration: jumpDuration * 0.4)

        let jumpAction = SKAction.group([jumpUp, moveToTarget])

        // Падение
        let fallAction = SKAction.moveBy(x: 0, y: -jumpHeight, duration: jumpDuration * 0.3)
        fallAction.timingMode = .easeIn

        // Приземление и создание волны
        let landAction = SKAction.run { [weak self] in
            self?.createGroundWaves()
            self?.playLandingEffect()
        }

        // Восстановление
        let recoverAction = SKAction.scaleY(to: 1.0, duration: 0.2)

        run(SKAction.sequence([
            prepareAction,
            jumpAction,
            fallAction,
            landAction,
            recoverAction,
            SKAction.run { completion() }
        ]))
    }

    /// Создание волн по земле при приземлении
    private func createGroundWaves() {
        guard let parent = self.parent else { return }

        // Волна вправо
        let rightWave = GroundWave(direction: 1, damage: DefilerConfig.attackDamage)
        rightWave.position = CGPoint(x: position.x + size.width / 2, y: position.y - size.height / 2)
        parent.addChild(rightWave)

        // Волна влево
        let leftWave = GroundWave(direction: -1, damage: DefilerConfig.attackDamage)
        leftWave.position = CGPoint(x: position.x - size.width / 2, y: position.y - size.height / 2)
        parent.addChild(leftWave)
    }

    /// Эффект приземления
    private func playLandingEffect() {
        // Тряска камеры
        NotificationCenter.default.post(
            name: .requestCameraShake,
            object: nil,
            userInfo: ["intensity": 5.0, "duration": 0.2]
        )

        // Визуальный эффект удара
        guard let parent = self.parent else { return }

        let impactCircle = SKShapeNode(circleOfRadius: 30)
        impactCircle.position = CGPoint(x: position.x, y: position.y - size.height / 2)
        impactCircle.strokeColor = SKColor(red: 0.6, green: 0.3, blue: 0.8, alpha: 0.8)
        impactCircle.fillColor = .clear
        impactCircle.lineWidth = 3
        impactCircle.zPosition = 4
        parent.addChild(impactCircle)

        let expand = SKAction.scale(to: 3.0, duration: 0.3)
        let fadeOut = SKAction.fadeOut(withDuration: 0.3)
        impactCircle.run(SKAction.sequence([
            SKAction.group([expand, fadeOut]),
            SKAction.removeFromParent()
        ]))
    }

    /// Выполнить SlashCombo атаку
    func performSlashCombo(target: Player, completion: @escaping () -> Void) {
        guard slashComboCooldownTimer <= 0 else {
            completion()
            return
        }

        slashComboCooldownTimer = DefilerConfig.slashComboCooldown

        let attackRange: CGFloat = 60

        // Первый удар
        let firstSlash = SKAction.run { [weak self, weak target] in
            guard let self = self, let target = target else { return }
            self.performSingleSlash(target: target, range: attackRange)
        }

        // Второй удар
        let secondSlash = SKAction.run { [weak self, weak target] in
            guard let self = self, let target = target else { return }
            self.performSingleSlash(target: target, range: attackRange)
        }

        // Окно уязвимости после комбо
        let vulnerabilityWindow = SKAction.run { [weak self] in
            self?.showVulnerabilityWindow(duration: DefilerConfig.postComboPause)
        }

        run(SKAction.sequence([
            firstSlash,
            SKAction.wait(forDuration: DefilerConfig.slashComboWindow),
            secondSlash,
            vulnerabilityWindow,
            SKAction.wait(forDuration: DefilerConfig.postComboPause),
            SKAction.run { completion() }
        ]))
    }

    /// Выполнить одиночный удар
    private func performSingleSlash(target: Player, range: CGFloat) {
        let distance = abs(target.position.x - position.x)

        // Визуальный эффект удара
        playSlashEffect()

        // Проверяем попадание
        if distance <= range && abs(target.position.y - position.y) < size.height {
            let knockbackDirection: CGFloat = target.position.x > position.x ? 1 : -1
            target.takeDamage(DefilerConfig.attackDamage, knockbackDirection: knockbackDirection, knockbackForce: 200)
        }
    }

    /// Эффект удара мечом
    private func playSlashEffect() {
        guard let parent = self.parent else { return }

        let slashDirection: CGFloat = facingDirection == .right ? 1 : -1

        // Дуга удара
        let slashArc = SKShapeNode()
        let path = UIBezierPath(
            arcCenter: .zero,
            radius: 40,
            startAngle: slashDirection > 0 ? -.pi / 4 : .pi - .pi / 4,
            endAngle: slashDirection > 0 ? .pi / 4 : .pi + .pi / 4,
            clockwise: slashDirection > 0
        )
        slashArc.path = path.cgPath
        slashArc.strokeColor = SKColor(red: 0.8, green: 0.6, blue: 1.0, alpha: 0.8)
        slashArc.lineWidth = 4
        slashArc.position = CGPoint(x: position.x + slashDirection * 20, y: position.y)
        slashArc.zPosition = 20
        parent.addChild(slashArc)

        slashArc.run(SKAction.sequence([
            SKAction.fadeOut(withDuration: 0.2),
            SKAction.removeFromParent()
        ]))

        // Рывок вперёд
        run(SKAction.sequence([
            SKAction.moveBy(x: slashDirection * 15, y: 0, duration: 0.1),
            SKAction.moveBy(x: -slashDirection * 15, y: 0, duration: 0.1)
        ]))
    }

    /// Призыв миньонов
    func performSummonMinions(completion: @escaping () -> Void) {
        guard summonMinionsCooldownTimer <= 0 else {
            completion()
            return
        }

        guard activeMinionsCount < DefilerConfig.maxMinions else {
            completion()
            return
        }

        summonMinionsCooldownTimer = DefilerConfig.summonMinionsCooldown

        // Показываем окно уязвимости во время призыва
        showVulnerabilityWindow(duration: 1.5)

        // Анимация призыва
        let raiseArms = SKAction.sequence([
            SKAction.scaleY(to: 1.1, duration: 0.2),
            SKAction.wait(forDuration: 0.3)
        ])

        let summon = SKAction.run { [weak self] in
            self?.spawnMinions()
        }

        let lowerArms = SKAction.scaleY(to: 1.0, duration: 0.2)

        run(SKAction.sequence([
            raiseArms,
            summon,
            lowerArms,
            SKAction.wait(forDuration: 0.5),
            SKAction.run { completion() }
        ]))
    }

    /// Спавн миньонов
    private func spawnMinions() {
        let minionsToSpawn = min(
            DefilerConfig.minionsPerSummon,
            DefilerConfig.maxMinions - activeMinionsCount
        )

        guard minionsToSpawn > 0 else { return }

        // Отправляем уведомление для спавна миньонов
        // GameScene должна обработать это уведомление
        NotificationCenter.default.post(
            name: .defilerSummonMinions,
            object: self,
            userInfo: [
                "count": minionsToSpawn,
                "position": position,
                "arenaBounds": arenaBounds
            ]
        )

        activeMinionsCount += minionsToSpawn

        // Визуальный эффект призыва
        playSummonEffect()
    }

    /// Эффект призыва
    private func playSummonEffect() {
        guard let parent = self.parent else { return }

        // Круг призыва
        let summonCircle = SKShapeNode(circleOfRadius: 60)
        summonCircle.position = position
        summonCircle.strokeColor = SKColor(red: 0.5, green: 0.2, blue: 0.6, alpha: 0.8)
        summonCircle.fillColor = SKColor(red: 0.5, green: 0.2, blue: 0.6, alpha: 0.2)
        summonCircle.lineWidth = 2
        summonCircle.zPosition = 3
        summonCircle.setScale(0.1)
        parent.addChild(summonCircle)

        summonCircle.run(SKAction.sequence([
            SKAction.scale(to: 1.5, duration: 0.3),
            SKAction.group([
                SKAction.fadeOut(withDuration: 0.3),
                SKAction.scale(to: 2.0, duration: 0.3)
            ]),
            SKAction.removeFromParent()
        ]))
    }

    // MARK: - Minion Tracking

    /// Обработка смерти миньона
    @objc private func handleMinionDied(_ notification: Notification) {
        // Проверяем, что это наш миньон (культист)
        guard let enemy = notification.userInfo?["enemy"] as? Enemy,
              enemy.entityType == "cultist" else { return }

        // Уменьшаем счётчик только если он больше 0
        if activeMinionsCount > 0 {
            activeMinionsCount -= 1
        }
    }

    // MARK: - Death

    override func die() {
        // Показываем диалог
        NotificationCenter.default.post(
            name: .bossDialogue,
            object: self,
            userInfo: ["dialogue": Defiler.deathDialogue]
        )

        super.die()
    }

    // MARK: - Speed Modifier

    /// Получить текущую скорость с учётом фазы
    var currentSpeed: CGFloat {
        return isPhase2 ? DefilerConfig.baseSpeed * DefilerConfig.phase2SpeedMultiplier : DefilerConfig.baseSpeed
    }
}

// MARK: - Defiler Phase 1

/// Первая фаза Defiler (HP 100% - 50%)
class DefilerPhase1: BaseBossPhase {
    init() {
        let patterns: [AttackPattern] = [
            DefilerJumpSlamPattern(),
            DefilerSlashComboPattern()
        ]
        super.init(healthThreshold: 1.0, patterns: patterns, phaseName: "Фаза 1")
        self.auraColor = SKColor(red: 0.5, green: 0.2, blue: 0.6, alpha: 1.0)
    }
}

// MARK: - Defiler Phase 2

/// Вторая фаза Defiler (HP 50% - 0%)
class DefilerPhase2: BaseBossPhase {
    init() {
        let patterns: [AttackPattern] = [
            DefilerJumpSlamPattern(),
            DefilerSlashComboPattern(),
            DefilerSummonMinionsPattern()
        ]
        super.init(healthThreshold: 0.5, patterns: patterns, phaseName: "Фаза 2 - Ярость")
        self.auraColor = SKColor(red: 0.8, green: 0.2, blue: 0.8, alpha: 1.0)
    }

    override func onEnter(boss: Boss) {
        super.onEnter(boss: boss)

        // Активируем переход во вторую фазу
        if let defiler = boss as? Defiler {
            defiler.enterPhase2()
        }
    }
}

// MARK: - Attack Patterns

/// Паттерн атаки JumpSlam
class DefilerJumpSlamPattern: BaseAttackPattern {
    init() {
        super.init(
            name: "JumpSlam",
            duration: 1.2,
            cooldown: DefilerConfig.jumpSlamCooldown
        )
    }

    override func execute(target: Player, boss: Boss, completion: @escaping () -> Void) {
        lastExecutionTime = CACurrentMediaTime()

        if let defiler = boss as? Defiler {
            defiler.performJumpSlam(target: target, completion: completion)
        } else {
            completion()
        }
    }
}

/// Паттерн атаки SlashCombo
class DefilerSlashComboPattern: BaseAttackPattern {
    init() {
        super.init(
            name: "SlashCombo",
            duration: 1.5,
            cooldown: DefilerConfig.slashComboCooldown
        )
    }

    override func execute(target: Player, boss: Boss, completion: @escaping () -> Void) {
        lastExecutionTime = CACurrentMediaTime()

        if let defiler = boss as? Defiler {
            defiler.performSlashCombo(target: target, completion: completion)
        } else {
            completion()
        }
    }
}

/// Паттерн призыва миньонов
class DefilerSummonMinionsPattern: BaseAttackPattern {
    init() {
        super.init(
            name: "SummonMinions",
            duration: 2.0,
            cooldown: DefilerConfig.summonMinionsCooldown
        )
    }

    override func execute(target: Player, boss: Boss, completion: @escaping () -> Void) {
        lastExecutionTime = CACurrentMediaTime()

        if let defiler = boss as? Defiler {
            defiler.performSummonMinions(completion: completion)
        } else {
            completion()
        }
    }
}

// MARK: - Notifications

extension Notification.Name {
    /// Уведомление о призыве миньонов Defiler
    static let defilerSummonMinions = Notification.Name("defilerSummonMinions")

    /// Уведомление о диалоге босса
    static let bossDialogue = Notification.Name("bossDialogue")
}
