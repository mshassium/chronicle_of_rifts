import SpriteKit

/// Визуальный компонент для отображения диалогов
/// Располагается внизу экрана и показывает текст с эффектом печатной машинки
final class DialogBox: SKNode {

    // MARK: - Visual Elements

    /// Фоновая область диалога
    private let backgroundNode: SKShapeNode

    /// Рамка портрета
    private let portraitFrame: SKShapeNode

    /// Изображение персонажа
    private let portraitNode: SKSpriteNode

    /// Имя говорящего
    private let speakerLabel: SKLabelNode

    /// Текст реплики
    private let textLabel: SKLabelNode

    /// Индикатор продолжения (стрелка вниз)
    private let continueIndicator: SKShapeNode

    // MARK: - Properties

    /// Идёт ли анимация печати
    private(set) var isTyping: Bool = false

    /// Скорость печати (секунд на символ)
    var typewriterSpeed: TimeInterval = 0.03

    /// Полный текст текущей реплики
    private var currentText: String = ""

    /// Отображённая часть текста
    private var displayedText: String = ""

    /// Текущий индекс символа
    private var currentCharIndex: Int = 0

    /// Размер экрана для позиционирования
    private let screenSize: CGSize

    /// Высота диалогового окна
    private let boxHeight: CGFloat = 140

    /// Отступы
    private let margin: CGFloat = 20
    private let portraitSize: CGFloat = 100

    // MARK: - Colors

    private let goldColor = SKColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 1.0) // #FFD700
    private let darkBlueColor = SKColor(red: 0.05, green: 0.1, blue: 0.2, alpha: 0.85)
    private let borderColor = SKColor(red: 0.8, green: 0.68, blue: 0.0, alpha: 1.0)

    // MARK: - Initialization

    /// Инициализация диалогового окна
    /// - Parameter size: Размер экрана для правильного позиционирования
    init(size: CGSize) {
        self.screenSize = size

        // Создаём фон диалога
        let boxWidth = size.width - margin * 2
        let boxRect = CGRect(
            x: -boxWidth / 2,
            y: 0,
            width: boxWidth,
            height: boxHeight
        )

        // Скругление только сверху
        let path = CGMutablePath()
        let cornerRadius: CGFloat = 16
        path.move(to: CGPoint(x: boxRect.minX, y: boxRect.minY))
        path.addLine(to: CGPoint(x: boxRect.minX, y: boxRect.maxY - cornerRadius))
        path.addArc(
            center: CGPoint(x: boxRect.minX + cornerRadius, y: boxRect.maxY - cornerRadius),
            radius: cornerRadius,
            startAngle: .pi,
            endAngle: .pi / 2,
            clockwise: true
        )
        path.addLine(to: CGPoint(x: boxRect.maxX - cornerRadius, y: boxRect.maxY))
        path.addArc(
            center: CGPoint(x: boxRect.maxX - cornerRadius, y: boxRect.maxY - cornerRadius),
            radius: cornerRadius,
            startAngle: .pi / 2,
            endAngle: 0,
            clockwise: true
        )
        path.addLine(to: CGPoint(x: boxRect.maxX, y: boxRect.minY))
        path.closeSubpath()

        backgroundNode = SKShapeNode(path: path)
        backgroundNode.fillColor = darkBlueColor
        backgroundNode.strokeColor = borderColor
        backgroundNode.lineWidth = 2

        // Рамка портрета
        let frameSize = portraitSize + 8
        portraitFrame = SKShapeNode(rectOf: CGSize(width: frameSize, height: frameSize), cornerRadius: 4)
        portraitFrame.fillColor = SKColor(white: 0.1, alpha: 0.5)
        portraitFrame.strokeColor = goldColor
        portraitFrame.lineWidth = 2

        // Портрет персонажа
        portraitNode = SKSpriteNode(color: .clear, size: CGSize(width: portraitSize, height: portraitSize))
        portraitNode.anchorPoint = CGPoint(x: 0.5, y: 0.5)

        // Имя говорящего
        speakerLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        speakerLabel.fontSize = 22
        speakerLabel.fontColor = goldColor
        speakerLabel.horizontalAlignmentMode = .left
        speakerLabel.verticalAlignmentMode = .top

        // Текст реплики
        textLabel = SKLabelNode(fontNamed: "AvenirNext-Medium")
        textLabel.fontSize = 18
        textLabel.fontColor = .white
        textLabel.horizontalAlignmentMode = .left
        textLabel.verticalAlignmentMode = .top
        textLabel.numberOfLines = 0
        textLabel.preferredMaxLayoutWidth = boxWidth - portraitSize - margin * 4

        // Индикатор продолжения (треугольник вниз)
        let trianglePath = CGMutablePath()
        trianglePath.move(to: CGPoint(x: -8, y: 8))
        trianglePath.addLine(to: CGPoint(x: 8, y: 8))
        trianglePath.addLine(to: CGPoint(x: 0, y: -4))
        trianglePath.closeSubpath()

        continueIndicator = SKShapeNode(path: trianglePath)
        continueIndicator.fillColor = goldColor
        continueIndicator.strokeColor = .clear
        continueIndicator.alpha = 0

        super.init()

        // Добавляем элементы
        addChild(backgroundNode)
        addChild(portraitFrame)
        addChild(portraitNode)
        addChild(speakerLabel)
        addChild(textLabel)
        addChild(continueIndicator)

        // Позиционирование
        setupLayout()

        // Начальное состояние - скрыто
        alpha = 0
        isHidden = true

        name = "dialogBox"
        zPosition = 150
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Layout

    private func setupLayout() {
        // Позиция диалогового окна (внизу экрана)
        position = CGPoint(x: 0, y: -screenSize.height / 2)

        // Портрет слева
        let portraitX = -screenSize.width / 2 + margin * 2 + portraitSize / 2
        let portraitY = boxHeight / 2
        portraitFrame.position = CGPoint(x: portraitX, y: portraitY)
        portraitNode.position = CGPoint(x: portraitX, y: portraitY)

        // Имя говорящего справа от портрета
        let textStartX = portraitX + portraitSize / 2 + margin
        speakerLabel.position = CGPoint(x: textStartX, y: boxHeight - margin)

        // Текст под именем
        textLabel.position = CGPoint(x: textStartX, y: boxHeight - margin - 30)

        // Индикатор продолжения в правом нижнем углу
        continueIndicator.position = CGPoint(
            x: screenSize.width / 2 - margin * 2 - 20,
            y: margin + 10
        )
    }

    // MARK: - Public Methods

    /// Показать диалоговое окно
    /// - Parameter animated: С анимацией или нет
    func show(animated: Bool = true) {
        isHidden = false

        if animated {
            let moveUp = SKAction.moveBy(x: 0, y: boxHeight + 10, duration: 0.3)
            moveUp.timingMode = .easeOut
            let fadeIn = SKAction.fadeIn(withDuration: 0.3)
            run(SKAction.group([moveUp, fadeIn]))
        } else {
            position.y = -screenSize.height / 2 + boxHeight + 10
            alpha = 1
        }
    }

    /// Скрыть диалоговое окно
    /// - Parameter animated: С анимацией или нет
    func hide(animated: Bool = true) {
        stopTypewriter()

        if animated {
            let moveDown = SKAction.moveBy(x: 0, y: -(boxHeight + 10), duration: 0.3)
            moveDown.timingMode = .easeIn
            let fadeOut = SKAction.fadeOut(withDuration: 0.3)
            run(SKAction.group([moveDown, fadeOut])) { [weak self] in
                self?.isHidden = true
                self?.position.y = -self!.screenSize.height / 2
            }
        } else {
            alpha = 0
            isHidden = true
            position.y = -screenSize.height / 2
        }
    }

    /// Отобразить строку диалога
    /// - Parameter line: Данные строки диалога
    func displayLine(_ line: DialogLine) {
        // Останавливаем предыдущую анимацию
        stopTypewriter()

        // Обновляем имя говорящего
        speakerLabel.text = line.speaker

        // Обновляем портрет
        updatePortrait(name: line.portraitName, emotion: line.emotion)

        // Запускаем эффект печатной машинки
        startTypewriterEffect(text: line.text)
    }

    /// Пропустить анимацию печати и показать весь текст
    func skipTypewriter() {
        guard isTyping else { return }

        stopTypewriter()
        displayedText = currentText
        textLabel.text = displayedText
        showContinueIndicator()
    }

    /// Проверить, отображён ли весь текст
    /// - Returns: true если весь текст показан
    func isFullyDisplayed() -> Bool {
        return !isTyping && displayedText == currentText
    }

    // MARK: - Private Methods

    /// Запустить эффект печатной машинки
    private func startTypewriterEffect(text: String) {
        currentText = text
        displayedText = ""
        currentCharIndex = 0
        isTyping = true
        textLabel.text = ""
        continueIndicator.alpha = 0
        continueIndicator.removeAllActions()

        typeNextCharacter()
    }

    /// Напечатать следующий символ
    private func typeNextCharacter() {
        guard isTyping, currentCharIndex < currentText.count else {
            finishTyping()
            return
        }

        let index = currentText.index(currentText.startIndex, offsetBy: currentCharIndex)
        let char = currentText[index]
        displayedText.append(char)
        textLabel.text = displayedText
        currentCharIndex += 1

        // Определяем задержку для следующего символа
        var delay = typewriterSpeed

        // Пауза на знаках препинания
        if char == "." || char == "!" || char == "?" {
            delay = typewriterSpeed * 8
        } else if char == "," || char == ":" || char == ";" {
            delay = typewriterSpeed * 4
        }

        // Планируем следующий символ
        let waitAction = SKAction.wait(forDuration: delay)
        let typeAction = SKAction.run { [weak self] in
            self?.typeNextCharacter()
        }
        run(SKAction.sequence([waitAction, typeAction]), withKey: "typewriter")
    }

    /// Завершить печать
    private func finishTyping() {
        isTyping = false
        showContinueIndicator()
    }

    /// Остановить эффект печатной машинки
    private func stopTypewriter() {
        removeAction(forKey: "typewriter")
        isTyping = false
    }

    /// Показать индикатор продолжения с пульсирующей анимацией
    private func showContinueIndicator() {
        continueIndicator.alpha = 1
        animateContinueIndicator()
    }

    /// Анимация пульсации индикатора
    private func animateContinueIndicator() {
        let moveUp = SKAction.moveBy(x: 0, y: 5, duration: 0.4)
        moveUp.timingMode = .easeInEaseOut
        let moveDown = SKAction.moveBy(x: 0, y: -5, duration: 0.4)
        moveDown.timingMode = .easeInEaseOut
        let pulse = SKAction.sequence([moveUp, moveDown])
        let repeatPulse = SKAction.repeatForever(pulse)

        continueIndicator.run(repeatPulse, withKey: "pulse")
    }

    /// Обновить портрет персонажа
    private func updatePortrait(name: String?, emotion: String?) {
        // Пытаемся загрузить портрет
        var textureName = "portrait_unknown"

        if let portraitName = name {
            // Формируем имя текстуры: portrait_name_emotion или portrait_name
            if let emotion = emotion {
                textureName = "portrait_\(portraitName.lowercased())_\(emotion.lowercased())"
            } else {
                textureName = "portrait_\(portraitName.lowercased())"
            }
        }

        // Пробуем загрузить текстуру
        let texture = SKTexture(imageNamed: textureName)

        // Проверяем, загрузилась ли текстура (если размер > 0)
        if texture.size().width > 1 {
            portraitNode.texture = texture
            portraitNode.color = .clear
            portraitNode.colorBlendFactor = 0
        } else {
            // Placeholder - серый квадрат с первой буквой имени
            portraitNode.texture = nil
            portraitNode.color = SKColor(white: 0.3, alpha: 1.0)
            portraitNode.colorBlendFactor = 1.0

            // Удаляем старый placeholder label если есть
            portraitNode.childNode(withName: "placeholderLabel")?.removeFromParent()

            // Добавляем букву
            let initial = name?.first.map { String($0).uppercased() } ?? "?"
            let placeholderLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
            placeholderLabel.name = "placeholderLabel"
            placeholderLabel.text = initial
            placeholderLabel.fontSize = 40
            placeholderLabel.fontColor = .white
            placeholderLabel.verticalAlignmentMode = .center
            placeholderLabel.horizontalAlignmentMode = .center
            portraitNode.addChild(placeholderLabel)
        }
    }
}
