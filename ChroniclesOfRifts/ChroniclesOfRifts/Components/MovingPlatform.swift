import SpriteKit

/// Тип движения платформы
enum MovementType: String, Codable {
    /// Зацикленное движение (A -> B -> C -> A -> ...)
    case loop
    /// Движение туда-обратно (A -> B -> C -> B -> A -> ...)
    case pingPong
    /// Однократное движение (A -> B -> C -> остановка)
    case oneWay
}

/// Движущаяся платформа с поддержкой нескольких waypoints и типов движения
class MovingPlatform: SKSpriteNode {

    // MARK: - Properties

    /// Точки маршрута движения
    private(set) var waypoints: [CGPoint]

    /// Скорость движения (пикселей в секунду)
    var moveSpeed: CGFloat

    /// Текущий индекс целевой точки
    private(set) var currentWaypointIndex: Int = 0

    /// Движется ли платформа
    private(set) var isMoving: Bool = true

    /// Пауза на каждой точке (секунды)
    var pauseAtWaypoints: TimeInterval = 0

    /// Тип движения
    var movementType: MovementType = .loop

    /// Направление движения для pingPong (true = вперёд, false = назад)
    private var movingForward: Bool = true

    /// Предыдущая позиция для расчёта дельты
    private(set) var previousPosition: CGPoint = .zero

    /// Ключ для действия движения
    private let moveActionKey = "movingPlatformMove"

    // MARK: - Initialization

    /// Создаёт движущуюся платформу
    /// - Parameters:
    ///   - size: Размер платформы
    ///   - waypoints: Точки маршрута (первая точка = начальная позиция)
    ///   - moveSpeed: Скорость движения в пикселях в секунду
    ///   - texture: Опциональная текстура
    init(size: CGSize, waypoints: [CGPoint], moveSpeed: CGFloat, texture: SKTexture? = nil) {
        self.waypoints = waypoints
        self.moveSpeed = moveSpeed

        let color = SKColor(red: 0.3, green: 0.4, blue: 0.5, alpha: 1.0)
        super.init(texture: texture, color: color, size: size)

        name = "platform_moving"

        // Начальная позиция - первый waypoint
        if let firstPoint = waypoints.first {
            position = firstPoint
            previousPosition = firstPoint
        }

        // Настраиваем физическое тело
        setupPhysicsBody(size: size)

        // Добавляем визуальные элементы
        addVisualIndicators()
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
        physicsBody?.friction = 1.0
        physicsBody?.restitution = 0
    }

    private func addVisualIndicators() {
        // Добавляем индикаторы движения (стрелки по бокам)
        let arrowColor = SKColor(red: 0.5, green: 0.6, blue: 0.7, alpha: 0.8)

        // Левая стрелка
        let leftArrow = SKShapeNode()
        let leftPath = CGMutablePath()
        leftPath.move(to: CGPoint(x: -size.width * 0.35, y: 0))
        leftPath.addLine(to: CGPoint(x: -size.width * 0.25, y: size.height * 0.15))
        leftPath.addLine(to: CGPoint(x: -size.width * 0.25, y: -size.height * 0.15))
        leftPath.closeSubpath()
        leftArrow.path = leftPath
        leftArrow.fillColor = arrowColor
        leftArrow.strokeColor = .clear
        leftArrow.zPosition = 1
        addChild(leftArrow)

        // Правая стрелка
        let rightArrow = SKShapeNode()
        let rightPath = CGMutablePath()
        rightPath.move(to: CGPoint(x: size.width * 0.35, y: 0))
        rightPath.addLine(to: CGPoint(x: size.width * 0.25, y: size.height * 0.15))
        rightPath.addLine(to: CGPoint(x: size.width * 0.25, y: -size.height * 0.15))
        rightPath.closeSubpath()
        rightArrow.path = rightPath
        rightArrow.fillColor = arrowColor
        rightArrow.strokeColor = .clear
        rightArrow.zPosition = 1
        addChild(rightArrow)
    }

    // MARK: - Movement Control

    /// Начинает движение платформы
    func startMoving() {
        guard !isMoving else { return }
        isMoving = true
        moveToNextWaypoint()
    }

    /// Останавливает движение платформы
    func stopMoving() {
        isMoving = false
        removeAction(forKey: moveActionKey)
    }

    /// Начинает движение к следующей точке маршрута
    func moveToNextWaypoint() {
        guard isMoving, waypoints.count > 1 else { return }

        // Определяем следующую точку
        let nextIndex = getNextWaypointIndex()
        let targetPoint = waypoints[nextIndex]

        // Рассчитываем длительность движения
        let duration = calculateDuration(to: targetPoint)

        // Создаём действие движения
        let moveAction = SKAction.move(to: targetPoint, duration: duration)
        moveAction.timingMode = .linear

        // Действие после достижения точки
        let completionAction = SKAction.run { [weak self] in
            self?.onWaypointReached(index: nextIndex)
        }

        // Пауза на точке (если задана)
        var sequence: [SKAction] = [moveAction, completionAction]
        if pauseAtWaypoints > 0 {
            sequence.append(SKAction.wait(forDuration: pauseAtWaypoints))
        }

        // Запуск цепочки действий
        sequence.append(SKAction.run { [weak self] in
            self?.moveToNextWaypoint()
        })

        run(SKAction.sequence(sequence), withKey: moveActionKey)

        // Обновляем индекс
        currentWaypointIndex = nextIndex
    }

    /// Вызывается при достижении waypoint
    private func onWaypointReached(index: Int) {
        // Для pingPong - меняем направление на крайних точках
        if movementType == .pingPong {
            if index == waypoints.count - 1 {
                movingForward = false
            } else if index == 0 {
                movingForward = true
            }
        }

        // Для oneWay - останавливаемся в конечной точке
        if movementType == .oneWay && index == waypoints.count - 1 {
            stopMoving()
        }
    }

    /// Определяет индекс следующей точки маршрута
    private func getNextWaypointIndex() -> Int {
        switch movementType {
        case .loop:
            return (currentWaypointIndex + 1) % waypoints.count

        case .pingPong:
            if movingForward {
                return min(currentWaypointIndex + 1, waypoints.count - 1)
            } else {
                return max(currentWaypointIndex - 1, 0)
            }

        case .oneWay:
            return min(currentWaypointIndex + 1, waypoints.count - 1)
        }
    }

    /// Рассчитывает длительность движения до точки
    /// - Parameter point: Целевая точка
    /// - Returns: Время в секундах
    private func calculateDuration(to point: CGPoint) -> TimeInterval {
        let distance = hypot(point.x - position.x, point.y - position.y)
        return TimeInterval(distance / moveSpeed)
    }

    // MARK: - Delta Calculation

    /// Рассчитывает вектор перемещения с предыдущего кадра
    /// - Returns: Вектор перемещения
    func calculateMovementDelta() -> CGVector {
        let delta = CGVector(
            dx: position.x - previousPosition.x,
            dy: position.y - previousPosition.y
        )
        return delta
    }

    /// Обновляет предыдущую позицию (вызывать в конце update)
    func updatePreviousPosition() {
        previousPosition = position
    }

    // MARK: - Configuration

    /// Устанавливает waypoints (позиция платформы перемещается к первой точке)
    /// - Parameter points: Массив точек маршрута
    func setWaypoints(_ points: [CGPoint]) {
        waypoints = points
        if let first = points.first {
            position = first
            previousPosition = first
        }
        currentWaypointIndex = 0
        movingForward = true

        // Перезапускаем движение если платформа двигалась
        if isMoving {
            removeAction(forKey: moveActionKey)
            moveToNextWaypoint()
        }
    }

    /// Конфигурирует платформу из данных уровня
    /// - Parameters:
    ///   - waypoints: Точки маршрута
    ///   - moveSpeed: Скорость
    ///   - movementType: Тип движения
    ///   - pauseAtWaypoints: Пауза на точках
    func configure(waypoints: [CGPoint], moveSpeed: CGFloat, movementType: MovementType = .loop, pauseAtWaypoints: TimeInterval = 0) {
        self.waypoints = waypoints
        self.moveSpeed = moveSpeed
        self.movementType = movementType
        self.pauseAtWaypoints = pauseAtWaypoints

        if let first = waypoints.first {
            previousPosition = first
        }

        currentWaypointIndex = 0
        movingForward = true
    }
}
