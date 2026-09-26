# Ruined Academy — combat prototype

Open `project.godot` in Godot 4.7 and press **F6** with `main.tscn` open, or **F5** to run the project.

Move with **W A S D**. **Left-click** to fire one projectile toward the mouse. Press **Space** to dodge: a quick dash toward the keys you hold, or the way you face. Press **F11** or **Alt + Enter** to toggle fullscreen. Each of the three stationary enemies has 3 health, turns to face the wizard, flinches when hit, and plays a death animation after 3 hits. A projectile deals 1 damage and disappears on impact or when it leaves the map.

The caretaker and the artificer stand in the courtyard and turn to watch the wizard (they can't be talked to yet), and candle stands flicker at its corners. Characters and props overlap by depth.

The map is 1600 × 960 pixels with grass, earth paths, and a stone courtyard. The camera follows the wizard and stops at the map edges.

The larger Pixel Lab art batch is stored separately in `../art_library`. Only the wizard's and three enemies' sprites and animations are used by this scene.
