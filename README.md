# Ruined Academy

A solo-first, dark-fantasy pixel-art Action RPG built in **Godot 4.7** for desktop (macOS / Linux / Windows).

![Gameplay Preview](game/tests/preview.png)

## Overview

You play as a former student wizard returning to a ruined magical academy. Master elemental and forbidden magic, customize spells, allocate points into a branching passive tree, battle corrupted monstrosities, and restore the academy's forgotten workshops and ward beacons.

- **Perspective**: Elevated top-down view with clear pixel readability and silhouettes.
- **Controls**: Fluid 8-directional WASD movement and responsive mouse-aimed casting.
- **Combat**: Fast magic projectiles with raycast sweep collision, point-blank overlap handling, enemy hit flashes, and dynamic overhead health bars.
- **Visuals**: Cohesive dark-fantasy palette (desaturated stone, weathered bronze, ink-blue shadows, and vibrant elemental magic) generated with Pixel Lab.

---

## Project Structure

```
├── game/                    # Godot 4.7 project
│   ├── project.godot        # Engine configuration (640x400 native viewport, GL Compatibility)
│   ├── main.tscn            # Primary playable combat scene
│   ├── player.gd            # Wizard movement, 8-way facing, and projectile firing
│   ├── projectile.gd        # Swept raycast magic missile with collision & despawning
│   ├── enemy.gd / enemy.tscn# Enemy AI (chase, melee/ranged attacks), damage, animations, health bar
│   ├── enemy_projectile.gd  # The Scholar's hostile bolt
│   ├── hud.gd               # Life and mana bars, messages, fallen prompt
│   ├── stats.gd             # Character stats from gear; armour and resistance maths
│   ├── inventory.gd         # Autoload: equipped gear, 10x5 backpack grid, save file
│   ├── items/               # Item bases, affixes, uniques, and the random item generator
│   ├── character_panel.gd   # Character sheet (C)
│   ├── inventory_panel.gd   # Inventory screen (I): equipment slots and backpack grid
│   ├── item_tooltip.gd      # Item tooltip with stat comparison
│   ├── loot.gd              # Enemy drop tables and spawning items on the ground
│   ├── ground_item.gd       # An item on the ground: icon, label, beam, pickup
│   ├── animation_library.gd # Builds directional animations from asset folders
│   ├── npc.gd / npc.tscn    # Idle NPC that turns to watch the wizard
│   ├── prop.gd              # Looping animated prop (candles)
│   ├── map.gd               # Map layout (stone courtyard, paths, grass)
│   └── tests/               # Headless automated test suite (combat, movement, preview)
├── art_library/             # 300+ generated visual assets from Pixel Lab
│   ├── assets/              # Sprites, directional animation sheets, props, tiles, UI, icons
│   ├── queue.json           # Declarative generation queue
│   └── status.json          # Production pipeline tracking
├── tools/                   # Generation automation scripts
│   ├── build_asset_queue.py # Translates ASSET_MANIFEST into API tasks
│   ├── make_item_icons.py   # Builds game/assets/icons (generated, recoloured, placeholder)
│   └── pixellab_batch.py    # Multi-worker generation processor
└── ASSET_MANIFEST.md        # Comprehensive art specification and production roadmap
```

---

## Getting Started

### Prerequisites

- [Godot Engine 4.7](https://godotengine.org/) (Standard or .NET edition)

### Running the Game

1. Open Godot and click **Import**.
2. Select the `game/project.godot` file in this repository.
3. Open `main.tscn` and press **F6** (or **F5** to run the project).

Or, from a terminal in the repository root:

```bash
./play.sh
```

The script imports assets before launching. Godot's import cache (`game/.godot/`) isn't committed, so running a fresh clone with `godot --path game` directly shows no sprites. Set `GODOT=/path/to/godot` if Godot isn't on your `PATH`.

### Controls

| Action | Input |
|---|---|
| Move Up / Left / Down / Right | **W** / **A** / **S** / **D** |
| Aim | **Mouse Cursor** |
| Cast Magic Missile | **Left Mouse Button** |
| Dodge | **Space** |
| Restart after falling | **R** |
| Inventory (click to move, Shift+click to equip/unequip) | **I** (Esc closes) |
| Pick up loot (walks over if far) | **Left-click** its label |
| Show every item label | hold **Alt** |
| Character sheet (gear and stats) | **C** |
| Debug: roll and equip a random item / clear gear / respawn enemies | **F3** / **F4** / **F5** |
| Toggle Fullscreen | **F11** or **Alt + Enter** |

---

## Running Automated Tests

The project includes headless automated integration tests:

```bash
# Loot: drops, labels, pickup, dropping items
godot --headless --path game -s res://tests/loot_test.gd

# Inventory screen: cursor, swaps, equipping, tooltips
godot --headless --path game -s res://tests/inventory_ui_test.gd

# Items, affixes, stats, inventory, and saving
godot --headless --path game -s res://tests/items_test.gd

# Enemy AI, wizard health, death, and restart prompt
godot --headless --path game -s res://tests/ai_test.gd

# Wizard idle, walk, and cast animations
godot --headless --path game -s res://tests/animation_test.gd

# Movement & boundary verification
godot --headless --path game -s res://tests/movement_test.gd

# Combat, swept raycasts, damage, and projectile cleanup
godot --headless --path game -s res://tests/combat_test.gd

# Viewport preview capture
godot --headless --path game -s res://tests/render_preview.gd
```

---

## License

This project is licensed under the MIT License.
