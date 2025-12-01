# Фаза 2: Игрок и Физика

## Обзор фазы

Фаза 2 создаёт ядро геймплея: персонажа игрока с полноценной физикой платформера, системой анимаций, боевой механикой и коллекционными предметами.

**Предварительные требования:**
- Завершена Фаза 1 (архитектура и базовый каркас)
- Существуют: `BaseGameScene`, `InputManager`, `LevelData`, `GameCamera`, `TouchControlsOverlay`

---

## Стадия 2.1: Персонаж игрока (Player Entity)

### Промт

```
Создай класс Player для игры Chronicles of Rifts.

## Контекст проекта
- Движок: SpriteKit
- Существующие файлы: BaseGameScene.swift, InputManager.swift (с InputDelegate), PhysicsCategories.swift
- Путь для файла: ChroniclesOfRifts/ChroniclesOfRifts/Entities/Player.swift

## Требования к Player

### 1. State Machine (конечный автомат)
Создай enum PlayerState:
- idle: стоит на месте
- walking: ходьба
- jumping: прыжок вверх
- falling: падение вниз
- attacking: атака мечом
- hurt: получение урона (кратковременно)
- dead: смерть

Правила переходов:
- idle → walking (при движении джойстика)
- idle/walking → jumping (при нажатии прыжка, если на земле)
- jumping → falling (когда velocity.dy < 0)
- falling → idle/walking (при приземлении)
- любое → attacking (при нажатии атаки, если не dead/hurt)
- любое → hurt (при получении урона, если не неуязвим)
- hurt → idle (после окончания анимации hurt)
- любое → dead (когда health <= 0)

### 2. Физические параметры
```swift
struct PlayerConfig {
    static let moveSpeed: CGFloat = 200       // пикселей/сек
    static let jumpForce: CGFloat = 450       // импульс прыжка
    static let gravity: CGFloat = -980        // гравитация
    static let maxFallSpeed: CGFloat = -600   // макс. скорость падения
    static let groundFriction: CGFloat = 0.85 // трение при остановке
    static let airControl: CGFloat = 0.7      // контроль в воздухе (множитель)
}
```

### 3. Продвинутая механика прыжка
- **Variable Jump Height**: высота зависит от длительности удержания кнопки
  - При отпускании кнопки раньше: velocity.dy *= 0.5 (если velocity.dy > 0)
  - Максимальное время удержания: 0.2 сек
- **Coyote Time**: можно прыгнуть 0.1 сек после схода с платформы
  - Храни `timeSinceGrounded: TimeInterval`
  - Если timeSinceGrounded < 0.1 и была команда прыжка — разреши прыжок
- **Jump Buffer**: прыжок регистрируется за 0.1 сек до приземления
  - Храни `jumpBufferTime: TimeInterval`
  - При нажатии прыжка в воздухе: jumpBufferTime = 0.1
  - При приземлении: если jumpBufferTime > 0 — автоматический прыжок

### 4. Параметры персонажа
```swift
var maxHealth: Int = 3
var currentHealth: Int = 3
var isInvulnerable: Bool = false          // после урона
let invulnerabilityDuration: TimeInterval = 1.5
var facingDirection: Direction = .right   // используй enum из LevelData
```

### 5. Physics Body
- Размер коллайдера: 24x48 пикселей (уже спрайта для точности)
- categoryBitMask: PhysicsCategory.player
- collisionBitMask: PhysicsCategory.ground
- contactTestBitMask: PhysicsCategory.enemy | PhysicsCategory.collectible | PhysicsCategory.hazard | PhysicsCategory.trigger

### 6. Структура класса
```swift
final class Player: SKSpriteNode {
    // MARK: - State
    private(set) var currentState: PlayerState = .idle

    // MARK: - Movement
    private var velocity: CGVector = .zero
    private var isGrounded: Bool = false
    private var inputDirection: CGFloat = 0  // -1 до 1

    // MARK: - Jump mechanics
    private var isJumpHeld: Bool = false
    private var jumpHoldTime: TimeInterval = 0
    private var timeSinceGrounded: TimeInterval = 0
    private var jumpBufferTime: TimeInterval = 0

    // MARK: - Combat
    private var attackCooldown: TimeInterval = 0

    // MARK: - Health
    var maxHealth: Int = 3
    private(set) var currentHealth: Int = 3
    private var isInvulnerable: Bool = false
    private var invulnerabilityTimer: TimeInterval = 0

    // MARK: - Init
    init()
    required init?(coder aDecoder: NSCoder)

    // MARK: - Setup
    private func setupPhysicsBody()
    private func setupInitialState()

    // MARK: - Update
    func update(deltaTime: TimeInterval)
    private func updateMovement(deltaTime: TimeInterval)
    private func updateJump(deltaTime: TimeInterval)
    private func updateTimers(deltaTime: TimeInterval)
    private func applyGravity(deltaTime: TimeInterval)
    private func clampVelocity()

    // MARK: - State Machine
    private func changeState(to newState: PlayerState)
    private func canTransition(to newState: PlayerState) -> Bool
    private func onStateEnter(_ state: PlayerState)
    private func onStateExit(_ state: PlayerState)

    // MARK: - Input
    func setInputDirection(_ direction: CGFloat)
    func jump()
    func releaseJump()
    func attack()

    // MARK: - Combat
    func takeDamage(_ amount: Int)
    func heal(_ amount: Int)
    func die()

    // MARK: - Ground Detection
    func setGrounded(_ grounded: Bool)

    // MARK: - Helpers
    private func updateFacingDirection()
}
```

### 7. Визуал (placeholder)
- Создай спрайт 32x64 пикселя
- Используй SKShapeNode или цветной SKSpriteNode для теста
- Цвет: золотистый (#FFD700) для светорождённого Каэля

## Требования к коду
- Комментарии на русском языке
- MARK секции для организации
- Все публичные методы с документацией
- Использовать существующие PhysicsCategory и Direction из проекта

## После создания
1. Добавь файл в Xcode проект (группа Entities)
2. Проверь сборку: xcodebuild -project ChroniclesOfRifts/ChroniclesOfRifts.xcodeproj -scheme ChroniclesOfRifts -configuration Debug build
```

### Проверка после стадии 2.1

```bash
# Проверить что файл создан
ls -la ChroniclesOfRifts/ChroniclesOfRifts/Entities/Player.swift

# Собрать проект
xcodebuild -project ChroniclesOfRifts/ChroniclesOfRifts.xcodeproj -scheme ChroniclesOfRifts -configuration Debug build
```

---

## Стадия 2.2: Интеграция Player в GameScene

### Промт

```
Интегрируй Player в GameScene для тестирования управления.

## Контекст
- Создан Player.swift в предыдущей стадии
- Существует GameScene.swift который наследуется от BaseGameScene
- InputManager с InputDelegate уже настроен
- TouchControlsOverlay подключён к BaseGameScene

## Задачи

### 1. Обновление GameScene.swift
Путь: ChroniclesOfRifts/ChroniclesOfRifts/Scenes/GameScene.swift

```swift
class GameScene: BaseGameScene, InputDelegate {
    // MARK: - Entities
    private var player: Player!

    // MARK: - Level
    private var currentLevelData: LevelData?

    override func didMove(to view: SKView) {
        super.didMove(to: view)

        // Подключаем делегат ввода
        inputManager.delegate = self

        // Настраиваем физику
        setupPhysics()

        // Создаём тестовый уровень
        setupTestLevel()

        // Создаём игрока
        setupPlayer()
    }

    // MARK: - Setup
    private func setupPhysics() {
        physicsWorld.gravity = CGVector(dx: 0, dy: -9.8)
        physicsWorld.contactDelegate = self
    }

    private func setupTestLevel() {
        // Создай простую платформу для тестирования
        // Позиция: по центру внизу экрана
        // Размер: 800x32
    }

    private func setupPlayer() {
        player = Player()
        player.position = CGPoint(x: size.width / 2, y: 200)
        gameLayer.addChild(player)

        // Камера следит за игроком
        gameCamera.target = player
        gameCamera.bounds = CGRect(x: 0, y: 0, width: 2000, height: 1000)
    }

    // MARK: - Update
    override func updateGame(deltaTime: TimeInterval) {
        player.update(deltaTime: deltaTime)
    }

    // MARK: - InputDelegate
    func joystickMoved(direction: CGVector) {
        player.setInputDirection(direction.dx)
    }

    func jumpPressed() {
        player.jump()
    }

    func jumpReleased() {
        player.releaseJump()
    }

    func attackPressed() {
        player.attack()
    }

    func pausePressed() {
        togglePause()
    }
}

// MARK: - SKPhysicsContactDelegate
extension GameScene: SKPhysicsContactDelegate {
    func didBegin(_ contact: SKPhysicsContact) {
        // Определи какие тела столкнулись
        // Обработай контакт player с ground для setGrounded(true)
    }

    func didEnd(_ contact: SKPhysicsContact) {
        // Обработай окончание контакта player с ground для setGrounded(false)
    }
}
```

### 2. Создай тестовую платформу
```swift
private func createPlatform(at position: CGPoint, size: CGSize) -> SKSpriteNode {
    let platform = SKSpriteNode(color: .brown, size: size)
    platform.position = position
    platform.physicsBody = SKPhysicsBody(rectangleOf: size)
    platform.physicsBody?.isDynamic = false
    platform.physicsBody?.categoryBitMask = PhysicsCategory.ground
    platform.physicsBody?.collisionBitMask = PhysicsCategory.player
    platform.physicsBody?.friction = 0.5
    return platform
}
```

### 3. Обнови GameCamera если нужно
Добавь в GameCamera.swift:
```swift
weak var target: SKNode?

func update(deltaTime: TimeInterval) {
    guard let target = target else { return }
    // Плавное следование за целью
    let lerpFactor: CGFloat = 0.1
    let targetPos = target.position
    position.x += (targetPos.x - position.x) * lerpFactor
    position.y += (targetPos.y - position.y) * lerpFactor

    // Ограничение по bounds
    clampToBounds()
}
```

## Требования
- Player должен двигаться влево-вправо от джойстика
- Player должен прыгать от кнопки прыжка
- Камера должна следить за игроком
- Коллизия с платформой должна работать

## После интеграции
1. Добавь изменённые файлы в проект
2. Собери: xcodebuild -project ChroniclesOfRifts/ChroniclesOfRifts.xcodeproj -scheme ChroniclesOfRifts -configuration Debug build
3. Запусти на симуляторе для проверки управления
```

### Проверка после стадии 2.2

```bash
# Собрать проект
xcodebuild -project ChroniclesOfRifts/ChroniclesOfRifts.xcodeproj -scheme ChroniclesOfRifts -configuration Debug build

# Запустить на симуляторе (опционально)
xcodebuild -project ChroniclesOfRifts/ChroniclesOfRifts.xcodeproj -scheme ChroniclesOfRifts -destination 'platform=iOS Simulator,name=iPhone 15' build
```

---

## Стадия 2.3: Система анимаций (AnimationManager)

### Промт

```
Создай AnimationManager для управления анимациями спрайтов.

## Контекст проекта
- Движок: SpriteKit
- Путь: ChroniclesOfRifts/ChroniclesOfRifts/Managers/AnimationManager.swift
- Анимации будут использоваться Player и Enemy классами

## Требования к AnimationManager

### 1. Структура данных анимации
```swift
/// Данные одной анимации
struct AnimationData {
    let name: String
    let frames: [SKTexture]
    let timePerFrame: TimeInterval
    let repeatForever: Bool

    /// Создаёт SKAction для этой анимации
    func toAction() -> SKAction
}
```

### 2. AnimationManager (синглтон)
```swift
final class AnimationManager {
    static let shared = AnimationManager()

    // MARK: - Cache
    /// Кэш загруженных анимаций: [entityType_animationName: AnimationData]
    private var animationCache: [String: AnimationData] = [:]

    /// Кэш текстурных атласов
    private var atlasCache: [String: SKTextureAtlas] = [:]

    // MARK: - Loading

    /// Загрузить все анимации для типа сущности
    /// - Parameter entityType: Тип сущности (player, cultist, etc.)
    func preloadAnimations(for entityType: String)

    /// Получить анимацию по ключу
    /// - Parameters:
    ///   - name: Имя анимации (idle, walk, jump, etc.)
    ///   - entityType: Тип сущности
    /// - Returns: AnimationData или nil
    func getAnimation(name: String, for entityType: String) -> AnimationData?

    /// Создать SKAction для анимации
    /// - Parameters:
    ///   - name: Имя анимации
    ///   - entityType: Тип сущности
    /// - Returns: SKAction или nil
    func createAnimationAction(name: String, for entityType: String) -> SKAction?

    // MARK: - Placeholder Generation

    /// Создать placeholder текстуры для тестирования
    /// - Parameters:
    ///   - entityType: Тип сущности
    ///   - frameCount: Количество кадров
    ///   - size: Размер кадра
    ///   - color: Базовый цвет
    /// - Returns: Массив текстур
    func createPlaceholderTextures(
        for entityType: String,
        animationName: String,
        frameCount: Int,
        size: CGSize,
        color: UIColor
    ) -> [SKTexture]

    // MARK: - Atlas Loading

    /// Загрузить текстурный атлас
    /// - Parameter name: Имя атласа
    /// - Returns: SKTextureAtlas
    private func loadAtlas(named name: String) -> SKTextureAtlas?

    /// Извлечь кадры из атласа по префиксу
    /// - Parameters:
    ///   - atlas: Текстурный атлас
    ///   - prefix: Префикс имён текстур (например "player_walk_")
    /// - Returns: Отсортированный массив текстур
    private func extractFrames(from atlas: SKTextureAtlas, prefix: String) -> [SKTexture]
}
```

### 3. Конфигурация анимаций игрока
```swift
/// Конфигурация анимаций для Player
struct PlayerAnimationConfig {
    static let animations: [(name: String, frames: Int, timePerFrame: TimeInterval, repeats: Bool)] = [
        ("idle", 4, 0.2, true),      // 4 кадра, 0.2 сек каждый, зациклено
        ("walk", 6, 0.1, true),      // 6 кадров, 0.1 сек, зациклено
        ("jump", 2, 0.15, false),    // 2 кадра, без цикла
        ("fall", 2, 0.15, false),    // 2 кадра, без цикла
        ("attack", 4, 0.08, false),  // 4 кадра, быстрая, без цикла
        ("hurt", 2, 0.1, false),     // 2 кадра, без цикла
        ("death", 6, 0.12, false)    // 6 кадров, без цикла
    ]

    static let size = CGSize(width: 32, height: 64)
    static let color = UIColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 1.0) // Gold
}
```

### 4. Генерация placeholder текстур
Для тестирования без реальных ассетов создай placeholder спрайты:

```swift
private func generatePlaceholderFrame(
    size: CGSize,
    color: UIColor,
    frameIndex: Int,
    totalFrames: Int,
    animationName: String
) -> SKTexture {
    let renderer = UIGraphicsImageRenderer(size: size)
    let image = renderer.image { context in
        // Фон - основной цвет с небольшой вариацией по кадрам
        let brightness = 0.8 + (CGFloat(frameIndex) / CGFloat(totalFrames)) * 0.2
        let adjustedColor = color.withAlphaComponent(brightness)
        adjustedColor.setFill()
        context.fill(CGRect(origin: .zero, size: size))

        // Визуальная индикация анимации
        UIColor.black.setStroke()
        let rect = CGRect(origin: .zero, size: size).insetBy(dx: 2, dy: 2)
        context.stroke(rect)

        // Индикатор кадра (полоска внизу)
        let indicatorWidth = (size.width - 4) / CGFloat(totalFrames)
        let indicatorRect = CGRect(
            x: 2 + indicatorWidth * CGFloat(frameIndex),
            y: size.height - 6,
            width: indicatorWidth,
            height: 4
        )
        UIColor.white.setFill()
        context.fill(indicatorRect)
    }
    return SKTexture(image: image)
}
```

### 5. Инициализация при запуске
```swift
private init() {
    // Создаём placeholder анимации для игрока
    setupPlayerPlaceholderAnimations()
}

private func setupPlayerPlaceholderAnimations() {
    for config in PlayerAnimationConfig.animations {
        let textures = createPlaceholderTextures(
            for: "player",
            animationName: config.name,
            frameCount: config.frames,
            size: PlayerAnimationConfig.size,
            color: PlayerAnimationConfig.color
        )

        let animationData = AnimationData(
            name: config.name,
            frames: textures,
            timePerFrame: config.timePerFrame,
            repeatForever: config.repeats
        )

        let key = "player_\(config.name)"
        animationCache[key] = animationData
    }
}
```

## Требования к коду
- Комментарии на русском
- Потокобезопасность не требуется (всё в main thread)
- Lazy loading для экономии памяти
- Методы для очистки кэша при необходимости

## После создания
1. Добавь файл в Xcode проект (группа Managers)
2. Собери проект: xcodebuild -project ChroniclesOfRifts/ChroniclesOfRifts.xcodeproj -scheme ChroniclesOfRifts -configuration Debug build
```

### Проверка после стадии 2.3

```bash
xcodebuild -project ChroniclesOfRifts/ChroniclesOfRifts.xcodeproj -scheme ChroniclesOfRifts -configuration Debug build
```

---

## Стадия 2.4: Интеграция анимаций в Player

### Промт

```
Интегрируй AnimationManager в класс Player для отображения анимаций.

## Контекст
- Создан AnimationManager.swift с placeholder анимациями
- Существует Player.swift со state machine
- Нужно связать состояния игрока с анимациями

## Задачи

### 1. Добавь в Player.swift компонент анимаций

```swift
// MARK: - Animation
private var currentAnimation: String = ""
private let animationKey = "playerAnimation"

/// Проигрывает анимацию для текущего состояния
private func playAnimation(for state: PlayerState) {
    let animationName = animationNameFor(state)

    // Не перезапускать ту же анимацию
    guard animationName != currentAnimation else { return }
    currentAnimation = animationName

    // Остановить предыдущую
    removeAction(forKey: animationKey)

    // Получить и запустить новую
    if let action = AnimationManager.shared.createAnimationAction(
        name: animationName,
        for: "player"
    ) {
        run(action, withKey: animationKey)
    }
}

/// Маппинг состояния на имя анимации
private func animationNameFor(_ state: PlayerState) -> String {
    switch state {
    case .idle: return "idle"
    case .walking: return "walk"
    case .jumping: return "jump"
    case .falling: return "fall"
    case .attacking: return "attack"
    case .hurt: return "hurt"
    case .dead: return "death"
    }
}
```

### 2. Обнови методы смены состояния

```swift
private func changeState(to newState: PlayerState) {
    guard canTransition(to: newState) else { return }

    let oldState = currentState
    onStateExit(oldState)

    currentState = newState
    onStateEnter(newState)

    // Запускаем анимацию для нового состояния
    playAnimation(for: newState)
}
```

### 3. Обработка окончания анимаций

Для одноразовых анимаций (attack, hurt) нужно вернуться в нормальное состояние:

```swift
private func onStateEnter(_ state: PlayerState) {
    switch state {
    case .attacking:
        // После окончания атаки вернуться в idle/walk
        let attackDuration = 4 * 0.08 // 4 кадра по 0.08 сек
        run(SKAction.sequence([
            SKAction.wait(forDuration: attackDuration),
            SKAction.run { [weak self] in
                self?.onAttackComplete()
            }
        ]))

    case .hurt:
        // После hurt вернуться в idle
        let hurtDuration = 2 * 0.1
        run(SKAction.sequence([
            SKAction.wait(forDuration: hurtDuration),
            SKAction.run { [weak self] in
                self?.onHurtComplete()
            }
        ]))

    case .dead:
        // Анимация смерти + callback
        let deathDuration = 6 * 0.12
        run(SKAction.sequence([
            SKAction.wait(forDuration: deathDuration),
            SKAction.run { [weak self] in
                self?.onDeathComplete()
            }
        ]))

    default:
        break
    }
}

private func onAttackComplete() {
    guard currentState == .attacking else { return }
    attackCooldown = 0.5 // Кулдаун атаки

    if isGrounded {
        changeState(to: abs(inputDirection) > 0.1 ? .walking : .idle)
    } else {
        changeState(to: velocity.dy > 0 ? .jumping : .falling)
    }
}

private func onHurtComplete() {
    guard currentState == .hurt else { return }

    if currentHealth <= 0 {
        changeState(to: .dead)
    } else if isGrounded {
        changeState(to: abs(inputDirection) > 0.1 ? .walking : .idle)
    } else {
        changeState(to: .falling)
    }
}

private func onDeathComplete() {
    // Уведомить сцену о смерти
    NotificationCenter.default.post(name: .playerDied, object: self)
}
```

### 4. Добавь Notification для смерти игрока

```swift
// В отдельном файле или расширении
extension Notification.Name {
    static let playerDied = Notification.Name("playerDied")
}
```

### 5. Визуальный эффект направления
```swift
private func updateFacingDirection() {
    if inputDirection > 0.1 {
        facingDirection = .right
        xScale = abs(xScale)
    } else if inputDirection < -0.1 {
        facingDirection = .left
        xScale = -abs(xScale)
    }
}
```

### 6. Мигание при неуязвимости
```swift
private func startInvulnerabilityEffect() {
    let blink = SKAction.sequence([
        SKAction.fadeAlpha(to: 0.3, duration: 0.1),
        SKAction.fadeAlpha(to: 1.0, duration: 0.1)
    ])
    run(SKAction.repeatForever(blink), withKey: "invulnerabilityBlink")
}

private func stopInvulnerabilityEffect() {
    removeAction(forKey: "invulnerabilityBlink")
    alpha = 1.0
}
```

## Требования
- Анимации должны корректно переключаться при смене состояния
- Одноразовые анимации должны возвращать в нормальное состояние
- Направление спрайта должно соответствовать движению
- При неуязвимости спрайт должен мигать

## После интеграции
1. Собери проект: xcodebuild -project ChroniclesOfRifts/ChroniclesOfRifts.xcodeproj -scheme ChroniclesOfRifts -configuration Debug build
2. Проверь на симуляторе что анимации переключаются при разных действиях
```

### Проверка после стадии 2.4

```bash
xcodebuild -project ChroniclesOfRifts/ChroniclesOfRifts.xcodeproj -scheme ChroniclesOfRifts -configuration Debug build
```

---

## Стадия 2.5: Система атаки и хитбоксы

### Промт

```
Создай систему ближнего боя для Player.

## Контекст
- Player имеет состояние .attacking
- Нужна система хитбоксов для атаки мечом
- Существуют PhysicsCategory.playerAttack для атак

## Требования

### 1. Создай компонент MeleeAttack
Путь: ChroniclesOfRifts/ChroniclesOfRifts/Components/MeleeAttack.swift

```swift
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
        guard let owner = owner else { return }

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
        hitbox?.userData = ["attack": self]

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
        effect.position = convert(position, from: scene)
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
```

### 2. Интегрируй в Player

```swift
// В Player.swift

// MARK: - Attack

/// Текущий кулдаун атаки
private var attackCooldown: TimeInterval = 0

func attack() {
    // Проверка кулдауна
    guard attackCooldown <= 0 else { return }

    // Проверка состояния
    guard currentState != .hurt && currentState != .dead else { return }

    // Переход в состояние атаки
    changeState(to: .attacking)

    // Создание хитбокса
    let meleeAttack = MeleeAttack(config: .playerSword, owner: self)
    addChild(meleeAttack)
    meleeAttack.execute(direction: facingDirection)

    // Установка кулдауна
    attackCooldown = MeleeAttack.Config.playerSword.cooldown
}

// В updateTimers:
private func updateTimers(deltaTime: TimeInterval) {
    // ... existing code ...

    if attackCooldown > 0 {
        attackCooldown -= deltaTime
    }
}
```

### 3. Обработка попаданий в GameScene

```swift
// В GameScene.swift

override func didMove(to view: SKView) {
    super.didMove(to: view)

    // ... existing code ...

    // Подписка на события попаданий
    NotificationCenter.default.addObserver(
        self,
        selector: #selector(handleEntityHit(_:)),
        name: .entityHit,
        object: nil
    )
}

@objc private func handleEntityHit(_ notification: Notification) {
    guard let target = notification.object as? SKNode,
          let hitInfo = notification.userInfo?["hitInfo"] as? HitInfo else { return }

    // Если цель - враг, нанести урон
    if let enemy = target as? Enemy {
        enemy.takeDamage(hitInfo.damage, knockback: hitInfo.knockbackForce * hitInfo.knockbackDirection)
    }
}

// Обработка контакта хитбокса с врагом
func didBegin(_ contact: SKPhysicsContact) {
    let (bodyA, bodyB) = (contact.bodyA, contact.bodyB)

    // Attack hitbox + Enemy
    if bodyA.categoryBitMask == PhysicsCategory.playerAttack &&
       bodyB.categoryBitMask == PhysicsCategory.enemy {
        if let attack = bodyA.node?.userData?["attack"] as? MeleeAttack,
           let enemy = bodyB.node {
            attack.processHit(on: enemy)
        }
    } else if bodyB.categoryBitMask == PhysicsCategory.playerAttack &&
              bodyA.categoryBitMask == PhysicsCategory.enemy {
        if let attack = bodyB.node?.userData?["attack"] as? MeleeAttack,
           let enemy = bodyA.node {
            attack.processHit(on: enemy)
        }
    }

    // ... existing ground collision code ...
}
```

## Требования
- Хитбокс появляется на время атаки и исчезает
- Каждый враг получает урон только один раз за атаку
- Визуальный эффект взмаха меча
- Кулдаун между атаками
- Эффект попадания при контакте с врагом

## После создания
1. Добавь MeleeAttack.swift в проект (группа Components)
2. Обнови Player.swift и GameScene.swift
3. Собери: xcodebuild -project ChroniclesOfRifts/ChroniclesOfRifts.xcodeproj -scheme ChroniclesOfRifts -configuration Debug build
```

### Проверка после стадии 2.5

```bash
xcodebuild -project ChroniclesOfRifts/ChroniclesOfRifts.xcodeproj -scheme ChroniclesOfRifts -configuration Debug build
```

---

## Стадия 2.6: Коллекционные предметы (Collectibles)

### Промт

```
Создай систему коллекционных предметов.

## Контекст
- Существует CollectibleType enum в LevelData.swift: manaCrystal, healthPickup, chroniclePage, checkpoint
- PhysicsCategory.collectible = 0b1000

## Требования

### 1. Создай базовый класс Collectible
Путь: ChroniclesOfRifts/ChroniclesOfRifts/Entities/Collectible.swift

```swift
import SpriteKit

/// Базовый класс для всех коллекционных предметов
class Collectible: SKSpriteNode {

    // MARK: - Properties

    /// Тип предмета
    let type: CollectibleType

    /// Уникальный идентификатор (для страниц хроник и чекпоинтов)
    let id: String?

    /// Был ли предмет собран
    private(set) var isCollected: Bool = false

    // MARK: - Visual

    /// Эффект парения
    private var floatAction: SKAction?

    /// Эффект свечения
    private var glowNode: SKShapeNode?

    // MARK: - Init

    init(type: CollectibleType, id: String? = nil) {
        self.type = type
        self.id = id

        let size = Self.sizeFor(type)
        let color = Self.colorFor(type)

        super.init(texture: nil, color: color, size: size)

        self.name = "collectible_\(type.rawValue)"

        setupPhysics()
        setupVisuals()
        startAnimations()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Configuration

    private static func sizeFor(_ type: CollectibleType) -> CGSize {
        switch type {
        case .manaCrystal: return CGSize(width: 16, height: 24)
        case .healthPickup: return CGSize(width: 24, height: 24)
        case .chroniclePage: return CGSize(width: 20, height: 28)
        case .checkpoint: return CGSize(width: 32, height: 48)
        }
    }

    private static func colorFor(_ type: CollectibleType) -> UIColor {
        switch type {
        case .manaCrystal: return UIColor(red: 0.5, green: 0.8, blue: 1.0, alpha: 1.0)  // Голубой
        case .healthPickup: return UIColor(red: 1.0, green: 0.3, blue: 0.3, alpha: 1.0)  // Красный
        case .chroniclePage: return UIColor(red: 1.0, green: 0.9, blue: 0.6, alpha: 1.0)  // Пергамент
        case .checkpoint: return UIColor(red: 0.8, green: 0.6, blue: 1.0, alpha: 1.0)  // Фиолетовый
        }
    }

    // MARK: - Setup

    private func setupPhysics() {
        // Checkpoint имеет большой триггер
        let triggerSize = type == .checkpoint
            ? CGSize(width: 48, height: 64)
            : CGSize(width: size.width + 8, height: size.height + 8)

        physicsBody = SKPhysicsBody(rectangleOf: triggerSize)
        physicsBody?.isDynamic = false
        physicsBody?.categoryBitMask = PhysicsCategory.collectible
        physicsBody?.contactTestBitMask = PhysicsCategory.player
        physicsBody?.collisionBitMask = 0
    }

    private func setupVisuals() {
        // Эффект свечения
        let glowSize = CGSize(width: size.width * 1.5, height: size.height * 1.5)
        glowNode = SKShapeNode(ellipseOf: glowSize)
        glowNode?.fillColor = Self.colorFor(type).withAlphaComponent(0.3)
        glowNode?.strokeColor = .clear
        glowNode?.zPosition = -1
        glowNode?.blendMode = .add
        addChild(glowNode!)

        // Особый визуал для checkpoint
        if type == .checkpoint {
            setupCheckpointVisual()
        }
    }

    private func setupCheckpointVisual() {
        // Столб чекпоинта
        let pillar = SKSpriteNode(color: UIColor.darkGray, size: CGSize(width: 8, height: 48))
        pillar.position = .zero
        pillar.zPosition = -1
        addChild(pillar)

        // Кристалл наверху
        let crystal = SKSpriteNode(color: color, size: CGSize(width: 16, height: 16))
        crystal.position = CGPoint(x: 0, y: 20)
        addChild(crystal)

        // Скрываем основной спрайт
        self.color = .clear
    }

    // MARK: - Animations

    private func startAnimations() {
        // Парение вверх-вниз
        if type != .checkpoint {
            let floatUp = SKAction.moveBy(x: 0, y: 4, duration: 0.5)
            floatUp.timingMode = .easeInEaseOut
            let floatDown = floatUp.reversed()
            floatAction = SKAction.repeatForever(SKAction.sequence([floatUp, floatDown]))
            run(floatAction!, withKey: "float")
        }

        // Пульсация свечения
        let pulseGrow = SKAction.scale(to: 1.2, duration: 0.8)
        let pulseShrink = SKAction.scale(to: 0.9, duration: 0.8)
        let pulse = SKAction.repeatForever(SKAction.sequence([pulseGrow, pulseShrink]))
        glowNode?.run(pulse)
    }

    // MARK: - Collection

    /// Собрать предмет
    /// - Parameter collector: Узел, который собирает предмет (обычно Player)
    func collect(by collector: SKNode) {
        guard !isCollected else { return }
        isCollected = true

        // Остановить анимации
        removeAction(forKey: "float")

        // Эффект сбора
        playCollectEffect()

        // Уведомление
        NotificationCenter.default.post(
            name: .collectibleCollected,
            object: self,
            userInfo: ["collector": collector, "type": type, "id": id as Any]
        )
    }

    private func playCollectEffect() {
        // Анимация сбора
        let collectAction = SKAction.sequence([
            SKAction.group([
                SKAction.scale(to: 1.5, duration: 0.15),
                SKAction.fadeOut(withDuration: 0.15),
                SKAction.move(by: CGVector(dx: 0, dy: 20), duration: 0.15)
            ]),
            SKAction.removeFromParent()
        ])

        run(collectAction)

        // Частицы
        spawnCollectParticles()
    }

    private func spawnCollectParticles() {
        guard let parent = parent else { return }

        // Создаём несколько частиц
        for _ in 0..<8 {
            let particle = SKSpriteNode(color: Self.colorFor(type), size: CGSize(width: 4, height: 4))
            particle.position = position
            particle.zPosition = 100

            let angle = CGFloat.random(in: 0...CGFloat.pi * 2)
            let distance: CGFloat = CGFloat.random(in: 30...60)
            let targetPos = CGPoint(
                x: position.x + cos(angle) * distance,
                y: position.y + sin(angle) * distance
            )

            let particleAction = SKAction.sequence([
                SKAction.group([
                    SKAction.move(to: targetPos, duration: 0.3),
                    SKAction.fadeOut(withDuration: 0.3),
                    SKAction.scale(to: 0.1, duration: 0.3)
                ]),
                SKAction.removeFromParent()
            ])

            parent.addChild(particle)
            particle.run(particleAction)
        }
    }

    // MARK: - Checkpoint specific

    /// Активировать чекпоинт (визуальное изменение)
    func activateCheckpoint() {
        guard type == .checkpoint else { return }

        // Меняем цвет на активный
        glowNode?.fillColor = UIColor.green.withAlphaComponent(0.5)

        // Эффект активации
        let pulse = SKAction.sequence([
            SKAction.scale(to: 2.0, duration: 0.2),
            SKAction.scale(to: 1.0, duration: 0.2)
        ])
        glowNode?.run(pulse)
    }
}

// MARK: - Notification

extension Notification.Name {
    static let collectibleCollected = Notification.Name("collectibleCollected")
}
```

### 2. Обработка сбора в GameScene

```swift
// В GameScene.swift

// MARK: - Properties
private var collectedCrystals: Int = 0
private var currentCheckpoint: CGPoint?

override func didMove(to view: SKView) {
    super.didMove(to: view)

    // ... existing code ...

    // Подписка на сбор предметов
    NotificationCenter.default.addObserver(
        self,
        selector: #selector(handleCollectibleCollected(_:)),
        name: .collectibleCollected,
        object: nil
    )
}

@objc private func handleCollectibleCollected(_ notification: Notification) {
    guard let collectible = notification.object as? Collectible,
          let type = notification.userInfo?["type"] as? CollectibleType else { return }

    switch type {
    case .manaCrystal:
        collectedCrystals += 1
        // TODO: Обновить HUD

    case .healthPickup:
        player.heal(1)

    case .chroniclePage:
        if let id = notification.userInfo?["id"] as? String {
            GameManager.shared.collectPage(id)
        }

    case .checkpoint:
        currentCheckpoint = collectible.position
        collectible.activateCheckpoint()
        // TODO: Показать уведомление "Checkpoint!"
    }
}

// В didBegin(_ contact:)
func didBegin(_ contact: SKPhysicsContact) {
    // ... existing code ...

    // Player + Collectible
    if let collectible = getNode(from: contact, withCategory: PhysicsCategory.collectible) as? Collectible,
       let _ = getNode(from: contact, withCategory: PhysicsCategory.player) as? Player {
        collectible.collect(by: player)
    }
}

// Хелпер для получения ноды из контакта
private func getNode(from contact: SKPhysicsContact, withCategory category: UInt32) -> SKNode? {
    if contact.bodyA.categoryBitMask == category {
        return contact.bodyA.node
    } else if contact.bodyB.categoryBitMask == category {
        return contact.bodyB.node
    }
    return nil
}
```

### 3. Создание предметов из LevelData

```swift
// В LevelLoader или GameScene

func spawnCollectibles(from levelData: LevelData, in layer: SKNode) {
    for collectibleData in levelData.collectibles {
        let collectible = Collectible(type: collectibleData.type, id: collectibleData.id)
        collectible.position = collectibleData.position.toPixels(tileSize: levelData.tileSize)
        layer.addChild(collectible)
    }
}
```

## Требования
- 4 типа предметов с уникальным визуалом
- Анимация парения для кристаллов и пикапов
- Эффект сбора с частицами
- Чекпоинты активируются визуально
- Уведомления через NotificationCenter

## После создания
1. Добавь Collectible.swift в проект (группа Entities)
2. Обнови GameScene.swift
3. Собери: xcodebuild -project ChroniclesOfRifts/ChroniclesOfRifts.xcodeproj -scheme ChroniclesOfRifts -configuration Debug build
```

### Проверка после стадии 2.6

```bash
xcodebuild -project ChroniclesOfRifts/ChroniclesOfRifts.xcodeproj -scheme ChroniclesOfRifts -configuration Debug build
```

---

## Стадия 2.7: Получение урона и смерть игрока

### Промт

```
Реализуй полную систему получения урона и смерти для Player.

## Контекст
- Player имеет currentHealth, maxHealth, isInvulnerable
- Существуют состояния .hurt и .dead
- GameScene обрабатывает контакты с hazard и enemy

## Требования

### 1. Обнови метод takeDamage в Player

```swift
// В Player.swift

/// Нанести урон игроку
/// - Parameters:
///   - amount: Количество урона
///   - knockbackDirection: Направление отбрасывания (-1 влево, 1 вправо)
///   - knockbackForce: Сила отбрасывания
func takeDamage(_ amount: Int, knockbackDirection: CGFloat = 0, knockbackForce: CGFloat = 200) {
    // Проверка неуязвимости
    guard !isInvulnerable && currentState != .dead else { return }

    // Применить урон
    currentHealth = max(0, currentHealth - amount)

    // Отбрасывание
    velocity.dx = knockbackDirection * knockbackForce
    velocity.dy = knockbackForce * 0.5  // Небольшой подброс

    // Эффекты
    playDamageEffects()

    // Проверка смерти
    if currentHealth <= 0 {
        die()
    } else {
        // Переход в состояние hurt
        changeState(to: .hurt)

        // Временная неуязвимость
        startInvulnerability()
    }

    // Уведомление
    NotificationCenter.default.post(name: .playerDamaged, object: self, userInfo: ["health": currentHealth])
}

private func playDamageEffects() {
    // Тряска камеры (через уведомление)
    NotificationCenter.default.post(name: .requestCameraShake, object: nil, userInfo: ["intensity": 5.0, "duration": 0.2])

    // Красная вспышка
    let flashNode = SKSpriteNode(color: .red, size: size)
    flashNode.alpha = 0.5
    flashNode.zPosition = 50
    addChild(flashNode)

    flashNode.run(SKAction.sequence([
        SKAction.fadeOut(withDuration: 0.2),
        SKAction.removeFromParent()
    ]))
}

private func startInvulnerability() {
    isInvulnerable = true
    invulnerabilityTimer = invulnerabilityDuration
    startInvulnerabilityEffect()
}

// Обнови updateTimers
private func updateTimers(deltaTime: TimeInterval) {
    // ... existing cooldowns ...

    // Таймер неуязвимости
    if isInvulnerable {
        invulnerabilityTimer -= deltaTime
        if invulnerabilityTimer <= 0 {
            isInvulnerable = false
            stopInvulnerabilityEffect()
        }
    }
}

/// Смерть игрока
func die() {
    guard currentState != .dead else { return }

    changeState(to: .dead)

    // Остановить физику игрока
    physicsBody?.velocity = .zero
    physicsBody?.isDynamic = false

    // Уведомление о смерти
    NotificationCenter.default.post(name: .playerDied, object: self)
}
```

### 2. Обработка контактов с врагами и опасностями

```swift
// В GameScene.swift - didBegin(_ contact:)

func didBegin(_ contact: SKPhysicsContact) {
    let bodyA = contact.bodyA
    let bodyB = contact.bodyB

    // Определяем участников контакта
    let playerBody = bodyA.categoryBitMask == PhysicsCategory.player ? bodyA :
                     (bodyB.categoryBitMask == PhysicsCategory.player ? bodyB : nil)

    guard let playerBody = playerBody,
          let playerNode = playerBody.node as? Player else { return }

    let otherBody = playerBody === bodyA ? bodyB : bodyA

    switch otherBody.categoryBitMask {
    case PhysicsCategory.enemy:
        handlePlayerEnemyContact(player: playerNode, enemyBody: otherBody, contact: contact)

    case PhysicsCategory.hazard:
        handlePlayerHazardContact(player: playerNode)

    case PhysicsCategory.ground:
        handlePlayerGroundContact(player: playerNode)

    case PhysicsCategory.collectible:
        if let collectible = otherBody.node as? Collectible {
            collectible.collect(by: playerNode)
        }

    case PhysicsCategory.trigger:
        if let trigger = otherBody.node {
            handleTrigger(trigger)
        }

    default:
        break
    }
}

private func handlePlayerEnemyContact(player: Player, enemyBody: SKPhysicsBody, contact: SKPhysicsContact) {
    guard let enemy = enemyBody.node else { return }

    // Проверка: игрок прыгнул на врага сверху?
    let playerBottom = player.position.y - player.size.height / 2
    let enemyTop = enemy.position.y + (enemy.frame.height / 2)
    let isStompingEnemy = playerBottom > enemyTop - 10 && player.velocity.dy < 0

    if isStompingEnemy {
        // Урон врагу
        if let enemyEntity = enemy as? Enemy {
            enemyEntity.takeDamage(1, knockback: 0)
        }
        // Отскок игрока
        player.bounce()
    } else {
        // Урон игроку
        let knockbackDir: CGFloat = player.position.x < enemy.position.x ? -1 : 1
        player.takeDamage(1, knockbackDirection: knockbackDir)
    }
}

private func handlePlayerHazardContact(player: Player) {
    // Hazard наносит урон без отбрасывания
    player.takeDamage(1)
}

private func handlePlayerGroundContact(player: Player) {
    // Отметить что игрок на земле
    player.setGrounded(true)
}
```

### 3. Добавь метод bounce в Player

```swift
// В Player.swift

/// Отскок (при прыжке на врага)
func bounce() {
    velocity.dy = PlayerConfig.jumpForce * 0.7
    isGrounded = false
    changeState(to: .jumping)
}
```

### 4. Notifications

```swift
extension Notification.Name {
    static let playerDamaged = Notification.Name("playerDamaged")
    static let playerDied = Notification.Name("playerDied")
    static let requestCameraShake = Notification.Name("requestCameraShake")
}
```

### 5. Обработка смерти в GameScene

```swift
// В GameScene.swift

override func didMove(to view: SKView) {
    // ... existing code ...

    NotificationCenter.default.addObserver(
        self,
        selector: #selector(handlePlayerDied),
        name: .playerDied,
        object: nil
    )

    NotificationCenter.default.addObserver(
        self,
        selector: #selector(handleCameraShake(_:)),
        name: .requestCameraShake,
        object: nil
    )
}

@objc private func handlePlayerDied() {
    // Задержка перед game over
    run(SKAction.sequence([
        SKAction.wait(forDuration: 1.5),
        SKAction.run { [weak self] in
            self?.gameOver()
        }
    ]))
}

@objc private func handleCameraShake(_ notification: Notification) {
    guard let intensity = notification.userInfo?["intensity"] as? CGFloat,
          let duration = notification.userInfo?["duration"] as? TimeInterval else { return }

    gameCamera.shake(intensity: intensity, duration: duration)
}

// Респавн на чекпоинте
func respawnPlayer() {
    let spawnPosition = currentCheckpoint ?? currentLevelData?.playerSpawn.toPixels() ?? CGPoint(x: 100, y: 200)

    player.removeFromParent()
    player = Player()
    player.position = spawnPosition
    gameLayer.addChild(player)

    gameCamera.target = player
}
```

## Требования
- Урон с отбрасыванием
- Временная неуязвимость с визуальным миганием
- Прыжок на врага убивает его и отбрасывает игрока
- Тряска камеры при уроне
- Красная вспышка при уроне
- Респавн на чекпоинте при смерти

## После интеграции
1. Обнови файлы Player.swift и GameScene.swift
2. Собери: xcodebuild -project ChroniclesOfRifts/ChroniclesOfRifts.xcodeproj -scheme ChroniclesOfRifts -configuration Debug build
```

### Проверка после стадии 2.7

```bash
xcodebuild -project ChroniclesOfRifts/ChroniclesOfRifts.xcodeproj -scheme ChroniclesOfRifts -configuration Debug build
```

---

## Стадия 2.8: Финальная интеграция и тестовый уровень

### Промт

```
Создай полноценный тестовый уровень для проверки всех механик Фазы 2.

## Контекст
- Все компоненты Фазы 2 реализованы
- Нужен тестовый уровень для проверки:
  - Движение и прыжки игрока
  - Анимации
  - Атака
  - Сбор предметов
  - Получение урона
  - Чекпоинты

## Задачи

### 1. Создай JSON тестового уровня
Путь: ChroniclesOfRifts/ChroniclesOfRifts/Levels/level_test.json

```json
{
    "id": 0,
    "name": "Тестовый уровень",
    "width": 100,
    "height": 20,
    "tileSize": 32,

    "playerSpawn": {"x": 5, "y": 3},

    "bounds": {
        "x": 0,
        "y": 0,
        "width": 100,
        "height": 20
    },
    "deathZoneY": -2,

    "platforms": [
        {
            "position": {"x": 0, "y": 0},
            "size": {"width": 20, "height": 2},
            "type": "solid"
        },
        {
            "position": {"x": 25, "y": 0},
            "size": {"width": 15, "height": 2},
            "type": "solid"
        },
        {
            "position": {"x": 22, "y": 3},
            "size": {"width": 4, "height": 1},
            "type": "oneWay"
        },
        {
            "position": {"x": 30, "y": 5},
            "size": {"width": 3, "height": 1},
            "type": "crumbling"
        },
        {
            "position": {"x": 45, "y": 0},
            "size": {"width": 20, "height": 2},
            "type": "solid"
        },
        {
            "position": {"x": 35, "y": 3},
            "size": {"width": 4, "height": 1},
            "type": "moving",
            "movementPath": [
                {"x": 35, "y": 3},
                {"x": 42, "y": 3}
            ],
            "movementSpeed": 2
        },
        {
            "position": {"x": 70, "y": 0},
            "size": {"width": 30, "height": 2},
            "type": "solid"
        },
        {
            "position": {"x": 65, "y": 5},
            "size": {"width": 5, "height": 1},
            "type": "solid"
        }
    ],

    "collectibles": [
        {"type": "manaCrystal", "position": {"x": 8, "y": 4}},
        {"type": "manaCrystal", "position": {"x": 10, "y": 4}},
        {"type": "manaCrystal", "position": {"x": 12, "y": 4}},
        {"type": "healthPickup", "position": {"x": 50, "y": 3}},
        {"type": "checkpoint", "position": {"x": 45, "y": 3}, "id": "checkpoint_1"},
        {"type": "chroniclePage", "position": {"x": 67, "y": 7}, "id": "test_page_1"},
        {"type": "manaCrystal", "position": {"x": 80, "y": 4}},
        {"type": "manaCrystal", "position": {"x": 82, "y": 4}},
        {"type": "checkpoint", "position": {"x": 75, "y": 3}, "id": "checkpoint_2"}
    ],

    "enemies": [
        {"type": "Cultist", "position": {"x": 15, "y": 3}, "facing": "left"},
        {"type": "Cultist", "position": {"x": 55, "y": 3}, "facing": "right", "patrolPath": [{"x": 50, "y": 3}, {"x": 60, "y": 3}]}
    ],

    "interactables": [
        {"type": "levelExit", "position": {"x": 95, "y": 3}}
    ],

    "triggers": [],

    "backgroundLayers": [
        {"imageName": "bg_sky", "parallaxFactor": 0.1, "zPosition": -100},
        {"imageName": "bg_mountains", "parallaxFactor": 0.3, "zPosition": -90},
        {"imageName": "bg_trees", "parallaxFactor": 0.5, "zPosition": -80}
    ]
}
```

### 2. Обнови GameScene для загрузки уровня

```swift
// В GameScene.swift

override func didMove(to view: SKView) {
    super.didMove(to: view)

    inputManager.delegate = self
    setupPhysics()

    // Загрузка уровня
    loadLevel(named: "level_test")

    // Подписки на уведомления
    setupNotificationObservers()
}

private func loadLevel(named levelName: String) {
    guard let levelData = LevelLoader.load(levelName: levelName) else {
        print("Ошибка загрузки уровня: \(levelName)")
        return
    }

    currentLevelData = levelData

    // Границы камеры
    gameCamera.bounds = levelData.bounds.toPixels(tileSize: levelData.tileSize)

    // Создание платформ
    spawnPlatforms(from: levelData)

    // Создание предметов
    spawnCollectibles(from: levelData)

    // Создание игрока
    setupPlayer(at: levelData.playerSpawn.toPixels(tileSize: levelData.tileSize))

    // Враги (placeholder пока нет класса Enemy)
    spawnEnemyPlaceholders(from: levelData)
}

private func spawnPlatforms(from levelData: LevelData) {
    for platformData in levelData.platforms {
        let platform = createPlatform(
            at: platformData.position.toPixels(tileSize: levelData.tileSize),
            size: platformData.size.toPixels(tileSize: levelData.tileSize),
            type: platformData.type
        )
        gameLayer.addChild(platform)

        // Движущиеся платформы
        if platformData.type == .moving,
           let path = platformData.movementPath,
           let speed = platformData.movementSpeed {
            setupMovingPlatform(platform, path: path, speed: speed, tileSize: levelData.tileSize)
        }
    }
}

private func createPlatform(at position: CGPoint, size: CGSize, type: PlatformType) -> SKSpriteNode {
    let color: UIColor
    switch type {
    case .solid: color = UIColor(red: 0.4, green: 0.3, blue: 0.2, alpha: 1.0)
    case .oneWay: color = UIColor(red: 0.6, green: 0.5, blue: 0.3, alpha: 0.8)
    case .crumbling: color = UIColor(red: 0.5, green: 0.4, blue: 0.3, alpha: 1.0)
    case .moving: color = UIColor(red: 0.3, green: 0.5, blue: 0.6, alpha: 1.0)
    }

    let platform = SKSpriteNode(color: color, size: size)
    platform.position = CGPoint(x: position.x + size.width / 2, y: position.y + size.height / 2)
    platform.name = "platform_\(type.rawValue)"

    platform.physicsBody = SKPhysicsBody(rectangleOf: size)
    platform.physicsBody?.isDynamic = false
    platform.physicsBody?.categoryBitMask = PhysicsCategory.ground
    platform.physicsBody?.friction = 0.5

    // One-way платформы пропускают снизу
    if type == .oneWay {
        // Реализуется через contact delegate
        platform.userData = ["oneWay": true]
    }

    return platform
}

private func setupMovingPlatform(_ platform: SKSpriteNode, path: [CGPoint], speed: CGFloat, tileSize: CGFloat) {
    guard path.count >= 2 else { return }

    var actions: [SKAction] = []

    for point in path {
        let targetPos = point.toPixels(tileSize: tileSize)
        let adjustedTarget = CGPoint(
            x: targetPos.x + platform.size.width / 2,
            y: targetPos.y + platform.size.height / 2
        )

        let distance = hypot(
            adjustedTarget.x - platform.position.x,
            adjustedTarget.y - platform.position.y
        )
        let duration = TimeInterval(distance / (speed * tileSize))

        actions.append(SKAction.move(to: adjustedTarget, duration: duration))
    }

    // Добавляем обратный путь
    for point in path.reversed().dropFirst() {
        let targetPos = point.toPixels(tileSize: tileSize)
        let adjustedTarget = CGPoint(
            x: targetPos.x + platform.size.width / 2,
            y: targetPos.y + platform.size.height / 2
        )

        let distance = hypot(
            adjustedTarget.x - platform.position.x,
            adjustedTarget.y - platform.position.y
        )
        let duration = TimeInterval(distance / (speed * tileSize))

        actions.append(SKAction.move(to: adjustedTarget, duration: duration))
    }

    platform.run(SKAction.repeatForever(SKAction.sequence(actions)))
}

private func spawnCollectibles(from levelData: LevelData) {
    for collectibleData in levelData.collectibles {
        let collectible = Collectible(type: collectibleData.type, id: collectibleData.id)
        collectible.position = collectibleData.position.toPixels(tileSize: levelData.tileSize)
        gameLayer.addChild(collectible)
    }
}

private func setupPlayer(at position: CGPoint) {
    player = Player()
    player.position = position
    gameLayer.addChild(player)

    gameCamera.target = player
}

private func spawnEnemyPlaceholders(from levelData: LevelData) {
    // Временные placeholder-враги до реализации Фазы 3
    for enemyData in levelData.enemies {
        let enemy = SKSpriteNode(color: .red, size: CGSize(width: 32, height: 48))
        enemy.position = enemyData.position.toPixels(tileSize: levelData.tileSize)
        enemy.name = "enemy_placeholder"

        enemy.physicsBody = SKPhysicsBody(rectangleOf: enemy.size)
        enemy.physicsBody?.isDynamic = false
        enemy.physicsBody?.categoryBitMask = PhysicsCategory.enemy
        enemy.physicsBody?.contactTestBitMask = PhysicsCategory.player | PhysicsCategory.playerAttack

        gameLayer.addChild(enemy)
    }
}
```

### 3. Создай чек-лист для тестирования

```markdown
## Чек-лист тестирования Фазы 2

### Движение игрока
- [ ] Движение влево-вправо от джойстика
- [ ] Плавное ускорение и торможение
- [ ] Разворот спрайта при смене направления

### Прыжки
- [ ] Базовый прыжок
- [ ] Переменная высота (короткое/долгое нажатие)
- [ ] Coyote time (прыжок после схода с платформы)
- [ ] Jump buffer (прыжок перед приземлением)
- [ ] Нельзя прыгать в воздухе

### Анимации
- [ ] Idle при бездействии
- [ ] Walk при движении
- [ ] Jump при прыжке вверх
- [ ] Fall при падении
- [ ] Attack при атаке
- [ ] Hurt при уроне
- [ ] Мигание при неуязвимости

### Атака
- [ ] Хитбокс появляется перед игроком
- [ ] Визуальный эффект взмаха
- [ ] Кулдаун между атаками
- [ ] Урон врагам-placeholder'ам
- [ ] Эффект попадания

### Коллекционные предметы
- [ ] Кристаллы собираются и считаются
- [ ] Здоровье восстанавливается от пикапа
- [ ] Чекпоинт активируется визуально
- [ ] Страница хроник сохраняется

### Урон и смерть
- [ ] Урон от врагов
- [ ] Отбрасывание при уроне
- [ ] Временная неуязвимость
- [ ] Прыжок на врага убивает его
- [ ] Смерть при 0 здоровья
- [ ] Тряска камеры при уроне

### Платформы
- [ ] Твёрдые платформы
- [ ] Односторонние платформы (можно пройти снизу)
- [ ] Движущиеся платформы
- [ ] Падение в бездну = смерть

### Камера
- [ ] Следование за игроком
- [ ] Ограничение по границам уровня
- [ ] Тряска работает
```

## После интеграции
1. Добавь level_test.json в Resources или Levels группу
2. Обнови GameScene.swift
3. Собери: xcodebuild -project ChroniclesOfRifts/ChroniclesOfRifts.xcodeproj -scheme ChroniclesOfRifts -configuration Debug build
4. Запусти на симуляторе и пройди чек-лист
```

### Финальная проверка Фазы 2

```bash
# Собрать проект
xcodebuild -project ChroniclesOfRifts/ChroniclesOfRifts.xcodeproj -scheme ChroniclesOfRifts -configuration Debug build

# Запустить на симуляторе
xcodebuild -project ChroniclesOfRifts/ChroniclesOfRifts.xcodeproj -scheme ChroniclesOfRifts -destination 'platform=iOS Simulator,name=iPhone 15' build

# Или открыть в Xcode и запустить вручную
open ChroniclesOfRifts/ChroniclesOfRifts.xcodeproj
```

---

## Итоговая структура файлов Фазы 2

```
ChroniclesOfRifts/
├── Entities/
│   ├── Player.swift           (2.1, 2.4, 2.5, 2.7)
│   └── Collectible.swift      (2.6)
├── Components/
│   └── MeleeAttack.swift      (2.5)
├── Managers/
│   └── AnimationManager.swift (2.3)
├── Scenes/
│   └── GameScene.swift        (2.2, 2.5, 2.6, 2.7, 2.8)
└── Levels/
    └── level_test.json        (2.8)
```

## Зависимости между стадиями

```
2.1 Player Entity
    ↓
2.2 Integration → 2.3 AnimationManager
    ↓                ↓
    └────────────── 2.4 Animation Integration
                     ↓
2.5 MeleeAttack ────↓
    ↓
2.6 Collectibles
    ↓
2.7 Damage System
    ↓
2.8 Test Level (всё вместе)
```
