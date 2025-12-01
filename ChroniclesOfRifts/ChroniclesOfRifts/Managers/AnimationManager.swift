import SpriteKit
import UIKit

// MARK: - AnimationData

/// Данные одной анимации
struct AnimationData {
    let name: String
    let frames: [SKTexture]
    let timePerFrame: TimeInterval
    let repeatForever: Bool

    /// Создаёт SKAction для этой анимации
    func toAction() -> SKAction {
        let animate = SKAction.animate(with: frames, timePerFrame: timePerFrame)
        if repeatForever {
            return SKAction.repeatForever(animate)
        } else {
            return animate
        }
    }
}

// MARK: - PlayerAnimationConfig

/// Конфигурация анимаций для Player
struct PlayerAnimationConfig {
    static let animations: [(name: String, frames: Int, timePerFrame: TimeInterval, repeats: Bool)] = [
        ("idle", 4, 0.2, true),      // 4 кадра, 0.2 сек каждый, зациклено
        ("walk", 6, 0.1, true),      // 6 кадров, 0.1 сек, зациклено
        ("jump", 2, 0.15, false),    // 2 кадра, без цикла
        ("fall", 2, 0.15, false),    // 2 кадра, без цикла
        ("attack", 4, 0.08, false),  // 4 кадра, быстрая, без цикла
        ("hurt", 2, 0.1, false),     // 2 кадра, без цикла
        ("death", 6, 0.12, false)    // 6 кадров, без цикла
    ]

    static let size = CGSize(width: 32, height: 64)
    static let color = UIColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 1.0) // Gold
}

// MARK: - AnimationManager

/// Менеджер анимаций (синглтон)
/// Управляет загрузкой, кэшированием и созданием анимаций для игровых сущностей
final class AnimationManager {

    // MARK: - Singleton

    /// Единственный экземпляр AnimationManager
    static let shared = AnimationManager()

    // MARK: - Cache

    /// Кэш загруженных анимаций: [entityType_animationName: AnimationData]
    private var animationCache: [String: AnimationData] = [:]

    /// Кэш текстурных атласов
    private var atlasCache: [String: SKTextureAtlas] = [:]

    // MARK: - Initialization

    private init() {
        // Создаём placeholder анимации для игрока
        setupPlayerPlaceholderAnimations()
    }

    // MARK: - Setup

    /// Создаёт placeholder анимации для игрока при инициализации
    private func setupPlayerPlaceholderAnimations() {
        for config in PlayerAnimationConfig.animations {
            let textures = createPlaceholderTextures(
                for: "player",
                animationName: config.name,
                frameCount: config.frames,
                size: PlayerAnimationConfig.size,
                color: PlayerAnimationConfig.color
            )

            let animationData = AnimationData(
                name: config.name,
                frames: textures,
                timePerFrame: config.timePerFrame,
                repeatForever: config.repeats
            )

            let key = "player_\(config.name)"
            animationCache[key] = animationData
        }
    }

    // MARK: - Loading

    /// Загрузить все анимации для типа сущности
    /// - Parameter entityType: Тип сущности (player, cultist, etc.)
    func preloadAnimations(for entityType: String) {
        // Пытаемся загрузить атлас для сущности
        guard let atlas = loadAtlas(named: entityType) else {
            print("AnimationManager: Атлас '\(entityType)' не найден, используются placeholder")
            return
        }

        // Получаем список текстур из атласа
        let textureNames = atlas.textureNames

        // Группируем текстуры по анимациям (формат: entityType_animationName_frameIndex)
        var animationGroups: [String: [String]] = [:]

        for textureName in textureNames {
            // Удаляем расширение файла если есть
            let baseName = textureName.replacingOccurrences(of: ".png", with: "")
                                      .replacingOccurrences(of: ".jpg", with: "")

            // Ищем последний underscore для отделения номера кадра
            if let lastUnderscoreIndex = baseName.lastIndex(of: "_") {
                let prefix = String(baseName[..<lastUnderscoreIndex])
                if animationGroups[prefix] == nil {
                    animationGroups[prefix] = []
                }
                animationGroups[prefix]?.append(textureName)
            }
        }

        // Создаём AnimationData для каждой группы
        for (prefix, frameNames) in animationGroups {
            let frames = extractFrames(from: atlas, prefix: prefix + "_")

            guard !frames.isEmpty else { continue }

            // Извлекаем имя анимации из префикса (формат: entityType_animationName)
            let components = prefix.split(separator: "_")
            guard components.count >= 2 else { continue }

            let animationName = String(components.dropFirst().joined(separator: "_"))
            let key = "\(entityType)_\(animationName)"

            // Определяем параметры анимации (по умолчанию)
            let timePerFrame: TimeInterval = 0.1
            let repeatForever = animationName == "idle" || animationName == "walk"

            let animationData = AnimationData(
                name: animationName,
                frames: frames,
                timePerFrame: timePerFrame,
                repeatForever: repeatForever
            )

            animationCache[key] = animationData
        }
    }

    /// Получить анимацию по ключу
    /// - Parameters:
    ///   - name: Имя анимации (idle, walk, jump, etc.)
    ///   - entityType: Тип сущности
    /// - Returns: AnimationData или nil
    func getAnimation(name: String, for entityType: String) -> AnimationData? {
        let key = "\(entityType)_\(name)"
        return animationCache[key]
    }

    /// Создать SKAction для анимации
    /// - Parameters:
    ///   - name: Имя анимации
    ///   - entityType: Тип сущности
    /// - Returns: SKAction или nil
    func createAnimationAction(name: String, for entityType: String) -> SKAction? {
        return getAnimation(name: name, for: entityType)?.toAction()
    }

    // MARK: - Placeholder Generation

    /// Создать placeholder текстуры для тестирования
    /// - Parameters:
    ///   - entityType: Тип сущности
    ///   - animationName: Имя анимации
    ///   - frameCount: Количество кадров
    ///   - size: Размер кадра
    ///   - color: Базовый цвет
    /// - Returns: Массив текстур
    func createPlaceholderTextures(
        for entityType: String,
        animationName: String,
        frameCount: Int,
        size: CGSize,
        color: UIColor
    ) -> [SKTexture] {
        var textures: [SKTexture] = []

        for i in 0..<frameCount {
            let texture = generatePlaceholderFrame(
                size: size,
                color: color,
                frameIndex: i,
                totalFrames: frameCount,
                animationName: animationName
            )
            textures.append(texture)
        }

        return textures
    }

    /// Генерирует один кадр placeholder анимации
    /// - Parameters:
    ///   - size: Размер кадра
    ///   - color: Базовый цвет
    ///   - frameIndex: Индекс текущего кадра
    ///   - totalFrames: Общее количество кадров
    ///   - animationName: Имя анимации (для визуальной идентификации)
    /// - Returns: Текстура кадра
    private func generatePlaceholderFrame(
        size: CGSize,
        color: UIColor,
        frameIndex: Int,
        totalFrames: Int,
        animationName: String
    ) -> SKTexture {
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
            // Фон - основной цвет с небольшой вариацией по кадрам
            let brightness = 0.8 + (CGFloat(frameIndex) / CGFloat(max(totalFrames, 1))) * 0.2
            let adjustedColor = color.withAlphaComponent(brightness)
            adjustedColor.setFill()
            context.fill(CGRect(origin: .zero, size: size))

            // Визуальная индикация анимации - рамка
            UIColor.black.setStroke()
            let rect = CGRect(origin: .zero, size: size).insetBy(dx: 2, dy: 2)
            context.stroke(rect)

            // Индикатор кадра (полоска внизу)
            let indicatorWidth = (size.width - 4) / CGFloat(max(totalFrames, 1))
            let indicatorRect = CGRect(
                x: 2 + indicatorWidth * CGFloat(frameIndex),
                y: size.height - 6,
                width: indicatorWidth,
                height: 4
            )
            UIColor.white.setFill()
            context.fill(indicatorRect)

            // Первая буква анимации в центре для идентификации
            let letter = String(animationName.prefix(1)).uppercased()
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: min(size.width, size.height) * 0.4),
                .foregroundColor: UIColor.black
            ]
            let textSize = letter.size(withAttributes: attributes)
            let textRect = CGRect(
                x: (size.width - textSize.width) / 2,
                y: (size.height - textSize.height) / 2 - 4,
                width: textSize.width,
                height: textSize.height
            )
            letter.draw(in: textRect, withAttributes: attributes)
        }
        return SKTexture(image: image)
    }

    // MARK: - Atlas Loading

    /// Загрузить текстурный атлас
    /// - Parameter name: Имя атласа
    /// - Returns: SKTextureAtlas или nil если не найден
    private func loadAtlas(named name: String) -> SKTextureAtlas? {
        // Проверяем кэш
        if let cachedAtlas = atlasCache[name] {
            return cachedAtlas
        }

        // Пытаемся загрузить атлас
        let atlas = SKTextureAtlas(named: name)

        // Проверяем, есть ли текстуры в атласе
        guard !atlas.textureNames.isEmpty else {
            return nil
        }

        // Кэшируем
        atlasCache[name] = atlas
        return atlas
    }

    /// Извлечь кадры из атласа по префиксу
    /// - Parameters:
    ///   - atlas: Текстурный атлас
    ///   - prefix: Префикс имён текстур (например "player_walk_")
    /// - Returns: Отсортированный массив текстур
    private func extractFrames(from atlas: SKTextureAtlas, prefix: String) -> [SKTexture] {
        // Фильтруем текстуры по префиксу
        let matchingNames = atlas.textureNames.filter { $0.hasPrefix(prefix) }

        // Сортируем по номеру кадра
        let sortedNames = matchingNames.sorted { name1, name2 in
            let suffix1 = name1.dropFirst(prefix.count)
            let suffix2 = name2.dropFirst(prefix.count)

            // Извлекаем числовую часть
            let num1 = Int(suffix1.replacingOccurrences(of: ".png", with: "")
                                  .replacingOccurrences(of: ".jpg", with: "")) ?? 0
            let num2 = Int(suffix2.replacingOccurrences(of: ".png", with: "")
                                  .replacingOccurrences(of: ".jpg", with: "")) ?? 0

            return num1 < num2
        }

        // Создаём текстуры
        return sortedNames.map { atlas.textureNamed($0) }
    }

    // MARK: - Cache Management

    /// Очистить кэш анимаций для указанного типа сущности
    /// - Parameter entityType: Тип сущности или nil для очистки всего кэша
    func clearCache(for entityType: String? = nil) {
        if let entityType = entityType {
            // Очищаем только анимации указанного типа
            let keysToRemove = animationCache.keys.filter { $0.hasPrefix("\(entityType)_") }
            for key in keysToRemove {
                animationCache.removeValue(forKey: key)
            }
            atlasCache.removeValue(forKey: entityType)
        } else {
            // Очищаем весь кэш
            animationCache.removeAll()
            atlasCache.removeAll()
        }
    }

    /// Получить список всех загруженных анимаций
    /// - Returns: Массив ключей кэша
    func loadedAnimations() -> [String] {
        return Array(animationCache.keys).sorted()
    }

    /// Проверить, загружена ли анимация
    /// - Parameters:
    ///   - name: Имя анимации
    ///   - entityType: Тип сущности
    /// - Returns: true если анимация загружена
    func isAnimationLoaded(name: String, for entityType: String) -> Bool {
        let key = "\(entityType)_\(name)"
        return animationCache[key] != nil
    }
}
