"""Build the village art in game/assets from the reviewed Pixel Lab keepers.

Usage: python3 tools/make_village_art.py
- game/assets/village/<name>.png: each map object cropped to its pixels.
  The tavern keeps only its largest connected shape: the generator left a
  vent and a door floating below it.
- game/assets/village/terrain_grass_dirt.png: the tiles-pro 4x4 corner set.
  Tile index = NW*8 + NE*4 + SW*2 + SE with grass 1 and dirt 0, laid out
  left to right, top to bottom (checked by sampling each tile's corners).
- game/assets/npcs/<villager>/rotations and idle: the villagers' 8 stills
  and a 2-frame breathing idle, the same layout the academy NPCs use.
See art_library/README.md for which takes these are and why.
"""
import shutil
import subprocess
import sys
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
ART = ROOT / 'art_library/assets'
OUT = ROOT / 'game/assets/village'
NPCS = ROOT / 'game/assets/npcs'

OBJECTS = {
    'tavern': 'VIL-B-tavern-c', 'barn': 'VIL-B-barn', 'forge': 'VIL-B-forge-b', 'sawmill': 'VIL-B-sawmill-c',
    'cottage': 'VIL-B-cottage-b', 'watchtower': 'VIL-B-watchtower-b',
    'pine_tree': 'VIL-N-pine-tree-b', 'oak_tree': 'VIL-N-oak-tree', 'bush': 'VIL-N-bush', 'boulder': 'VIL-N-boulder',
    'flowers': 'VIL-N-flowers', 'stump': 'VIL-N-stump',
    'well': 'VIL-P-well', 'barrel': 'VIL-P-barrel', 'barrels': 'VIL-P-barrels-b', 'crate': 'VIL-P-crate',
    'crates': 'VIL-P-crates-b', 'lamp_post': 'VIL-P-lamp-post', 'fence_h': 'VIL-P-fence-h', 'fence_v': 'VIL-P-fence-v',
    'log_pile': 'VIL-P-log-pile-b', 'hay_bale': 'VIL-P-hay-bale', 'firewood_cart': 'VIL-P-firewood-cart',
    'produce_crate': 'VIL-P-produce-crate', 'training_dummy': 'VIL-P-training-dummy',
    'archery_target': 'VIL-P-archery-target', 'weapon_rack': 'VIL-P-weapon-rack', 'workbench': 'VIL-P-workbench',
    'carrots': 'VIL-F-carrots-c', 'cow': 'VIL-A-cow-b', 'sheep': 'VIL-A-sheep', 'chicken': 'VIL-A-chicken',
}
# Only this object keeps just its largest connected shape.
LARGEST_ONLY = {'tavern'}
# Transparent pixels inside these floor areas (in cropped pixels) get a grout
# colour: the forge's flagstones have see-through joints that let the grass show.
FLOORS = {'forge': ((0, 56, 111, 133), (52, 56, 60, 255))}
VILLAGERS = ['blacksmith', 'farmer', 'villager', 'militia', 'archer', 'lumberjack']
# Row where the breathing idle's upper body starts to sink, for the 48 px villagers.
IDLE_SPLIT = 26


def largest_shape(image):
    alpha = image.getchannel('A').load()
    width, height = image.size
    seen = set()
    best = set()
    for start in ((x, y) for y in range(height) for x in range(width)):
        if start in seen or alpha[start] == 0:
            continue
        shape, stack = set(), [start]
        seen.add(start)
        while stack:
            x, y = stack.pop()
            shape.add((x, y))
            for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
                if 0 <= nx < width and 0 <= ny < height and (nx, ny) not in seen and alpha[nx, ny]:
                    seen.add((nx, ny))
                    stack.append((nx, ny))
        if len(shape) > len(best):
            best = shape
    kept = Image.new('RGBA', image.size)
    pixels, source = kept.load(), image.load()
    for point in best:
        pixels[point] = source[point]
    return kept


# Fills the transparent pixels inside a box with a solid colour.
def fill_floor(image, box, colour):
    filled = image.copy()
    pixels = filled.load()
    for y in range(box[1], box[3]):
        for x in range(box[0], box[2]):
            if pixels[x, y][3] == 0:
                pixels[x, y] = colour
    return filled


OUT.mkdir(parents=True, exist_ok=True)
for name, asset_id in OBJECTS.items():
    image = Image.open(sorted((ART / asset_id).glob('*.png'))[0]).convert('RGBA')
    if name in LARGEST_ONLY:
        image = largest_shape(image)
    image = image.crop(image.getchannel('A').getbbox())
    if name in FLOORS:
        image = fill_floor(image, *FLOORS[name])
    image.save(OUT / f'{name}.png')
    print(f'{name}: {image.width}x{image.height}')
shutil.copyfile(ART / 'VIL-T-grass-dirt-c/image_tileset_grid_png.png', OUT / 'terrain_grass_dirt.png')

for villager in VILLAGERS:
    rotations = NPCS / villager / 'rotations'
    rotations.mkdir(parents=True, exist_ok=True)
    for still in (ART / f'VIL-C-{villager}').glob('rotation_*.png'):
        shutil.copyfile(still, rotations / still.name.removeprefix('rotation_'))
    subprocess.run([sys.executable, str(ROOT / 'tools/make_breathing_idle.py'), f'npcs/{villager}', str(IDLE_SPLIT)], check=True)
