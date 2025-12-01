import SpriteKit
import GameplayKit

/// Основная игровая сцена уровня
class GameScene: BaseGameScene, InputDelegate {
    // MARK: - Entities

    /// Игрок
    private var player: Player!

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

    /// Загрузить уровень по номеру
    /// - Parameter number: Номер уровня (0 = тестовый)
    private func loadLevel(number: Int) {
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

            // Создаём игрока в точке спавна
            let spawnPos = levelData.playerSpawn.toPixels(tileSize: tileSize)
            setupPlayer(at: spawnPos, levelBounds: levelBounds)

            // Обновляем HUD
            levelLabel?.text = levelData.name

            print("GameScene: Уровень '\(levelData.name)' загружен")

        } catch {
            print("GameScene: Ошибка загрузки уровня - \(error)")
        }
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

        // Обновление HUD
        healthLabel?.text = "\(player.currentHealth)"
        crystalsLabel?.text = "\(crystalsCollected)"
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

    /// Респавн игрока на чекпоинте
    func respawnPlayer() {
        let tileSize = currentLevelData?.tileSize ?? 32
        let spawnPosition = currentCheckpoint ?? currentLevelData?.playerSpawn.toPixels(tileSize: tileSize) ?? CGPoint(x: size.width / 2, y: 200)
        let levelBounds = currentLevelData?.bounds.toPixels(tileSize: tileSize) ?? CGRect(x: 0, y: 0, width: size.width * 2, height: size.height * 2)

        player.removeFromParent()
        player = Player()
        player.position = spawnPosition
        gameLayer.addChild(player)

        // Восстанавливаем физику
        player.physicsBody?.isDynamic = true

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
            // TODO: Показать уведомление "Checkpoint!"
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

        // Player + Enemy
        if collision == PhysicsCategory.player | PhysicsCategory.enemy {
            if let enemyBody = bodyA.categoryBitMask == PhysicsCategory.enemy ? bodyA : bodyB as SKPhysicsBody?,
               let enemy = enemyBody.node {
                handlePlayerEnemyContact(player: player, enemy: enemy)
            }
            return
        }

        // Player + Hazard
        if collision == PhysicsCategory.player | PhysicsCategory.hazard {
            handlePlayerHazardContact(player: player)
            return
        }

        // Player + Collectible
        if collision == PhysicsCategory.player | PhysicsCategory.collectible {
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

        if isStompingEnemy {
            // Урон врагу
            // TODO: if let enemyEntity = enemy as? Enemy { enemyEntity.takeDamage(1, knockback: 0) }

            // Отскок игрока
            player.bounce()
        } else {
            // Урон игроку
            let knockbackDir: CGFloat = player.position.x < enemy.position.x ? -1 : 1
            player.takeDamage(1, knockbackDirection: knockbackDir)
        }
    }

    /// Обрабатывает контакт игрока с опасностью (шипы, лава и т.д.)
    private func handlePlayerHazardContact(player: Player) {
        // Hazard наносит урон без отбрасывания
        player.takeDamage(1)
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
    }
}
