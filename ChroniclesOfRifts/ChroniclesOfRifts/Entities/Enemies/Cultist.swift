import SpriteKit

// MARK: - Cultist

/// Культист — базовый враг для первых уровней (1-3)
/// Простой враг с кинжалом, патрулирует территорию и преследует игрока
class Cultist: Enemy {

    // MARK: - Constants

    /// Размер спрайта культиста
    private static let spriteSize = CGSize(width: 24, height: 32)

    /// Цвет placeholder (тёмно-красный)
    private static let placeholderColor = UIColor(red: 0.545, green: 0, blue: 0, alpha: 1.0)

    /// Задержка при обнаружении игрока (эффект "!")
    private let alertDelay: TimeInterval = 0.3

    // MARK: - Alert State

    /// Находится ли культист в состоянии "обнаружил игрока"
    private var isAlerted: Bool = false

    /// Нода эффекта "!"
    private var alertIndicator: SKLabelNode?

    // MARK: - Init

    /// Инициализация культиста
    init() {
        super.init(config: .cultist, entityType: "cultist")

        // Устанавливаем правильный размер
        self.size = Cultist.spriteSize
        self.color = Cultist.placeholderColor

        // Перенастраиваем физическое тело под новый размер
        setupPhysicsBody(size: Cultist.spriteSize)

        // Загружаем placeholder анимации
        AnimationManager.shared.preloadAnimations(for: "cultist")

        // Запускаем idle анимацию
        playAnimation(for: .idle)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) не реализован")
    }

    // MARK: - State Machine Override

    override func onStateEnter(_ state: EnemyState) {
        switch state {
        case .chase:
            // При обнаружении игрока — показываем эффект "!" и задержка
            if !isAlerted {
                showAlertEffect()
            }

        case .idle, .patrol:
            // Сбрасываем состояние алерта когда теряем игрока
            isAlerted = false
            hideAlertEffect()

        case .dead:
            // Проверяем, была ли смерть от stomp
            // (вызывается из handleStomp, который устанавливает флаг)
            break

        default:
            break
        }

        super.onStateEnter(state)
    }

    // MARK: - Chase Override

    override func updateChase(deltaTime: TimeInterval, target: Player) {
        // Если в состоянии алерта — стоим на месте
        guard isAlerted == false || alertIndicator == nil else {
            return
        }

        // Проверяем, видим ли ещё игрока
        if !canSeePlayer(target) {
            let distance = hypot(target.position.x - position.x, target.position.y - position.y)
            if distance > config.detectionRange * 1.5 {
                // Потеряли игрока — возвращаемся к патрулированию
                targetPlayer = nil
                changeState(to: .patrol)
                return
            }
        }

        super.updateChase(deltaTime: deltaTime, target: target)
    }

    // MARK: - Alert Effect

    /// Показать эффект "!" над головой
    private func showAlertEffect() {
        guard alertIndicator == nil else { return }

        // Создаём "!" над головой
        let indicator = SKLabelNode(text: "!")
        indicator.fontName = "Helvetica-Bold"
        indicator.fontSize = 16
        indicator.fontColor = .yellow
        indicator.position = CGPoint(x: 0, y: size.height / 2 + 12)
        indicator.zPosition = 100
        indicator.name = "alertIndicator"

        addChild(indicator)
        alertIndicator = indicator

        // Анимация появления
        indicator.setScale(0)
        indicator.run(SKAction.sequence([
            SKAction.scale(to: 1.2, duration: 0.1),
            SKAction.scale(to: 1.0, duration: 0.05)
        ]))

        // Через alertDelay убираем индикатор и начинаем преследование
        run(SKAction.sequence([
            SKAction.wait(forDuration: alertDelay),
            SKAction.run { [weak self] in
                self?.isAlerted = true
                self?.hideAlertEffect()
            }
        ]), withKey: "alertSequence")
    }

    /// Скрыть эффект "!"
    private func hideAlertEffect() {
        removeAction(forKey: "alertSequence")
        alertIndicator?.removeFromParent()
        alertIndicator = nil
    }

    // MARK: - Stomp Death

    /// Обработка прыжка игрока сверху (stomp) с эффектом сплющивания
    override func handleStomp(by player: Player) {
        guard config.canBeStomped && currentState != .dead else { return }

        // Даём игроку отскок
        player.bounce()

        // Эффект сплющивания (squash)
        playSquashEffect()

        // Наносим урон (это вызовет смерть, т.к. HP = 1)
        let stompHitInfo = HitInfo(
            damage: 1,
            knockbackForce: 0,
            knockbackDirection: 0,
            source: player
        )
        takeDamage(stompHitInfo)
    }

    /// Эффект сплющивания при смерти от stomp
    private func playSquashEffect() {
        // Отключаем стандартную анимацию смерти
        removeAllActions()

        // Сплющивание
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

    // MARK: - Death Override

    override func die() {
        // Отключаем физику
        physicsBody?.isDynamic = false
        physicsBody?.categoryBitMask = 0
        physicsBody?.contactTestBitMask = 0

        // Скрываем алерт если был
        hideAlertEffect()

        // Если уже запущена squash анимация — не запускаем стандартную
        if xScale != 1.0 || yScale != 1.0 {
            // Squash эффект уже активен, просто отправляем уведомление
            NotificationCenter.default.post(
                name: .enemyDied,
                object: self,
                userInfo: ["enemy": self, "scoreValue": config.scoreValue]
            )
            return
        }

        // Стандартная анимация смерти
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

    // MARK: - Damage Override

    override func takeDamage(_ hitInfo: HitInfo) {
        guard currentState != .dead else { return }

        // Скрываем алерт при получении урона
        hideAlertEffect()
        isAlerted = false

        super.takeDamage(hitInfo)
    }
}
