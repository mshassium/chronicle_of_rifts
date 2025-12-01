import Foundation

/// Статистика прохождения уровня
struct LevelStats: Codable {
    /// Количество собранных кристаллов
    var crystalsCollected: Int

    /// Количество найденных секретов
    var secretsFound: Int

    /// Лучшее время прохождения
    var bestTime: TimeInterval?

    /// Уровень пройден
    var completed: Bool

    /// Пустая статистика для нового уровня
    static let empty = LevelStats(
        crystalsCollected: 0,
        secretsFound: 0,
        bestTime: nil,
        completed: false
    )

    /// Обновить статистику, сохраняя лучшие результаты
    mutating func updateWith(crystals: Int, secrets: Int, time: TimeInterval, completed: Bool) {
        crystalsCollected = max(crystalsCollected, crystals)
        secretsFound = max(secretsFound, secrets)
        if completed {
            self.completed = true
            if let currentBest = bestTime {
                bestTime = min(currentBest, time)
            } else {
                bestTime = time
            }
        }
    }
}

/// Данные игрока, сохраняемые между сессиями
struct PlayerData: Codable {
    /// Текущее здоровье (1-3)
    var health: Int

    /// Максимальное здоровье
    var maxHealth: Int

    /// Текущая мана
    var mana: Int

    /// Разблокированные уровни
    var unlockedLevels: [Int]

    /// ID собранных страниц хроник
    var collectedPages: [String]

    /// Статистика по каждому уровню
    var levelStats: [Int: LevelStats]

    /// Начальные данные нового игрока
    static let newPlayer = PlayerData(
        health: 3,
        maxHealth: 3,
        mana: 0,
        unlockedLevels: [1],
        collectedPages: [],
        levelStats: [:]
    )

    /// Проверить, разблокирован ли уровень
    func isLevelUnlocked(_ level: Int) -> Bool {
        unlockedLevels.contains(level)
    }

    /// Разблокировать следующий уровень
    mutating func unlockLevel(_ level: Int) {
        if !unlockedLevels.contains(level) {
            unlockedLevels.append(level)
            unlockedLevels.sort()
        }
    }

    /// Получить статистику уровня
    func statsForLevel(_ level: Int) -> LevelStats {
        levelStats[level] ?? .empty
    }

    /// Обновить статистику уровня
    mutating func updateStats(forLevel level: Int, crystals: Int, secrets: Int, time: TimeInterval, completed: Bool) {
        var stats = statsForLevel(level)
        stats.updateWith(crystals: crystals, secrets: secrets, time: time, completed: completed)
        levelStats[level] = stats

        if completed {
            unlockLevel(level + 1)
        }
    }

    /// Добавить страницу хроник
    mutating func collectPage(_ pageId: String) {
        if !collectedPages.contains(pageId) {
            collectedPages.append(pageId)
        }
    }

    /// Восстановить здоровье до максимума
    mutating func restoreFullHealth() {
        health = maxHealth
    }

    /// Получить урон
    mutating func takeDamage(_ amount: Int = 1) {
        health = max(0, health - amount)
    }

    /// Проверить, жив ли игрок
    var isAlive: Bool {
        health > 0
    }
}
