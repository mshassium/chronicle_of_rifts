import Foundation

/// Настройки игры, сохраняемые между сессиями
struct GameSettings: Codable {
    /// Громкость музыки (0.0 - 1.0)
    var musicVolume: Float

    /// Громкость звуковых эффектов (0.0 - 1.0)
    var sfxVolume: Float

    /// Чувствительность джойстика (0.5 - 2.0)
    var joystickSensitivity: Float

    /// Показывать FPS (только для debug)
    var showFPS: Bool

    /// Настройки по умолчанию
    static let `default` = GameSettings(
        musicVolume: 0.7,
        sfxVolume: 1.0,
        joystickSensitivity: 1.0,
        showFPS: false
    )

    /// Валидация и нормализация значений
    mutating func normalize() {
        musicVolume = min(max(musicVolume, 0.0), 1.0)
        sfxVolume = min(max(sfxVolume, 0.0), 1.0)
        joystickSensitivity = min(max(joystickSensitivity, 0.5), 2.0)
    }
}

/// Состояния игры
enum GameState: String, Codable {
    case menu       // Главное меню
    case playing    // Активный геймплей
    case paused     // Игра на паузе
    case gameOver   // Экран проигрыша
    case cutscene   // Кат-сцена/диалог
    case levelComplete // Уровень пройден
}
