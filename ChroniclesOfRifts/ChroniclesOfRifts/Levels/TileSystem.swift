import SpriteKit

// MARK: - TileType

/// Типы тайлов для построения уровней
enum TileType: String, CaseIterable {
    // Ground tiles
    case groundTop = "ground_top"
    case groundMiddle = "ground_middle"
    case groundBottom = "ground_bottom"
    case groundLeftEdge = "ground_left_edge"
    case groundRightEdge = "ground_right_edge"
    case groundTopLeftCorner = "ground_top_left_corner"
    case groundTopRightCorner = "ground_top_right_corner"
    case groundBottomLeftCorner = "ground_bottom_left_corner"
    case groundBottomRightCorner = "ground_bottom_right_corner"
    case groundSingle = "ground_single"

    // Platform tiles
    case platformThin = "platform_thin"
    case platformThick = "platform_thick"

    // Wall tiles
    case wallLeft = "wall_left"
    case wallRight = "wall_right"
    case wallFull = "wall_full"

    // Hazard tiles
    case hazardSpikes = "hazard_spikes"
    case hazardLava = "hazard_lava"
    case hazardVoid = "hazard_void"

    // Decoration tiles
    case decorGrass = "decor_grass"
    case decorStone = "decor_stone"
    case decorTorch = "decor_torch"
    case decorBanner = "decor_banner"
    case decorDebris = "decor_debris"
    case decorChain = "decor_chain"

    // MARK: - Properties

    var isCollidable: Bool {
        switch self {
        case .groundTop, .groundMiddle, .groundBottom, .groundLeftEdge, .groundRightEdge,
             .groundTopLeftCorner, .groundTopRightCorner, .groundBottomLeftCorner,
             .groundBottomRightCorner, .groundSingle,
             .platformThick,
             .wallLeft, .wallRight, .wallFull:
            return true
        case .platformThin:
            return true // One-way collision handled separately
        case .hazardSpikes, .hazardLava, .hazardVoid:
            return false // Contact detection, no physical collision
        case .decorGrass, .decorStone, .decorTorch, .decorBanner, .decorDebris, .decorChain:
            return false
        }
    }

    var isSemiSolid: Bool {
        return self == .platformThin
    }

    var damageOnContact: Int {
        switch self {
        case .hazardSpikes:
            return 25
        case .hazardLava:
            return 50
        case .hazardVoid:
            return 999 // Instant death
        default:
            return 0
        }
    }

    var isGround: Bool {
        switch self {
        case .groundTop, .groundMiddle, .groundBottom, .groundLeftEdge, .groundRightEdge,
             .groundTopLeftCorner, .groundTopRightCorner, .groundBottomLeftCorner,
             .groundBottomRightCorner, .groundSingle:
            return true
        default:
            return false
        }
    }

    var isPlatform: Bool {
        return self == .platformThin || self == .platformThick
    }

    var isWall: Bool {
        return self == .wallLeft || self == .wallRight || self == .wallFull
    }

    var isHazard: Bool {
        return self == .hazardSpikes || self == .hazardLava || self == .hazardVoid
    }

    var isDecoration: Bool {
        switch self {
        case .decorGrass, .decorStone, .decorTorch, .decorBanner, .decorDebris, .decorChain:
            return true
        default:
            return false
        }
    }
}

// MARK: - TileSet

/// Наборы тайлов для разных локаций
enum TileSet: String, CaseIterable {
    case burningVillage = "burning_village"     // Level 1: light stone blocks, wood, fire
    case bridgesOfAbyss = "bridges_of_abyss"    // Level 2: dark stone, chains, clouds
    case worldRoots = "world_roots"             // Level 3: wood, bark, mushrooms, vines
    case catacombs = "catacombs"                // Level 4: tombs, gold, torches
    case stormPeaks = "storm_peaks"             // Level 5: ice, snow, frozen stone
    case seaOfShards = "sea_of_shards"          // Level 6: floating stones, sky, ruins
    case citadelGates = "citadel_gates"         // Level 7: black stone, chains, banners
    case citadelHeart = "citadel_heart"         // Level 8: runes, columns, magic
    case throneHall = "throne_hall"             // Level 9: throne, darkness, chains
    case awakening = "awakening"                // Level 10: chaos, abyss, light

    /// Соответствие набора тайлов номеру уровня
    static func forLevel(_ levelId: Int) -> TileSet {
        switch levelId {
        case 1: return .burningVillage
        case 2: return .bridgesOfAbyss
        case 3: return .worldRoots
        case 4: return .catacombs
        case 5: return .stormPeaks
        case 6: return .seaOfShards
        case 7: return .citadelGates
        case 8: return .citadelHeart
        case 9: return .throneHall
        case 10: return .awakening
        default: return .burningVillage
        }
    }

    /// Локализованное название локации
    var displayName: String {
        switch self {
        case .burningVillage: return "Горящая деревня"
        case .bridgesOfAbyss: return "Мосты Бездны"
        case .worldRoots: return "Корни Мира"
        case .catacombs: return "Катакомбы Аурелиона"
        case .stormPeaks: return "Грозовые пики"
        case .seaOfShards: return "Море Осколков"
        case .citadelGates: return "Врата Цитадели"
        case .citadelHeart: return "Сердце Цитадели"
        case .throneHall: return "Тронный зал Бездны"
        case .awakening: return "Пробуждение"
        }
    }
}

// MARK: - TileData

/// Данные тайла для создания спрайтов
struct TileData {
    let tileType: TileType
    let tileSet: TileSet

    /// Имя текстуры на основе типа тайла и набора
    var textureName: String {
        return "\(tileSet.rawValue)_\(tileType.rawValue)"
    }

    var isCollidable: Bool {
        return tileType.isCollidable
    }

    var isSemiSolid: Bool {
        return tileType.isSemiSolid
    }

    var damageOnContact: Int {
        return tileType.damageOnContact
    }

    init(type: TileType, set: TileSet) {
        self.tileType = type
        self.tileSet = set
    }
}

// MARK: - SKColor Extension for Placeholder Colors

extension SKColor {

    /// Цветовая схема для набора тайлов
    struct TileSetColors {
        let primary: SKColor
        let secondary: SKColor
        let accent: SKColor
    }

    /// Получить цветовую схему для набора тайлов
    static func colors(for tileSet: TileSet) -> TileSetColors {
        switch tileSet {
        case .burningVillage:
            return TileSetColors(
                primary: SKColor(red: 0.55, green: 0.35, blue: 0.2, alpha: 1.0),    // Brown (stone/wood)
                secondary: SKColor(red: 0.9, green: 0.5, blue: 0.1, alpha: 1.0),    // Orange (fire)
                accent: SKColor(red: 0.9, green: 0.2, blue: 0.1, alpha: 1.0)        // Red (flames)
            )
        case .bridgesOfAbyss:
            return TileSetColors(
                primary: SKColor(red: 0.3, green: 0.3, blue: 0.35, alpha: 1.0),     // Dark gray stone
                secondary: SKColor(red: 0.15, green: 0.15, blue: 0.25, alpha: 1.0), // Dark blue
                accent: SKColor(red: 0.4, green: 0.3, blue: 0.5, alpha: 1.0)        // Purple mist
            )
        case .worldRoots:
            return TileSetColors(
                primary: SKColor(red: 0.3, green: 0.5, blue: 0.25, alpha: 1.0),     // Green (moss)
                secondary: SKColor(red: 0.45, green: 0.3, blue: 0.2, alpha: 1.0),   // Brown (bark)
                accent: SKColor(red: 0.8, green: 0.7, blue: 0.3, alpha: 1.0)        // Yellow (mushrooms)
            )
        case .catacombs:
            return TileSetColors(
                primary: SKColor(red: 0.4, green: 0.4, blue: 0.4, alpha: 1.0),      // Gray stone
                secondary: SKColor(red: 0.8, green: 0.65, blue: 0.2, alpha: 1.0),   // Gold
                accent: SKColor(red: 0.15, green: 0.1, blue: 0.1, alpha: 1.0)       // Dark shadow
            )
        case .stormPeaks:
            return TileSetColors(
                primary: SKColor(red: 0.9, green: 0.95, blue: 1.0, alpha: 1.0),     // White snow
                secondary: SKColor(red: 0.6, green: 0.8, blue: 0.95, alpha: 1.0),   // Light blue ice
                accent: SKColor(red: 0.5, green: 0.55, blue: 0.6, alpha: 1.0)       // Gray rock
            )
        case .seaOfShards:
            return TileSetColors(
                primary: SKColor(red: 0.6, green: 0.75, blue: 0.9, alpha: 1.0),     // Light blue sky
                secondary: SKColor(red: 0.95, green: 0.95, blue: 1.0, alpha: 1.0),  // White clouds
                accent: SKColor(red: 0.9, green: 0.75, blue: 0.4, alpha: 1.0)       // Gold ruins
            )
        case .citadelGates:
            return TileSetColors(
                primary: SKColor(red: 0.15, green: 0.15, blue: 0.2, alpha: 1.0),    // Black stone
                secondary: SKColor(red: 0.7, green: 0.15, blue: 0.15, alpha: 1.0),  // Dark red
                accent: SKColor(red: 0.4, green: 0.4, blue: 0.45, alpha: 1.0)       // Iron gray
            )
        case .citadelHeart:
            return TileSetColors(
                primary: SKColor(red: 0.15, green: 0.1, blue: 0.25, alpha: 1.0),    // Dark purple
                secondary: SKColor(red: 0.4, green: 0.2, blue: 0.5, alpha: 1.0),    // Purple magic
                accent: SKColor(red: 0.9, green: 0.75, blue: 0.3, alpha: 1.0)       // Gold runes
            )
        case .throneHall:
            return TileSetColors(
                primary: SKColor(red: 0.1, green: 0.05, blue: 0.1, alpha: 1.0),     // Deep black
                secondary: SKColor(red: 0.35, green: 0.15, blue: 0.4, alpha: 1.0),  // Dark purple
                accent: SKColor(red: 0.6, green: 0.1, blue: 0.15, alpha: 1.0)       // Blood red
            )
        case .awakening:
            return TileSetColors(
                primary: SKColor(red: 0.3, green: 0.15, blue: 0.4, alpha: 1.0),     // Purple chaos
                secondary: SKColor(red: 0.95, green: 0.85, blue: 0.5, alpha: 1.0),  // Golden light
                accent: SKColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)        // Pure white
            )
        }
    }

    /// Цвет для конкретного типа тайла в наборе
    static func color(for tileType: TileType, in tileSet: TileSet) -> SKColor {
        let colors = colors(for: tileSet)

        switch tileType {
        // Ground tiles use primary color
        case .groundTop, .groundMiddle, .groundBottom, .groundLeftEdge, .groundRightEdge,
             .groundTopLeftCorner, .groundTopRightCorner, .groundBottomLeftCorner,
             .groundBottomRightCorner, .groundSingle:
            return colors.primary

        // Platforms use secondary color
        case .platformThin, .platformThick:
            return colors.secondary

        // Walls use primary color with slight variation
        case .wallLeft, .wallRight, .wallFull:
            return colors.primary.withAlphaComponent(0.9)

        // Hazards use accent color
        case .hazardSpikes:
            return colors.accent
        case .hazardLava:
            return SKColor(red: 1.0, green: 0.4, blue: 0.1, alpha: 1.0) // Always orange-red
        case .hazardVoid:
            return SKColor(red: 0.1, green: 0.0, blue: 0.15, alpha: 0.8) // Dark purple void

        // Decorations use accent color
        case .decorGrass, .decorStone, .decorTorch, .decorBanner, .decorDebris, .decorChain:
            return colors.accent
        }
    }
}

// MARK: - Tile Index Mapping

extension TileType {
    /// Индекс тайла для tile map (используется в TileMapLoader)
    var index: Int {
        switch self {
        // Ground: 0-9
        case .groundTop: return 0
        case .groundMiddle: return 1
        case .groundBottom: return 2
        case .groundLeftEdge: return 3
        case .groundRightEdge: return 4
        case .groundTopLeftCorner: return 5
        case .groundTopRightCorner: return 6
        case .groundBottomLeftCorner: return 7
        case .groundBottomRightCorner: return 8
        case .groundSingle: return 9

        // Platforms: 10-11
        case .platformThin: return 10
        case .platformThick: return 11

        // Walls: 12-14
        case .wallLeft: return 12
        case .wallRight: return 13
        case .wallFull: return 14

        // Hazards: 15-17
        case .hazardSpikes: return 15
        case .hazardLava: return 16
        case .hazardVoid: return 17

        // Decorations: 18-23
        case .decorGrass: return 18
        case .decorStone: return 19
        case .decorTorch: return 20
        case .decorBanner: return 21
        case .decorDebris: return 22
        case .decorChain: return 23
        }
    }

    /// Создать TileType из индекса
    static func from(index: Int) -> TileType? {
        return TileType.allCases.first { $0.index == index }
    }
}
