import SpriteKit

/// Протокол для обработки событий игровой сцены
protocol GameSceneDelegate: AnyObject {
    /// Вызывается когда сцена полностью загружена
    func sceneDidLoad(_ scene: SKScene)

    /// Вызывается перед переходом на другую сцену
    func sceneWillTransition(_ scene: SKScene)

    /// Вызывается когда игрок умирает
    func playerDidDie()

    /// Вызывается когда уровень успешно завершён
    /// - Parameters:
    ///   - crystals: Количество собранных кристаллов
    ///   - secrets: Количество найденных секретов
    func levelDidComplete(crystals: Int, secrets: Int)

    /// Вызывается когда игрок достигает чекпоинта
    /// - Parameter checkpointId: Идентификатор чекпоинта
    func playerReachedCheckpoint(_ checkpointId: String)

    /// Вызывается когда собран коллекционный предмет
    /// - Parameter itemId: Идентификатор предмета
    func collectibleCollected(_ itemId: String)
}

// MARK: - Default Implementations

extension GameSceneDelegate {
    func sceneDidLoad(_ scene: SKScene) {}
    func sceneWillTransition(_ scene: SKScene) {}
    func playerDidDie() {}
    func levelDidComplete(crystals: Int, secrets: Int) {}
    func playerReachedCheckpoint(_ checkpointId: String) {}
    func collectibleCollected(_ itemId: String) {}
}
