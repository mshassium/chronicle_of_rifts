import SpriteKit

/// Overlay с touch-элементами управления
final class TouchControlsOverlay: SKNode {

    // MARK: - UI Elements

    /// Виртуальный джойстик
    let joystick: VirtualJoystick

    /// Кнопка прыжка
    let jumpButton: ActionButton

    /// Кнопка атаки
    let attackButton: ActionButton

    /// Кнопка паузы
    let pauseButton: ActionButton

    // MARK: - Properties

    /// Менеджер ввода для передачи событий
    weak var inputManager: InputManager?

    /// Размер сцены
    private var sceneSize: CGSize = .zero

    /// Safe Area Insets
    private var safeAreaInsets: UIEdgeInsets = .zero

    // MARK: - Layout Constants

    /// Отступ джойстика от края
    private let joystickMargin: CGFloat = 80

    /// Отступ кнопок действий от края
    private let actionButtonMargin: CGFloat = 80

    /// Вертикальное расстояние между кнопками атаки и прыжка
    private let actionButtonSpacing: CGFloat = 80

    /// Отступ кнопки паузы от края
    private let pauseButtonMargin: CGFloat = 40

    // MARK: - Initialization

    override init() {
        joystick = VirtualJoystick(baseRadius: 50, stickRadius: 20)
        jumpButton = ActionButton(type: .jump, radius: 35)
        attackButton = ActionButton(type: .attack, radius: 35)
        pauseButton = ActionButton(type: .pause, radius: 25)

        super.init()

        addChild(joystick)
        addChild(jumpButton)
        addChild(attackButton)
        addChild(pauseButton)

        setupCallbacks()

        name = "touchControlsOverlay"
        zPosition = 1000 // Поверх всего HUD
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    /// Настроить overlay в сцене
    /// - Parameter scene: Сцена, в которой будет overlay
    func setup(in scene: SKScene) {
        sceneSize = scene.size
        updateSafeAreaInsets()
        updateLayout(for: sceneSize)
    }

    /// Обновить Safe Area Insets
    private func updateSafeAreaInsets() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            safeAreaInsets = window.safeAreaInsets
        }
    }

    /// Настроить callbacks для элементов управления
    private func setupCallbacks() {
        // Джойстик
        joystick.onValueChanged = { [weak self] value in
            self?.inputManager?.updateJoystickValue(value)
        }

        // Кнопка прыжка
        jumpButton.onPress = { [weak self] in
            self?.inputManager?.handleJumpPressed()
        }
        jumpButton.onRelease = { [weak self] in
            self?.inputManager?.handleJumpReleased()
        }

        // Кнопка атаки
        attackButton.onPress = { [weak self] in
            self?.inputManager?.handleAttackPressed()
        }

        // Кнопка паузы
        pauseButton.onPress = { [weak self] in
            self?.inputManager?.handlePausePressed()
        }
    }

    // MARK: - Layout

    /// Обновить расположение элементов
    /// - Parameter size: Новый размер сцены
    func updateLayout(for size: CGSize) {
        sceneSize = size
        updateSafeAreaInsets()

        // Координаты от центра сцены (для SKScene с anchorPoint (0.5, 0.5))
        let halfWidth = size.width / 2
        let halfHeight = size.height / 2

        // Джойстик - левый нижний угол
        let joystickX = -halfWidth + safeAreaInsets.left + joystickMargin
        let joystickY = -halfHeight + safeAreaInsets.bottom + joystickMargin
        joystick.position = CGPoint(x: joystickX, y: joystickY)

        // Кнопка прыжка - правый нижний угол
        let jumpX = halfWidth - safeAreaInsets.right - actionButtonMargin
        let jumpY = -halfHeight + safeAreaInsets.bottom + actionButtonMargin
        jumpButton.position = CGPoint(x: jumpX, y: jumpY)

        // Кнопка атаки - над кнопкой прыжка
        let attackX = jumpX
        let attackY = jumpY + actionButtonSpacing
        attackButton.position = CGPoint(x: attackX, y: attackY)

        // Кнопка паузы - правый верхний угол
        let pauseX = halfWidth - safeAreaInsets.right - pauseButtonMargin
        let pauseY = halfHeight - safeAreaInsets.top - pauseButtonMargin
        pauseButton.position = CGPoint(x: pauseX, y: pauseY)
    }

    // MARK: - Touch Handling

    /// Обработать касание
    /// - Parameters:
    ///   - phase: Фаза касания
    ///   - location: Позиция в координатах overlay
    ///   - touch: Объект касания
    func handleTouch(phase: UITouch.Phase, location: CGPoint, touch: UITouch) {
        switch phase {
        case .began:
            handleTouchBegan(at: location, touch: touch)
        case .moved:
            handleTouchMoved(at: location, touch: touch)
        case .ended, .cancelled:
            handleTouchEnded(touch: touch)
        default:
            break
        }
    }

    /// Обработка начала касания
    private func handleTouchBegan(at location: CGPoint, touch: UITouch) {
        // Проверяем джойстик
        let joystickLocation = convert(location, to: joystick)
        if joystick.touchBegan(at: joystickLocation, touch: touch) {
            return
        }

        // Проверяем кнопку паузы (приоритет выше остальных кнопок)
        let pauseLocation = convert(location, to: pauseButton)
        if pauseButton.touchBegan(at: pauseLocation, touch: touch) {
            return
        }

        // Проверяем кнопку прыжка
        let jumpLocation = convert(location, to: jumpButton)
        if jumpButton.touchBegan(at: jumpLocation, touch: touch) {
            return
        }

        // Проверяем кнопку атаки
        let attackLocation = convert(location, to: attackButton)
        if attackButton.touchBegan(at: attackLocation, touch: touch) {
            return
        }
    }

    /// Обработка движения касания
    private func handleTouchMoved(at location: CGPoint, touch: UITouch) {
        // Обновляем джойстик, если это его касание
        if joystick.activeTouch === touch {
            let joystickLocation = convert(location, to: joystick)
            joystick.touchMoved(to: joystickLocation)
        }
    }

    /// Обработка окончания касания
    private func handleTouchEnded(touch: UITouch) {
        // Завершаем касание джойстика
        if joystick.activeTouch === touch {
            joystick.touchEnded()
        }

        // Завершаем касание кнопок
        if jumpButton.activeTouch === touch {
            jumpButton.touchEnded()
        }
        if attackButton.activeTouch === touch {
            attackButton.touchEnded()
        }
        if pauseButton.activeTouch === touch {
            pauseButton.touchEnded()
        }
    }

    // MARK: - Public Methods

    /// Показать/скрыть элементы управления
    /// - Parameter visible: Должны ли элементы быть видимыми
    func setControlsVisible(_ visible: Bool, animated: Bool = true) {
        joystick.setVisible(visible, animated: animated)
        jumpButton.setVisible(visible, animated: animated)
        attackButton.setVisible(visible, animated: animated)
        // Кнопка паузы всегда видна, если только не скрываем все
        pauseButton.setVisible(visible, animated: animated)
    }

    /// Показать/скрыть игровые кнопки (без паузы)
    /// - Parameter visible: Должны ли элементы быть видимыми
    func setGameControlsVisible(_ visible: Bool, animated: Bool = true) {
        joystick.setVisible(visible, animated: animated)
        jumpButton.setVisible(visible, animated: animated)
        attackButton.setVisible(visible, animated: animated)
    }

    /// Сбросить все элементы управления
    func reset() {
        joystick.reset()
        jumpButton.reset()
        attackButton.reset()
        pauseButton.reset()
        inputManager?.reset()
    }

    /// Включить/выключить кнопку атаки
    func setAttackEnabled(_ enabled: Bool) {
        attackButton.isEnabled = enabled
    }

    /// Включить/выключить кнопку прыжка
    func setJumpEnabled(_ enabled: Bool) {
        jumpButton.isEnabled = enabled
    }
}
