# Pixel Lab generation batch

The 314 request units in `queue.json` cover the visual asset manifest: characters, directional animations, portraits, terrain transitions, architecture, props and states, effects, icons, and UI art. Audio is not supported by this visual generation batch.

Generation is asynchronous and limited by Pixel Lab's concurrent-job allowance. The local worker submits requests as capacity becomes available. A locally queued request is not necessarily submitted to Pixel Lab yet.

- `status.json`: per-request state, remote job IDs, failures, and downloaded file counts.
- `requests/`: exact prompts and generation parameters, without credentials.
- `results/`: original submissions and completed job responses.
- `assets/`: downloaded PNGs grouped by manifest ID.
- `balance-after.json`: final balance after the worker stops.

The worker is `../tools/pixellab_batch.py`. It reads the API key from standard input and keeps it in memory. It never purchases credits. Accepted submissions are saved before polling, allowing completed or pending remote jobs to be resumed without submitting them again. Requests marked `needs_review` are not automatically retried because their submission status may be uncertain.

All generated artwork is a first production pass, pending review. Generating an asset does not add it to the game. These are currently copied into `../game`:

- Wizard: still rotations; walk, cast, dodge, hurt, and death clips (`../tools/copy_character_frames.py`). Walk, dodge, hurt, and death are pinned to the ground line (`../tools/ground_lock_frames.py`). Dodge west is mirrored from east, and dodge north reuses its first two frames because the staff vanishes later.
- Three enemies: still rotations and walk, attack (the Scholar's cast), hurt, and death clips, ground-locked. The Skitter's west death is mirrored from east.
- Two NPCs: still rotations.
- Candle flicker (`../tools/copy_prop_frames.py`), with the stand pinned so only the flame moves.

Every idle (wizard, enemies, NPCs) is a subtle breathing loop built from the stills (`../tools/make_breathing_idle.py`), because the generated idle clips shimmer and exaggerate the motion.

The spell effects (FX-01 to FX-16) are unusable: each came out as an academy building. The brazier (PROP-26) and ward beacon (PROP-20) ambient clips have the same problem.

The game is independently playable while this queue runs. The worker needs the computer to stay running and online. If the worker is interrupted, it can resume with the same queue and a key supplied again on stdin.

## Second pass (2026-09-28)

The first pass prefixed every prompt with "...a ruined magical academy RPG...", and for abstract subjects the generator drew the academy. The second pass (`../tools/build_regen_queue.py`, `queue-regen.json`) describes only the subject, isolated on a transparent background with no scenery, buildings, ground, or people, and keeps the outline, lighting, and palette notes. Every output was reviewed on a contact sheet and in the running game before use. It used 75 generations (500 → 425); every request cost 1 generation.

The storage host (`backblaze.pixellab.ai`) was not reachable from the generation environment, so clips were taken from the inline `image_images_*.png` frames, which are the same frames with the source pose first. Several submissions hit connection resets and were resubmitted; a -b or -c suffix marks a second or third take.

Effects, copied by `../tools/copy_effect_frames.py` into `../game/assets/effects/`, replacing the code-drawn versions:

| Game effect | Clip used | Notes |
|---|---|---|
| Firebolt | FXR-firebolt-animation, frames 0–3 | Loop; the last frame darkens |
| Fire impact | FXR-fire-impact-animation, frames 0–3 | Later frames turn into a campfire |
| Hit spark (melee hits on the wizard) | FXR-hit-spark-animation, frames 0–3 | The game fades it out |
| Frost Nova ring | FXR-frost-nova-animation, frames 0–2 | Scaled to the nova radius; later frames collapse to a thin ring |
| Chill status | FXR-chill-animation, frames 0–4 | Loop over chilled enemies (the blue tint stays) |
| Enemy fire bolt | FXR-ember-bolt-b-animation, frames 0–3 | Orange art tinted ember red in code |
| Enemy bolt impact | FXR-ember-impact-b-animation, frames 0–1 | Later frames grow dark blobs |
| Level-up | FXR-level-up-c-animation, frames 0–5 | The last frame is a solid grey square |

Rejected effects: FXR-ember-bolt (a crimson dart, not fire), FXR-ember-impact (a rubble pile on rocks), FXR-level-up (drawn on a stone floor tile), and FXR-level-up-b (smoke clouds and a ground line).

Item icons (`../tools/make_item_icons.py`): all twelve placeholders and the five wrong icons are replaced: scholars_hood, warden_helm, cloth_wraps, bronze_gauntlets, worn_sandals, bronze_greaves (-b), rope_belt, scholars_sash, copper_amulet, quartz_amulet, copper_focus, quartz_focus, apprentice_staff (-b), rime_staff, warded_robe, ruby_ring, topaz_ring. Rejected: the first bronze_greaves (a single leather boot) and the first apprentice_staff (reads as a spear). The code-drawn placeholders and recolours are gone; none of the reviewed icons needed them.

Passive icons (`../game/assets/passives/`, drawn by the passive tree in place of its code-drawn symbols): vitality, deep_reserves, spell_mastery, frostweaving, keen_mind (-b). The first Keen Mind was a dark wheel. The tree still draws its symbol for any node without a PNG.

Wizard (CH-01) clips, generated as `CH-01-<action>2-<direction>` on the existing character and copied with `../tools/copy_character_frames.py`:

- Walk: all 8 directions replaced (8 frames, longer stride), ground-locked.
- Dodge: all 8 directions replaced with generated frames 1–4 of 6 (a deep forward lunge), ground-locked. North-west and south-west were resubmitted after connection resets.
- Cast: only north (generated frames 1, 2, 3, 5; the staff stays in hand) and west (generated frames 2–5; now faces west throughout) are replaced; four frames keep the old timing. The other new cast directions were not used: north-east shows a doubled staff for a frame and south-east adds a spell spark, and the existing clips were fine. The whole cast folder is ground-locked, which lowers north-east by 2 pixels.

## HUD pass (2026-09-28)

`../tools/build_hud_queue.py` (`queue-hud.json`) asked for two takes of each HUD piece with the same setting-free prompts; 9 generations (425 → 416). `../tools/make_hud_art.py` builds `../game/assets/ui/` from the reviewed picks:

| Piece | Used | Notes |
|---|---|---|
| Life flask | HUD-life-flask-b, cropped | Take a was a different, larger flask shape |
| Mana flask | HUD-life-flask-b with the liquid shifted to blue | Matches the life flask exactly; HUD-mana-flask-a was a different shape and -b failed with a connection reset |
| Life and mana bar frame | HUD-bar-frame-a, cropped, stretched as a nine-patch | Take b (scroll ends, textured slot) was too heavy for thin bars |
| Firebolt skill icon | HUD-skill-firebolt-b | Take a had a black scribble in the flame |
| Frost Nova skill icon | HUD-skill-frost-nova-a | Take b was washed out |

The flask's liquid level shows its charges (the rest of the flask is drawn dark), with a pip per drink below it. The first pass's UI-01 bar sheet and UI-02 slot frames are still unused.

## Experience bar (2026-09-28)

HUD-exp-frame-a drew two separate bars side by side; the left one is cropped out by `../tools/make_hud_art.py` as `exp_frame.png` and stretched as a nine-patch. HUD-exp-frame-b was a single bar with a seam in the middle. 2 generations.

## Village environment (2026-09-28)

A village set modelled on a reference screenshot of a top-down medieval village (forge, tavern, barn, sawmill, farm plots, training yard). `../tools/build_village_queue.py` writes `queue-village.json`. Nothing here is in the game yet; `village_keepers.png` is a contact sheet of the usable pieces. It used 109 generations (409 → 300 after the tests), 40 of them on two tiles-pro terrain sets.

What worked: `/map-objects` (1 generation, straight-on high top-down view) for buildings and props; `/create-tiles-pro` with `tile_feature: tileset` for terrain (20 generations for a 16-tile corner set); `/create-character-v3` for villagers. What did not: pixen drew the cut-away tavern isometric twice; `/create-tileset` drew the dirt road as bricks, then planks. Short map-object prompts often came back as small isometric dioramas on a grass tile, so second and third takes spell out a flat straight-on view with nothing underneath. Character rotations and map objects are not on the storage host's links alone: the worker now reads bare base64 images and falls back to the character ZIP export.

| Group | Usable | Not usable |
|---|---|---|
| Terrain | VIL-T-grass-dirt-c (grass ↔ dirt road), VIL-T-grass-soil (grass ↔ tilled soil; its grass is more olive than the dirt set's) | VIL-T-grass-dirt, -b (bricks, planks) |
| Buildings | tavern-c (cut-away interior), barn, forge-b (furnace, anvil and floor, no walls), sawmill-c, cottage-b (slightly angled), watchtower-b | tavern, tavern-b, forge, cottage, sawmill, sawmill-b, watchtower (isometric) |
| Nature | pine-tree-b, oak-tree, bush, boulder, flowers, stump | mountain, -b, -c (always an isometric island), pine-tree, pine-tree-c (dioramas) |
| Props | well, barrel, barrels-b, crate, crates-b, lamp-post, fence-h, fence-v, log-pile-b, hay-bale, firewood-cart, produce-crate, training-dummy, archery-target, weapon-rack, workbench | barrels, crates, log-pile (dioramas), chopping-block, -b (a stool) |
| Farm and animals | carrots-c, cow-b, sheep, chicken | carrots, -b, wheat, -b, -c, cabbages (raised isometric beds), cow (tiny); cabbages-b failed with a connection reset |
| Villagers (8 rotations each) | blacksmith, farmer, villager, militia, archer, lumberjack | |

The reference's interface (resource counters, quest panel, task tracker, day and season panel, action buttons, minimap) belongs to a village-management game and was not generated.

The village set is now in the game (`../game/village.tscn`), built into `../game/assets/village/` and `../game/assets/npcs/` by `../tools/make_village_art.py`. It keeps only the tavern's largest shape (a vent and a door floated below it) and fills the forge floor's see-through stone joints. The soil terrain set is not used: the garden is carrot plots on grass.

The villagers were regenerated at 64 px (`VIL-C-<name>-64`, 12 generations): at 48 px they stood a head shorter than the wizard, the enemies and the academy NPCs, which are all 64 px. The dash icon is HUD-skill-dash-b (a wind swoosh); take a, an orb with speed lines, read as a spell projectile.

## Wind Slash (2026-09-28)

`../tools/build_melee_queue.py` (`queue-melee.json`), about 20 generations. The slash is a 6-frame clip in 8 directions in `../game/assets/wizard/slash/`. The first takes (CH-01-slash-*, `/animate-character`) drifted in colour and mostly swung the staff. The second (CH-01-slash-b-*, `/animate-with-text-v3` from each still with `drift_threshold` 0) hold his colours and show a sword. East is the west clip mirrored (its own sword smeared into a grey blob), and north-west is north-east mirrored (its staff vanished). The wind crescent is FXM-wind-slash-b (frames 0–4); the first effect filled its middle with a dark disc. The skill icon is HUD-skill-wind-slash-b.
