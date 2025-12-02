import SpriteKit

/// Летающий глаз - стреляющий враг
/// Парит в воздухе, стреляет магическими снарядами в игрока
final class FloatingEye: Enemy {

    // MARK: - State

    /// Состояния летающего глаза
    private enum FloatingEyeState {
        case patrol     // Парит вверх-вниз
        case alert      // Обнаружил игрока, фокусируется
        case attack     // Стреляет
        case retreat    // Отступает от игрока
    }

    /// Текущее состояние глаза
    private var eyeState: FloatingEyeState = .patrol

    // MARK: - Config

    /// Скорость полёта
    private let flySpeed: CGFloat = 40

    /// Радиус обнаружения
    private let detectionRadius: CGFloat = 250

    /// Дальность стрельбы
    private let shootingRange: CGFloat = 200

    /// Интервал стрельбы
    private let shootInterval: TimeInterval = 2.0

    /// Дистанция отступления
    private let retreatDistance: CGFloat = 80

    /// Пауза после выстрела
    private let shootRecoilTime: TimeInterval = 0.5

    // MARK: - Timers

    /// Таймер стрельбы
    private var shootTimer: TimeInterval = 0

    /// Таймер отдачи
    private var recoilTimer: TimeInterval = 0

    /// Таймер предупреждения перед выстрелом
    private var alertTimer: TimeInterval = 0

    // MARK: - Patrol

    /// Начальная позиция для патрулирования
    private var patrolStartY: CGFloat = 0

    /// Амплитуда парения
    private let floatAmplitude: CGFloat = 20

    /// Скорость парения
    private let floatSpeed: CGFloat = 2.0

    /// Текущий угол парения
    private var floatAngle: CGFloat = 0

    // MARK: - Visual

    /// Спрайт зрачка
    private var pupilNode: SKSpriteNode?

    /// Максимальное смещение зрачка
    private let maxPupilOffset: CGFloat = 4

    // MARK: - Projectile Tracking

    /// Активные снаряды (для обновления)
    private var activeProjectiles: [EyeProjectile] = []

    // MARK: - Bounds

    /// Границы уровня для ограничения отступления
    var levelBounds: CGRect = .zero

    // MARK: - Movement

    /// Текущая скорость глаза (своя, т.к. базовая velocity - private set)
    private var eyeVelocity: CGVector = .zero

    // MARK: - Init

    init() {
        // Создаём конфигурацию FloatingEye
        let config = EnemyConfig(
            health: 1,
            damage: 1,
            moveSpeed: 40,
            detectionRange: 250,
            attackRange: 200,
            attackCooldown: 2.0,
            scoreValue: 20,
            canBeStomped: false,
            knockbackResistance: 0.0
        )

        super.init(config: config, entityType: "floatingEye")

        // Устанавливаем размер
        self.size = CGSize(width: 32, height: 32)

        // Настройка визуала
        setupVisual()
        setupPhysicsForFlying()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) не реализован")
    }

    // MARK: - Setup

    /// Настройка визуального отображения глаза
    private func setupVisual() {
        // Основной цвет - белый глаз
        self.color = .white

        // Красный зрачок
        let pupil = SKSpriteNode(color: .red, size: CGSize(width: 10, height: 10))
        pupil.name = "pupil"
        pupil.zPosition = 1
        addChild(pupil)
        self.pupilNode = pupil

        // Чёрная обводка (глаз)
        let outline = SKShapeNode(ellipseOf: CGSize(width: 32, height: 32))
        outline.strokeColor = .black
        outline.lineWidth = 2
        outline.fillColor = .clear
        outline.zPosition = 2
        addChild(outline)
    }

    /// Настройка физики для летающего врага
    private func setupPhysicsForFlying() {
        guard let body = physicsBody else { return }

        // Летающий враг не подвержен гравитации
        body.affectedByGravity = false

        // Не сталкивается с землёй (летает)
        body.collisionBitMask = 0
    }

    // MARK: - Setup Position

    /// Устанавливает начальную позицию Y для патрулирования
    func setupPatrolPosition() {
        patrolStartY = position.y
    }

    // MARK: - Update

    override func update(deltaTime: TimeInterval) {
        guard currentState != .dead else { return }

        // Обновляем таймеры
        updateEyeTimers(deltaTime: deltaTime)

        // Обновляем состояние глаза
        updateEyeAI(deltaTime: deltaTime)

        // Обновляем зрачок (следит за игроком)
        updatePupil()

        // Обновляем снаряды
        updateProjectiles(deltaTime: deltaTime)

        // Применяем скорость (без гравитации для летающего врага)
        physicsBody?.velocity = eyeVelocity
    }

    /// Обновление таймеров глаза
    private func updateEyeTimers(deltaTime: TimeInterval) {
        if shootTimer > 0 {
            shootTimer -= deltaTime
        }

        if recoilTimer > 0 {
            recoilTimer -= deltaTime
        }

        if alertTimer > 0 {
            alertTimer -= deltaTime
        }

        // Обновляем угол парения
        floatAngle += CGFloat(deltaTime) * floatSpeed
    }

    /// Обновление AI глаза
    private func updateEyeAI(deltaTime: TimeInterval) {
        // Проверяем игрока
        let playerDistance = distanceToPlayer()

        switch eyeState {
        case .patrol:
            updatePatrolState(deltaTime: deltaTime)

            // Переход в alert при обнаружении игрока
            if playerDistance <= detectionRadius {
                if let player = detectPlayer() {
                    targetPlayer = player
                    transitionTo(.alert)
                }
            }

        case .alert:
            eyeVelocity = .zero
            alertTimer -= deltaTime

            // После 0.5 сек переходим к атаке или отступлению
            if alertTimer <= 0 {
                if playerDistance < retreatDistance {
                    transitionTo(.retreat)
                } else if playerDistance <= shootingRange && shootTimer <= 0 {
                    transitionTo(.attack)
                } else {
                    transitionTo(.patrol)
                }
            }

        case .attack:
            eyeVelocity = .zero

            if recoilTimer <= 0 {
                // Проверяем, нужно ли отступать
                if playerDistance < retreatDistance {
                    transitionTo(.retreat)
                } else if playerDistance > shootingRange {
                    transitionTo(.patrol)
                } else if shootTimer <= 0 {
                    // Стреляем снова или переходим в patrol
                    transitionTo(.alert)
                }
            }

        case .retreat:
            updateRetreatState(deltaTime: deltaTime)

            // Если отдалились достаточно, возвращаемся к патрулированию
            if playerDistance >= retreatDistance * 1.5 {
                transitionTo(.patrol)
            }
        }
    }

    /// Обновление состояния патрулирования
    private func updatePatrolState(deltaTime: TimeInterval) {
        // Парим вверх-вниз
        let floatOffset = sin(floatAngle) * floatAmplitude
        let targetY = patrolStartY + floatOffset

        eyeVelocity.dy = (targetY - position.y) * 2

        // Небольшое горизонтальное колебание
        eyeVelocity.dx = sin(floatAngle * 0.5) * flySpeed * 0.3
    }

    /// Обновление состояния отступления
    private func updateRetreatState(deltaTime: TimeInterval) {
        guard let playerPos = targetPlayer?.position else {
            transitionTo(.patrol)
            return
        }

        // Направление от игрока
        let dx = position.x - playerPos.x
        let dy = position.y - playerPos.y
        let length = hypot(dx, dy)

        guard length > 0 else { return }

        // Движемся от игрока
        var retreatVelocity = CGVector(
            dx: (dx / length) * flySpeed * 2,
            dy: (dy / length) * flySpeed
        )

        // Ограничиваем отступление границами уровня
        if levelBounds != .zero {
            let nextX = position.x + retreatVelocity.dx * CGFloat(deltaTime)
            let nextY = position.y + retreatVelocity.dy * CGFloat(deltaTime)

            let margin: CGFloat = 50
            if nextX < levelBounds.minX + margin || nextX > levelBounds.maxX - margin {
                retreatVelocity.dx = 0
            }
            if nextY < levelBounds.minY + margin || nextY > levelBounds.maxY - margin {
                retreatVelocity.dy = 0
            }
        }

        eyeVelocity = retreatVelocity
    }

    /// Переход в новое состояние глаза
    private func transitionTo(_ newState: FloatingEyeState) {
        guard newState != eyeState else { return }

        eyeState = newState

        switch newState {
        case .patrol:
            playAnimation(for: .idle)

        case .alert:
            alertTimer = 0.5
            playAlertAnimation()

        case .attack:
            shoot()
            playAttackAnimation()

        case .retreat:
            playAnimation(for: .idle)
        }
    }

    // MARK: - Pupil

    /// Обновление позиции зрачка (следит за игроком)
    private func updatePupil() {
        guard let pupil = pupilNode else { return }

        if let playerPos = targetPlayer?.position {
            // Направление к игроку
            let dx = playerPos.x - position.x
            let dy = playerPos.y - position.y
            let distance = hypot(dx, dy)

            guard distance > 0 else { return }

            // Нормализованное направление, умноженное на максимальное смещение
            let offsetX = (dx / distance) * maxPupilOffset
            let offsetY = (dy / distance) * maxPupilOffset

            pupil.position = CGPoint(x: offsetX, y: offsetY)
        } else {
            // Возвращаем зрачок в центр
            pupil.position = .zero
        }
    }

    // MARK: - Combat

    /// Выстрел снарядом
    private func shoot() {
        guard let playerPos = targetPlayer?.position else { return }
        guard let parentNode = self.parent else { return }

        // Направление к игроку
        let dx = playerPos.x - position.x
        let dy = playerPos.y - position.y

        let direction = CGVector(dx: dx, dy: dy)

        // Создаём снаряд
        let projectile = EyeProjectile(direction: direction)
        projectile.position = position
        parentNode.addChild(projectile)

        // Отслеживаем снаряд
        activeProjectiles.append(projectile)

        // Запускаем таймеры
        shootTimer = shootInterval
        recoilTimer = shootRecoilTime
    }

    /// Обновление снарядов
    private func updateProjectiles(deltaTime: TimeInterval) {
        // Удаляем уничтоженные снаряды из списка
        activeProjectiles.removeAll { $0.parent == nil }

        // Обновляем активные снаряды
        for projectile in activeProjectiles {
            projectile.update(deltaTime: deltaTime)
        }
    }

    // MARK: - Animations

    /// Анимация предупреждения
    private func playAlertAnimation() {
        let animationName = "alert"
        removeAction(forKey: "enemyAnimation")

        if let action = AnimationManager.shared.createAnimationAction(name: animationName, for: entityType) {
            run(action, withKey: "enemyAnimation")
        }

        // Расширение зрачка
        pupilNode?.run(SKAction.scale(to: 1.3, duration: 0.2))
    }

    /// Анимация атаки
    private func playAttackAnimation() {
        let animationName = "attack"
        removeAction(forKey: "enemyAnimation")

        if let action = AnimationManager.shared.createAnimationAction(name: animationName, for: entityType) {
            run(action, withKey: "enemyAnimation")
        }

        // Сужение зрачка при выстреле
        pupilNode?.run(SKAction.sequence([
            SKAction.scale(to: 0.7, duration: 0.1),
            SKAction.scale(to: 1.0, duration: 0.3)
        ]))

        // Отдача
        let recoilDirection: CGFloat = (targetPlayer?.position.x ?? 0) > position.x ? -1 : 1
        run(SKAction.sequence([
            SKAction.moveBy(x: recoilDirection * 5, y: 0, duration: 0.05),
            SKAction.moveBy(x: recoilDirection * -5, y: 0, duration: 0.1)
        ]))
    }

    // MARK: - Helper

    /// Расстояние до игрока
    private func distanceToPlayer() -> CGFloat {
        guard let playerPos = targetPlayer?.position else { return .infinity }
        return hypot(position.x - playerPos.x, position.y - playerPos.y)
    }

    /// Override detectPlayer для использования собственного радиуса
    override func detectPlayer() -> Player? {
        guard let scene = scene else { return nil }

        for child in scene.children {
            if child.name == "gameLayer" {
                for entity in child.children {
                    if let player = entity as? Player {
                        let distance = hypot(player.position.x - position.x, player.position.y - position.y)
                        if distance <= detectionRadius {
                            return player
                        }
                    }
                }
            }
            if let player = child as? Player {
                let distance = hypot(player.position.x - position.x, player.position.y - position.y)
                if distance <= detectionRadius {
                    return player
                }
            }
        }

        return nil
    }

    // MARK: - Death

    override func die() {
        // Уничтожаем все снаряды при смерти
        for projectile in activeProjectiles {
            projectile.destroy()
        }
        activeProjectiles.removeAll()

        super.die()
    }
}
