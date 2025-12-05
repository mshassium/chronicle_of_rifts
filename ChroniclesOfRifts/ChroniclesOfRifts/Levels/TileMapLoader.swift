import SpriteKit

// MARK: - Tile Map Data Structures

/// Данные карты тайлов (загружаются из JSON)
struct TileMapData: Codable {
    let width: Int
    let height: Int
    let tileSize: CGFloat
    let layers: [TileLayerData]

    init(width: Int, height: Int, tileSize: CGFloat = 32, layers: [TileLayerData]) {
        self.width = width
        self.height = height
        self.tileSize = tileSize
        self.layers = layers
    }

    enum CodingKeys: String, CodingKey {
        case width, height, tileSize, layers
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        width = try container.decode(Int.self, forKey: .width)
        height = try container.decode(Int.self, forKey: .height)
        tileSize = try container.decodeIfPresent(CGFloat.self, forKey: .tileSize) ?? 32
        layers = try container.decode([TileLayerData].self, forKey: .layers)
    }
}

/// Данные слоя тайлов
struct TileLayerData: Codable {
    let name: String
    let zPosition: CGFloat
    let tiles: [[Int]]

    init(name: String, zPosition: CGFloat, tiles: [[Int]]) {
        self.name = name
        self.zPosition = zPosition
        self.tiles = tiles
    }
}

// MARK: - TileMapLoader

/// Загрузчик и построитель карт тайлов
class TileMapLoader {

    // MARK: - Properties

    let tileSet: TileSet
    let tileSize: CGFloat

    // MARK: - Constants

    struct NodeNames {
        static let tileMapContainer = "tileMap"
        static let groundLayer = "ground"
        static let decorationLayer = "decoration"
        static let hazardsLayer = "hazards"
    }

    // MARK: - Autotiling Bitmask

    /// Биты для соседей (используется в автотайлинге)
    /// 7 0 1
    /// 6 X 2
    /// 5 4 3
    private struct NeighborBits {
        static let top: UInt8 = 1 << 0
        static let topRight: UInt8 = 1 << 1
        static let right: UInt8 = 1 << 2
        static let bottomRight: UInt8 = 1 << 3
        static let bottom: UInt8 = 1 << 4
        static let bottomLeft: UInt8 = 1 << 5
        static let left: UInt8 = 1 << 6
        static let topLeft: UInt8 = 1 << 7
    }

    // MARK: - Initialization

    init(tileSet: TileSet, tileSize: CGFloat = 32) {
        self.tileSet = tileSet
        self.tileSize = tileSize
    }

    // MARK: - Loading

    /// Загрузить карту тайлов из JSON файла
    func loadTileMap(named name: String) -> TileMapData? {
        guard let url = Bundle.main.url(forResource: name, withExtension: "json") else {
            print("TileMapLoader: Could not find \(name).json")
            return nil
        }

        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let tileMapData = try decoder.decode(TileMapData.self, from: data)
            return tileMapData
        } catch {
            print("TileMapLoader: Failed to decode \(name).json - \(error)")
            return nil
        }
    }

    // MARK: - Building

    /// Построить карту тайлов в родительской ноде
    func buildTileMap(from data: TileMapData, in parentNode: SKNode) {
        let container = SKNode()
        container.name = NodeNames.tileMapContainer
        parentNode.addChild(container)

        for layerData in data.layers {
            let layerNode = SKNode()
            layerNode.name = layerData.name
            layerNode.zPosition = layerData.zPosition
            container.addChild(layerNode)

            // Применяем автотайлинг для ground слоя
            let processedTiles: [[Int]]
            if layerData.name == NodeNames.groundLayer {
                processedTiles = applyAutotiling(tiles: layerData.tiles)
            } else {
                processedTiles = layerData.tiles
            }

            // Строим тайлы
            for (rowIndex, row) in processedTiles.enumerated() {
                for (colIndex, tileIndex) in row.enumerated() {
                    // Конвертируем координаты (JSON хранит сверху вниз, SpriteKit снизу вверх)
                    let flippedRow = data.height - 1 - rowIndex
                    let position = CGPoint(
                        x: CGFloat(colIndex) * data.tileSize + data.tileSize / 2,
                        y: CGFloat(flippedRow) * data.tileSize + data.tileSize / 2
                    )

                    if let tileNode = createTileNode(tileIndex: tileIndex, at: position) {
                        layerNode.addChild(tileNode)
                    }
                }
            }
        }
    }

    /// Создать ноду тайла
    func createTileNode(tileIndex: Int, at position: CGPoint) -> SKNode? {
        // Пустой тайл
        guard tileIndex >= 0 else { return nil }

        // Получаем тип тайла
        guard let tileType = tileTypeFromIndex(tileIndex) else {
            print("TileMapLoader: Unknown tile index \(tileIndex)")
            return nil
        }

        let size = CGSize(width: tileSize, height: tileSize)

        // Создаём спрайт с placeholder текстурой
        let texture = PlaceholderTextures.createTileTexture(type: tileType, tileSet: tileSet, size: size)
        let sprite = SKSpriteNode(texture: texture, size: size)
        sprite.position = position
        sprite.name = "tile_\(tileType.rawValue)"

        // Настраиваем физику
        setupTilePhysics(for: sprite, tileType: tileType)

        return sprite
    }

    // MARK: - Private Methods

    /// Преобразовать индекс в тип тайла
    private func tileTypeFromIndex(_ index: Int) -> TileType? {
        return TileType.from(index: index)
    }

    /// Настроить физику для тайла
    private func setupTilePhysics(for node: SKSpriteNode, tileType: TileType) {
        guard tileType.isCollidable || tileType.isHazard else { return }

        let physicsBody = SKPhysicsBody(rectangleOf: node.size)
        physicsBody.isDynamic = false

        if tileType.isHazard {
            // Hazards are sensors
            physicsBody.categoryBitMask = PhysicsCategory.hazard
            physicsBody.contactTestBitMask = PhysicsCategory.player
            physicsBody.collisionBitMask = 0

            node.userData = [
                "damage": tileType.damageOnContact,
                "hazardType": tileType.rawValue
            ]
        } else if tileType.isSemiSolid {
            // One-way platforms
            physicsBody.categoryBitMask = PhysicsCategory.ground
            physicsBody.contactTestBitMask = PhysicsCategory.player
            physicsBody.collisionBitMask = 0 // Handled in game logic

            node.userData = ["oneWay": true]
        } else {
            // Solid collision
            physicsBody.categoryBitMask = PhysicsCategory.ground
            physicsBody.contactTestBitMask = PhysicsCategory.player
            physicsBody.collisionBitMask = PhysicsCategory.player | PhysicsCategory.enemy
        }

        node.physicsBody = physicsBody
    }

    /// Применить автотайлинг для определения углов и краёв
    private func applyAutotiling(tiles: [[Int]]) -> [[Int]] {
        guard !tiles.isEmpty, !tiles[0].isEmpty else { return tiles }

        var result = tiles
        let height = tiles.count
        let width = tiles[0].count

        for row in 0..<height {
            for col in 0..<width {
                let currentTile = tiles[row][col]

                // Пропускаем пустые тайлы и не-ground тайлы
                guard currentTile >= 0 && currentTile <= 9 else { continue }

                // Получаем маску соседей
                let neighborMask = getNeighborMask(tiles: tiles, row: row, col: col, width: width, height: height)

                // Определяем правильный тип тайла на основе соседей
                result[row][col] = determineTileIndex(baseTile: currentTile, neighbors: neighborMask)
            }
        }

        return result
    }

    /// Получить битовую маску соседей
    private func getNeighborMask(tiles: [[Int]], row: Int, col: Int, width: Int, height: Int) -> UInt8 {
        var mask: UInt8 = 0

        // Проверяем является ли тайл "твёрдым" (ground тайл)
        func isSolid(_ r: Int, _ c: Int) -> Bool {
            guard r >= 0 && r < height && c >= 0 && c < width else { return false }
            let tile = tiles[r][c]
            return tile >= 0 && tile <= 9 // Ground tiles: 0-9
        }

        // Top
        if isSolid(row - 1, col) { mask |= NeighborBits.top }
        // Top-Right
        if isSolid(row - 1, col + 1) { mask |= NeighborBits.topRight }
        // Right
        if isSolid(row, col + 1) { mask |= NeighborBits.right }
        // Bottom-Right
        if isSolid(row + 1, col + 1) { mask |= NeighborBits.bottomRight }
        // Bottom
        if isSolid(row + 1, col) { mask |= NeighborBits.bottom }
        // Bottom-Left
        if isSolid(row + 1, col - 1) { mask |= NeighborBits.bottomLeft }
        // Left
        if isSolid(row, col - 1) { mask |= NeighborBits.left }
        // Top-Left
        if isSolid(row - 1, col - 1) { mask |= NeighborBits.topLeft }

        return mask
    }

    /// Определить индекс тайла на основе соседей
    private func determineTileIndex(baseTile: Int, neighbors: UInt8) -> Int {
        let hasTop = (neighbors & NeighborBits.top) != 0
        let hasBottom = (neighbors & NeighborBits.bottom) != 0
        let hasLeft = (neighbors & NeighborBits.left) != 0
        let hasRight = (neighbors & NeighborBits.right) != 0

        // Single tile (no neighbors)
        if !hasTop && !hasBottom && !hasLeft && !hasRight {
            return TileType.groundSingle.index
        }

        // Top surface (no tile above)
        if !hasTop {
            if !hasLeft && !hasRight {
                return TileType.groundTop.index // Only top, no sides
            }
            if !hasLeft {
                return TileType.groundTopLeftCorner.index // Top-left corner
            }
            if !hasRight {
                return TileType.groundTopRightCorner.index // Top-right corner
            }
            return TileType.groundTop.index // Standard top
        }

        // Bottom surface (no tile below)
        if !hasBottom {
            if !hasLeft {
                return TileType.groundBottomLeftCorner.index
            }
            if !hasRight {
                return TileType.groundBottomRightCorner.index
            }
            return TileType.groundBottom.index
        }

        // Left edge
        if !hasLeft {
            return TileType.groundLeftEdge.index
        }

        // Right edge
        if !hasRight {
            return TileType.groundRightEdge.index
        }

        // Middle (surrounded by tiles)
        return TileType.groundMiddle.index
    }
}

// MARK: - LevelLoader Integration

extension LevelLoader {

    /// Загрузить и построить тайловую карту для уровня
    func buildTileMap(levelId: Int, in parentNode: SKNode, tileSize: CGFloat = 32) {
        let tileSet = TileSet.forLevel(levelId)
        let loader = TileMapLoader(tileSet: tileSet, tileSize: tileSize)

        if let tileMapData = loader.loadTileMap(named: "level_\(levelId)_tiles") {
            loader.buildTileMap(from: tileMapData, in: parentNode)
        } else {
            print("LevelLoader: No tile map found for level \(levelId)")
        }
    }
}
