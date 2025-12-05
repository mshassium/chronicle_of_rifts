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

    /// Текущий ID уровня
    private(set) var currentLevelId: Int = 1

    /// Статистика текущего уровня
    private var levelCrystals: Int = 0
    private var levelSecrets: Int = 0
    private var levelStartTime: Date?

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

    // MARK: - Level Transition System

    /// Загрузить уровень по ID (используется LevelExit)
    /// - Parameter levelId: ID уровня для загрузки
    func loadLevel(_ levelId: Int) {
        guard let view = view else { return }

        // Проверяем существование уровня
        let levelName = "level_\(levelId)"
        guard Bundle.main.url(forResource: levelName, withExtension: "json") != nil else {
            print("SceneManager: Уровень \(levelId) не найден")
            // Если уровень не существует - показываем экран победы или меню
            if levelId > 10 {
                presentVictoryScreen()
            } else {
                presentMainMenu()
            }
            return
        }

        // Сохраняем прогресс текущего уровня
        saveCurrentLevelProgress()

        // Обновляем текущий ID уровня
        currentLevelId = levelId

        // Сбрасываем статистику для нового уровня
        levelCrystals = 0
        levelSecrets = 0
        levelStartTime = Date()

        // Создаём новую GameScene
        let gameScene = GameScene(size: view.bounds.size)
        gameScene.levelNumber = levelId

        // Переход с анимацией
        let transition = Self.portalTransition()
        presentScene(gameScene, transition: transition)

        // Обновляем GameManager
        GameManager.shared.setCurrentLevel(levelId)
        GameManager.shared.changeState(to: .playing)
    }

    /// Показать экран завершения уровня со статистикой
    /// - Parameters:
    ///   - crystals: Собранные кристаллы
    ///   - secrets: Найденные секреты
    ///   - time: Время прохождения
    func showLevelCompleteScreen(crystals: Int, secrets: Int, time: TimeInterval) {
        guard let view = view else { return }

        // Сохраняем статистику
        levelCrystals = crystals
        levelSecrets = secrets

        // Обновляем GameManager
        GameManager.shared.completeLevelWith(crystals: crystals, secrets: secrets)

        // Создаём сцену завершения уровня
        let levelCompleteScene = LevelCompleteScene(size: view.bounds.size)
        levelCompleteScene.crystalsCollected = crystals
        levelCompleteScene.secretsFound = secrets
        levelCompleteScene.completionTime = time
        levelCompleteScene.currentLevelId = currentLevelId

        presentScene(levelCompleteScene, transition: Self.fadeTransition())
        GameManager.shared.changeState(to: .levelComplete)
    }

    /// Перейти к следующему уровню (используется из LevelCompleteScene)
    func proceedToNextLevel() {
        let nextLevelId = currentLevelId + 1
        loadLevel(nextLevelId)
    }

    /// Сохранить прогресс текущего уровня
    private func saveCurrentLevelProgress() {
        if let startTime = levelStartTime {
            let completionTime = Date().timeIntervalSince(startTime)
            GameManager.shared.completeLevelWith(crystals: levelCrystals, secrets: levelSecrets)
            _ = completionTime // Используется в completeLevelWith через GameManager.currentLevelTime()
        }
    }

    /// Обновить статистику уровня
    /// - Parameters:
    ///   - crystals: Кристаллы
    ///   - secrets: Секреты
    func updateLevelStats(crystals: Int, secrets: Int) {
        levelCrystals = crystals
        levelSecrets = secrets
    }

    /// Получить время прохождения текущего уровня
    func getCurrentLevelTime() -> TimeInterval {
        guard let startTime = levelStartTime else { return 0 }
        return Date().timeIntervalSince(startTime)
    }

    // MARK: - Special Transitions

    /// Переход через портал
    /// - Returns: SKTransition
    static func portalTransition() -> SKTransition {
        let transition = SKTransition.doorway(withDuration: 1.0)
        transition.pausesOutgoingScene = true
        transition.pausesIncomingScene = true
        return transition
    }

    /// Показать экран победы (после прохождения всех уровней)
    func presentVictoryScreen() {
        guard let view = view else { return }

        let victoryScene = VictoryScene(size: view.bounds.size)
        presentScene(victoryScene, transition: Self.fadeTransition(duration: 1.0))

        GameManager.shared.changeState(to: .levelComplete)
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

/// Сцена завершения уровня с детальной статистикой
class LevelCompleteScene: SKScene {
    var crystalsCollected: Int = 0
    var secretsFound: Int = 0
    var completionTime: TimeInterval = 0
    var currentLevelId: Int = 1

    // Максимальные значения для уровня (TODO: загружать из JSON)
    private var maxCrystals: Int = 10
    private var maxSecrets: Int = 3

    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.05, green: 0.1, blue: 0.15, alpha: 1.0)

        setupBackground()
        setupTitle()
        setupStats()
        setupButtons()

        // Анимация появления
        animateAppearance()
    }

    private func setupBackground() {
        // Градиентный фон
        let gradientNode = SKSpriteNode(color: SKColor(red: 0.1, green: 0.15, blue: 0.2, alpha: 1.0), size: size)
        gradientNode.position = CGPoint(x: size.width / 2, y: size.height / 2)
        gradientNode.zPosition = -10
        addChild(gradientNode)

        // Декоративные частицы
        if let particles = createCelebrationParticles() {
            particles.position = CGPoint(x: size.width / 2, y: size.height * 0.7)
            particles.zPosition = -5
            addChild(particles)
        }
    }

    private func setupTitle() {
        // Заголовок "УРОВЕНЬ ПРОЙДЕН"
        let titleLabel = SKLabelNode(text: "УРОВЕНЬ ПРОЙДЕН!")
        titleLabel.fontName = "AvenirNext-Bold"
        titleLabel.fontSize = 48
        titleLabel.fontColor = SKColor(red: 0.4, green: 0.9, blue: 0.5, alpha: 1.0)
        titleLabel.position = CGPoint(x: size.width / 2, y: size.height * 0.75)
        titleLabel.name = "title"
        titleLabel.alpha = 0
        addChild(titleLabel)

        // Свечение заголовка
        let glowLabel = SKLabelNode(text: "УРОВЕНЬ ПРОЙДЕН!")
        glowLabel.fontName = "AvenirNext-Bold"
        glowLabel.fontSize = 48
        glowLabel.fontColor = SKColor(red: 0.4, green: 0.9, blue: 0.5, alpha: 0.3)
        glowLabel.position = titleLabel.position
        glowLabel.zPosition = -1
        glowLabel.setScale(1.05)
        glowLabel.name = "titleGlow"
        glowLabel.alpha = 0
        addChild(glowLabel)

        // Название уровня
        let levelName = getLevelName(currentLevelId)
        let levelLabel = SKLabelNode(text: levelName)
        levelLabel.fontName = "AvenirNext-Medium"
        levelLabel.fontSize = 24
        levelLabel.fontColor = SKColor(white: 0.7, alpha: 1.0)
        levelLabel.position = CGPoint(x: size.width / 2, y: size.height * 0.68)
        levelLabel.name = "levelName"
        levelLabel.alpha = 0
        addChild(levelLabel)
    }

    private func setupStats() {
        let statsY = size.height * 0.52
        let spacing: CGFloat = 50

        // Кристаллы
        let crystalContainer = createStatRow(
            icon: "💎",
            label: "Кристаллы",
            value: "\(crystalsCollected)/\(maxCrystals)",
            y: statsY
        )
        crystalContainer.name = "crystalStats"
        crystalContainer.alpha = 0
        addChild(crystalContainer)

        // Секреты
        let secretContainer = createStatRow(
            icon: "🔮",
            label: "Секреты",
            value: "\(secretsFound)/\(maxSecrets)",
            y: statsY - spacing
        )
        secretContainer.name = "secretStats"
        secretContainer.alpha = 0
        addChild(secretContainer)

        // Время
        let timeString = formatTime(completionTime)
        let timeContainer = createStatRow(
            icon: "⏱",
            label: "Время",
            value: timeString,
            y: statsY - spacing * 2
        )
        timeContainer.name = "timeStats"
        timeContainer.alpha = 0
        addChild(timeContainer)
    }

    private func createStatRow(icon: String, label: String, value: String, y: CGFloat) -> SKNode {
        let container = SKNode()
        container.position = CGPoint(x: size.width / 2, y: y)

        // Иконка
        let iconLabel = SKLabelNode(text: icon)
        iconLabel.fontSize = 28
        iconLabel.position = CGPoint(x: -120, y: -5)
        container.addChild(iconLabel)

        // Название
        let nameLabel = SKLabelNode(text: label)
        nameLabel.fontName = "AvenirNext-Medium"
        nameLabel.fontSize = 22
        nameLabel.fontColor = .white
        nameLabel.horizontalAlignmentMode = .left
        nameLabel.position = CGPoint(x: -80, y: -5)
        container.addChild(nameLabel)

        // Значение
        let valueLabel = SKLabelNode(text: value)
        valueLabel.fontName = "AvenirNext-Bold"
        valueLabel.fontSize = 22
        valueLabel.fontColor = SKColor(red: 0.3, green: 0.8, blue: 1.0, alpha: 1.0)
        valueLabel.horizontalAlignmentMode = .right
        valueLabel.position = CGPoint(x: 120, y: -5)
        container.addChild(valueLabel)

        return container
    }

    private func setupButtons() {
        let buttonY = size.height * 0.2
        let buttonSpacing: CGFloat = 140

        // Кнопка "Следующий уровень"
        let nextButton = createButton(text: "Далее →", name: "nextButton")
        nextButton.position = CGPoint(x: size.width / 2, y: buttonY)
        nextButton.alpha = 0
        addChild(nextButton)

        // Кнопка "Повторить"
        let retryButton = createButton(text: "Заново", name: "retryButton", secondary: true)
        retryButton.position = CGPoint(x: size.width / 2 - buttonSpacing, y: buttonY)
        retryButton.alpha = 0
        addChild(retryButton)

        // Кнопка "Меню"
        let menuButton = createButton(text: "Меню", name: "menuButton", secondary: true)
        menuButton.position = CGPoint(x: size.width / 2 + buttonSpacing, y: buttonY)
        menuButton.alpha = 0
        addChild(menuButton)
    }

    private func createButton(text: String, name: String, secondary: Bool = false) -> SKNode {
        let container = SKNode()
        container.name = name

        let width: CGFloat = secondary ? 100 : 150
        let height: CGFloat = 44

        let background = SKShapeNode(rectOf: CGSize(width: width, height: height), cornerRadius: 8)
        background.fillColor = secondary ?
            SKColor(red: 0.2, green: 0.25, blue: 0.3, alpha: 1.0) :
            SKColor(red: 0.2, green: 0.5, blue: 0.3, alpha: 1.0)
        background.strokeColor = secondary ?
            SKColor(white: 0.4, alpha: 1.0) :
            SKColor(red: 0.4, green: 0.8, blue: 0.5, alpha: 1.0)
        background.lineWidth = 2
        container.addChild(background)

        let label = SKLabelNode(text: text)
        label.fontName = "AvenirNext-Medium"
        label.fontSize = 18
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        container.addChild(label)

        return container
    }

    private func animateAppearance() {
        let fadeIn = SKAction.fadeIn(withDuration: 0.4)
        let delay = SKAction.wait(forDuration: 0.15)

        // Заголовок
        childNode(withName: "title")?.run(SKAction.sequence([delay, fadeIn]))
        childNode(withName: "titleGlow")?.run(SKAction.sequence([delay, fadeIn]))
        childNode(withName: "levelName")?.run(SKAction.sequence([
            SKAction.wait(forDuration: 0.3),
            fadeIn
        ]))

        // Статистика
        childNode(withName: "crystalStats")?.run(SKAction.sequence([
            SKAction.wait(forDuration: 0.5),
            fadeIn
        ]))
        childNode(withName: "secretStats")?.run(SKAction.sequence([
            SKAction.wait(forDuration: 0.65),
            fadeIn
        ]))
        childNode(withName: "timeStats")?.run(SKAction.sequence([
            SKAction.wait(forDuration: 0.8),
            fadeIn
        ]))

        // Кнопки
        childNode(withName: "nextButton")?.run(SKAction.sequence([
            SKAction.wait(forDuration: 1.0),
            fadeIn
        ]))
        childNode(withName: "retryButton")?.run(SKAction.sequence([
            SKAction.wait(forDuration: 1.1),
            fadeIn
        ]))
        childNode(withName: "menuButton")?.run(SKAction.sequence([
            SKAction.wait(forDuration: 1.2),
            fadeIn
        ]))
    }

    private func createCelebrationParticles() -> SKEmitterNode? {
        let emitter = SKEmitterNode()

        let texture = SKTexture(imageNamed: "spark") // Fallback to shape if not found
        emitter.particleTexture = texture

        emitter.particleBirthRate = 5
        emitter.particleLifetime = 3
        emitter.particleSize = CGSize(width: 8, height: 8)
        emitter.particleScaleRange = 0.5

        emitter.emissionAngle = .pi / 2
        emitter.emissionAngleRange = .pi
        emitter.particleSpeed = 50
        emitter.particleSpeedRange = 30

        emitter.particlePositionRange = CGVector(dx: size.width * 0.8, dy: 20)

        emitter.particleColor = SKColor(red: 0.4, green: 0.8, blue: 0.5, alpha: 1.0)
        emitter.particleColorBlendFactor = 1.0
        emitter.particleAlpha = 0.6
        emitter.particleAlphaSpeed = -0.2

        emitter.particleBlendMode = .add

        return emitter
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private func getLevelName(_ levelId: Int) -> String {
        let names = [
            1: "Горящая деревня",
            2: "Мосты Бездны",
            3: "Корни Мира",
            4: "Катакомбы Аурелиона",
            5: "Штормовые Пики",
            6: "Море Осколков",
            7: "Врата Цитадели",
            8: "Сердце Цитадели",
            9: "Тронный Зал Бездны",
            10: "Пробуждение"
        ]
        return names[levelId] ?? "Уровень \(levelId)"
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let nodesAtPoint = nodes(at: location)

        for node in nodesAtPoint {
            if let name = node.name ?? node.parent?.name {
                switch name {
                case "nextButton":
                    SceneManager.shared.proceedToNextLevel()
                    return
                case "retryButton":
                    SceneManager.shared.restartCurrentLevel()
                    return
                case "menuButton":
                    SceneManager.shared.presentMainMenu()
                    return
                default:
                    break
                }
            }
        }
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

/// Сцена победы (после прохождения всех уровней)
class VictoryScene: SKScene {
    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.05, green: 0.05, blue: 0.1, alpha: 1.0)

        // Заголовок
        let titleLabel = SKLabelNode(text: "ПОБЕДА!")
        titleLabel.fontName = "AvenirNext-Bold"
        titleLabel.fontSize = 64
        titleLabel.fontColor = SKColor(red: 1.0, green: 0.85, blue: 0.3, alpha: 1.0)
        titleLabel.position = CGPoint(x: size.width / 2, y: size.height * 0.7)
        addChild(titleLabel)

        // Свечение заголовка
        let glowLabel = SKLabelNode(text: "ПОБЕДА!")
        glowLabel.fontName = "AvenirNext-Bold"
        glowLabel.fontSize = 64
        glowLabel.fontColor = SKColor(red: 1.0, green: 0.85, blue: 0.3, alpha: 0.4)
        glowLabel.position = titleLabel.position
        glowLabel.zPosition = -1
        glowLabel.setScale(1.1)
        addChild(glowLabel)

        // Подзаголовок
        let subtitleLabel = SKLabelNode(text: "Хроники Разломов пройдены!")
        subtitleLabel.fontName = "AvenirNext-Medium"
        subtitleLabel.fontSize = 28
        subtitleLabel.fontColor = .white
        subtitleLabel.position = CGPoint(x: size.width / 2, y: size.height * 0.58)
        addChild(subtitleLabel)

        // Текст благодарности
        let thanksLabel = SKLabelNode(text: "Спасибо за игру!")
        thanksLabel.fontName = "AvenirNext-Medium"
        thanksLabel.fontSize = 24
        thanksLabel.fontColor = SKColor(white: 0.7, alpha: 1.0)
        thanksLabel.position = CGPoint(x: size.width / 2, y: size.height * 0.45)
        addChild(thanksLabel)

        // Кнопка "В меню"
        let menuButton = SKNode()
        menuButton.name = "menuButton"
        menuButton.position = CGPoint(x: size.width / 2, y: size.height * 0.25)

        let buttonBg = SKShapeNode(rectOf: CGSize(width: 200, height: 50), cornerRadius: 10)
        buttonBg.fillColor = SKColor(red: 0.2, green: 0.3, blue: 0.5, alpha: 1.0)
        buttonBg.strokeColor = SKColor(red: 0.4, green: 0.6, blue: 0.9, alpha: 1.0)
        buttonBg.lineWidth = 2
        menuButton.addChild(buttonBg)

        let buttonLabel = SKLabelNode(text: "В главное меню")
        buttonLabel.fontName = "AvenirNext-Medium"
        buttonLabel.fontSize = 20
        buttonLabel.fontColor = .white
        buttonLabel.verticalAlignmentMode = .center
        menuButton.addChild(buttonLabel)

        addChild(menuButton)

        // Анимация пульсации свечения
        let pulse = SKAction.sequence([
            SKAction.scale(to: 1.15, duration: 1.0),
            SKAction.scale(to: 1.05, duration: 1.0)
        ])
        glowLabel.run(SKAction.repeatForever(pulse))
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let nodesAtPoint = nodes(at: location)

        for node in nodesAtPoint {
            if node.name == "menuButton" || node.parent?.name == "menuButton" {
                SceneManager.shared.presentMainMenu()
                return
            }
        }
    }
}
