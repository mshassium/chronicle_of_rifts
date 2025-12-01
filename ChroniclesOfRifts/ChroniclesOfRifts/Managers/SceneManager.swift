import SpriteKit

/// Менеджер переходов между сценами
final class SceneManager {
    // MARK: - Singleton

    /// Единственный экземпляр SceneManager
    static let shared = SceneManager()

    // MARK: - Properties

    /// Текущий SKView для презентации сцен
    private weak var view: SKView?

    /// Текущая активная сцена
    private(set) weak var currentScene: SKScene?

    // MARK: - Initialization

    private init() {}

    // MARK: - Configuration

    /// Настроить менеджер с SKView
    /// - Parameter view: SKView для презентации сцен
    func configure(with view: SKView) {
        self.view = view
    }

    // MARK: - Transitions

    /// Стандартный fade-переход
    /// - Parameter duration: Длительность перехода
    /// - Returns: SKTransition
    static func fadeTransition(duration: TimeInterval = 0.5) -> SKTransition {
        let transition = SKTransition.fade(withDuration: duration)
        transition.pausesOutgoingScene = true
        transition.pausesIncomingScene = true
        return transition
    }

    /// Push-переход в указанном направлении
    /// - Parameters:
    ///   - direction: Направление перехода
    ///   - duration: Длительность перехода
    /// - Returns: SKTransition
    static func pushTransition(direction: SKTransitionDirection, duration: TimeInterval = 0.5) -> SKTransition {
        let transition = SKTransition.push(with: direction, duration: duration)
        transition.pausesOutgoingScene = true
        transition.pausesIncomingScene = true
        return transition
    }

    /// Crossfade-переход
    /// - Parameter duration: Длительность перехода
    /// - Returns: SKTransition
    static func crossfadeTransition(duration: TimeInterval = 0.3) -> SKTransition {
        let transition = SKTransition.crossFade(withDuration: duration)
        transition.pausesOutgoingScene = true
        transition.pausesIncomingScene = true
        return transition
    }

    // MARK: - Scene Presentation

    /// Презентовать сцену с опциональным переходом
    /// - Parameters:
    ///   - scene: Сцена для презентации
    ///   - transition: Переход (nil для мгновенной смены)
    func presentScene(_ scene: SKScene, transition: SKTransition? = nil) {
        guard let view = view else {
            print("SceneManager: SKView not configured")
            return
        }

        scene.scaleMode = .aspectFill

        if let transition = transition {
            view.presentScene(scene, transition: transition)
        } else {
            view.presentScene(scene)
        }

        currentScene = scene
    }

    /// Показать главное меню
    func presentMainMenu() {
        guard let view = view else { return }

        let menuScene = MainMenuScene(size: view.bounds.size)
        presentScene(menuScene, transition: Self.fadeTransition())

        GameManager.shared.changeState(to: .menu)
    }

    /// Загрузить и показать игровой уровень
    /// - Parameter levelNumber: Номер уровня
    func presentLevel(_ levelNumber: Int) {
        guard let view = view else { return }

        GameManager.shared.setCurrentLevel(levelNumber)

        let gameScene = GameScene(size: view.bounds.size)
        gameScene.levelNumber = levelNumber
        presentScene(gameScene, transition: Self.fadeTransition())

        GameManager.shared.changeState(to: .playing)
    }

    /// Показать экран Game Over
    func presentGameOver() {
        guard let view = view else { return }

        let gameOverScene = GameOverScene(size: view.bounds.size)
        presentScene(gameOverScene, transition: Self.fadeTransition(duration: 0.8))

        GameManager.shared.changeState(to: .gameOver)
    }

    /// Показать экран завершения уровня
    /// - Parameters:
    ///   - crystals: Собранные кристаллы
    ///   - secrets: Найденные секреты
    func presentLevelComplete(crystals: Int = 0, secrets: Int = 0) {
        guard let view = view else { return }

        GameManager.shared.completeLevelWith(crystals: crystals, secrets: secrets)

        let levelCompleteScene = LevelCompleteScene(size: view.bounds.size)
        levelCompleteScene.crystalsCollected = crystals
        levelCompleteScene.secretsFound = secrets
        presentScene(levelCompleteScene, transition: Self.fadeTransition())

        GameManager.shared.changeState(to: .levelComplete)
    }

    /// Показать выбор уровней
    func presentLevelSelect() {
        guard let view = view else { return }

        let levelSelectScene = LevelSelectScene(size: view.bounds.size)
        presentScene(levelSelectScene, transition: Self.pushTransition(direction: .left))
    }

    /// Перезапустить текущий уровень
    func restartCurrentLevel() {
        let currentLevel = GameManager.shared.currentLevel
        presentLevel(currentLevel)
    }

    /// Перейти к следующему уровню
    func presentNextLevel() {
        let nextLevel = GameManager.shared.currentLevel + 1
        if GameManager.shared.playerData.isLevelUnlocked(nextLevel) {
            presentLevel(nextLevel)
        } else {
            presentMainMenu()
        }
    }
}

// MARK: - Placeholder Scenes

/// Заглушка для MainMenuScene (будет реализована позже)
class MainMenuScene: SKScene {
    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.1, green: 0.1, blue: 0.2, alpha: 1.0)

        let title = SKLabelNode(text: "Хроники Разломов")
        title.fontName = "AvenirNext-Bold"
        title.fontSize = 48
        title.fontColor = .white
        title.position = CGPoint(x: size.width / 2, y: size.height * 0.7)
        addChild(title)

        let playLabel = SKLabelNode(text: "Нажмите для начала")
        playLabel.fontName = "AvenirNext-Medium"
        playLabel.fontSize = 24
        playLabel.fontColor = SKColor(white: 0.8, alpha: 1.0)
        playLabel.position = CGPoint(x: size.width / 2, y: size.height * 0.4)
        playLabel.name = "playButton"
        addChild(playLabel)

        let pulseAction = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.5, duration: 0.8),
            SKAction.fadeAlpha(to: 1.0, duration: 0.8)
        ])
        playLabel.run(SKAction.repeatForever(pulseAction))
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        SceneManager.shared.presentLevel(1)
    }
}

/// Заглушка для GameOverScene
class GameOverScene: SKScene {
    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.2, green: 0.05, blue: 0.05, alpha: 1.0)

        let label = SKLabelNode(text: "ПОРАЖЕНИЕ")
        label.fontName = "AvenirNext-Bold"
        label.fontSize = 64
        label.fontColor = SKColor(red: 0.8, green: 0.2, blue: 0.2, alpha: 1.0)
        label.position = CGPoint(x: size.width / 2, y: size.height * 0.6)
        addChild(label)

        let retryLabel = SKLabelNode(text: "Нажмите для повтора")
        retryLabel.fontName = "AvenirNext-Medium"
        retryLabel.fontSize = 24
        retryLabel.fontColor = .white
        retryLabel.position = CGPoint(x: size.width / 2, y: size.height * 0.35)
        addChild(retryLabel)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        SceneManager.shared.restartCurrentLevel()
    }
}

/// Заглушка для LevelCompleteScene
class LevelCompleteScene: SKScene {
    var crystalsCollected: Int = 0
    var secretsFound: Int = 0

    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.1, green: 0.15, blue: 0.1, alpha: 1.0)

        let label = SKLabelNode(text: "УРОВЕНЬ ПРОЙДЕН!")
        label.fontName = "AvenirNext-Bold"
        label.fontSize = 48
        label.fontColor = SKColor(red: 0.4, green: 0.8, blue: 0.4, alpha: 1.0)
        label.position = CGPoint(x: size.width / 2, y: size.height * 0.65)
        addChild(label)

        let statsLabel = SKLabelNode(text: "Кристаллы: \(crystalsCollected) | Секреты: \(secretsFound)")
        statsLabel.fontName = "AvenirNext-Medium"
        statsLabel.fontSize = 24
        statsLabel.fontColor = .white
        statsLabel.position = CGPoint(x: size.width / 2, y: size.height * 0.5)
        addChild(statsLabel)

        let nextLabel = SKLabelNode(text: "Нажмите для продолжения")
        nextLabel.fontName = "AvenirNext-Medium"
        nextLabel.fontSize = 24
        nextLabel.fontColor = SKColor(white: 0.7, alpha: 1.0)
        nextLabel.position = CGPoint(x: size.width / 2, y: size.height * 0.3)
        addChild(nextLabel)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        SceneManager.shared.presentNextLevel()
    }
}

/// Заглушка для LevelSelectScene
class LevelSelectScene: SKScene {
    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.1, green: 0.1, blue: 0.15, alpha: 1.0)

        let title = SKLabelNode(text: "ВЫБОР УРОВНЯ")
        title.fontName = "AvenirNext-Bold"
        title.fontSize = 36
        title.fontColor = .white
        title.position = CGPoint(x: size.width / 2, y: size.height * 0.85)
        addChild(title)

        // Сетка уровней 5x2
        let playerData = GameManager.shared.playerData
        let columns = 5
        let rows = 2
        let buttonSize: CGFloat = 60
        let spacing: CGFloat = 20

        let totalWidth = CGFloat(columns) * buttonSize + CGFloat(columns - 1) * spacing
        let startX = (size.width - totalWidth) / 2 + buttonSize / 2
        let startY = size.height * 0.55

        for row in 0..<rows {
            for col in 0..<columns {
                let levelNum = row * columns + col + 1
                let x = startX + CGFloat(col) * (buttonSize + spacing)
                let y = startY - CGFloat(row) * (buttonSize + spacing)

                let isUnlocked = playerData.isLevelUnlocked(levelNum)

                let button = SKShapeNode(rectOf: CGSize(width: buttonSize, height: buttonSize), cornerRadius: 8)
                button.position = CGPoint(x: x, y: y)
                button.fillColor = isUnlocked ? SKColor(red: 0.2, green: 0.4, blue: 0.6, alpha: 1.0) : SKColor.darkGray
                button.strokeColor = isUnlocked ? SKColor.cyan : SKColor.gray
                button.lineWidth = 2
                button.name = isUnlocked ? "level_\(levelNum)" : nil
                addChild(button)

                let label = SKLabelNode(text: isUnlocked ? "\(levelNum)" : "🔒")
                label.fontName = "AvenirNext-Bold"
                label.fontSize = 24
                label.fontColor = isUnlocked ? .white : .gray
                label.verticalAlignmentMode = .center
                label.position = CGPoint(x: x, y: y)
                addChild(label)
            }
        }

        let backLabel = SKLabelNode(text: "← Назад")
        backLabel.fontName = "AvenirNext-Medium"
        backLabel.fontSize = 20
        backLabel.fontColor = .white
        backLabel.position = CGPoint(x: 80, y: size.height - 40)
        backLabel.name = "back"
        addChild(backLabel)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let nodesAtPoint = nodes(at: location)

        for node in nodesAtPoint {
            if let name = node.name {
                if name == "back" {
                    SceneManager.shared.presentMainMenu()
                    return
                }
                if name.hasPrefix("level_"),
                   let levelNum = Int(name.replacingOccurrences(of: "level_", with: "")) {
                    SceneManager.shared.presentLevel(levelNum)
                    return
                }
            }
        }
    }
}
