"""Pixel Lab requests for HUD art: flasks, the life/mana bar frame, skill icons.

Usage: python3 tools/build_hud_queue.py   (writes art_library/queue-hud.json)
Then:  echo "$PIXELLAB_API_KEY" | python3 tools/pixellab_batch.py queue-hud.json [ID prefixes...]

Prompts describe only the subject, isolated, like build_regen_queue.py; two
takes of each (-a, -b) so review can pick the better one.
"""
import json
from pathlib import Path

LIB = Path(__file__).resolve().parents[1] / 'art_library'
LOOK = ('Crisp pixel clusters, thin dark outline, upper-left lighting, limited palette, readable at native resolution. '
        'Isolated on a transparent background. No scenery, no buildings, no ground, no people, no text.')
SUBJECTS = [
    ('HUD-life-flask', 'A single small round glass potion flask with a cork stopper and a short neck, '
     'full of glowing deep red healing liquid, side view, centered', 32, 32),
    ('HUD-mana-flask', 'A single small round glass potion flask with a cork stopper and a short neck, '
     'full of glowing deep blue mana liquid, side view, centered', 32, 32),
    ('HUD-bar-frame', 'A long thin horizontal game status bar frame made of weathered dark bronze metal, with small '
     'decorative end caps, the long inner slot is empty and dark, flat front view, fills the width', 128, 32),
    ('HUD-skill-firebolt', 'A single spell icon of a blazing orange fireball flying diagonally up to the right '
     'with a bright yellow core and a flame trail, centered, no border', 32, 32),
    ('HUD-skill-frost-nova', 'A single spell icon of a ring of pale cyan ice shards bursting outward '
     'from a bright white frost core, centered, no border', 32, 32),
    ('HUD-exp-frame', 'A very long and very thin horizontal experience bar frame with a thin polished gold trim border, '
     'a small round amber gem at each end, the long inner slot is empty and dark, flat front view, fills the width', 192, 32),
    ('HUD-skill-dash', 'A single skill icon of a swift dash: a pale blue and white wind swoosh with speed lines '
     'streaking to the right, centered, no border', 32, 32),
]
queue = []
for id, subject, width, height in SUBJECTS:
    for take in 'ab':
        queue.append(dict(id=id + '-' + take, endpoint='/create-image-pixen', payload=dict(
            description=subject + '. ' + LOOK, image_size=dict(width=width, height=height), no_background=True,
            view='side', outline='single color black outline', detail='medium detail')))
(LIB / 'queue-hud.json').write_text(json.dumps(queue, indent=2))
print('Queued request units:', len(queue))
