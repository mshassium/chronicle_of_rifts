import SpriteKit

/// Игровая камера с плавным следованием и эффектами
class GameCamera: SKCameraNode {
    // MARK: - Properties

    /// Цель, за которой следует камера
    weak var target: SKNode?

    /// Границы уровня (камера не выходит за них)
    var levelBounds: CGRect?

    /// Плавность следования (0.0 - мгновенно, 1.0 - без следования)
    var smoothing: CGFloat = 0.1

    /// Смещение от центра персонажа
    var offset: CGPoint = .zero

    /// Размер viewport (размер экрана)
    var viewportSize: CGSize = .zero

    /// Текущий зум (1.0 = нормальный)
    private(set) var currentZoom: CGFloat = 1.0

    /// Идёт ли тряска камеры
    private(set) var isShaking: Bool = false

    // MARK: - Configuration

    /// Расстояние "смотреть вперёд" по направлению движения
    var lookAheadDistance: CGFloat = 50.0

    /// Смещение вверх для лучшего обзора
    var verticalBias: CGFloat = 30.0

    // MARK: - Private Properties

    /// Текущая интенсивность тряски
    private var shakeIntensity: CGFloat = 0

    /// Начальная интенсивность тряски (для затухания)
    private var initialShakeIntensity: CGFloat = 0

    /// Оставшееся время тряски
    private var shakeTimeRemaining: TimeInterval = 0

    /// Общая длительность тряски
    private var shakeDuration: TimeInterval = 0

    /// Режим слежения за точкой (для катсцен)
    private var isFocusing: Bool = false

    /// Точка фокуса (для катсцен)
    private var focusPoint: CGPoint = .zero

    /// Последняя позиция цели (для расчёта направления движения)
    private var lastTargetPosition: CGPoint = .zero

    /// Направление движения цели
    private var targetVelocity: CGPoint = .zero

    // MARK: - HUD Container

    /// Контейнер для HUD (не участвует в тряске)
    let hudContainer = SKNode()

    // MARK: - Initialization

    override init() {
        super.init()
        setupHUDContainer()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupHUDContainer()
    }

    private func setupHUDContainer() {
        hudContainer.name = "hudContainer"
        hudContainer.zPosition = 1000
        addChild(hudContainer)
    }

    // MARK: - Configuration

    /// Настроить камеру
    /// - Parameters:
    ///   - target: Цель для слежения
    ///   - bounds: Границы мира
    ///   - viewportSize: Размер экрана
    func configure(target: SKNode?, bounds: CGRect?, viewportSize: CGSize) {
        self.target = target
        self.levelBounds = bounds
        self.viewportSize = viewportSize

        if let target = target {
            lastTargetPosition = target.position
        }
    }

    // MARK: - Update

    /// Обновить позицию камеры (вызывать каждый кадр)
    func update(deltaTime: TimeInterval) {
        // Обновляем тряску
        updateShake(deltaTime: deltaTime)

        // Если в режиме фокуса на точке - не следуем за целью
        if isFocusing {
            return
        }

        guard let target = target else { return }

        // Расчёт скорости/направления движения цели
        let currentTargetPosition = target.position
        if deltaTime > 0 {
            targetVelocity = CGPoint(
                x: (currentTargetPosition.x - lastTargetPosition.x) / CGFloat(deltaTime),
                y: (currentTargetPosition.y - lastTargetPosition.y) / CGFloat(deltaTime)
            )
        }
        lastTargetPosition = currentTargetPosition

        // Нормализуем направление для look-ahead
        let velocityLength = sqrt(targetVelocity.x * targetVelocity.x + targetVelocity.y * targetVelocity.y)
        var lookAheadOffset = CGPoint.zero
        if velocityLength > 10 { // Порог минимальной скорости
            lookAheadOffset = CGPoint(
                x: (targetVelocity.x / velocityLength) * lookAheadDistance,
                y: 0 // Только по горизонтали для платформера
            )
        }

        // Целевая позиция с учётом offset, look-ahead и вертикального смещения
        var targetPosition = CGPoint(
            x: target.position.x + offset.x + lookAheadOffset.x,
            y: target.position.y + offset.y + verticalBias
        )

        // Ограничение по границам мира с учётом зума
        if let bounds = levelBounds {
            let halfWidth = viewportSize.width / 2 / currentZoom
            let halfHeight = viewportSize.height / 2 / currentZoom

            let minX = bounds.minX + halfWidth
            let maxX = bounds.maxX - halfWidth
            let minY = bounds.minY + halfHeight
            let maxY = bounds.maxY - halfHeight

            // Если уровень меньше экрана - центрируем
            if minX > maxX {
                targetPosition.x = bounds.midX
            } else {
                targetPosition.x = max(minX, min(maxX, targetPosition.x))
            }

            if minY > maxY {
                targetPosition.y = bounds.midY
            } else {
                targetPosition.y = max(minY, min(maxY, targetPosition.y))
            }
        }

        // Плавное следование (lerp)
        let lerpX = position.x + (targetPosition.x - position.x) * smoothing
        let lerpY = position.y + (targetPosition.y - position.y) * smoothing

        position = CGPoint(x: lerpX, y: lerpY)
    }

    /// Обновление эффекта тряски
    private func updateShake(deltaTime: TimeInterval) {
        guard isShaking else { return }

        shakeTimeRemaining -= deltaTime

        if shakeTimeRemaining <= 0 {
            // Тряска закончилась
            isShaking = false
            shakeIntensity = 0
            // Убираем смещение от тряски (HUD container уже не смещается)
            return
        }

        // Затухание интенсивности к концу
        let progress = shakeTimeRemaining / shakeDuration
        shakeIntensity = initialShakeIntensity * CGFloat(progress)

        // Применяем случайное смещение
        let shakeX = CGFloat.random(in: -shakeIntensity...shakeIntensity)
        let shakeY = CGFloat.random(in: -shakeIntensity...shakeIntensity)

        // Смещаем камеру, но не HUD (HUD в hudContainer не двигается)
        position = CGPoint(x: position.x + shakeX, y: position.y + shakeY)

        // Компенсируем смещение для HUD
        hudContainer.position = CGPoint(x: -shakeX, y: -shakeY)
    }

    // MARK: - Effects

    /// Тряска камеры
    /// - Parameters:
    ///   - intensity: Интенсивность тряски в пикселях
    ///   - duration: Длительность тряски
    func shake(intensity: CGFloat = 10, duration: TimeInterval = 0.3) {
        isShaking = true
        shakeIntensity = intensity
        initialShakeIntensity = intensity
        shakeDuration = duration
        shakeTimeRemaining = duration
    }

    /// Плавный зум
    /// - Parameters:
    ///   - scale: Новый масштаб (1.0 = нормальный, 0.5 = приближение x2, 2.0 = отдаление x2)
    ///   - duration: Длительность анимации
    func zoom(to scale: CGFloat, duration: TimeInterval = 0.5) {
        // Ограничиваем масштаб
        let clampedScale = max(0.5, min(2.0, scale))
        currentZoom = clampedScale

        let zoomAction = SKAction.scale(to: clampedScale, duration: duration)
        zoomAction.timingMode = .easeInEaseOut
        run(zoomAction)
    }

    /// Временно переместить камеру на точку (для катсцен)
    /// - Parameters:
    ///   - point: Точка фокуса
    ///   - duration: Длительность перемещения
    func focusOn(point: CGPoint, duration: TimeInterval = 1.0) {
        isFocusing = true
        focusPoint = point

        // Ограничиваем точку фокуса границами
        var clampedPoint = point
        if let bounds = levelBounds {
            let halfWidth = viewportSize.width / 2 / currentZoom
            let halfHeight = viewportSize.height / 2 / currentZoom

            clampedPoint.x = max(bounds.minX + halfWidth, min(bounds.maxX - halfWidth, point.x))
            clampedPoint.y = max(bounds.minY + halfHeight, min(bounds.maxY - halfHeight, point.y))
        }

        let moveAction = SKAction.move(to: clampedPoint, duration: duration)
        moveAction.timingMode = .easeInEaseOut
        run(moveAction)
    }

    /// Вернуться к слежению за target
    /// - Parameter duration: Длительность возврата
    func returnToTarget(duration: TimeInterval = 0.5) {
        guard let target = target else {
            isFocusing = false
            return
        }

        let targetPoint = CGPoint(
            x: target.position.x + offset.x,
            y: target.position.y + offset.y + verticalBias
        )

        let moveAction = SKAction.move(to: targetPoint, duration: duration)
        moveAction.timingMode = .easeInEaseOut

        run(SKAction.sequence([
            moveAction,
            SKAction.run { [weak self] in
                self?.isFocusing = false
            }
        ]))
    }

    /// Мгновенное перемещение к цели
    func snapToTarget() {
        guard let target = target else { return }

        var targetPosition = CGPoint(
            x: target.position.x + offset.x,
            y: target.position.y + offset.y + verticalBias
        )

        // Ограничение по границам
        if let bounds = levelBounds {
            let halfWidth = viewportSize.width / 2 / currentZoom
            let halfHeight = viewportSize.height / 2 / currentZoom

            targetPosition.x = max(bounds.minX + halfWidth, min(bounds.maxX - halfWidth, targetPosition.x))
            targetPosition.y = max(bounds.minY + halfHeight, min(bounds.maxY - halfHeight, targetPosition.y))
        }

        position = targetPosition
        lastTargetPosition = target.position
    }

    // MARK: - Legacy Compatibility

    /// Границы мира (алиас для совместимости)
    var worldBounds: CGRect? {
        get { levelBounds }
        set { levelBounds = newValue }
    }

    /// Скорость следования (алиас для совместимости)
    var followLerp: CGFloat {
        get { smoothing }
        set { smoothing = newValue }
    }
}
