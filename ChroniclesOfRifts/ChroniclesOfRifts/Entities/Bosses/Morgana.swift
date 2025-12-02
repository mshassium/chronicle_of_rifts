import SpriteKit

/// Morgana — босс уровня 9 (Тронный Зал Бездны)
/// Главная антагонистка. 3 фазы боя.
/// Теневая магия, манипуляции, слияние с Велькором в конце.
final class Morgana: Boss {

    // MARK: - Configuration

    private struct Config {
        static let maxHealth: Int = 400         // TODO: Много HP (предфинальный босс)
        static let contactDamage: Int = 2       // TODO
        static let shadowDamage: Int = 3        // TODO: Урон теневой магией
        static let moveSpeed: CGFloat = 100     // TODO: Быстрая
        static let size = CGSize(width: 48, height: 72)

        // Теневые клоны
        static let maxClones: Int = 3           // TODO
        static let cloneHealth: Int = 30        // TODO

        // Cooldowns
        static let shadowBoltCooldown: TimeInterval = 2.0     // TODO
        static let shadowClonesCoolldown: TimeInterval = 10.0 // TODO
        static let voidZoneCooldown: TimeInterval = 8.0       // TODO
        static let darkPactCooldown: TimeInterval = 15.0      // TODO
        static let mindControlCooldown: TimeInterval = 20.0   // TODO
    }

    // MARK: - Phases

    // TODO: Фаза 1 (100% - 65% HP) - Теневая Ведьма
    // - Теневые снаряды
    // - Телепортация
    // - Теневые клоны

    // TODO: Фаза 2 (65% - 30% HP) - Высшая Магия
    // - Зоны пустоты (области урона)
    // - Попытки контроля разума
    // - Более агрессивная

    // TODO: Фаза 3 (30% - 0% HP) - Слияние с Велькором
    // - Частичная трансформация
    // - Получает новые атаки
    // - Арена меняется
    // - При победе — переход к финальному боссу

    // MARK: - Attack Patterns

    // TODO: ShadowBolt - теневой снаряд
    // - Базовая атака
    // - Самонаводящийся (слабо)

    // TODO: ShadowClones - теневые клоны
    // - Создаёт 2-3 клона
    // - Клоны атакуют но слабее
    // - Нужно найти настоящую Моргану

    // TODO: Teleport - телепортация
    // - Исчезает в тенях
    // - Появляется в другом месте
    // - Оставляет теневую ловушку

    // TODO: VoidZone - зона пустоты
    // - Круг на полу
    // - Наносит урон если стоять
    // - Растёт со временем

    // TODO: MindControl - контроль разума
    // - Попытка захватить контроль
    // - Игрок должен быстро нажимать кнопки
    // - Если провал — получает урон

    // TODO: DarkPact - тёмный пакт (фаза 3)
    // - Призывает силу Велькора
    // - Мощная атака по всей арене
    // - Нужно найти безопасную зону

    // TODO: VelkorMerge - слияние с Велькором
    // - Кат-сцена при победе
    // - Моргана сливается с Велькором
    // - Открывается путь к финальному боссу

    // MARK: - Properties

    /// Активные теневые клоны
    private var shadowClones: [ShadowClone] = []

    /// Находится ли в фазе слияния
    private var isMerging: Bool = false

    /// Сила связи с Велькором (влияет на атаки)
    private var velkorConnection: CGFloat = 0  // 0.0 - 1.0

    // MARK: - Dialogs

    static let phase1Dialog = "Глупец! Ты не понимаешь силу, которую я пробудила!"
    static let phase2Dialog = "Чувствуешь? Он уже здесь... Велькор пробуждается!"
    static let phase3Dialog = "Да! ДА! Сила Велькора течёт сквозь меня!"
    static let defeatDialog = "Нет... Велькор... забери меня... Я БУДУ СОСУДОМ!"

    // MARK: - Init

    init() {
        // TODO: Инициализация
        // - Тёмная волшебница
        // - Плащ из теней
        // - Корона/тиара
        // - Светящиеся фиолетовые глаза
        // - Тёмная аура
        fatalError("Morgana: Not implemented")
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Clone Mechanics

    // TODO: Система клонов
    // - Клоны выглядят идентично
    // - Но имеют меньше HP
    // - Настоящая Моргана слегка отличается (подсказка)
    // - При убийстве клона — он исчезает в дыму

    // MARK: - Velkor Connection

    // TODO: Связь с Велькором
    // - Увеличивается в фазе 3
    // - Влияет на визуальные эффекты
    // - Влияет на силу атак
    // - При слиянии — кат-сцена
}

// MARK: - ShadowClone

/// Теневой клон Морганы
class ShadowClone: Boss {
    // TODO: Реализовать теневой клон
    // - Выглядит как Моргана
    // - Меньше HP
    // - Упрощённые атаки
    // - При смерти — эффект рассеивания

    weak var original: Morgana?

    init(original: Morgana) {
        fatalError("ShadowClone: Not implemented")
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
