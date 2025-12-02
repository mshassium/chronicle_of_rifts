import SpriteKit

// MARK: - CorruptedSpirit

/// Повреждённый Дух — летающий призрачный враг для уровня 3 (Корни Мира)
/// Призрачное существо, заражённое скверной. Летает по синусоиде,
/// периодически становится неуязвимым, может проходить сквозь платформы.
class CorruptedSpirit: Enemy {

    // MARK: - Constants

    /// Размер спрайта духа
    private static let spriteSize = CGSize(width: 28, height: 28)

    /// Цвет placeholder (полупрозрачный фиолетовый)
    private static let placeholderColor = UIColor(red: 0.6, green: 0.2, blue: 0.8, alpha: 0.7)

    /// Конфигурация для призрака
    private static let spiritConfig = EnemyConfig(
        health: 1,
        damage: 1,
        moveSpeed: 60,
        detectionRange: 200,
        attackRange: 30,
        attackCooldown: 1.0,
        scoreValue: 15,
        canBeStomped: false,
        knockbackResistance: 0.5
    )

    // MARK: - Sinusoidal Movement

    /// Амплитуда вертикального смещения (пиксели)
    private let waveAmplitude: CGFloat = 30

    /// Частота волны
    private let waveFrequency: CGFloat = 2.0

    /// Общее время с момента создания (для синусоиды)
    private var totalTime: TimeInterval = 0

    /// Базовая позиция Y (вокруг которой колеблется призрак)
    private var baseY: CGFloat = 0

    // MARK: - Intangibility (Неуязвимость)

    /// Находится ли призрак в неуязвимом (прозрачном) состоянии
    private var isIntangible: Bool = false

    /// Таймер до следующего перехода в неуязвимость
    private var intangibilityTimer: TimeInterval = 3.0

    /// Длительность интервала между переходами в неуязвимость
    private let intangibilityInterval: TimeInterval = 3.0

    /// Длительность неуязвимости
    private let intangibilityDuration: TimeInterval = 1.5

    /// Прозрачность в неуязвимом состоянии
    private let intangibleAlpha: CGFloat = 0.3

    // MARK: - Glow Effect

    /// Нода эффекта свечения
    private var glowNode: SKEffectNode?

    /// Спрайт внутри эффекта свечения
    private var glowSprite: SKSpriteNode?

    // MARK: - Init

    /// Инициализация повреждённого духа
    init() {
        super.init(config: CorruptedSpirit.spiritConfig, entityType: "corruptedSpirit")

        // Устанавливаем правильный размер
        self.size = CorruptedSpirit.spriteSize
        self.color = CorruptedSpirit.placeholderColor

        // Перенастраиваем физическое тело для призрака
        setupGhostPhysicsBody()

        // Настраиваем свечение
        setupGlowEffect()

        // Загружаем placeholder анимации
        AnimationManager.shared.preloadAnimations(for: "corruptedSpirit")

        // Запускаем idle анимацию
        playAnimation(for: .idle)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) не реализован")
    }

    // MARK: - Setup

    /// Настройка физического тела призрака (игнорирует гравитацию и платформы)
    private func setupGhostPhysicsBody() {
        let colliderSize = CGSize(
            width: CorruptedSpirit.spriteSize.width * 0.7,
            height: CorruptedSpirit.spriteSize.height * 0.7
        )
        let physicsBody = SKPhysicsBody(rectangleOf: colliderSize)

        physicsBody.isDynamic = true
        physicsBody.allowsRotation = false
        physicsBody.friction = 0
        physicsBody.restitution = 0
        physicsBody.linearDamping = 0

        // Призрак не подчиняется гравитации
        physicsBody.affectedByGravity = false

        physicsBody.categoryBitMask = PhysicsCategory.enemy
        // Призрак не сталкивается ни с чем (проходит сквозь платформы)
        physicsBody.collisionBitMask = 0
        physicsBody.contactTestBitMask = PhysicsCategory.player | PhysicsCategory.playerAttack

        self.physicsBody = physicsBody
    }

    /// Настройка эффекта свечения
    private func setupGlowEffect() {
        // Создаём EffectNode для свечения
        let effectNode = SKEffectNode()
        effectNode.shouldRasterize = true
        effectNode.shouldEnableEffects = true
        effectNode.zPosition = -1

        // Настраиваем blur filter для свечения
        let blurFilter = CIFilter(name: "CIGaussianBlur")
        blurFilter?.setValue(8.0, forKey: kCIInputRadiusKey)
        effectNode.filter = blurFilter

        // Создаём спрайт для свечения (больше основного)
        let glowSize = CGSize(
            width: CorruptedSpirit.spriteSize.width * 1.5,
            height: CorruptedSpirit.spriteSize.height * 1.5
        )
        let sprite = SKSpriteNode(
            color: UIColor(red: 0.6, green: 0.2, blue: 0.8, alpha: 0.5),
            size: glowSize
        )

        effectNode.addChild(sprite)
        addChild(effectNode)

        glowNode = effectNode
        glowSprite = sprite

        // Анимация пульсации свечения
        let pulseAction = SKAction.repeatForever(
            SKAction.sequence([
                SKAction.fadeAlpha(to: 0.3, duration: 0.8),
                SKAction.fadeAlpha(to: 0.6, duration: 0.8)
            ])
        )
        effectNode.run(pulseAction, withKey: "glowPulse")
    }

    // MARK: - Update Override

    override func update(deltaTime: TimeInterval) {
        guard currentState != .dead else { return }

        // Обновляем общее время
        totalTime += deltaTime

        // Обновляем таймер неуязвимости
        updateIntangibility(deltaTime: deltaTime)

        // Вызываем базовый update
        super.update(deltaTime: deltaTime)

        // Применяем синусоидальное движение по вертикали
        applySinusoidalMovement()
    }

    /// Обновление состояния неуязвимости
    private func updateIntangibility(deltaTime: TimeInterval) {
        intangibilityTimer -= deltaTime

        if intangibilityTimer <= 0 {
            if isIntangible {
                // Выходим из неуязвимости
                becomeVulnerable()
                intangibilityTimer = intangibilityInterval
            } else {
                // Входим в неуязвимость
                becomeIntangible()
                intangibilityTimer = intangibilityDuration
            }
        }
    }

    /// Переход в неуязвимое состояние
    private func becomeIntangible() {
        isIntangible = true

        // Проигрываем анимацию перехода
        playFadeAnimation(toAlpha: intangibleAlpha)

        // Обновляем свечение
        glowNode?.run(SKAction.fadeAlpha(to: 0.15, duration: 0.3))
    }

    /// Выход из неуязвимого состояния
    private func becomeVulnerable() {
        isIntangible = false

        // Проигрываем анимацию возврата
        playFadeAnimation(toAlpha: 1.0)

        // Восстанавливаем свечение
        glowNode?.run(SKAction.fadeAlpha(to: 0.6, duration: 0.3))
    }

    /// Анимация перехода прозрачности
    private func playFadeAnimation(toAlpha: CGFloat) {
        run(SKAction.fadeAlpha(to: toAlpha, duration: 0.3), withKey: "fadeTransition")
    }

    /// Применение синусоидального движения по вертикали
    private func applySinusoidalMovement() {
        // Если базовая позиция не установлена, используем текущую
        if baseY == 0 {
            baseY = position.y
        }

        // Синусоидальное смещение
        let verticalOffset = sin(CGFloat(totalTime) * waveFrequency) * waveAmplitude

        // Применяем только смещение, не трогая velocity (чтобы не мешать горизонтальному движению)
        // Используем прямое изменение позиции для вертикали
        position.y = baseY + verticalOffset
    }

    // MARK: - Patrol Override

    override func updatePatrol(deltaTime: TimeInterval) {
        // Проверяем игрока
        if let player = detectPlayer() {
            targetPlayer = player
            changeState(to: .chase)
            return
        }

        // Призрак не проверяет края платформ — он летает!

        // Движение к следующей точке патрулирования
        if let targetPoint = getNextPatrolPoint() {
            moveTowards(point: targetPoint)

            // Проверяем достижение точки (только по X, т.к. Y колеблется)
            let distance = abs(position.x - targetPoint.x)
            if distance < 10 {
                // Обновляем базовую позицию Y для следующего отрезка
                baseY = targetPoint.y
                currentPatrolIndex = (currentPatrolIndex + 1) % (patrolPath?.count ?? 1)
                changeState(to: .idle)
            }
        } else {
            // Если нет пути, просто ходим туда-сюда
            if let body = physicsBody {
                body.velocity.dx = facingDirection == .right ? config.moveSpeed : -config.moveSpeed
            }
        }
    }

    /// Текущий индекс патрулирования (переопределяем доступ)
    private var currentPatrolIndex: Int = 0

    // MARK: - Chase Override

    override func updateChase(deltaTime: TimeInterval, target: Player) {
        // Призрак не может атаковать в неуязвимом состоянии
        if isIntangible {
            // Просто следуем за игроком, но не атакуем
            let distance = hypot(target.position.x - position.x, target.position.y - position.y)

            if distance > config.detectionRange * 1.5 {
                targetPlayer = nil
                changeState(to: .patrol)
                return
            }

            // Двигаемся к игроку (медленнее в неуязвимом состоянии)
            let direction = target.position.x > position.x ? 1.0 : -1.0
            physicsBody?.velocity.dx = CGFloat(direction) * config.moveSpeed * 0.5

            // Обновляем базовую Y к позиции игрока (плавно)
            let targetBaseY = target.position.y
            baseY += (targetBaseY - baseY) * 0.02

            return
        }

        let distance = hypot(target.position.x - position.x, target.position.y - position.y)

        // Если игрок вне радиуса обнаружения, прекращаем преследование
        if distance > config.detectionRange * 1.5 {
            targetPlayer = nil
            changeState(to: .patrol)
            return
        }

        // Призрак плывёт прямо к игроку (игнорируя препятствия)
        let direction = target.position.x > position.x ? 1.0 : -1.0
        physicsBody?.velocity.dx = CGFloat(direction) * config.moveSpeed

        // Обновляем базовую Y к позиции игрока (плавно)
        let targetBaseY = target.position.y
        baseY += (targetBaseY - baseY) * 0.05
    }

    // MARK: - Combat Override

    override func takeDamage(_ hitInfo: HitInfo) {
        // Призрак неуязвим в прозрачном состоянии
        guard !isIntangible else { return }
        guard currentState != .dead else { return }

        super.takeDamage(hitInfo)
    }

    override func dealContactDamage(to player: Player) {
        // Призрак не может наносить урон в прозрачном состоянии
        guard !isIntangible else { return }

        super.dealContactDamage(to: player)
    }

    // MARK: - Death Override

    override func die() {
        // Останавливаем все эффекты
        glowNode?.removeAllActions()
        removeAction(forKey: "fadeTransition")

        // Отключаем физику
        physicsBody?.isDynamic = false
        physicsBody?.categoryBitMask = 0
        physicsBody?.contactTestBitMask = 0

        // Анимация рассеивания (специальная для призрака)
        let dissipateAnimation = SKAction.sequence([
            SKAction.group([
                SKAction.fadeOut(withDuration: 0.6),
                SKAction.scale(to: 1.5, duration: 0.6),
                // Эффект "растворения" вверх
                SKAction.moveBy(x: 0, y: 30, duration: 0.6)
            ]),
            SKAction.removeFromParent()
        ])

        // Свечение тоже рассеивается
        glowNode?.run(SKAction.sequence([
            SKAction.group([
                SKAction.fadeOut(withDuration: 0.4),
                SKAction.scale(to: 2.0, duration: 0.4)
            ])
        ]))

        run(dissipateAnimation)

        // Отправляем уведомление о смерти
        NotificationCenter.default.post(
            name: .enemyDied,
            object: self,
            userInfo: ["enemy": self, "scoreValue": config.scoreValue]
        )
    }

    // MARK: - Animation Override

    override func getAnimationName(for state: EnemyState) -> String {
        switch state {
        case .idle: return "idle"
        case .patrol: return "move"
        case .chase: return "move"
        case .attack: return "move"
        case .hurt: return "idle"  // Призрак не имеет hurt анимации
        case .dead: return "death"
        }
    }

    // MARK: - Stomp Override

    override func handleStomp(by player: Player) {
        // Призрака нельзя убить прыжком сверху (canBeStomped = false)
        // Вместо этого игрок получает урон
        if !isIntangible {
            dealContactDamage(to: player)
        }
    }

    // MARK: - Gravity Override

    /// Переопределяем setGrounded, т.к. призрак всегда "в воздухе"
    override func setGrounded(_ grounded: Bool) {
        // Призрак никогда не касается земли
        // Ничего не делаем
    }
}
