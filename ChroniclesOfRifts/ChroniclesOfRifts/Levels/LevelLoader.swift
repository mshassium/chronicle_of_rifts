import SpriteKit

class LevelLoader {

    // MARK: - Node Names

    struct NodeNames {
        static let platformsContainer = "platforms"
        static let enemiesContainer = "enemies"
        static let collectiblesContainer = "collectibles"
        static let triggersContainer = "triggers"
        static let interactablesContainer = "interactables"
        static let backgroundContainer = "background"
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

    func buildLevel(from data: LevelData, in scene: SKScene) {
        let tileSize = data.tileSize

        // Create containers
        let platformsContainer = SKNode()
        platformsContainer.name = NodeNames.platformsContainer
        scene.addChild(platformsContainer)

        let enemiesContainer = SKNode()
        enemiesContainer.name = NodeNames.enemiesContainer
        scene.addChild(enemiesContainer)

        let collectiblesContainer = SKNode()
        collectiblesContainer.name = NodeNames.collectiblesContainer
        scene.addChild(collectiblesContainer)

        let triggersContainer = SKNode()
        triggersContainer.name = NodeNames.triggersContainer
        scene.addChild(triggersContainer)

        let interactablesContainer = SKNode()
        interactablesContainer.name = NodeNames.interactablesContainer
        scene.addChild(interactablesContainer)

        let backgroundContainer = SKNode()
        backgroundContainer.name = NodeNames.backgroundContainer
        scene.addChild(backgroundContainer)

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
    }

    // MARK: - Platform Creation

    func createPlatform(from data: PlatformData, tileSize: CGFloat) -> SKNode {
        let position = data.position.toPixels(tileSize: tileSize)
        let size = data.size.toPixels(tileSize: tileSize)

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

        // Moving platform setup
        if data.type == .moving, let path = data.movementPath, !path.isEmpty {
            let pixelPath = path.map { $0.toPixels(tileSize: tileSize) }
            let speed = data.movementSpeed ?? 50.0
            platform.userData = platform.userData ?? [:]
            platform.userData?["movementPath"] = pixelPath
            platform.userData?["movementSpeed"] = speed
            setupMovingPlatform(platform, path: pixelPath, speed: speed)
        }

        // Crumbling platform setup
        if data.type == .crumbling {
            platform.userData = platform.userData ?? [:]
            platform.userData?["crumbling"] = true
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
        }
    }

    private func setupMovingPlatform(_ platform: SKSpriteNode, path: [CGPoint], speed: CGFloat) {
        guard path.count >= 1 else { return }

        var actions: [SKAction] = []
        var previousPoint = platform.position

        for point in path {
            let distance = hypot(point.x - previousPoint.x, point.y - previousPoint.y)
            let duration = TimeInterval(distance / speed)
            actions.append(SKAction.move(to: point, duration: duration))
            previousPoint = point
        }

        // Return to start
        let distanceBack = hypot(platform.position.x - previousPoint.x, platform.position.y - previousPoint.y)
        let durationBack = TimeInterval(distanceBack / speed)
        actions.append(SKAction.move(to: platform.position, duration: durationBack))

        let sequence = SKAction.sequence(actions)
        platform.run(SKAction.repeatForever(sequence))
    }

    // MARK: - Enemy Creation (Stub)

    func createEnemy(from data: EnemySpawnData, tileSize: CGFloat) -> SKNode {
        let position = data.position.toPixels(tileSize: tileSize)

        // Stub implementation - colored rectangle
        let enemy = SKSpriteNode(color: .red, size: CGSize(width: 32, height: 48))
        enemy.position = position
        enemy.name = "enemy_\(data.type)"
        enemy.xScale = data.facing == .left ? -1 : 1

        // Physics body
        enemy.physicsBody = SKPhysicsBody(rectangleOf: enemy.size)
        enemy.physicsBody?.isDynamic = true
        enemy.physicsBody?.allowsRotation = false
        enemy.physicsBody?.categoryBitMask = PhysicsCategory.enemy
        enemy.physicsBody?.contactTestBitMask = PhysicsCategory.player | PhysicsCategory.playerAttack
        enemy.physicsBody?.collisionBitMask = PhysicsCategory.ground

        // Store enemy data for later use
        enemy.userData = [
            "type": data.type,
            "facing": data.facing.rawValue,
            "patrolPath": data.patrolPath?.map { $0.toPixels(tileSize: tileSize) } ?? []
        ]

        return enemy
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

        let size: CGSize
        let color: SKColor

        switch data.type {
        case .door:
            size = CGSize(width: 48, height: 80)
            color = SKColor(red: 0.5, green: 0.35, blue: 0.2, alpha: 1.0) // Wood brown
        case .switch:
            size = CGSize(width: 24, height: 32)
            color = SKColor(red: 0.7, green: 0.7, blue: 0.3, alpha: 1.0) // Yellow
        case .levelExit:
            size = CGSize(width: 64, height: 96)
            color = SKColor(red: 0.8, green: 0.6, blue: 1.0, alpha: 0.8) // Purple glow
        }

        let interactable = SKSpriteNode(color: color, size: size)
        interactable.position = position
        interactable.name = "interactable_\(data.type.rawValue)"

        // Physics body
        interactable.physicsBody = SKPhysicsBody(rectangleOf: size)
        interactable.physicsBody?.isDynamic = false
        interactable.physicsBody?.categoryBitMask = PhysicsCategory.trigger
        interactable.physicsBody?.contactTestBitMask = PhysicsCategory.player
        interactable.physicsBody?.collisionBitMask = data.type == .door ? PhysicsCategory.player : 0

        // Store data
        interactable.userData = [
            "type": data.type.rawValue,
            "linkedId": data.linkedId ?? "",
            "isActive": true
        ]

        // Level exit glow effect
        if data.type == .levelExit {
            let pulse = SKAction.sequence([
                SKAction.fadeAlpha(to: 0.5, duration: 1.0),
                SKAction.fadeAlpha(to: 1.0, duration: 1.0)
            ])
            interactable.run(SKAction.repeatForever(pulse))
        }

        return interactable
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
}
