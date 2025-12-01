import SpriteKit

/// Статические методы для визуальных эффектов камеры
enum CameraEffects {

    // MARK: - Flash Effects

    /// Эффект вспышки (белый или цветной)
    /// - Parameters:
    ///   - color: Цвет вспышки
    ///   - duration: Длительность эффекта
    /// - Returns: Нода с анимацией вспышки
    static func flashEffect(color: SKColor = .white, duration: TimeInterval = 0.3) -> SKNode {
        let flashNode = SKSpriteNode(color: color, size: CGSize(width: 2000, height: 2000))
        flashNode.name = "flashEffect"
        flashNode.zPosition = 900
        flashNode.alpha = 0

        let flashAction = SKAction.sequence([
            SKAction.fadeAlpha(to: 1.0, duration: duration * 0.3),
            SKAction.fadeAlpha(to: 0.0, duration: duration * 0.7),
            SKAction.removeFromParent()
        ])

        flashNode.run(flashAction)
        return flashNode
    }

    /// Создать действие вспышки для существующей ноды
    /// - Parameters:
    ///   - color: Цвет вспышки
    ///   - duration: Длительность
    /// - Returns: SKAction для применения к ноде
    static func flashAction(duration: TimeInterval = 0.3) -> SKAction {
        return SKAction.sequence([
            SKAction.fadeAlpha(to: 1.0, duration: duration * 0.3),
            SKAction.fadeAlpha(to: 0.0, duration: duration * 0.7)
        ])
    }

    // MARK: - Fade Effects

    /// Затемнение экрана (fade to black)
    /// - Parameter duration: Длительность затемнения
    /// - Returns: Нода с анимацией затемнения
    static func fadeToBlack(duration: TimeInterval = 1.0) -> SKNode {
        let fadeNode = SKSpriteNode(color: .black, size: CGSize(width: 2000, height: 2000))
        fadeNode.name = "fadeToBlack"
        fadeNode.zPosition = 950
        fadeNode.alpha = 0

        let fadeAction = SKAction.fadeAlpha(to: 1.0, duration: duration)
        fadeAction.timingMode = .easeIn

        fadeNode.run(fadeAction)
        return fadeNode
    }

    /// Появление из темноты (fade from black)
    /// - Parameter duration: Длительность появления
    /// - Returns: Нода с анимацией
    static func fadeFromBlack(duration: TimeInterval = 1.0) -> SKNode {
        let fadeNode = SKSpriteNode(color: .black, size: CGSize(width: 2000, height: 2000))
        fadeNode.name = "fadeFromBlack"
        fadeNode.zPosition = 950
        fadeNode.alpha = 1

        let fadeAction = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.0, duration: duration),
            SKAction.removeFromParent()
        ])
        fadeAction.timingMode = .easeOut

        fadeNode.run(fadeAction)
        return fadeNode
    }

    /// Затемнение к произвольному цвету
    /// - Parameters:
    ///   - color: Целевой цвет
    ///   - duration: Длительность
    /// - Returns: Нода с анимацией
    static func fadeTo(color: SKColor, duration: TimeInterval = 1.0) -> SKNode {
        let fadeNode = SKSpriteNode(color: color, size: CGSize(width: 2000, height: 2000))
        fadeNode.name = "fadeTo"
        fadeNode.zPosition = 950
        fadeNode.alpha = 0

        let fadeAction = SKAction.fadeAlpha(to: 1.0, duration: duration)
        fadeAction.timingMode = .easeIn

        fadeNode.run(fadeAction)
        return fadeNode
    }

    // MARK: - Slow Motion

    /// Включить замедление времени
    /// - Parameters:
    ///   - scene: Сцена для замедления
    ///   - factor: Фактор замедления (0.5 = в 2 раза медленнее)
    ///   - duration: Длительность эффекта
    static func slowMotion(scene: SKScene, factor: CGFloat = 0.5, duration: TimeInterval = 2.0) {
        // Замедляем физику
        scene.physicsWorld.speed = factor

        // Замедляем действия (через speed всех нод)
        scene.speed = factor

        // Возвращаем к нормальной скорости через duration
        let restoreAction = SKAction.sequence([
            SKAction.wait(forDuration: duration * Double(factor)),
            SKAction.run {
                scene.physicsWorld.speed = 1.0
                scene.speed = 1.0
            }
        ])

        scene.run(restoreAction, withKey: "slowMotion")
    }

    /// Плавное включение/выключение замедления
    /// - Parameters:
    ///   - scene: Сцена
    ///   - factor: Фактор замедления
    ///   - transitionDuration: Время перехода к замедлению
    ///   - holdDuration: Время удержания замедления
    static func smoothSlowMotion(
        scene: SKScene,
        factor: CGFloat = 0.3,
        transitionDuration: TimeInterval = 0.2,
        holdDuration: TimeInterval = 1.0
    ) {
        // Количество шагов для плавного перехода
        let steps = 10
        let stepDuration = transitionDuration / TimeInterval(steps)
        let speedStep = (1.0 - factor) / CGFloat(steps)

        var actions: [SKAction] = []

        // Плавное замедление
        for i in 1...steps {
            let newSpeed = 1.0 - speedStep * CGFloat(i)
            actions.append(SKAction.run {
                scene.physicsWorld.speed = newSpeed
                scene.speed = newSpeed
            })
            actions.append(SKAction.wait(forDuration: stepDuration))
        }

        // Удержание
        actions.append(SKAction.wait(forDuration: holdDuration * Double(factor)))

        // Плавное ускорение обратно
        for i in 1...steps {
            let newSpeed = factor + speedStep * CGFloat(i)
            actions.append(SKAction.run {
                scene.physicsWorld.speed = newSpeed
                scene.speed = newSpeed
            })
            actions.append(SKAction.wait(forDuration: stepDuration))
        }

        // Гарантируем возврат к нормальной скорости
        actions.append(SKAction.run {
            scene.physicsWorld.speed = 1.0
            scene.speed = 1.0
        })

        scene.run(SKAction.sequence(actions), withKey: "smoothSlowMotion")
    }

    // MARK: - Screen Effects

    /// Эффект виньетки (затемнение по краям)
    /// - Parameters:
    ///   - size: Размер экрана
    ///   - intensity: Интенсивность (0.0-1.0)
    /// - Returns: Нода с эффектом виньетки
    static func vignette(size: CGSize, intensity: CGFloat = 0.5) -> SKNode {
        let vignetteNode = SKEffectNode()
        vignetteNode.name = "vignette"
        vignetteNode.zPosition = 800

        // Создаём радиальный градиент через CIFilter (если доступен)
        // Или используем простую версию с overlay
        let overlay = SKSpriteNode(color: .black, size: size)
        overlay.alpha = intensity * 0.3

        // Центральная прозрачная область
        let centerHole = SKShapeNode(ellipseOf: CGSize(width: size.width * 0.8, height: size.height * 0.8))
        centerHole.fillColor = .black
        centerHole.strokeColor = .clear
        centerHole.blendMode = .subtract

        vignetteNode.addChild(overlay)
        vignetteNode.addChild(centerHole)

        return vignetteNode
    }

    /// Эффект "Hit Stop" (короткая пауза при ударе)
    /// - Parameters:
    ///   - scene: Сцена
    ///   - duration: Длительность паузы
    static func hitStop(scene: SKScene, duration: TimeInterval = 0.05) {
        scene.physicsWorld.speed = 0
        scene.isPaused = false // Сцена не на паузе, но физика остановлена

        scene.run(SKAction.sequence([
            SKAction.wait(forDuration: duration),
            SKAction.run {
                scene.physicsWorld.speed = 1.0
            }
        ]), withKey: "hitStop")
    }

    // MARK: - Color Effects

    /// Эффект красного оттенка при получении урона
    /// - Parameter duration: Длительность эффекта
    /// - Returns: Нода с эффектом
    static func damageOverlay(duration: TimeInterval = 0.3) -> SKNode {
        let damageNode = SKSpriteNode(color: .red, size: CGSize(width: 2000, height: 2000))
        damageNode.name = "damageOverlay"
        damageNode.zPosition = 850
        damageNode.alpha = 0
        damageNode.blendMode = .add

        let pulseAction = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.3, duration: duration * 0.2),
            SKAction.fadeAlpha(to: 0.0, duration: duration * 0.8),
            SKAction.removeFromParent()
        ])

        damageNode.run(pulseAction)
        return damageNode
    }

    /// Эффект золотого сияния при подборе предмета
    /// - Parameter duration: Длительность эффекта
    /// - Returns: Нода с эффектом
    static func collectGlow(duration: TimeInterval = 0.5) -> SKNode {
        let glowNode = SKSpriteNode(color: .yellow, size: CGSize(width: 2000, height: 2000))
        glowNode.name = "collectGlow"
        glowNode.zPosition = 850
        glowNode.alpha = 0
        glowNode.blendMode = .add

        let glowAction = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.15, duration: duration * 0.3),
            SKAction.fadeAlpha(to: 0.0, duration: duration * 0.7),
            SKAction.removeFromParent()
        ])

        glowNode.run(glowAction)
        return glowNode
    }
}
