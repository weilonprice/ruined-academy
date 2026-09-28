"""Build the HUD art in game/assets/ui/ from reviewed Pixel Lab images.

Usage: python3 tools/make_hud_art.py
- bar_frame.png: the bronze bar frame cropped to its edges; the HUD
  stretches it as a nine-patch around the life and mana fills.
- life_flask.png / mana_flask.png: one generated flask, cropped; the mana
  flask is the same flask with its red liquid shifted to blue, so the pair
  matches. LIQUID_TOP is the first liquid row in the cropped image.
- skill_firebolt.png / skill_frost_nova.png / skill_dash.png / skill_wind_slash.png /
  skill_wind_wave.png: 32x32 skill bar icons.
- exp_frame.png: the left one of the two bars the generator drew side by
  side, stretched as a nine-patch around the experience fill.
"""
import colorsys
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
ART = ROOT / 'art_library/assets'
OUT = ROOT / 'game/assets/ui'
# Liquid starts at this row of the uncropped flask; the cork above it has reddish pixels too.
LIQUID_ROW = 11


def generated(asset_id):
    return Image.open(ART / asset_id / 'image_image.png').convert('RGBA')


def cropped(image):
    return image.crop(image.getchannel('A').getbbox())


# Shifts the red liquid below LIQUID_ROW to a new hue.
def recolour_liquid(image, hue):
    result = image.copy()
    pixels = result.load()
    for y in range(LIQUID_ROW, image.height):
        for x in range(image.width):
            r, g, b, a = pixels[x, y]
            h, s, v = colorsys.rgb_to_hsv(r / 255, g / 255, b / 255)
            if a and s > 0.3 and (h < 0.08 or h > 0.9):
                r2, g2, b2 = colorsys.hsv_to_rgb(hue / 360, s, v)
                pixels[x, y] = (round(r2 * 255), round(g2 * 255), round(b2 * 255), a)
    return result


OUT.mkdir(parents=True, exist_ok=True)
flask = generated('HUD-life-flask-b')
top = flask.getchannel('A').getbbox()[1]
outputs = {
    'bar_frame': cropped(generated('HUD-bar-frame-a')),
    'life_flask': cropped(flask),
    'mana_flask': cropped(recolour_liquid(flask, 222)),
    'skill_firebolt': generated('HUD-skill-firebolt-b'),
    'skill_frost_nova': generated('HUD-skill-frost-nova-a'),
    'exp_frame': generated('HUD-exp-frame-a').crop((3, 7, 84, 25)),
    'skill_dash': generated('HUD-skill-dash-b'),
    'skill_wind_slash': generated('HUD-skill-wind-slash-b'),
    'skill_wind_wave': generated('HUD-skill-wind-wave-a'),
}
for name, image in outputs.items():
    image.save(OUT / f'{name}.png')
    print(f'{name}: {image.size[0]}x{image.size[1]}')
print('flask LIQUID_TOP =', LIQUID_ROW - top)
