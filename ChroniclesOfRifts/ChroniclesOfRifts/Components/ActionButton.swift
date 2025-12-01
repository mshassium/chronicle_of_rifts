import SpriteKit

/// Тип кнопки действия
enum ButtonType {
    case jump
    case attack
    case pause
    case special // Для будущих способностей

    /// Иконка для кнопки (placeholder)
    var iconName: String {
        switch self {
        case .jump: return "button_jump"
        case .attack: return "button_attack"
        case .pause: return "button_pause"
        case .special: return "button_special"
        }
    }

    /// Символ для отображения, если иконка не найдена
    var fallbackSymbol: String {
        switch self {
        case .jump: return "↑"
        case .attack: return "⚔"
        case .pause: return "⏸"
        case .special: return "★"
        }
    }
}

/// Кнопка действия для touch-управления
final class ActionButton: SKNode {

    // MARK: - Visual Elements

    /// Фоновый круг кнопки
    private let backgroundNode: SKShapeNode

    /// Иконка кнопки (если есть текстура)
    private let iconNode: SKSpriteNode

    /// Текстовый символ (если нет текстуры)
    private let labelNode: SKLabelNode

    // MARK: - Properties

    /// Тип кнопки
    let buttonType: ButtonType

    /// Радиус кнопки
    let radius: CGFloat

    /// Нажата ли кнопка
    private(set) var isPressed: Bool = false

    /// Активна ли кнопка (можно ли нажимать)
    var isEnabled: Bool = true {
        didSet {
            updateVisualState()
        }
    }

    /// Активное касание для этой кнопки
    weak var activeTouch: UITouch?

    // MARK: - Callbacks

    /// Вызывается при нажатии кнопки
    var onPress: (() -> Void)?

    /// Вызывается при отпускании кнопки
    var onRelease: (() -> Void)?

    // MARK: - Visual States

    /// Альфа в нормальном состоянии
    private let normalAlpha: CGFloat = 0.6

    /// Альфа в нажатом состоянии
    private let pressedAlpha: CGFloat = 1.0

    /// Альфа в отключённом состоянии
    private let disabledAlpha: CGFloat = 0.3

    /// Масштаб в нажатом состоянии
    private let pressedScale: CGFloat = 0.9

    // MARK: - Initialization

    /// Инициализация кнопки действия
    /// - Parameters:
    ///   - type: Тип кнопки
    ///   - radius: Радиус кнопки (по умолчанию 30)
    init(type: ButtonType, radius: CGFloat = 30) {
        self.buttonType = type
        self.radius = radius

        // Создание фона
        backgroundNode = SKShapeNode(circleOfRadius: radius)
        backgroundNode.fillColor = UIColor.white.withAlphaComponent(0.2)
        backgroundNode.strokeColor = UIColor.white.withAlphaComponent(0.5)
        backgroundNode.lineWidth = 2

        // Создание иконки
        iconNode = SKSpriteNode()
        iconNode.size = CGSize(width: radius * 1.2, height: radius * 1.2)

        // Создание текстового лейбла
        labelNode = SKLabelNode(fontNamed: "Helvetica-Bold")
        labelNode.fontSize = radius * 0.8
        labelNode.fontColor = .white
        labelNode.verticalAlignmentMode = .center
        labelNode.horizontalAlignmentMode = .center
        labelNode.text = type.fallbackSymbol

        super.init()

        addChild(backgroundNode)
        addChild(iconNode)
        addChild(labelNode)

        // Попытка загрузить иконку
        loadIcon()

        name = "actionButton_\(type)"
        isUserInteractionEnabled = false // Обрабатывается родительским overlay

        updateVisualState()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    /// Загрузить иконку из ресурсов
    private func loadIcon() {
        if let texture = SKTexture(imageNamed: buttonType.iconName).size().width > 0 ? SKTexture(imageNamed: buttonType.iconName) : nil {
            iconNode.texture = texture
            iconNode.isHidden = false
            labelNode.isHidden = true
        } else {
            iconNode.isHidden = true
            labelNode.isHidden = false
        }
    }

    // MARK: - Touch Handling

    /// Проверить, находится ли точка в пределах кнопки
    /// - Parameter point: Точка в локальных координатах
    /// - Returns: true, если точка в пределах кнопки
    func isPointInside(_ point: CGPoint) -> Bool {
        let distance = hypot(point.x, point.y)
        // Немного увеличиваем зону для удобства
        return distance <= radius * 1.3
    }

    /// Обработка начала касания
    /// - Parameters:
    ///   - point: Позиция касания в локальных координатах
    ///   - touch: Объект касания
    /// - Returns: true, если касание было обработано
    @discardableResult
    func touchBegan(at point: CGPoint, touch: UITouch) -> Bool {
        guard isPointInside(point), isEnabled, activeTouch == nil else { return false }

        isPressed = true
        activeTouch = touch
        animatePress()
        onPress?()

        return true
    }

    /// Обработка окончания касания
    func touchEnded() {
        guard isPressed else { return }

        isPressed = false
        activeTouch = nil
        animateRelease()
        onRelease?()
    }

    // MARK: - Animations

    /// Анимация нажатия
    private func animatePress() {
        let scaleAction = SKAction.scale(to: pressedScale, duration: 0.05)
        scaleAction.timingMode = .easeOut

        backgroundNode.run(scaleAction)
        iconNode.run(scaleAction)
        labelNode.run(scaleAction)

        alpha = pressedAlpha
    }

    /// Анимация отпускания
    private func animateRelease() {
        let scaleAction = SKAction.scale(to: 1.0, duration: 0.1)
        scaleAction.timingMode = .easeOut

        backgroundNode.run(scaleAction)
        iconNode.run(scaleAction)
        labelNode.run(scaleAction)

        updateVisualState()
    }

    /// Обновить визуальное состояние в зависимости от isEnabled
    private func updateVisualState() {
        if !isEnabled {
            alpha = disabledAlpha
        } else if isPressed {
            alpha = pressedAlpha
        } else {
            alpha = normalAlpha
        }
    }

    // MARK: - Public Methods

    /// Сбросить кнопку в начальное состояние
    func reset() {
        isPressed = false
        activeTouch = nil
        setScale(1.0)
        updateVisualState()
    }

    /// Установить видимость кнопки с анимацией
    /// - Parameter visible: Должна ли кнопка быть видимой
    func setVisible(_ visible: Bool, animated: Bool = true) {
        let targetAlpha: CGFloat = visible ? (isEnabled ? normalAlpha : disabledAlpha) : 0.0

        if animated {
            let fadeAction = SKAction.fadeAlpha(to: targetAlpha, duration: 0.2)
            run(fadeAction)
        } else {
            alpha = targetAlpha
        }
    }
}
