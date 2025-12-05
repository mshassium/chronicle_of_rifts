import Foundation

// MARK: - DialogLine

/// Структура одной строки диалога
struct DialogLine: Codable {
    /// Имя говорящего
    let speaker: String
    /// Текст реплики
    let text: String
    /// Имя изображения портрета (опционально)
    let portraitName: String?
    /// Эмоция для портрета: "neutral", "angry", "sad", "shocked", "determined", "dying", "evil", "desperate", etc.
    let emotion: String?

    enum CodingKeys: String, CodingKey {
        case speaker, text, portraitName, emotion
    }

    init(speaker: String, text: String, portraitName: String? = nil, emotion: String? = nil) {
        self.speaker = speaker
        self.text = text
        self.portraitName = portraitName
        self.emotion = emotion
    }
}

// MARK: - DialogData

/// Структура данных диалога
struct DialogData: Codable {
    /// Уникальный идентификатор диалога (например, "intro_level1")
    let id: String
    /// Массив реплик диалога
    let lines: [DialogLine]
    /// Автоматическое переключение реплик
    let autoAdvance: Bool
    /// Задержка перед автоматическим переключением
    let autoAdvanceDelay: TimeInterval

    enum CodingKeys: String, CodingKey {
        case id, lines, autoAdvance, autoAdvanceDelay
    }

    init(id: String, lines: [DialogLine], autoAdvance: Bool = false, autoAdvanceDelay: TimeInterval = 3.0) {
        self.id = id
        self.lines = lines
        self.autoAdvance = autoAdvance
        self.autoAdvanceDelay = autoAdvanceDelay
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        lines = try container.decode([DialogLine].self, forKey: .lines)
        autoAdvance = try container.decodeIfPresent(Bool.self, forKey: .autoAdvance) ?? false
        autoAdvanceDelay = try container.decodeIfPresent(TimeInterval.self, forKey: .autoAdvanceDelay) ?? 3.0
    }
}

// MARK: - DialogsContainer

/// Контейнер для загрузки диалогов из JSON
private struct DialogsContainer: Codable {
    let dialogs: [DialogData]
}

// MARK: - DialogManagerDelegate

/// Делегат для получения событий диалогов
protocol DialogManagerDelegate: AnyObject {
    /// Вызывается при начале диалога
    func dialogDidStart(dialogId: String)
    /// Вызывается при завершении диалога
    func dialogDidEnd(dialogId: String)
    /// Вызывается при смене реплики
    func dialogLineChanged(line: DialogLine, index: Int, total: Int)
}

// MARK: - DialogManager

/// Менеджер диалогов (синглтон)
/// Управляет загрузкой и воспроизведением диалогов
final class DialogManager {

    // MARK: - Singleton

    static let shared = DialogManager()

    // MARK: - Properties

    /// Загруженные диалоги [id: DialogData]
    private var dialogs: [String: DialogData] = [:]

    /// Флаг активного диалога
    private(set) var isDialogActive: Bool = false

    /// Текущий диалог
    private var currentDialog: DialogData?

    /// Текущий индекс строки в диалоге
    private var currentLineIndex: Int = 0

    /// Делегат для событий диалога
    weak var delegate: DialogManagerDelegate?

    /// Таймер для автоматического переключения
    private var autoAdvanceTimer: Timer?

    // MARK: - Initialization

    private init() {
        loadDialogs()
    }

    // MARK: - Public Methods

    /// Загрузить все диалоги из JSON файла
    func loadDialogs() {
        dialogs.removeAll()

        guard let url = Bundle.main.url(forResource: "dialogs", withExtension: "json") else {
            print("⚠️ DialogManager: dialogs.json not found in bundle")
            return
        }

        do {
            let data = try Data(contentsOf: url)
            let container = try JSONDecoder().decode(DialogsContainer.self, from: data)

            for dialog in container.dialogs {
                dialogs[dialog.id] = dialog
            }

            print("✅ DialogManager: Loaded \(dialogs.count) dialogs")
        } catch {
            print("❌ DialogManager: Failed to load dialogs - \(error)")
        }
    }

    /// Загрузить конкретный диалог по имени
    /// - Parameter named: ID диалога
    /// - Returns: Данные диалога или nil
    func loadDialog(named: String) -> DialogData? {
        return dialogs[named]
    }

    /// Начать диалог по ID
    /// - Parameter id: Идентификатор диалога
    func startDialog(id: String) {
        // Проверяем, не активен ли уже диалог
        guard !isDialogActive else {
            print("⚠️ DialogManager: Dialog already active, ignoring startDialog(\(id))")
            return
        }

        // Проверяем, существует ли диалог
        guard let dialog = dialogs[id] else {
            print("⚠️ DialogManager: Dialog '\(id)' not found")
            return
        }

        // Проверяем, есть ли реплики
        guard !dialog.lines.isEmpty else {
            print("⚠️ DialogManager: Dialog '\(id)' has no lines")
            return
        }

        // Начинаем диалог
        currentDialog = dialog
        currentLineIndex = 0
        isDialogActive = true

        delegate?.dialogDidStart(dialogId: id)

        // Показываем первую реплику
        showCurrentLine()
    }

    /// Перейти к следующей реплике
    func advanceDialog() {
        guard isDialogActive, let dialog = currentDialog else { return }

        // Отменяем таймер автопереключения
        autoAdvanceTimer?.invalidate()
        autoAdvanceTimer = nil

        currentLineIndex += 1

        if currentLineIndex >= dialog.lines.count {
            // Диалог завершен
            endDialog()
        } else {
            // Показываем следующую реплику
            showCurrentLine()
        }
    }

    /// Пропустить весь диалог
    func skipDialog() {
        guard isDialogActive else { return }
        endDialog()
    }

    /// Получить текущую реплику
    /// - Returns: Текущая строка диалога или nil
    func getCurrentLine() -> DialogLine? {
        guard isDialogActive,
              let dialog = currentDialog,
              currentLineIndex < dialog.lines.count else {
            return nil
        }
        return dialog.lines[currentLineIndex]
    }

    /// Получить общее количество реплик в текущем диалоге
    func getTotalLines() -> Int {
        return currentDialog?.lines.count ?? 0
    }

    /// Получить текущий индекс реплики (0-based)
    func getCurrentLineIndex() -> Int {
        return currentLineIndex
    }

    /// Проверить, есть ли следующая реплика
    func hasNextLine() -> Bool {
        guard let dialog = currentDialog else { return false }
        return currentLineIndex < dialog.lines.count - 1
    }

    /// Проверить, загружен ли диалог
    func isDialogLoaded(_ id: String) -> Bool {
        return dialogs[id] != nil
    }

    /// Получить количество загруженных диалогов
    func getLoadedDialogsCount() -> Int {
        return dialogs.count
    }

    // MARK: - Private Methods

    /// Показать текущую реплику
    private func showCurrentLine() {
        guard let dialog = currentDialog,
              currentLineIndex < dialog.lines.count else { return }

        let line = dialog.lines[currentLineIndex]
        delegate?.dialogLineChanged(line: line, index: currentLineIndex, total: dialog.lines.count)

        // Запускаем таймер автопереключения если нужно
        if dialog.autoAdvance {
            scheduleAutoAdvance(delay: dialog.autoAdvanceDelay)
        }
    }

    /// Запланировать автоматическое переключение
    private func scheduleAutoAdvance(delay: TimeInterval) {
        autoAdvanceTimer?.invalidate()
        autoAdvanceTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            self?.advanceDialog()
        }
    }

    /// Завершить диалог
    private func endDialog() {
        guard let dialogId = currentDialog?.id else { return }

        autoAdvanceTimer?.invalidate()
        autoAdvanceTimer = nil

        isDialogActive = false
        currentDialog = nil
        currentLineIndex = 0

        delegate?.dialogDidEnd(dialogId: dialogId)
    }
}
