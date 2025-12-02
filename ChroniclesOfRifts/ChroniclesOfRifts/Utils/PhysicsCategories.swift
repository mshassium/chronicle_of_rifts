import Foundation

struct PhysicsCategory {
    static let none: UInt32 = 0
    static let player: UInt32 = 0b1
    static let ground: UInt32 = 0b10
    static let enemy: UInt32 = 0b100
    static let collectible: UInt32 = 0b1000
    static let hazard: UInt32 = 0b10000
    static let trigger: UInt32 = 0b100000
    static let playerAttack: UInt32 = 0b1000000
    static let enemyProjectile: UInt32 = 0b10000000
}
