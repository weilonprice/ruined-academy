"""Pin every frame of an animation to the character's ground line.

Usage: python3 tools/ground_lock_frames.py wizard move
Generated walk clips drift up and down by a few pixels, which reads as the
character floating. Each frame is shifted vertically so its lowest pixel sits
where the still rotation's feet are, and padded to 84x84 so every clip shares
one canvas. Edits game/assets/<name>/<action>/<direction>/ in place.
"""
import sys
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
CANVAS = 84

name, action = sys.argv[1], sys.argv[2]
character = ROOT / 'game/assets' / name
for folder in sorted((character / action).iterdir()):
    still = Image.open(character / 'rotations' / f'{folder.name}.png').convert('RGBA')
    baseline = still.getchannel('A').getbbox()[3] + (CANVAS - still.height) // 2
    shifts = []
    for path in sorted(folder.glob('frame_*.png')):
        frame = Image.open(path).convert('RGBA')
        pad = (CANVAS - frame.width) // 2
        shift = baseline - (frame.getchannel('A').getbbox()[3] + pad)
        locked = Image.new('RGBA', (CANVAS, CANVAS))
        locked.paste(frame, (pad, pad + shift))
        locked.save(path)
        shifts.append(shift)
    print(f'{action}/{folder.name}: shifted {shifts}')
