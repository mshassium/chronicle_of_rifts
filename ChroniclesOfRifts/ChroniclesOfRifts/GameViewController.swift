import UIKit
import SpriteKit
import GameplayKit

class GameViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let skView = self.view as? SKView else {
            fatalError("View is not SKView")
        }

        // Настройка SKView
        skView.ignoresSiblingOrder = true

        #if DEBUG
        if GameManager.shared.settings.showFPS {
            skView.showsFPS = true
            skView.showsNodeCount = true
            skView.showsDrawCount = true
        }
        #endif

        // Конфигурация SceneManager
        SceneManager.shared.configure(with: skView)

        // Загрузка сохранённого прогресса
        GameManager.shared.loadProgress()

        // Показать главное меню
        SceneManager.shared.presentMainMenu()
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .landscape
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }

    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }
}
