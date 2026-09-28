"""Pixel Lab requests for the ruined village north of the village.

Usage: python3 tools/build_ruins_queue.py   (writes art_library/queue-ruins.json)
Then:  echo "$PIXELLAB_API_KEY" | python3 tools/pixellab_batch.py queue-ruins.json [ID prefixes...]

Map objects, prompted the way the village's keepers were: a flat straight-on
view with nothing underneath, which kept them off little isometric islands.
The ground reuses the village tileset, tinted in the game.
"""
import base64
import io
import json
from pathlib import Path

from PIL import Image

LIB = Path(__file__).resolve().parents[1] / 'art_library'
LOOK = ('Classic 16-bit top-down RPG map sprite, orthographic straight-on view, not isometric, not diagonal. '
        'Abandoned ruined village palette: faded wood, soot-blackened timber, grey weathered stone, muted dull greens, '
        'soft shading, crisp pixel clusters, thin dark outline, upper-left lighting. Isolated on a transparent background, '
        'no ground tile, no base, no extra objects, no text.')
FLAT = ('Flat straight-on view like a classic 16-bit SNES RPG town map: the front face is square to the frame and the top '
        'is seen from above, no isometric angle, no diamond shape. It stands alone with nothing under it: no grass, '
        'no ground, no floor, no platform.')
ABOVE = 'Seen straight from directly above, square footprint, walls square to the frame, no isometric angle.'
queue = []


def map_object(id, subject, width, height=None, view='low top-down', framing=FLAT):
    queue.append(dict(id=id, endpoint='/map-objects', payload=dict(
        description=framing + ' ' + subject + '. ' + LOOK, image_size=dict(width=width, height=height or width),
        view=view, outline='single color outline', shading='medium shading', detail='medium detail')))


BUILDINGS = [
    ('RUIN-B-burned-cottage', 'A burned-out cottage ruin with the roof gone: soot-blackened stone walls broken to '
     'different heights, charred roof beams fallen inside, an empty doorway', 128),
    ('RUIN-B-collapsed-barn', 'A collapsed wooden barn ruin: a broken timber frame, half the plank walls fallen, '
     'splintered beams and old rotten hay inside', 160),
    ('RUIN-B-stone-house', 'A ruined grey stone house with crumbled walls and no roof, heaps of rubble inside, '
     'one standing chimney', 128),
]
for id, subject, size in BUILDINGS:
    map_object(id, subject, size, view='high top-down', framing=ABOVE)
PROPS = [
    ('RUIN-P-broken-well', 'A broken round stone well with fallen stones and a snapped wooden crossbeam', 48),
    ('RUIN-P-rubble', 'A pile of broken grey stone rubble and brick fragments', 48),
    ('RUIN-P-broken-fence', 'A short horizontal section of broken wooden rail fence with a snapped rail and a leaning post', 64, 32),
    ('RUIN-P-broken-cart', 'An overturned broken wooden cart with a snapped wheel lying beside it', 64),
    ('RUIN-P-broken-barrels', 'A few smashed wooden barrels and broken crate planks', 48),
    ('RUIN-P-graves', 'Three weathered old grave markers, a small stone headstone and two leaning wooden crosses', 48),
    ('RUIN-N-dead-tree', 'A single bare dead tree with twisted grey branches and no leaves', 64),
    ('RUIN-N-charred-stump', 'A single charred black tree stump', 32),
    ('RUIN-N-weeds', 'A small clump of dry brown dead weeds and withered grass', 32),
]
for id, subject, width, *height in PROPS:
    map_object(id, subject, width, height[0] if height else None)

# Second takes. The palette line said "abandoned ruined village", and the generator
# drew little houses for the barrels, rubble and weeds, and isometric dioramas for
# two buildings. The retry palette names no setting at all.
LOOK_B = ('Classic 16-bit top-down RPG map sprite, orthographic straight-on view, not isometric, not diagonal. '
          'Palette of faded wood, soot-black char, grey weathered stone and dull brown-greens, soft shading, crisp pixel '
          'clusters, thin dark outline, upper-left lighting. Isolated on a transparent background, no ground tile, no '
          'base, no extra objects, no buildings, no text.')
RETRIES = [
    ('RUIN-B-burned-cottage-b', 'A burned-out cottage with the roof gone, showing soot-blackened stone walls broken to '
     'different heights and charred beams fallen on the floor inside, an empty doorway in the front wall', 128, 'high top-down', ABOVE),
    ('RUIN-B-stone-house-b', 'A roofless ruined grey stone house with crumbled walls and heaps of rubble on the floor inside, '
     'one standing chimney at the back wall', 128, 'high top-down', ABOVE),
    ('RUIN-P-broken-barrels-b', 'Two smashed wooden barrels with burst staves and loose iron hoops, and a few broken planks', 48, 'low top-down', FLAT),
    ('RUIN-P-rubble-b', 'A low heap of broken grey stones and brick fragments', 48, 'low top-down', FLAT),
    ('RUIN-P-graves-b', 'Three weathered grave markers standing in a row: a small rounded stone headstone and two '
     'leaning wooden crosses', 48, 'low top-down', FLAT),
    ('RUIN-N-charred-stump-b', 'A single burnt tree stump with blackened charred wood and a jagged broken top', 32, 'low top-down', FLAT),
    ('RUIN-N-weeds-b', 'A clump of dry brown dead weeds and withered grass stalks', 32, 'low top-down', FLAT),
]
for id, subject, size, view, framing in RETRIES:
    queue.append(dict(id=id, endpoint='/map-objects', payload=dict(
        description=framing + ' ' + subject + '. ' + LOOK_B, image_size=dict(width=size, height=size),
        view=view, outline='single color outline', shading='medium shading', detail='medium detail')))

# Third takes. Map objects kept turning small props into cottages and grass islands,
# so props go through pixen, which draws one isolated object. The buildings copy the
# wording of the collapsed barn, the one building that came out straight top-down.
PIXEN_LOOK = ('Crisp pixel clusters, thin dark outline, upper-left lighting, muted palette of grey stone, faded wood '
              'and soot black. Isolated on a transparent background. No ground, no grass, no scenery, no buildings, no text.')
for id, subject, size in [
        ('RUIN-P-rubble-c', 'A single low heap of broken grey stones and brick fragments, seen from slightly above', 48),
        ('RUIN-N-weeds-c', 'A single small clump of dry brown dead weeds and withered grass stalks, seen from slightly above', 32),
        ('RUIN-N-charred-stump-c', 'A single burnt black tree stump with a jagged broken top, seen from slightly above', 32),
        ('RUIN-P-broken-barrels-c', 'Two smashed wooden barrels with burst staves and loose iron hoops, seen from slightly above', 48),
        ('RUIN-P-graves-c', 'Three weathered grave markers in a row, a small rounded stone headstone between two leaning '
         'wooden crosses, seen from slightly above', 48)]:
    queue.append(dict(id=id, endpoint='/create-image-pixen', payload=dict(
        description=subject + '. ' + PIXEN_LOOK, image_size=dict(width=size, height=size), no_background=True,
        view='high top-down', outline='single color black outline', detail='medium detail')))
for take in 'cd':
    map_object('RUIN-B-burned-cottage-' + take, 'A collapsed stone cottage ruin: broken stone walls, the roof fallen in, '
               'charred black beams and ash inside', 128, view='high top-down', framing=ABOVE)
    map_object('RUIN-B-stone-house-' + take, 'A collapsed grey stone house ruin: crumbled walls, no roof, heaps of rubble '
               'inside, one standing chimney', 128, view='high top-down', framing=ABOVE)

# Fourth takes for the two buildings: every text-only take came out isometric, so
# these start from the collapsed barn (the straight top-down one) as the init image.
barn = Image.open(sorted((LIB / 'assets/RUIN-B-collapsed-barn').glob('*.png'))[0]).convert('RGBA')
barn = barn.crop(barn.getchannel('A').getbbox()).resize((128, 128), Image.NEAREST)
buffer = io.BytesIO()
barn.save(buffer, 'PNG')
BARN_INIT = dict(type='base64', base64=base64.b64encode(buffer.getvalue()).decode())
for id, subject in [
        ('RUIN-B-burned-cottage-e', 'A burned-out stone cottage ruin: soot-blackened broken stone walls, no roof, charred '
         'beams and ash on the floor inside, an empty doorway at the bottom'),
        ('RUIN-B-stone-house-e', 'A ruined grey stone house: crumbled stone walls, no roof, heaps of grey rubble on the floor '
         'inside, one standing chimney')]:
    map_object(id, subject, 128, view='high top-down', framing=ABOVE)
    queue[-1]['payload'].update(init_image=BARN_INIT, init_image_strength=300)

(LIB / 'queue-ruins.json').write_text(json.dumps(queue, indent=2))
print('Queued request units:', len(queue))
