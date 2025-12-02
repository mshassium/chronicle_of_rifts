import SpriteKit

/// HeartOfCorruption — босс уровня 3 (Корни Мира)
/// Стационарный босс — паразит, захвативший древнее дерево.
/// Атакует щупальцами, защищён наростами которые нужно уничтожить.
final class HeartOfCorruption: Boss {

    // MARK: - Configuration

    private struct Config {
        static let maxHealth: Int = 200         // TODO: Сбалансировать
        static let tentacleDamage: Int = 2      // TODO: Урон от щупалец
        static let moveSpeed: CGFloat = 0       // Стационарный босс!
        static let size = CGSize(width: 128, height: 160)  // Большой

        // Защитные наросты
        static let growthsCount: Int = 4        // TODO: Количество наростов
        static let growthHealth: Int = 30       // TODO: HP каждого нароста

        // Cooldowns
        static let tentacleSlamCooldown: TimeInterval = 3.0   // TODO
        static let sporeCloudCooldown: TimeInterval = 6.0     // TODO
        static let rootBurstCooldown: TimeInterval = 8.0      // TODO
    }

    // MARK: - Phases

    // TODO: Фаза 1 — Защищённое сердце
    // - Все 4 нароста целы
    // - Босс неуязвим к прямым атакам
    // - Атакует медленно

    // TODO: Фаза 2 — Пробуждение (2 нароста уничтожено)
    // - Босс начинает получать урон
    // - Новые атаки: облако спор
    // - Пытается регенерировать наросты

    // TODO: Фаза 3 — Агония (все наросты уничтожено)
    // - Босс полностью уязвим
    // - Бешеные атаки
    // - Корни вырываются из земли

    // MARK: - Attack Patterns

    // TODO: TentacleSlam - удар щупальцем
    // - Бьёт по позиции игрока
    // - Остаётся в земле на секунду (можно атаковать)

    // TODO: TentacleSweep - горизонтальный взмах
    // - Перепрыгиваемая атака
    // - Покрывает большую область

    // TODO: SporeCloud - облако спор
    // - Зона урона над временем
    // - Замедляет игрока

    // TODO: RootBurst - корни из земли
    // - Появляются под игроком
    // - Серия из 3-5 точек

    // MARK: - Properties

    /// Защитные наросты
    private var growths: [CorruptionGrowth] = []

    /// Количество живых наростов
    private var aliveGrowthsCount: Int {
        return growths.filter { !$0.isDestroyed }.count
    }

    // MARK: - Init

    init() {
        // TODO: Инициализация
        // - Стационарная позиция (не двигается)
        // - Создать 4 защитных нароста вокруг
        // - Настроить щупальца (SKSpriteNode или Spine анимации)
        fatalError("HeartOfCorruption: Not implemented")
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Damage Override

    // TODO: Переопределить takeDamage
    // - Пока есть наросты, урон уменьшается
    // - Когда нароста нет — полный урон

    // MARK: - Growths Management

    // TODO: Создание наростов (CorruptionGrowth)
    // - Позиции вокруг босса
    // - Каждый нарост — отдельный Enemy
    // - При уничтожении: проверить переход фазы
}

// MARK: - CorruptionGrowth

/// Защитный нарост (часть босса HeartOfCorruption)
class CorruptionGrowth: SKSpriteNode {
    // TODO: Реализовать защитный нарост
    // - HP
    // - Визуальные эффекты при повреждении
    // - Взрыв при уничтожении

    var isDestroyed: Bool = false

    init() {
        fatalError("CorruptionGrowth: Not implemented")
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
