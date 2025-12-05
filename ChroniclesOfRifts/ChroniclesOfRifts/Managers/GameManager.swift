import Foundation
import Combine

/// Центральный менеджер игры (синглтон)
/// Управляет состоянием игры, данными игрока и настройками
final class GameManager: ObservableObject {
    // MARK: - Singleton

    /// Единственный экземпляр GameManager
    static let shared = GameManager()

    // MARK: - Published Properties

    /// Текущее состояние игры
    @Published private(set) var gameState: GameState = .menu

    /// Данные игрока
    @Published var playerData: PlayerData = .newPlayer

    /// Настройки игры
    @Published var settings: GameSettings = .default

    // MARK: - Properties

    /// Текущий уровень
    private(set) var currentLevel: Int = 1

    /// Время начала уровня (для статистики)
    private var levelStartTime: Date?

    // MARK: - Checkpoint

    /// Позиция текущего чекпоинта
    private(set) var currentCheckpointPosition: CGPoint?

    /// ID уровня для текущего чекпоинта
    private(set) var currentCheckpointLevelId: Int?

    /// Ключи для UserDefaults
    private enum Keys {
        static let playerData = "com.chroniclesofrifts.playerData"
        static let settings = "com.chroniclesofrifts.settings"
        static let currentLevel = "com.chroniclesofrifts.currentLevel"
    }

    // MARK: - Initialization

    private init() {
        loadProgress()
    }

    // MARK: - State Management

    /// Сменить состояние игры
    /// - Parameter newState: Новое состояние
    func changeState(to newState: GameState) {
        let oldState = gameState
        gameState = newState

        // Обработка переходов состояний
        handleStateTransition(from: oldState, to: newState)
    }

    /// Обработка логики перехода между состояниями
    private func handleStateTransition(from oldState: GameState, to newState: GameState) {
        switch (oldState, newState) {
        case (_, .playing):
            levelStartTime = Date()
        case (.playing, .paused):
            break
        case (.paused, .playing):
            break
        case (.playing, .gameOver):
            break
        case (.playing, .levelComplete):
            recordLevelCompletion()
        default:
            break
        }
    }

    // MARK: - Level Management

    /// Установить текущий уровень
    /// - Parameter level: Номер уровня
    func setCurrentLevel(_ level: Int) {
        guard playerData.isLevelUnlocked(level) else { return }
        currentLevel = level
        playerData.restoreFullHealth()
        levelStartTime = nil
    }

    /// Записать завершение уровня
    private func recordLevelCompletion() {
        guard let startTime = levelStartTime else { return }
        let completionTime = Date().timeIntervalSince(startTime)

        // Статистика обновляется через вызов updateStats в GameScene
        _ = completionTime // Используется при вызове updateStats извне
    }

    /// Получить время прохождения текущего уровня
    func currentLevelTime() -> TimeInterval? {
        guard let startTime = levelStartTime else { return nil }
        return Date().timeIntervalSince(startTime)
    }

    // MARK: - Persistence

    /// Сохранить прогресс в UserDefaults
    func saveProgress() {
        let encoder = JSONEncoder()

        if let playerDataEncoded = try? encoder.encode(playerData) {
            UserDefaults.standard.set(playerDataEncoded, forKey: Keys.playerData)
        }

        if let settingsEncoded = try? encoder.encode(settings) {
            UserDefaults.standard.set(settingsEncoded, forKey: Keys.settings)
        }

        UserDefaults.standard.set(currentLevel, forKey: Keys.currentLevel)
        UserDefaults.standard.synchronize()
    }

    /// Загрузить прогресс из UserDefaults
    func loadProgress() {
        let decoder = JSONDecoder()

        if let playerDataData = UserDefaults.standard.data(forKey: Keys.playerData),
           let loadedPlayerData = try? decoder.decode(PlayerData.self, from: playerDataData) {
            playerData = loadedPlayerData
        }

        if let settingsData = UserDefaults.standard.data(forKey: Keys.settings),
           let loadedSettings = try? decoder.decode(GameSettings.self, from: settingsData) {
            settings = loadedSettings
            settings.normalize()
        }

        currentLevel = UserDefaults.standard.integer(forKey: Keys.currentLevel)
        if currentLevel == 0 {
            currentLevel = 1
        }
    }

    /// Сбросить весь прогресс
    func resetProgress() {
        playerData = .newPlayer
        currentLevel = 1
        // Настройки не сбрасываем - это пользовательские предпочтения
        saveProgress()
    }

    // MARK: - Player Actions

    /// Обновить статистику уровня при завершении
    /// - Parameters:
    ///   - crystals: Собранные кристаллы
    ///   - secrets: Найденные секреты
    func completeLevelWith(crystals: Int, secrets: Int) {
        guard let time = currentLevelTime() else { return }
        playerData.updateStats(
            forLevel: currentLevel,
            crystals: crystals,
            secrets: secrets,
            time: time,
            completed: true
        )
        saveProgress()
    }

    /// Игрок получил урон
    func playerTakeDamage(_ amount: Int = 1) {
        playerData.takeDamage(amount)
        if !playerData.isAlive {
            changeState(to: .gameOver)
        }
    }

    /// Игрок собрал страницу хроник
    func collectPage(_ pageId: String) {
        playerData.collectPage(pageId)
        saveProgress()
    }

    // MARK: - Checkpoint Management

    /// Установить чекпоинт
    /// - Parameters:
    ///   - position: Позиция респавна
    ///   - levelId: ID уровня
    func setCheckpoint(position: CGPoint, levelId: Int) {
        currentCheckpointPosition = position
        currentCheckpointLevelId = levelId
    }

    /// Получить позицию чекпоинта для указанного уровня
    /// - Parameter levelId: ID уровня
    /// - Returns: Позиция чекпоинта или nil если нет чекпоинта
    func getCheckpointPosition(for levelId: Int) -> CGPoint? {
        guard currentCheckpointLevelId == levelId else { return nil }
        return currentCheckpointPosition
    }

    /// Очистить текущий чекпоинт
    func clearCheckpoint() {
        currentCheckpointPosition = nil
        currentCheckpointLevelId = nil
    }
}
