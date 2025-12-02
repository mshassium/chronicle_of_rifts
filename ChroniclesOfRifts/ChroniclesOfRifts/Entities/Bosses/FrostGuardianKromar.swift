import SpriteKit

/// FrostGuardianKromar — босс уровня 5 (Штормовые Пики)
/// Ледяной голем-гигант, бывший защитник горы.
/// ОСОБЕННОСТЬ: Можно очистить вместо убийства (альтернативный исход).
/// Если очистить — становится союзником позже в игре.
final class FrostGuardianKromar: Boss {

    // MARK: - Configuration

    private struct Config {
        static let maxHealth: Int = 250         // TODO: Много HP
        static let contactDamage: Int = 3       // TODO: Сильный контактный урон
        static let freezeDamage: Int = 2        // TODO: Урон от замораживания
        static let moveSpeed: CGFloat = 40      // TODO: Очень медленный
        static let size = CGSize(width: 112, height: 144)  // Огромный

        // Механика очищения
        static let purifyThreshold: Int = 50    // TODO: HP при котором можно очистить
        static let purifyWindowDuration: TimeInterval = 5.0  // TODO

        // Cooldowns
        static let iceBreathCooldown: TimeInterval = 4.0    // TODO
        static let groundFreezeCooldown: TimeInterval = 6.0 // TODO
        static let avalancheCooldown: TimeInterval = 10.0   // TODO
        static let iceSpikesCooldown: TimeInterval = 3.0    // TODO
    }

    // MARK: - Phases

    // TODO: Фаза 1 (100% - 60% HP)
    // - Медленные но мощные атаки
    // - Ледяное дыхание
    // - Замораживает пол

    // TODO: Фаза 2 (60% - 30% HP)
    // - Вызывает лавину (камни сверху)
    // - Ледяные шипы из пола
    // - Создаёт ледяные стены

    // TODO: Фаза 3 (30% - 0% HP) ИЛИ Очищение
    // - Бешенство: все атаки быстрее
    // - ИЛИ при HP < purifyThreshold появляется окно очищения
    // - Игрок с навыком "Очищение" (уровень 7) может очистить

    // MARK: - Attack Patterns

    // TODO: IceBreath - ледяное дыхание
    // - Конус впереди
    // - Замедляет игрока
    // - Накапливает стаки замораживания

    // TODO: GroundFreeze - замораживание пола
    // - Пол становится скользким
    // - Появляются ледяные шипы

    // TODO: IceSpikes - ледяные шипы
    // - Появляются под игроком
    // - Индикатор за 1 сек до появления

    // TODO: Avalanche - лавина
    // - Камни падают сверху
    // - Нужно уворачиваться
    // - Некоторые камни разрушают платформы

    // TODO: IceWall - ледяная стена
    // - Блокирует путь
    // - Можно разрушить ударами
    // - Или подождать пока растает

    // MARK: - Properties

    /// Можно ли сейчас очистить босса
    private var canBePurified: Bool = false

    /// Был ли очищен (альтернативный исход)
    private(set) var wasPurified: Bool = false

    /// Стаки замораживания на игроке
    private var freezeStacksOnPlayer: Int = 0
    private let maxFreezeStacks: Int = 5  // При достижении — полная заморозка

    // MARK: - Init

    init() {
        // TODO: Инициализация
        // - Огромный ледяной голем
        // - Частицы снега вокруг
        // - Светящиеся голубые глаза
        // - Лёд трескается при повреждениях
        fatalError("FrostGuardianKromar: Not implemented")
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Purification Mechanic

    // TODO: Реализовать механику очищения
    // func attemptPurify(player: Player) -> Bool
    // - Проверить наличие навыка очищения
    // - Проверить HP босса
    // - Анимация очищения
    // - Изменить исход боя

    // TODO: Альтернативные диалоги
    // - При очищении: благодарность, обещание помочь
    // - При убийстве: обычная смерть босса

    // MARK: - Freeze Mechanics

    // TODO: Система заморозки игрока
    // - Накопление стаков при попадании ледяных атак
    // - При 5 стаках — полная заморозка (1.5 сек без движения)
    // - Стаки спадают со временем
}
