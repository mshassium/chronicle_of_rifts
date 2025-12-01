import SpriteKit
import GameplayKit

/// Основная игровая сцена уровня
class GameScene: BaseGameScene {
    // MARK: - Properties

    /// Номер текущего уровня
    var levelNumber: Int = 1

    /// Собранные кристаллы на этом уровне
    private var crystalsCollected: Int = 0

    /// Найденные секреты на этом уровне
    private var secretsFound: Int = 0

    // MARK: - UI Elements

    private var healthLabel: SKLabelNode?
    private var crystalsLabel: SKLabelNode?
    private var levelLabel: SKLabelNode?
    private var pauseButton: SKSpriteNode?

    // MARK: - Lifecycle

    override func didMove(to view: SKView) {
        super.didMove(to: view)

        setupBackground()
        setupHUD()
        setupTestContent()

        GameManager.shared.changeState(to: .playing)
    }

    // MARK: - Setup

    private func setupBackground() {
        backgroundColor = SKColor(red: 0.15, green: 0.15, blue: 0.25, alpha: 1.0)

        // Простой градиентный фон
        let gradientNode = SKSpriteNode(color: SKColor(red: 0.1, green: 0.1, blue: 0.2, alpha: 1.0), size: size)
        gradientNode.position = CGPoint(x: size.width / 2, y: size.height / 2)
        gradientNode.zPosition = -99
        backgroundLayer.addChild(gradientNode)
    }

    private func setupHUD() {
        let safeArea = view?.safeAreaInsets ?? .zero
        let margin: CGFloat = 20

        // Здоровье (левый верхний угол)
        let healthContainer = SKNode()
        healthContainer.position = CGPoint(
            x: -size.width / 2 + margin + safeArea.left,
            y: size.height / 2 - margin - safeArea.top - 15
        )

        let heartIcon = SKLabelNode(text: "❤️")
        heartIcon.fontSize = 24
        heartIcon.position = CGPoint(x: 0, y: 0)
        healthContainer.addChild(heartIcon)

        healthLabel = SKLabelNode(text: "3")
        healthLabel?.fontName = "AvenirNext-Bold"
        healthLabel?.fontSize = 20
        healthLabel?.fontColor = .white
        healthLabel?.horizontalAlignmentMode = .left
        healthLabel?.position = CGPoint(x: 25, y: -5)
        healthContainer.addChild(healthLabel!)

        hudLayer.addChild(healthContainer)

        // Кристаллы
        let crystalsContainer = SKNode()
        crystalsContainer.position = CGPoint(
            x: -size.width / 2 + margin + safeArea.left,
            y: size.height / 2 - margin - safeArea.top - 50
        )

        let crystalIcon = SKLabelNode(text: "💎")
        crystalIcon.fontSize = 20
        crystalsContainer.addChild(crystalIcon)

        crystalsLabel = SKLabelNode(text: "0")
        crystalsLabel?.fontName = "AvenirNext-Bold"
        crystalsLabel?.fontSize = 18
        crystalsLabel?.fontColor = SKColor.cyan
        crystalsLabel?.horizontalAlignmentMode = .left
        crystalsLabel?.position = CGPoint(x: 25, y: -5)
        crystalsContainer.addChild(crystalsLabel!)

        hudLayer.addChild(crystalsContainer)

        // Название уровня (верхний центр)
        levelLabel = SKLabelNode(text: "Уровень \(levelNumber)")
        levelLabel?.fontName = "AvenirNext-Medium"
        levelLabel?.fontSize = 18
        levelLabel?.fontColor = SKColor(white: 0.8, alpha: 1.0)
        levelLabel?.position = CGPoint(x: 0, y: size.height / 2 - margin - safeArea.top - 15)
        hudLayer.addChild(levelLabel!)

        // Кнопка паузы (правый верхний угол)
        let pauseLabel = SKLabelNode(text: "⏸")
        pauseLabel.fontSize = 28
        pauseLabel.name = "pauseButton"
        pauseLabel.position = CGPoint(
            x: size.width / 2 - margin - safeArea.right - 20,
            y: size.height / 2 - margin - safeArea.top - 20
        )
        hudLayer.addChild(pauseLabel)
    }

    private func setupTestContent() {
        // Тестовый контент - платформа и информация
        let platform = SKShapeNode(rectOf: CGSize(width: 300, height: 30), cornerRadius: 5)
        platform.position = CGPoint(x: size.width / 2, y: 100)
        platform.fillColor = SKColor(red: 0.3, green: 0.25, blue: 0.2, alpha: 1.0)
        platform.strokeColor = SKColor(red: 0.4, green: 0.35, blue: 0.3, alpha: 1.0)
        platform.lineWidth = 2
        gameLayer.addChild(platform)

        // Инструкции
        let infoLabel = SKLabelNode(text: "Нажмите для теста камеры")
        infoLabel.fontName = "AvenirNext-Medium"
        infoLabel.fontSize = 16
        infoLabel.fontColor = SKColor(white: 0.6, alpha: 1.0)
        infoLabel.position = CGPoint(x: size.width / 2, y: size.height / 2 + 50)
        gameLayer.addChild(infoLabel)

        // Тестовая цель для камеры
        let target = SKShapeNode(circleOfRadius: 20)
        target.position = CGPoint(x: size.width / 2, y: size.height / 2)
        target.fillColor = SKColor(red: 0.8, green: 0.6, blue: 0.2, alpha: 1.0)
        target.strokeColor = .white
        target.lineWidth = 2
        target.name = "cameraTarget"
        gameLayer.addChild(target)

        // Настроить камеру на цель
        gameCamera.configure(
            target: target,
            bounds: CGRect(x: 0, y: 0, width: size.width * 2, height: size.height * 2),
            viewportSize: size
        )
        gameCamera.snapToTarget()
    }

    // MARK: - Update

    override func updateGame(deltaTime: TimeInterval) {
        // Обновление HUD
        let playerData = GameManager.shared.playerData
        healthLabel?.text = "\(playerData.health)"
        crystalsLabel?.text = "\(crystalsCollected)"
    }

    // MARK: - Touch Handling

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }

        // Проверка нажатия на HUD элементы
        let hudLocation = touch.location(in: hudLayer)
        let hudNodes = hudLayer.nodes(at: hudLocation)

        for node in hudNodes {
            if node.name == "pauseButton" {
                togglePause()
                return
            }
        }

        // Тестовое взаимодействие - перемещение цели камеры
        let gameLocation = touch.location(in: gameLayer)
        if let target = gameLayer.childNode(withName: "cameraTarget") {
            let moveAction = SKAction.move(to: gameLocation, duration: 0.5)
            moveAction.timingMode = .easeInEaseOut
            target.run(moveAction)

            // Тест тряски камеры
            gameCamera.shake(intensity: 5, duration: 0.2)
        }
    }

    // MARK: - Pause Menu

    private var pauseOverlay: SKNode?

    override func onGamePaused() {
        showPauseMenu()
    }

    override func onGameResumed() {
        hidePauseMenu()
    }

    private func showPauseMenu() {
        let overlay = SKNode()
        overlay.name = "pauseOverlay"
        overlay.zPosition = 50

        // Затемнение
        let dimmer = SKShapeNode(rectOf: size)
        dimmer.fillColor = SKColor(white: 0, alpha: 0.7)
        dimmer.strokeColor = .clear
        dimmer.position = .zero
        overlay.addChild(dimmer)

        // Заголовок
        let title = SKLabelNode(text: "ПАУЗА")
        title.fontName = "AvenirNext-Bold"
        title.fontSize = 48
        title.fontColor = .white
        title.position = CGPoint(x: 0, y: 80)
        overlay.addChild(title)

        // Кнопка продолжить
        let resumeButton = createButton(text: "Продолжить", name: "resumeButton", y: 0)
        overlay.addChild(resumeButton)

        // Кнопка рестарт
        let restartButton = createButton(text: "Заново", name: "restartButton", y: -60)
        overlay.addChild(restartButton)

        // Кнопка выход
        let exitButton = createButton(text: "В меню", name: "exitButton", y: -120)
        overlay.addChild(exitButton)

        hudLayer.addChild(overlay)
        pauseOverlay = overlay
    }

    private func hidePauseMenu() {
        pauseOverlay?.removeFromParent()
        pauseOverlay = nil
    }

    private func createButton(text: String, name: String, y: CGFloat) -> SKNode {
        let container = SKNode()
        container.name = name
        container.position = CGPoint(x: 0, y: y)

        let background = SKShapeNode(rectOf: CGSize(width: 200, height: 44), cornerRadius: 8)
        background.fillColor = SKColor(red: 0.2, green: 0.4, blue: 0.6, alpha: 1.0)
        background.strokeColor = SKColor.cyan
        background.lineWidth = 2
        container.addChild(background)

        let label = SKLabelNode(text: text)
        label.fontName = "AvenirNext-Medium"
        label.fontSize = 20
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        container.addChild(label)

        return container
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isGamePaused, let touch = touches.first else { return }

        let location = touch.location(in: hudLayer)
        let nodes = hudLayer.nodes(at: location)

        for node in nodes {
            switch node.name {
            case "resumeButton":
                resumeGame()
            case "restartButton":
                SceneManager.shared.restartCurrentLevel()
            case "exitButton":
                SceneManager.shared.presentMainMenu()
            default:
                // Проверяем родителя
                if let parent = node.parent, let parentName = parent.name {
                    switch parentName {
                    case "resumeButton":
                        resumeGame()
                    case "restartButton":
                        SceneManager.shared.restartCurrentLevel()
                    case "exitButton":
                        SceneManager.shared.presentMainMenu()
                    default:
                        break
                    }
                }
            }
        }
    }

    // MARK: - Game Events

    /// Добавить кристалл к счёту
    func collectCrystal() {
        crystalsCollected += 1
        sceneDelegate?.collectibleCollected("crystal")
    }

    /// Найти секрет
    func findSecret() {
        secretsFound += 1
        sceneDelegate?.collectibleCollected("secret")
    }

    /// Тестовая функция завершения уровня
    func testLevelComplete() {
        levelComplete(crystals: crystalsCollected, secrets: secretsFound)
    }

    /// Тестовая функция смерти игрока
    func testGameOver() {
        GameManager.shared.playerData.health = 0
        gameOver()
    }
}
