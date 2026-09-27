"""Build the 32x32 item icons in game/assets/icons/, one per base type.

Usage: python3 tools/make_item_icons.py
Uses the generated Pixel Lab icons that came out right, recolours some for
sibling bases, and draws simple placeholder icons for the rest. Every icon
is a plain PNG named after the base's "icon" key, so real art can replace
any of them later without code changes.
"""
import colorsys
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
ART = ROOT / 'art_library/assets'
OUT = ROOT / 'game/assets/icons'
SIZE = 32
OUTLINE = (20, 16, 24, 255)

# Generated icons that match their base.
GENERATED = {
    'apprentice_staff': 'ICON-04',
    'ember_staff': 'ICON-02',
    'student_robe': 'ICON-05',
    'warded_robe': 'ICON-08',
    'ashweave_robe': 'ICON-07',
    'copper_ring': 'ICON-09',
    'sapphire_ring': 'ICON-11',
}
# Recoloured siblings: (source icon, hue in degrees, saturation factor).
RECOLOURED = {
    'rime_staff': ('ember_staff', 195, 0.7),
    'ruby_ring': ('sapphire_ring', 355, 1.1),
    'topaz_ring': ('sapphire_ring', 45, 1.0),
}


def generated(icon_id):
    return Image.open(next((ART / icon_id).glob('*.png'))).convert('RGBA')


# Shifts every saturated pixel to a new hue; greys and dark outlines stay put.
def recolour(image, hue, saturation_factor):
    result = image.copy()
    pixels = result.load()
    for y in range(image.height):
        for x in range(image.width):
            r, g, b, a = pixels[x, y]
            h, s, v = colorsys.rgb_to_hsv(r / 255, g / 255, b / 255)
            if a and s > 0.25:
                r2, g2, b2 = colorsys.hsv_to_rgb(hue / 360, min(1.0, s * saturation_factor), v)
                pixels[x, y] = (round(r2 * 255), round(g2 * 255), round(b2 * 255), a)
    return result


def shade(color, factor):
    return tuple(max(0, min(255, round(c * factor))) for c in color[:3]) + (255,)


# Colours a drawn mask: base colour, a light top-left edge, a dark lower half, and an outline.
def finish(mask, color):
    image = Image.new('RGBA', (SIZE, SIZE))
    pixels = image.load()
    solid = mask.load()
    filled = lambda x, y: 0 <= x < SIZE and 0 <= y < SIZE and solid[x, y] > 0
    for y in range(SIZE):
        for x in range(SIZE):
            if not filled(x, y):
                continue
            if not all(filled(x + dx, y + dy) for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))):
                pixels[x, y] = OUTLINE
            elif not filled(x - 1, y - 1) or not filled(x - 2, y - 1):
                pixels[x, y] = shade(color, 1.35)
            elif solid[x, y] == 2:
                pixels[x, y] = shade(color, 0.55)
            elif y > SIZE * 0.6:
                pixels[x, y] = shade(color, 0.8)
            else:
                pixels[x, y] = color
    return image


def canvas():
    mask = Image.new('L', (SIZE, SIZE), 0)
    return mask, ImageDraw.Draw(mask)


# Mask value 1 is the item; 2 marks recessed detail drawn darker.
def hood(color):
    mask, draw = canvas()
    draw.polygon([(16, 3), (25, 10), (28, 27), (21, 29), (11, 29), (4, 27), (7, 10)], fill=1)
    draw.ellipse((11, 12, 21, 26), fill=2)
    return finish(mask, color)


def helm(color):
    mask, draw = canvas()
    draw.ellipse((6, 4, 26, 24), fill=1)
    draw.rectangle((6, 14, 26, 27), fill=1)
    draw.rectangle((10, 15, 22, 17), fill=2)
    draw.rectangle((15, 18, 17, 25), fill=2)
    return finish(mask, color)


def gloves(color):
    mask, draw = canvas()
    for left in (3, 17):
        draw.rectangle((left, 12, left + 10, 27), fill=1)
        for finger in range(4):
            draw.rectangle((left + finger * 3, 6 + (finger % 2), left + finger * 3 + 1, 12), fill=1)
        draw.rectangle((left, 22, left + 10, 23), fill=2)
    return finish(mask, color)


def boots(color):
    mask, draw = canvas()
    for left in (3, 17):
        draw.rectangle((left, 5, left + 7, 24), fill=1)
        draw.rectangle((left, 20, left + 12, 27), fill=1)
        draw.rectangle((left, 9, left + 7, 10), fill=2)
    return finish(mask, color)


def belt(color, buckle):
    mask, draw = canvas()
    draw.rectangle((1, 12, 30, 20), fill=1)
    draw.rectangle((1, 15, 30, 16), fill=2)
    image = finish(mask, color)
    knot, knot_draw = canvas()
    knot_draw.ellipse((11, 9, 21, 23), fill=1)
    knot_draw.rectangle((14, 13, 18, 19), fill=2)
    image.alpha_composite(finish(knot, buckle))
    return image


def amulet(chain, stone):
    image = Image.new('RGBA', (SIZE, SIZE))
    draw = ImageDraw.Draw(image)
    draw.line((6, 3, 16, 17), fill=shade(chain, 1.0), width=1)
    draw.line((26, 3, 16, 17), fill=shade(chain, 1.0), width=1)
    mask, mask_draw = canvas()
    mask_draw.ellipse((10, 14, 22, 28), fill=1)
    mask_draw.ellipse((14, 18, 18, 23), fill=2)
    image.alpha_composite(finish(mask, stone))
    return image


def focus(orb, stand):
    image = Image.new('RGBA', (SIZE, SIZE))
    base, base_draw = canvas()
    base_draw.polygon([(9, 29), (23, 29), (19, 21), (13, 21)], fill=1)
    image.alpha_composite(finish(base, stand))
    sphere, sphere_draw = canvas()
    sphere_draw.ellipse((7, 3, 25, 21), fill=1)
    sphere_draw.ellipse((13, 9, 17, 13), fill=2)
    image.alpha_composite(finish(sphere, orb))
    return image


DRAWN = {
    'scholars_hood': lambda: hood((60, 82, 122)),
    'warden_helm': lambda: helm((156, 110, 56)),
    'cloth_wraps': lambda: gloves((178, 158, 116)),
    'bronze_gauntlets': lambda: gloves((164, 112, 52)),
    'worn_sandals': lambda: boots((122, 84, 56)),
    'bronze_greaves': lambda: boots((164, 112, 52)),
    'rope_belt': lambda: belt((168, 142, 96), (120, 96, 60)),
    'scholars_sash': lambda: belt((58, 120, 118), (200, 170, 90)),
    'copper_amulet': lambda: amulet((190, 130, 80), (184, 110, 60)),
    'quartz_amulet': lambda: amulet((190, 190, 200), (190, 160, 230)),
    'copper_focus': lambda: focus((196, 128, 70), (96, 72, 56)),
    'quartz_focus': lambda: focus((150, 214, 230), (96, 96, 120)),
}

OUT.mkdir(parents=True, exist_ok=True)
made = {}
for name, icon_id in GENERATED.items():
    made[name] = generated(icon_id)
for name, (source, hue, saturation) in RECOLOURED.items():
    made[name] = recolour(made[source], hue, saturation)
for name, draw_icon in DRAWN.items():
    made[name] = draw_icon()
for name, image in sorted(made.items()):
    image.save(OUT / f'{name}.png')
print(f'{len(made)} icons written to {OUT.relative_to(ROOT)}')
