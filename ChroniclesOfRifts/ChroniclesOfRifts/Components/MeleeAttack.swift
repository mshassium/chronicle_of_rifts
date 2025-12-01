import SpriteKit

/// Компонент ближней атаки
final class MeleeAttack: SKNode {

    // MARK: - Configuration
    struct Config {
        let damage: Int
        let knockbackForce: CGFloat
        let hitboxSize: CGSize
        let hitboxOffset: CGFloat      // Смещение от центра атакующего
        let duration: TimeInterval
        let cooldown: TimeInterval

        static let playerSword = Config(
            damage: 1,
            knockbackForce: 300,
            hitboxSize: CGSize(width: 40, height: 50),
            hitboxOffset: 30,
            duration: 0.2,
            cooldown: 0.5
        )
    }

    // MARK: - Properties
    private let config: Config
    private weak var owner: SKNode?
    private var hitEntities: Set<ObjectIdentifier> = []  // Избежать двойного урона

    // MARK: - Visual
    private var hitbox: SKSpriteNode?
    private var slashEffect: SKSpriteNode?

    // MARK: - Init
    init(config: Config, owner: SKNode) {
        self.config = config
        self.owner = owner
        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Attack Execution

    /// Выполнить атаку в указанном направлении
    /// - Parameter direction: Направление атаки (.left или .right)
    func execute(direction: Direction) {
        guard owner != nil else { return }

        // Очистить список попаданий
        hitEntities.removeAll()

        // Позиция хитбокса
        let offsetX = direction == .right ? config.hitboxOffset : -config.hitboxOffset
        let hitboxPosition = CGPoint(x: offsetX, y: 0)

        // Создать хитбокс
        createHitbox(at: hitboxPosition, direction: direction)

        // Создать визуальный эффект
        createSlashEffect(at: hitboxPosition, direction: direction)

        // Удалить через duration
        run(SKAction.sequence([
            SKAction.wait(forDuration: config.duration),
            SKAction.run { [weak self] in
                self?.cleanup()
            }
        ]))
    }

    // MARK: - Hitbox

    private func createHitbox(at position: CGPoint, direction: Direction) {
        hitbox = SKSpriteNode(color: .clear, size: config.hitboxSize)
        hitbox?.position = position
        hitbox?.name = "attackHitbox"

        // Debug визуализация (убрать в релизе)
        #if DEBUG
        hitbox?.color = UIColor.red.withAlphaComponent(0.3)
        #endif

        // Physics body
        hitbox?.physicsBody = SKPhysicsBody(rectangleOf: config.hitboxSize)
        hitbox?.physicsBody?.isDynamic = false
        hitbox?.physicsBody?.categoryBitMask = PhysicsCategory.playerAttack
        hitbox?.physicsBody?.contactTestBitMask = PhysicsCategory.enemy
        hitbox?.physicsBody?.collisionBitMask = 0

        // Сохраняем ссылку на атаку в userData
        hitbox?.userData = NSMutableDictionary()
        hitbox?.userData?["attack"] = self

        addChild(hitbox!)
    }

    // MARK: - Visual Effect

    private func createSlashEffect(at position: CGPoint, direction: Direction) {
        // Эффект взмаха меча
        slashEffect = SKSpriteNode(color: .white, size: CGSize(width: 50, height: 10))
        slashEffect?.position = position
        slashEffect?.alpha = 0.8
        slashEffect?.zPosition = 10

        // Поворот в зависимости от направления
        let startAngle: CGFloat = direction == .right ? CGFloat.pi / 4 : CGFloat.pi * 3 / 4
        let endAngle: CGFloat = direction == .right ? -CGFloat.pi / 4 : CGFloat.pi * 5 / 4

        slashEffect?.zRotation = startAngle

        // Анимация взмаха
        let swingAction = SKAction.sequence([
            SKAction.group([
                SKAction.rotate(toAngle: endAngle, duration: config.duration),
                SKAction.sequence([
                    SKAction.fadeAlpha(to: 1.0, duration: config.duration * 0.3),
                    SKAction.fadeAlpha(to: 0.0, duration: config.duration * 0.7)
                ])
            ])
        ])

        addChild(slashEffect!)
        slashEffect?.run(swingAction)
    }

    // MARK: - Hit Detection

    /// Вызывается при контакте с целью
    /// - Parameter target: Узел, с которым произошёл контакт
    /// - Returns: true если урон нанесён, false если цель уже была поражена
    func processHit(on target: SKNode) -> Bool {
        let id = ObjectIdentifier(target)
        guard !hitEntities.contains(id) else { return false }

        hitEntities.insert(id)

        // Вычисляем направление отбрасывания
        let knockbackDirection: CGFloat = target.position.x > (owner?.position.x ?? 0) ? 1 : -1

        // Уведомляем о попадании
        let hitInfo = HitInfo(
            damage: config.damage,
            knockbackForce: config.knockbackForce,
            knockbackDirection: knockbackDirection,
            source: owner
        )

        NotificationCenter.default.post(
            name: .entityHit,
            object: target,
            userInfo: ["hitInfo": hitInfo]
        )

        // Визуальный эффект попадания
        createHitEffect(at: target.position)

        return true
    }

    // MARK: - Hit Effect

    private func createHitEffect(at position: CGPoint) {
        guard let scene = scene else { return }

        // Создаём эффект попадания
        let effect = SKSpriteNode(color: .white, size: CGSize(width: 20, height: 20))
        effect.position = position
        effect.zPosition = 100

        let effectAction = SKAction.sequence([
            SKAction.group([
                SKAction.scale(to: 2.0, duration: 0.1),
                SKAction.fadeOut(withDuration: 0.1)
            ]),
            SKAction.removeFromParent()
        ])

        scene.addChild(effect)
        effect.run(effectAction)
    }

    // MARK: - Cleanup

    private func cleanup() {
        hitbox?.removeFromParent()
        slashEffect?.removeFromParent()
        removeFromParent()
    }
}

// MARK: - Hit Info

/// Информация о попадании
struct HitInfo {
    let damage: Int
    let knockbackForce: CGFloat
    let knockbackDirection: CGFloat
    weak var source: SKNode?
}

// MARK: - Notifications

extension Notification.Name {
    static let entityHit = Notification.Name("entityHit")
}
