"""Pixel Lab requests for the second pass over broken art; no network calls.

Usage: python3 tools/build_regen_queue.py   (writes art_library/queue-regen.json)
Then:  echo "$PIXELLAB_API_KEY" | python3 tools/pixellab_batch.py queue-regen.json [ID prefixes...]

The first pass prefixed every prompt with "...a ruined magical academy RPG...",
and for abstract subjects (effects, icons) the generator drew the academy.
Here effects and icons describe only the subject, isolated, with no setting.
"""
import json
from pathlib import Path

LIB = Path(__file__).resolve().parents[1] / 'art_library'
# Style notes without any setting, so the subject is all there is to draw.
LOOK = ('Crisp pixel clusters, thin dark outline, upper-left lighting, limited palette, readable at native resolution. '
        'Isolated on a transparent background. No scenery, no buildings, no ground, no people, no text.')
queue = []


def add(id, endpoint, payload, **kw):
    queue.append(dict(id=id, endpoint=endpoint, payload=payload, **kw))


def still(id, subject, size, view='side', seed=None):
    payload = dict(description=subject + '. ' + LOOK, image_size=dict(width=size, height=size), no_background=True,
                   view=view, outline='single color black outline', detail='medium detail')
    if seed is not None:
        payload['seed'] = seed
    add(id, '/create-image-pixen', payload)


def anim(id, parent, action, frames):
    add(id, '/animate-with-text-v3', dict(action=action, frame_count=frames, no_background=True),
        first_frame=parent, depends=[parent])


# Spell and combat effects: a still, then a clip animated from it.
FX = [
    ('FXR-firebolt', 'A single small blazing orange fireball spell projectile flying to the right, bright yellow white core at the front, '
     'short flickering flame tail trailing to the left, side view', 32, 'side',
     'The flame tail flickers in a seamless loop; the fireball stays in place, pointing right.', 4),
    ('FXR-fire-impact', 'A single small burst of orange and yellow fire sparks exploding outward from the centre, magic spell impact', 48, 'side',
     'The fire burst expands outward and dissipates into sparks, fading to nothing.', 6),
    ('FXR-frost-nova', 'A thin flat ring of pale cyan ice shards and frost lying on the ground, seen from above, hollow empty centre, '
     'white and cyan ice crystals pointing outward around the ring', 128, 'high top-down',
     'The ice ring expands outward, shards glinting, then shatters and fades away.', 6),
    ('FXR-chill', 'A few small pale blue snowflakes and frost crystals floating in a loose cluster, frost status effect, empty centre', 32, 'side',
     'The snowflakes drift slowly and twinkle in a seamless loop.', 4),
    ('FXR-ember-bolt', 'A single small hostile dark ember red fire bolt projectile flying to the right, glowing crimson coal core, '
     'smoky dark red flame tail trailing to the left, side view', 32, 'side',
     'The dark red flame tail flickers in a seamless loop; the bolt stays in place, pointing right.', 4),
    ('FXR-ember-impact', 'A single small burst of dark ember red and crimson fire and smoke exploding outward from the centre', 48, 'side',
     'The ember burst expands outward and dissipates into smoke, fading to nothing.', 6),
    ('FXR-hit-spark', 'A single small pale gold and white impact spark, a sharp four pointed starburst with a few flying sparks', 32, 'side',
     'The spark flashes bright then shrinks and fades to nothing.', 4),
    ('FXR-level-up', 'A glowing golden ring of light on the ground seen at an angle, with pale gold and cyan light motes and sparkles rising '
     'upward from it, celebratory magic burst, hollow centre', 96, 'low top-down',
     'The golden ring expands while light motes rise upward, then everything fades out.', 8),
]
# Second takes after review: the first ember bolt was a dart, the ember impact
# a rubble pile, and the level-up sat on a floor tile.
FX += [
    ('FXR-ember-bolt-b', 'A single small dark red fireball spell projectile flying to the right, glowing crimson and ember orange flames, '
     'dark red flame tail trailing to the left, side view', 32, 'side',
     'The flame tail flickers in a seamless loop; the fireball stays in place, pointing right.', 4),
    ('FXR-ember-impact-b', 'A single small burst of dark red and crimson fire sparks exploding outward from the centre, floating in the air, '
     'no ground, no rocks, no smoke pile', 48, 'side',
     'The burst expands outward and dissipates into sparks, fading to nothing.', 6),
    ('FXR-level-up-b', 'A burst of rising golden light: a column of pale gold and cyan sparkles and light motes floating upward in the air, '
     'no ground, no platform, no tile', 64, 'side',
     'The golden sparkles rise upward and spread, then fade out.', 8),
    # Third take: the second level-up still had smoke clouds and a ground line.
    ('FXR-level-up-c', 'A small radiant burst of golden and pale cyan sparkles and four pointed stars, floating in empty space, '
     'no ground, no smoke, no clouds, no platform', 48, 'side',
     'The sparkles burst outward and upward, twinkle, then fade out.', 8),
]
for id, subject, size, view, action, frames in FX:
    still(id, subject, size, view)
    anim(id + '-animation', id, action, frames)

# Item icons, 32x32, keyed by the base's icon name.
ICON = 'A single inventory icon of '
ITEMS = {
    'scholars_hood': 'an empty midnight blue cloth scholar\'s hood with teal lining, a soft cowl, no face inside',
    'warden_helm': 'a bronze warden\'s helmet with a narrow visor slit and a short crest, dark fantasy armour',
    'cloth_wraps': 'a pair of beige cloth hand wraps, bandage gloves wound around empty hands shapes',
    'bronze_gauntlets': 'a pair of bronze plated armoured gauntlets',
    'worn_sandals': 'a pair of worn brown leather sandals with straps',
    'bronze_greaves': 'a pair of bronze armoured boots',
    'rope_belt': 'a coiled tan hemp rope belt tied in a simple knot',
    'scholars_sash': 'a folded teal cloth sash belt with a small gold clasp',
    'copper_amulet': 'a round copper medallion amulet hanging on a thin chain',
    'quartz_amulet': 'a pale violet quartz crystal pendant hanging on a thin silver chain',
    'copper_focus': 'a small copper orb, a wizard\'s magical focus resting on a little dark wooden stand',
    'quartz_focus': 'a clear pale cyan quartz crystal orb, a wizard\'s magical focus resting in a small silver cradle',
    'apprentice_staff': 'a plain wooden wizard staff with a small pale cyan crystal at the top, drawn diagonally from bottom left to top right',
    'rime_staff': 'a frosted pale blue wooden wizard staff topped with a jagged white and cyan ice crystal, drawn diagonally from bottom left to top right',
    'warded_robe': 'an empty dark blue wizard robe garment with bronze trim and faint glowing protective sigils, shown flat with no wearer',
    'ruby_ring': 'a gold ring set with a large faceted red ruby gemstone',
    'topaz_ring': 'a gold ring set with a large faceted amber yellow topaz gemstone',
}
for name, subject in ITEMS.items():
    still('ICONR-' + name, ICON + subject + ', centered, no border', 32)
# Second takes after review.
RETRY_ITEMS = {
    'bronze_greaves': 'a pair of shiny bronze metal plate armour boots',
    'apprentice_staff': 'a wooden wizard staff with a curled hooked top holding a small glowing pale cyan crystal, drawn diagonally',
}
for name, subject in RETRY_ITEMS.items():
    still('ICONR-' + name + '-b', ICON + subject + ', centered, no border', 32)

# Passive tree symbols.
PASSIVE_ICONS = {
    'vitality': 'a glowing red heart, symbol of life',
    'deep_reserves': 'a glowing deep blue mana droplet, symbol of magical energy',
    'spell_mastery': 'a bright orange arcane starburst of spell power with a glowing core',
    'frostweaving': 'a pale cyan ice snowflake crystal',
    'keen_mind': 'a glowing golden eye with a sharp pupil and small rays, symbol of focus and precision',
}
for name, subject in PASSIVE_ICONS.items():
    still('PASSR-' + name, 'A single skill icon of ' + subject + ', centered, no border, no frame', 32)
# Second take: the first Keen Mind was a dark wheel.
still('PASSR-keen_mind-b', 'A single skill icon of one open almond shaped eye with a glowing golden amber iris and small golden light rays, '
      'centered, no ring, no wheel, no border, no frame', 32)

# Wizard (CH-01) clips, animated on the existing character.
ACTIONS = {
    'cast': ('Cast a spell while facing the same direction the whole time: raise the staff in one hand and thrust the free hand forward, '
             'then return to the starting pose. Hold the staff firmly in every frame. No spell effects.', 6),
    'dodge': ('Quick evasive dash: drop into a deep low crouch leaning strongly forward with the robe flaring behind, '
              'then spring back up to standing. Big clear pose change, staff held in hand, no effects.', 6),
    'move': ('Walking cycle with long strides: legs swing wide forward and back with clear foot lifts, '
             'arms swing, robe sways, staff held consistently, stays in place, no effects.', 8),
}
for action, (description, frames) in ACTIONS.items():
    for direction in ['south', 'south-east', 'east', 'north-east', 'north', 'north-west', 'west', 'south-west']:
        add('CH-01-' + action + '2-' + direction, '/animate-character',
            dict(animation_name=action + '2', action_description=description, mode='v3', frame_count=frames,
                 keep_first_frame=False, directions=[direction]), character='CH-01')

(LIB / 'queue-regen.json').write_text(json.dumps(queue, indent=2))
print('Queued request units:', len(queue))
