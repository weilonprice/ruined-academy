"""Copy generated animation frames from art_library into the Godot project.

Usage: python3 tools/copy_character_frames.py CH-01 wizard idle move
Writes game/assets/<name>/<action>/<direction>/frame_NN.png. Run a Godot
import afterwards (./play.sh does this) so the new frames can load.
"""
import shutil
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DIRECTIONS = ['south', 'south-east', 'east', 'north-east', 'north', 'north-west', 'west', 'south-west']

character, name, *actions = sys.argv[1:]
for action in actions:
    for direction in DIRECTIONS:
        source = ROOT / 'art_library/assets' / f'{character}-{action}-{direction}'
        if not source.is_dir():
            continue
        # storage_urls frames are the finished clip; image_images also holds the source pose.
        frames = sorted(source.glob('image_storage_urls_frames_*.png'))
        target = ROOT / 'game/assets' / name / action / direction
        target.mkdir(parents=True, exist_ok=True)
        for old in target.glob('frame_*'):
            old.unlink()
        for index, frame in enumerate(frames):
            shutil.copyfile(frame, target / f'frame_{index:02d}.png')
        print(f'{action}/{direction}: {len(frames)} frames')
