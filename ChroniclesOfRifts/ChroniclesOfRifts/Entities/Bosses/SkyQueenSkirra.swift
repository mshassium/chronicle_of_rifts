import SpriteKit

/// SkyQueenSkirra — босс уровня 6 (Море Осколков)
/// Королева неба — огромная птица/гарпия на летающих островах.
/// Бой на движущихся платформах, воздушные атаки, призыв птенцов.
final class SkyQueenSkirra: Boss {

    // MARK: - Configuration

    private struct Config {
        static let maxHealth: Int = 200         // TODO: Сбалансировать
        static let contactDamage: Int = 2       // TODO: Урон при столкновении
        static let diveDamage: Int = 4          // TODO: Урон от пикирования
        static let moveSpeed: CGFloat = 120     // TODO: Быстрая (летает!)
        static let size = CGSize(width: 80, height: 64)

        // Платформы
        static let platformSpeed: CGFloat = 30  // TODO: Скорость движения платформ
        static let platformCount: Int = 5       // TODO: Количество платформ

        // Птенцы
        static let maxHatchlings: Int = 4       // TODO
        static let hatchlingsPerSummon: Int = 2 // TODO

        // Cooldowns
        static let diveBombCooldown: TimeInterval = 4.0     // TODO
        static let windGustCooldown: TimeInterval = 5.0     // TODO
        static let summonHatchlingsCooldown: TimeInterval = 8.0 // TODO
        static let featherStormCooldown: TimeInterval = 6.0  // TODO
    }

    // MARK: - Phases

    // TODO: Фаза 1 (100% - 65% HP)
    // - Летает между платформами
    // - Базовые атаки пикированием
    // - Призывает 2 птенцов

    // TODO: Фаза 2 (65% - 35% HP)
    // - Платформы начинают двигаться
    // - Порывы ветра (сдувают с платформ)
    // - Шторм перьев

    // TODO: Фаза 3 (35% - 0% HP)
    // - Гнездо в опасности — яростные атаки
    // - Платформы двигаются быстрее
    // - Непрерывные пикирования

    // MARK: - Attack Patterns

    // TODO: DiveBomb - пикирование
    // - Поднимается высоко
    // - Индикатор на земле
    // - Стремительное пикирование
    // - Небольшая область поражения

    // TODO: WindGust - порыв ветра
    // - Горизонтальный порыв
    // - Сдувает игрока в сторону
    // - Можно упасть с платформы!

    // TODO: FeatherStorm - шторм перьев
    // - Множество перьев падают сверху
    // - Нужно уворачиваться
    // - Перья застревают в платформах (временные препятствия)

    // TODO: SummonHatchlings - призыв птенцов
    // - Кричит, зовёт птенцов
    // - Птенцы летают и атакуют игрока
    // - Маленькие, но быстрые

    // TODO: TalonSwipe (ближний бой) - удар когтями
    // - Если игрок близко
    // - Быстрая атака

    // MARK: - Properties

    /// Летит ли босс сейчас
    private var isFlying: Bool = true

    /// Активные птенцы
    private var hatchlings: [SkyHatchling] = []

    /// Платформы арены
    private var platforms: [MovingPlatform] = []

    /// Текущая целевая платформа
    private var targetPlatform: MovingPlatform?

    // MARK: - Init

    init() {
        // TODO: Инициализация
        // - Большая птица/гарпия
        // - Анимация полёта (крылья)
        // - Перья и частицы ветра
        // - Корона или украшения (королева)
        fatalError("SkyQueenSkirra: Not implemented")
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Flying Mechanics

    // TODO: Реализовать механику полёта
    // - Босс не касается земли
    // - Движение между платформами
    // - Временное приземление (окно атаки)

    // MARK: - Platform Management

    // TODO: Управление платформами
    // - Движущиеся платформы
    // - Некоторые платформы временные (исчезают)
    // - Игрок должен прыгать между ними
}

// MARK: - SkyHatchling

/// Птенец Сёрры (миньон босса SkyQueenSkirra)
class SkyHatchling: Enemy {
    // TODO: Реализовать птенца
    // - Маленький, летает
    // - Быстрые атаки
    // - Легко убить (1-2 удара)

    init() {
        fatalError("SkyHatchling: Not implemented")
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - MovingPlatform
// MovingPlatform теперь определён в Components/MovingPlatform.swift
