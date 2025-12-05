import SpriteKit

// MARK: - Notification Names

extension Notification.Name {
    static let switchActivated = Notification.Name("switchActivated")
}

// MARK: - GameSwitch

/// Переключатель, активирующий связанную дверь
class GameSwitch: SKSpriteNode {

    // MARK: - Activation Type

    enum ActivationType: String {
        case attack     // активируется атакой
        case step       // активируется при наступании
        case interact   // активируется кнопкой взаимодействия (будущее)
    }

    // MARK: - Properties

    /// Активирован ли переключатель
    private(set) var isActivated: Bool = false

    /// ID связанной двери
    let linkedDoorId: String

    /// Тип активации
    let activationType: ActivationType

    /// Может ли переключатель быть деактивирован (toggle)
    var isToggleable: Bool = false

    // MARK: - Visual

    private let inactiveColor = SKColor(red: 0.5, green: 0.5, blue: 0.3, alpha: 1.0)
    private let activeColor = SKColor(red: 0.3, green: 0.8, blue: 0.3, alpha: 1.0)

    // MARK: - Initialization

    init(linkedDoorId: String, activationType: ActivationType = .attack, size: CGSize = CGSize(width: 32, height: 32)) {
        self.linkedDoorId = linkedDoorId
        self.activationType = activationType

        super.init(texture: nil, color: inactiveColor, size: size)

        self.name = "switch_\(linkedDoorId)"

        setupPhysics()
        setupVisual()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupPhysics() {
        physicsBody = SKPhysicsBody(rectangleOf: size)
        physicsBody?.isDynamic = false
        physicsBody?.categoryBitMask = PhysicsCategory.trigger

        switch activationType {
        case .attack:
            physicsBody?.contactTestBitMask = PhysicsCategory.playerAttack
        case .step:
            physicsBody?.contactTestBitMask = PhysicsCategory.player
        case .interact:
            physicsBody?.contactTestBitMask = PhysicsCategory.player
        }

        physicsBody?.collisionBitMask = 0
    }

    private func setupVisual() {
        // Базовый спрайт - квадрат с рамкой
        let border = SKShapeNode(rectOf: CGSize(width: size.width - 4, height: size.height - 4), cornerRadius: 4)
        border.strokeColor = SKColor(white: 0.3, alpha: 1.0)
        border.lineWidth = 2
        border.fillColor = .clear
        border.name = "border"
        addChild(border)

        // Индикатор в центре
        let indicator = SKShapeNode(circleOfRadius: size.width * 0.25)
        indicator.fillColor = SKColor(red: 0.6, green: 0.2, blue: 0.2, alpha: 1.0)
        indicator.strokeColor = .clear
        indicator.name = "indicator"
        addChild(indicator)
    }

    // MARK: - Activation

    /// Активировать переключатель
    func activate() {
        guard !isActivated else { return }

        isActivated = true
        playActivationAnimation()
        notifyLinkedDoor()

        // Регистрируем в менеджере
        SwitchDoorManager.shared.handleSwitchActivated(doorId: linkedDoorId)
    }

    /// Деактивировать переключатель (для toggle режима)
    func deactivate() {
        guard isActivated && isToggleable else { return }

        isActivated = false
        playDeactivationAnimation()

        // Уведомляем о деактивации
        NotificationCenter.default.post(
            name: .switchActivated,
            object: self,
            userInfo: ["doorId": linkedDoorId, "activated": false]
        )
    }

    /// Переключить состояние
    func toggle() {
        if isActivated {
            deactivate()
        } else {
            activate()
        }
    }

    // MARK: - Animations

    private func playActivationAnimation() {
        // Меняем цвет
        run(SKAction.colorize(with: activeColor, colorBlendFactor: 1.0, duration: 0.2))

        // Индикатор меняет цвет на зелёный
        if let indicator = childNode(withName: "indicator") as? SKShapeNode {
            let changeColor = SKAction.run {
                indicator.fillColor = SKColor(red: 0.2, green: 0.8, blue: 0.2, alpha: 1.0)
            }
            let scale = SKAction.sequence([
                SKAction.scale(to: 1.3, duration: 0.1),
                SKAction.scale(to: 1.0, duration: 0.1)
            ])
            indicator.run(SKAction.group([changeColor, scale]))
        }

        // Звуковой эффект (опционально)
        // run(SKAction.playSoundFileNamed("switch_on.wav", waitForCompletion: false))
    }

    private func playDeactivationAnimation() {
        // Меняем цвет обратно
        run(SKAction.colorize(with: inactiveColor, colorBlendFactor: 1.0, duration: 0.2))

        // Индикатор меняет цвет на красный
        if let indicator = childNode(withName: "indicator") as? SKShapeNode {
            let changeColor = SKAction.run {
                indicator.fillColor = SKColor(red: 0.6, green: 0.2, blue: 0.2, alpha: 1.0)
            }
            indicator.run(changeColor)
        }
    }

    private func notifyLinkedDoor() {
        NotificationCenter.default.post(
            name: .switchActivated,
            object: self,
            userInfo: ["doorId": linkedDoorId, "activated": true]
        )
    }
}

// MARK: - GameDoor

/// Дверь, открываемая переключателем
class GameDoor: SKSpriteNode {

    // MARK: - Open Direction

    enum OpenDirection: String {
        case up     // дверь поднимается
        case down   // дверь опускается
        case fade   // дверь исчезает
    }

    // MARK: - Properties

    /// Уникальный ID двери
    let doorId: String

    /// Открыта ли дверь
    private(set) var isOpen: Bool = false

    /// Направление открытия
    let openDirection: OpenDirection

    /// Автоматически закрыть через указанное время (0 = не закрывать)
    var autoCloseDelay: TimeInterval = 0

    /// Исходная позиция для анимации
    private var originalPosition: CGPoint = .zero

    // MARK: - Visual

    private let doorColor = SKColor(red: 0.4, green: 0.3, blue: 0.2, alpha: 1.0)

    // MARK: - Initialization

    init(doorId: String, openDirection: OpenDirection = .up, size: CGSize = CGSize(width: 48, height: 96)) {
        self.doorId = doorId
        self.openDirection = openDirection

        super.init(texture: nil, color: doorColor, size: size)

        self.name = "door_\(doorId)"

        setupPhysics()
        setupVisual()
        subscribeToNotifications()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Setup

    private func setupPhysics() {
        physicsBody = SKPhysicsBody(rectangleOf: size)
        physicsBody?.isDynamic = false
        physicsBody?.categoryBitMask = PhysicsCategory.ground
        physicsBody?.contactTestBitMask = PhysicsCategory.player
        physicsBody?.collisionBitMask = PhysicsCategory.player | PhysicsCategory.enemy
    }

    private func setupVisual() {
        // Добавляем текстуру двери (вертикальные полосы)
        let stripeCount = 4
        let stripeWidth: CGFloat = 4
        let spacing = (size.width - CGFloat(stripeCount) * stripeWidth) / CGFloat(stripeCount + 1)

        for i in 0..<stripeCount {
            let stripe = SKSpriteNode(
                color: SKColor(red: 0.5, green: 0.4, blue: 0.3, alpha: 1.0),
                size: CGSize(width: stripeWidth, height: size.height - 8)
            )
            stripe.position = CGPoint(
                x: -size.width / 2 + spacing + CGFloat(i) * (stripeWidth + spacing) + stripeWidth / 2,
                y: 0
            )
            addChild(stripe)
        }

        // Рамка двери
        let frame = SKShapeNode(rectOf: size)
        frame.strokeColor = SKColor(red: 0.3, green: 0.2, blue: 0.1, alpha: 1.0)
        frame.lineWidth = 3
        frame.fillColor = .clear
        addChild(frame)
    }

    private func subscribeToNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleSwitchActivated(_:)),
            name: .switchActivated,
            object: nil
        )
    }

    /// Сохраняет исходную позицию (вызывать после добавления на сцену)
    func saveOriginalPosition() {
        originalPosition = position
    }

    // MARK: - Notification Handling

    @objc private func handleSwitchActivated(_ notification: Notification) {
        guard let info = notification.userInfo,
              let targetDoorId = info["doorId"] as? String,
              targetDoorId == doorId else { return }

        let activated = info["activated"] as? Bool ?? true

        if activated {
            open()
        } else {
            close()
        }
    }

    // MARK: - Open/Close

    /// Открыть дверь
    func open() {
        guard !isOpen else { return }

        isOpen = true

        // Отключаем физику (дверь становится проходимой)
        physicsBody?.categoryBitMask = 0
        physicsBody?.collisionBitMask = 0

        playOpenAnimation()

        // Автозакрытие
        if autoCloseDelay > 0 {
            run(SKAction.sequence([
                SKAction.wait(forDuration: autoCloseDelay),
                SKAction.run { [weak self] in
                    self?.close()
                }
            ]), withKey: "autoClose")
        }
    }

    /// Закрыть дверь
    func close() {
        guard isOpen else { return }

        // Отменяем автозакрытие если было запланировано
        removeAction(forKey: "autoClose")

        isOpen = false

        playCloseAnimation { [weak self] in
            // Восстанавливаем физику после закрытия
            self?.physicsBody?.categoryBitMask = PhysicsCategory.ground
            self?.physicsBody?.collisionBitMask = PhysicsCategory.player | PhysicsCategory.enemy
        }
    }

    // MARK: - Animations

    private func playOpenAnimation() {
        removeAllActions()

        let duration: TimeInterval = 0.5

        switch openDirection {
        case .up:
            let moveUp = SKAction.moveBy(x: 0, y: size.height + 10, duration: duration)
            moveUp.timingMode = .easeOut
            run(moveUp)

        case .down:
            let moveDown = SKAction.moveBy(x: 0, y: -(size.height + 10), duration: duration)
            moveDown.timingMode = .easeOut
            run(moveDown)

        case .fade:
            let fadeOut = SKAction.fadeOut(withDuration: duration)
            run(fadeOut)
        }

        // Звуковой эффект (опционально)
        // run(SKAction.playSoundFileNamed("door_open.wav", waitForCompletion: false))
    }

    private func playCloseAnimation(completion: @escaping () -> Void) {
        let duration: TimeInterval = 0.5

        switch openDirection {
        case .up:
            let moveDown = SKAction.move(to: originalPosition, duration: duration)
            moveDown.timingMode = .easeIn
            run(SKAction.sequence([moveDown, SKAction.run(completion)]))

        case .down:
            let moveUp = SKAction.move(to: originalPosition, duration: duration)
            moveUp.timingMode = .easeIn
            run(SKAction.sequence([moveUp, SKAction.run(completion)]))

        case .fade:
            let fadeIn = SKAction.fadeIn(withDuration: duration)
            run(SKAction.sequence([fadeIn, SKAction.run(completion)]))
        }
    }
}

// MARK: - SwitchDoorManager

/// Синглтон для управления связями переключателей и дверей
class SwitchDoorManager {

    // MARK: - Singleton

    static let shared = SwitchDoorManager()

    private init() {}

    // MARK: - Properties

    private var switches: [String: GameSwitch] = [:]
    private var doors: [String: GameDoor] = [:]

    // MARK: - Registration

    /// Регистрирует переключатель
    func registerSwitch(_ gameSwitch: GameSwitch) {
        switches[gameSwitch.linkedDoorId] = gameSwitch
    }

    /// Регистрирует дверь
    func registerDoor(_ door: GameDoor) {
        doors[door.doorId] = door
    }

    /// Удаляет регистрацию переключателя
    func unregisterSwitch(linkedDoorId: String) {
        switches.removeValue(forKey: linkedDoorId)
    }

    /// Удаляет регистрацию двери
    func unregisterDoor(doorId: String) {
        doors.removeValue(forKey: doorId)
    }

    /// Очищает все регистрации (при смене уровня)
    func clearAll() {
        switches.removeAll()
        doors.removeAll()
    }

    // MARK: - Switch Handling

    /// Обрабатывает активацию переключателя
    func handleSwitchActivated(doorId: String) {
        guard let door = doors[doorId] else {
            print("SwitchDoorManager: Дверь с ID '\(doorId)' не найдена")
            return
        }

        door.open()
    }

    // MARK: - Queries

    /// Получить переключатель по ID связанной двери
    func getSwitch(forDoorId doorId: String) -> GameSwitch? {
        return switches[doorId]
    }

    /// Получить дверь по ID
    func getDoor(byId doorId: String) -> GameDoor? {
        return doors[doorId]
    }

    /// Проверить, открыта ли дверь
    func isDoorOpen(doorId: String) -> Bool {
        return doors[doorId]?.isOpen ?? false
    }
}
