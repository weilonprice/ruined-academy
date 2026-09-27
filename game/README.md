# Ruined Academy — combat prototype

Open `project.godot` in Godot 4.7 and press **F5**, or run `../play.sh`, which imports assets first.

## Controls

| Action | Input |
|---|---|
| Move | **W A S D** |
| Magic bolt (aimed at the cursor) | **Left-click** |
| Frost Nova (burst around you) | **Right-click** |
| Dodge | **Space** |
| Life / Mana Flask | **1** / **2** |
| Inventory | **I** (Esc closes) |
| Character sheet | **C** |
| Show every item label | hold **Alt** |
| Pause menu (Resume / Quit) | **Esc** |
| Restart after falling | **R** |
| Fullscreen | **F11** or **Alt + Enter** |
| Debug: roll and equip an item / clear gear / respawn enemies | **F3** / **F4** / **F5** |

## The wizard

The wizard has 100 life and 60 mana, regenerating 6 mana per second. Life and mana bars are top-left; flask vials and the skill bar are bottom-centre.

- **Magic bolt:** 5 mana, 8–12 damage, then 0.25 s before the next cast. It launches from the staff's orb and flies through the clicked point.
- **Frost Nova:** 12 mana, then 0.45 s. It hits every enemy within about 90 pixels once for 12–18 cold damage and chills them for 2 s, so they move, animate, and attack at 70% speed.
- **Crits:** both spells have a 5% base chance to crit for 1.5× damage; a crit bolt looks larger and whiter.
- **Dodge:** a 68-pixel dash over 0.2 s toward the keys you hold (or the way you face), leaving afterimages; 0.5 s cooldown. There is no invincibility.
- **Flasks:** the Life Flask recovers 50 life over 2 s (10 of 30 charges); the Mana Flask 40 mana over 1.5 s (5 of 20). A flask can't be drunk again while it's recovering. Kills refill charges, and flasks start full each run.
- **Falling:** at zero life the wizard falls, enemies stand down, and **R** restarts. Gear is kept.

## Enemies

Three enemies wait at the north edge until the wizard comes within about 220 pixels or shoots them, then attack. Each has 30 health, flinches when hit, and plays a death animation. Hitting one mid-windup cancels its attack, and melee blows land partway through the swing, so stepping or dodging away avoids them.

| Enemy | Behaviour | Damage | Flask charges on kill |
|---|---|---|---|
| Skitter | Rushes in and claws | 8 physical | 5 |
| Sentinel | Lumbers in and punches | 16 physical | 10 |
| Scholar | Keeps its distance and throws ember-red bolts you can sidestep | 10 fire | 5 |

Armour reduces physical hits (big hits get through more); fire resistance reduces the Scholar's bolts.

## Items and stats

Gear sets the wizard's stats: life, life regeneration, armour, mana, mana regeneration, spell damage, cast speed, projectile speed, critical strike chance, and fire, cold, and lightning resistance (capped at 75%).

Items have a base type (22 across weapon, off-hand, helmet, body, gloves, boots, belt, amulet, and two rings), a rarity, and random affixes whose tiers depend on item level:

- **Normal** (white): no affixes.
- **Magic** (blue): a prefix and/or a suffix.
- **Rare** (yellow): 3–6 affixes and a two-word name.
- **Unique** (orange): fixed stats, such as *The Headmaster's Mantle* and *Emberlink*.

Equipped gear and the backpack are saved to `user://inventory.json`, so they survive death, restarts, and quitting.

## Inventory

**I** opens the inventory on the right half of the screen (the camera shifts so the wizard stays in view): equipment slots above a 10×5 grid where items keep their shape (a staff is 2×4, a ring 1×1).

- Click an item to carry it; click again to place it. Dropping onto exactly one item swaps them.
- Click an equipment slot to equip the carried item; what was there is carried instead.
- **Shift+click** equips from the backpack or unequips to it.
- Hover for a tooltip; backpack items also show how equipping them would change each stat.
- Clicking the world while carrying an item drops it at the wizard's feet. Casting is paused while carrying.

## Loot

Enemies drop items when they die: the Skitter and Scholar drop 0–2 at item level 15, and the Sentinel always drops at least one, with better odds of rares, at item level 20. Drops pop out and land nearby with a label in their rarity colour; rares and uniques also get a beam of light. Normal items show their label only while **Alt** is held.

Click a label (or the item) to pick it up. In reach it goes straight into the backpack; otherwise the wizard walks over first, and a movement key cancels the walk. A full backpack leaves the item on the ground. Items on the ground aren't saved.

## The courtyard

The map is 1600 × 960 pixels with grass, earth paths, and a stone courtyard; the camera follows the wizard and stops at the edges. The caretaker and the artificer stand in the courtyard and turn to watch the wizard (they can't be talked to yet), and candle stands flicker at its corners. Characters and props overlap by depth.

The full Pixel Lab art batch lives in `../art_library`; see its README for which assets the game uses.
