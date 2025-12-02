import SpriteKit

/// GeneralMaltorus — босс уровня 7 (Врата Цитадели)
/// Генерал культистов. Самый сложный обычный босс игры.
/// Комбо-атаки, призыв культистов, тактическое сражение.
final class GeneralMaltorus: Boss {

    // MARK: - Configuration

    private struct Config {
        static let maxHealth: Int = 300         // TODO: Много HP (сложный босс)
        static let contactDamage: Int = 2       // TODO
        static let swordDamage: Int = 3         // TODO: Урон мечом
        static let darkMagicDamage: Int = 2     // TODO: Урон тёмной магией
        static let moveSpeed: CGFloat = 90      // TODO: Быстрый воин
        static let size = CGSize(width: 56, height: 80)

        // Культисты
        static let maxCultists: Int = 4         // TODO
        static let cultistsPerSummon: Int = 2   // TODO

        // Cooldowns
        static let swordComboCooldown: TimeInterval = 2.5   // TODO
        static let darkSlashCooldown: TimeInterval = 4.0    // TODO
        static let summonCultistsCooldown: TimeInterval = 12.0 // TODO
        static let shieldBashCooldown: TimeInterval = 5.0   // TODO
        static let warCryCooldown: TimeInterval = 15.0      // TODO
    }

    // MARK: - Phases

    // TODO: Фаза 1 (100% - 70% HP) - Воин
    // - Мечные комбо
    // - Блок щитом
    // - Контратаки

    // TODO: Фаза 2 (70% - 40% HP) - Командир
    // - Призывает культистов
    // - Тактические отступления
    // - Боевой клич (баф культистам)

    // TODO: Фаза 3 (40% - 0% HP) - Отчаяние
    // - Использует тёмную магию (ранее скрывал)
    // - Более агрессивен
    // - Комбо удлиняются

    // MARK: - Attack Patterns

    // TODO: SwordCombo - комбо мечом
    // - 3-4 удара подряд
    // - Последний удар сильнее
    // - Можно прервать уроном

    // TODO: DarkSlash - тёмный разрез
    // - Проектайл в форме полумесяца
    // - Летит на расстояние

    // TODO: ShieldBash - удар щитом
    // - Оглушает игрока на 0.5 сек
    // - Контратака после блока

    // TODO: CounterStance - стойка контратаки
    // - Поднимает меч
    // - Если атаковать — получаешь урон
    // - Нужно подождать или атаковать сзади

    // TODO: SummonCultists - призыв культистов
    // - Отступает назад
    // - Призывает 2 культистов
    // - Культисты используют магию

    // TODO: WarCry - боевой клич
    // - Усиливает себя и культистов
    // - Увеличивает скорость атаки
    // - Длится 10 секунд

    // TODO: DarkBarrage (фаза 3) - шквал тьмы
    // - Множественные тёмные проектайлы
    // - Сложно уклониться

    // MARK: - Properties

    /// Активные культисты
    private var cultists: [Enemy] = []

    /// Находится ли в стойке контратаки
    private var isInCounterStance: Bool = false

    /// Активен ли боевой клич
    private var warCryActive: Bool = false

    /// Счётчик комбо (для удлинения в фазе 3)
    private var comboCounter: Int = 0

    // MARK: - Init

    init() {
        // TODO: Инициализация
        // - Рыцарь в тёмных доспехах
        // - Меч и щит
        // - Плащ культистов
        // - Светящиеся глаза под шлемом
        fatalError("GeneralMaltorus: Not implemented")
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Combat Mechanics

    // TODO: Система комбо
    // - Отслеживание ударов в комбо
    // - Бонус урона на последнем ударе
    // - Сброс при получении урона

    // TODO: Система блока
    // - Может блокировать атаки игрока
    // - После успешного блока — контратака
    // - Некоторые атаки игрока пробивают блок

    // TODO: Тактическое поведение
    // - Отступает при низком HP
    // - Использует культистов как щит
    // - Атакует когда игрок занят культистами
}
