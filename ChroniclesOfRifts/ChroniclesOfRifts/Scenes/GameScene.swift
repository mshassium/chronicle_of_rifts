import SpriteKit
import GameplayKit

/// Основная игровая сцена уровня
class GameScene: BaseGameScene, InputDelegate, DialogManagerDelegate {
    // MARK: - Entities

    /// Игрок
    private var player: Player!

    /// Враги на уровне
    private var enemies: [Enemy] = []

    /// Движущиеся платформы на уровне
    private var movingPlatforms: [MovingPlatform] = []

    /// Загрузчик уровней
    private let levelLoader = LevelLoader()

    // MARK: - Level

    /// Номер текущего уровня
    var levelNumber: Int = 0  // 0 = тестовый уровень

    /// Данные текущего уровня
    private var currentLevelData: LevelData?

    /// Собранные кристаллы на этом уровне
    private var crystalsCollected: Int = 0

    /// Найденные секреты на этом уровне
    private var secretsFound: Int = 0

    /// Позиция текущего чекпоинта
    private var currentCheckpoint: CGPoint?

    // MARK: - UI Elements

    private var healthLabel: SKLabelNode?
    private var crystalsLabel: SKLabelNode?
    private var levelLabel: SKLabelNode?
    private var pauseButton: SKSpriteNode?

    // MARK: - Dialog

    /// Диалоговое окно
    private var dialogBox: DialogBox?

    /// Флаг активного диалога
    private var isDialogActive: Bool = false

    // MARK: - Lifecycle

    override func didMove(to view: SKView) {
        super.didMove(to: view)

        // Подключаем делегат ввода
        inputManager.delegate = self

        // Настраиваем физику
        setupPhysics()

        setupBackground()
        setupHUD()

        // Загрузка уровня из JSON
        loadLevel(number: levelNumber)

        // Подписка на события попаданий
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleEntityHit(_:)),
            name: .entityHit,
            object: nil
        )

        // Подписка на сбор предметов
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleCollectibleCollected(_:)),
            name: .collectibleCollected,
            object: nil
        )

        // Подписка на смерть игрока
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handlePlayerDied),
            name: .playerDied,
            object: nil
        )

        // Подписка на завершение анимации смерти
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handlePlayerDeathAnimationComplete),
            name: .playerDeathAnimationComplete,
            object: nil
        )

        // Подписка на запрос тряски камеры
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleCameraShake(_:)),
            name: .requestCameraShake,
            object: nil
        )

        // Подписка на активацию чекпоинта
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleCheckpointActivated(_:)),
            name: .checkpointActivated,
            object: nil
        )

        // Подписка на события диалогов
        DialogManager.shared.delegate = self

        // Создаём диалоговое окно
        setupDialogBox()

        GameManager.shared.changeState(to: .playing)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Setup

    private func setupPhysics() {
        physicsWorld.gravity = CGVector(dx: 0, dy: -9.8)
        physicsWorld.contactDelegate = self
    }

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

    /// Настройка диалогового окна
    private func setupDialogBox() {
        dialogBox = DialogBox(size: size)
        hudLayer.addChild(dialogBox!)
    }

    // MARK: - Dialog Methods

    /// Показать диалоговое окно
    func showDialogBox() {
        dialogBox?.show(animated: true)
    }

    /// Скрыть диалоговое окно
    func hideDialogBox() {
        dialogBox?.hide(animated: true)
    }

    /// Запустить диалог по ID
    func startDialog(id: String) {
        guard !isDialogActive else { return }

        isDialogActive = true

        // Приостанавливаем игру (но не показываем меню паузы)
        pauseGameForDialog()

        // Показываем диалоговое окно
        showDialogBox()

        // Запускаем диалог
        DialogManager.shared.startDialog(id: id)
    }

    /// Пауза игры для диалога (без показа меню паузы)
    private func pauseGameForDialog() {
        guard !isGamePaused else { return }

        gameLayer.isPaused = true
        physicsWorld.speed = 0
    }

    /// Возобновить игру после диалога
    private func resumeGameFromDialog() {
        guard isDialogActive else { return }

        isDialogActive = false
        gameLayer.isPaused = false
        physicsWorld.speed = 1
    }

    // MARK: - DialogManagerDelegate

    func dialogDidStart(dialogId: String) {
        print("GameScene: Dialog '\(dialogId)' started")
    }

    func dialogDidEnd(dialogId: String) {
        print("GameScene: Dialog '\(dialogId)' ended")

        // Скрываем диалоговое окно
        hideDialogBox()

        // Возобновляем игру
        resumeGameFromDialog()
    }

    func dialogLineChanged(line: DialogLine, index: Int, total: Int) {
        // Отображаем реплику в диалоговом окне
        dialogBox?.displayLine(line)
    }

    /// Загрузить уровень по номеру
    /// - Parameter number: Номер уровня (0 = тестовый)
    private func loadLevel(number: Int) {
        // Очищаем менеджер переключателей и дверей от предыдущего уровня
        SwitchDoorManager.shared.clearAll()

        // Определяем имя файла
        let levelName = number == 0 ? "level_test" : "level_\(number)"

        guard let url = Bundle.main.url(forResource: levelName, withExtension: "json") else {
            print("GameScene: Не удалось найти \(levelName).json")
            return
        }

        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let levelData = try decoder.decode(LevelData.self, from: data)

            currentLevelData = levelData
            let tileSize = levelData.tileSize

            // Границы камеры (в пикселях)
            let levelBounds = levelData.bounds.toPixels(tileSize: tileSize)

            // Создаём уровень через LevelLoader
            levelLoader.buildLevel(from: levelData, in: gameLayer)

            // Получаем движущиеся платформы
            movingPlatforms = levelLoader.getMovingPlatforms()

            // Запускаем движение платформ
            for platform in movingPlatforms {
                platform.moveToNextWaypoint()
            }

            // Создаём игрока в точке спавна
            let spawnPos = levelData.playerSpawn.toPixels(tileSize: tileSize)
            setupPlayer(at: spawnPos, levelBounds: levelBounds)

            // Спавним врагов через EnemyFactory
            spawnEnemies(from: levelData)

            // Обновляем HUD
            levelLabel?.text = levelData.name

            print("GameScene: Уровень '\(levelData.name)' загружен")

        } catch {
            print("GameScene: Ошибка загрузки уровня - \(error)")
        }
    }

    /// Спавнит врагов из данных уровня
    /// - Parameter levelData: Данные уровня
    private func spawnEnemies(from levelData: LevelData) {
        // Очищаем старых врагов
        enemies.forEach { $0.removeFromParent() }
        enemies.removeAll()

        // Спавним новых врагов через LevelLoader
        enemies = levelLoader.spawnEnemies(in: gameLayer, from: levelData)

        // Устанавливаем targetPlayer для всех врагов
        for enemy in enemies {
            enemy.targetPlayer = player
        }

        print("GameScene: Создано \(enemies.count) врагов, targetPlayer установлен")
    }

    /// Настройка игрока в заданной позиции
    private func setupPlayer(at position: CGPoint, levelBounds: CGRect) {
        player = Player()
        player.position = position
        gameLayer.addChild(player)

        // Камера следит за игроком
        gameCamera.configure(
            target: player,
            bounds: levelBounds,
            viewportSize: size
        )
        gameCamera.snapToTarget()
    }

    // MARK: - Update

    override func updateGame(deltaTime: TimeInterval) {
        // Обновление игрока
        player.update(deltaTime: deltaTime)

        // Обновление врагов
        updateEnemies(deltaTime: deltaTime)

        // Обновление движущихся платформ и перемещение игрока с ними
        updatePlayerOnPlatforms()

        // Обновление HUD
        healthLabel?.text = "\(player.currentHealth)"
        crystalsLabel?.text = "\(crystalsCollected)"
    }

    /// Проверяет, стоит ли игрок на движущейся платформе, и перемещает его вместе с ней
    private func updatePlayerOnPlatforms() {
        // Находим платформу, на которой стоит игрок
        let playerFeetY = player.position.y - player.size.height / 2
        let playerLeft = player.position.x - player.size.width / 2
        let playerRight = player.position.x + player.size.width / 2

        // Проверяем вертикальную скорость игрока (если падает быстро - не на платформе)
        let playerVelocityY = player.physicsBody?.velocity.dy ?? 0
        let isPlayerFalling = playerVelocityY < -50

        for platform in movingPlatforms {
            let platformTop = platform.position.y + platform.size.height / 2
            let platformLeft = platform.position.x - platform.size.width / 2
            let platformRight = platform.position.x + platform.size.width / 2

            // Проверяем, стоит ли игрок на этой платформе
            let isOnTop = abs(playerFeetY - platformTop) < 10
            let isWithinX = playerRight > platformLeft && playerLeft < platformRight

            if isOnTop && isWithinX && !isPlayerFalling {
                // Применяем дельту движения платформы к игроку
                let delta = platform.calculateMovementDelta()
                player.position.x += delta.dx
                player.position.y += delta.dy
            }

            // Обновляем previousPosition после проверки
            platform.updatePreviousPosition()
        }
    }

    /// Обновляет всех врагов и удаляет мёртвых
    private func updateEnemies(deltaTime: TimeInterval) {
        // Удаляем мёртвых врагов из массива
        enemies.removeAll { $0.parent == nil || $0.currentState == .dead }

        // Обновляем живых врагов
        for enemy in enemies {
            enemy.update(deltaTime: deltaTime)
        }
    }

    // MARK: - InputDelegate

    func joystickMoved(direction: CGVector) {
        player.setInputDirection(direction.dx)
    }

    func jumpPressed() {
        player.jump()
    }

    func jumpReleased() {
        player.releaseJump()
    }

    func attackPressed() {
        player.attack()
    }

    func pausePressed() {
        togglePause()
    }

    // MARK: - Touch Handling

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Обработка касания во время диалога
        if isDialogActive {
            handleDialogTouch()
            return
        }

        // Передаём касания в базовый класс для обработки контролов
        super.touchesBegan(touches, with: event)

        guard let touch = touches.first else { return }

        // Проверка нажатия на HUD элементы (кроме контролов)
        let hudLocation = touch.location(in: hudLayer)
        let hudNodes = hudLayer.nodes(at: hudLocation)

        for node in hudNodes {
            if node.name == "pauseButton" {
                togglePause()
                return
            }
        }
    }

    /// Обработка касания во время диалога
    private func handleDialogTouch() {
        guard let dialogBox = dialogBox else { return }

        if dialogBox.isTyping {
            // Если текст ещё печатается - показать весь текст
            dialogBox.skipTypewriter()
        } else {
            // Если текст полностью показан - следующая реплика
            DialogManager.shared.advanceDialog()
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Передаём касания в базовый класс для обработки контролов (джойстик)
        super.touchesMoved(touches, with: event)
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
        // Передаём касания в базовый класс для обработки контролов
        super.touchesEnded(touches, with: event)

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

    /// Респавн игрока на чекпоинте
    func respawnPlayer() {
        let tileSize = currentLevelData?.tileSize ?? 32

        // Приоритет: 1) GameManager checkpoint, 2) локальный checkpoint, 3) playerSpawn из уровня
        let checkpointFromManager = GameManager.shared.getCheckpointPosition(for: levelNumber)
        let spawnPosition = checkpointFromManager ?? currentCheckpoint ?? currentLevelData?.playerSpawn.toPixels(tileSize: tileSize) ?? CGPoint(x: size.width / 2, y: 200)
        let levelBounds = currentLevelData?.bounds.toPixels(tileSize: tileSize) ?? CGRect(x: 0, y: 0, width: size.width * 2, height: size.height * 2)

        player.removeFromParent()
        player = Player()
        player.position = spawnPosition
        gameLayer.addChild(player)

        // Восстанавливаем физику
        player.physicsBody?.isDynamic = true

        // Устанавливаем targetPlayer для всех врагов
        for enemy in enemies {
            enemy.targetPlayer = player
        }

        // Камера следит за игроком
        gameCamera.configure(
            target: player,
            bounds: levelBounds,
            viewportSize: size
        )
        gameCamera.snapToTarget()
    }

    // MARK: - Collectible Handling

    @objc private func handleCollectibleCollected(_ notification: Notification) {
        guard let collectible = notification.object as? Collectible,
              let type = notification.userInfo?["type"] as? CollectibleType else { return }

        switch type {
        case .manaCrystal:
            crystalsCollected += 1
            // HUD обновляется в updateGame

        case .healthPickup:
            player.heal(1)

        case .chroniclePage:
            if let id = notification.userInfo?["id"] as? String {
                GameManager.shared.collectPage(id)
            }

        case .checkpoint:
            currentCheckpoint = collectible.position
            collectible.activateCheckpoint()
            showCheckpointMessage()
        }
    }

    // MARK: - Hit Handling

    @objc private func handleEntityHit(_ notification: Notification) {
        guard let target = notification.object as? SKNode,
              let hitInfo = notification.userInfo?["hitInfo"] as? HitInfo else { return }

        // Если цель - враг, нанести урон
        // TODO: Добавить обработку Enemy когда будет создан класс Enemy
        // if let enemy = target as? Enemy {
        //     enemy.takeDamage(hitInfo.damage, knockback: hitInfo.knockbackForce * hitInfo.knockbackDirection)
        // }

        // Для тестирования: показываем визуальный эффект урона на любом объекте
        showDamageEffect(on: target, damage: hitInfo.damage)
    }

    @objc private func handlePlayerDied() {
        // Сразу при смерти - останавливаем игру для игрока
        // Анимация смерти проигрывается в Player
    }

    @objc private func handlePlayerDeathAnimationComplete() {
        // Задержка перед game over
        run(SKAction.sequence([
            SKAction.wait(forDuration: 1.0),
            SKAction.run { [weak self] in
                self?.gameOver()
            }
        ]))
    }

    @objc private func handleCameraShake(_ notification: Notification) {
        guard let intensity = notification.userInfo?["intensity"] as? CGFloat,
              let duration = notification.userInfo?["duration"] as? TimeInterval else { return }

        gameCamera.shake(intensity: intensity, duration: duration)
    }

    @objc private func handleCheckpointActivated(_ notification: Notification) {
        guard let checkpoint = notification.object as? Checkpoint else { return }

        // Обновляем локальную позицию чекпоинта
        currentCheckpoint = checkpoint.getRespawnPosition()

        // Показываем сообщение
        showCheckpointMessage()
    }

    /// Показать сообщение "CHECKPOINT" на экране
    private func showCheckpointMessage() {
        // Создаём текст
        let messageLabel = SKLabelNode(text: "CHECKPOINT")
        messageLabel.fontName = "AvenirNext-Bold"
        messageLabel.fontSize = 36
        messageLabel.fontColor = SKColor(red: 0.3, green: 0.9, blue: 0.4, alpha: 1.0)
        messageLabel.position = CGPoint(x: 0, y: 0)
        messageLabel.zPosition = 200
        messageLabel.alpha = 0

        // Свечение текста
        let glowLabel = SKLabelNode(text: "CHECKPOINT")
        glowLabel.fontName = "AvenirNext-Bold"
        glowLabel.fontSize = 36
        glowLabel.fontColor = SKColor(red: 0.3, green: 0.9, blue: 0.4, alpha: 0.5)
        glowLabel.position = .zero
        glowLabel.zPosition = -1
        glowLabel.setScale(1.1)
        messageLabel.addChild(glowLabel)

        hudLayer.addChild(messageLabel)

        // Анимация: появление, подъём вверх, затухание
        let appear = SKAction.fadeIn(withDuration: 0.2)
        let wait = SKAction.wait(forDuration: 0.8)
        let moveUp = SKAction.moveBy(x: 0, y: 50, duration: 0.5)
        let fadeOut = SKAction.fadeOut(withDuration: 0.5)
        let moveAndFade = SKAction.group([moveUp, fadeOut])
        let remove = SKAction.removeFromParent()

        let sequence = SKAction.sequence([appear, wait, moveAndFade, remove])
        messageLabel.run(sequence)
    }

    // MARK: - Dialog Trigger Handling

    /// Обработка триггера диалога
    private func handleDialogTrigger(_ triggerNode: SKNode) {
        guard let userData = triggerNode.userData else { return }

        // Проверяем, не был ли триггер уже активирован (для oneTime триггеров)
        let oneTime = userData["oneTime"] as? Bool ?? false
        let alreadyTriggered = userData["triggered"] as? Bool ?? false

        if oneTime && alreadyTriggered {
            return
        }

        // Получаем dialogId
        guard let dialogId = userData["dialogId"] as? String, !dialogId.isEmpty else {
            print("GameScene: Dialog trigger has no dialogId")
            return
        }

        // Отмечаем триггер как активированный
        triggerNode.userData?["triggered"] = true

        // Запускаем диалог
        startDialog(id: dialogId)
    }

    /// Показать визуальный эффект урона
    private func showDamageEffect(on target: SKNode, damage: Int) {
        // Красная вспышка на цели
        let flashRed = SKAction.sequence([
            SKAction.colorize(with: .red, colorBlendFactor: 1.0, duration: 0.05),
            SKAction.colorize(withColorBlendFactor: 0.0, duration: 0.1)
        ])

        if let sprite = target as? SKSpriteNode {
            sprite.run(flashRed)
        }

        // Всплывающий текст урона
        let damageLabel = SKLabelNode(text: "-\(damage)")
        damageLabel.fontName = "AvenirNext-Bold"
        damageLabel.fontSize = 20
        damageLabel.fontColor = .red
        damageLabel.position = target.position
        damageLabel.position.y += 40
        damageLabel.zPosition = 100
        gameLayer.addChild(damageLabel)

        let floatUp = SKAction.moveBy(x: 0, y: 30, duration: 0.5)
        let fadeOut = SKAction.fadeOut(withDuration: 0.5)
        let remove = SKAction.removeFromParent()
        damageLabel.run(SKAction.sequence([SKAction.group([floatUp, fadeOut]), remove]))
    }
}

// MARK: - SKPhysicsContactDelegate

extension GameScene: SKPhysicsContactDelegate {
    func didBegin(_ contact: SKPhysicsContact) {
        let (bodyA, bodyB) = (contact.bodyA, contact.bodyB)
        let collision = bodyA.categoryBitMask | bodyB.categoryBitMask

        // Attack hitbox + Enemy
        if collision == PhysicsCategory.playerAttack | PhysicsCategory.enemy {
            if bodyA.categoryBitMask == PhysicsCategory.playerAttack {
                if let attack = bodyA.node?.userData?["attack"] as? MeleeAttack,
                   let enemy = bodyB.node {
                    _ = attack.processHit(on: enemy)
                }
            } else {
                if let attack = bodyB.node?.userData?["attack"] as? MeleeAttack,
                   let enemy = bodyA.node {
                    _ = attack.processHit(on: enemy)
                }
            }
            return
        }

        // Attack hitbox + Switch (attack activation)
        if collision == PhysicsCategory.playerAttack | PhysicsCategory.trigger {
            if let gameSwitch = getNode(from: contact, withCategory: PhysicsCategory.trigger) as? GameSwitch {
                if gameSwitch.activationType == .attack {
                    gameSwitch.activate()
                }
            }
            return
        }

        // Player + Switch (step activation) or LevelExit or Dialog Trigger
        if collision == PhysicsCategory.player | PhysicsCategory.trigger {
            // Проверяем LevelExit
            if let levelExit = getNode(from: contact, withCategory: PhysicsCategory.trigger) as? LevelExit {
                levelExit.enter(player: player)
                return
            }

            // Проверяем GameSwitch
            if let gameSwitch = getNode(from: contact, withCategory: PhysicsCategory.trigger) as? GameSwitch {
                if gameSwitch.activationType == .step {
                    gameSwitch.activate()
                }
            }

            // Проверяем Dialog Trigger
            if let triggerNode = getNode(from: contact, withCategory: PhysicsCategory.trigger),
               let userData = triggerNode.userData,
               let typeString = userData["type"] as? String,
               typeString == "dialog" {
                handleDialogTrigger(triggerNode)
                return
            }
            // Продолжаем обработку - могут быть другие триггеры
        }

        // Player + Enemy
        if collision == PhysicsCategory.player | PhysicsCategory.enemy {
            if let enemyBody = bodyA.categoryBitMask == PhysicsCategory.enemy ? bodyA : bodyB as SKPhysicsBody?,
               let enemy = enemyBody.node {
                handlePlayerEnemyContact(player: player, enemy: enemy)
            }
            return
        }

        // Player + EnemyProjectile
        if collision == PhysicsCategory.player | PhysicsCategory.enemyProjectile {
            if let projectile = getNode(from: contact, withCategory: PhysicsCategory.enemyProjectile) {
                handlePlayerProjectileContact(player: player, projectile: projectile)
            }
            return
        }

        // Player + Hazard
        if collision == PhysicsCategory.player | PhysicsCategory.hazard {
            if let hazard = getNode(from: contact, withCategory: PhysicsCategory.hazard) as? Hazard {
                hazard.applyDamage(to: player)
            } else {
                // Fallback для старых hazard-нод
                handlePlayerHazardContact(player: player)
            }
            return
        }

        // Player + Collectible
        if collision == PhysicsCategory.player | PhysicsCategory.collectible {
            // Проверяем, является ли это Checkpoint
            if let checkpoint = getNode(from: contact, withCategory: PhysicsCategory.collectible) as? Checkpoint {
                checkpoint.activate(by: player)
                return
            }
            // Иначе это обычный Collectible
            if let collectible = getNode(from: contact, withCategory: PhysicsCategory.collectible) as? Collectible {
                collectible.collect(by: player)
            }
            return
        }

        // Проверяем контакт игрока с землёй
        if collision == PhysicsCategory.player | PhysicsCategory.ground {
            // Определяем какое тело - игрок
            let playerBody = bodyA.categoryBitMask == PhysicsCategory.player ? bodyA : bodyB
            let groundBody = bodyA.categoryBitMask == PhysicsCategory.ground ? bodyA : bodyB

            // Проверяем что игрок находится сверху платформы
            if let playerNode = playerBody.node, let groundNode = groundBody.node {
                let playerBottom = playerNode.position.y - PlayerConfig.colliderSize.height / 2
                let groundHeight = (groundNode as? SKSpriteNode)?.size.height ?? 32
                let groundTop = groundNode.position.y + groundHeight / 2

                // Если игрок выше или на уровне верха платформы - он приземлился
                if playerBottom >= groundTop - 10 {
                    player.setGrounded(true)

                    // Если это разрушающаяся платформа - активируем её
                    if let crumblingPlatform = groundNode as? CrumblingPlatform {
                        crumblingPlatform.trigger()
                    }
                }
            }
        }
    }

    /// Обрабатывает контакт игрока с врагом
    private func handlePlayerEnemyContact(player: Player, enemy: SKNode) {
        // Проверка: игрок прыгнул на врага сверху?
        let playerBottom = player.position.y - player.size.height / 2
        let enemyTop = enemy.position.y + (enemy.frame.height / 2)
        let isStompingEnemy = playerBottom > enemyTop - 10 && player.velocity.dy < 0

        if let enemyEntity = enemy as? Enemy {
            if isStompingEnemy {
                // Stomp атака - враг обрабатывает это сам
                enemyEntity.handleStomp(by: player)
            } else {
                // Контактный урон игроку
                enemyEntity.dealContactDamage(to: player)
            }
        } else {
            // Fallback для placeholder врагов
            if isStompingEnemy {
                player.bounce()
            } else {
                let knockbackDir: CGFloat = player.position.x < enemy.position.x ? -1 : 1
                player.takeDamage(1, knockbackDirection: knockbackDir)
            }
        }
    }

    /// Обрабатывает контакт игрока с опасностью (шипы, лава и т.д.)
    private func handlePlayerHazardContact(player: Player) {
        // Hazard наносит урон без отбрасывания
        player.takeDamage(1)
    }

    /// Обрабатывает контакт игрока со снарядом врага
    private func handlePlayerProjectileContact(player: Player, projectile: SKNode) {
        // Наносим урон игроку
        let knockbackDirection: CGFloat = player.position.x < projectile.position.x ? -1 : 1
        player.takeDamage(1, knockbackDirection: knockbackDirection)

        // Удаляем снаряд
        projectile.removeFromParent()
    }

    /// Хелпер для получения ноды из контакта по категории
    private func getNode(from contact: SKPhysicsContact, withCategory category: UInt32) -> SKNode? {
        if contact.bodyA.categoryBitMask == category {
            return contact.bodyA.node
        } else if contact.bodyB.categoryBitMask == category {
            return contact.bodyB.node
        }
        return nil
    }

    func didEnd(_ contact: SKPhysicsContact) {
        let collision = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask

        // Проверяем окончание контакта игрока с землёй
        if collision == PhysicsCategory.player | PhysicsCategory.ground {
            // Небольшая задержка перед setGrounded(false) для стабильности
            // (coyote time в Player уже обрабатывает это)
            player.setGrounded(false)
        }

        // Окончание контакта с опасностью - остановить периодический урон
        if collision == PhysicsCategory.player | PhysicsCategory.hazard {
            if let hazard = getNode(from: contact, withCategory: PhysicsCategory.hazard) as? Hazard {
                hazard.stopPeriodicDamage()
            }
        }
    }
}
