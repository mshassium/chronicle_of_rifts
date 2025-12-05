import Foundation
import CoreGraphics

// MARK: - JSON Decoding Helpers

/// Хелпер для декодирования CGPoint из {"x": ..., "y": ...}
struct PointJSON: Codable {
    let x: CGFloat
    let y: CGFloat

    var cgPoint: CGPoint { CGPoint(x: x, y: y) }
}

/// Хелпер для декодирования CGSize из {"width": ..., "height": ...}
struct SizeJSON: Codable {
    let width: CGFloat
    let height: CGFloat

    var cgSize: CGSize { CGSize(width: width, height: height) }
}

/// Хелпер для декодирования CGRect из {"x": ..., "y": ..., "width": ..., "height": ...}
struct RectJSON: Codable {
    let x: CGFloat
    let y: CGFloat
    let width: CGFloat
    let height: CGFloat

    var cgRect: CGRect { CGRect(x: x, y: y, width: width, height: height) }
}

// MARK: - Enums

enum PlatformType: String, Codable {
    case solid
    case oneWay
    case crumbling
    case moving
    case bouncy
    case ice
    case disappearing
    case floating
}

enum Direction: String, Codable {
    case left
    case right
}

enum CollectibleType: String, Codable {
    case manaCrystal
    case healthPickup
    case chroniclePage
    case checkpoint
}

enum InteractableType: String, Codable {
    case door
    case `switch`
    case levelExit
}

enum TriggerType: String, Codable {
    case dialog
    case bossSpawn
    case cutscene
}

// MARK: - Supporting Data Structures

struct PlatformData: Codable {
    let position: CGPoint
    let size: CGSize
    let type: PlatformType
    let movementPath: [CGPoint]?
    let movementSpeed: CGFloat?
    let movementType: MovementType?
    let pauseAtWaypoints: TimeInterval?
    let bounceMultiplier: CGFloat?
    let friction: CGFloat?
    // Disappearing platform properties
    let visibleTime: CGFloat?
    let hiddenTime: CGFloat?
    let startVisible: Bool?
    // Floating platform properties
    let floatAmplitude: CGFloat?
    let floatPeriod: CGFloat?
    // Crumbling platform properties
    let crumbleDelay: TimeInterval?
    let respawnDelay: TimeInterval?

    enum CodingKeys: String, CodingKey {
        case position, size, type, movementPath, movementSpeed, movementType, pauseAtWaypoints
        case bounceMultiplier, friction
        case visibleTime, hiddenTime, startVisible
        case floatAmplitude, floatPeriod
        case crumbleDelay, respawnDelay
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        position = try container.decode(PointJSON.self, forKey: .position).cgPoint
        size = try container.decode(SizeJSON.self, forKey: .size).cgSize
        type = try container.decode(PlatformType.self, forKey: .type)
        movementPath = try container.decodeIfPresent([PointJSON].self, forKey: .movementPath)?.map { $0.cgPoint }
        movementSpeed = try container.decodeIfPresent(CGFloat.self, forKey: .movementSpeed)
        movementType = try container.decodeIfPresent(MovementType.self, forKey: .movementType)
        pauseAtWaypoints = try container.decodeIfPresent(TimeInterval.self, forKey: .pauseAtWaypoints)
        bounceMultiplier = try container.decodeIfPresent(CGFloat.self, forKey: .bounceMultiplier)
        friction = try container.decodeIfPresent(CGFloat.self, forKey: .friction)
        // Disappearing platform properties
        visibleTime = try container.decodeIfPresent(CGFloat.self, forKey: .visibleTime)
        hiddenTime = try container.decodeIfPresent(CGFloat.self, forKey: .hiddenTime)
        startVisible = try container.decodeIfPresent(Bool.self, forKey: .startVisible)
        // Floating platform properties
        floatAmplitude = try container.decodeIfPresent(CGFloat.self, forKey: .floatAmplitude)
        floatPeriod = try container.decodeIfPresent(CGFloat.self, forKey: .floatPeriod)
        // Crumbling platform properties
        crumbleDelay = try container.decodeIfPresent(TimeInterval.self, forKey: .crumbleDelay)
        respawnDelay = try container.decodeIfPresent(TimeInterval.self, forKey: .respawnDelay)
    }
}

struct EnemySpawnData: Codable {
    let type: String
    let position: CGPoint
    let patrolPath: [CGPoint]?
    let facing: Direction

    enum CodingKeys: String, CodingKey {
        case type, position, patrolPath, facing
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = try container.decode(String.self, forKey: .type)
        position = try container.decode(PointJSON.self, forKey: .position).cgPoint
        patrolPath = try container.decodeIfPresent([PointJSON].self, forKey: .patrolPath)?.map { $0.cgPoint }
        facing = try container.decode(Direction.self, forKey: .facing)
    }
}

struct CollectibleData: Codable {
    let type: CollectibleType
    let position: CGPoint
    let id: String?

    enum CodingKeys: String, CodingKey {
        case type, position, id
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = try container.decode(CollectibleType.self, forKey: .type)
        position = try container.decode(PointJSON.self, forKey: .position).cgPoint
        id = try container.decodeIfPresent(String.self, forKey: .id)
    }
}

struct InteractableData: Codable {
    let type: InteractableType
    let position: CGPoint
    let linkedId: String?
    // Switch properties
    let activationType: String?  // "attack", "step", "interact"
    let isToggleable: Bool?
    // Door properties
    let openDirection: String?   // "up", "down", "fade"
    let autoCloseDelay: TimeInterval?
    let size: CGSize?
    // LevelExit properties
    let nextLevelId: Int?
    let transitionType: String?  // "portal", "door", "path"
    let requiresKey: Bool?
    let keyId: String?

    enum CodingKeys: String, CodingKey {
        case type, position, linkedId
        case activationType, isToggleable
        case openDirection, autoCloseDelay, size
        case nextLevelId, transitionType, requiresKey, keyId
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = try container.decode(InteractableType.self, forKey: .type)
        position = try container.decode(PointJSON.self, forKey: .position).cgPoint
        linkedId = try container.decodeIfPresent(String.self, forKey: .linkedId)
        activationType = try container.decodeIfPresent(String.self, forKey: .activationType)
        isToggleable = try container.decodeIfPresent(Bool.self, forKey: .isToggleable)
        openDirection = try container.decodeIfPresent(String.self, forKey: .openDirection)
        autoCloseDelay = try container.decodeIfPresent(TimeInterval.self, forKey: .autoCloseDelay)
        size = try container.decodeIfPresent(SizeJSON.self, forKey: .size)?.cgSize
        nextLevelId = try container.decodeIfPresent(Int.self, forKey: .nextLevelId)
        transitionType = try container.decodeIfPresent(String.self, forKey: .transitionType)
        requiresKey = try container.decodeIfPresent(Bool.self, forKey: .requiresKey)
        keyId = try container.decodeIfPresent(String.self, forKey: .keyId)
    }
}

struct TriggerData: Codable {
    let type: TriggerType
    let position: CGPoint
    let size: CGSize
    let dialogId: String?
    let oneTime: Bool

    enum CodingKeys: String, CodingKey {
        case type, position, size, dialogId, oneTime
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = try container.decode(TriggerType.self, forKey: .type)
        position = try container.decode(PointJSON.self, forKey: .position).cgPoint
        size = try container.decode(SizeJSON.self, forKey: .size).cgSize
        dialogId = try container.decodeIfPresent(String.self, forKey: .dialogId)
        oneTime = try container.decode(Bool.self, forKey: .oneTime)
    }
}

struct BackgroundLayerData: Codable {
    let imageName: String
    let parallaxFactor: CGFloat
    let zPosition: CGFloat
}

// MARK: - Hazard Data

struct HazardData: Codable {
    let type: String
    let hazardType: String
    let position: CGPoint
    let size: CGSize
    let damage: Int?
    let damageInterval: TimeInterval?

    enum CodingKeys: String, CodingKey {
        case type, hazardType, position, size, damage, damageInterval
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = try container.decode(String.self, forKey: .type)
        hazardType = try container.decode(String.self, forKey: .hazardType)
        position = try container.decode(PointJSON.self, forKey: .position).cgPoint
        size = try container.decode(SizeJSON.self, forKey: .size).cgSize
        damage = try container.decodeIfPresent(Int.self, forKey: .damage)
        damageInterval = try container.decodeIfPresent(TimeInterval.self, forKey: .damageInterval)
    }
}

// MARK: - Dark Zone Data

struct DarkZoneData: Codable {
    let type: String
    let position: CGPoint
    let size: CGSize
    let lightRadius: CGFloat

    enum CodingKeys: String, CodingKey {
        case type, position, size, lightRadius
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = try container.decode(String.self, forKey: .type)
        position = try container.decode(PointJSON.self, forKey: .position).cgPoint
        size = try container.decode(SizeJSON.self, forKey: .size).cgSize
        lightRadius = try container.decode(CGFloat.self, forKey: .lightRadius)
    }
}

// MARK: - Torch Data

struct TorchData: Codable {
    let type: String
    let position: CGPoint
    let lightRadius: CGFloat
    let isLit: Bool

    enum CodingKeys: String, CodingKey {
        case type, position, lightRadius, isLit
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = try container.decode(String.self, forKey: .type)
        position = try container.decode(PointJSON.self, forKey: .position).cgPoint
        lightRadius = try container.decode(CGFloat.self, forKey: .lightRadius)
        isLit = try container.decode(Bool.self, forKey: .isLit)
    }
}

// MARK: - Falling Gate Data

struct FallingGateData: Codable {
    let type: String
    let position: CGPoint
    let triggerDistance: CGFloat
    let fallSpeed: CGFloat

    enum CodingKeys: String, CodingKey {
        case type, position, triggerDistance, fallSpeed
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = try container.decode(String.self, forKey: .type)
        position = try container.decode(PointJSON.self, forKey: .position).cgPoint
        triggerDistance = try container.decode(CGFloat.self, forKey: .triggerDistance)
        fallSpeed = try container.decode(CGFloat.self, forKey: .fallSpeed)
    }
}

// MARK: - Icicle Data

struct IcicleData: Codable {
    let type: String
    let position: CGPoint
    let triggerRadius: CGFloat
    let damage: Int
    let respawnTime: CGFloat

    enum CodingKeys: String, CodingKey {
        case type, position, triggerRadius, damage, respawnTime
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = try container.decode(String.self, forKey: .type)
        position = try container.decode(PointJSON.self, forKey: .position).cgPoint
        triggerRadius = try container.decode(CGFloat.self, forKey: .triggerRadius)
        damage = try container.decode(Int.self, forKey: .damage)
        respawnTime = try container.decode(CGFloat.self, forKey: .respawnTime)
    }
}

// MARK: - Avalanche Data

struct AvalancheData: Codable {
    let type: String
    let triggerPosition: CGPoint
    let startX: CGFloat
    let endX: CGFloat
    let speed: CGFloat

    enum CodingKeys: String, CodingKey {
        case type, triggerPosition, startX, endX, speed
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = try container.decode(String.self, forKey: .type)
        triggerPosition = try container.decode(PointJSON.self, forKey: .triggerPosition).cgPoint
        startX = try container.decode(CGFloat.self, forKey: .startX)
        endX = try container.decode(CGFloat.self, forKey: .endX)
        speed = try container.decode(CGFloat.self, forKey: .speed)
    }
}

// MARK: - Main Level Data

struct LevelData: Codable {
    let id: Int
    let name: String
    let width: Int
    let height: Int
    let tileSize: CGFloat

    let playerSpawn: CGPoint

    let platforms: [PlatformData]
    let enemies: [EnemySpawnData]
    let collectibles: [CollectibleData]
    let interactables: [InteractableData]
    let triggers: [TriggerData]
    let backgroundLayers: [BackgroundLayerData]

    // New data types for level 4+
    let hazards: [HazardData]
    let darkZones: [DarkZoneData]
    let torches: [TorchData]
    let fallingGates: [FallingGateData]

    // New data types for level 5+
    let icicles: [IcicleData]
    let avalanches: [AvalancheData]

    let bounds: CGRect
    let deathZoneY: CGFloat

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(Int.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        width = try container.decode(Int.self, forKey: .width)
        height = try container.decode(Int.self, forKey: .height)
        tileSize = try container.decodeIfPresent(CGFloat.self, forKey: .tileSize) ?? 32

        playerSpawn = try container.decode(PointJSON.self, forKey: .playerSpawn).cgPoint

        platforms = try container.decodeIfPresent([PlatformData].self, forKey: .platforms) ?? []
        enemies = try container.decodeIfPresent([EnemySpawnData].self, forKey: .enemies) ?? []
        collectibles = try container.decodeIfPresent([CollectibleData].self, forKey: .collectibles) ?? []
        interactables = try container.decodeIfPresent([InteractableData].self, forKey: .interactables) ?? []
        triggers = try container.decodeIfPresent([TriggerData].self, forKey: .triggers) ?? []
        backgroundLayers = try container.decodeIfPresent([BackgroundLayerData].self, forKey: .backgroundLayers) ?? []

        // New data types for level 4+
        hazards = try container.decodeIfPresent([HazardData].self, forKey: .hazards) ?? []
        darkZones = try container.decodeIfPresent([DarkZoneData].self, forKey: .darkZones) ?? []
        torches = try container.decodeIfPresent([TorchData].self, forKey: .torches) ?? []
        fallingGates = try container.decodeIfPresent([FallingGateData].self, forKey: .fallingGates) ?? []

        // New data types for level 5+
        icicles = try container.decodeIfPresent([IcicleData].self, forKey: .icicles) ?? []
        avalanches = try container.decodeIfPresent([AvalancheData].self, forKey: .avalanches) ?? []

        bounds = try container.decode(RectJSON.self, forKey: .bounds).cgRect
        deathZoneY = try container.decode(CGFloat.self, forKey: .deathZoneY)
    }

    enum CodingKeys: String, CodingKey {
        case id, name, width, height, tileSize
        case playerSpawn
        case platforms, enemies, collectibles, interactables, triggers
        case backgroundLayers
        case hazards, darkZones, torches, fallingGates
        case icicles, avalanches
        case bounds, deathZoneY
    }
}

// MARK: - Tile Coordinate Conversion

extension CGPoint {
    func toPixels(tileSize: CGFloat = 32) -> CGPoint {
        return CGPoint(x: x * tileSize, y: y * tileSize)
    }

    static func fromTiles(x: Int, y: Int, tileSize: CGFloat = 32) -> CGPoint {
        return CGPoint(x: CGFloat(x) * tileSize, y: CGFloat(y) * tileSize)
    }
}

extension CGSize {
    func toPixels(tileSize: CGFloat = 32) -> CGSize {
        return CGSize(width: width * tileSize, height: height * tileSize)
    }

    static func fromTiles(width: Int, height: Int, tileSize: CGFloat = 32) -> CGSize {
        return CGSize(width: CGFloat(width) * tileSize, height: CGFloat(height) * tileSize)
    }
}

extension CGRect {
    func toPixels(tileSize: CGFloat = 32) -> CGRect {
        return CGRect(
            x: origin.x * tileSize,
            y: origin.y * tileSize,
            width: size.width * tileSize,
            height: size.height * tileSize
        )
    }
}
