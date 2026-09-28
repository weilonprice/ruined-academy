"""Copy the reviewed spell and combat effect frames into the Godot project.

Usage: python3 tools/copy_effect_frames.py
Writes game/assets/effects/<name>/frame_NN.png. Each entry names the
art_library clip and the frames kept after review: several generated clips
go wrong at the end (the fire impact turns into a campfire, the nova ring
collapses), so only the good opening frames are used and the game fades
them out. Run a Godot import afterwards (./play.sh does this).
"""
import shutil
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ART = ROOT / 'art_library/assets'
OUT = ROOT / 'game/assets/effects'

# name: (clip folder, first frame, frames kept). Frame 0 is the reviewed still.
CLIPS = {
    'firebolt': ('FXR-firebolt-animation', 0, 4),
    'fire_impact': ('FXR-fire-impact-animation', 0, 4),
    'hit_spark': ('FXR-hit-spark-animation', 0, 4),
    'chill': ('FXR-chill-animation', 0, 5),
    'frost_nova': ('FXR-frost-nova-animation', 0, 3),
    'ember_bolt': ('FXR-ember-bolt-b-animation', 0, 4),
    'ember_impact': ('FXR-ember-impact-b-animation', 0, 2),
    'level_up': ('FXR-level-up-c-animation', 0, 6),
    'wind_slash': ('FXM-wind-slash-b-animation', 0, 5),
}

for name, (clip, first, count) in CLIPS.items():
    frames = sorted((ART / clip).glob('image_images_*.png'))[first:first + count]
    assert len(frames) == count, f'{clip}: expected {count} frames'
    target = OUT / name
    target.mkdir(parents=True, exist_ok=True)
    for old in target.glob('frame_*.png'):
        old.unlink()
    for index, frame in enumerate(frames):
        shutil.copyfile(frame, target / f'frame_{index:02d}.png')
    print(f'{name}: {count} frames from {clip}')
