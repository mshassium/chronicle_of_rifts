import Foundation
import CoreGraphics

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
}

struct EnemySpawnData: Codable {
    let type: String
    let position: CGPoint
    let patrolPath: [CGPoint]?
    let facing: Direction
}

struct CollectibleData: Codable {
    let type: CollectibleType
    let position: CGPoint
    let id: String?
}

struct InteractableData: Codable {
    let type: InteractableType
    let position: CGPoint
    let linkedId: String?
}

struct TriggerData: Codable {
    let type: TriggerType
    let position: CGPoint
    let size: CGSize
    let dialogId: String?
    let oneTime: Bool
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

        playerSpawn = try container.decode(CGPoint.self, forKey: .playerSpawn)

        platforms = try container.decodeIfPresent([PlatformData].self, forKey: .platforms) ?? []
        enemies = try container.decodeIfPresent([EnemySpawnData].self, forKey: .enemies) ?? []
        collectibles = try container.decodeIfPresent([CollectibleData].self, forKey: .collectibles) ?? []
        interactables = try container.decodeIfPresent([InteractableData].self, forKey: .interactables) ?? []
        triggers = try container.decodeIfPresent([TriggerData].self, forKey: .triggers) ?? []
        backgroundLayers = try container.decodeIfPresent([BackgroundLayerData].self, forKey: .backgroundLayers) ?? []

        bounds = try container.decode(CGRect.self, forKey: .bounds)
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
