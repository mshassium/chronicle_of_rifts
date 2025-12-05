import SpriteKit

class LevelLoader {

    // MARK: - Properties

    /// Хранит созданные движущиеся платформы для доступа из сцены
    private(set) var createdMovingPlatforms: [MovingPlatform] = []

    // MARK: - Node Names

    struct NodeNames {
        static let platformsContainer = "platforms"
        static let enemiesContainer = "enemies"
        static let collectiblesContainer = "collectibles"
        static let triggersContainer = "triggers"
        static let interactablesContainer = "interactables"
        static let backgroundContainer = "background"
        static let hazardsContainer = "hazards"
        static let darkZonesContainer = "darkZones"
        static let torchesContainer = "torches"
        static let fallingGatesContainer = "fallingGates"
        static let iciclesContainer = "icicles"
        static let avalanchesContainer = "avalanches"
    }

    // MARK: - Loading

    func loadLevel(_ number: Int) -> LevelData? {
        guard let url = Bundle.main.url(forResource: "level_\(number)", withExtension: "json") else {
            print("LevelLoader: Could not find level_\(number).json")
            return nil
        }

        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let levelData = try decoder.decode(LevelData.self, from: data)
            return levelData
        } catch {
            print("LevelLoader: Failed to decode level_\(number).json - \(error)")
            return nil
        }
    }

    // MARK: - Building

    func buildLevel(from data: LevelData, in parentNode: SKNode) {
        let tileSize = data.tileSize

        // Очищаем список движущихся платформ от предыдущего уровня
        createdMovingPlatforms.removeAll()

        // Create containers
        let platformsContainer = SKNode()
        platformsContainer.name = NodeNames.platformsContainer
        parentNode.addChild(platformsContainer)

        let enemiesContainer = SKNode()
        enemiesContainer.name = NodeNames.enemiesContainer
        parentNode.addChild(enemiesContainer)

        let collectiblesContainer = SKNode()
        collectiblesContainer.name = NodeNames.collectiblesContainer
        parentNode.addChild(collectiblesContainer)

        let triggersContainer = SKNode()
        triggersContainer.name = NodeNames.triggersContainer
        parentNode.addChild(triggersContainer)

        let interactablesContainer = SKNode()
        interactablesContainer.name = NodeNames.interactablesContainer
        parentNode.addChild(interactablesContainer)

        let backgroundContainer = SKNode()
        backgroundContainer.name = NodeNames.backgroundContainer
        parentNode.addChild(backgroundContainer)

        let hazardsContainer = SKNode()
        hazardsContainer.name = NodeNames.hazardsContainer
        parentNode.addChild(hazardsContainer)

        let darkZonesContainer = SKNode()
        darkZonesContainer.name = NodeNames.darkZonesContainer
        parentNode.addChild(darkZonesContainer)

        let torchesContainer = SKNode()
        torchesContainer.name = NodeNames.torchesContainer
        parentNode.addChild(torchesContainer)

        let fallingGatesContainer = SKNode()
        fallingGatesContainer.name = NodeNames.fallingGatesContainer
        parentNode.addChild(fallingGatesContainer)

        let iciclesContainer = SKNode()
        iciclesContainer.name = NodeNames.iciclesContainer
        parentNode.addChild(iciclesContainer)

        let avalanchesContainer = SKNode()
        avalanchesContainer.name = NodeNames.avalanchesContainer
        parentNode.addChild(avalanchesContainer)

        // Build background layers (lowest z)
        for layerData in data.backgroundLayers {
            let layer = createBackgroundLayer(from: layerData, levelSize: CGSize(
                width: CGFloat(data.width) * tileSize,
                height: CGFloat(data.height) * tileSize
            ))
            backgroundContainer.addChild(layer)
        }

        // Build platforms
        for platformData in data.platforms {
            let platform = createPlatform(from: platformData, tileSize: tileSize)
            platformsContainer.addChild(platform)
        }

        // Build enemies (stubs)
        for enemyData in data.enemies {
            let enemy = createEnemy(from: enemyData, tileSize: tileSize)
            enemiesContainer.addChild(enemy)
        }

        // Build collectibles
        for collectibleData in data.collectibles {
            let collectible = createCollectible(from: collectibleData, tileSize: tileSize)
            collectiblesContainer.addChild(collectible)
        }

        // Build interactables
        for interactableData in data.interactables {
            let interactable = createInteractable(from: interactableData, tileSize: tileSize)
            interactablesContainer.addChild(interactable)
        }

        // Build triggers
        for triggerData in data.triggers {
            let trigger = createTrigger(from: triggerData, tileSize: tileSize)
            triggersContainer.addChild(trigger)
        }

        // Build hazards
        for hazardData in data.hazards {
            let hazard = createHazard(from: hazardData, tileSize: tileSize)
            hazardsContainer.addChild(hazard)
        }

        // Build dark zones
        for darkZoneData in data.darkZones {
            let darkZone = createDarkZone(from: darkZoneData, tileSize: tileSize)
            darkZonesContainer.addChild(darkZone)
        }

        // Build torches
        for torchData in data.torches {
            let torch = createTorch(from: torchData, tileSize: tileSize)
            torchesContainer.addChild(torch)
        }

        // Build falling gates
        for fallingGateData in data.fallingGates {
            let fallingGate = createFallingGate(from: fallingGateData, tileSize: tileSize)
            fallingGatesContainer.addChild(fallingGate)
        }

        // Build icicles
        for icicleData in data.icicles {
            let icicle = createIcicle(from: icicleData, tileSize: tileSize)
            iciclesContainer.addChild(icicle)
        }

        // Build avalanches
        for avalancheData in data.avalanches {
            let avalanche = createAvalanche(from: avalancheData, tileSize: tileSize)
            avalanchesContainer.addChild(avalanche)
        }
    }

    // MARK: - Platform Access

    /// Возвращает все созданные движущиеся платформы
    /// - Returns: Массив MovingPlatform
    func getMovingPlatforms() -> [MovingPlatform] {
        return createdMovingPlatforms
    }

    // MARK: - Platform Creation

    func createPlatform(from data: PlatformData, tileSize: CGFloat) -> SKNode {
        let position = data.position.toPixels(tileSize: tileSize)
        let size = data.size.toPixels(tileSize: tileSize)

        // Moving platform - создаём специальный класс MovingPlatform
        if data.type == .moving, let path = data.movementPath, !path.isEmpty {
            // Конвертируем путь в пиксели
            var pixelPath = path.map { $0.toPixels(tileSize: tileSize) }

            // Добавляем начальную позицию в начало пути, если её там нет
            if pixelPath.first != position {
                pixelPath.insert(position, at: 0)
            }

            let moveSpeed = data.movementSpeed ?? 50.0
            let movementType = data.movementType ?? .loop

            let movingPlatform = MovingPlatform(size: size, waypoints: pixelPath, moveSpeed: moveSpeed)
            movingPlatform.position = position
            movingPlatform.movementType = movementType

            if let pauseTime = data.pauseAtWaypoints {
                movingPlatform.pauseAtWaypoints = pauseTime
            }

            // Сохраняем ссылку на платформу для доступа из сцены
            createdMovingPlatforms.append(movingPlatform)

            return movingPlatform
        }

        // Crumbling platform - создаём специальный класс
        if data.type == .crumbling {
            let crumblingPlatform = CrumblingPlatform(size: size)
            crumblingPlatform.position = position
            crumblingPlatform.saveOriginalPosition()

            // Опциональные параметры из данных уровня
            if let crumbleDelay = data.crumbleDelay {
                crumblingPlatform.crumbleDelay = crumbleDelay
            }
            if let respawnDelay = data.respawnDelay {
                crumblingPlatform.respawnDelay = respawnDelay
            }

            return crumblingPlatform
        }

        let platform = SKSpriteNode(color: platformColor(for: data.type), size: size)
        platform.position = position
        platform.name = "platform_\(data.type.rawValue)"

        // Physics body
        platform.physicsBody = SKPhysicsBody(rectangleOf: size)
        platform.physicsBody?.isDynamic = false
        platform.physicsBody?.categoryBitMask = PhysicsCategory.ground
        platform.physicsBody?.contactTestBitMask = PhysicsCategory.player
        platform.physicsBody?.collisionBitMask = PhysicsCategory.player | PhysicsCategory.enemy

        // Special handling for one-way platforms
        if data.type == .oneWay {
            platform.physicsBody?.collisionBitMask = 0 // Will be handled in game logic
            platform.userData = ["oneWay": true]
        }

        // Moving platform setup - теперь используем специальный класс MovingPlatform
        // (обрабатывается выше, этот код оставлен для совместимости)

        // Bouncy platform setup
        if data.type == .bouncy {
            platform.userData = platform.userData ?? [:]
            platform.userData?["bouncy"] = true
            platform.userData?["bounceMultiplier"] = data.bounceMultiplier ?? 2.0
        }

        // Ice platform setup
        if data.type == .ice {
            platform.userData = platform.userData ?? [:]
            platform.userData?["ice"] = true
            platform.userData?["friction"] = data.friction ?? 0.1
        }

        // Disappearing platform setup
        if data.type == .disappearing {
            let visibleTime = data.visibleTime ?? 2.0
            let hiddenTime = data.hiddenTime ?? 1.5
            let startVisible = data.startVisible ?? true
            platform.userData = platform.userData ?? [:]
            platform.userData?["disappearing"] = true
            platform.userData?["visibleTime"] = visibleTime
            platform.userData?["hiddenTime"] = hiddenTime
            setupDisappearingPlatform(platform, visibleTime: visibleTime, hiddenTime: hiddenTime, startVisible: startVisible)
        }

        // Floating platform setup
        if data.type == .floating {
            let amplitude = (data.floatAmplitude ?? 0.5) * tileSize
            let period = data.floatPeriod ?? 3.0
            platform.userData = platform.userData ?? [:]
            platform.userData?["floating"] = true
            platform.userData?["floatAmplitude"] = amplitude
            platform.userData?["floatPeriod"] = period
            setupFloatingPlatform(platform, amplitude: amplitude, period: period)
        }

        return platform
    }

    private func platformColor(for type: PlatformType) -> SKColor {
        switch type {
        case .solid:
            return SKColor(red: 0.4, green: 0.3, blue: 0.2, alpha: 1.0) // Brown
        case .oneWay:
            return SKColor(red: 0.6, green: 0.5, blue: 0.4, alpha: 0.8) // Light brown
        case .crumbling:
            return SKColor(red: 0.5, green: 0.4, blue: 0.3, alpha: 1.0) // Cracked look
        case .moving:
            return SKColor(red: 0.3, green: 0.4, blue: 0.5, alpha: 1.0) // Blue-gray
        case .bouncy:
            return SKColor(red: 0.8, green: 0.3, blue: 0.5, alpha: 1.0) // Mushroom pink/red
        case .ice:
            return SKColor(red: 0.7, green: 0.85, blue: 0.95, alpha: 1.0) // Light blue ice
        case .disappearing:
            return SKColor(red: 0.6, green: 0.7, blue: 0.9, alpha: 0.8) // Ethereal blue
        case .floating:
            return SKColor(red: 0.5, green: 0.6, blue: 0.4, alpha: 1.0) // Mossy green
        }
    }

    // setupMovingPlatform удалён - теперь используется класс MovingPlatform

    private func setupDisappearingPlatform(_ platform: SKSpriteNode, visibleTime: CGFloat, hiddenTime: CGFloat, startVisible: Bool) {
        let showAction = SKAction.run { [weak platform] in
            platform?.alpha = 1.0
            platform?.physicsBody?.categoryBitMask = PhysicsCategory.ground
            platform?.physicsBody?.collisionBitMask = PhysicsCategory.player | PhysicsCategory.enemy
        }
        let hideAction = SKAction.run { [weak platform] in
            platform?.alpha = 0.2
            platform?.physicsBody?.categoryBitMask = 0
            platform?.physicsBody?.collisionBitMask = 0
        }

        let visibleWait = SKAction.wait(forDuration: TimeInterval(visibleTime))
        let hiddenWait = SKAction.wait(forDuration: TimeInterval(hiddenTime))

        let fadeOut = SKAction.fadeAlpha(to: 0.2, duration: 0.3)
        let fadeIn = SKAction.fadeAlpha(to: 1.0, duration: 0.3)

        let cycle = SKAction.sequence([
            showAction,
            visibleWait,
            fadeOut,
            hideAction,
            hiddenWait,
            fadeIn
        ])

        // Set initial state
        if !startVisible {
            platform.alpha = 0.2
            platform.physicsBody?.categoryBitMask = 0
            platform.physicsBody?.collisionBitMask = 0
            // Offset the cycle start
            platform.run(SKAction.sequence([
                SKAction.wait(forDuration: TimeInterval(hiddenTime)),
                SKAction.repeatForever(cycle)
            ]))
        } else {
            platform.run(SKAction.repeatForever(cycle))
        }
    }

    private func setupFloatingPlatform(_ platform: SKSpriteNode, amplitude: CGFloat, period: CGFloat) {
        let moveUp = SKAction.moveBy(x: 0, y: amplitude, duration: TimeInterval(period / 2))
        moveUp.timingMode = .easeInEaseOut
        let moveDown = SKAction.moveBy(x: 0, y: -amplitude, duration: TimeInterval(period / 2))
        moveDown.timingMode = .easeInEaseOut

        let floatCycle = SKAction.sequence([moveUp, moveDown])
        platform.run(SKAction.repeatForever(floatCycle))
    }

    // MARK: - Enemy Creation

    /// Создаёт врага используя EnemyFactory
    /// - Parameters:
    ///   - data: Данные спавна врага
    ///   - tileSize: Размер тайла для конвертации координат
    /// - Returns: Созданный враг или placeholder если тип неизвестен
    func createEnemy(from data: EnemySpawnData, tileSize: CGFloat) -> SKNode {
        let position = data.position.toPixels(tileSize: tileSize)

        // Используем EnemyFactory для создания врага
        if let enemy = EnemyFactory.createEnemy(from: data) {
            enemy.position = position

            // Конвертируем путь патрулирования в пиксели
            if let path = data.patrolPath {
                enemy.patrolPath = path.map { $0.toPixels(tileSize: tileSize) }
            }

            return enemy
        }

        // Fallback: если тип неизвестен, создаём placeholder
        print("LevelLoader: Неизвестный тип врага '\(data.type)', создаю placeholder")
        let placeholder = SKSpriteNode(color: .red, size: CGSize(width: 32, height: 48))
        placeholder.position = position
        placeholder.name = "enemy_\(data.type)_placeholder"
        placeholder.xScale = data.facing == .left ? -1 : 1

        placeholder.physicsBody = SKPhysicsBody(rectangleOf: placeholder.size)
        placeholder.physicsBody?.isDynamic = true
        placeholder.physicsBody?.allowsRotation = false
        placeholder.physicsBody?.categoryBitMask = PhysicsCategory.enemy
        placeholder.physicsBody?.contactTestBitMask = PhysicsCategory.player | PhysicsCategory.playerAttack
        placeholder.physicsBody?.collisionBitMask = PhysicsCategory.ground

        placeholder.userData = [
            "type": data.type,
            "facing": data.facing.rawValue,
            "isPlaceholder": true
        ]

        return placeholder
    }

    // MARK: - Enemy Spawning

    /// Спавнит врагов в сцене на основе данных уровня
    /// - Parameters:
    ///   - scene: Сцена для добавления врагов
    ///   - levelData: Данные уровня
    /// - Returns: Массив созданных врагов
    @discardableResult
    func spawnEnemies(in scene: SKScene, from levelData: LevelData) -> [Enemy] {
        var spawnedEnemies: [Enemy] = []

        for enemyData in levelData.enemies {
            guard let enemy = EnemyFactory.createEnemy(from: enemyData) else {
                print("LevelLoader: Неизвестный тип врага '\(enemyData.type)' — пропускаю")
                continue
            }

            // Конвертируем позицию в пиксели
            enemy.position = enemyData.position.toPixels(tileSize: levelData.tileSize)

            // Конвертируем путь патрулирования в пиксели
            if let path = enemyData.patrolPath {
                enemy.patrolPath = path.map { $0.toPixels(tileSize: levelData.tileSize) }
            }

            scene.addChild(enemy)
            spawnedEnemies.append(enemy)
        }

        print("LevelLoader: Создано \(spawnedEnemies.count) врагов из \(levelData.enemies.count)")
        return spawnedEnemies
    }

    /// Спавнит врагов в указанную ноду (например, gameLayer)
    /// - Parameters:
    ///   - parentNode: Родительская нода для врагов
    ///   - levelData: Данные уровня
    /// - Returns: Массив созданных врагов
    @discardableResult
    func spawnEnemies(in parentNode: SKNode, from levelData: LevelData) -> [Enemy] {
        var spawnedEnemies: [Enemy] = []

        for enemyData in levelData.enemies {
            guard let enemy = EnemyFactory.createEnemy(from: enemyData) else {
                print("LevelLoader: Неизвестный тип врага '\(enemyData.type)' — пропускаю")
                continue
            }

            // Конвертируем позицию в пиксели
            enemy.position = enemyData.position.toPixels(tileSize: levelData.tileSize)

            // Конвертируем путь патрулирования в пиксели
            if let path = enemyData.patrolPath {
                enemy.patrolPath = path.map { $0.toPixels(tileSize: levelData.tileSize) }
            }

            parentNode.addChild(enemy)
            spawnedEnemies.append(enemy)
        }

        print("LevelLoader: Создано \(spawnedEnemies.count) врагов из \(levelData.enemies.count)")
        return spawnedEnemies
    }

    // MARK: - Collectible Creation

    func createCollectible(from data: CollectibleData, tileSize: CGFloat) -> SKNode {
        let position = data.position.toPixels(tileSize: tileSize)

        let collectible = SKSpriteNode(color: collectibleColor(for: data.type), size: collectibleSize(for: data.type))
        collectible.position = position
        collectible.name = "collectible_\(data.type.rawValue)"

        // Physics body (sensor)
        collectible.physicsBody = SKPhysicsBody(rectangleOf: collectible.size)
        collectible.physicsBody?.isDynamic = false
        collectible.physicsBody?.categoryBitMask = PhysicsCategory.collectible
        collectible.physicsBody?.contactTestBitMask = PhysicsCategory.player
        collectible.physicsBody?.collisionBitMask = 0 // No collision, just detection

        // Store additional data
        collectible.userData = [
            "type": data.type.rawValue,
            "id": data.id ?? ""
        ]

        // Add floating animation for crystals
        if data.type == .manaCrystal {
            let floatUp = SKAction.moveBy(x: 0, y: 5, duration: 0.5)
            let floatDown = floatUp.reversed()
            let float = SKAction.sequence([floatUp, floatDown])
            collectible.run(SKAction.repeatForever(float))
        }

        return collectible
    }

    private func collectibleColor(for type: CollectibleType) -> SKColor {
        switch type {
        case .manaCrystal:
            return SKColor(red: 0.4, green: 0.6, blue: 1.0, alpha: 1.0) // Blue
        case .healthPickup:
            return SKColor(red: 1.0, green: 0.3, blue: 0.3, alpha: 1.0) // Red
        case .chroniclePage:
            return SKColor(red: 1.0, green: 0.9, blue: 0.6, alpha: 1.0) // Cream/parchment
        case .checkpoint:
            return SKColor(red: 0.3, green: 1.0, blue: 0.5, alpha: 1.0) // Green
        }
    }

    private func collectibleSize(for type: CollectibleType) -> CGSize {
        switch type {
        case .manaCrystal:
            return CGSize(width: 16, height: 24)
        case .healthPickup:
            return CGSize(width: 20, height: 20)
        case .chroniclePage:
            return CGSize(width: 24, height: 32)
        case .checkpoint:
            return CGSize(width: 32, height: 64)
        }
    }

    // MARK: - Interactable Creation

    func createInteractable(from data: InteractableData, tileSize: CGFloat) -> SKNode {
        let position = data.position.toPixels(tileSize: tileSize)

        switch data.type {
        case .door:
            // Используем новый класс GameDoor
            let openDirection: GameDoor.OpenDirection
            if let dirString = data.openDirection {
                openDirection = GameDoor.OpenDirection(rawValue: dirString) ?? .up
            } else {
                openDirection = .up
            }

            let doorSize = data.size?.toPixels(tileSize: tileSize) ?? CGSize(width: 48, height: 96)
            let door = GameDoor(
                doorId: data.linkedId ?? UUID().uuidString,
                openDirection: openDirection,
                size: doorSize
            )
            door.position = position
            door.saveOriginalPosition()

            // Автозакрытие если указано
            if let autoClose = data.autoCloseDelay {
                door.autoCloseDelay = autoClose
            }

            // Регистрируем в менеджере
            SwitchDoorManager.shared.registerDoor(door)

            return door

        case .switch:
            // Используем новый класс GameSwitch
            let activationType: GameSwitch.ActivationType
            if let typeString = data.activationType {
                activationType = GameSwitch.ActivationType(rawValue: typeString) ?? .attack
            } else {
                activationType = .attack
            }

            let switchSize = data.size?.toPixels(tileSize: tileSize) ?? CGSize(width: 32, height: 32)
            let gameSwitch = GameSwitch(
                linkedDoorId: data.linkedId ?? "",
                activationType: activationType,
                size: switchSize
            )
            gameSwitch.position = position

            // Toggle режим если указан
            if let isToggle = data.isToggleable {
                gameSwitch.isToggleable = isToggle
            }

            // Регистрируем в менеджере
            SwitchDoorManager.shared.registerSwitch(gameSwitch)

            return gameSwitch

        case .levelExit:
            // Определяем ID следующего уровня (из linkedId или nextLevelId)
            var nextLevelId: Int
            if let explicitId = data.nextLevelId {
                nextLevelId = explicitId
            } else if let linkedIdString = data.linkedId, let parsedId = Int(linkedIdString) {
                nextLevelId = parsedId
            } else {
                // По умолчанию - следующий уровень
                nextLevelId = GameManager.shared.currentLevel + 1
            }

            // Определяем тип перехода
            let transitionType: TransitionType
            if let typeString = data.transitionType {
                switch typeString {
                case "door":
                    transitionType = .door
                case "path":
                    transitionType = .path
                default:
                    transitionType = .portal
                }
            } else {
                transitionType = .portal
            }

            // Создаём LevelExit
            let levelExit = LevelExit(nextLevelId: nextLevelId, transitionType: transitionType)
            levelExit.position = position

            // Настраиваем требование ключа
            if let requiresKey = data.requiresKey, requiresKey {
                levelExit.requiresKey = true
                levelExit.keyId = data.keyId
            }

            return levelExit
        }
    }

    // MARK: - Trigger Creation

    func createTrigger(from data: TriggerData, tileSize: CGFloat) -> SKNode {
        let position = data.position.toPixels(tileSize: tileSize)
        let size = data.size.toPixels(tileSize: tileSize)

        let trigger = SKNode()
        trigger.position = position
        trigger.name = "trigger_\(data.type.rawValue)"

        // Invisible physics body
        trigger.physicsBody = SKPhysicsBody(rectangleOf: size)
        trigger.physicsBody?.isDynamic = false
        trigger.physicsBody?.categoryBitMask = PhysicsCategory.trigger
        trigger.physicsBody?.contactTestBitMask = PhysicsCategory.player
        trigger.physicsBody?.collisionBitMask = 0

        // Store trigger data
        trigger.userData = [
            "type": data.type.rawValue,
            "dialogId": data.dialogId ?? "",
            "oneTime": data.oneTime,
            "triggered": false
        ]

        #if DEBUG
        // Debug visualization
        let debugRect = SKShapeNode(rectOf: size)
        debugRect.strokeColor = triggerDebugColor(for: data.type)
        debugRect.lineWidth = 2
        debugRect.fillColor = debugRect.strokeColor.withAlphaComponent(0.1)
        trigger.addChild(debugRect)
        #endif

        return trigger
    }

    private func triggerDebugColor(for type: TriggerType) -> SKColor {
        switch type {
        case .dialog:
            return .cyan
        case .bossSpawn:
            return .orange
        case .cutscene:
            return .magenta
        }
    }

    // MARK: - Background Layer Creation

    private func createBackgroundLayer(from data: BackgroundLayerData, levelSize: CGSize) -> SKNode {
        let layer = SKSpriteNode(imageNamed: data.imageName)
        layer.name = "background_\(data.imageName)"
        layer.zPosition = data.zPosition
        layer.position = CGPoint(x: levelSize.width / 2, y: levelSize.height / 2)

        // Scale to fit level if needed
        if layer.size.width > 0 && layer.size.height > 0 {
            let scaleX = levelSize.width / layer.size.width
            let scaleY = levelSize.height / layer.size.height
            let scale = max(scaleX, scaleY)
            layer.setScale(scale)
        }

        // Store parallax factor for camera updates
        layer.userData = ["parallaxFactor": data.parallaxFactor]

        return layer
    }

    // MARK: - Hazard Creation

    func createHazard(from data: HazardData, tileSize: CGFloat) -> SKNode {
        let position = data.position.toPixels(tileSize: tileSize)
        let size = data.size.toPixels(tileSize: tileSize)

        // Определяем тип опасности
        let hazardType = HazardType(rawValue: data.hazardType) ?? .spikes

        // Создаём опасность используя новый класс Hazard
        let hazard = Hazard(type: hazardType, size: size)
        hazard.position = position

        // Настраиваем опциональные параметры
        if let damage = data.damage {
            hazard.damage = damage
        }

        if let interval = data.damageInterval {
            hazard.damageInterval = interval
        }

        return hazard
    }

    // MARK: - Dark Zone Creation

    func createDarkZone(from data: DarkZoneData, tileSize: CGFloat) -> SKNode {
        let position = data.position.toPixels(tileSize: tileSize)
        let size = data.size.toPixels(tileSize: tileSize)

        let darkZone = SKNode()
        darkZone.position = position
        darkZone.name = "darkZone"

        // Create darkness overlay
        let darkness = SKSpriteNode(color: SKColor.black.withAlphaComponent(0.85), size: size)
        darkness.position = CGPoint(x: size.width / 2, y: size.height / 2)
        darkness.zPosition = 50 // Above game elements but below HUD
        darkness.name = "darkness_overlay"
        darkZone.addChild(darkness)

        // Physics body for detection
        darkZone.physicsBody = SKPhysicsBody(rectangleOf: size, center: CGPoint(x: size.width / 2, y: size.height / 2))
        darkZone.physicsBody?.isDynamic = false
        darkZone.physicsBody?.categoryBitMask = PhysicsCategory.trigger
        darkZone.physicsBody?.contactTestBitMask = PhysicsCategory.player
        darkZone.physicsBody?.collisionBitMask = 0

        // Store dark zone data
        darkZone.userData = [
            "type": "darkZone",
            "lightRadius": data.lightRadius
        ]

        return darkZone
    }

    // MARK: - Torch Creation

    func createTorch(from data: TorchData, tileSize: CGFloat) -> SKNode {
        let position = data.position.toPixels(tileSize: tileSize)

        let torch = SKNode()
        torch.position = position
        torch.name = "torch"

        // Torch holder (brown rectangle)
        let holder = SKSpriteNode(color: SKColor(red: 0.4, green: 0.25, blue: 0.1, alpha: 1.0), size: CGSize(width: 8, height: 24))
        holder.position = .zero
        torch.addChild(holder)

        // Flame (yellow/orange)
        let flameColor = data.isLit ? SKColor(red: 1.0, green: 0.6, blue: 0.2, alpha: 1.0) : SKColor.darkGray
        let flame = SKSpriteNode(color: flameColor, size: CGSize(width: 12, height: 16))
        flame.position = CGPoint(x: 0, y: 16)
        flame.name = "flame"
        torch.addChild(flame)

        // Light glow effect (if lit)
        if data.isLit {
            let glow = SKShapeNode(circleOfRadius: data.lightRadius)
            glow.fillColor = SKColor(red: 1.0, green: 0.8, blue: 0.4, alpha: 0.15)
            glow.strokeColor = .clear
            glow.position = CGPoint(x: 0, y: 16)
            glow.zPosition = -1
            glow.name = "glow"
            torch.addChild(glow)

            // Flickering animation
            let flicker = SKAction.sequence([
                SKAction.fadeAlpha(to: 0.8, duration: 0.1),
                SKAction.fadeAlpha(to: 1.0, duration: 0.1),
                SKAction.wait(forDuration: Double.random(in: 0.1...0.3))
            ])
            flame.run(SKAction.repeatForever(flicker))
        }

        // Physics body for interaction
        torch.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: 16, height: 32))
        torch.physicsBody?.isDynamic = false
        torch.physicsBody?.categoryBitMask = PhysicsCategory.trigger
        torch.physicsBody?.contactTestBitMask = PhysicsCategory.playerAttack
        torch.physicsBody?.collisionBitMask = 0

        // Store torch data
        torch.userData = [
            "type": "torch",
            "isLit": data.isLit,
            "lightRadius": data.lightRadius
        ]

        return torch
    }

    // MARK: - Falling Gate Creation

    func createFallingGate(from data: FallingGateData, tileSize: CGFloat) -> SKNode {
        let position = data.position.toPixels(tileSize: tileSize)

        let gate = SKNode()
        gate.position = position
        gate.name = "fallingGate"

        // Gate visual (iron bars)
        let gateSize = CGSize(width: 32, height: 96)
        let gateSprite = SKSpriteNode(color: SKColor(red: 0.3, green: 0.3, blue: 0.35, alpha: 1.0), size: gateSize)
        gateSprite.position = CGPoint(x: 0, y: gateSize.height / 2) // Anchor at bottom
        gateSprite.name = "gateSprite"
        gate.addChild(gateSprite)

        // Add bar pattern
        for i in 0..<4 {
            let bar = SKSpriteNode(color: SKColor(red: 0.4, green: 0.4, blue: 0.45, alpha: 1.0), size: CGSize(width: 4, height: gateSize.height - 8))
            bar.position = CGPoint(x: CGFloat(i) * 8 - 12, y: gateSize.height / 2)
            gate.addChild(bar)
        }

        // Trigger zone (invisible, larger area)
        let triggerZone = SKNode()
        triggerZone.name = "triggerZone"
        triggerZone.position = CGPoint(x: 0, y: -data.triggerDistance / 2)
        triggerZone.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: data.triggerDistance * 2, height: data.triggerDistance))
        triggerZone.physicsBody?.isDynamic = false
        triggerZone.physicsBody?.categoryBitMask = PhysicsCategory.trigger
        triggerZone.physicsBody?.contactTestBitMask = PhysicsCategory.player
        triggerZone.physicsBody?.collisionBitMask = 0
        gate.addChild(triggerZone)

        // Store gate data
        gate.userData = [
            "type": "fallingGate",
            "triggerDistance": data.triggerDistance,
            "fallSpeed": data.fallSpeed,
            "hasFallen": false
        ]

        return gate
    }

    // MARK: - Icicle Creation

    func createIcicle(from data: IcicleData, tileSize: CGFloat) -> SKNode {
        let position = data.position.toPixels(tileSize: tileSize)

        let icicle = SKNode()
        icicle.position = position
        icicle.name = "icicle"

        // Icicle visual (triangular shape approximated with sprite)
        let icicleSize = CGSize(width: 16, height: 48)
        let icicleSprite = SKSpriteNode(color: SKColor(red: 0.8, green: 0.9, blue: 1.0, alpha: 0.9), size: icicleSize)
        icicleSprite.position = CGPoint(x: 0, y: -icicleSize.height / 2)
        icicleSprite.name = "icicleSprite"
        icicle.addChild(icicleSprite)

        // Add icy shine effect
        let shine = SKSpriteNode(color: SKColor.white.withAlphaComponent(0.4), size: CGSize(width: 4, height: 40))
        shine.position = CGPoint(x: -4, y: -icicleSize.height / 2)
        icicle.addChild(shine)

        // Trigger zone (invisible, detects player proximity)
        let triggerZone = SKNode()
        triggerZone.name = "triggerZone"
        triggerZone.position = CGPoint(x: 0, y: -data.triggerRadius)
        triggerZone.physicsBody = SKPhysicsBody(circleOfRadius: data.triggerRadius)
        triggerZone.physicsBody?.isDynamic = false
        triggerZone.physicsBody?.categoryBitMask = PhysicsCategory.trigger
        triggerZone.physicsBody?.contactTestBitMask = PhysicsCategory.player
        triggerZone.physicsBody?.collisionBitMask = 0
        icicle.addChild(triggerZone)

        // Store icicle data
        icicle.userData = [
            "type": "icicle",
            "triggerRadius": data.triggerRadius,
            "damage": data.damage,
            "respawnTime": data.respawnTime,
            "hasFallen": false,
            "originalPosition": position
        ]

        return icicle
    }

    // MARK: - Avalanche Creation

    func createAvalanche(from data: AvalancheData, tileSize: CGFloat) -> SKNode {
        let triggerPosition = data.triggerPosition.toPixels(tileSize: tileSize)

        let avalanche = SKNode()
        avalanche.position = triggerPosition
        avalanche.name = "avalanche"

        // Trigger zone (invisible, starts avalanche when player enters)
        let triggerZone = SKShapeNode(rectOf: CGSize(width: tileSize * 2, height: tileSize * 4))
        triggerZone.name = "triggerZone"
        triggerZone.fillColor = .clear
        triggerZone.strokeColor = .clear
        triggerZone.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: tileSize * 2, height: tileSize * 4))
        triggerZone.physicsBody?.isDynamic = false
        triggerZone.physicsBody?.categoryBitMask = PhysicsCategory.trigger
        triggerZone.physicsBody?.contactTestBitMask = PhysicsCategory.player
        triggerZone.physicsBody?.collisionBitMask = 0
        avalanche.addChild(triggerZone)

        #if DEBUG
        // Debug visualization
        let debugRect = SKShapeNode(rectOf: CGSize(width: tileSize * 2, height: tileSize * 4))
        debugRect.strokeColor = SKColor.red.withAlphaComponent(0.5)
        debugRect.lineWidth = 2
        debugRect.fillColor = SKColor.red.withAlphaComponent(0.1)
        avalanche.addChild(debugRect)
        #endif

        // Store avalanche data
        avalanche.userData = [
            "type": "avalanche",
            "startX": data.startX * tileSize,
            "endX": data.endX * tileSize,
            "speed": data.speed,
            "isActive": false,
            "hasTriggered": false
        ]

        return avalanche
    }
}
