import SpriteKit

// MARK: - BossPhase Protocol

/// Протокол для описания фазы босса
protocol BossPhase: AnyObject {
    /// Порог здоровья для активации фазы (0.0-1.0)
    /// Например: 1.0 = полное здоровье, 0.5 = половина здоровья
    var healthThreshold: CGFloat { get }

    /// Доступные паттерны атак в этой фазе
    var patterns: [AttackPattern] { get }

    /// Название фазы (для UI/отладки)
    var phaseName: String { get }

    /// Вызывается при входе в фазу
    /// - Parameter boss: Босс, переходящий в эту фазу
    func onEnter(boss: Boss)

    /// Вызывается при выходе из фазы
    /// - Parameter boss: Босс, выходящий из этой фазы
    func onExit(boss: Boss)

    /// Выбрать следующий паттерн атаки
    /// - Parameter currentTime: Текущее время
    /// - Returns: Паттерн атаки или nil если все на перезарядке
    func selectPattern(currentTime: TimeInterval) -> AttackPattern?
}

// MARK: - Default Implementation

extension BossPhase {
    func selectPattern(currentTime: TimeInterval) -> AttackPattern? {
        // Выбираем случайный доступный паттерн
        let availablePatterns = patterns.filter { $0.canExecute(currentTime: currentTime) }
        return availablePatterns.randomElement()
    }
}

// MARK: - BaseBossPhase

/// Базовый класс для фаз босса
class BaseBossPhase: BossPhase {
    let healthThreshold: CGFloat
    let patterns: [AttackPattern]
    let phaseName: String

    /// Визуальные эффекты фазы
    var auraColor: SKColor = .purple
    var auraIntensity: CGFloat = 0.5

    init(healthThreshold: CGFloat, patterns: [AttackPattern], phaseName: String) {
        self.healthThreshold = healthThreshold
        self.patterns = patterns
        self.phaseName = phaseName
    }

    func onEnter(boss: Boss) {
        // Уведомление о смене фазы
        NotificationCenter.default.post(
            name: .bossPhaseChanged,
            object: boss,
            userInfo: ["phaseName": phaseName, "healthThreshold": healthThreshold]
        )

        // Визуальный эффект перехода
        playPhaseTransitionEffect(on: boss)
    }

    func onExit(boss: Boss) {
        // Базовая реализация - ничего не делает
    }

    /// Эффект перехода между фазами
    private func playPhaseTransitionEffect(on boss: Boss) {
        // Вспышка
        let flash = SKAction.sequence([
            SKAction.colorize(with: auraColor, colorBlendFactor: 0.8, duration: 0.1),
            SKAction.colorize(withColorBlendFactor: 0, duration: 0.3)
        ])

        // Увеличение и возврат
        let pulse = SKAction.sequence([
            SKAction.scale(to: 1.2, duration: 0.15),
            SKAction.scale(to: 1.0, duration: 0.15)
        ])

        boss.run(SKAction.group([flash, pulse]))

        // Частицы перехода
        if let particles = createTransitionParticles() {
            particles.position = .zero
            boss.addChild(particles)

            particles.run(SKAction.sequence([
                SKAction.wait(forDuration: 1.0),
                SKAction.removeFromParent()
            ]))
        }
    }

    /// Создание частиц для эффекта перехода
    private func createTransitionParticles() -> SKEmitterNode? {
        let emitter = SKEmitterNode()

        emitter.particleBirthRate = 50
        emitter.numParticlesToEmit = 30
        emitter.particleLifetime = 0.8
        emitter.particleLifetimeRange = 0.2

        emitter.particleColor = auraColor
        emitter.particleColorBlendFactor = 1.0
        emitter.particleBlendMode = .add

        emitter.particleSize = CGSize(width: 8, height: 8)
        emitter.particleScale = 1.0
        emitter.particleScaleRange = 0.5
        emitter.particleScaleSpeed = -0.5

        emitter.particleSpeed = 100
        emitter.particleSpeedRange = 50
        emitter.emissionAngleRange = .pi * 2

        emitter.particleAlpha = 1.0
        emitter.particleAlphaSpeed = -1.0

        emitter.zPosition = 100

        return emitter
    }
}

// MARK: - AggressivePhase

/// Фаза с агрессивными атаками (обычно при низком здоровье)
class AggressivePhase: BaseBossPhase {
    /// Множитель скорости атак
    let attackSpeedMultiplier: CGFloat

    init(healthThreshold: CGFloat,
         patterns: [AttackPattern],
         phaseName: String = "Ярость",
         attackSpeedMultiplier: CGFloat = 1.5) {
        self.attackSpeedMultiplier = attackSpeedMultiplier
        super.init(healthThreshold: healthThreshold, patterns: patterns, phaseName: phaseName)
        self.auraColor = .red
        self.auraIntensity = 0.8
    }

    override func onEnter(boss: Boss) {
        super.onEnter(boss: boss)

        // Постоянный эффект ярости
        let rage = SKAction.sequence([
            SKAction.colorize(with: .red, colorBlendFactor: 0.3, duration: 0.3),
            SKAction.colorize(withColorBlendFactor: 0.1, duration: 0.3)
        ])
        boss.run(SKAction.repeatForever(rage), withKey: "rageEffect")
    }

    override func onExit(boss: Boss) {
        super.onExit(boss: boss)
        boss.removeAction(forKey: "rageEffect")
        boss.run(SKAction.colorize(withColorBlendFactor: 0, duration: 0.2))
    }
}

// MARK: - DefensivePhase

/// Защитная фаза (босс восстанавливается или призывает миньонов)
class DefensivePhase: BaseBossPhase {
    /// Количество здоровья для восстановления
    let healAmount: Int

    /// Призывать ли миньонов
    let summonMinions: Bool

    init(healthThreshold: CGFloat,
         patterns: [AttackPattern],
         phaseName: String = "Защита",
         healAmount: Int = 0,
         summonMinions: Bool = false) {
        self.healAmount = healAmount
        self.summonMinions = summonMinions
        super.init(healthThreshold: healthThreshold, patterns: patterns, phaseName: phaseName)
        self.auraColor = .cyan
        self.auraIntensity = 0.6
    }

    override func onEnter(boss: Boss) {
        super.onEnter(boss: boss)

        // Восстановление здоровья
        if healAmount > 0 {
            boss.heal(healAmount)
        }

        // Призыв миньонов
        if summonMinions {
            boss.summonMinions()
        }

        // Защитный барьер
        let barrier = createDefensiveBarrier(for: boss)
        boss.addChild(barrier)
    }

    private func createDefensiveBarrier(for boss: Boss) -> SKNode {
        let barrier = SKShapeNode(circleOfRadius: boss.size.width * 0.8)
        barrier.name = "defensiveBarrier"
        barrier.strokeColor = auraColor
        barrier.fillColor = auraColor.withAlphaComponent(0.1)
        barrier.lineWidth = 3
        barrier.glowWidth = 5
        barrier.zPosition = -1

        // Пульсация барьера
        let pulse = SKAction.sequence([
            SKAction.scale(to: 1.1, duration: 0.5),
            SKAction.scale(to: 1.0, duration: 0.5)
        ])
        barrier.run(SKAction.repeatForever(pulse))

        return barrier
    }

    override func onExit(boss: Boss) {
        super.onExit(boss: boss)
        boss.childNode(withName: "defensiveBarrier")?.removeFromParent()
    }
}

// MARK: - Notification Names

extension Notification.Name {
    /// Уведомление о смене фазы босса
    static let bossPhaseChanged = Notification.Name("bossPhaseChanged")
}
