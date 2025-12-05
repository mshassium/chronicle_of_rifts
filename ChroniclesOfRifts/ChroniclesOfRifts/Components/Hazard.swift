import SpriteKit

// MARK: - HazardType Enum

/// Типы опасностей в игре
enum HazardType: String, CaseIterable {
    case spikes      // Шипы (мгновенный урон при касании)
    case lava        // Лава (урон + эффект горения)
    case void        // Пустота (мгновенная смерть)
    case poison      // Яд (урон со временем)
    case electricity // Электричество (периодический урон)
}

// MARK: - Hazard Class

/// Опасность в игровом мире (шипы, лава, пустота и т.д.)
final class Hazard: SKSpriteNode {

    // MARK: - Properties

    /// Тип опасности
    private(set) var hazardType: HazardType

    /// Урон, наносимый при контакте
    var damage: Int = 1

    /// Интервал периодического урона (для electricity, poison)
    var damageInterval: TimeInterval = 0

    /// Сила отбрасывания
    var knockback: CGFloat = 200

    /// Применяет ли эффект (горение/отравление)
    var appliesEffect: Bool = false

    /// Длительность эффекта
    var effectDuration: TimeInterval = 0

    /// Флаг активного периодического урона
    private var isPeriodicDamageActive: Bool = false

    /// Ссылка на игрока для периодического урона
    private weak var periodicDamageTarget: Player?

    /// Ключ действия периодического урона
    private let periodicDamageKey = "periodicDamage"

    /// Ключ визуальных эффектов
    private let visualEffectKey = "visualEffect"

    // MARK: - Init

    /// Инициализация опасности
    /// - Parameters:
    ///   - type: Тип опасности
    ///   - size: Размер области опасности
    init(type: HazardType, size: CGSize) {
        self.hazardType = type

        // Определяем цвет по типу
        let color = Hazard.colorForType(type)

        super.init(texture: nil, color: color, size: size)

        self.name = "hazard_\(type.rawValue)"
        self.zPosition = 5

        // Настраиваем свойства по типу
        configureForType(type)

        // Настраиваем физику
        setupPhysics()

        // Создаём визуальные эффекты
        createVisualEffect()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) не реализован")
    }

    // MARK: - Configuration

    /// Настройка свойств по типу опасности
    private func configureForType(_ type: HazardType) {
        switch type {
        case .spikes:
            damage = 1
            damageInterval = 0
            knockback = 200
            appliesEffect = false

        case .lava:
            damage = 1
            damageInterval = 0.5
            knockback = 150
            appliesEffect = true
            effectDuration = 3.0

        case .void:
            damage = 999  // Мгновенная смерть
            damageInterval = 0
            knockback = 0
            appliesEffect = false

        case .poison:
            damage = 1
            damageInterval = 1.0
            knockback = 0
            appliesEffect = true
            effectDuration = 5.0

        case .electricity:
            damage = 1
            damageInterval = 0.3
            knockback = 100
            appliesEffect = false
        }
    }

    /// Цвет опасности по типу
    private static func colorForType(_ type: HazardType) -> SKColor {
        switch type {
        case .spikes:
            return SKColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1.0) // Серый металл
        case .lava:
            return SKColor(red: 1.0, green: 0.3, blue: 0.1, alpha: 1.0) // Оранжевая лава
        case .void:
            return SKColor(red: 0.1, green: 0.0, blue: 0.15, alpha: 1.0) // Тёмно-фиолетовый
        case .poison:
            return SKColor(red: 0.2, green: 0.7, blue: 0.2, alpha: 0.8) // Зелёный яд
        case .electricity:
            return SKColor(red: 0.9, green: 0.9, blue: 0.3, alpha: 1.0) // Жёлтое электричество
        }
    }

    // MARK: - Physics

    /// Настройка физического тела
    private func setupPhysics() {
        physicsBody = SKPhysicsBody(rectangleOf: size)
        physicsBody?.isDynamic = false
        physicsBody?.categoryBitMask = PhysicsCategory.hazard
        physicsBody?.contactTestBitMask = PhysicsCategory.player
        physicsBody?.collisionBitMask = 0  // Нет физического столкновения, только детекция
    }

    // MARK: - Damage

    /// Нанести урон игроку
    /// - Parameter player: Игрок, получающий урон
    func applyDamage(to player: Player) {
        guard !player.isInvulnerable else { return }

        switch hazardType {
        case .void:
            // Мгновенная смерть
            player.die()

        case .spikes:
            // Мгновенный урон + отбрасывание
            let knockbackDir: CGFloat = player.position.x < position.x ? -1 : 1
            player.takeDamage(damage, knockbackDirection: knockbackDir, knockbackForce: knockback)

        case .lava:
            // Урон + эффект горения
            let knockbackDir: CGFloat = player.position.x < position.x ? -1 : 1
            player.takeDamage(damage, knockbackDirection: knockbackDir, knockbackForce: knockback)

            if appliesEffect {
                applyBurningEffect(to: player)
            }

        case .poison:
            // Начинаем периодический урон + эффект отравления
            if !isPeriodicDamageActive {
                startPeriodicDamage(to: player)
            }

            if appliesEffect {
                applyPoisonEffect(to: player)
            }

        case .electricity:
            // Периодический урон начинается при контакте
            if !isPeriodicDamageActive {
                startPeriodicDamage(to: player)
            }
        }
    }

    /// Начать периодический урон
    /// - Parameter player: Игрок, получающий урон
    func startPeriodicDamage(to player: Player) {
        guard damageInterval > 0 else { return }
        guard !isPeriodicDamageActive else { return }

        isPeriodicDamageActive = true
        periodicDamageTarget = player

        // Немедленный первый урон
        dealPeriodicDamage(to: player)

        // Периодический урон
        let damageAction = SKAction.sequence([
            SKAction.wait(forDuration: damageInterval),
            SKAction.run { [weak self, weak player] in
                guard let player = player else {
                    self?.stopPeriodicDamage()
                    return
                }
                self?.dealPeriodicDamage(to: player)
            }
        ])

        run(SKAction.repeatForever(damageAction), withKey: periodicDamageKey)
    }

    /// Нанести периодический урон
    private func dealPeriodicDamage(to player: Player) {
        guard !player.isInvulnerable else { return }

        let knockbackDir: CGFloat = knockback > 0 ? (player.position.x < position.x ? -1 : 1) : 0
        player.takeDamage(damage, knockbackDirection: knockbackDir, knockbackForce: knockback)

        // Визуальный эффект урона
        showDamageFlash()
    }

    /// Остановить периодический урон
    func stopPeriodicDamage() {
        isPeriodicDamageActive = false
        periodicDamageTarget = nil
        removeAction(forKey: periodicDamageKey)
    }

    // MARK: - Effects

    /// Применить эффект горения
    private func applyBurningEffect(to player: Player) {
        // Создаём визуальный эффект горения на игроке
        let burnOverlay = SKSpriteNode(color: SKColor(red: 1.0, green: 0.4, blue: 0.1, alpha: 0.3), size: player.size)
        burnOverlay.name = "burnOverlay"
        burnOverlay.zPosition = 50

        // Удаляем старый эффект если есть
        player.childNode(withName: "burnOverlay")?.removeFromParent()
        player.addChild(burnOverlay)

        // Анимация мерцания
        let flicker = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.5, duration: 0.2),
            SKAction.fadeAlpha(to: 0.2, duration: 0.2)
        ])
        burnOverlay.run(SKAction.repeat(flicker, count: Int(effectDuration / 0.4)))

        // Периодический урон от горения
        let burnDamage = SKAction.sequence([
            SKAction.wait(forDuration: 1.0),
            SKAction.run { [weak player] in
                guard let player = player, !player.isInvulnerable else { return }
                player.takeDamage(1)
            }
        ])

        let burnSequence = SKAction.sequence([
            SKAction.repeat(burnDamage, count: Int(effectDuration)),
            SKAction.run { [weak burnOverlay] in
                burnOverlay?.removeFromParent()
            }
        ])

        player.run(burnSequence, withKey: "burningEffect")
    }

    /// Применить эффект отравления
    private func applyPoisonEffect(to player: Player) {
        // Создаём визуальный эффект отравления на игроке
        let poisonOverlay = SKSpriteNode(color: SKColor(red: 0.2, green: 0.8, blue: 0.2, alpha: 0.3), size: player.size)
        poisonOverlay.name = "poisonOverlay"
        poisonOverlay.zPosition = 50

        // Удаляем старый эффект если есть
        player.childNode(withName: "poisonOverlay")?.removeFromParent()
        player.addChild(poisonOverlay)

        // Применяем замедление
        player.applySlow(duration: effectDuration, multiplier: 0.6)

        // Анимация пульсации
        let pulse = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.5, duration: 0.5),
            SKAction.fadeAlpha(to: 0.2, duration: 0.5)
        ])
        poisonOverlay.run(SKAction.repeat(pulse, count: Int(effectDuration)))

        // Удаление эффекта после окончания
        let removeEffect = SKAction.sequence([
            SKAction.wait(forDuration: effectDuration),
            SKAction.run { [weak poisonOverlay] in
                poisonOverlay?.removeFromParent()
            }
        ])
        player.run(removeEffect, withKey: "poisonEffect")
    }

    // MARK: - Visual Effects

    /// Создание визуальных эффектов для опасности
    private func createVisualEffect() {
        switch hazardType {
        case .spikes:
            createSpikesVisual()

        case .lava:
            createLavaVisual()

        case .void:
            createVoidVisual()

        case .poison:
            createPoisonVisual()

        case .electricity:
            createElectricityVisual()
        }
    }

    /// Визуал для шипов
    private func createSpikesVisual() {
        // Добавляем треугольные шипы
        let spikeCount = Int(size.width / 16)
        let spikeWidth = size.width / CGFloat(spikeCount)

        for i in 0..<spikeCount {
            let spike = SKShapeNode()
            let path = CGMutablePath()
            path.move(to: CGPoint(x: -spikeWidth / 2, y: -size.height / 2))
            path.addLine(to: CGPoint(x: 0, y: size.height / 2 - 2))
            path.addLine(to: CGPoint(x: spikeWidth / 2, y: -size.height / 2))
            path.closeSubpath()

            spike.path = path
            spike.fillColor = SKColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1.0)
            spike.strokeColor = SKColor(red: 0.3, green: 0.3, blue: 0.3, alpha: 1.0)
            spike.lineWidth = 1
            spike.position = CGPoint(
                x: -size.width / 2 + spikeWidth * (CGFloat(i) + 0.5),
                y: 0
            )
            spike.zPosition = 1
            addChild(spike)
        }

        // Редкий блеск
        let glintAction = SKAction.sequence([
            SKAction.wait(forDuration: Double.random(in: 3.0...6.0)),
            SKAction.run { [weak self] in
                self?.showSpikeGlint()
            }
        ])
        run(SKAction.repeatForever(glintAction), withKey: visualEffectKey)
    }

    /// Показать блеск на шипах
    private func showSpikeGlint() {
        let glint = SKSpriteNode(color: .white, size: CGSize(width: 4, height: 8))
        glint.alpha = 0
        glint.position = CGPoint(
            x: CGFloat.random(in: -size.width / 2 + 4...size.width / 2 - 4),
            y: CGFloat.random(in: -size.height / 4...size.height / 4)
        )
        glint.zPosition = 10
        addChild(glint)

        let glintAnimation = SKAction.sequence([
            SKAction.fadeIn(withDuration: 0.1),
            SKAction.wait(forDuration: 0.1),
            SKAction.fadeOut(withDuration: 0.2),
            SKAction.removeFromParent()
        ])
        glint.run(glintAnimation)
    }

    /// Визуал для лавы
    private func createLavaVisual() {
        // Анимация волн
        let wave = SKAction.sequence([
            SKAction.moveBy(x: 0, y: 3, duration: 1.0),
            SKAction.moveBy(x: 0, y: -3, duration: 1.0)
        ])
        run(SKAction.repeatForever(wave))

        // Пузыри
        let bubbleAction = SKAction.sequence([
            SKAction.wait(forDuration: Double.random(in: 0.5...2.0)),
            SKAction.run { [weak self] in
                self?.createBubble()
            }
        ])
        run(SKAction.repeatForever(bubbleAction), withKey: visualEffectKey)

        // Свечение
        let glow = SKShapeNode(rectOf: CGSize(width: size.width, height: size.height + 8))
        glow.fillColor = SKColor(red: 1.0, green: 0.5, blue: 0.0, alpha: 0.2)
        glow.strokeColor = .clear
        glow.position = CGPoint(x: 0, y: 4)
        glow.zPosition = -1
        addChild(glow)

        let glowPulse = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.3, duration: 0.5),
            SKAction.fadeAlpha(to: 0.15, duration: 0.5)
        ])
        glow.run(SKAction.repeatForever(glowPulse))
    }

    /// Создать пузырь лавы
    private func createBubble() {
        let bubbleSize = CGFloat.random(in: 4...8)
        let bubble = SKShapeNode(circleOfRadius: bubbleSize / 2)
        bubble.fillColor = SKColor(red: 1.0, green: 0.6, blue: 0.1, alpha: 0.7)
        bubble.strokeColor = .clear
        bubble.position = CGPoint(
            x: CGFloat.random(in: -size.width / 2 + bubbleSize...size.width / 2 - bubbleSize),
            y: -size.height / 2 + bubbleSize
        )
        bubble.zPosition = 5
        addChild(bubble)

        let rise = SKAction.moveBy(x: CGFloat.random(in: -5...5), y: size.height, duration: Double.random(in: 0.8...1.5))
        let pop = SKAction.sequence([
            SKAction.scale(to: 1.5, duration: 0.1),
            SKAction.fadeOut(withDuration: 0.1),
            SKAction.removeFromParent()
        ])

        bubble.run(SKAction.sequence([rise, pop]))
    }

    /// Визуал для пустоты
    private func createVoidVisual() {
        // Тёмное свечение
        let glow = SKShapeNode(rectOf: CGSize(width: size.width + 20, height: size.height + 20))
        glow.fillColor = SKColor(red: 0.2, green: 0.0, blue: 0.3, alpha: 0.3)
        glow.strokeColor = .clear
        glow.zPosition = -1
        addChild(glow)

        // Пульсация затягивания
        let pulse = SKAction.sequence([
            SKAction.scale(to: 0.95, duration: 1.0),
            SKAction.scale(to: 1.05, duration: 1.0)
        ])
        glow.run(SKAction.repeatForever(pulse))

        // Частицы, летящие внутрь
        let particleAction = SKAction.sequence([
            SKAction.wait(forDuration: 0.3),
            SKAction.run { [weak self] in
                self?.createVoidParticle()
            }
        ])
        run(SKAction.repeatForever(particleAction), withKey: visualEffectKey)
    }

    /// Создать частицу пустоты
    private func createVoidParticle() {
        let particle = SKShapeNode(circleOfRadius: 2)
        particle.fillColor = SKColor(red: 0.5, green: 0.2, blue: 0.8, alpha: 0.8)
        particle.strokeColor = .clear

        // Начальная позиция на краю
        let angle = CGFloat.random(in: 0...CGFloat.pi * 2)
        let radius = max(size.width, size.height) / 2 + 20
        particle.position = CGPoint(
            x: cos(angle) * radius,
            y: sin(angle) * radius
        )
        particle.zPosition = 2
        addChild(particle)

        // Летит к центру и исчезает
        let moveToCenter = SKAction.move(to: .zero, duration: Double.random(in: 0.5...1.0))
        moveToCenter.timingMode = .easeIn
        let shrink = SKAction.scale(to: 0.1, duration: 0.5)
        let fade = SKAction.fadeOut(withDuration: 0.5)

        particle.run(SKAction.sequence([
            SKAction.group([moveToCenter, shrink, fade]),
            SKAction.removeFromParent()
        ]))
    }

    /// Визуал для яда
    private func createPoisonVisual() {
        // Зелёный туман
        let mistAction = SKAction.sequence([
            SKAction.wait(forDuration: 0.5),
            SKAction.run { [weak self] in
                self?.createPoisonMist()
            }
        ])
        run(SKAction.repeatForever(mistAction), withKey: visualEffectKey)

        // Пульсация цвета
        let colorPulse = SKAction.sequence([
            SKAction.colorize(with: SKColor(red: 0.3, green: 0.8, blue: 0.2, alpha: 0.8), colorBlendFactor: 1.0, duration: 1.0),
            SKAction.colorize(with: SKColor(red: 0.1, green: 0.6, blue: 0.1, alpha: 0.8), colorBlendFactor: 1.0, duration: 1.0)
        ])
        run(SKAction.repeatForever(colorPulse))
    }

    /// Создать частицу ядовитого тумана
    private func createPoisonMist() {
        let mist = SKShapeNode(circleOfRadius: CGFloat.random(in: 8...16))
        mist.fillColor = SKColor(red: 0.2, green: 0.8, blue: 0.3, alpha: 0.3)
        mist.strokeColor = .clear
        mist.position = CGPoint(
            x: CGFloat.random(in: -size.width / 2...size.width / 2),
            y: size.height / 2
        )
        mist.zPosition = 3
        addChild(mist)

        let rise = SKAction.moveBy(x: CGFloat.random(in: -10...10), y: 30, duration: 2.0)
        let expand = SKAction.scale(to: 2.0, duration: 2.0)
        let fade = SKAction.fadeOut(withDuration: 2.0)

        mist.run(SKAction.sequence([
            SKAction.group([rise, expand, fade]),
            SKAction.removeFromParent()
        ]))
    }

    /// Визуал для электричества
    private func createElectricityVisual() {
        // Мерцание
        let flicker = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.7, duration: 0.05),
            SKAction.fadeAlpha(to: 1.0, duration: 0.05),
            SKAction.wait(forDuration: Double.random(in: 0.1...0.3))
        ])
        run(SKAction.repeatForever(flicker))

        // Искры
        let sparkAction = SKAction.sequence([
            SKAction.wait(forDuration: Double.random(in: 0.1...0.3)),
            SKAction.run { [weak self] in
                self?.createSpark()
            }
        ])
        run(SKAction.repeatForever(sparkAction), withKey: visualEffectKey)
    }

    /// Создать искру
    private func createSpark() {
        let spark = SKShapeNode(circleOfRadius: 2)
        spark.fillColor = SKColor(red: 1.0, green: 1.0, blue: 0.8, alpha: 1.0)
        spark.strokeColor = .clear
        spark.glowWidth = 3
        spark.position = CGPoint(
            x: CGFloat.random(in: -size.width / 2...size.width / 2),
            y: CGFloat.random(in: -size.height / 2...size.height / 2)
        )
        spark.zPosition = 5
        addChild(spark)

        // Быстрое движение в случайном направлении
        let angle = CGFloat.random(in: 0...CGFloat.pi * 2)
        let distance = CGFloat.random(in: 10...30)
        let move = SKAction.moveBy(
            x: cos(angle) * distance,
            y: sin(angle) * distance,
            duration: 0.1
        )

        spark.run(SKAction.sequence([
            move,
            SKAction.fadeOut(withDuration: 0.1),
            SKAction.removeFromParent()
        ]))
    }

    /// Показать вспышку при нанесении урона
    private func showDamageFlash() {
        let flash = SKSpriteNode(color: .white, size: size)
        flash.alpha = 0.5
        flash.zPosition = 10
        addChild(flash)

        flash.run(SKAction.sequence([
            SKAction.fadeOut(withDuration: 0.1),
            SKAction.removeFromParent()
        ]))
    }

    // MARK: - Cleanup

    /// Очистка при удалении
    func cleanup() {
        stopPeriodicDamage()
        removeAction(forKey: visualEffectKey)
        removeAllActions()
    }
}
