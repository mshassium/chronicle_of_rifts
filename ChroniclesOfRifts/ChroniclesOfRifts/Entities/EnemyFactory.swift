import SpriteKit

// MARK: - EnemyFactory

/// Фабрика для создания врагов по типу из LevelData
enum EnemyFactory {

    // MARK: - Type Alias

    /// Замыкание для создания врага
    typealias EnemyCreator = () -> Enemy

    // MARK: - Registry

    /// Реестр кастомных типов врагов для расширяемости
    private static var customEnemyTypes: [String: EnemyCreator] = [:]

    // MARK: - Enemy Creation

    /// Создаёт врага по данным из уровня
    /// - Parameter data: Данные о спавне врага из JSON
    /// - Returns: Сконфигурированный враг или nil если тип неизвестен
    static func createEnemy(from data: EnemySpawnData) -> Enemy? {
        guard let enemy = createBaseEnemy(type: data.type) else {
            print("EnemyFactory: Неизвестный тип врага '\(data.type)'")
            return nil
        }

        // Настройка начального направления
        enemy.setFacingDirection(data.facing)

        // Настройка пути патрулирования (без конвертации - это делается позже)
        if let path = data.patrolPath {
            enemy.patrolPath = path
        }

        return enemy
    }

    /// Создаёт базового врага по строковому типу
    /// - Parameter type: Строковый идентификатор типа врага
    /// - Returns: Экземпляр врага или nil
    private static func createBaseEnemy(type: String) -> Enemy? {
        // Сначала проверяем кастомные типы
        if let creator = customEnemyTypes[type] {
            return creator()
        }

        // Стандартные типы врагов
        switch type {
        // Обычные враги
        case "Cultist":
            return Cultist()

        case "CorruptedSpirit":
            return CorruptedSpirit()

        case "FloatingEye":
            return FloatingEye()

        case "Skeleton":
            return Skeleton()

        case "IceGolem":
            return IceGolem()

        case "SkyDevourer":
            return SkyDevourer()

        case "EliteCultist":
            return EliteCultist()

        // Боссы
        case "Defiler":
            return Defiler()

        case "ChainMasterGrondar":
            return ChainMasterGrondar()

        case "HeartOfCorruption":
            return HeartOfCorruption()

        case "ArchnecromancerSalvus":
            return ArchnecromancerSalvus()

        case "FrostGuardianKromar":
            return FrostGuardianKromar()

        case "SkyQueenSkirra":
            return SkyQueenSkirra()

        case "GeneralMaltorus":
            return GeneralMaltorus()

        case "Morgana":
            return Morgana()

        case "Velkor":
            return Velkor()

        default:
            return nil
        }
    }

    // MARK: - Custom Type Registration

    /// Регистрирует новый тип врага для расширяемости
    /// - Parameters:
    ///   - type: Строковый идентификатор типа
    ///   - creator: Замыкание для создания экземпляра врага
    static func registerEnemyType(_ type: String, creator: @escaping EnemyCreator) {
        customEnemyTypes[type] = creator
    }

    /// Удаляет зарегистрированный тип врага
    /// - Parameter type: Строковый идентификатор типа
    static func unregisterEnemyType(_ type: String) {
        customEnemyTypes.removeValue(forKey: type)
    }

    /// Проверяет, зарегистрирован ли тип врага
    /// - Parameter type: Строковый идентификатор типа
    /// - Returns: true если тип зарегистрирован
    static func isTypeRegistered(_ type: String) -> Bool {
        if customEnemyTypes[type] != nil {
            return true
        }

        // Проверяем стандартные типы
        let standardTypes = [
            "Cultist", "CorruptedSpirit", "FloatingEye", "Skeleton",
            "IceGolem", "SkyDevourer", "EliteCultist",
            "Defiler", "ChainMasterGrondar", "HeartOfCorruption",
            "ArchnecromancerSalvus", "FrostGuardianKromar", "SkyQueenSkirra",
            "GeneralMaltorus", "Morgana", "Velkor"
        ]

        return standardTypes.contains(type)
    }

    /// Возвращает список всех доступных типов врагов
    /// - Returns: Массив строковых идентификаторов
    static func availableEnemyTypes() -> [String] {
        var types = [
            "Cultist", "CorruptedSpirit", "FloatingEye", "Skeleton",
            "IceGolem", "SkyDevourer", "EliteCultist",
            "Defiler", "ChainMasterGrondar", "HeartOfCorruption",
            "ArchnecromancerSalvus", "FrostGuardianKromar", "SkyQueenSkirra",
            "GeneralMaltorus", "Morgana", "Velkor"
        ]

        types.append(contentsOf: customEnemyTypes.keys)

        return types.sorted()
    }
}
