import SpriteKit

/// ArchnecromancerSalvus — босс уровня 4 (Катакомбы Аурелиона)
/// Могущественный некромант. Телепортируется, призывает скелетов,
/// стреляет лучом смерти. Классический бой с магом.
final class ArchnecromancerSalvus: Boss {

    // MARK: - Configuration

    private struct Config {
        static let maxHealth: Int = 180         // TODO: Сбалансировать
        static let contactDamage: Int = 1       // TODO: Маг слаб в ближнем бою
        static let deathRayDamage: Int = 4      // TODO: Высокий урон от луча
        static let moveSpeed: CGFloat = 50      // TODO: Медленный, но телепортируется
        static let size = CGSize(width: 48, height: 80)

        // Скелеты
        static let maxSkeletons: Int = 6        // TODO
        static let skeletonsPerSummon: Int = 2  // TODO

        // Cooldowns
        static let teleportCooldown: TimeInterval = 4.0     // TODO
        static let deathRayCooldown: TimeInterval = 6.0     // TODO
        static let summonCooldown: TimeInterval = 10.0      // TODO
        static let shadowBoltCooldown: TimeInterval = 2.0   // TODO
    }

    // MARK: - Phases

    // TODO: Фаза 1 (100% - 70% HP)
    // - Базовые заклинания: Shadow Bolt
    // - Телепортируется редко
    // - Призывает 2 скелетов

    // TODO: Фаза 2 (70% - 40% HP)
    // - Луч смерти (нужно уворачиваться)
    // - Телепортируется чаще
    // - Призывает больше скелетов

    // TODO: Фаза 3 (40% - 0% HP)
    // - Непрерывные телепортации
    // - Двойной луч смерти
    // - Скелеты усиливаются

    // MARK: - Attack Patterns

    // TODO: ShadowBolt - тёмный снаряд
    // - Летит к игроку
    // - Можно уклониться

    // TODO: DeathRay - луч смерти
    // - Предупреждение (красная линия)
    // - Затем мгновенный урон по линии
    // - Игрок должен убежать с линии

    // TODO: Teleport - телепортация
    // - Исчезает в дыму
    // - Появляется в случайной точке арены
    // - Неуязвим во время телепортации

    // TODO: SummonSkeletons - призыв скелетов
    // - Круг призыва на полу
    // - Скелеты появляются через секунду
    // - Можно прервать атакой

    // TODO: BoneShield (фаза 3) - щит из костей
    // - Временная неуязвимость
    // - Скелеты взрываются при смерти

    // MARK: - Properties

    /// Активные скелеты
    private var activeSkeletons: [Enemy] = []

    /// Точки телепортации
    private var teleportPoints: [CGPoint] = []

    /// Заряжает ли луч смерти
    private var isChargingDeathRay: Bool = false

    // MARK: - Init

    init() {
        // TODO: Инициализация
        // - Настроить визуал (плащ, посох, светящиеся глаза)
        // - Частицы тьмы вокруг
        // - Настроить точки телепортации
        fatalError("ArchnecromancerSalvus: Not implemented")
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Teleportation

    // TODO: Реализовать телепортацию
    // - Эффект исчезновения (дым, частицы)
    // - Перемещение в новую точку
    // - Эффект появления
    // - Короткий период неуязвимости

    // MARK: - Death Ray

    // TODO: Реализовать луч смерти
    // - Индикатор (красная линия) — 1.5 сек
    // - Луч активируется — мгновенный урон
    // - Луч держится 0.5 сек
    // - Можно прервать урон по боссу во время зарядки
}
