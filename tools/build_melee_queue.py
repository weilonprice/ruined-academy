"""Pixel Lab requests for the wizard's melee attack: a magic wind slash.

Usage: python3 tools/build_melee_queue.py   (writes art_library/queue-melee.json)
Then:  echo "$PIXELLAB_API_KEY" | python3 tools/pixellab_batch.py queue-melee.json [ID prefixes...]

- CH-01-slash-<direction>: the wizard (CH-01) swings a sword; walking and
  idle keep the staff, so the sword appears only in this clip.
- FXM-wind-slash: the crescent of wind the slash throws, still and animation.
- HUD-skill-wind-slash-a/-b: the skill bar icon, two takes.
"""
import base64
import json
from pathlib import Path

LIB = Path(__file__).resolve().parents[1] / 'art_library'
LOOK = ('Crisp pixel clusters, thin dark outline, upper-left lighting, limited palette, readable at native resolution. '
        'Isolated on a transparent background. No scenery, no buildings, no ground, no people, no text.')
SLASH = ('Draw a short glowing steel sword in the free hand and swing it in one fast wide horizontal slash toward the '
         'facing direction, staff kept in the other hand, then return to the starting stance. Keep facing the same '
         'direction the whole time. No spell effects.')
queue = []
for direction in ['south', 'south-east', 'east', 'north-east', 'north', 'north-west', 'west', 'south-west']:
    queue.append(dict(id='CH-01-slash-' + direction, endpoint='/animate-character', character='CH-01', payload=dict(
        animation_name='slash', action_description=SLASH, mode='v3', frame_count=6, keep_first_frame=False,
        directions=[direction])))


def still(id, subject, size):
    queue.append(dict(id=id, endpoint='/create-image-pixen', payload=dict(
        description=subject + '. ' + LOOK, image_size=dict(width=size, height=size), no_background=True,
        view='side', outline='single color black outline', detail='medium detail')))


still('FXM-wind-slash', 'A single crescent shaped arc of pale teal and white magic wind, a curved blade of swirling air '
      'with thin speed streaks, curving around the right side with an empty centre on the left', 64)
queue.append(dict(id='FXM-wind-slash-animation', endpoint='/animate-with-text-v3', first_frame='FXM-wind-slash',
                  depends=['FXM-wind-slash'], payload=dict(
                      action='The wind crescent sweeps forward in a fast arc, flares bright, then thins out and fades away.',
                      frame_count=6, no_background=True)))
for take in 'ab':
    still('HUD-skill-wind-slash-' + take, 'A single skill icon of a steel sword slashing through a pale teal crescent '
          'of magic wind, centered, no border', 32)

# Second takes. The character animations above drifted in colour (the hood went
# grey-green) and mostly swung the staff. animate-with-text-v3 starts from the
# wizard's still and can pull every frame back to its colours (drift_threshold 0).
ROTATIONS = Path(__file__).resolve().parents[1] / 'game/assets/wizard/rotations'
SLASH_B = ('The hooded wizard pulls a short straight steel sword into his free hand and slashes it once in a fast wide '
           'horizontal arc in front of him, the wooden staff stays in his other hand, then he returns to the starting '
           'pose. Same facing throughout, no spell effects, no flash.')
for direction in ['south', 'south-east', 'east', 'north-east', 'north', 'north-west', 'west', 'south-west']:
    still_png = base64.b64encode((ROTATIONS / (direction + '.png')).read_bytes()).decode()
    queue.append(dict(id='CH-01-slash-b-' + direction, endpoint='/animate-with-text-v3', payload=dict(
        first_frame=dict(type='base64', base64=still_png), action=SLASH_B, frame_count=6, no_background=True,
        drift_threshold=0)))
# The first effect filled its middle with a dark see-through disc.
still('FXM-wind-slash-b', 'A single thin curved crescent line of pale teal and white wind, like a sword swoosh trail, '
      'the arc bends around the right side, nothing inside the curve', 64)
queue.append(dict(id='FXM-wind-slash-b-animation', endpoint='/animate-with-text-v3', first_frame='FXM-wind-slash-b',
                  depends=['FXM-wind-slash-b'], payload=dict(
                      action='The wind swoosh sweeps forward in a fast arc, flares bright, then thins out and fades away.',
                      frame_count=6, no_background=True)))

# The melee kit: sword item icons for the off-hand swords, and the Wind Wave skill icon.
for take in 'ab':
    still('ICONR-short_sword-' + take, 'A single inventory icon of a plain short steel sword with a simple brass crossguard '
          'and a leather grip, drawn diagonally from bottom left to top right, centered, no border', 32)
    still('ICONR-windblade-' + take, 'A single inventory icon of an elegant slender sword with a pale teal glowing blade '
          'and wisps of wind curling around it, drawn diagonally from bottom left to top right, centered, no border', 32)
    still('HUD-skill-wind-wave-' + take, 'A single skill icon of a wide pale teal crescent wave of wind flying forward to '
          'the right with speed lines behind it, centered, no border', 32)

(LIB / 'queue-melee.json').write_text(json.dumps(queue, indent=2))
print('Queued request units:', len(queue))
