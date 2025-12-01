import SpriteKit

/// Протокол делегата для обработки ввода
protocol InputDelegate: AnyObject {
    /// Вызывается при движении джойстика
    /// - Parameter direction: Вектор направления от -1 до 1 по осям X и Y
    func joystickMoved(direction: CGVector)

    /// Вызывается при нажатии кнопки прыжка
    func jumpPressed()

    /// Вызывается при отпускании кнопки прыжка
    func jumpReleased()

    /// Вызывается при нажатии кнопки атаки
    func attackPressed()

    /// Вызывается при нажатии кнопки паузы
    func pausePressed()
}

/// Расширение с дефолтными пустыми реализациями
extension InputDelegate {
    func joystickMoved(direction: CGVector) {}
    func jumpPressed() {}
    func jumpReleased() {}
    func attackPressed() {}
    func pausePressed() {}
}

/// Менеджер ввода, обрабатывающий touch-события
final class InputManager {

    // MARK: - Properties

    /// Делегат для получения событий ввода
    weak var delegate: InputDelegate?

    /// Текущее значение джойстика (-1 до 1 по осям)
    private(set) var joystickValue: CGVector = .zero

    /// Удерживается ли кнопка прыжка
    private(set) var isJumpHeld: Bool = false

    /// Чувствительность джойстика (множитель)
    var sensitivity: CGFloat = 1.0

    // MARK: - Touch Handling

    /// Обработка начала касания
    /// - Parameters:
    ///   - touch: Объект касания
    ///   - view: Представление, в котором произошло касание
    func handleTouchBegan(_ touch: UITouch, in view: SKView) {
        // Обработка выполняется через TouchControlsOverlay
    }

    /// Обработка движения касания
    /// - Parameters:
    ///   - touch: Объект касания
    ///   - view: Представление, в котором произошло касание
    func handleTouchMoved(_ touch: UITouch, in view: SKView) {
        // Обработка выполняется через TouchControlsOverlay
    }

    /// Обработка окончания касания
    /// - Parameters:
    ///   - touch: Объект касания
    ///   - view: Представление, в котором произошло касание
    func handleTouchEnded(_ touch: UITouch, in view: SKView) {
        // Обработка выполняется через TouchControlsOverlay
    }

    // MARK: - Input Events

    /// Обновить значение джойстика
    /// - Parameter value: Новое значение вектора направления
    func updateJoystickValue(_ value: CGVector) {
        let adjustedValue = CGVector(
            dx: value.dx * sensitivity,
            dy: value.dy * sensitivity
        )
        joystickValue = adjustedValue
        delegate?.joystickMoved(direction: adjustedValue)
    }

    /// Обработать нажатие прыжка
    func handleJumpPressed() {
        isJumpHeld = true
        delegate?.jumpPressed()
    }

    /// Обработать отпускание прыжка
    func handleJumpReleased() {
        isJumpHeld = false
        delegate?.jumpReleased()
    }

    /// Обработать нажатие атаки
    func handleAttackPressed() {
        delegate?.attackPressed()
    }

    /// Обработать нажатие паузы
    func handlePausePressed() {
        delegate?.pausePressed()
    }

    /// Сбросить все значения ввода
    func reset() {
        joystickValue = .zero
        isJumpHeld = false
    }
}
