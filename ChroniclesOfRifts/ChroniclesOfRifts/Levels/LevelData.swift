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

    enum CodingKeys: String, CodingKey {
        case position, size, type, movementPath, movementSpeed
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        position = try container.decode(PointJSON.self, forKey: .position).cgPoint
        size = try container.decode(SizeJSON.self, forKey: .size).cgSize
        type = try container.decode(PlatformType.self, forKey: .type)
        movementPath = try container.decodeIfPresent([PointJSON].self, forKey: .movementPath)?.map { $0.cgPoint }
        movementSpeed = try container.decodeIfPresent(CGFloat.self, forKey: .movementSpeed)
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

    enum CodingKeys: String, CodingKey {
        case type, position, linkedId
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = try container.decode(InteractableType.self, forKey: .type)
        position = try container.decode(PointJSON.self, forKey: .position).cgPoint
        linkedId = try container.decodeIfPresent(String.self, forKey: .linkedId)
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

        bounds = try container.decode(RectJSON.self, forKey: .bounds).cgRect
        deathZoneY = try container.decode(CGFloat.self, forKey: .deathZoneY)
    }

    enum CodingKeys: String, CodingKey {
        case id, name, width, height, tileSize
        case playerSpawn
        case platforms, enemies, collectibles, interactables, triggers
        case backgroundLayers
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
