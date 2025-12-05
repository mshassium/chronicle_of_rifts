import SpriteKit
import UIKit

/// Генератор placeholder текстур для тайлов
class PlaceholderTextures {

    // MARK: - Texture Cache

    private static let textureCache = NSCache<NSString, SKTexture>()

    // MARK: - Public Methods

    /// Создать текстуру для тайла
    static func createTileTexture(type: TileType, tileSet: TileSet, size: CGSize = CGSize(width: 32, height: 32)) -> SKTexture {
        let cacheKey = "\(tileSet.rawValue)_\(type.rawValue)_\(Int(size.width))x\(Int(size.height))" as NSString

        if let cached = textureCache.object(forKey: cacheKey) {
            return cached
        }

        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
            let cgContext = context.cgContext

            if type.isGround || type.isWall {
                drawGroundTile(context: cgContext, type: type, tileSet: tileSet, size: size)
            } else if type.isPlatform {
                let platformType: PlatformType = type == .platformThin ? .oneWay : .solid
                drawPlatformTile(context: cgContext, type: platformType, tileSet: tileSet, size: size)
            } else if type.isHazard {
                drawHazardTile(context: cgContext, hazardType: type.rawValue, size: size)
            } else if type.isDecoration {
                drawDecorationTile(context: cgContext, type: type, tileSet: tileSet, size: size)
            }
        }

        let texture = SKTexture(image: image)
        textureCache.setObject(texture, forKey: cacheKey)

        return texture
    }

    /// Создать текстуру для платформы
    static func createPlatformTexture(type: PlatformType, size: CGSize = CGSize(width: 32, height: 32)) -> SKTexture {
        let cacheKey = "platform_\(type.rawValue)_\(Int(size.width))x\(Int(size.height))" as NSString

        if let cached = textureCache.object(forKey: cacheKey) {
            return cached
        }

        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
            drawPlatformTile(context: context.cgContext, type: type, tileSet: .burningVillage, size: size)
        }

        let texture = SKTexture(image: image)
        textureCache.setObject(texture, forKey: cacheKey)

        return texture
    }

    /// Создать текстуру для hazard
    static func createHazardTexture(type: String, size: CGSize = CGSize(width: 32, height: 32)) -> SKTexture {
        let cacheKey = "hazard_\(type)_\(Int(size.width))x\(Int(size.height))" as NSString

        if let cached = textureCache.object(forKey: cacheKey) {
            return cached
        }

        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
            drawHazardTile(context: context.cgContext, hazardType: type, size: size)
        }

        let texture = SKTexture(image: image)
        textureCache.setObject(texture, forKey: cacheKey)

        return texture
    }

    // MARK: - Private Drawing Methods

    /// Рисование ground тайла
    private static func drawGroundTile(context: CGContext, type: TileType, tileSet: TileSet, size: CGSize) {
        let colors = colorForTileSet(tileSet)
        let rect = CGRect(origin: .zero, size: size)

        // Заливка основным цветом
        context.setFillColor(colors.primary.cgColor)
        context.fill(rect)

        // Добавляем текстуру в зависимости от типа тайла
        context.setStrokeColor(colors.secondary.cgColor)
        context.setLineWidth(1)

        // Рисуем "каменную" текстуру - линии и точки
        let dotSize: CGFloat = 2
        let spacing: CGFloat = 8

        for y in stride(from: spacing, to: size.height, by: spacing) {
            for x in stride(from: spacing, to: size.width, by: spacing) {
                // Небольшой случайный сдвиг для естественности
                let offsetX = CGFloat((Int(x) + Int(y)) % 3) - 1
                let offsetY = CGFloat((Int(x) * 2 + Int(y)) % 3) - 1

                let dotRect = CGRect(
                    x: x + offsetX - dotSize / 2,
                    y: y + offsetY - dotSize / 2,
                    width: dotSize,
                    height: dotSize
                )
                context.setFillColor(colors.secondary.withAlphaComponent(0.3).cgColor)
                context.fillEllipse(in: dotRect)
            }
        }

        // Рисуем границы в зависимости от типа
        context.setStrokeColor(colors.secondary.cgColor)
        context.setLineWidth(2)

        switch type {
        case .groundTop:
            // Верхняя граница (трава/поверхность)
            context.setStrokeColor(colors.accent.cgColor)
            context.move(to: CGPoint(x: 0, y: size.height))
            context.addLine(to: CGPoint(x: size.width, y: size.height))
            context.strokePath()

        case .groundTopLeftCorner:
            context.setStrokeColor(colors.accent.cgColor)
            context.move(to: CGPoint(x: 0, y: 0))
            context.addLine(to: CGPoint(x: 0, y: size.height))
            context.addLine(to: CGPoint(x: size.width, y: size.height))
            context.strokePath()

        case .groundTopRightCorner:
            context.setStrokeColor(colors.accent.cgColor)
            context.move(to: CGPoint(x: 0, y: size.height))
            context.addLine(to: CGPoint(x: size.width, y: size.height))
            context.addLine(to: CGPoint(x: size.width, y: 0))
            context.strokePath()

        case .groundLeftEdge:
            context.move(to: CGPoint(x: 0, y: 0))
            context.addLine(to: CGPoint(x: 0, y: size.height))
            context.strokePath()

        case .groundRightEdge:
            context.move(to: CGPoint(x: size.width, y: 0))
            context.addLine(to: CGPoint(x: size.width, y: size.height))
            context.strokePath()

        case .groundBottomLeftCorner:
            context.move(to: CGPoint(x: 0, y: size.height))
            context.addLine(to: CGPoint(x: 0, y: 0))
            context.addLine(to: CGPoint(x: size.width, y: 0))
            context.strokePath()

        case .groundBottomRightCorner:
            context.move(to: CGPoint(x: 0, y: 0))
            context.addLine(to: CGPoint(x: size.width, y: 0))
            context.addLine(to: CGPoint(x: size.width, y: size.height))
            context.strokePath()

        case .groundBottom:
            context.move(to: CGPoint(x: 0, y: 0))
            context.addLine(to: CGPoint(x: size.width, y: 0))
            context.strokePath()

        case .groundSingle:
            // Все границы
            context.setStrokeColor(colors.accent.cgColor)
            context.stroke(rect.insetBy(dx: 1, dy: 1))

        case .wallLeft, .wallRight, .wallFull:
            // Вертикальные линии для стен
            context.setStrokeColor(colors.secondary.cgColor)
            for x in stride(from: CGFloat(4), to: size.width, by: 8) {
                context.move(to: CGPoint(x: x, y: 0))
                context.addLine(to: CGPoint(x: x, y: size.height))
            }
            context.strokePath()

        default:
            break
        }
    }

    /// Рисование платформы
    private static func drawPlatformTile(context: CGContext, type: PlatformType, tileSet: TileSet, size: CGSize) {
        let colors = colorForTileSet(tileSet)
        let rect = CGRect(origin: .zero, size: size)

        switch type {
        case .oneWay:
            // Тонкая платформа - только верхняя часть
            let platformHeight: CGFloat = size.height * 0.3
            let platformRect = CGRect(x: 0, y: size.height - platformHeight, width: size.width, height: platformHeight)

            context.setFillColor(colors.secondary.cgColor)
            context.fill(platformRect)

            // Горизонтальные линии
            context.setStrokeColor(colors.primary.cgColor)
            context.setLineWidth(1)
            let lineY = size.height - platformHeight / 2
            context.move(to: CGPoint(x: 2, y: lineY))
            context.addLine(to: CGPoint(x: size.width - 2, y: lineY))
            context.strokePath()

            // Стрелка вверх для индикации one-way
            context.setStrokeColor(colors.accent.cgColor)
            context.setLineWidth(2)
            let arrowX = size.width / 2
            let arrowTop = size.height - platformHeight - 4
            let arrowBottom = size.height - platformHeight + 2
            context.move(to: CGPoint(x: arrowX - 4, y: arrowBottom))
            context.addLine(to: CGPoint(x: arrowX, y: arrowTop))
            context.addLine(to: CGPoint(x: arrowX + 4, y: arrowBottom))
            context.strokePath()

        case .solid:
            // Толстая платформа - полная высота
            context.setFillColor(colors.primary.cgColor)
            context.fill(rect)

            // Добавляем текстуру
            context.setStrokeColor(colors.secondary.cgColor)
            context.setLineWidth(1)
            for y in stride(from: CGFloat(8), to: size.height, by: 8) {
                context.move(to: CGPoint(x: 2, y: y))
                context.addLine(to: CGPoint(x: size.width - 2, y: y))
            }
            context.strokePath()

        case .crumbling:
            // Рассыпающаяся платформа - с трещинами
            context.setFillColor(colors.primary.withAlphaComponent(0.8).cgColor)
            context.fill(rect)

            // Трещины
            context.setStrokeColor(UIColor.black.withAlphaComponent(0.5).cgColor)
            context.setLineWidth(1)

            // Диагональные трещины
            context.move(to: CGPoint(x: size.width * 0.2, y: 0))
            context.addLine(to: CGPoint(x: size.width * 0.4, y: size.height))
            context.move(to: CGPoint(x: size.width * 0.6, y: 0))
            context.addLine(to: CGPoint(x: size.width * 0.8, y: size.height))
            context.strokePath()

        case .moving:
            // Движущаяся платформа - с индикатором движения
            context.setFillColor(colors.secondary.cgColor)
            context.fill(rect)

            // Стрелки по бокам
            context.setStrokeColor(colors.accent.cgColor)
            context.setLineWidth(2)

            // Левая стрелка
            context.move(to: CGPoint(x: 8, y: size.height / 2))
            context.addLine(to: CGPoint(x: 4, y: size.height / 2 - 4))
            context.move(to: CGPoint(x: 8, y: size.height / 2))
            context.addLine(to: CGPoint(x: 4, y: size.height / 2 + 4))

            // Правая стрелка
            context.move(to: CGPoint(x: size.width - 8, y: size.height / 2))
            context.addLine(to: CGPoint(x: size.width - 4, y: size.height / 2 - 4))
            context.move(to: CGPoint(x: size.width - 8, y: size.height / 2))
            context.addLine(to: CGPoint(x: size.width - 4, y: size.height / 2 + 4))

            context.strokePath()

        case .bouncy:
            // Прыжковая платформа (гриб) - розово-красный с выпуклой формой
            let mushroomColor = UIColor(red: 0.8, green: 0.3, blue: 0.5, alpha: 1.0)
            let capColor = UIColor(red: 0.9, green: 0.4, blue: 0.6, alpha: 1.0)

            // Шляпка гриба (выпуклая верхняя часть)
            let capHeight = size.height * 0.7
            let capRect = CGRect(x: 0, y: size.height - capHeight, width: size.width, height: capHeight)
            context.setFillColor(mushroomColor.cgColor)
            context.fillEllipse(in: capRect)

            // Ножка гриба
            let stemWidth = size.width * 0.4
            let stemRect = CGRect(x: (size.width - stemWidth) / 2, y: 0, width: stemWidth, height: size.height * 0.4)
            context.setFillColor(capColor.cgColor)
            context.fill(stemRect)

            // Стрелка вверх для индикации прыжка
            context.setStrokeColor(UIColor.white.cgColor)
            context.setLineWidth(2)
            let arrowX = size.width / 2
            let arrowTop = size.height - 4
            let arrowBottom = size.height - capHeight + 4
            context.move(to: CGPoint(x: arrowX - 4, y: arrowBottom))
            context.addLine(to: CGPoint(x: arrowX, y: arrowTop))
            context.addLine(to: CGPoint(x: arrowX + 4, y: arrowBottom))
            context.strokePath()

        case .ice:
            // Ледяная платформа - светло-голубая с блеском
            let iceColor = UIColor(red: 0.7, green: 0.85, blue: 0.95, alpha: 1.0)
            let highlightColor = UIColor(red: 0.95, green: 0.98, blue: 1.0, alpha: 1.0)

            // Основа платформы
            context.setFillColor(iceColor.cgColor)
            context.fill(rect)

            // Блики льда (диагональные линии)
            context.setStrokeColor(highlightColor.cgColor)
            context.setLineWidth(1)
            for x in stride(from: CGFloat(4), to: size.width + size.height, by: 8) {
                context.move(to: CGPoint(x: x, y: 0))
                context.addLine(to: CGPoint(x: max(0, x - size.height), y: min(size.height, size.height)))
            }
            context.strokePath()

            // Символ скольжения (волнистая линия)
            context.setStrokeColor(UIColor.white.withAlphaComponent(0.6).cgColor)
            context.setLineWidth(2)
            context.move(to: CGPoint(x: 4, y: size.height / 2))
            for x in stride(from: CGFloat(4), to: size.width - 4, by: 4) {
                let waveY = size.height / 2 + sin(x / 4) * 2
                context.addLine(to: CGPoint(x: x, y: waveY))
            }
            context.strokePath()

        case .disappearing:
            // Исчезающая платформа - полупрозрачная с эффектом мерцания
            let disappearingColor = UIColor(red: 0.6, green: 0.7, blue: 0.9, alpha: 0.8)
            let borderColor = UIColor(red: 0.4, green: 0.5, blue: 0.8, alpha: 1.0)

            // Основа платформы
            context.setFillColor(disappearingColor.cgColor)
            context.fill(rect)

            // Рамка
            context.setStrokeColor(borderColor.cgColor)
            context.setLineWidth(2)
            context.stroke(rect.insetBy(dx: 1, dy: 1))

            // Пунктирные линии для эффекта "эфемерности"
            context.setStrokeColor(UIColor.white.withAlphaComponent(0.5).cgColor)
            context.setLineWidth(1)
            let dashPattern: [CGFloat] = [4, 4]
            context.setLineDash(phase: 0, lengths: dashPattern)
            for y in stride(from: CGFloat(8), to: size.height, by: 8) {
                context.move(to: CGPoint(x: 4, y: y))
                context.addLine(to: CGPoint(x: size.width - 4, y: y))
            }
            context.strokePath()
            context.setLineDash(phase: 0, lengths: [])

        case .floating:
            // Плавающая платформа - с эффектом парения
            let floatingColor = UIColor(red: 0.5, green: 0.6, blue: 0.4, alpha: 1.0)
            let mossColor = UIColor(red: 0.3, green: 0.5, blue: 0.2, alpha: 1.0)

            // Основа платформы
            context.setFillColor(floatingColor.cgColor)
            context.fill(rect)

            // Мох сверху
            let mossHeight = size.height * 0.2
            let mossRect = CGRect(x: 0, y: size.height - mossHeight, width: size.width, height: mossHeight)
            context.setFillColor(mossColor.cgColor)
            context.fill(mossRect)

            // Волнистые линии снизу (эффект парения)
            context.setStrokeColor(UIColor.white.withAlphaComponent(0.4).cgColor)
            context.setLineWidth(1)
            for i in 0..<3 {
                let baseY = CGFloat(i + 1) * 4
                context.move(to: CGPoint(x: 4, y: baseY))
                for x in stride(from: CGFloat(4), to: size.width - 4, by: 2) {
                    let waveY = baseY + sin(x / 6 + CGFloat(i)) * 2
                    context.addLine(to: CGPoint(x: x, y: waveY))
                }
                context.strokePath()
            }
        }
    }

    /// Рисование hazard тайла
    private static func drawHazardTile(context: CGContext, hazardType: String, size: CGSize) {
        let rect = CGRect(origin: .zero, size: size)

        switch hazardType {
        case "hazard_spikes", "spikes":
            // Шипы - треугольники снизу вверх
            let spikeColor = UIColor(red: 0.5, green: 0.5, blue: 0.55, alpha: 1.0)
            context.setFillColor(spikeColor.cgColor)

            let spikeCount = 4
            let spikeWidth = size.width / CGFloat(spikeCount)

            for i in 0..<spikeCount {
                let x = CGFloat(i) * spikeWidth
                context.move(to: CGPoint(x: x, y: 0))
                context.addLine(to: CGPoint(x: x + spikeWidth / 2, y: size.height * 0.8))
                context.addLine(to: CGPoint(x: x + spikeWidth, y: 0))
                context.closePath()
            }
            context.fillPath()

            // Предупреждающие полосы на основании
            context.setFillColor(UIColor.yellow.cgColor)
            context.fill(CGRect(x: 0, y: 0, width: size.width, height: 4))

        case "hazard_lava", "lava":
            // Лава - волнистая поверхность
            let lavaColor = UIColor(red: 1.0, green: 0.4, blue: 0.1, alpha: 1.0)
            let darkLava = UIColor(red: 0.8, green: 0.2, blue: 0.0, alpha: 1.0)

            context.setFillColor(darkLava.cgColor)
            context.fill(rect)

            // Волны
            context.setFillColor(lavaColor.cgColor)
            context.move(to: CGPoint(x: 0, y: size.height * 0.7))

            for x in stride(from: CGFloat(0), through: size.width, by: 4) {
                let waveY = size.height * 0.7 + sin(x / 4) * 3
                context.addLine(to: CGPoint(x: x, y: waveY))
            }

            context.addLine(to: CGPoint(x: size.width, y: size.height))
            context.addLine(to: CGPoint(x: 0, y: size.height))
            context.closePath()
            context.fillPath()

            // Пузырьки
            context.setFillColor(UIColor.yellow.withAlphaComponent(0.6).cgColor)
            context.fillEllipse(in: CGRect(x: 8, y: size.height * 0.8, width: 4, height: 4))
            context.fillEllipse(in: CGRect(x: size.width - 12, y: size.height * 0.75, width: 3, height: 3))

        case "hazard_void", "void":
            // Пустота - тёмный градиент с мерцанием
            let voidColor = UIColor(red: 0.05, green: 0.0, blue: 0.1, alpha: 0.9)
            context.setFillColor(voidColor.cgColor)
            context.fill(rect)

            // "Звёзды" в пустоте
            context.setFillColor(UIColor.purple.withAlphaComponent(0.5).cgColor)
            for i in 0..<5 {
                let x = CGFloat((i * 7) % Int(size.width))
                let y = CGFloat((i * 11) % Int(size.height))
                context.fillEllipse(in: CGRect(x: x, y: y, width: 2, height: 2))
            }

        default:
            // Неизвестный hazard - красные полосы
            context.setFillColor(UIColor.red.withAlphaComponent(0.5).cgColor)
            context.fill(rect)

            context.setStrokeColor(UIColor.yellow.cgColor)
            context.setLineWidth(2)

            // Диагональные предупреждающие полосы
            for x in stride(from: CGFloat(-size.height), to: size.width + size.height, by: 8) {
                context.move(to: CGPoint(x: x, y: 0))
                context.addLine(to: CGPoint(x: x + size.height, y: size.height))
            }
            context.strokePath()
        }
    }

    /// Рисование декоративного тайла
    private static func drawDecorationTile(context: CGContext, type: TileType, tileSet: TileSet, size: CGSize) {
        let colors = colorForTileSet(tileSet)

        switch type {
        case .decorGrass:
            // Травинки
            context.setStrokeColor(colors.accent.cgColor)
            context.setLineWidth(1)

            for i in 0..<5 {
                let x = CGFloat(i) * (size.width / 5) + 4
                let height = size.height * CGFloat(0.4 + Double(i % 3) * 0.15)
                let curve = CGFloat((i % 2 == 0) ? 2 : -2)

                context.move(to: CGPoint(x: x, y: 0))
                context.addQuadCurve(
                    to: CGPoint(x: x + curve, y: height),
                    control: CGPoint(x: x + curve / 2, y: height / 2)
                )
            }
            context.strokePath()

        case .decorStone:
            // Камень
            context.setFillColor(colors.secondary.withAlphaComponent(0.7).cgColor)
            let stoneRect = CGRect(
                x: size.width * 0.2,
                y: size.height * 0.1,
                width: size.width * 0.6,
                height: size.height * 0.5
            )
            context.fillEllipse(in: stoneRect)

        case .decorTorch:
            // Факел
            // Ручка
            context.setFillColor(UIColor.brown.cgColor)
            context.fill(CGRect(x: size.width * 0.4, y: 0, width: size.width * 0.2, height: size.height * 0.6))

            // Пламя
            context.setFillColor(UIColor.orange.cgColor)
            context.fillEllipse(in: CGRect(
                x: size.width * 0.25,
                y: size.height * 0.5,
                width: size.width * 0.5,
                height: size.height * 0.4
            ))
            context.setFillColor(UIColor.yellow.cgColor)
            context.fillEllipse(in: CGRect(
                x: size.width * 0.35,
                y: size.height * 0.55,
                width: size.width * 0.3,
                height: size.height * 0.25
            ))

        case .decorBanner:
            // Флаг/баннер
            context.setFillColor(colors.accent.cgColor)

            // Древко
            context.fill(CGRect(x: size.width * 0.45, y: 0, width: size.width * 0.1, height: size.height))

            // Полотно
            context.move(to: CGPoint(x: size.width * 0.5, y: size.height * 0.9))
            context.addLine(to: CGPoint(x: size.width * 0.9, y: size.height * 0.8))
            context.addLine(to: CGPoint(x: size.width * 0.85, y: size.height * 0.5))
            context.addLine(to: CGPoint(x: size.width * 0.5, y: size.height * 0.4))
            context.closePath()
            context.fillPath()

        case .decorDebris:
            // Обломки
            context.setFillColor(colors.primary.withAlphaComponent(0.6).cgColor)

            // Несколько случайных камней
            context.fillEllipse(in: CGRect(x: 2, y: 2, width: 8, height: 6))
            context.fillEllipse(in: CGRect(x: 14, y: 4, width: 10, height: 7))
            context.fillEllipse(in: CGRect(x: 8, y: 10, width: 6, height: 5))

        case .decorChain:
            // Цепь
            context.setStrokeColor(UIColor.gray.cgColor)
            context.setLineWidth(2)

            let linkHeight: CGFloat = 8
            for i in 0..<Int(size.height / linkHeight) {
                let y = CGFloat(i) * linkHeight
                let offset = (i % 2 == 0) ? CGFloat(2) : CGFloat(-2)

                context.strokeEllipse(in: CGRect(
                    x: size.width / 2 - 4 + offset,
                    y: y,
                    width: 8,
                    height: linkHeight
                ))
            }

        default:
            break
        }
    }

    // MARK: - Color Helpers

    /// Получить цветовую схему для набора тайлов
    private static func colorForTileSet(_ tileSet: TileSet) -> (primary: UIColor, secondary: UIColor, accent: UIColor) {
        switch tileSet {
        case .burningVillage:
            return (
                UIColor(red: 0.55, green: 0.35, blue: 0.2, alpha: 1.0),  // Brown
                UIColor(red: 0.9, green: 0.5, blue: 0.1, alpha: 1.0),   // Orange
                UIColor(red: 0.9, green: 0.2, blue: 0.1, alpha: 1.0)    // Red
            )
        case .bridgesOfAbyss:
            return (
                UIColor(red: 0.3, green: 0.3, blue: 0.35, alpha: 1.0),  // Dark gray
                UIColor(red: 0.15, green: 0.15, blue: 0.25, alpha: 1.0), // Dark blue
                UIColor(red: 0.4, green: 0.3, blue: 0.5, alpha: 1.0)    // Purple
            )
        case .worldRoots:
            return (
                UIColor(red: 0.3, green: 0.5, blue: 0.25, alpha: 1.0),  // Green
                UIColor(red: 0.45, green: 0.3, blue: 0.2, alpha: 1.0), // Brown
                UIColor(red: 0.8, green: 0.7, blue: 0.3, alpha: 1.0)   // Yellow
            )
        case .catacombs:
            return (
                UIColor(red: 0.4, green: 0.4, blue: 0.4, alpha: 1.0),   // Gray
                UIColor(red: 0.8, green: 0.65, blue: 0.2, alpha: 1.0), // Gold
                UIColor(red: 0.15, green: 0.1, blue: 0.1, alpha: 1.0)  // Dark
            )
        case .stormPeaks:
            return (
                UIColor(red: 0.9, green: 0.95, blue: 1.0, alpha: 1.0),  // White
                UIColor(red: 0.6, green: 0.8, blue: 0.95, alpha: 1.0), // Light blue
                UIColor(red: 0.5, green: 0.55, blue: 0.6, alpha: 1.0)  // Gray
            )
        case .seaOfShards:
            return (
                UIColor(red: 0.6, green: 0.75, blue: 0.9, alpha: 1.0),  // Light blue
                UIColor(red: 0.95, green: 0.95, blue: 1.0, alpha: 1.0), // White
                UIColor(red: 0.9, green: 0.75, blue: 0.4, alpha: 1.0)  // Gold
            )
        case .citadelGates:
            return (
                UIColor(red: 0.15, green: 0.15, blue: 0.2, alpha: 1.0), // Black
                UIColor(red: 0.7, green: 0.15, blue: 0.15, alpha: 1.0), // Red
                UIColor(red: 0.4, green: 0.4, blue: 0.45, alpha: 1.0)  // Iron
            )
        case .citadelHeart:
            return (
                UIColor(red: 0.15, green: 0.1, blue: 0.25, alpha: 1.0), // Dark purple
                UIColor(red: 0.4, green: 0.2, blue: 0.5, alpha: 1.0),  // Purple
                UIColor(red: 0.9, green: 0.75, blue: 0.3, alpha: 1.0)  // Gold
            )
        case .throneHall:
            return (
                UIColor(red: 0.1, green: 0.05, blue: 0.1, alpha: 1.0), // Deep black
                UIColor(red: 0.35, green: 0.15, blue: 0.4, alpha: 1.0), // Dark purple
                UIColor(red: 0.6, green: 0.1, blue: 0.15, alpha: 1.0)  // Blood red
            )
        case .awakening:
            return (
                UIColor(red: 0.3, green: 0.15, blue: 0.4, alpha: 1.0), // Purple
                UIColor(red: 0.95, green: 0.85, blue: 0.5, alpha: 1.0), // Gold
                UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)   // White
            )
        }
    }

    // MARK: - Cache Management

    /// Очистить кэш текстур
    static func clearCache() {
        textureCache.removeAllObjects()
    }
}
