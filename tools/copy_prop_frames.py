"""Copy a generated prop animation into the game, keeping only its top animated.

Usage: python3 tools/copy_prop_frames.py PROP-25-ambient candle 17
Generated ambient clips redraw the whole prop, so solid parts shimmer. Rows
from the given one down are pinned to the first frame; only the rows above
(a flame, a glow) change. Writes game/assets/props/<name>/frame_NN.png.
"""
import sys
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]

source_id, name, pin_from = sys.argv[1], sys.argv[2], int(sys.argv[3])
sources = sorted((ROOT / 'art_library/assets' / source_id).glob('image_images_*.png'))
target = ROOT / 'game/assets/props' / name
target.mkdir(parents=True, exist_ok=True)
for old in target.glob('frame_*'):
    old.unlink()
base = Image.open(sources[0]).convert('RGBA')
solid = base.crop((0, pin_from, base.width, base.height))
for index, path in enumerate(sources):
    frame = Image.open(path).convert('RGBA')
    frame.paste((0, 0, 0, 0), (0, pin_from, frame.width, frame.height))
    frame.alpha_composite(solid, (0, pin_from))
    frame.save(target / f'frame_{index:02d}.png')
print(f'props/{name}: {len(sources)} frames, rows {pin_from}+ pinned')
