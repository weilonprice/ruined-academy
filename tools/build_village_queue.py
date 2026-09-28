"""Pixel Lab requests for a village environment modelled on a reference screenshot
(top-down medieval village: forge, tavern, barn, sawmill, farm plots, training yard).

Usage: python3 tools/build_village_queue.py   (writes art_library/queue-village.json)
Then:  echo "$PIXELLAB_API_KEY" | python3 tools/pixellab_batch.py queue-village.json [ID prefixes...]

Prompts describe only the subject, isolated, in a warm village palette rather
than the ruined academy's dark one. Map pieces use /map-objects (straight-on
high top-down, 1 generation); villagers are 4-direction characters so they can
be animated later.
"""
import json
from pathlib import Path

LIB = Path(__file__).resolve().parents[1] / 'art_library'
# The first test came back isometric and as little dioramas on ground tiles; the
# reference is a flat, straight-on top-down map, so say so and forbid a base.
LOOK = ('Classic 16-bit top-down RPG map sprite, orthographic straight-on view, not isometric, not diagonal. '
        'Warm medieval village palette of muted greens, browns and wood tones, soft shading, crisp pixel clusters, '
        'thin dark outline, upper-left lighting. Isolated on a transparent background, no ground tile, no base, '
        'no extra objects, no text.')
queue = []


def still(id, subject, width, height=None, view='low top-down'):
    queue.append(dict(id=id, endpoint='/create-image-pixen', payload=dict(
        description=subject + '. ' + LOOK, image_size=dict(width=width, height=height or width), no_background=True,
        view=view, outline='single color black outline', detail='medium detail')))


# Map objects: Pixel Lab's endpoint for pieces placed on a map; its high top-down
# view is straight on, where pixen drew the cut-away buildings isometric.
def map_object(id, subject, width, height=None):
    queue.append(dict(id=id, endpoint='/map-objects', payload=dict(
        description=subject + '. ' + LOOK, image_size=dict(width=width, height=height or width), view='high top-down',
        outline='single color outline', shading='medium shading', detail='medium detail')))


# A top-down Wang terrain-transition set (16 corner tiles) from tiles-pro.
def terrain(id, description):
    queue.append(dict(id=id, endpoint='/create-tiles-pro', payload=dict(
        description=description, tile_type='square_topdown', tile_size=32, tile_view='top-down',
        tile_feature='tileset', outline_mode='segmentation')))


def tileset(id, lower, upper, transition):
    queue.append(dict(id=id, endpoint='/create-tileset', reserve=20, payload=dict(
        lower_description=lower, upper_description=upper, transition_description=transition,
        tile_size=dict(width=32, height=32), transition_size=0, view='high top-down', mode='standard',
        detail='medium detail', shading='medium shading')))


def villager(id, description, size=48):
    queue.append(dict(id=id, endpoint='/create-character-v3', payload=dict(
        name=id, description=description + ', cozy medieval village pixel art, warm colours. Full body standing, centered, '
        'visible feet, transparent background, no scenery.', image_size=dict(width=size, height=size), view='low top-down',
        no_background=True, outline='single color black outline', detail='medium detail')))


# Trials, kept as a record (all reviewed and rejected): pixen drew the cut-away
# tavern isometric twice and the pine as a little diorama, and /create-tileset
# drew the dirt road as bricks, then planks. See art_library/README.md.
tileset('VIL-T-grass-dirt', 'lush bright green meadow grass with tiny flowers', 'worn packed brown dirt road',
        'soft ragged grass edge over dirt')
tileset('VIL-T-grass-dirt-b', 'muted medium green grass texture with subtle darker grass blades, seamless, top-down',
        'smooth packed light brown dirt road texture with a few small pebbles, no bricks, no stone blocks, seamless, top-down',
        'soft ragged grass edge over the dirt')
for id, view in [('VIL-B-tavern', 'high top-down'), ('VIL-B-tavern-b', 'high top-down')]:
    still(id, 'A two storey wooden medieval tavern seen from above with the roof removed so the interior shows: '
          'plank floor, long bar counter with shelves of bottles, round tables and chairs, a staircase; stone lower walls, '
          'a door and two windows on the front wall', 192, view=view)
still('VIL-N-pine-tree', 'A single tall dark green pine fir tree with a brown trunk', 64)
still('VIL-N-pine-tree-b', 'A single tall dark green pine fir tree with a short brown trunk, front view', 64)

# Ground: grass crossed by dirt roads, and tilled farm plots. tiles-pro Wang sets
# (20 generations each) came out clean and seamless where /create-tileset did not.
terrain('VIL-T-grass-dirt-c', 'muted medium green grass to smooth packed light brown dirt road')
terrain('VIL-T-grass-soil', 'muted medium green grass to dark brown tilled farmland soil in neat furrows')

# Buildings. The reference shows workshops with the roof removed so the interior is visible.
BUILDINGS = [
    ('VIL-B-tavern-c', 'A two storey wooden medieval tavern seen from above with the roof removed so the interior shows: '
     'plank floor, long bar counter with shelves of bottles, round tables and chairs, a staircase; stone lower walls, '
     'a door and two windows on the front wall', 192, 'high top-down'),
    ('VIL-B-forge', 'A stone blacksmith forge seen from above with the roof removed: a brick furnace with a glowing fire '
     'and a tall chimney, an anvil, tool racks with hammers and tongs, a quench barrel, stone floor', 160, 'high top-down'),
    ('VIL-B-barn', 'A wooden barn and stable seen from above with the roof removed: stalls full of golden hay bales, '
     'a hay loft, plank walls, a wide open doorway, a small lean-to on one side', 160, 'high top-down'),
    ('VIL-B-cottage', 'A small cozy medieval cottage with a steep red clay tile roof, stone walls, a timber frame, '
     'one wooden door and small windows', 128, 'low top-down'),
    ('VIL-B-sawmill', 'An open timber frame sawmill shed with a pitched wooden shingle roof on posts, a log saw bench '
     'underneath, stacked logs at the sides', 160, 'low top-down'),
    ('VIL-B-watchtower', 'A tall wooden lookout watchtower on four log legs with a ladder, a small railed platform and '
     'a peaked roof with a blue flag', 128, 'low top-down'),
]
for id, subject, size, _view in BUILDINGS:
    map_object(id, subject, size)

# Nature.
NATURE = [
    ('VIL-N-pine-tree-c', 'A single tall dark green pine fir tree with a short brown trunk', 64),
    ('VIL-N-oak-tree', 'A single round leafy green oak tree with a thick brown trunk', 64),
    ('VIL-N-bush', 'A single small round green leafy bush', 32),
    ('VIL-N-mountain', 'A cluster of jagged grey rocky mountain peaks with snow caps, seen from above at an angle', 192),
    ('VIL-N-boulder', 'A single mossy grey boulder rock', 32),
    ('VIL-N-flowers', 'A small clump of white and yellow wildflowers with green leaves', 32),
    ('VIL-N-stump', 'A single tree stump with an axe stuck in it', 32),
]
for id, subject, size in NATURE:
    map_object(id, subject, size)

# Props seen around the village.
PROPS = [
    ('VIL-P-well', 'A round stone water well with a dark opening', 48),
    ('VIL-P-barrel', 'A single wooden barrel with iron bands', 32),
    ('VIL-P-barrels', 'A stack of three wooden barrels', 48),
    ('VIL-P-crate', 'A single wooden supply crate', 32),
    ('VIL-P-crates', 'A small stack of wooden crates', 48),
    ('VIL-P-lamp-post', 'A single wooden street lamp post with a hanging iron lantern glowing warm yellow', 32, 64),
    ('VIL-P-fence-h', 'A straight horizontal section of rustic wooden rail fence with posts', 64, 32),
    ('VIL-P-fence-v', 'A straight vertical section of rustic wooden rail fence with posts, seen from above', 32, 64),
    ('VIL-P-log-pile', 'A neat pile of cut timber logs stacked on their sides', 64),
    ('VIL-P-hay-bale', 'A single square golden hay bale', 32),
    ('VIL-P-firewood-cart', 'A wooden hand cart with two wheels loaded with split firewood', 64),
    ('VIL-P-produce-crate', 'A wooden crate full of potatoes', 32),
    ('VIL-P-training-dummy', 'A straw and wood combat training dummy on a post', 48),
    ('VIL-P-archery-target', 'A round straw archery target with red and white rings on a wooden stand', 32),
    ('VIL-P-weapon-rack', 'A wooden weapon rack holding swords and spears', 48),
    ('VIL-P-workbench', 'A wooden workbench with tools and a vise', 48),
    ('VIL-P-chopping-block', 'A chopping block with split firewood beside it', 32),
]
for id, subject, width, *height in PROPS:
    map_object(id, subject, width, height[0] if height else None)

# Crops and animals.
FARM = [
    ('VIL-F-carrots', 'A small square garden bed of leafy carrot plants in rows on dark soil', 32),
    ('VIL-F-wheat', 'A small square patch of tall golden ripe wheat', 32),
    ('VIL-F-cabbages', 'A small square garden bed of green cabbages on dark soil', 32),
    ('VIL-A-cow', 'A single black and white spotted dairy cow standing, side view', 48),
    ('VIL-A-sheep', 'A single fluffy white sheep standing, side view', 32),
    ('VIL-A-chicken', 'A single small white chicken standing, side view', 32),
]
for id, subject, size in FARM:
    map_object(id, subject, size)

# Villagers and militia seen in the reference.
VILLAGERS = [
    ('VIL-C-blacksmith', 'Burly village blacksmith, adult human with a leather apron, rolled sleeves and a hammer'),
    ('VIL-C-farmer', 'Village farmer, adult human in a straw hat, plain tunic and trousers, holding a hoe'),
    ('VIL-C-villager', 'Village woman, adult human in a simple dress with a white apron and headscarf'),
    ('VIL-C-militia', 'Village militia soldier, adult human in a chainmail shirt and iron helmet with a sword and round shield'),
    ('VIL-C-archer', 'Village archer, adult human in a green hooded tunic holding a longbow'),
    ('VIL-C-lumberjack', 'Village lumberjack, burly adult human in a red plaid shirt carrying an axe'),
]
for id, description in VILLAGERS:
    villager(id, description)
# Second takes at 64 px, the canvas the wizard, the enemies and the academy NPCs
# use: at 48 px the villagers stood a head shorter than everyone else.
for id, description in VILLAGERS:
    villager(id + '-64', description, 64)

# Second takes: short prompts came back as little isometric dioramas on a grass
# tile. Spell out the flat straight-on view and that nothing stands under them.
FLAT = ('Flat straight-on view like a classic 16-bit SNES RPG town map: the front face is square to the frame and the top '
        'is seen from above, no isometric angle, no diamond shape. It stands alone with nothing under it: no grass, '
        'no ground, no floor, no platform.')
RETRIES = {
    'VIL-B-cottage': 'low top-down', 'VIL-B-sawmill': 'low top-down', 'VIL-B-watchtower': 'low top-down',
    'VIL-N-mountain': 'high top-down', 'VIL-P-barrels': 'low top-down', 'VIL-P-crates': 'low top-down',
    'VIL-P-chopping-block': 'low top-down', 'VIL-P-log-pile': 'low top-down', 'VIL-F-carrots': 'high top-down',
    'VIL-F-wheat': 'high top-down',
}
for task in list(queue):
    if task['id'] in RETRIES:
        payload = dict(task['payload'], view=RETRIES[task['id']])
        payload['description'] = payload['description'].replace(LOOK, FLAT + ' ' + LOOK)
        queue.append(dict(task, id=task['id'] + '-b', payload=payload))

# Third takes for what stayed isometric; the tavern and barn worked when described
# as seen straight from directly above with a square footprint.
ABOVE = 'Seen straight from directly above, square footprint, walls square to the frame, no isometric angle.'
THIRD = [
    ('VIL-B-forge-b', 'A square stone blacksmith forge with the roof removed so the interior shows: a brick furnace with '
     'a glowing fire and a chimney against the back wall, an anvil, tool racks with hammers and tongs, a quench barrel, '
     'grey flagstone floor, an open doorway in the front wall', 160, 'high top-down'),
    ('VIL-B-sawmill-c', 'A rectangular open timber sawmill shed: a wooden shingle roof on four posts, a log saw bench '
     'underneath, stacked logs at the sides', 160, 'high top-down'),
    ('VIL-N-mountain-c', 'A cluster of jagged grey rocky mountain peaks with snow caps, the rock face toward the viewer, '
     'no platform, no grass underneath', 192, 'high top-down'),
    ('VIL-F-carrots-c', 'A flat square garden plot of dark tilled soil with three straight rows of leafy carrot tops, no raised box',
     32, 'high top-down'),
    ('VIL-F-wheat-c', 'A flat square patch of tall golden ripe wheat stalks, no raised box, no soil edge', 32, 'high top-down'),
    ('VIL-F-cabbages-b', 'A flat square garden plot of dark tilled soil with rows of round green cabbages, no raised box',
     32, 'high top-down'),
]
for id, subject, size, view in THIRD:
    map_object(id, ABOVE + ' ' + subject, size)
    queue[-1]['payload']['view'] = view
map_object('VIL-A-cow-b', 'A single black and white spotted dairy cow standing, full body, side view', 48)
queue[-1]['payload']['view'] = 'side'

(LIB / 'queue-village.json').write_text(json.dumps(queue, indent=2))
print('Queued request units:', len(queue))
