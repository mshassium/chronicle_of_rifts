import SpriteKit

/// Слой параллакс-фона
struct ParallaxLayer {
    /// Нода слоя
    let node: SKNode

    /// Фактор параллакса (0.0 = не двигается, 1.0 = двигается с камерой)
    let parallaxFactor: CGFloat

    /// Повторять по горизонтали
    let repeatX: Bool

    /// Повторять по вертикали
    let repeatY: Bool

    /// Ширина одного тайла (для repeatX)
    let tileWidth: CGFloat

    /// Высота одного тайла (для repeatY)
    let tileHeight: CGFloat
}

/// Управление параллакс-фоном
class ParallaxBackground {
    // MARK: - Properties

    /// Все слои параллакса
    private(set) var layers: [ParallaxLayer] = []

    /// Родительская нода для слоёв
    private weak var parentNode: SKNode?

    /// Размер viewport
    var viewportSize: CGSize = .zero

    /// Начальная позиция камеры (для расчёта смещения)
    private var initialCameraPosition: CGPoint = .zero

    /// Установлена ли начальная позиция
    private var isInitialized: Bool = false

    // MARK: - Initialization

    /// Инициализация с родительской нодой
    /// - Parameter parentNode: Нода, к которой будут добавляться слои (обычно backgroundLayer)
    init(parentNode: SKNode) {
        self.parentNode = parentNode
    }

    // MARK: - Layer Management

    /// Добавить слой параллакса
    /// - Parameters:
    ///   - imageName: Имя изображения в ассетах
    ///   - parallaxFactor: Фактор параллакса (0.0-1.0)
    ///   - zPosition: Z-позиция слоя
    ///   - repeatX: Повторять по горизонтали
    ///   - repeatY: Повторять по вертикали
    func addLayer(
        imageName: String,
        parallaxFactor: CGFloat,
        zPosition: CGFloat,
        repeatX: Bool = true,
        repeatY: Bool = false
    ) {
        guard let parentNode = parentNode else { return }

        // Создаём контейнер для слоя
        let containerNode = SKNode()
        containerNode.name = "parallaxLayer_\(imageName)"
        containerNode.zPosition = zPosition

        // Создаём основной спрайт
        let texture = SKTexture(imageNamed: imageName)
        let sprite = SKSpriteNode(texture: texture)
        sprite.anchorPoint = CGPoint(x: 0.5, y: 0.5)

        let tileWidth = sprite.size.width
        let tileHeight = sprite.size.height

        if repeatX || repeatY {
            // Для бесконечного скроллинга создаём несколько копий
            let horizontalCount = repeatX ? Int(ceil(viewportSize.width / tileWidth)) + 3 : 1
            let verticalCount = repeatY ? Int(ceil(viewportSize.height / tileHeight)) + 3 : 1

            for x in 0..<horizontalCount {
                for y in 0..<verticalCount {
                    let tileSprite = SKSpriteNode(texture: texture)
                    tileSprite.anchorPoint = CGPoint(x: 0.5, y: 0.5)

                    // Позиционируем тайлы относительно центра
                    let offsetX = CGFloat(x - horizontalCount / 2) * tileWidth
                    let offsetY = CGFloat(y - verticalCount / 2) * tileHeight
                    tileSprite.position = CGPoint(x: offsetX, y: offsetY)
                    tileSprite.name = "tile_\(x)_\(y)"

                    containerNode.addChild(tileSprite)
                }
            }
        } else {
            containerNode.addChild(sprite)
        }

        parentNode.addChild(containerNode)

        let layer = ParallaxLayer(
            node: containerNode,
            parallaxFactor: parallaxFactor,
            repeatX: repeatX,
            repeatY: repeatY,
            tileWidth: tileWidth,
            tileHeight: tileHeight
        )

        layers.append(layer)
    }

    /// Добавить слой с произвольной нодой
    /// - Parameters:
    ///   - node: Нода слоя
    ///   - parallaxFactor: Фактор параллакса
    ///   - zPosition: Z-позиция
    func addLayer(node: SKNode, parallaxFactor: CGFloat, zPosition: CGFloat) {
        guard let parentNode = parentNode else { return }

        node.zPosition = zPosition
        parentNode.addChild(node)

        let layer = ParallaxLayer(
            node: node,
            parallaxFactor: parallaxFactor,
            repeatX: false,
            repeatY: false,
            tileWidth: 0,
            tileHeight: 0
        )

        layers.append(layer)
    }

    // MARK: - Update

    /// Обновить позиции слоёв относительно камеры
    /// - Parameter cameraPosition: Текущая позиция камеры
    func update(cameraPosition: CGPoint) {
        // Инициализируем начальную позицию при первом вызове
        if !isInitialized {
            initialCameraPosition = cameraPosition
            isInitialized = true
        }

        // Смещение камеры от начальной позиции
        let cameraOffset = CGPoint(
            x: cameraPosition.x - initialCameraPosition.x,
            y: cameraPosition.y - initialCameraPosition.y
        )

        for layer in layers {
            // Позиция слоя = противоположное движение камеры * (1 - фактор)
            // При факторе 0 - слой не двигается (небо)
            // При факторе 1 - слой двигается с камерой (передний план)
            let layerOffset = CGPoint(
                x: -cameraOffset.x * (1.0 - layer.parallaxFactor),
                y: -cameraOffset.y * (1.0 - layer.parallaxFactor)
            )

            // Базовая позиция слоя следует за камерой
            var newPosition = CGPoint(
                x: cameraPosition.x + layerOffset.x,
                y: cameraPosition.y + layerOffset.y
            )

            // Для бесконечного скроллинга корректируем позицию
            if layer.repeatX && layer.tileWidth > 0 {
                // Смещаем контейнер так, чтобы он всегда был около камеры
                let wrappedX = cameraOffset.x.truncatingRemainder(dividingBy: layer.tileWidth)
                newPosition.x = cameraPosition.x - wrappedX * (1.0 - layer.parallaxFactor)
            }

            if layer.repeatY && layer.tileHeight > 0 {
                let wrappedY = cameraOffset.y.truncatingRemainder(dividingBy: layer.tileHeight)
                newPosition.y = cameraPosition.y - wrappedY * (1.0 - layer.parallaxFactor)
            }

            layer.node.position = newPosition
        }
    }

    /// Сбросить начальную позицию (вызывать при смене уровня)
    func reset() {
        isInitialized = false
    }

    /// Удалить все слои
    func removeAllLayers() {
        for layer in layers {
            layer.node.removeFromParent()
        }
        layers.removeAll()
        isInitialized = false
    }
}
