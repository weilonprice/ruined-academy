"""Copy generated animation frames from art_library into the Godot project.

Usage: python3 tools/copy_character_frames.py CH-01 wizard idle move
       python3 tools/copy_character_frames.py CH-01 wizard cast2:cast --frames 3,4,5,6 --directions north west
Writes game/assets/<name>/<action>/<direction>/frame_NN.png. An action
written source:target copies the art_library clip <character>-<source>-<dir>
into <target>. --frames keeps only those clip frames (0 is the first
generated frame); --directions limits which facings are replaced. Run a
Godot import afterwards (./play.sh does this) so the new frames can load.
"""
import argparse
import shutil
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DIRECTIONS = ['south', 'south-east', 'east', 'north-east', 'north', 'north-west', 'west', 'south-west']

parser = argparse.ArgumentParser()
parser.add_argument('character')
parser.add_argument('name')
parser.add_argument('actions', nargs='+')
parser.add_argument('--frames', type=lambda text: [int(index) for index in text.split(',')])
parser.add_argument('--directions', nargs='+', default=DIRECTIONS)
args = parser.parse_args()

for action in args.actions:
    source_action, _, target_action = action.partition(':')
    target_action = target_action or source_action
    for direction in args.directions:
        source = ROOT / 'art_library/assets' / f'{args.character}-{source_action}-{direction}'
        if not source.is_dir():
            continue
        # storage_urls frames are the finished clip; image_images also holds the source pose.
        frames = sorted(source.glob('image_storage_urls_frames_*.png'))
        if not frames:
            # When the storage host is unreachable, the inline images are the
            # same frames after the source pose in image_images_000.
            frames = sorted(source.glob('image_images_*.png'))[1:]
        if args.frames:
            frames = [frames[index] for index in args.frames]
        target = ROOT / 'game/assets' / args.name / target_action / direction
        target.mkdir(parents=True, exist_ok=True)
        for old in target.glob('frame_*.png'):
            old.unlink()
        for index, frame in enumerate(frames):
            shutil.copyfile(frame, target / f'frame_{index:02d}.png')
        print(f'{target_action}/{direction}: {len(frames)} frames from {source.name}')
