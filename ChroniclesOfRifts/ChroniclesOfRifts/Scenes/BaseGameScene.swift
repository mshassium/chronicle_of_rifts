import SpriteKit

/// Базовый класс для всех игровых сцен
/// Предоставляет общую функциональность: слои, камеру, паузу
class BaseGameScene: SKScene {
    // MARK: - Layers

    /// Слой фона (z = -100)
    let backgroundLayer = SKNode()

    /// Слой игровых объектов (z = 0)
    let gameLayer = SKNode()

    /// Слой UI/HUD (привязан к камере, z = 100)
    let hudLayer = SKNode()

    // MARK: - Camera

    /// Игровая камера
    let gameCamera = GameCamera()

    /// Параллакс-фон
    var parallaxBackground: ParallaxBackground!

    // MARK: - Input

    /// Менеджер ввода
    let inputManager = InputManager()

    /// Overlay с touch-элементами управления
    let touchControlsOverlay = TouchControlsOverlay()

    // MARK: - Properties

    /// Делегат сцены
    weak var sceneDelegate: GameSceneDelegate?

    /// Игра на паузе
    private(set) var isGamePaused: Bool = false

    /// Последнее время обновления
    private var lastUpdateTime: TimeInterval = 0

    // MARK: - Lifecycle

    override func didMove(to view: SKView) {
        super.didMove(to: view)

        setupLayers()
        setupCamera()
        setupTouchControls()

        // Включаем мультитач
        view.isMultipleTouchEnabled = true

        sceneDelegate?.sceneDidLoad(self)
    }

    override func willMove(from view: SKView) {
        super.willMove(from: view)
        sceneDelegate?.sceneWillTransition(self)
    }

    // MARK: - Setup

    /// Настройка слоёв сцены
    func setupLayers() {
        // Фоновый слой
        backgroundLayer.zPosition = -100
        backgroundLayer.name = "backgroundLayer"
        addChild(backgroundLayer)

        // Игровой слой
        gameLayer.zPosition = 0
        gameLayer.name = "gameLayer"
        addChild(gameLayer)

        // HUD слой (добавляется к камере, чтобы следовать за ней)
        hudLayer.zPosition = 100
        hudLayer.name = "hudLayer"
    }

    /// Настройка камеры
    func setupCamera() {
        gameCamera.viewportSize = size
        addChild(gameCamera)
        camera = gameCamera

        // HUD привязан к камере через hudContainer (не участвует в тряске)
        hudLayer.zPosition = 100
        gameCamera.hudContainer.addChild(hudLayer)

        // Инициализация параллакс-фона
        parallaxBackground = ParallaxBackground(parentNode: backgroundLayer)
        parallaxBackground.viewportSize = size
    }

    /// Настройка touch-управления
    func setupTouchControls() {
        // Связываем overlay с input manager
        touchControlsOverlay.inputManager = inputManager

        // Добавляем overlay к HUD слою
        hudLayer.addChild(touchControlsOverlay)

        // Настраиваем позиционирование
        touchControlsOverlay.setup(in: self)
    }

    // MARK: - Update Loop

    override func update(_ currentTime: TimeInterval) {
        // Расчёт delta time
        let deltaTime: TimeInterval
        if lastUpdateTime == 0 {
            deltaTime = 0
        } else {
            deltaTime = currentTime - lastUpdateTime
        }
        lastUpdateTime = currentTime

        // Не обновлять если на паузе
        guard !isGamePaused else { return }

        // Обновление камеры
        gameCamera.update(deltaTime: deltaTime)

        // Обновление параллакс-фона
        parallaxBackground.update(cameraPosition: gameCamera.position)

        // Вызов метода для наследников
        updateGame(deltaTime: deltaTime)
    }

    /// Переопределите этот метод в наследниках для игровой логики
    /// - Parameter deltaTime: Время с прошлого кадра
    func updateGame(deltaTime: TimeInterval) {
        // Override in subclasses
    }

    // MARK: - Pause

    /// Поставить игру на паузу
    func pauseGame() {
        guard !isGamePaused else { return }
        isGamePaused = true

        // Остановить физику и действия игрового слоя
        gameLayer.isPaused = true
        physicsWorld.speed = 0

        GameManager.shared.changeState(to: .paused)

        onGamePaused()
    }

    /// Снять игру с паузы
    func resumeGame() {
        guard isGamePaused else { return }
        isGamePaused = false

        // Возобновить физику и действия
        gameLayer.isPaused = false
        physicsWorld.speed = 1

        GameManager.shared.changeState(to: .playing)

        onGameResumed()
    }

    /// Переключить паузу
    func togglePause() {
        if isGamePaused {
            resumeGame()
        } else {
            pauseGame()
        }
    }

    /// Вызывается при постановке на паузу (для переопределения)
    func onGamePaused() {
        // Override in subclasses to show pause menu, etc.
    }

    /// Вызывается при снятии с паузы (для переопределения)
    func onGameResumed() {
        // Override in subclasses
    }

    // MARK: - Game Over

    /// Обработка проигрыша
    func gameOver() {
        isGamePaused = true
        gameLayer.isPaused = true
        physicsWorld.speed = 0

        sceneDelegate?.playerDidDie()

        // Небольшая задержка перед показом экрана Game Over
        run(SKAction.sequence([
            SKAction.wait(forDuration: 1.0),
            SKAction.run {
                SceneManager.shared.presentGameOver()
            }
        ]))
    }

    /// Обработка завершения уровня
    /// - Parameters:
    ///   - crystals: Собранные кристаллы
    ///   - secrets: Найденные секреты
    func levelComplete(crystals: Int = 0, secrets: Int = 0) {
        isGamePaused = true
        gameLayer.isPaused = true
        physicsWorld.speed = 0

        sceneDelegate?.levelDidComplete(crystals: crystals, secrets: secrets)

        run(SKAction.sequence([
            SKAction.wait(forDuration: 1.5),
            SKAction.run {
                SceneManager.shared.presentLevelComplete(crystals: crystals, secrets: secrets)
            }
        ]))
    }

    // MARK: - Utility

    /// Конвертировать координаты из экранных в игровые
    func gameLayerPosition(for screenPosition: CGPoint) -> CGPoint {
        return convert(screenPosition, to: gameLayer)
    }

    /// Конвертировать координаты из игровых в экранные
    func screenPosition(for gameLayerPosition: CGPoint) -> CGPoint {
        return convert(gameLayerPosition, from: gameLayer)
    }

    // MARK: - Touch Handling

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let location = touch.location(in: hudLayer)
            touchControlsOverlay.handleTouch(phase: .began, location: location, touch: touch)
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let location = touch.location(in: hudLayer)
            touchControlsOverlay.handleTouch(phase: .moved, location: location, touch: touch)
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let location = touch.location(in: hudLayer)
            touchControlsOverlay.handleTouch(phase: .ended, location: location, touch: touch)
        }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let location = touch.location(in: hudLayer)
            touchControlsOverlay.handleTouch(phase: .cancelled, location: location, touch: touch)
        }
    }
}
