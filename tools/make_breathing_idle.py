"""Build a subtle 2-frame breathing idle from a character's still rotations.

Usage: python3 tools/make_breathing_idle.py wizard 40
Frame 0 is the still pose; frame 1 sinks every row above the split row by one
pixel, so the head and shoulders settle while the feet stay planted. Frames
are padded to 84x84 like the Pixel Lab animation clips, keeping them aligned.
Replaces game/assets/<name>/idle/<direction>/. Requires Pillow.
"""
import sys
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
PAD = 10

name, split = sys.argv[1], int(sys.argv[2])
character = ROOT / 'game/assets' / name
for still_path in sorted((character / 'rotations').glob('*.png')):
    still = Image.open(still_path).convert('RGBA')
    sunk = still.copy()
    sunk.paste((0, 0, 0, 0), (0, 0, still.width, split + 1))
    sunk.alpha_composite(still.crop((0, 0, still.width, split)), (0, 1))
    target = character / 'idle' / still_path.stem
    target.mkdir(parents=True, exist_ok=True)
    for old in target.glob('frame_*'):
        old.unlink()
    for index, pose in enumerate([still, sunk]):
        frame = Image.new('RGBA', (still.width + PAD * 2, still.height + PAD * 2))
        frame.paste(pose, (PAD, PAD))
        frame.save(target / f'frame_{index:02d}.png')
    print(f'idle/{still_path.stem}: 2 frames')
