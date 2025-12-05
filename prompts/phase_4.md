# PHASE 4: LEVELS AND CONTENT

## Phase Overview

Phase 4 includes creating the tile system, designing all 10 levels, interactive objects, and the dialog system. Each prompt contains instructions for adding files to the project and verifying the build.

---

## 4.1 TILE SYSTEM

### Prompt 4.1.1: Creating TileSet enum and TileType

```
Create a tile system for the Chronicles of Rifts game.

Create file ChroniclesOfRifts/ChroniclesOfRifts/Levels/TileSystem.swift with the following content:

1. TileType enum with categories:
   - Ground: top, middle, bottom, leftEdge, rightEdge, topLeftCorner, topRightCorner, bottomLeftCorner, bottomRightCorner, single
   - Platform: thin (passable from below), thick
   - Wall: left, right, full
   - Hazard: spikes, lava, void
   - Decoration: grass, stone, torch, banner, debris, chain

2. TileSet enum for different locations:
   - burningVillage (level 1): light stone blocks, wood, fire
   - bridgesOfAbyss (level 2): dark stone, chains, clouds
   - worldRoots (level 3): wood, bark, mushrooms, vines
   - catacombs (level 4): tombs, gold, torches
   - stormPeaks (level 5): ice, snow, frozen stone
   - seaOfShards (level 6): floating stones, sky, ruins
   - citadelGates (level 7): black stone, chains, banners
   - citadelHeart (level 8): runes, columns, magic
   - throneHall (level 9): throne, darkness, chains
   - awakening (level 10): chaos, abyss, light

3. Struct TileData:
   - tileType: TileType
   - tileSet: TileSet
   - textureName: String (computed property based on tileType + tileSet)
   - isCollidable: Bool
   - isSemiSolid: Bool (for one-way platforms)
   - damageOnContact: Int (for hazards)

4. Extension for SKColor with placeholder colors for each TileSet (placeholder colors for testing before real textures appear).

IMPORTANT: Use the existing PhysicsCategories structure from Utils/PhysicsCategories.swift.

---

After creating the file:

1. Add file to Xcode project:
   - Open ChroniclesOfRifts.xcodeproj
   - In navigator find Levels group
   - Drag TileSystem.swift into this group
   - Make sure Target Membership includes ChroniclesOfRifts

2. Check syntax and logic:
   - All enum cases should have rawValue of type String
   - Computed properties should correctly form texture names
   - Check for no circular dependencies between types

3. Build the project:
   xcodebuild -project ChroniclesOfRifts/ChroniclesOfRifts.xcodeproj -scheme ChroniclesOfRifts -configuration Debug build

4. Fix all compilation errors if any.
```

### Prompt 4.1.2: Creating TileMapLoader

```
Create a tile map loader for the Chronicles of Rifts game.

Create file ChroniclesOfRifts/ChroniclesOfRifts/Levels/TileMapLoader.swift:

1. Struct TileMapData (Codable):
   - width: Int (map width in tiles)
   - height: Int (map height in tiles)
   - tileSize: CGFloat (tile size in pixels, default 32)
   - layers: [TileLayerData]

2. Struct TileLayerData (Codable):
   - name: String ("ground", "decoration", "hazards")
   - zPosition: CGFloat
   - tiles: [[Int]] (2D array of tile indices, -1 = empty)

3. Class TileMapLoader:

   Properties:
   - tileSet: TileSet
   - tileSize: CGFloat

   Methods:
   - init(tileSet: TileSet, tileSize: CGFloat = 32)
   - func loadTileMap(named: String) -> TileMapData?
   - func buildTileMap(from data: TileMapData, in parentNode: SKNode)
   - func createTileNode(tileIndex: Int, at position: CGPoint) -> SKNode?

   Private Methods:
   - func tileTypeFromIndex(_ index: Int) -> TileType?
   - func setupTilePhysics(for node: SKSpriteNode, tileType: TileType)
   - func applyAutotiling(tiles: [[Int]]) -> [[Int]] (automatic corner and edge detection)

4. Autotiling logic:
   - Analyzes neighboring tiles (8 directions)
   - Automatically selects correct corner/edge
   - Uses bitmask to determine tile variant

IMPORTANT:
- Integrate with existing LevelLoader.swift - TileMapLoader supplements it, does not replace
- Use existing CGPoint.toPixels() extensions from LevelData.swift
- Physics should use PhysicsCategory from PhysicsCategories.swift

---

After creating the file:

1. Add file to Xcode project:
   - Open ChroniclesOfRifts.xcodeproj
   - In navigator find Levels group
   - Drag TileMapLoader.swift into this group

2. Check logic and connections:
   - TileMapLoader should correctly import SpriteKit
   - Check that tileTypeFromIndex covers all possible indices
   - Autotiling bitmask should be correct (8 bits for 8 neighbors)
   - Make sure createTileNode returns nil for empty tiles (-1)

3. Check integration:
   - TileSet enum should exist in TileSystem.swift
   - PhysicsCategory should be accessible from PhysicsCategories.swift

4. Build the project:
   xcodebuild -project ChroniclesOfRifts/ChroniclesOfRifts.xcodeproj -scheme ChroniclesOfRifts -configuration Debug build

5. Fix all compilation errors.
```

### Prompt 4.1.3: Creating basic tileset (placeholder textures)

```
Create a placeholder texture system for tiles in Chronicles of Rifts.

Create file ChroniclesOfRifts/ChroniclesOfRifts/Utils/PlaceholderTextures.swift:

1. Class PlaceholderTextures:

   Static Methods:
   - static func createTileTexture(type: TileType, tileSet: TileSet, size: CGSize) -> SKTexture
   - static func createPlatformTexture(type: PlatformType, size: CGSize) -> SKTexture
   - static func createHazardTexture(type: String, size: CGSize) -> SKTexture

   Private Static Methods:
   - static func drawGroundTile(context: CGContext, type: TileType, tileSet: TileSet, size: CGSize)
   - static func drawPlatformTile(context: CGContext, type: PlatformType, size: CGSize)
   - static func drawHazardTile(context: CGContext, hazardType: String, size: CGSize)
   - static func colorForTileSet(_ tileSet: TileSet) -> (primary: UIColor, secondary: UIColor, accent: UIColor)

2. Color schemes for each TileSet:
   - burningVillage: brown/orange/red (fire)
   - bridgesOfAbyss: gray/dark blue/purple
   - worldRoots: green/brown/yellow
   - catacombs: gray/gold/black
   - stormPeaks: white/light blue/gray
   - seaOfShards: light blue/white/gold
   - citadelGates: black/red/gray
   - citadelHeart: dark blue/purple/gold
   - throneHall: black/purple/red
   - awakening: purple/gold/white

3. Visual differences of tiles:
   - Ground tiles: solid fill with texture (lines/dots to simulate stone)
   - Platform tiles: horizontal lines on top
   - Hazard tiles: warning patterns (diagonal stripes for spikes, waves for lava)
   - Decoration: semi-transparent elements

4. Texture caching:
   - Use NSCache for storing created textures
   - Cache key: "\(tileSet.rawValue)_\(tileType.rawValue)_\(size.width)x\(size.height)"

IMPORTANT:
- Use UIGraphicsImageRenderer for creating images
- Textures should be tileable (edges should match)
- Default size 32x32 pixels

---

After creating the file:

1. Add file to Xcode project:
   - Open ChroniclesOfRifts.xcodeproj
   - In navigator find Utils group
   - Drag PlaceholderTextures.swift into this group

2. Check logic:
   - UIGraphicsImageRenderer should be used correctly
   - CGContext methods should be called in correct order
   - NSCache should be static for reuse

3. Check connections:
   - TileType and TileSet should be accessible from TileSystem.swift
   - PlatformType should be accessible from LevelData.swift

4. Build the project:
   xcodebuild -project ChroniclesOfRifts/ChroniclesOfRifts.xcodeproj -scheme ChroniclesOfRifts -configuration Debug build

5. Fix all errors.
```

---

## 4.2 LEVEL DESIGN

### Prompt 4.2.1: Level 1 - Burning Village (Tutorial)

```
Update level_1.json file for a complete first level of Chronicles of Rifts game.

Level 1 "Burning Village" - tutorial level.

Parameters:
- Size: 100x15 tiles (3200x480 pixels)
- TileSet: burningVillage
- Difficulty: easy (tutorial)

Level structure (left to right):

SECTION 1 (tiles 0-20): Village beginning
- Flat ground for basic controls tutorial
- 4 mana crystals in a row (reward for movement)
- Dialog trigger at start (intro_level1)
- 1 cultist with patrol (combat tutorial)
- First checkpoint at tile 20

SECTION 2 (tiles 20-40): Destroyed houses
- Platforms of different heights (jump tutorial)
- One-way platform at height 4 tiles
- Crumbling platform (mechanic tutorial)
- 2 cultists
- 3 crystals on platforms
- healthPickup at tile 35

SECTION 3 (tiles 40-65): Burning bridge
- Moving platform (vertically, then horizontally)
- Gap between tiles 38-42 (first gap)
- FloatingEye at height 5 tiles
- One-way platforms for climbing
- Second checkpoint at tile 50
- Chronicle page (page_1_1) in secret place (high on platform)

SECTION 4 (tiles 65-85): Mini-boss arena
- Enclosed arena with platforms
- bossSpawn trigger at tile 75
- 2 cultists before arena
- Crumbling platforms on arena (combat dynamics)
- healthPickup at tile 80

SECTION 5 (tiles 85-100): Path to exit
- Simple path after boss (reward for victory)
- 5 mana crystals
- Third checkpoint at tile 85
- Dialog trigger before exit (exit_level1)
- levelExit at tile 97

Enemies (total 6):
1. Cultist at tile 15 (patrol 12-18)
2. Cultist at tile 28 (static)
3. Cultist at tile 50 (patrol 45-55)
4. FloatingEye at tile 60 (height 5)
5. Cultist at tile 72 (patrol 70-75)
6. Cultist at tile 75 (patrol 73-78)

Collectibles:
- 20 manaCrystal (distributed across level)
- 2 healthPickup
- 3 checkpoint
- 1 chroniclePage

Triggers:
- dialog "intro_level1" at start
- bossSpawn at tile 75
- dialog "exit_level1" before exit

---

After updating the file:

1. Check JSON syntax:
   - All brackets closed
   - Commas between array elements
   - No trailing commas

2. Check level logic:
   - playerSpawn not inside platform
   - All platforms reachable by jump
   - No isolated sections
   - deathZoneY below all platforms

3. Check enemy data:
   - All enemy types exist in EnemyFactory
   - patrolPath doesn't go beyond platforms
   - facing correctly specified

4. Build project and run on simulator:
   xcodebuild -project ChroniclesOfRifts/ChroniclesOfRifts.xcodeproj -scheme ChroniclesOfRifts -destination 'platform=iOS Simulator,name=iPhone 15' build

5. Test level playthrough from start to end.
```

### Prompt 4.2.2: Level 2 - Bridges of the Abyss

```
Create level_2.json file for the second level of Chronicles of Rifts game.

Path: ChroniclesOfRifts/ChroniclesOfRifts/Levels/level_2.json

Level 2 "Bridges of the Abyss" - chain bridges over the chasm.

Parameters:
- id: 2
- name: "Bridges of the Abyss"
- Size: 80x20 tiles (2560x640 pixels)
- TileSet: bridgesOfAbyss
- Difficulty: medium

Level features:
- Lots of vertical gameplay
- Platforms over abyss (high deathZoneY risk)
- Moving cart platforms
- Collapsing bridges

Level structure:

SECTION 1 (tiles 0-20): Bridge start
- Starting platform (solid)
- First chain bridge (series of thin platforms)
- 3 cultists on bridge
- Crystals on bridge
- Checkpoint at tile 18

SECTION 2 (tiles 20-40): Carts
- Horizontally moving platforms (3 pieces)
- Gaps between platforms
- FloatingEye patrols above carts
- Cultist with crossbow (static, shoots)
- One-way platforms for alternative path above
- Chronicle page (page_2_1) on upper path

SECTION 3 (tiles 40-55): Vertical climb
- Series of platforms for climbing 10 tiles up
- Crumbling platforms (3 pieces)
- Vertically moving platform
- 2 FloatingEye at different heights
- Checkpoint at top (tile 52, height 12)
- healthPickup in difficult place

SECTION 4 (tiles 55-70): Long bridge
- Longest bridge of the level
- Bridge partially collapses (crumbling sections)
- Cultists patrol bridge (2 pieces)
- Wind (visual effect, not mechanic)

SECTION 5 (tiles 70-80): Grondar boss arena
- Large arena with 3 platform levels
- bossSpawn trigger
- Platforms collapse during fight (visually through triggers)
- levelExit after victory

Enemies:
1. Cultist (tile 8, patrol 5-12)
2. Cultist (tile 15, patrol 13-18)
3. Cultist (tile 18, static)
4. FloatingEye (tile 30, height 8)
5. Cultist (tile 35, static - "crossbowman")
6. FloatingEye (tile 45, height 6)
7. FloatingEye (tile 48, height 10)
8. Cultist (tile 60, patrol 58-65)
9. Cultist (tile 65, patrol 62-68)

Collectibles:
- 25 manaCrystal
- 2 healthPickup
- 3 checkpoint
- 1 chroniclePage (page_2_1)

Triggers:
- dialog "intro_level2" at start
- dialog "bridge_crumbling" when entering section 4
- bossSpawn "Grondar" at tile 72
- dialog "grondar_defeat" after boss

backgroundLayers:
- bg_abyss_far (parallax 0.05, zPosition -100) - abyss below
- bg_clouds_mid (parallax 0.2, zPosition -50) - clouds
- bg_chains_near (parallax 0.5, zPosition -20) - chains in foreground

Bounds: { x: 0, y: 0, width: 80, height: 20 }
deathZoneY: -5 (falling into abyss)

---

After creating the file:

1. Check JSON syntax:
   - Valid JSON (use jsonlint or IDE)
   - All required fields present

2. Check logic:
   - All platforms reachable
   - Moving platforms have correct movementPath
   - Crumbling platforms don't block only path
   - Boss arena has enough space for fight

3. Add file to Xcode:
   - Drag level_2.json into Levels group
   - Make sure file is added to Copy Bundle Resources

4. Update LevelLoader or GameScene if needed for new level support.

5. Build the project:
   xcodebuild -project ChroniclesOfRifts/ChroniclesOfRifts.xcodeproj -scheme ChroniclesOfRifts -configuration Debug build
```

### Prompt 4.2.3: Level 3 - World Roots

```
Create level_3.json file for the third level of Chronicles of Rifts game.

Path: ChroniclesOfRifts/ChroniclesOfRifts/Levels/level_3.json

Level 3 "World Roots" - flying grove with giant trees.

Parameters:
- id: 3
- name: "World Roots"
- Size: 90x25 tiles (2880x800 pixels)
- TileSet: worldRoots
- Difficulty: medium

Level features:
- Organic design (branches, mushrooms, vines)
- Mushroom trampolines (super jump platforms)
- Infected zones (visually different)
- Vertical and horizontal gameplay

Mechanics:
- Bounce platforms (mushrooms): type "bouncy" with bounceMultiplier: 2.0
- Vine platforms (vines): narrow vertical platforms for wall-jump-like climbing
- Infected zones: visually dark, more enemies

Level structure:

SECTION 1 (tiles 0-25): Healthy forest
- Branch platforms of various sizes
- Mushroom trampolines for climbing
- CorruptedSpirit (first appearance of new enemy)
- Crystals on branches
- Checkpoint at tile 22

SECTION 2 (tiles 25-45): Infected zone
- Dark textures (infected version)
- More CorruptedSpirit enemies
- Living roots (hazard - deal damage)
- Bouncy mushrooms for navigation
- Chronicle page in hard-to-reach place
- healthPickup

SECTION 3 (tiles 45-65): Climb to the heart
- Vertical climb 15 tiles up
- Combination of regular platforms and mushrooms
- Moving platforms (horizontally between branches)
- FloatingEye and CorruptedSpirit
- Checkpoint at height 18

SECTION 4 (tiles 65-75): Mini-boss Rotting Guardian
- Arena inside giant tree
- bossSpawn for GnarledGuardian (mini-boss)
- Platforms from roots
- After victory path continues

SECTION 5 (tiles 75-90): Heart of Corruption
- Final boss arena
- Central ancient tree
- Platforms around tree at different heights
- bossSpawn for HeartOfCorruption
- Elvira appears after victory (dialog)
- levelExit

Enemies:
1. CorruptedSpirit (tile 10, height 5)
2. CorruptedSpirit (tile 18, height 8)
3. Cultist (tile 25, patrol - infected cultist)
4. CorruptedSpirit (tile 32, height 6)
5. CorruptedSpirit (tile 38, height 4)
6. CorruptedSpirit (tile 42, height 10)
7. FloatingEye (tile 55, height 12)
8. CorruptedSpirit (tile 58, height 15)
9. CorruptedSpirit (tile 62, height 18)

Collectibles:
- 30 manaCrystal (many on branches and mushrooms)
- 3 healthPickup
- 3 checkpoint
- 1 chroniclePage (page_3_1)

New platform type for JSON:
{
    "position": { "x": 15, "y": 5 },
    "size": { "width": 2, "height": 1 },
    "type": "bouncy",
    "bounceMultiplier": 2.0
}

Triggers:
- dialog "intro_level3" - Kael enters the grove
- dialog "corruption_spreading" - when entering infected zone
- bossSpawn "GnarledGuardian" at tile 68
- bossSpawn "HeartOfCorruption" at tile 82
- dialog "elvira_freed" - after defeating boss

backgroundLayers:
- bg_forest_far (parallax 0.1) - distant trees
- bg_leaves_mid (parallax 0.3) - foliage
- bg_branches_near (parallax 0.6) - nearby branches

---

After creating the file:

1. Update LevelData.swift:
   - Add case bouncy to PlatformType enum
   - Add bounceMultiplier: CGFloat? to PlatformData

2. Update LevelLoader.swift:
   - Add bouncy platform handling in createPlatform()
   - Set userData["bounceMultiplier"] for bouncy platforms

3. Check JSON syntax and level logic.

4. Add file to Xcode project.

5. Build the project:
   xcodebuild -project ChroniclesOfRifts/ChroniclesOfRifts.xcodeproj -scheme ChroniclesOfRifts -configuration Debug build

6. Test the new bouncy mechanic.
```

### Prompt 4.2.4: Level 4 - Aurelion Catacombs

```
Create level_4.json file for the fourth level of Chronicles of Rifts game.

Path: ChroniclesOfRifts/ChroniclesOfRifts/Levels/level_4.json

Level 4 "Aurelion Catacombs" - catacombs under the capital.

Parameters:
- id: 4
- name: "Aurelion Catacombs"
- Size: 100x18 tiles (3200x576 pixels)
- TileSet: catacombs
- Difficulty: medium-high

Level features:
- Dark zones (limited visibility)
- Stealth sections (necromancer patrols)
- Raised dead (Skeleton enemies)
- Traps (spikes, falling gates)

New mechanics:
- DarkZone: zone with limited visibility (light radius around player)
- Torch: interactive object, illuminates area
- FallingGate: trap, falls when player approaches

Level structure:

SECTION 1 (tiles 0-25): Catacomb entrance
- Descent down (step platforms)
- First torches (light mechanic tutorial)
- Skeleton (first appearance)
- Floor spikes (hazard)
- Checkpoint at tile 22

SECTION 2 (tiles 25-45): Dark corridor
- DarkZone - visibility 3 tiles around player
- Rare torches (can be activated by attack)
- Skeleton patrols
- Falling gate traps (2 pieces)
- Secret passage with chroniclePage

SECTION 3 (tiles 45-60): Sarcophagus hall
- Large hall with columns
- Necromancer (EliteCultist with magic)
- Skeletons rise from sarcophagi (scripted)
- Moving platforms between columns
- Checkpoint at tile 58
- healthPickup

SECTION 4 (tiles 60-80): Underground river
- Water below (instant death like lava)
- Platforms over water
- Crumbling platforms
- FloatingEye over water
- Skeleton on platforms

SECTION 5 (tiles 80-100): Archnecromancer arena
- Large circular arena
- Meeting with Korina (dialog)
- bossSpawn Archnecromancer Salvus
- Columns as cover from magic
- levelExit after victory

Enemies:
1. Skeleton (tile 15, patrol 12-18)
2. Skeleton (tile 22, static)
3. Skeleton (tile 30, patrol 28-35)
4. Skeleton (tile 38, static)
5. Skeleton (tile 42, patrol 40-45)
6. EliteCultist (tile 52, static - necromancer)
7. Skeleton (tile 55, rises from sarcophagus)
8. Skeleton (tile 57, rises from sarcophagus)
9. FloatingEye (tile 68, height 5)
10. Skeleton (tile 72, patrol 70-75)
11. Skeleton (tile 78, static)

New types for JSON:

Hazard (spikes):
{
    "type": "hazard",
    "hazardType": "spikes",
    "position": { "x": 10, "y": 1 },
    "size": { "width": 3, "height": 1 },
    "damage": 1
}

DarkZone:
{
    "type": "darkZone",
    "position": { "x": 25, "y": 0 },
    "size": { "width": 20, "height": 18 },
    "lightRadius": 96
}

Torch (interactive):
{
    "type": "torch",
    "position": { "x": 30, "y": 3 },
    "lightRadius": 128,
    "isLit": false
}

FallingGate:
{
    "type": "fallingGate",
    "position": { "x": 35, "y": 8 },
    "triggerDistance": 64,
    "fallSpeed": 300
}

Collectibles:
- 25 manaCrystal
- 3 healthPickup
- 3 checkpoint
- 1 chroniclePage (page_4_1)

Triggers:
- dialog "catacombs_intro"
- dialog "meet_korina" at tile 82
- bossSpawn "ArchnecromancerSalvus" at tile 88
- dialog "salvus_defeat"

---

After creating the file:

1. Update LevelData.swift:
   - Add HazardData struct
   - Add DarkZoneData struct
   - Add TorchData struct
   - Add FallingGateData struct
   - Update LevelData with new arrays

2. Update LevelLoader.swift:
   - Add methods createHazard(), createDarkZone(), createTorch(), createFallingGate()
   - Integrate into buildLevel()

3. Check that all new data types parse correctly.

4. Add file to Xcode project.

5. Build the project:
   xcodebuild -project ChroniclesOfRifts/ChroniclesOfRifts.xcodeproj -scheme ChroniclesOfRifts -configuration Debug build
```

### Prompt 4.2.5: Level 5 - Storm Peaks

```
Create level_5.json file for the fifth level of Chronicles of Rifts game.

Path: ChroniclesOfRifts/ChroniclesOfRifts/Levels/level_5.json

Level 5 "Storm Peaks" - icy mountains.

Parameters:
- id: 5
- name: "Storm Peaks"
- Size: 85x22 tiles (2720x704 pixels)
- TileSet: stormPeaks
- Difficulty: high

Level features:
- Slippery platforms (ice physics)
- Falling icicles (hazard)
- Snow avalanches (sections where you need to run)
- IceGolem enemies (slow but dangerous)

New mechanics:
- IcePlatform: slippery surface (player slides when stopping)
- Icicle: falls when approaching, respawn after 5 sec
- Avalanche: zone where you need to run right, otherwise death

Level structure:

SECTION 1 (tiles 0-20): Mountain base
- Regular platforms transition to icy ones
- First icicles (mechanic tutorial)
- Snow elementals (IceGolem)
- Crystals on platforms

SECTION 2 (tiles 20-40): Icy climb
- Vertical climb on icy platforms
- Slippery surfaces complicate jumps
- Falling icicles
- Checkpoint at tile 35

SECTION 3 (tiles 40-55): Avalanche!
- Avalanche zone - trigger starts avalanche
- Player must run right
- Platforms collapse behind
- Autoscroll section (technically through triggers)

SECTION 4 (tiles 55-70): Ice caves
- Inside the mountain
- Father's notes (chroniclePage)
- IceGolem patrols
- Secret passage to bonuses
- Checkpoint at tile 65
- healthPickup

SECTION 5 (tiles 70-85): Pass Guardian
- Boss arena Kromar
- Ice platforms on arena
- Icicles fall during fight
- Choice: destroy or purify (affects ending)
- levelExit / secretExit (secret passage if purified)

Enemies:
1. IceGolem (tile 12)
2. IceGolem (tile 18)
3. Cultist (tile 25, patrol - in winter clothes)
4. IceGolem (tile 32)
5. IceGolem (tile 45) - after avalanche
6. FloatingEye (tile 58, height 8)
7. IceGolem (tile 62)
8. IceGolem (tile 68)

New types for JSON:

IcePlatform:
{
    "position": { "x": 25, "y": 5 },
    "size": { "width": 5, "height": 1 },
    "type": "ice",
    "friction": 0.1
}

Icicle (falling icicle):
{
    "type": "icicle",
    "position": { "x": 30, "y": 12 },
    "triggerRadius": 48,
    "damage": 1,
    "respawnTime": 5.0
}

AvalancheZone:
{
    "type": "avalanche",
    "triggerPosition": { "x": 40, "y": 5 },
    "startX": 40,
    "endX": 55,
    "speed": 150
}

Collectibles:
- 28 manaCrystal
- 2 healthPickup
- 3 checkpoint
- 1 chroniclePage (page_5_1) - father's notes

Triggers:
- dialog "storm_peaks_intro"
- dialog "father_notes" when finding notes
- avalanche at tile 40
- bossSpawn "FrostGuardianKromar" at tile 75
- dialog "kromar_choice" - choice destroy/purify

---

After creating the file:

1. Update LevelData.swift:
   - Add friction to PlatformData (optional)
   - Add IcicleData struct
   - Add AvalancheData struct

2. Update LevelLoader.swift for new mechanics.

3. Update Player.swift:
   - Add slippery platform handling
   - Check userData["friction"] during movement

4. Add file to Xcode project.

5. Build the project:
   xcodebuild -project ChroniclesOfRifts/ChroniclesOfRifts.xcodeproj -scheme ChroniclesOfRifts -configuration Debug build
```

### Prompt 4.2.6: Level 6 - Sea of Shards

```
Create level_6.json file for the sixth level of Chronicles of Rifts game.

Path: ChroniclesOfRifts/ChroniclesOfRifts/Levels/level_6.json

Level 6 "Sea of Shards" - archipelago of tiny floating islands.

Parameters:
- id: 6
- name: "Sea of Shards"
- Size: 95x30 tiles (3040x960 pixels)
- TileSet: seaOfShards
- Difficulty: high

Level features:
- Pure platforming
- Small islands of various sizes
- Moving and disappearing platforms
- SkyDevourer enemies (flying, kidnap player)
- Meeting with Morgana (story scene)

New mechanics:
- DisappearingPlatform: appears/disappears with interval
- FloatingIsland: platform with slight vertical oscillation
- SkyDevourer grab: enemy grabs player and lifts (need to break free)

Level structure:

SECTION 1 (tiles 0-25): First islands
- Series of small islands (2-4 tiles wide)
- Gaps between islands (precise jump tutorial)
- Floating islands (oscillate up-down)
- First SkyDevourer
- Crystals on islands

SECTION 2 (tiles 25-45): Disappearing islands
- Disappearing platforms
- Need to memorize appearance rhythm
- Moving platforms between static ones
- SkyDevourer on patrol
- Checkpoint on stable island

SECTION 3 (tiles 45-60): Meeting with Morgana
- Large island (story scene)
- dialog trigger "morgana_encounter"
- Morgana doesn't attack, only talks
- After dialog - path continues
- chroniclePage on island

SECTION 4 (tiles 60-80): Devourer nest
- Many SkyDevourer enemies
- Islands with nests (visually)
- Complex platforming
- Combination of all platform types
- healthPickup in hard-to-reach place
- Checkpoint before boss

SECTION 5 (tiles 80-95): Queen of Devourers
- Boss arena on moving islands
- Islands move in circle
- bossSpawn SkyQueenSkirra
- Boss attacks from air
- levelExit after victory

Enemies:
1. SkyDevourer (tile 15, height 10)
2. FloatingEye (tile 22, height 8)
3. SkyDevourer (tile 35, height 12)
4. SkyDevourer (tile 42, height 15)
5. Cultist (tile 50, on Morgana's island - her servant)
6. SkyDevourer (tile 65, height 10)
7. SkyDevourer (tile 70, height 8)
8. SkyDevourer (tile 75, height 12)
9. FloatingEye (tile 78, height 6)

New types for JSON:

DisappearingPlatform:
{
    "position": { "x": 30, "y": 8 },
    "size": { "width": 3, "height": 1 },
    "type": "disappearing",
    "visibleTime": 2.0,
    "hiddenTime": 1.5,
    "startVisible": true
}

FloatingIsland:
{
    "position": { "x": 15, "y": 6 },
    "size": { "width": 4, "height": 2 },
    "type": "floating",
    "floatAmplitude": 0.5,
    "floatPeriod": 3.0
}

Collectibles:
- 35 manaCrystal (many on islands)
- 2 healthPickup
- 3 checkpoint
- 1 chroniclePage (page_6_1)

Triggers:
- dialog "sea_of_shards_intro"
- dialog "morgana_encounter" at tile 50
- bossSpawn "SkyQueenSkirra" at tile 85
- dialog "skirra_defeat"

---

After creating the file:

1. Update LevelData.swift:
   - Add disappearing and floating to PlatformType
   - Add fields visibleTime, hiddenTime, startVisible
   - Add fields floatAmplitude, floatPeriod

2. Update LevelLoader.swift:
   - Disappearing platform handling (SKAction sequence show/hide)
   - Floating platform handling (SKAction moveBy sine wave)

3. Add file to Xcode project.

4. Build the project:
   xcodebuild -project ChroniclesOfRifts/ChroniclesOfRifts.xcodeproj -scheme ChroniclesOfRifts -configuration Debug build
```
------- ЗАКОНЧИЛ ТУТ -----------
### Prompt 4.2.7: Levels 7-10 (Citadel and Finale)

```
Create JSON files for levels 7-10 of Chronicles of Rifts game.

Create 4 files in ChroniclesOfRifts/ChroniclesOfRifts/Levels/:

---

LEVEL 7: level_7.json - "Citadel Gates"

Parameters:
- id: 7, name: "Citadel Gates"
- Size: 90x20 tiles
- TileSet: citadelGates
- Difficulty: high

Features:
- Combination of combat and platforming
- Traps: spikes, flamethrowers, falling gates
- Elite cultists and demon guards
- Father's notes about Kael

Sections:
1. Outer walls (0-25): storming fortifications
2. First gates (25-45): traps and patrols
3. Inner courtyard (45-65): large battles
4. Prison block (65-80): father's notes
5. Boss General Maltorus (80-90)

Enemies: 12 enemies (EliteCultist, Skeleton, FloatingEye mix)
Collectibles: 30 crystals, 3 health, 3 checkpoints, 1 page

---

LEVEL 8: level_8.json - "Citadel Heart"

Parameters:
- id: 8, name: "Citadel Heart"
- Size: 75x25 tiles
- TileSet: citadelHeart
- Difficulty: very high

Features:
- Rune puzzles (activation in correct order)
- Platforms over chasms
- Meeting with father Tariel (main story scene)
- Enemy waves in finale

Sections:
1. Containment runes (0-20): puzzles
2. Bridge over abyss (20-40): platforming
3. Meeting hall (40-55): dialog with father
4. Defense (55-75): enemy waves while father opens door

Enemies: 15+ enemies (waves at end)
No traditional boss - waves instead
Collectibles: 25 crystals, 4 health, 2 checkpoints, 1 page

---

LEVEL 9: level_9.json - "Throne Hall of the Abyss"

Parameters:
- id: 9, name: "Throne Hall of the Abyss"
- Size: 60x30 tiles (vertical arena)
- TileSet: throneHall
- Difficulty: boss level

Features:
- Morgana boss arena
- Three fight phases
- Dynamically changing arena
- Story climax

Sections:
1. Hall entrance (0-15): last enemies
2. Morgana arena (15-60): three-phase fight

Boss Morgana:
- Phase 1: shadow magic, teleport
- Phase 2: merge with Velkor's shadow
- Phase 3: half-demon form

Enemies: only Morgana
Collectibles: 10 crystals, 2 health, 1 checkpoint before boss

---

LEVEL 10: level_10.json - "Awakening"

Parameters:
- id: 10, name: "Awakening"
- Size: 50x40 tiles (vertical + chaos)
- TileSet: awakening
- Difficulty: final boss

Features:
- Final battle with Velkor
- Not direct fight - activating 4 chains
- Platforming under boss attacks
- Climax and epilogue

Fight structure:
1. Stage 1: Reach 4 chains, activate runes
2. Stage 2: Velkor weakens with each chain
3. Stage 3: Final platforming to Seal Heart
4. Climax: Seed of Life + Victory

Mechanics:
- Collapsing floor
- Velkor attacks (darkness rays, waves, tentacles)
- 4 chain objectives (interactive)

Enemies: Velkor (unique boss) + minions in stage 1
Collectibles: 5 crystals, 1 health, no checkpoints (one-shot)

---

For each file:

1. Create full JSON structure with all sections
2. Include all platforms, enemies, collectibles, triggers
3. Add backgroundLayers for atmosphere
4. Set correct bounds and deathZoneY

After creating all files:

1. Add all 4 files to Xcode project (Levels group)
2. Make sure all files are in Copy Bundle Resources

3. Check JSON syntax of each file

4. Build the project:
   xcodebuild -project ChroniclesOfRifts/ChroniclesOfRifts.xcodeproj -scheme ChroniclesOfRifts -configuration Debug build

5. Check that GameScene can load each level by number.
```

---

## 4.3 INTERACTIVE OBJECTS

### Prompt 4.3.1: CrumblingPlatform

```
Create a complete implementation of crumbling platforms.

Create file ChroniclesOfRifts/ChroniclesOfRifts/Components/CrumblingPlatform.swift:

1. Class CrumblingPlatform: SKSpriteNode

Properties:
- crumbleDelay: TimeInterval = 1.0 (time to fall after touch)
- respawnDelay: TimeInterval = 3.0 (time to respawn)
- isTriggered: Bool = false
- isFallen: Bool = false
- originalPosition: CGPoint
- originalPhysicsBody: SKPhysicsBody?

Methods:
- init(size: CGSize, texture: SKTexture?)
- func trigger() - start countdown to fall
- func fall() - platform falls
- func respawn() - platform respawns
- private func startShaking() - shake animation before falling
- private func stopShaking()
- private func createFallParticles() - particles when falling

Behavior:
1. When player steps on platform - trigger()
2. Platform starts shaking (shake animation)
3. After crumbleDelay - fall()
4. Platform falls down with physics
5. After respawnDelay - respawn() to original position

Integration:
- Use PhysicsCategory.ground for collisions
- On fall remove collisions
- On respawn restore collisions

2. Update LevelLoader.swift:
   - In createPlatform() for type .crumbling create CrumblingPlatform instead of regular SKSpriteNode

3. Update GameScene.swift:
   - In didBegin(_ contact:) add handling of player contact with CrumblingPlatform
   - Call platform.trigger() on contact

---

After creating the file:

1. Add CrumblingPlatform.swift to Xcode project (Components group)

2. Check logic:
   - Make sure trigger() is not called again if isTriggered
   - Check that respawn correctly restores physics
   - Shake animation should not conflict with fall()

3. Check integration:
   - LevelLoader should create CrumblingPlatform for type .crumbling
   - GameScene should handle contact

4. Build the project:
   xcodebuild -project ChroniclesOfRifts/ChroniclesOfRifts.xcodeproj -scheme ChroniclesOfRifts -configuration Debug build

5. Test on level_1 where crumbling platforms exist.
```

### Prompt 4.3.2: MovingPlatform with improvements

```
Improve the moving platform system.

Create file ChroniclesOfRifts/ChroniclesOfRifts/Components/MovingPlatform.swift:

1. Class MovingPlatform: SKSpriteNode

Properties:
- waypoints: [CGPoint] - path points
- speed: CGFloat - movement speed
- currentWaypointIndex: Int = 0
- isMoving: Bool = true
- pauseAtWaypoints: TimeInterval = 0 (optional pause)
- movementType: MovementType = .loop

Enum MovementType:
- loop: looped movement (A -> B -> C -> A -> ...)
- pingPong: back and forth (A -> B -> C -> B -> A -> ...)
- oneWay: one-time movement (A -> B -> C -> stop)

Methods:
- init(size: CGSize, waypoints: [CGPoint], speed: CGFloat)
- func startMoving()
- func stopMoving()
- func moveToNextWaypoint()
- private func calculateDuration(to point: CGPoint) -> TimeInterval

Critically important - moving player with platform:
- In scene's update() method check if player is standing on platform
- If yes - move player with platform
- Use previousPosition to calculate movement delta

2. Add to MovingPlatform:
- previousPosition: CGPoint
- func calculateMovementDelta() -> CGVector

3. Update GameScene.swift:
   - Add array movingPlatforms: [MovingPlatform]
   - In updateGame() call updatePlayerOnPlatforms()
   - updatePlayerOnPlatforms() checks if player is on platform and moves them

4. Update LevelLoader.swift:
   - For type .moving create MovingPlatform
   - Parse movementType from JSON if specified

---

After creating the file:

1. Add MovingPlatform.swift to Xcode project (Components group)

2. Check logic:
   - Movement between waypoints should be smooth
   - PingPong should correctly reverse direction
   - Player should move with platform

3. Check physics:
   - Player should not "slide off" platform
   - During fast platform movement player should not fall through

4. Build the project:
   xcodebuild -project ChroniclesOfRifts/ChroniclesOfRifts.xcodeproj -scheme ChroniclesOfRifts -configuration Debug build

5. Test on level_1 and level_2 where moving platforms exist.
```

### Prompt 4.3.3: Switch and Door system

```
Create a switch and door system.

Create file ChroniclesOfRifts/ChroniclesOfRifts/Components/SwitchAndDoor.swift:

1. Class GameSwitch: SKSpriteNode

Properties:
- isActivated: Bool = false
- linkedDoorId: String
- activationType: ActivationType = .attack

Enum ActivationType:
- attack: activated by attack
- step: activated when player steps on
- interact: activated by interaction button (future)

Methods:
- init(linkedDoorId: String, activationType: ActivationType)
- func activate()
- func deactivate() (for toggle switches)
- private func playActivationAnimation()
- private func notifyLinkedDoor()

On activation:
- Changes visual (color/texture)
- Sends Notification "switchActivated" with linkedDoorId

2. Class GameDoor: SKSpriteNode

Properties:
- doorId: String
- isOpen: Bool = false
- openDirection: OpenDirection = .up

Enum OpenDirection:
- up: door rises
- down: door lowers
- fade: door fades out

Methods:
- init(doorId: String, openDirection: OpenDirection)
- func open()
- func close()
- private func playOpenAnimation()
- private func playCloseAnimation()

On opening:
- Removes physics (passable)
- Opening animation
- Optionally - return to closed state after time

3. Class SwitchDoorManager

Singleton for managing switch-door connections:
- func registerSwitch(_ switch: GameSwitch)
- func registerDoor(_ door: GameDoor)
- func handleSwitchActivated(doorId: String)
- private var switches: [String: GameSwitch]
- private var doors: [String: GameDoor]

4. Update LevelLoader.swift:
   - In createInteractable() create GameSwitch and GameDoor
   - Register them in SwitchDoorManager

5. Update GameScene.swift:
   - Add attack handling on GameSwitch in didBegin contact
   - Add step handling on GameSwitch

---

After creating the file:

1. Add SwitchAndDoor.swift to Xcode project (Components group)

2. Check logic:
   - Switch should correctly find linked door by ID
   - Door should open with animation
   - Door physics should disable when open

3. Check Notification system:
   - Notification should contain doorId
   - SwitchDoorManager should receive notification

4. Build the project:
   xcodebuild -project ChroniclesOfRifts/ChroniclesOfRifts.xcodeproj -scheme ChroniclesOfRifts -configuration Debug build

5. Add switch and door to level_test.json for testing.
```

### Prompt 4.3.4: Checkpoint system

```
Create a complete checkpoint system.

Create file ChroniclesOfRifts/ChroniclesOfRifts/Components/Checkpoint.swift:

1. Class Checkpoint: SKSpriteNode

Properties:
- checkpointId: String
- isActivated: Bool = false
- respawnOffset: CGPoint = CGPoint(x: 0, y: 32) // spawn slightly above checkpoint

Visual States:
- inactive: gray/dim
- active: bright/glowing with particles

Methods:
- init(id: String)
- func activate(by player: Player)
- private func playActivationAnimation()
- private func createActiveParticles() -> SKEmitterNode?
- private func saveCheckpoint()

On activation:
1. Check that not already activated
2. Set isActivated = true
3. Change visual to active
4. Start light particles
5. Save position in GameManager
6. Send Notification "checkpointActivated"
7. Show text "CHECKPOINT" on screen

2. Update GameManager.swift:

Add:
- currentCheckpointPosition: CGPoint?
- currentCheckpointLevelId: Int?
- func setCheckpoint(position: CGPoint, levelId: Int)
- func getCheckpointPosition(for levelId: Int) -> CGPoint?
- func clearCheckpoint()

3. Update GameScene.swift:

In respawnPlayer():
- Get checkpoint position from GameManager
- If exists - spawn there
- If not - spawn at playerSpawn from levelData

Add "CHECKPOINT" display:
- func showCheckpointMessage()
- Text appears in center, rises and fades

4. Update Collectible.swift:
   - Method activateCheckpoint() should call Checkpoint.activate()
   - Or replace collectible checkpoint with separate Checkpoint class

---

After creating the file:

1. Add Checkpoint.swift to Xcode project (Components group)

2. Check logic:
   - Checkpoint activates only once
   - Position saves in GameManager
   - On death player spawns at checkpoint

3. Check visual:
   - Inactive checkpoint differs from active
   - Activation animation is visible and nice
   - "CHECKPOINT" message is readable

4. Build the project:
   xcodebuild -project ChroniclesOfRifts/ChroniclesOfRifts.xcodeproj -scheme ChroniclesOfRifts -configuration Debug build

5. Test: activate checkpoint, die, check respawn.
```

### Prompt 4.3.5: LevelExit and level transitions

```
Create a level exit and transition system.

Create file ChroniclesOfRifts/ChroniclesOfRifts/Components/LevelExit.swift:

1. Class LevelExit: SKSpriteNode

Properties:
- nextLevelId: Int
- isActive: Bool = true
- requiresKey: Bool = false
- keyId: String?
- transitionType: TransitionType = .portal

Enum TransitionType:
- portal: magic portal (glowing)
- door: regular door
- path: trail (just exit beyond edge)

Visual:
- Pulsing glow for portal
- Particles around
- Arrow or "forward" icon

Methods:
- init(nextLevelId: Int, transitionType: TransitionType)
- func enter(player: Player)
- func setActive(_ active: Bool)
- private func playEnterAnimation(completion: @escaping () -> Void)
- private func triggerLevelTransition()

On player entry:
1. Check isActive
2. If requiresKey - check for key
3. Start entry animation (player disappears into portal)
4. On completion - call triggerLevelTransition()
5. triggerLevelTransition() calls SceneManager.loadLevel(nextLevelId)

2. Update SceneManager.swift:

Add:
- func loadLevel(_ levelId: Int)
- func showLevelCompleteScreen(crystals: Int, secrets: Int, time: TimeInterval)
- func proceedToNextLevel()
- currentLevelId: Int

loadLevel():
1. Save current level progress
2. Create new GameScene with levelNumber = levelId
3. Show transition animation
4. Present new scene

3. Create LevelCompleteScene.swift:

Shows:
- "LEVEL COMPLETE"
- Crystals collected: X/Y
- Secrets found: X/Y
- Completion time
- Buttons: "Next Level", "Retry", "Menu"

4. Update GameScene.swift:

In didBegin(_ contact:) add LevelExit contact handling:
- If player + levelExit - call levelExit.enter(player)

Add levelComplete() method:
- Stop game
- Collect statistics
- Call SceneManager.showLevelCompleteScreen()

---

After creating files:

1. Add LevelExit.swift to Components group
2. Create LevelCompleteScene.swift in Scenes group (if not exists)
3. Update SceneManager.swift

4. Check logic:
   - LevelExit triggers on player contact
   - Transition animation is smooth
   - Next level loads correctly
   - Progress saves

5. Check edge cases:
   - What if nextLevelId doesn't exist?
   - What if player enters portal during animation?

6. Build the project:
   xcodebuild -project ChroniclesOfRifts/ChroniclesOfRifts.xcodeproj -scheme ChroniclesOfRifts -configuration Debug build

7. Test transition from level_1 to level_2.
```

### Prompt 4.3.6: Hazards (spikes, lava, void)

```
Create a hazard system.

Create file ChroniclesOfRifts/ChroniclesOfRifts/Components/Hazard.swift:

1. Class Hazard: SKSpriteNode

Enum HazardType:
- spikes: spikes (instant damage on touch)
- lava: lava (damage + burning)
- void: void (instant death)
- poison: poison (damage over time)
- electricity: electricity (periodic damage)

Properties:
- hazardType: HazardType
- damage: Int = 1
- damageInterval: TimeInterval = 0 (for periodic damage)
- knockback: CGFloat = 200
- appliesEffect: Bool = false (for poison/burn)
- effectDuration: TimeInterval = 0

Methods:
- init(type: HazardType, size: CGSize)
- func applyDamage(to player: Player)
- func startPeriodicDamage(to player: Player)
- func stopPeriodicDamage()
- private func createVisualEffect()
- private func setupPhysics()

Visual effects:
- Spikes: static with rare glint
- Lava: animated texture + bubble particles
- Void: dark glow + pulling effect
- Poison: green mist
- Electricity: sparks + flickering

2. Update PhysicsCategories.swift:

If not present - add:
- static let hazard: UInt32 = 0b10000

3. Update LevelData.swift:

Add HazardData struct:
struct HazardData: Codable {
    let type: String // "spikes", "lava", etc.
    let position: CGPoint
    let size: CGSize
    let damage: Int?
    let damageInterval: TimeInterval?

    enum CodingKeys: String, CodingKey {
        case type, position, size, damage, damageInterval
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = try container.decode(String.self, forKey: .type)
        position = try container.decode(PointJSON.self, forKey: .position).cgPoint
        size = try container.decode(SizeJSON.self, forKey: .size).cgSize
        damage = try container.decodeIfPresent(Int.self, forKey: .damage)
        damageInterval = try container.decodeIfPresent(TimeInterval.self, forKey: .damageInterval)
    }
}

Add to LevelData:
- hazards: [HazardData]

4. Update LevelLoader.swift:

Add createHazard() method:
func createHazard(from data: HazardData, tileSize: CGFloat) -> Hazard {
    let position = data.position.toPixels(tileSize: tileSize)
    let size = data.size.toPixels(tileSize: tileSize)
    let hazardType = HazardType(rawValue: data.type) ?? .spikes

    let hazard = Hazard(type: hazardType, size: size)
    hazard.position = position
    hazard.damage = data.damage ?? 1

    return hazard
}

5. Update GameScene.swift:

In didBegin(_ contact:):
- If player + hazard: call hazard.applyDamage(to: player)

---

After creating the file:

1. Add Hazard.swift to Xcode project (Components group)

2. Check logic:
   - Spikes deal damage once on touch
   - Lava deals damage + burning effect
   - Void - instant death
   - Periodic damage works correctly

3. Check visual:
   - Each hazard type is visually different
   - Animations and particles work

4. Check physics:
   - Hazard uses correct category
   - Player contact is detected

5. Build the project:
   xcodebuild -project ChroniclesOfRifts/ChroniclesOfRifts.xcodeproj -scheme ChroniclesOfRifts -configuration Debug build

6. Add hazards to level_test.json and test.
```

---

## 4.4 DIALOG SYSTEM

### Prompt 4.4.1: DialogData and DialogManager

```
Create a dialog system for story scenes.

Create file ChroniclesOfRifts/ChroniclesOfRifts/Managers/DialogManager.swift:

1. Struct DialogLine:
- speaker: String (speaker's name)
- text: String (line text)
- portraitName: String? (portrait image name)
- emotion: String? (emotion for portrait: "neutral", "angry", "sad", etc.)

2. Struct DialogData: Codable
- id: String (unique dialog ID, e.g. "intro_level1")
- lines: [DialogLine]
- autoAdvance: Bool = false (auto-scroll)
- autoAdvanceDelay: TimeInterval = 3.0

3. Class DialogManager

Properties:
- static let shared = DialogManager()
- private var dialogs: [String: DialogData] = [:]
- private(set) var isDialogActive: Bool = false
- weak var delegate: DialogManagerDelegate?

Protocol DialogManagerDelegate:
- func dialogDidStart(dialogId: String)
- func dialogDidEnd(dialogId: String)
- func dialogLineChanged(line: DialogLine, index: Int, total: Int)

Methods:
- func loadDialogs() - load all dialogs from JSON
- func loadDialog(named: String) -> DialogData? - load specific dialog
- func startDialog(id: String)
- func advanceDialog() - next line
- func skipDialog() - skip entire dialog
- func getCurrentLine() -> DialogLine?
- private func parseDialogsFromJSON()

4. Create dialogs.json file in Levels folder (or create Dialogs folder):

{
    "dialogs": [
        {
            "id": "intro_level1",
            "lines": [
                {
                    "speaker": "Kael",
                    "text": "What is happening? The village is on fire!",
                    "portraitName": "kael_portrait",
                    "emotion": "shocked"
                },
                {
                    "speaker": "Torvald",
                    "text": "Cultists... they attacked the Anchor. Run, warn Aurelion!",
                    "portraitName": "torvald_portrait",
                    "emotion": "urgent"
                },
                {
                    "speaker": "Kael",
                    "text": "But master...",
                    "portraitName": "kael_portrait",
                    "emotion": "sad"
                },
                {
                    "speaker": "Torvald",
                    "text": "Go! Find other guardians... This is our only chance...",
                    "portraitName": "torvald_portrait",
                    "emotion": "dying"
                }
            ]
        },
        {
            "id": "exit_level1",
            "lines": [
                {
                    "speaker": "Kael",
                    "text": "Torvald... I won't let you down. I'll find a way to stop them.",
                    "portraitName": "kael_portrait",
                    "emotion": "determined"
                }
            ]
        }
    ]
}

5. Add dialogs for all story moments from the script (all 10 levels).

---

After creating files:

1. Add DialogManager.swift to Xcode (Managers group)
2. Create Dialogs folder and add dialogs.json
3. Add JSON to Copy Bundle Resources

4. Check logic:
   - DialogData parses correctly from JSON
   - DialogManager loads all dialogs
   - startDialog() correctly starts dialog
   - advanceDialog() switches lines

5. Check edge cases:
   - What if dialogId not found?
   - What if lines is empty?
   - Double call to startDialog()

6. Build the project:
   xcodebuild -project ChroniclesOfRifts/ChroniclesOfRifts.xcodeproj -scheme ChroniclesOfRifts -configuration Debug build
```

### Prompt 4.4.2: DialogBox UI component

```
Create a visual component for displaying dialogs.

Create file ChroniclesOfRifts/ChroniclesOfRifts/Components/DialogBox.swift:

1. Class DialogBox: SKNode

Visual Layout (bottom of screen):
+--------------------------------------------------+
|  [Portrait]  | Speaker Name                       |
|              |                                    |
|              | Dialog text appears here with      |
|              | typewriter effect...               |
|              |                          [v Tap]   |
+--------------------------------------------------+

Properties:
- backgroundNode: SKShapeNode (semi-transparent background)
- portraitNode: SKSpriteNode (character portrait)
- speakerLabel: SKLabelNode (speaker's name)
- textLabel: SKLabelNode (line text)
- continueIndicator: SKSpriteNode ("continue" icon)
- isTyping: Bool = false
- typewriterSpeed: TimeInterval = 0.03 (seconds per character)
- currentText: String = ""
- displayedText: String = ""

Methods:
- init(size: CGSize) - size is screen size for positioning
- func show(animated: Bool = true)
- func hide(animated: Bool = true)
- func displayLine(_ line: DialogLine)
- func skipTypewriter() - show all text at once
- func isFullyDisplayed() -> Bool
- private func startTypewriterEffect(text: String)
- private func updatePortrait(name: String?, emotion: String?)
- private func animateContinueIndicator()

Typewriter Effect:
1. Show text character by character
2. Pause on punctuation marks (., !, ?)
3. Typewriter sound (optional)
4. On completion - show continueIndicator

2. Visual style:

Background:
- Dark blue semi-transparent (alpha 0.85)
- Rounded corners on top
- Gold border (2px)

Portrait:
- Size: 100x100
- Gold frame
- Left of text

Speaker Name:
- Font: AvenirNext-Bold, 22pt
- Color: gold (#FFD700)

Text:
- Font: AvenirNext-Medium, 18pt
- Color: white
- Line wrap (preferredMaxLayoutWidth)

Continue Indicator:
- Small down triangle
- Pulsing animation
- Appears when text is fully shown

3. Update GameScene.swift:

Add:
- dialogBox: DialogBox?
- func showDialogBox()
- func hideDialogBox()
- Subscribe to DialogManagerDelegate

On DialogManagerDelegate.dialogLineChanged():
- dialogBox.displayLine(line)

On tap during dialog:
- If isTyping - skipTypewriter()
- Otherwise - DialogManager.shared.advanceDialog()

On DialogManagerDelegate.dialogDidEnd():
- hideDialogBox()
- Resume game

4. Integration with triggers:

In didBegin(_ contact:) for trigger type .dialog:
- Pause game (but don't show pause menu)
- DialogManager.shared.startDialog(id: dialogId)
- showDialogBox()

---

After creating the file:

1. Add DialogBox.swift to Xcode (Components group)

2. Check visual:
   - DialogBox looks nice at bottom of screen
   - Text doesn't go beyond boundaries
   - Portrait displays correctly
   - Typewriter effect works

3. Check logic:
   - Tap during typing - shows all text
   - Tap after full display - next line
   - After last line - dialog closes

4. Check integration:
   - Dialog trigger in level starts dialog
   - Game is paused during dialog
   - After dialog game continues

5. Build the project:
   xcodebuild -project ChroniclesOfRifts/ChroniclesOfRifts.xcodeproj -scheme ChroniclesOfRifts -configuration Debug build

6. Test "intro_level1" dialog on first level.
```

### Prompt 4.4.3: Complete dialog set for the game

```
Write all dialogs for Chronicles of Rifts game.

Update file ChroniclesOfRifts/ChroniclesOfRifts/Dialogs/dialogs.json:

Add dialogs for all story moments:

LEVEL 1 - Burning Village:
- intro_level1: Torvald dies, guidance to Kael
- exit_level1: Kael vows revenge

LEVEL 2 - Bridges of the Abyss:
- intro_level2: Kael sees destruction scale
- bridge_crumbling: Bridge starts collapsing
- grondar_intro: Grondar betrays his people
- grondar_defeat: Grondar's last words about Anchors

LEVEL 3 - World Roots:
- intro_level3: Kael enters infected grove
- corruption_spreading: Corruption spreads
- gnarled_guardian: Meeting with Rotting Guardian
- elvira_freed: Elvira thanks and joins

LEVEL 4 - Aurelion Catacombs:
- catacombs_intro: Descent into catacombs
- meet_korina: Meeting with Korina
- salvus_intro: Archnecromancer starts ritual
- salvus_defeat: Korina explains the plan

LEVEL 5 - Storm Peaks:
- storm_peaks_intro: Icy mountains
- father_notes: Kael finds father's notes
- kromar_intro: Pass Guardian awakens
- kromar_choice: Choice - destroy or purify
- kromar_purified: (if purified) Kromar opens secret path

LEVEL 6 - Sea of Shards:
- sea_of_shards_intro: Archipelago over abyss
- morgana_encounter: Morgana talks about father
- skirra_intro: Queen of Devourers
- skirra_defeat: Path to Citadel opens

LEVEL 7 - Citadel Gates:
- citadel_gates_intro: Army of the corrupted
- father_cell: Father's traces in prison
- maltorus_intro: General of Corruption
- maltorus_defeat: Gates open

LEVEL 8 - Citadel Heart:
- citadel_heart_intro: Containment runes
- father_reunion: Meeting with Tariel
- father_explanation: Tariel explains how to win
- father_sacrifice: Tariel stays to cover

LEVEL 9 - Throne Hall:
- throne_hall_intro: Kael enters the hall
- morgana_final: Morgana starts ritual
- morgana_phase2: Merge with Velkor's shadow
- morgana_phase3: Transformation
- morgana_defeat: Anchor destroyed

LEVEL 10 - Awakening:
- velkor_awakening: Velkor awakens
- chain1_activated: First chain
- chain2_activated: Second chain
- chain3_activated: Third chain
- chain4_activated: Fourth chain
- final_climb: Path to Seal Heart
- victory: Victory, Seed of Life works
- epilogue: Epilogue with father and allies

Each dialog format:
{
    "id": "dialog_id",
    "lines": [
        {
            "speaker": "Name",
            "text": "Line text in Russian language",
            "portraitName": "portrait_name",
            "emotion": "neutral"
        }
    ]
}

Emotions: neutral, happy, sad, angry, shocked, determined, dying, evil, desperate

Characters with portraits:
- Kael (kael): main hero
- Torvald (torvald): mentor
- Elvira (elvira): forest spirit
- Korina (korina): resistance commander
- Tariel (tariel): Kael's father
- Morgana (morgana): antagonist
- Grondar (grondar): level 2 boss
- Archnecromancer (salvus): level 4 boss
- Kromar (kromar): level 5 boss
- Maltorus (maltorus): level 7 boss
- Velkor (velkor): final boss

---

After updating the file:

1. Check JSON syntax:
   - Valid JSON
   - All strings in quotes
   - Cyrillic correctly encoded (UTF-8)

2. Check completeness:
   - All dialogId from triggers in levels are present
   - No empty dialogs
   - Story is logically consistent

3. Check style:
   - Dialogs match character personalities
   - Russian language is grammatically correct
   - Lines not too long (2-3 lines maximum)

4. Build the project:
   xcodebuild -project ChroniclesOfRifts/ChroniclesOfRifts.xcodeproj -scheme ChroniclesOfRifts -configuration Debug build

5. Test several dialogs in game.
```

---

## GENERAL INSTRUCTIONS FOR ALL PROMPTS

After completing each prompt:

### 1. Adding files to Xcode project

# If file is created in correct folder, add it to project:
# 1. Open ChroniclesOfRifts.xcodeproj in Xcode
# 2. In Project Navigator find corresponding group
# 3. Right-click -> Add Files to "ChroniclesOfRifts"
# 4. Select created file
# 5. Make sure Target Membership includes ChroniclesOfRifts
# 6. For resources (JSON, images) make sure they are in Copy Bundle Resources

### 2. Syntax and logic check

Before building manually check:

Swift files:
- All imports present (import SpriteKit, import Foundation)
- All types defined or imported
- No typos in method and property names
- Closures have correct capture list [weak self]
- Optional unwrapping is safe (guard let, if let)

JSON files:
- Valid JSON syntax
- All required fields present
- Data types match expected (numbers without quotes, strings in quotes)
- No trailing commas

### 3. Building the project

# Debug build
xcodebuild -project ChroniclesOfRifts/ChroniclesOfRifts.xcodeproj \
    -scheme ChroniclesOfRifts \
    -configuration Debug \
    build

# Build for simulator with launch
xcodebuild -project ChroniclesOfRifts/ChroniclesOfRifts.xcodeproj \
    -scheme ChroniclesOfRifts \
    -destination 'platform=iOS Simulator,name=iPhone 15' \
    build

# If there are errors - fix them before continuing

### 4. Testing

After successful build:
1. Run on simulator (Cmd+R in Xcode)
2. Check that new functionality works
3. Check that existing functionality is not broken
4. Check console for warnings and errors

---

## PHASE 4 COMPLETION CHECKLIST

After completing all prompts check:

- [ ] TileSystem.swift created and compiles
- [ ] TileMapLoader.swift created and compiles
- [ ] PlaceholderTextures.swift created and compiles
- [ ] All 10 levels (level_1.json - level_10.json) created
- [ ] CrumblingPlatform.swift works
- [ ] MovingPlatform.swift works with player
- [ ] Switch and Door system works
- [ ] Checkpoint system saves progress
- [ ] LevelExit transitions to next level
- [ ] Hazards deal damage
- [ ] DialogManager loads dialogs
- [ ] DialogBox displays dialogs with typewriter effect
- [ ] All dialogs written and load
- [ ] Project builds without errors
- [ ] Can complete level_1 from start to end
