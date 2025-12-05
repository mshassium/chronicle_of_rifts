import SpriteKit

/// Разрушающаяся платформа, которая падает после того, как игрок на неё наступит
class CrumblingPlatform: SKSpriteNode {

    // MARK: - Properties

    /// Задержка перед падением после активации (секунды)
    var crumbleDelay: TimeInterval = 1.0

    /// Задержка перед респавном после падения (секунды)
    var respawnDelay: TimeInterval = 3.0

    /// Была ли платформа активирована (игрок наступил)
    private(set) var isTriggered: Bool = false

    /// Упала ли платформа
    private(set) var isFallen: Bool = false

    /// Оригинальная позиция платформы для респавна
    private var originalPosition: CGPoint = .zero

    /// Сохранённое физическое тело для восстановления после респавна
    private var savedPhysicsBodyConfig: PhysicsBodyConfig?

    /// Ключ анимации тряски
    private let shakeActionKey = "crumblingShake"

    // MARK: - Physics Body Configuration

    private struct PhysicsBodyConfig {
        let size: CGSize
        let categoryBitMask: UInt32
        let contactTestBitMask: UInt32
        let collisionBitMask: UInt32
    }

    // MARK: - Initialization

    init(size: CGSize, texture: SKTexture? = nil) {
        let color = SKColor(red: 0.5, green: 0.4, blue: 0.3, alpha: 1.0)
        super.init(texture: texture, color: color, size: size)

        name = "platform_crumbling"

        // Создаём физическое тело
        setupPhysicsBody(size: size)

        // Добавляем визуальные "трещины" для отличия от обычных платформ
        addCracks()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupPhysicsBody(size: CGSize) {
        physicsBody = SKPhysicsBody(rectangleOf: size)
        physicsBody?.isDynamic = false
        physicsBody?.categoryBitMask = PhysicsCategory.ground
        physicsBody?.contactTestBitMask = PhysicsCategory.player
        physicsBody?.collisionBitMask = PhysicsCategory.player | PhysicsCategory.enemy

        // Сохраняем конфигурацию для восстановления
        savedPhysicsBodyConfig = PhysicsBodyConfig(
            size: size,
            categoryBitMask: PhysicsCategory.ground,
            contactTestBitMask: PhysicsCategory.player,
            collisionBitMask: PhysicsCategory.player | PhysicsCategory.enemy
        )
    }

    private func addCracks() {
        // Добавляем несколько линий-трещин для визуального отличия
        let crackColor = SKColor(red: 0.3, green: 0.25, blue: 0.2, alpha: 1.0)

        // Горизонтальная трещина
        let crack1 = SKShapeNode()
        let path1 = CGMutablePath()
        path1.move(to: CGPoint(x: -size.width * 0.3, y: size.height * 0.1))
        path1.addLine(to: CGPoint(x: size.width * 0.2, y: -size.height * 0.05))
        crack1.path = path1
        crack1.strokeColor = crackColor
        crack1.lineWidth = 1.5
        crack1.zPosition = 1
        addChild(crack1)

        // Диагональная трещина
        let crack2 = SKShapeNode()
        let path2 = CGMutablePath()
        path2.move(to: CGPoint(x: size.width * 0.1, y: size.height * 0.2))
        path2.addLine(to: CGPoint(x: -size.width * 0.1, y: -size.height * 0.15))
        crack2.path = path2
        crack2.strokeColor = crackColor
        crack2.lineWidth = 1.5
        crack2.zPosition = 1
        addChild(crack2)
    }

    /// Сохраняет оригинальную позицию (вызывается после добавления в сцену)
    func saveOriginalPosition() {
        originalPosition = position
    }

    // MARK: - Trigger & Fall

    /// Активирует платформу (начинает обратный отсчёт до падения)
    func trigger() {
        // Не активируем повторно
        guard !isTriggered && !isFallen else { return }

        isTriggered = true

        // Запускаем тряску
        startShaking()

        // Через crumbleDelay - падаем
        run(SKAction.sequence([
            SKAction.wait(forDuration: crumbleDelay),
            SKAction.run { [weak self] in
                self?.fall()
            }
        ]), withKey: "crumbleFallSequence")
    }

    /// Платформа падает вниз
    private func fall() {
        guard !isFallen else { return }

        isFallen = true

        // Останавливаем тряску
        stopShaking()

        // Создаём частицы при разрушении
        createFallParticles()

        // Убираем коллизии
        physicsBody?.categoryBitMask = 0
        physicsBody?.collisionBitMask = 0
        physicsBody?.contactTestBitMask = 0

        // Включаем динамику для падения
        physicsBody?.isDynamic = true
        physicsBody?.affectedByGravity = true

        // Добавляем небольшое вращение при падении
        physicsBody?.angularVelocity = CGFloat.random(in: -2...2)

        // Анимация исчезновения + респавн
        run(SKAction.sequence([
            SKAction.wait(forDuration: 0.5),
            SKAction.fadeOut(withDuration: 0.3),
            SKAction.run { [weak self] in
                self?.hide()
            },
            SKAction.wait(forDuration: (respawnDelay - 0.8)),
            SKAction.run { [weak self] in
                self?.respawn()
            }
        ]), withKey: "crumbleRespawnSequence")
    }

    /// Скрывает платформу после падения
    private func hide() {
        isHidden = true
        physicsBody?.isDynamic = false
    }

    /// Респавн платформы в оригинальной позиции
    private func respawn() {
        // Сбрасываем состояние
        isTriggered = false
        isFallen = false

        // Возвращаем на оригинальную позицию
        position = originalPosition
        zRotation = 0

        // Восстанавливаем физическое тело
        if let config = savedPhysicsBodyConfig {
            physicsBody = SKPhysicsBody(rectangleOf: config.size)
            physicsBody?.isDynamic = false
            physicsBody?.categoryBitMask = config.categoryBitMask
            physicsBody?.contactTestBitMask = config.contactTestBitMask
            physicsBody?.collisionBitMask = config.collisionBitMask
        }

        // Показываем платформу с анимацией появления
        alpha = 0
        isHidden = false

        run(SKAction.fadeIn(withDuration: 0.3))
    }

    // MARK: - Visual Effects

    /// Запускает анимацию тряски
    private func startShaking() {
        let shakeAmount: CGFloat = 2.0
        let shakeDuration: TimeInterval = 0.05

        let shakeLeft = SKAction.moveBy(x: -shakeAmount, y: 0, duration: shakeDuration)
        let shakeRight = SKAction.moveBy(x: shakeAmount * 2, y: 0, duration: shakeDuration * 2)
        let shakeBack = SKAction.moveBy(x: -shakeAmount, y: 0, duration: shakeDuration)

        let shakeSequence = SKAction.sequence([shakeLeft, shakeRight, shakeBack])
        let repeatShake = SKAction.repeatForever(shakeSequence)

        run(repeatShake, withKey: shakeActionKey)
    }

    /// Останавливает анимацию тряски
    private func stopShaking() {
        removeAction(forKey: shakeActionKey)

        // Возвращаем к оригинальной позиции X (могла сместиться от тряски)
        position.x = originalPosition.x
    }

    /// Создаёт частицы при падении платформы
    private func createFallParticles() {
        guard let parent = parent else { return }

        // Создаём несколько маленьких кусочков, разлетающихся в стороны
        let particleCount = 6
        let particleSize = CGSize(width: size.width / 4, height: size.height / 3)

        for i in 0..<particleCount {
            let particle = SKSpriteNode(color: color, size: particleSize)
            particle.position = position
            particle.zPosition = zPosition
            parent.addChild(particle)

            // Случайное направление разлёта
            let angle = CGFloat(i) * (.pi * 2 / CGFloat(particleCount)) + CGFloat.random(in: -0.3...0.3)
            let speed: CGFloat = CGFloat.random(in: 50...100)
            let dx = cos(angle) * speed
            let dy = sin(angle) * speed + 50 // Немного вверх

            let moveAction = SKAction.move(
                by: CGVector(dx: dx, dy: dy - 100), // -100 для падения вниз
                duration: 0.5
            )
            let fadeAction = SKAction.fadeOut(withDuration: 0.5)
            let rotateAction = SKAction.rotate(byAngle: CGFloat.random(in: -2...2), duration: 0.5)
            let scaleAction = SKAction.scale(to: 0.5, duration: 0.5)

            let group = SKAction.group([moveAction, fadeAction, rotateAction, scaleAction])
            particle.run(SKAction.sequence([group, SKAction.removeFromParent()]))
        }
    }
}
