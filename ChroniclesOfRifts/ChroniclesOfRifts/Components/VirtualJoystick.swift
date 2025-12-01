import SpriteKit

/// Виртуальный джойстик для управления персонажем
final class VirtualJoystick: SKNode {

    // MARK: - Visual Elements

    /// Основание джойстика (внешний круг)
    private let baseNode: SKShapeNode

    /// Стик джойстика (внутренний круг)
    private let stickNode: SKShapeNode

    // MARK: - Properties

    /// Радиус основания джойстика
    let baseRadius: CGFloat

    /// Радиус стика
    let stickRadius: CGFloat

    /// Максимальное отклонение стика от центра
    var maxDisplacement: CGFloat {
        return baseRadius - stickRadius
    }

    /// Текущее значение джойстика (-1 до 1 по осям X и Y)
    private(set) var value: CGVector = .zero

    /// Активен ли джойстик в данный момент
    private(set) var isActive: Bool = false

    /// Текущее активное касание
    weak var activeTouch: UITouch?

    // MARK: - Colors

    /// Цвет основания
    private let baseColor = UIColor.white.withAlphaComponent(0.3)

    /// Цвет стика в неактивном состоянии
    private let stickColor = UIColor.white.withAlphaComponent(0.6)

    /// Цвет стика в активном состоянии
    private let activeStickColor = UIColor.white.withAlphaComponent(0.9)

    // MARK: - Callbacks

    /// Вызывается при изменении значения джойстика
    var onValueChanged: ((CGVector) -> Void)?

    // MARK: - Initialization

    /// Инициализация джойстика
    /// - Parameters:
    ///   - baseRadius: Радиус основания (по умолчанию 50)
    ///   - stickRadius: Радиус стика (по умолчанию 20)
    init(baseRadius: CGFloat = 50, stickRadius: CGFloat = 20) {
        self.baseRadius = baseRadius
        self.stickRadius = stickRadius

        // Создание основания
        baseNode = SKShapeNode(circleOfRadius: baseRadius)
        baseNode.fillColor = baseColor
        baseNode.strokeColor = UIColor.white.withAlphaComponent(0.5)
        baseNode.lineWidth = 2

        // Создание стика
        stickNode = SKShapeNode(circleOfRadius: stickRadius)
        stickNode.fillColor = stickColor
        stickNode.strokeColor = UIColor.white.withAlphaComponent(0.7)
        stickNode.lineWidth = 1

        super.init()

        addChild(baseNode)
        addChild(stickNode)

        name = "virtualJoystick"
        isUserInteractionEnabled = false // Обрабатывается родительским overlay
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Touch Handling

    /// Проверить, находится ли точка в зоне джойстика
    /// - Parameter point: Точка в локальных координатах
    /// - Returns: true, если точка в пределах джойстика
    func isPointInside(_ point: CGPoint) -> Bool {
        let distance = hypot(point.x, point.y)
        // Увеличиваем зону для удобства (1.5x радиус)
        return distance <= baseRadius * 1.5
    }

    /// Обработка начала касания
    /// - Parameters:
    ///   - point: Позиция касания в локальных координатах джойстика
    ///   - touch: Объект касания
    /// - Returns: true, если касание было обработано
    @discardableResult
    func touchBegan(at point: CGPoint, touch: UITouch) -> Bool {
        guard isPointInside(point), activeTouch == nil else { return false }

        isActive = true
        activeTouch = touch
        updateStickPosition(to: point)
        updateVisuals()

        return true
    }

    /// Обработка движения касания
    /// - Parameter point: Новая позиция касания в локальных координатах
    func touchMoved(to point: CGPoint) {
        guard isActive else { return }
        updateStickPosition(to: point)
    }

    /// Обработка окончания касания
    func touchEnded() {
        guard isActive else { return }

        isActive = false
        activeTouch = nil

        // Анимация возврата стика в центр
        let returnAction = SKAction.move(to: .zero, duration: 0.15)
        returnAction.timingMode = .easeOut
        stickNode.run(returnAction)

        value = .zero
        onValueChanged?(.zero)
        updateVisuals()
    }

    // MARK: - Private Methods

    /// Обновить позицию стика с ограничением по радиусу
    /// - Parameter point: Целевая позиция
    private func updateStickPosition(to point: CGPoint) {
        let distance = hypot(point.x, point.y)
        var newPosition = point

        // Ограничение по максимальному смещению
        if distance > maxDisplacement {
            let angle = atan2(point.y, point.x)
            newPosition = CGPoint(
                x: cos(angle) * maxDisplacement,
                y: sin(angle) * maxDisplacement
            )
        }

        stickNode.position = newPosition

        // Вычисление нормализованного значения
        if maxDisplacement > 0 {
            value = CGVector(
                dx: newPosition.x / maxDisplacement,
                dy: newPosition.y / maxDisplacement
            )
        } else {
            value = .zero
        }

        onValueChanged?(value)
    }

    /// Обновить визуальное состояние
    private func updateVisuals() {
        let targetColor = isActive ? activeStickColor : stickColor
        let fadeAction = SKAction.customAction(withDuration: 0.1) { [weak self] _, _ in
            self?.stickNode.fillColor = targetColor
        }
        stickNode.run(fadeAction)
    }

    // MARK: - Public Methods

    /// Сбросить джойстик в начальное состояние
    func reset() {
        isActive = false
        activeTouch = nil
        stickNode.position = .zero
        value = .zero
        updateVisuals()
    }

    /// Установить видимость джойстика с анимацией
    /// - Parameter visible: Должен ли джойстик быть видимым
    func setVisible(_ visible: Bool, animated: Bool = true) {
        let targetAlpha: CGFloat = visible ? 1.0 : 0.0

        if animated {
            let fadeAction = SKAction.fadeAlpha(to: targetAlpha, duration: 0.2)
            run(fadeAction)
        } else {
            alpha = targetAlpha
        }
    }
}
