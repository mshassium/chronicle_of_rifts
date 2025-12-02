# Фаза 3: Враги и ИИ — Детальные промпты

## Обзор

Эта фаза посвящена созданию системы врагов для игры «Хроники Разломов». Все враги должны интегрироваться с существующей архитектурой:
- Использовать `PhysicsCategory` из `Utils/PhysicsCategories.swift`
- Работать с `AnimationManager` для анимаций
- Поддерживать систему урона через `HitInfo` и уведомление `.entityHit`
- Загружаться через `LevelLoader` по типу из `EnemySpawnData`

---

## 3.1 Базовый класс врага

### Промпт

```
Создай базовый класс Enemy для всех врагов игры «Хроники Разломов».

КОНТЕКСТ ПРОЕКТА:
- Движок: SpriteKit, Swift 5.9, iOS 15+
- Игрок реализован в Entities/Player.swift с состояниями через enum PlayerState
- Физические категории в Utils/PhysicsCategories.swift:
  - PhysicsCategory.enemy = 0b100
  - PhysicsCategory.player = 0b1
  - PhysicsCategory.ground = 0b10
  - PhysicsCategory.playerAttack = 0b1000000
- Анимации через AnimationManager.shared
- Урон через HitInfo и Notification.Name.entityHit
- Враги спавнятся из LevelData.enemies (тип EnemySpawnData с полями: type, position, patrolPath, facing)

ТРЕБОВАНИЯ К Enemy:

1. СОСТОЯНИЯ (enum EnemyState):
   - idle: Стоит на месте
   - patrol: Патрулирует между точками
   - chase: Преследует игрока
   - attack: Атакует
   - hurt: Получил урон
   - dead: Мёртв

2. КОНФИГУРАЦИЯ (struct EnemyConfig):
   - health: Int — здоровье
   - damage: Int — урон при контакте
   - moveSpeed: CGFloat — скорость движения
   - detectionRange: CGFloat — радиус обнаружения игрока
   - attackRange: CGFloat — радиус атаки
   - attackCooldown: TimeInterval — перезарядка атаки
   - scoreValue: Int — очки за убийство
   - canBeStomped: Bool — можно ли убить прыжком сверху (как в Марио)
   - knockbackResistance: CGFloat — сопротивление отбрасыванию (0-1)

3. СВОЙСТВА:
   - currentState: EnemyState
   - config: EnemyConfig
   - facingDirection: Direction (.left/.right)
   - velocity: CGVector
   - isGrounded: Bool
   - patrolPath: [CGPoint]? — путь патрулирования
   - currentPatrolIndex: Int
   - targetPlayer: Player? (weak reference)

4. ФИЗИКА:
   - categoryBitMask = PhysicsCategory.enemy
   - collisionBitMask = PhysicsCategory.ground
   - contactTestBitMask = PhysicsCategory.player | PhysicsCategory.playerAttack

5. МЕТОДЫ:
   - init(config: EnemyConfig, entityType: String)
   - update(deltaTime: TimeInterval) — главный цикл обновления
   - setupPhysicsBody(size: CGSize) — настройка физики
   - changeState(to: EnemyState) — машина состояний
   - canTransition(to: EnemyState) -> Bool
   - onStateEnter(_ state: EnemyState)
   - onStateExit(_ state: EnemyState)

   Обнаружение и ИИ:
   - detectPlayer() -> Player? — поиск игрока в радиусе
   - canSeePlayer(_ player: Player) -> Bool — проверка видимости
   - moveTowards(point: CGPoint) — движение к точке
   - turnAround() — разворот
   - checkEdge() -> Bool — проверка края платформы

   Патрулирование:
   - updatePatrol(deltaTime: TimeInterval)
   - getNextPatrolPoint() -> CGPoint?

   Преследование:
   - updateChase(deltaTime: TimeInterval, target: Player)

   Боевая система:
   - takeDamage(_ hitInfo: HitInfo) — получение урона
   - die() — смерть с анимацией и дропом
   - dealContactDamage(to player: Player) — нанесение контактного урона
   - handleStomp(by player: Player) — обработка прыжка сверху

   Анимация:
   - playAnimation(for state: EnemyState)
   - getAnimationName(for state: EnemyState) -> String

6. УВЕДОМЛЕНИЯ:
   - Подписка на .entityHit для получения урона
   - Отправка .enemyDied при смерти (userInfo: ["enemy": self, "scoreValue": config.scoreValue])

7. ВИЗУАЛ:
   - Placeholder: цветной прямоугольник (красный для врагов)
   - Индикатор здоровья над головой (опционально, для врагов с HP > 1)

СТРУКТУРА ФАЙЛА:
- Entities/Enemy.swift

ПОСЛЕ СОЗДАНИЯ:
1. Добавь файл Enemy.swift в Xcode проект:
   - Открой ChroniclesOfRifts.xcodeproj
   - В навигаторе найди группу Entities
   - Добавь новый файл Enemy.swift

2. Добавь новое уведомление в расширение Notification.Name (можно в том же файле или в отдельном):
   static let enemyDied = Notification.Name("enemyDied")

3. Проверь сборку командой:
   xcodebuild -project ChroniclesOfRifts/ChroniclesOfRifts.xcodeproj -scheme ChroniclesOfRifts -configuration Debug build

4. Проверь код на:
   - Все импорты присутствуют (SpriteKit)
   - PhysicsCategory используется корректно
   - Нет retain cycles (weak references где нужно)
   - State machine корректно обрабатывает все переходы
   - Методы detectPlayer и canSeePlayer работают через scene?.children
```

---

## 3.2 Типы врагов (уровни 1-3)

### 3.2.1 Cultist (Культист)

```
Создай класс Cultist — базового врага для первых уровней игры.

КОНТЕКСТ:
- Наследуется от Enemy (Entities/Enemy.swift)
- Это культист с кинжалом, самый простой враг
- Появляется на уровнях 1-3

ХАРАКТЕРИСТИКИ:
- HP: 1
- Урон: 1
- Скорость: 80 пикселей/сек
- Радиус обнаружения: 150 пикселей
- Радиус атаки: 30 пикселей
- Можно убить прыжком сверху (canBeStomped = true)
- Очки: 10

ПОВЕДЕНИЕ:
1. Idle: Стоит на месте, смотрит в одну сторону
2. Patrol: Ходит между точками патруля (если задан patrolPath)
   - Разворачивается у края платформы
   - Разворачивается при столкновении со стеной
3. Chase: Бежит к игроку когда видит его
   - Не прыгает
   - Останавливается у края платформы
4. Attack: Наносит урон при контакте

ОСОБЕННОСТИ:
- При обнаружении игрока — короткая пауза (0.3 сек) с "!" эффектом
- При получении урона — небольшой knockback
- При смерти от прыжка сверху — сплющивание (squash эффект)

АНИМАЦИИ (placeholder через AnimationManager):
- idle: 2 кадра
- walk: 4 кадра
- hurt: 1 кадр
- death: 3 кадра

ВИЗУАЛ:
- Размер: 24x32 пикселей
- Цвет placeholder: тёмно-красный (#8B0000)

СТРУКТУРА ФАЙЛА:
- Entities/Enemies/Cultist.swift

ПОСЛЕ СОЗДАНИЯ:
1. Создай папку Entities/Enemies/ если её нет
2. Добавь Cultist.swift в проект Xcode в группу Entities/Enemies
3. В AnimationManager добавь конфигурацию анимаций для "cultist":

   struct CultistAnimationConfig {
       static let animations: [(name: String, frames: Int, timePerFrame: TimeInterval, repeats: Bool)] = [
           ("idle", 2, 0.3, true),
           ("walk", 4, 0.15, true),
           ("hurt", 1, 0.2, false),
           ("death", 3, 0.15, false)
       ]
       static let size = CGSize(width: 24, height: 32)
       static let color = UIColor(red: 0.545, green: 0, blue: 0, alpha: 1.0)
   }

4. В методе setupPlayerPlaceholderAnimations() добавь вызов setupCultistPlaceholderAnimations()

5. Проверь сборку:
   xcodebuild -project ChroniclesOfRifts/ChroniclesOfRifts.xcodeproj -scheme ChroniclesOfRifts -configuration Debug build

6. Проверь код на:
   - Корректное наследование от Enemy
   - Правильная инициализация с EnemyConfig
   - Логика патрулирования не выходит за края платформы
   - Alert state ("!") корректно прерывается при потере игрока из виду
```

### 3.2.2 CorruptedSpirit (Искажённый дух)

```
Создай класс CorruptedSpirit — летающего призрачного врага для уровня 3.

КОНТЕКСТ:
- Наследуется от Enemy (Entities/Enemy.swift)
- Призрачное существо, заражённое скверной
- Появляется в «Корнях Мира» (уровень 3)

ХАРАКТЕРИСТИКИ:
- HP: 1
- Урон: 1
- Скорость: 60 пикселей/сек
- Радиус обнаружения: 200 пикселей
- Не может быть убит прыжком сверху (canBeStomped = false)
- Очки: 15
- Сопротивление отбрасыванию: 0.5

ПОВЕДЕНИЕ:
1. Patrol: Летает по синусоиде
   - Базовое горизонтальное движение между точками
   - Вертикальное смещение: sin(time * frequency) * amplitude
   - amplitude = 30 пикселей
   - frequency = 2.0

2. Периодическая неуязвимость:
   - Каждые 3 секунды становится полупрозрачным на 1.5 сек
   - В прозрачном состоянии: alpha = 0.3, isInvulnerable = true
   - Не может атаковать в прозрачном состоянии

3. Chase: Медленно плывёт к игроку (игнорирует препятствия — призрак!)

ОСОБЕННОСТИ:
- Не подчиняется гравитации (physicsBody.affectedByGravity = false)
- Проходит сквозь платформы (collisionBitMask = 0)
- Свечение/аура вокруг (SKEffectNode с blur или glow)

АНИМАЦИИ:
- idle: 4 кадра (плавное мерцание)
- move: 4 кадра
- fade: 2 кадра (для перехода в прозрачность)
- death: 4 кадра (рассеивание)

ВИЗУАЛ:
- Размер: 28x28 пикселей
- Цвет: полупрозрачный фиолетовый (#9932CC с alpha 0.7)
- Эффект свечения

СТРУКТУРА ФАЙЛА:
- Entities/Enemies/CorruptedSpirit.swift

ПОСЛЕ СОЗДАНИЯ:
1. Добавь файл в проект Xcode
2. Добавь конфигурацию анимаций в AnimationManager:

   struct CorruptedSpiritAnimationConfig {
       static let animations: [(name: String, frames: Int, timePerFrame: TimeInterval, repeats: Bool)] = [
           ("idle", 4, 0.25, true),
           ("move", 4, 0.2, true),
           ("fade", 2, 0.3, false),
           ("death", 4, 0.15, false)
       ]
       static let size = CGSize(width: 28, height: 28)
       static let color = UIColor(red: 0.6, green: 0.2, blue: 0.8, alpha: 0.7)
   }

3. Проверь сборку
4. Проверь код на:
   - Синусоидальное движение использует правильную формулу
   - Таймер неуязвимости работает корректно
   - Призрак действительно игнорирует коллизии с ground
   - Glow эффект не создаёт проблем производительности
```

### 3.2.3 FloatingEye (Летающий глаз)

```
Создай класс FloatingEye — летающего стреляющего врага.

КОНТЕКСТ:
- Наследуется от Enemy
- Парящий глаз, стреляет магическими снарядами
- Появляется на уровнях 2-3

ХАРАКТЕРИСТИКИ:
- HP: 1
- Урон снаряда: 1
- Скорость полёта: 40 пикселей/сек
- Радиус обнаружения: 250 пикселей
- Дальность стрельбы: 200 пикселей
- Интервал стрельбы: 2.0 секунды
- Не может быть убит прыжком (canBeStomped = false)
- Очки: 20

ПОВЕДЕНИЕ:
1. Patrol: Медленно парит вверх-вниз на месте
2. Alert: При обнаружении игрока — фокусируется (зрачок поворачивается)
3. Attack:
   - Стреляет снарядом в направлении игрока
   - После выстрела — пауза 0.5 сек (отдача)
   - Снаряды можно уничтожить атакой игрока

4. Retreat: Если игрок слишком близко (< 80 пикселей), отлетает назад

СНАРЯД (EyeProjectile):
- Отдельный класс/структура
- Размер: 8x8 пикселей
- Скорость: 150 пикселей/сек
- Летит по прямой
- Уничтожается при контакте с ground, player, playerAttack
- categoryBitMask = новая категория PhysicsCategory.enemyProjectile
- Время жизни: 3 секунды

ВИЗУАЛ:
- Размер глаза: 32x32 пикселя
- Цвет: белый с красным зрачком
- Зрачок следит за игроком (поворачивается)
- Снаряд: фиолетовый шар с trail эффектом

АНИМАЦИИ:
- idle: 2 кадра (моргание)
- alert: 2 кадра (расширение зрачка)
- attack: 3 кадра (выстрел)
- death: 3 кадра

СТРУКТУРА ФАЙЛОВ:
- Entities/Enemies/FloatingEye.swift
- Entities/Projectiles/EyeProjectile.swift

ПОСЛЕ СОЗДАНИЯ:
1. Добавь новую категорию в PhysicsCategories.swift:
   static let enemyProjectile: UInt32 = 0b10000000

2. Обнови contactTestBitMask игрока в Player.swift чтобы включить enemyProjectile

3. Создай папку Entities/Projectiles/ и добавь EyeProjectile.swift

4. Добавь оба файла в проект Xcode

5. Добавь конфигурации анимаций в AnimationManager

6. Проверь сборку

7. Проверь код на:
   - Снаряды корректно удаляются после времени жизни
   - Снаряды уничтожаются при попадании playerAttack
   - Зрачок следит за игроком через atan2
   - Нет утечки памяти при создании множества снарядов
   - Retreat поведение не заставляет врага улетать за границы уровня
```

---

## 3.3 Дополнительные враги (уровни 4-7)

### 3.3.1 Skeleton (Скелет)

```
Создай класс Skeleton — врага со щитом для уровня 4 (Катакомбы).

ХАРАКТЕРИСТИКИ:
- HP: 2
- Урон: 1
- Скорость: 70 пикселей/сек
- Радиус обнаружения: 120 пикселей
- Может блокировать атаки щитом
- Очки: 25
- canBeStomped = true

ПОВЕДЕНИЕ:
1. Patrol: Ходит между точками
2. Block:
   - При виде игрока поднимает щит
   - В состоянии блока неуязвим спереди
   - Атаки сзади проходят
3. Attack:
   - Опускает щит для атаки (окно уязвимости 0.5 сек)
   - Удар мечом вперёд
   - После атаки снова поднимает щит

ОСОБЕННОСТИ:
- Щит блокирует только атаки спереди
- Определение "спереди" через сравнение позиций
- При блоке — визуальный эффект (искры)
- Можно обойти сзади

ВИЗУАЛ:
- Размер: 24x40 пикселей
- Цвет: серо-белый (кости)
- Щит: отдельный child node

СТРУКТУРА ФАЙЛА:
- Entities/Enemies/Skeleton.swift

ПОСЛЕ СОЗДАНИЯ:
1. Добавь файл в проект
2. Добавь анимации в AnimationManager
3. Проверь сборку
4. Проверь:
   - Блок работает только с фронтальных атак
   - Окно уязвимости при атаке корректное
   - Щит визуально поднимается/опускается
```

### 3.3.2 IceGolem (Ледяной голем)

```
Создай класс IceGolem — медленного мощного врага для уровня 5 (Штормовые Пики).

ХАРАКТЕРИСТИКИ:
- HP: 3
- Урон: 2
- Скорость: 40 пикселей/сек
- Радиус обнаружения: 100 пикселей
- knockbackResistance = 1.0 (не отбрасывается)
- Очки: 40
- canBeStomped = false

ПОВЕДЕНИЕ:
1. Patrol: Очень медленно ходит
2. Chase: Идёт к игроку, не ускоряется
3. Attack:
   - Удар кулаком (медленный, 1 сек подготовка)
   - Большой радиус удара
   - Оставляет ледяной след

ОСОБЕННОСТИ:
- При контакте замедляет игрока на 2 секунды (slow эффект)
- Slow: скорость игрока * 0.5
- Визуальный эффект заморозки на игроке (голубой оттенок)
- Уведомление .playerSlowed для применения эффекта

ВИЗУАЛ:
- Размер: 48x56 пикселей
- Цвет: голубой лёд (#ADD8E6)
- Частицы снега вокруг

СТРУКТУРА ФАЙЛА:
- Entities/Enemies/IceGolem.swift

ПОСЛЕ СОЗДАНИЯ:
1. Добавь файл в проект
2. Добавь уведомление .playerSlowed в Notification.Name
3. В Player.swift добавь обработку slow эффекта:
   - Свойство slowMultiplier: CGFloat = 1.0
   - Таймер slowTimer
   - Метод applySlow(duration: TimeInterval, multiplier: CGFloat)
4. Проверь сборку
5. Проверь:
   - Голем не отбрасывается при ударе
   - Slow эффект корректно применяется и снимается
   - Визуальные эффекты не влияют на производительность
```

### 3.3.3 SkyDevourer (Пожиратель Неба)

```
Создай класс SkyDevourer — летающего врага для уровня 6 (Море Осколков).

ХАРАКТЕРИСТИКИ:
- HP: 2
- Урон: 1
- Скорость полёта: 100 пикселей/сек
- Скорость пике: 300 пикселей/сек
- Радиус обнаружения: 200 пикселей
- Очки: 30
- canBeStomped = true (только когда на земле после пике)

ПОВЕДЕНИЕ:
1. Patrol: Летает кругами/восьмёркой на высоте
2. Dive Attack:
   - Выбирает точку над игроком
   - Пикирует вниз с ускорением
   - При промахе — врезается в землю (stunned 1 сек)
   - В stunned можно убить прыжком
3. Grab (опционально):
   - Может схватить игрока
   - Поднимает вверх на 2 секунды
   - Игрок может вырваться (spam attack)
   - Урон при падении если не вырвался

ОСОБЕННОСТИ:
- Игнорирует гравитацию в воздухе
- После пике временно на земле (подчиняется гравитации)
- Красная тень под ним при подготовке к пике

ВИЗУАЛ:
- Размер: 40x24 пикселей (птица)
- Цвет: тёмно-серый с фиолетовыми глазами

СТРУКТУРА ФАЙЛА:
- Entities/Enemies/SkyDevourer.swift

ПОСЛЕ СОЗДАНИЯ:
1. Добавь файл в проект
2. Если реализуешь Grab — добавь состояние .grabbed в Player
3. Проверь сборку
4. Проверь:
   - Пике корректно рассчитывает траекторию
   - Stunned состояние работает по таймеру
   - Тень появляется в правильной позиции
```

### 3.3.4 EliteCultist (Элитный культист)

```
Создай класс EliteCultist — магического врага для уровня 7.

ХАРАКТЕРИСТИКИ:
- HP: 2
- Урон: 1
- Скорость: 90 пикселей/сек
- Радиус обнаружения: 180 пикселей
- Телепорт: дальность 100 пикселей, кулдаун 3 сек
- Очки: 35
- canBeStomped = true

ПОВЕДЕНИЕ:
1. Patrol: Ходит как обычный культист
2. Alert: При обнаружении игрока — начинает кастовать
3. Attack (дальний):
   - Магический снаряд (аналогично FloatingEye)
   - Кастует 0.5 сек перед выстрелом
4. Teleport:
   - Если игрок слишком близко
   - Телепортируется на случайную позицию в радиусе
   - Эффект исчезновения/появления
5. Retreat: После телепорта — атакует издалека

ОСОБЕННОСТИ:
- Снаряд медленнее чем у FloatingEye (100 пикс/сек)
- Телепорт имеет короткий delay (0.2 сек) — можно прервать атакой
- При телепорте оставляет "послеобраз"

ВИЗУАЛ:
- Размер: 24x36 пикселей
- Цвет: тёмно-фиолетовый с золотыми акцентами

СТРУКТУРА ФАЙЛА:
- Entities/Enemies/EliteCultist.swift

ПОСЛЕ СОЗДАНИЯ:
1. Добавь файл в проект
2. Можно переиспользовать EyeProjectile или создать CultistProjectile
3. Проверь сборку
4. Проверь:
   - Телепорт не переносит за границы уровня
   - Каст можно прервать уроном
   - Послеобраз корректно исчезает
```

---

## 3.4 Система боссов

### 3.4.1 Базовый класс Boss

```
Создай базовый класс Boss для всех боссов игры.

КОНТЕКСТ:
- Наследуется от Enemy
- Боссы имеют несколько фаз
- UI с полоской здоровья

ТРЕБОВАНИЯ:

1. BossPhase (protocol):
   - healthThreshold: CGFloat (0.0-1.0) — порог здоровья для активации
   - patterns: [AttackPattern] — доступные паттерны атак
   - onEnter() — при входе в фазу
   - onExit() — при выходе из фазы

2. AttackPattern (protocol):
   - name: String
   - duration: TimeInterval
   - cooldown: TimeInterval
   - execute(target: Player, completion: @escaping () -> Void)
   - canExecute() -> Bool

3. Boss class:
   Свойства:
   - phases: [BossPhase]
   - currentPhaseIndex: Int
   - bossName: String (для UI)
   - isInvulnerableDuringTransition: Bool
   - currentPattern: AttackPattern?

   Методы:
   - checkPhaseTransition() — проверка перехода в следующую фазу
   - transitionToPhase(_ index: Int) — анимированный переход
   - selectNextPattern() -> AttackPattern? — выбор следующей атаки
   - executePattern(_ pattern: AttackPattern)
   - showVulnerabilityWindow(duration: TimeInterval) — окно уязвимости

   UI:
   - Уведомление .bossEncountered при первом обнаружении игрока
   - Уведомление .bossPhaseChanged при смене фазы
   - Уведомление .bossDefeated при смерти

4. BossArena:
   - Боссы сражаются в закрытых аренах
   - При входе — закрыть выходы
   - При победе — открыть

ВИЗУАЛ:
- Боссы крупнее обычных врагов
- Эффект "ауры" вокруг босса
- Анимация перехода между фазами

СТРУКТУРА ФАЙЛОВ:
- Entities/Bosses/Boss.swift
- Entities/Bosses/BossPhase.swift
- Entities/Bosses/AttackPattern.swift

ПОСЛЕ СОЗДАНИЯ:
1. Создай папку Entities/Bosses/
2. Добавь файлы в проект
3. Добавь уведомления:
   - .bossEncountered
   - .bossPhaseChanged
   - .bossDefeated
4. Проверь сборку
5. Проверь:
   - Фазы корректно переключаются по порогам здоровья
   - Неуязвимость во время перехода работает
   - Паттерны выполняются последовательно
```

### 3.4.2 Defiler (Осквернитель) — Босс уровня 1

```
Создай класс Defiler — первого босса игры (уровень 1).

КОНТЕКСТ:
- Бывший страж, обращённый тьмой
- Друг детства Каэля (сюжетная значимость)
- Обучающий босс — должен научить механикам боссов

ХАРАКТЕРИСТИКИ:
- HP: 100
- Урон контакт: 1
- Урон атаки: 1
- Размер: 48x64 пикселей
- Скорость: 80 пикселей/сек

ФАЗЫ:

Фаза 1 (HP 100%-50%):
Паттерны:
1. JumpSlam:
   - Прыгает к игроку
   - При приземлении — волна по земле
   - Волна: GroundWave entity, движется горизонтально
   - Нужно перепрыгнуть волну
   - Кулдаун: 3 сек

2. SlashCombo:
   - 2 удара мечом подряд
   - Окно между ударами 0.3 сек
   - После комбо — пауза 1 сек (уязвимость)
   - Кулдаун: 4 сек

Фаза 2 (HP 50%-0%):
- Скорость увеличивается на 30%
- Добавляется паттерн:

3. SummonMinions:
   - Призывает 2 мелких культистов
   - Максимум 4 миньона одновременно
   - Кулдаун: 8 сек
   - Во время призыва — уязвим

ВИЗУАЛ:
- Цвет: тёмно-серый с фиолетовыми прожилками скверны
- При переходе во вторую фазу — вспышка, крик
- Глаза горят фиолетовым

АРЕНА:
- Плоская платформа
- Стены слева и справа (нельзя выйти)
- Размер: 20x8 тайлов (640x256 пикселей)

ДИАЛОГ:
- Перед боем: "Каэль... прости... я не могу... контролировать..."
- При переходе в фазу 2: "БОЛЬШЕ! СИЛЫ!"
- При смерти: "Спасибо... друг..."

СТРУКТУРА ФАЙЛА:
- Entities/Bosses/Defiler.swift
- Entities/Projectiles/GroundWave.swift

ПОСЛЕ СОЗДАНИЯ:
1. Добавь файлы в проект
2. Создай GroundWave как отдельную сущность:
   - SKSpriteNode
   - Движется горизонтально
   - Урон при контакте
   - Исчезает у стен или через 2 сек
3. Проверь сборку
4. Проверь:
   - JumpSlam приземляется в позицию игрока
   - GroundWave движется в правильном направлении
   - Миньоны спавнятся в пределах арены
   - Диалоги интегрированы (через TriggerData)
```

### 3.4.3 Структура остальных боссов (обзор)

```
Создай заглушки (stub классы) для остальных боссов игры.
Каждый файл должен содержать базовую структуру с TODO комментариями.

СПИСОК БОССОВ:

1. ChainMasterGrondar (уровень 2):
   - Гигант с механическими руками
   - Разрушает платформы
   - Уязвим когда застревает

2. HeartOfCorruption (уровень 3):
   - Стационарный босс (паразит в дереве)
   - Атакует щупальцами
   - Нужно уничтожить защитные наросты

3. ArchnecromancerSalvus (уровень 4):
   - Призывает скелетов
   - Телепортируется
   - Луч смерти

4. FrostGuardianKromar (уровень 5):
   - Ледяной голем-гигант
   - Можно очистить вместо убийства
   - Альтернативный исход

5. SkyQueenSkirra (уровень 6):
   - Бой на движущихся платформах
   - Воздушные атаки
   - Призыв птенцов

6. GeneralMaltorus (уровень 7):
   - Самый сложный обычный босс
   - Комбо атаки
   - Призыв культистов

7. Morgana (уровень 9):
   - 3 фазы
   - Теневая магия
   - Слияние с Велькором

8. Velkor (уровень 10):
   - Финальный босс
   - Не прямой бой
   - Активация 4 цепей
   - Платформинг-финал

СТРУКТУРА ФАЙЛОВ:
Для каждого босса создай файл в Entities/Bosses/:
- ChainMasterGrondar.swift
- HeartOfCorruption.swift
- ArchnecromancerSalvus.swift
- FrostGuardianKromar.swift
- SkyQueenSkirra.swift
- GeneralMaltorus.swift
- Morgana.swift
- Velkor.swift

ШАБЛОН ЗАГЛУШКИ:
```swift
import SpriteKit

/// [Имя босса] — босс уровня [N]
/// [Краткое описание]
final class [BossName]: Boss {

    // MARK: - Configuration

    private struct Config {
        static let maxHealth: Int = 0 // TODO
        static let damage: Int = 0 // TODO
        static let moveSpeed: CGFloat = 0 // TODO
        // TODO: Добавить остальные параметры
    }

    // MARK: - Phases

    // TODO: Определить фазы босса

    // MARK: - Init

    init() {
        // TODO: Инициализация
        fatalError("Not implemented")
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Attack Patterns

    // TODO: Реализовать паттерны атак
}
```

ПОСЛЕ СОЗДАНИЯ:
1. Создай все 8 файлов
2. Добавь в проект Xcode
3. Проверь сборку (несмотря на fatalError, код должен компилироваться)
4. Каждый файл должен содержать:
   - Описание босса в комментарии
   - Список фаз и паттернов в TODO
   - Базовую структуру Config
```

---

## 3.5 Фабрика врагов и интеграция

### Промпт

```
Создай EnemyFactory для создания врагов по типу из LevelData.

КОНТЕКСТ:
- LevelLoader загружает JSON с массивом enemies: [EnemySpawnData]
- EnemySpawnData содержит: type (String), position, patrolPath, facing
- Нужно создавать нужный класс врага по строковому типу

ТРЕБОВАНИЯ:

1. EnemyFactory (static class или enum):

   static func createEnemy(from data: EnemySpawnData) -> Enemy?

   Маппинг типов:
   - "Cultist" -> Cultist
   - "CorruptedSpirit" -> CorruptedSpirit
   - "FloatingEye" -> FloatingEye
   - "Skeleton" -> Skeleton
   - "IceGolem" -> IceGolem
   - "SkyDevourer" -> SkyDevourer
   - "EliteCultist" -> EliteCultist

   Для боссов:
   - "Defiler" -> Defiler
   - и т.д.

2. Настройка врага:
   - Установить позицию из data.position
   - Установить patrolPath если есть
   - Установить начальное направление из data.facing

3. Регистрация новых типов:
   - Метод registerEnemyType(_ type: String, creator: () -> Enemy)
   - Для расширяемости

СТРУКТУРА ФАЙЛА:
- Entities/EnemyFactory.swift

ИНТЕГРАЦИЯ В LevelLoader:
Добавь в LevelLoader.swift метод:

func spawnEnemies(in scene: SKScene, from levelData: LevelData) {
    for enemyData in levelData.enemies {
        guard let enemy = EnemyFactory.createEnemy(from: enemyData) else {
            print("Unknown enemy type: \(enemyData.type)")
            continue
        }

        enemy.position = enemyData.position.toPixels(tileSize: levelData.tileSize)
        if let path = enemyData.patrolPath {
            enemy.patrolPath = path.map { $0.toPixels(tileSize: levelData.tileSize) }
        }

        scene.addChild(enemy)
    }
}

ПОСЛЕ СОЗДАНИЯ:
1. Добавь EnemyFactory.swift в проект
2. Обнови LevelLoader с методом spawnEnemies
3. В GameScene добавь вызов spawnEnemies при загрузке уровня
4. Проверь сборку
5. Проверь:
   - Все существующие типы врагов регистрируются
   - Неизвестные типы логируются, но не крашат игру
   - Позиции и пути корректно конвертируются в пиксели
```

---

## 3.6 Обработка коллизий врагов в GameScene

### Промпт

```
Обнови GameScene для обработки коллизий с врагами.

КОНТЕКСТ:
- GameScene уже обрабатывает коллизии через SKPhysicsContactDelegate
- Нужно добавить обработку:
  - player <-> enemy (контактный урон)
  - playerAttack <-> enemy (урон врагу)
  - player <-> enemyProjectile (урон игроку)

ТРЕБОВАНИЯ:

В метод didBegin(_ contact: SKPhysicsContact) добавь:

1. Player -> Enemy контакт:
   - Проверить, прыгает ли игрок сверху (stomp)
   - Если stomp и enemy.canBeStomped:
     - enemy.handleStomp(by: player)
     - player.bounce()
   - Иначе:
     - enemy.dealContactDamage(to: player)

2. PlayerAttack -> Enemy:
   - Получить MeleeAttack из hitbox.userData["attack"]
   - Вызвать meleeAttack.processHit(on: enemy)
   - Enemy получит урон через .entityHit notification

3. Player -> EnemyProjectile:
   - player.takeDamage(1)
   - projectile.removeFromParent()

ВСПОМОГАТЕЛЬНЫЕ МЕТОДЫ:

/// Проверяет, является ли контакт "прыжком сверху"
func isStompContact(_ contact: SKPhysicsContact, player: Player, enemy: Enemy) -> Bool {
    // Игрок должен быть выше врага
    let playerBottom = player.position.y - player.size.height / 2
    let enemyTop = enemy.position.y + enemy.size.height / 2

    // Игрок должен падать
    let isFalling = player.velocity.dy < 0

    // Игрок должен быть достаточно выше
    let heightDiff = playerBottom - enemyTop

    return isFalling && heightDiff > -10
}

ПОСЛЕ ИЗМЕНЕНИЙ:
1. Обнови GameScene.swift
2. Проверь сборку
3. Проверь логику:
   - Stomp срабатывает только при падении сверху
   - Контактный урон не наносится при stomp
   - Projectile уничтожается после урона
   - Нет двойного урона за один контакт
```

---

## Чек-лист завершения Фазы 3

```
□ Enemy базовый класс создан и работает
□ Все враги уровней 1-3 реализованы (Cultist, CorruptedSpirit, FloatingEye)
□ Все враги уровней 4-7 реализованы (Skeleton, IceGolem, SkyDevourer, EliteCultist)
□ Boss базовый класс создан
□ Defiler (первый босс) полностью реализован
□ Заглушки для остальных боссов созданы
□ EnemyFactory работает
□ Враги спавнятся из LevelData
□ Коллизии player<->enemy обрабатываются
□ Stomp механика работает
□ Projectiles врагов работают
□ Проект собирается без ошибок
□ Нет retain cycles и утечек памяти
```
