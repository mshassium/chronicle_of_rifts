# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Chronicles of Rifts** (Хроники Разломов) is a 2D platformer game for iOS built with SpriteKit and Swift. The game features a fantasy world with floating islands, where the player character Kael must save the world from an awakening evil deity.

## Tech Stack

- **Engine:** SpriteKit (native iOS 2D game framework)
- **Language:** Swift 5.9
- **IDE:** Xcode 15+
- **Minimum iOS:** 15.0
- **Target Devices:** iPhone, iPad (landscape only)

## Build Commands

```bash
# Build the project
xcodebuild -project ChroniclesOfRifts/ChroniclesOfRifts.xcodeproj -scheme ChroniclesOfRifts -configuration Debug build

# Run on simulator
xcodebuild -project ChroniclesOfRifts/ChroniclesOfRifts.xcodeproj -scheme ChroniclesOfRifts -destination 'platform=iOS Simulator,name=iPhone 15' build

# Clean build
xcodebuild -project ChroniclesOfRifts/ChroniclesOfRifts.xcodeproj clean
```

Or open `ChroniclesOfRifts/ChroniclesOfRifts.xcodeproj` in Xcode and use Cmd+B to build, Cmd+R to run.

## Architecture

The project follows an Entity-Component pattern with the following structure:

```
ChroniclesOfRifts/
├── Managers/        # GameManager, SceneManager, InputManager, AudioManager
├── Scenes/          # SKScene subclasses (GameScene, MenuScene, etc.)
├── Entities/        # Game entities (Player, Enemy, Boss)
├── Components/      # Reusable components (GameCamera, VirtualJoystick, etc.)
├── Levels/          # Level data (JSON) and LevelLoader
├── Resources/       # Textures, Audio, Fonts
└── Utils/           # Helpers, PhysicsCategories, Extensions
```

### Key Patterns

- **GameManager** (singleton): Central game state management, save/load progress
- **SceneManager**: Scene transitions with animations
- **BaseGameScene**: Base class for game scenes with camera, HUD, and input handling
- **LevelData/LevelLoader**: JSON-based level definitions

### Physics Categories (bitmask)

```swift
player: 0b1
ground: 0b10
enemy: 0b100
collectible: 0b1000
hazard: 0b10000
trigger: 0b100000
playerAttack: 0b1000000
```

## Game Design Reference

The game consists of 10 levels with unique themes:
1. Burning Village (tutorial)
2. Bridges of the Abyss
3. World Roots (flying grove)
4. Aurelion Catacombs
5. Storm Peaks (ice)
6. Sea of Shards (floating islands)
7. Citadel Gates
8. Heart of the Citadel
9. Throne Hall of the Abyss (Morgana boss)
10. Awakening (Velkor final boss)

### Player Abilities (progression)
- Basic sword attack
- Light dash (level 3)
- Ancestor shield (level 5)
- Purification (level 7)
- Dawn strike (level 9)

## Development Notes

- Level data is stored in JSON format in `Levels/level_X.json`
- Tile coordinates in JSON are converted to pixels (multiply by tileSize, default 32)
- Touch controls: virtual joystick (left) + action buttons (right)
- Camera follows player with smoothing and bounds constraints
- Support for parallax backgrounds (3 layers)
- All text/dialogs are in Russian
