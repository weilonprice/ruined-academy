# Ruined Academy — First Playable Asset Manifest

Status: visual generation authorized and started on 2026-09-25. The separate movement prototype contains only an empty map, the generated wizard, and WASD movement.
Updated: 2026-09-25.

## Project direction

A solo-first, dark-fantasy pixel-art action RPG for Mac, built in Godot. The protagonist is a former student returning to a ruined magical academy. WASD movement and mouse aiming support a mixture of crowd combat and deliberate boss encounters. Elemental and forbidden magic feed into customizable spells and a branching passive tree. Forbidden magic has visible gameplay costs.

The first playable targets a 20–30-minute journey through an academy courtyard and adjoining wing, with one wizard, three ordinary enemies, one boss, equipment drops, two NPCs, a restored workshop, and a small decoration-placement area.

Story names, item names, and creature designs below are working proposals. Little Master Merlin informs camera, readability, and visual feel; assets will have original designs.

## Pixel Lab connection

- Verified an authenticated, read-only `GET https://api.pixellab.ai/v2/balance` on 2026-09-25; HTTP 200.
- Subscription: active, Tier 1: Pixel Apprentice.
- Reported subscription generations: 1,030 available; reported total: 2,000.
- Separate USD credit balance: $0.00.
- The initial connection test made no generation requests. The subsequent user instruction authorized the visual batch; progress is recorded in `art_library/status.json`. The API key is not saved in this project.
- This verifies direct API access; it does not install a persistent Codex MCP integration.
- Official API documentation: https://api.pixellab.ai/v2/llms.txt
- Public price estimates: https://www.pixellab.ai/pixellab-api

## Proposed art specification

| Property | Starting specification |
|---|---|
| Camera | Elevated top-down view, with visible character fronts and building faces |
| Environment grid | 32 × 32 pixel tiles |
| Wizard/enemy canvas | 64 × 64 pixels; consistent ground contact and body scale |
| Boss canvas | Approximately 96 × 96 or 128 × 128 pixels |
| Icons | 32 × 32 pixels, readable at native scale |
| Portraits | 96 × 96 pixels |
| Palette | Desaturated stone, ink-blue shadows, weathered bronze; distinct spell colors |
| Lighting | Consistent upper-left lighting on sprites and props |
| Files | Transparent PNGs for sprites; PNG atlases and frame metadata for animations |
| Animation | Start with 4–8 frames per action; adjust after motion review |
| Readability | Clear silhouettes, visible enemy windups, effects that preserve floor visibility |
| Interface text | Separate, readable text; no generated text baked into panels |

Canvas dimensions and palette are provisional until the style test is reviewed. Rotation should not change character proportions, clothing, or staff details. Equipment initially changes stats and icons; separate wearable animation sets are outside this first manifest.

## Production order

1. Style test: validate the wizard, environment scale, one enemy, and one spell together.
2. Combat essentials: wizard motion, enemies, boss, spell effects, readable combat HUD.
3. Exploration and rewards: connected terrain, props, loot icons, inventory, dialogue.
4. Academy restoration: workshop states, gathering nodes, placeable decorations, crafting UI.
5. Polish: portraits, ambient motion, audio, and consistency corrections.

## Stage 0 — style test

These are samples of production assets, not an additional content set.

| ID | Deliverable | Scope |
|---|---|---|
| TEST-01 | Wizard design candidates | 2–3 single-facing variations; select one before producing rotations |
| TEST-02 | Wizard movement sample | One short walk animation in one direction for the selected design |
| TEST-03 | Academy environment sample | Small courtyard sample showing a floor, wall, doorway, and rubble at matching scale |
| TEST-04 | Enemy design sample | One south-facing Ashbound Scholar |
| TEST-05 | Spell sample | Firebolt projectile and impact |

Acceptance: readable at native scale, consistent palette/perspective, no blurry edge pixels, coherent character proportions, and compatible ground-contact points. An environment concept alone does not count as a usable connected tileset.

## A — characters and animations

| ID | Asset | Facings | Actions | Directional clips |
|---|---|---:|---|---:|
| CH-01 | Former student wizard | 8 | Idle, move, cast, channel, dodge, hurt, death | 56 |
| EN-01 | Ruin Skitter — rushing creature | 4 | Idle, move, attack, hurt, death | 20 |
| EN-02 | Ashbound Scholar — ranged caster | 4 | Idle, move, cast, hurt, death | 20 |
| EN-03 | Broken Sentinel — armored guardian | 4 | Idle, move, attack, hurt, death | 20 |
| BO-01 | Corrupted Warden | 4 | Idle, move, melee attack, cast, summon, stagger, death | 28 |
| NPC-01 | Academy caretaker | 4 | Idle | 4 |
| NPC-02 | Rescued artificer | 4 | Idle | 4 |

Total: **7 character designs and 152 directional animation clips**. A clip is one action in one direction, not one frame or necessarily one API request. Four-facing characters may still move continuously in any direction.

The wizard includes a separate channel action to support Soul Drain. The warden's summon action reuses an existing enemy instead of requiring another creature design. Enemy attack and cast clips must include a readable anticipation pose.

Additional portrait assets: wizard, caretaker, and artificer — **3 portraits**.

## B — terrain and architecture

| ID | Kit | Required pieces |
|---|---|---|
| ENV-01 | Courtyard terrain | Intact flagstone, cracked flagstone, earth, dead grass; connected edges/corners for grass-to-earth, earth-to-stone, and corruption-to-stone; wear variations |
| ENV-02 | Academy interior terrain | Intact and damaged floor, ritual floor accents, pit edges/corners, corruption overlays, threshold connections |
| ENV-03 | Shared architecture | Straight walls, inner/outer corners, wall ends, wall faces, archway, doorway, short stairs, pillars, ruined wall variants |

The boss arena and safe hub reuse these kits. Final atlas tile counts depend on the selected connectivity scheme; three kits do not mean three API calls. Check seams, matching heights, navigable widths, and readable foreground occlusion before acceptance.

## C — world props

**32 base prop designs**; the states listed below are additional deliverables.

| IDs | Group | Individual assets |
|---|---|---|
| PROP-01–08 | Ruins and scenery | Small rubble, large rubble, broken column, fallen statue, dead tree, root cluster, torn academy banner, broken desk |
| PROP-09–16 | Academy furnishings | Bookshelf, book pile, lectern, desk, chair, chalkboard, alchemy table, ritual pedestal |
| PROP-17–24 | Interactive objects | Chest, door, academy gate, ward beacon, workbench, stash, herb node, crystal node |
| PROP-25–32 | Placeable decorations | Candle stand, brazier, bench, rug, planter, crate, freestanding banner, stone ornament |

Required extra states:

- Chest, door, and gate: closed and open.
- Ward beacon: dormant and active.
- Workbench: ruined and restored.
- Herb and crystal nodes: available and depleted.
- Workshop: one ruined facade overlay and one restored facade overlay, using shared architecture.
- Ambient loops for candle stand, brazier, and active ward beacon.

Ground footprints and collision boundaries will be defined during integration. The placeable decorations use one orientation each initially.

## D — spell and combat effects

**16 effect families**, each potentially containing multiple frames or layers.

| ID | Effect | Components |
|---|---|---|
| FX-01 | Firebolt | Projectile loop |
| FX-02 | Fire impact | Brief hit burst |
| FX-03 | Burning | Small persistent flame loop |
| FX-04 | Frost Nova | Expanding ring and shards |
| FX-05 | Chilled/frozen status | Ground frost and ice overlay |
| FX-06 | Soul Drain | Channel tether segments and contact effect |
| FX-07 | Blood payment | Small self-damage pulse, distinct from an enemy hit |
| FX-08 | Life return | Inward-moving particles |
| FX-09 | Dodge | Short trail or dust burst |
| FX-10 | Physical hit | Impact spark and debris |
| FX-11 | Enemy magic | Hostile projectile and impact |
| FX-12 | Warden hazard | Ground warning followed by eruption |
| FX-13 | Warden summon | Summoning ring and emergence burst |
| FX-14 | Loot pickup | Small glint/pickup burst |
| FX-15 | Level up | Brief celebratory pulse |
| FX-16 | Ward activation | Restoration/reveal effect |

Projectiles, rings, and tether pieces should be reusable across aim directions where possible. Gameplay warning boundaries should be drawn precisely in-engine later, with decorative art layered over them. Modifier variants initially reuse these effects through count, timing, trajectory, or scale changes.

## E — item, skill, and passive icons

**40 icon designs**. Passive node frames and connection lines are separate UI components.

| IDs | Category | Count | Designs |
|---|---|---:|---|
| ICON-01–04 | Staves | 4 | Apprentice staff, ember staff, rime staff, bloodwood staff |
| ICON-05–08 | Robes | 4 | Student robe, warded robe, ashweave robe, ritual vestment |
| ICON-09–12 | Rings | 4 | Copper focus, quartz seal, frost band, sanguine loop |
| ICON-13–15 | Active spells | 3 | Firebolt, Frost Nova, Soul Drain |
| ICON-16–21 | Spell modifiers | 6 | Split, pierce, wider nova, lingering frost, longer drain, empowered drain |
| ICON-22–33 | Passive symbols | 12 | Fire, frost, lightning, blood, curse, necromancy, spell power, critical chance, cast speed, health, mana, defense |
| ICON-34–35 | Gathered materials | 2 | Withered herb, aether crystal |
| ICON-36–37 | Crafting outputs | 2 | Restorative draught, refined aether focus |
| ICON-38–40 | Quest items | 3 | Academy seal, recovered journal, warden fragment |

The opening 20–25-node passive tree reuses symbols. Icons representing future disciplines do not imply full lightning, curse, or necromancy gameplay in the first playable. Ground loot can initially use three category sprites derived from equipment icons, plus a shared pickup effect.

## F — interface kit

**12 reusable component families**, primarily composed in Godot later; Pixel Lab may provide decorative borders and textures.

1. Health and mana bar frames/fills.
2. Skill slots with cooldown and selected states.
3. Inventory/equipment slots with hover and equipped states.
4. Item tooltip panel with rarity accents.
5. Dialogue panel and portrait frame.
6. Quest tracker and interaction prompt.
7. Passive node frames: ordinary, notable, locked, available, allocated.
8. Passive-tree connections and selection highlight.
9. Crafting panel and recipe-row components.
10. Building-placement valid/invalid footprint indicators.
11. Buttons and general panels with normal, hover, pressed, disabled states.
12. Mouse cursor, aim reticle, boss health bar, and pause/death screen accents.

Use a separately licensed readable font. Labels, numbers, cooldown masks, and precise placement indicators are engine-rendered, not generated lettering. No bespoke logo or elaborate title illustration is required for this milestone.

## G — audio (separate from Pixel Lab)

These remain part of the complete playable asset needs, but are not Pixel Lab image-generation requests.

- 2 music pieces: exploration/hub and boss encounter.
- 2 ambience loops: courtyard wind and interior arcane hum.
- Approximately 24 sound cues: stone/dirt footsteps; three spell casts; fire impact; frost burst; drain loop; drain release; health-payment cue; dodge; player hurt/death; three enemy attack cues; enemy death; boss windup/impact; loot; inventory; UI confirm; gathering; restoration.

Source or commission licensed audio later. Track source and license for every external asset.

## Cost and allowance

Public USD estimates and subscription generations are different units. The earlier $5–10 style-test and $100–250 full-art figures were provisional USD allowances, not a quote for this account's subscription usage.

For illustration only, 152 Pro character-animation directions at the published $0.095 per-direction estimate would be $14.44 for one pass. This excludes base designs, extra frames or requests, effects, tiles, props, icons, editing, and rejected attempts. The posted rate and plan eligibility must be checked for the actual selected route.

Before any generation batch:

1. Choose exact endpoints, dimensions, frame counts, and requested directions.
2. Use documented cost information or a read-only estimate endpoint where available; do not infer that one request equals one subscription generation.
3. Set a batch allowance in the account's actual billing unit. Treat unknown costs as unresolved rather than assuming the USD estimate converts directly.
4. Begin with the style test and measure actual balance changes before scaling production.

The subsequent instruction to generate the listed assets authorizes the visual batch using the existing account allowance. The worker makes no purchases and stops submitting when the remaining allowance is insufficient. Concrete requests are in `art_library/queue.json`; audio is outside Pixel Lab's visual-generation API.

## Completion criteria for each delivered asset

- Stable asset ID, descriptive filename, dimensions, palette/style reference, and production status.
- Transparent edges where needed, consistent scale and perspective, no clipped motion.
- Correct directional facing, stable silhouette and ground-contact point across frames.
- Seamless terrain connections; intact/open/ruined states align spatially.
- Readable spells and warning zones over the chosen backgrounds.
- Animation frame order, duration, loop behavior, and pivot recorded during export.
- Source/generation metadata and license details recorded without API credentials.

## Deferred content

Full six-discipline passive tree, extensive summons, additional biomes, multiple bosses, multiplayer, character appearance customization, equipment-specific wearable animation sets, a large freely buildable town, voice acting, and endgame content.
