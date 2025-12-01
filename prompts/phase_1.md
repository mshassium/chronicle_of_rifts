# ФАЗА 1: АРХИТЕКТУРА И БАЗОВЫЙ КАРКАС

## Обзор фазы

**Цель:** Создать прочную архитектурную основу игры, которая будет использоваться на протяжении всей разработки.

**Результат:** Работающий прототип с управлением игровыми состояниями, системой загрузки уровней, камерой и touch-контролами.

---

## 1.1 Игровая архитектура

### Промпт для Claude Code:

```
Создай базовую архитектуру игры для SpriteKit платформера "Хроники Разломов".

ТРЕБОВАНИЯ:

1. GameManager (синглтон):
   Расположение: Managers/GameManager.swift

   Свойства:
   - currentState: GameState (enum: menu, playing, paused, gameOver, cutscene)
   - currentLevel: Int
   - playerData: PlayerData (здоровье, мана, собранные предметы)
   - settings: GameSettings (громкость музыки, громкость звуков, чувствительность)

   Методы:
   - shared: статический экземпляр
   - changeState(to: GameState) - смена состояния с уведомлением
   - saveProgress() - сохранение в UserDefaults
   - loadProgress() - загрузка из UserDefaults
   - resetProgress() - сброс прогресса

   Используй Combine для публикации изменений состояния:
   - @Published var gameState: GameState

2. PlayerData (Codable struct):
   Расположение: Managers/PlayerData.swift

   Свойства:
   - health: Int (1-3)
   - maxHealth: Int
   - mana: Int
   - unlockedLevels: [Int]
   - collectedPages: [String] (ID страниц хроник)
   - levelStats: [Int: LevelStats] (статистика по уровням)

   LevelStats:
   - crystalsCollected: Int
   - secretsFound: Int
   - bestTime: TimeInterval?
   - completed: Bool

3. GameSettings (Codable struct):
   Расположение: Managers/GameSettings.swift

   Свойства:
   - musicVolume: Float (0.0-1.0)
   - sfxVolume: Float (0.0-1.0)
   - joystickSensitivity: Float (0.5-2.0)
   - showFPS: Bool (только для debug)

4. SceneManager:
   Расположение: Managers/SceneManager.swift

   Методы:
   - presentScene(_ scene: SKScene, transition: SKTransition?)
   - presentMainMenu()
   - presentLevel(_ levelNumber: Int)
   - presentGameOver()
   - presentLevelComplete()

   Переходы:
   - fadeTransition(duration: 0.5)
   - pushTransition(direction: .left/.right)

5. BaseGameScene (базовый класс для игровых сцен):
   Расположение: Scenes/BaseGameScene.swift

   Наследуется от SKScene

   Свойства:
   - gameCamera: GameCamera
   - hudLayer: SKNode (для UI элементов)
   - gameLayer: SKNode (для игровых объектов)
   - backgroundLayer: SKNode (для фона)

   Методы:
   - setupLayers() - создание слоёв в правильном порядке
   - setupCamera() - инициализация камеры
   - pauseGame() / resumeGame()
   - gameOver()

6. Протокол GameSceneDelegate:
   - sceneDidLoad()
   - sceneWillTransition()
   - playerDidDie()
   - levelDidComplete()

ВАЖНО:
- Все классы должны быть хорошо структурированы
- Используй weak references где нужно, чтобы избежать retain cycles
- Добавь комментарии к публичным методам
- Используй Swift 5.9 синтаксис
- Код должен компилироваться без ошибок
```

---

## 1.2 Система уровней

### Промпт для Claude Code:

```
Создай систему загрузки уровней для платформера "Хроники Разломов".

ТРЕБОВАНИЯ:

1. LevelData (Codable struct):
   Расположение: Levels/LevelData.swift

   Основные свойства:
   - id: Int (номер уровня 1-10)
   - name: String (название на русском)
   - width: Int (ширина в тайлах)
   - height: Int (высота в тайлах)
   - tileSize: CGFloat (размер тайла, по умолчанию 32)

   Игрок:
   - playerSpawn: CGPoint (начальная позиция)

   Платформы:
   - platforms: [PlatformData]

   PlatformData:
   - position: CGPoint
   - size: CGSize
   - type: PlatformType (solid, oneWay, crumbling, moving)
   - movementPath: [CGPoint]? (для moving платформ)
   - movementSpeed: CGFloat? (для moving платформ)

   Враги:
   - enemies: [EnemySpawnData]

   EnemySpawnData:
   - type: String (Cultist, FloatingEye, CorruptedSpirit и т.д.)
   - position: CGPoint
   - patrolPath: [CGPoint]? (для патрулирующих)
   - facing: Direction (left/right)

   Предметы:
   - collectibles: [CollectibleData]

   CollectibleData:
   - type: CollectibleType (manaCrystal, healthPickup, chroniclePage, checkpoint)
   - position: CGPoint
   - id: String? (для страниц хроник)

   Интерактивные объекты:
   - interactables: [InteractableData]

   InteractableData:
   - type: InteractableType (door, switch, levelExit)
   - position: CGPoint
   - linkedId: String? (связь switch-door)

   Триггеры:
   - triggers: [TriggerData]

   TriggerData:
   - type: TriggerType (dialog, bossSpawn, cutscene)
   - position: CGPoint
   - size: CGSize (зона триггера)
   - dialogId: String? (для диалогов)
   - oneTime: Bool

   Фон:
   - backgroundLayers: [BackgroundLayerData]

   BackgroundLayerData:
   - imageName: String
   - parallaxFactor: CGFloat (0.0 = статичный, 1.0 = с камерой)
   - zPosition: CGFloat

   Границы:
   - bounds: CGRect (границы уровня для камеры)
   - deathZoneY: CGFloat (высота, ниже которой смерть)

2. LevelLoader:
   Расположение: Levels/LevelLoader.swift

   Методы:
   - loadLevel(_ number: Int) -> LevelData?
     Загружает JSON из Bundle

   - buildLevel(from data: LevelData, in scene: SKScene)
     Создаёт все ноды из данных:
     - Платформы как SKSpriteNode с физикой
     - Врагов (пока заглушки)
     - Коллекционные предметы
     - Триггеры (невидимые зоны)
     - Фоновые слои

   - createPlatform(from data: PlatformData) -> SKNode
   - createEnemy(from data: EnemySpawnData) -> SKNode
   - createCollectible(from data: CollectibleData) -> SKNode
   - createTrigger(from data: TriggerData) -> SKNode

3. Физические категории:
   Расположение: Utils/PhysicsCategories.swift

   struct PhysicsCategory {
       static let none: UInt32 = 0
       static let player: UInt32 = 0b1
       static let ground: UInt32 = 0b10
       static let enemy: UInt32 = 0b100
       static let collectible: UInt32 = 0b1000
       static let hazard: UInt32 = 0b10000
       static let trigger: UInt32 = 0b100000
       static let playerAttack: UInt32 = 0b1000000
   }

4. Создай шаблон JSON для уровня 1 (Рассветный Шпиль):
   Расположение: Levels/level_1.json

   Содержимое:
   - Размер: 100x15 тайлов
   - 10 платформ разного типа
   - 5 культистов
   - 3 чекпоинта
   - 20 кристаллов маны
   - 1 страница хроник
   - Начальный диалоговый триггер
   - Триггер появления мини-босса
   - Выход из уровня

   Фон:
   - 3 слоя параллакса (дальние горы, средний план, близкие объекты)

ВАЖНО:
- JSON должен быть валидным и легко читаемым
- Все enum должны иметь String rawValue для Codable
- Позиции в JSON указывать в тайловых координатах, конвертировать в пиксели при загрузке
- Добавь extension для конвертации тайловых координат в CGPoint
```

---

## 1.3 Камера и viewport

### Промпт для Claude Code:

```
Создай систему камеры для платформера "Хроники Разломов".

ТРЕБОВАНИЯ:

1. GameCamera (SKCameraNode subclass):
   Расположение: Components/GameCamera.swift

   Свойства:
   - target: SKNode? (за кем следить, обычно Player)
   - bounds: CGRect (границы уровня)
   - smoothing: CGFloat (0.0-1.0, плавность следования, по умолчанию 0.1)
   - offset: CGPoint (смещение от центра персонажа)
   - isShaking: Bool
   - currentZoom: CGFloat (1.0 = нормальный)

   Конфигурация:
   - lookAheadDistance: CGFloat (смотреть вперёд по направлению движения)
   - verticalBias: CGFloat (смещение вверх для лучшего обзора)

   Методы:
   - update(deltaTime: TimeInterval)
     Плавное следование за target с учётом:
     - Ограничения по bounds
     - Look-ahead в направлении движения
     - Плавная интерполяция (lerp)

   - shake(intensity: CGFloat, duration: TimeInterval)
     Тряска камеры:
     - Случайное смещение по X и Y
     - Затухание к концу
     - Не влияет на HUD (HUD не дочерний элемент камеры)

   - zoom(to scale: CGFloat, duration: TimeInterval)
     Плавный zoom:
     - Используй SKAction для анимации xScale и yScale
     - Ограничение: 0.5 - 2.0

   - focusOn(point: CGPoint, duration: TimeInterval)
     Временно переместить камеру на точку (для катсцен)

   - returnToTarget(duration: TimeInterval)
     Вернуться к слежению за target

2. ParallaxBackground:
   Расположение: Components/ParallaxBackground.swift

   Класс для управления параллакс-слоями

   Свойства:
   - layers: [ParallaxLayer]

   ParallaxLayer:
   - node: SKSpriteNode
   - parallaxFactor: CGFloat (0.0 = не двигается, 1.0 = с камерой)
   - repeatX: Bool (повторять по горизонтали)
   - repeatY: Bool

   Методы:
   - addLayer(imageName: String, parallaxFactor: CGFloat, zPosition: CGFloat)
   - update(cameraPosition: CGPoint)
     Обновляет позиции слоёв относительно камеры:
     layer.position.x = -cameraPosition.x * layer.parallaxFactor

     Если repeatX:
     - Создать несколько копий изображения
     - Бесконечный скроллинг

3. Интеграция в BaseGameScene:

   Добавь в setupCamera():
   - Создание GameCamera
   - Установка camera = gameCamera
   - Инициализация ParallaxBackground

   Добавь в update():
   - gameCamera.update(deltaTime: deltaTime)
   - parallaxBackground.update(cameraPosition: gameCamera.position)

4. CameraEffects (опционально):
   Расположение: Components/CameraEffects.swift

   Статические методы для эффектов:
   - flashEffect(color: SKColor, duration: TimeInterval) -> SKAction
   - fadeToBlack(duration: TimeInterval) -> SKAction
   - fadeFromBlack(duration: TimeInterval) -> SKAction
   - slowMotion(factor: CGFloat, duration: TimeInterval)

ФОРМУЛЫ:

Плавное следование (lerp):
let lerpX = currentPosition.x + (targetPosition.x - currentPosition.x) * smoothing
let lerpY = currentPosition.y + (targetPosition.y - currentPosition.y) * smoothing

Ограничение по границам:
let halfWidth = scene.size.width / 2 / currentZoom
let halfHeight = scene.size.height / 2 / currentZoom
let clampedX = max(bounds.minX + halfWidth, min(bounds.maxX - halfWidth, x))
let clampedY = max(bounds.minY + halfHeight, min(bounds.maxY - halfHeight, y))

ВАЖНО:
- Камера не должна выходить за границы уровня
- HUD должен быть привязан к камере, но не участвовать в shake
- Parallax должен работать плавно без рывков
- Все значения должны быть настраиваемыми
```

---

## 1.4 Система ввода (Touch Controls)

### Промпт для Claude Code:

```
Создай систему touch-управления для платформера "Хроники Разломов".

ТРЕБОВАНИЯ:

1. InputManager:
   Расположение: Managers/InputManager.swift

   Протокол InputDelegate:
   - joystickMoved(direction: CGVector) // -1 to 1 по X
   - jumpPressed()
   - jumpReleased()
   - attackPressed()
   - pausePressed()

   Свойства:
   - weak var delegate: InputDelegate?
   - joystickValue: CGVector (текущее значение)
   - isJumpHeld: Bool
   - sensitivity: CGFloat

   Методы:
   - handleTouchBegan(_ touch: UITouch, in view: SKView)
   - handleTouchMoved(_ touch: UITouch, in view: SKView)
   - handleTouchEnded(_ touch: UITouch, in view: SKView)

2. VirtualJoystick:
   Расположение: Components/VirtualJoystick.swift

   Наследуется от SKNode

   Визуальные элементы:
   - baseNode: SKShapeNode (круг, полупрозрачный, радиус 50)
   - stickNode: SKShapeNode (круг поменьше, радиус 20)

   Свойства:
   - radius: CGFloat (максимальное отклонение)
   - value: CGVector (текущее значение -1 to 1)
   - isActive: Bool
   - activeTouch: UITouch?

   Цвета:
   - baseColor: UIColor.white.withAlphaComponent(0.3)
   - stickColor: UIColor.white.withAlphaComponent(0.6)
   - activeStickColor: UIColor.white.withAlphaComponent(0.9)

   Методы:
   - touchBegan(at point: CGPoint, touch: UITouch)
     Если точка внутри зоны джойстика -> активация

   - touchMoved(to point: CGPoint)
     Обновить позицию стика с ограничением по радиусу
     Вычислить value

   - touchEnded()
     Вернуть стик в центр с анимацией
     Сбросить value в .zero

   - updateVisuals()
     Анимация при активации/деактивации

   Позиционирование:
   - Левая часть экрана
   - Отступ от края: 80 пикселей
   - Адаптация под Safe Area

3. ActionButton:
   Расположение: Components/ActionButton.swift

   Наследуется от SKNode

   Визуальные элементы:
   - backgroundNode: SKShapeNode (круг)
   - iconNode: SKSpriteNode (иконка)
   - labelNode: SKLabelNode (опционально)

   Свойства:
   - buttonType: ButtonType (jump, attack, pause)
   - isPressed: Bool
   - isEnabled: Bool
   - size: CGFloat (радиус)

   Callback:
   - onPress: (() -> Void)?
   - onRelease: (() -> Void)?

   Визуальные состояния:
   - Normal: альфа 0.6
   - Pressed: альфа 1.0, scale 0.9
   - Disabled: альфа 0.3

   Методы:
   - touchBegan(at point: CGPoint) -> Bool
     Вернуть true если попадание в кнопку

   - touchEnded()
     Вернуть в нормальное состояние

4. TouchControlsOverlay:
   Расположение: Components/TouchControlsOverlay.swift

   Контейнер для всех touch элементов
   Добавляется к HUD слою

   Содержит:
   - joystick: VirtualJoystick
   - jumpButton: ActionButton
   - attackButton: ActionButton
   - pauseButton: ActionButton (верхний правый угол)

   Методы:
   - setup(in scene: SKScene)
     Позиционирование с учётом Safe Area:
     - safeAreaInsets от UIApplication.shared.windows

   - handleTouch(phase: UITouch.Phase, location: CGPoint, touch: UITouch)
     Распределение touch по элементам

   - setControlsVisible(_ visible: Bool)
     Для скрытия во время катсцен

   - updateLayout(for size: CGSize)
     Перерасчёт при повороте экрана

5. Интеграция в BaseGameScene:

   В touchesBegan/touchesMoved/touchesEnded:
   - Передавать события в TouchControlsOverlay
   - Поддержка мультитача (одновременно джойстик + кнопки)

   Пример:
   override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
       for touch in touches {
           let location = touch.location(in: hudLayer)
           touchControlsOverlay.handleTouch(phase: .began, location: location, touch: touch)
       }
   }

РАСПОЛОЖЕНИЕ ЭЛЕМЕНТОВ (для iPhone в landscape):

+------------------------------------------+
|  [Pause]                                 |
|                                          |
|                                          |
|                              [Attack]    |
|  (Joystick)                  [Jump]      |
+------------------------------------------+

Отступы:
- Joystick: 80pt от левого края, 80pt от низа
- Jump: 80pt от правого края, 80pt от низа
- Attack: 80pt от правого края, 160pt от низа
- Pause: 40pt от правого края, 40pt от верха

ВАЖНО:
- Все элементы должны учитывать Safe Area
- Мультитач обязателен (движение + прыжок одновременно)
- Визуальная обратная связь при нажатии
- Полупрозрачность чтобы не мешать обзору
- Плавные анимации появления/исчезновения
```

---

## Порядок выполнения

1. **Сначала:** 1.1 Игровая архитектура (GameManager, SceneManager)
2. **Затем:** 1.3 Камера (GameCamera, ParallaxBackground)
3. **Далее:** 1.4 Система ввода (InputManager, TouchControls)
4. **В конце:** 1.2 Система уровней (LevelData, LevelLoader)

Такой порядок позволяет тестировать каждый компонент по мере добавления.

---

## Тестирование после завершения фазы

После выполнения всех промптов проверь:

1. [ ] Проект компилируется без ошибок
2. [ ] GameManager сохраняет и загружает данные
3. [ ] Камера плавно следует за точкой
4. [ ] Touch-контролы реагируют на нажатия
5. [ ] Уровень загружается из JSON
6. [ ] Платформы отображаются в правильных позициях
7. [ ] Мультитач работает (джойстик + кнопки одновременно)

---

## Структура файлов после завершения

```
ChroniclesOfRifts/
├── Managers/
│   ├── GameManager.swift
│   ├── SceneManager.swift
│   ├── InputManager.swift
│   ├── PlayerData.swift
│   └── GameSettings.swift
├── Scenes/
│   ├── BaseGameScene.swift
│   └── GameScene.swift
├── Components/
│   ├── GameCamera.swift
│   ├── ParallaxBackground.swift
│   ├── VirtualJoystick.swift
│   ├── ActionButton.swift
│   └── TouchControlsOverlay.swift
├── Levels/
│   ├── LevelData.swift
│   ├── LevelLoader.swift
│   └── level_1.json
└── Utils/
    └── PhysicsCategories.swift
```
