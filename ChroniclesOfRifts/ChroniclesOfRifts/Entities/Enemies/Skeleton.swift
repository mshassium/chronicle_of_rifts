import SpriteKit

// MARK: - SkeletonState

/// Дополнительные состояния скелета (расширяем EnemyState)
enum SkeletonShieldState {
    case lowered    // Щит опущен
    case raised     // Щит поднят (блокирует атаки спереди)
}

// MARK: - Skeleton

/// Скелет — враг со щитом для уровня 4 (Катакомбы)
/// Может блокировать атаки спереди щитом, уязвим сзади и во время атаки
class Skeleton: Enemy {

    // MARK: - Constants

    /// Размер спрайта скелета
    private static let spriteSize = CGSize(width: 24, height: 40)

    /// Цвет placeholder (серо-белый, кости)
    private static let placeholderColor = UIColor(red: 0.85, green: 0.85, blue: 0.8, alpha: 1.0)

    /// Цвет щита
    private static let shieldColor = UIColor(red: 0.5, green: 0.4, blue: 0.3, alpha: 1.0)

    /// Конфигурация скелета
    private static let skeletonConfig = EnemyConfig(
        health: 2,
        damage: 1,
        moveSpeed: 70,
        detectionRange: 120,
        attackRange: 35,
        attackCooldown: 1.5,
        scoreValue: 25,
        canBeStomped: true,
        knockbackResistance: 0.3
    )

    // MARK: - Shield Properties

    /// Состояние щита
    private var shieldState: SkeletonShieldState = .lowered

    /// Нода щита
    private var shieldNode: SKSpriteNode?

    /// Окно уязвимости при атаке (сек)
    private let attackVulnerabilityWindow: TimeInterval = 0.5

    /// Находится ли в окне уязвимости
    private var isVulnerable: Bool = false

    // MARK: - Combat Timers

    /// Таймер перед атакой (опускаем щит)
    private var preAttackTimer: TimeInterval = 0
    private let preAttackDuration: TimeInterval = 0.3

    /// Таймер атаки
    private var attackDuration: TimeInterval = 0.5

    // MARK: - Init

    /// Инициализация скелета
    init() {
        super.init(config: Skeleton.skeletonConfig, entityType: "skeleton")

        // Устанавливаем правильный размер
        self.size = Skeleton.spriteSize
        self.color = Skeleton.placeholderColor

        // Перенастраиваем физическое тело под новый размер
        setupPhysicsBody(size: Skeleton.spriteSize)

        // Создаём щит
        setupShield()

        // Загружаем placeholder анимации
        AnimationManager.shared.preloadAnimations(for: "skeleton")

        // Запускаем idle анимацию
        playAnimation(for: .idle)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) не реализован")
    }

    // MARK: - Setup

    /// Настройка щита
    private func setupShield() {
        let shieldSize = CGSize(width: 8, height: 24)
        let shield = SKSpriteNode(color: Skeleton.shieldColor, size: shieldSize)
        shield.name = "shield"
        shield.zPosition = 1
        shield.position = CGPoint(x: size.width / 2 + 4, y: 0)
        shield.alpha = 0.8

        // Добавляем рамку щита
        let border = SKShapeNode(rectOf: shieldSize)
        border.strokeColor = .darkGray
        border.lineWidth = 1
        border.fillColor = .clear
        shield.addChild(border)

        addChild(shield)
        shieldNode = shield

        // Начальное положение — опущен
        updateShieldPosition(raised: false, animated: false)
    }

    // MARK: - Update Override

    override func update(deltaTime: TimeInterval) {
        super.update(deltaTime: deltaTime)

        // Обновляем положение щита в зависимости от направления
        updateShieldFacing()
    }

    // MARK: - State Machine Override

    override func onStateEnter(_ state: EnemyState) {
        switch state {
        case .chase:
            // При виде игрока поднимаем щит
            raiseShield()

        case .attack:
            // Опускаем щит для атаки (окно уязвимости)
            performSkeletonAttack()
            return // Не вызываем super, т.к. сами управляем атакой

        case .idle, .patrol:
            // Опускаем щит когда не видим игрока
            lowerShield()

        case .hurt:
            // При получении урона щит остаётся в текущем положении
            break

        case .dead:
            lowerShield()
        }

        super.onStateEnter(state)
    }

    override func onStateExit(_ state: EnemyState) {
        switch state {
        case .attack:
            // После атаки поднимаем щит обратно
            isVulnerable = false
            raiseShield()

        default:
            break
        }

        super.onStateExit(state)
    }

    // MARK: - Shield Control

    /// Поднять щит (блокировка атак спереди)
    private func raiseShield() {
        guard shieldState != .raised else { return }
        shieldState = .raised
        isVulnerable = false
        updateShieldPosition(raised: true, animated: true)
    }

    /// Опустить щит
    private func lowerShield() {
        guard shieldState != .lowered else { return }
        shieldState = .lowered
        updateShieldPosition(raised: false, animated: true)
    }

    /// Обновить позицию щита
    /// - Parameters:
    ///   - raised: Поднят ли щит
    ///   - animated: Анимировать ли переход
    private func updateShieldPosition(raised: Bool, animated: Bool) {
        guard let shield = shieldNode else { return }

        let raisedY: CGFloat = size.height / 4  // Щит на уровне груди
        let loweredY: CGFloat = -size.height / 4 // Щит внизу

        let targetY = raised ? raisedY : loweredY
        let targetRotation: CGFloat = raised ? 0 : CGFloat.pi / 6 // Наклон когда опущен

        if animated {
            let moveAction = SKAction.moveTo(y: targetY, duration: 0.15)
            let rotateAction = SKAction.rotate(toAngle: targetRotation, duration: 0.15)
            shield.run(SKAction.group([moveAction, rotateAction]))
        } else {
            shield.position.y = targetY
            shield.zRotation = targetRotation
        }
    }

    /// Обновить положение щита по направлению взгляда
    private func updateShieldFacing() {
        guard let shield = shieldNode else { return }

        // Щит всегда спереди (учитывая xScale)
        let offsetX: CGFloat = size.width / 2 + 4
        shield.position.x = facingDirection == .right ? offsetX : -offsetX
    }

    // MARK: - Attack

    /// Выполнить атаку скелета
    private func performSkeletonAttack() {
        // Опускаем щит — окно уязвимости
        lowerShield()
        isVulnerable = true

        // Последовательность атаки
        run(SKAction.sequence([
            // Замах
            SKAction.wait(forDuration: preAttackDuration),
            // Удар
            SKAction.run { [weak self] in
                self?.executeAttackHit()
            },
            // Окно уязвимости после атаки
            SKAction.wait(forDuration: attackVulnerabilityWindow),
            // Возврат в chase или idle
            SKAction.run { [weak self] in
                guard let self = self else { return }
                self.isVulnerable = false
                self.raiseShield()

                // Проверяем, видим ли ещё игрока
                if let player = self.detectPlayer() {
                    self.targetPlayer = player
                    self.changeState(to: .chase)
                } else {
                    self.changeState(to: .idle)
                }
            }
        ]), withKey: "skeletonAttack")
    }

    /// Выполнить удар
    private func executeAttackHit() {
        guard let player = targetPlayer else { return }

        // Проверяем, в радиусе ли атаки
        let distance = hypot(player.position.x - position.x, player.position.y - position.y)

        if distance <= config.attackRange + 10 {
            let knockbackDirection: CGFloat = player.position.x > position.x ? 1 : -1
            player.takeDamage(config.damage, knockbackDirection: knockbackDirection, knockbackForce: 250)
        }
    }

    // MARK: - Damage Override

    override func takeDamage(_ hitInfo: HitInfo) {
        guard currentState != .dead else { return }

        // Проверяем, заблокирован ли урон щитом
        if shouldBlockDamage(from: hitInfo) {
            playBlockEffect()
            return // Урон заблокирован
        }

        // Если в окне уязвимости или атака сзади — получаем урон
        super.takeDamage(hitInfo)
    }

    /// Проверить, должен ли щит заблокировать урон
    /// - Parameter hitInfo: Информация об ударе
    /// - Returns: true если урон заблокирован
    private func shouldBlockDamage(from hitInfo: HitInfo) -> Bool {
        // Если щит опущен или скелет уязвим — не блокируем
        guard shieldState == .raised && !isVulnerable else { return false }

        // Определяем направление атаки
        guard let attacker = hitInfo.source else { return false }

        let attackerX = attacker.position.x
        let selfX = position.x

        // Атака спереди = атакующий находится в направлении взгляда
        let attackFromRight = attackerX > selfX
        let attackFromLeft = attackerX < selfX

        let isFrontalAttack: Bool
        if facingDirection == .right {
            isFrontalAttack = attackFromRight
        } else {
            isFrontalAttack = attackFromLeft
        }

        // Блокируем только фронтальные атаки
        return isFrontalAttack
    }

    /// Эффект блокировки щитом (искры)
    private func playBlockEffect() {
        guard let shield = shieldNode else { return }

        // Искры при блоке
        let sparks = SKEmitterNode()
        sparks.particleTexture = nil
        sparks.particleBirthRate = 20
        sparks.numParticlesToEmit = 10
        sparks.particleLifetime = 0.3
        sparks.particleSpeed = 100
        sparks.particleSpeedRange = 50
        sparks.emissionAngleRange = CGFloat.pi * 2
        sparks.particleScale = 0.3
        sparks.particleScaleRange = 0.2
        sparks.particleColor = .yellow
        sparks.particleColorBlendFactor = 1.0
        sparks.particleAlphaSpeed = -3
        sparks.position = shield.position
        sparks.zPosition = 50

        addChild(sparks)

        // Удаляем эмиттер через время
        sparks.run(SKAction.sequence([
            SKAction.wait(forDuration: 0.5),
            SKAction.removeFromParent()
        ]))

        // Визуальный отклик щита
        shield.run(SKAction.sequence([
            SKAction.colorize(with: .white, colorBlendFactor: 0.8, duration: 0.05),
            SKAction.colorize(with: Skeleton.shieldColor, colorBlendFactor: 1.0, duration: 0.1)
        ]))

        // Небольшое отбрасывание через физику
        let knockbackDirection: CGFloat = facingDirection == .right ? -1 : 1
        physicsBody?.applyImpulse(CGVector(dx: knockbackDirection * 5, dy: 0))
    }

    // MARK: - Stomp Override

    override func handleStomp(by player: Player) {
        guard config.canBeStomped && currentState != .dead else { return }

        // Прыжок сверху игнорирует щит

        // Даём игроку отскок
        player.bounce()

        // Наносим урон
        let stompHitInfo = HitInfo(
            damage: 1,
            knockbackForce: 0,
            knockbackDirection: 0,
            source: player
        )

        // Обходим проверку щита при stomp
        super.takeDamage(stompHitInfo)
    }

    // MARK: - Chase Override

    override func updateChase(deltaTime: TimeInterval, target: Player) {
        // Если атакуем — не двигаемся
        guard currentState != .attack else { return }

        super.updateChase(deltaTime: deltaTime, target: target)
    }

    // MARK: - Death Override

    override func die() {
        // Убираем щит при смерти
        shieldNode?.run(SKAction.sequence([
            SKAction.group([
                SKAction.fadeOut(withDuration: 0.3),
                SKAction.rotate(byAngle: CGFloat.pi / 2, duration: 0.3)
            ]),
            SKAction.removeFromParent()
        ]))

        super.die()
    }
}
