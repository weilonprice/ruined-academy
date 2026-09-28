"""Build the 32x32 item icons in game/assets/icons/ and the passive tree icons
in game/assets/passives/.

Usage: python3 tools/make_item_icons.py
Every icon is a reviewed Pixel Lab image from art_library/assets. Item icons
are named after the base's "icon" key and passive icons after the node id,
so any of them can be replaced later without code changes; a passive without
a PNG falls back to a symbol drawn by the tree.
"""
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
ART = ROOT / 'art_library/assets'
OUT = ROOT / 'game/assets/icons'
PASSIVE_OUT = ROOT / 'game/assets/passives'

# Item base icon -> generated image. ICON-* are from the first pass; ICONR-* are
# the second pass, where the first was a building, a creature, or a recolour.
ITEMS = {
    'apprentice_staff': 'ICONR-apprentice_staff-b',
    'ember_staff': 'ICON-02',
    'rime_staff': 'ICONR-rime_staff',
    'student_robe': 'ICON-05',
    'warded_robe': 'ICONR-warded_robe',
    'ashweave_robe': 'ICON-07',
    'copper_ring': 'ICON-09',
    'sapphire_ring': 'ICON-11',
    'ruby_ring': 'ICONR-ruby_ring',
    'topaz_ring': 'ICONR-topaz_ring',
    'scholars_hood': 'ICONR-scholars_hood',
    'warden_helm': 'ICONR-warden_helm',
    'cloth_wraps': 'ICONR-cloth_wraps',
    'bronze_gauntlets': 'ICONR-bronze_gauntlets',
    'worn_sandals': 'ICONR-worn_sandals',
    'bronze_greaves': 'ICONR-bronze_greaves-b',
    'rope_belt': 'ICONR-rope_belt',
    'scholars_sash': 'ICONR-scholars_sash',
    'copper_amulet': 'ICONR-copper_amulet',
    'quartz_amulet': 'ICONR-quartz_amulet',
    'copper_focus': 'ICONR-copper_focus',
    'quartz_focus': 'ICONR-quartz_focus',
    'short_sword': 'ICONR-short_sword-a',
    'windblade': 'ICONR-windblade-a',
}
PASSIVES = {
    'vitality': 'PASSR-vitality',
    'deep_reserves': 'PASSR-deep_reserves',
    'spell_mastery': 'PASSR-spell_mastery',
    'frostweaving': 'PASSR-frostweaving',
    'keen_mind': 'PASSR-keen_mind-b',
}


def generated(icon_id):
    return Image.open(sorted((ART / icon_id).glob('*.png'))[0]).convert('RGBA')


for folder, icons in ((OUT, ITEMS), (PASSIVE_OUT, PASSIVES)):
    folder.mkdir(parents=True, exist_ok=True)
    for name, icon_id in sorted(icons.items()):
        generated(icon_id).save(folder / f'{name}.png')
    print(f'{len(icons)} icons written to {folder.relative_to(ROOT)}')
