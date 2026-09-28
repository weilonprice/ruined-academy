"""Build the ruined village's art in game/assets/ruins from the reviewed keepers.

Usage: python3 tools/make_ruins_art.py
Each map object is cropped to its pixels. The ground reuses the village's
terrain tileset, tinted by the ruins scene. See art_library/README.md for
which takes these are.
"""
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
ART = ROOT / 'art_library/assets'
OUT = ROOT / 'game/assets/ruins'

# The collapsed barn is the only ruined building that came out straight top-down;
# the cottage and stone house were isometric in every take, so the map uses the
# barn twice and marks the lost houses with rubble. Small props are pixen -c takes.
OBJECTS = {
    'collapsed_barn': 'RUIN-B-collapsed-barn', 'broken_well': 'RUIN-P-broken-well', 'rubble': 'RUIN-P-rubble-c',
    'broken_fence': 'RUIN-P-broken-fence', 'broken_cart': 'RUIN-P-broken-cart',
    'broken_barrels': 'RUIN-P-broken-barrels-c', 'graves': 'RUIN-P-graves-c', 'dead_tree': 'RUIN-N-dead-tree',
    'charred_stump': 'RUIN-N-charred-stump-c', 'weeds': 'RUIN-N-weeds-c',
}

OUT.mkdir(parents=True, exist_ok=True)
for name, asset_id in OBJECTS.items():
    image = Image.open(sorted((ART / asset_id).glob('*.png'))[0]).convert('RGBA')
    image = image.crop(image.getchannel('A').getbbox())
    image.save(OUT / f'{name}.png')
    print(f'{name}: {image.width}x{image.height}')
