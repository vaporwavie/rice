#!/usr/bin/env python3
import hashlib
import json
from pathlib import Path
import subprocess
import tempfile

HYPR = Path(__file__).resolve().parents[2]
PILLAR = HYPR / 'pillar' / 'pillar.mjs'

# Failures: bake not deterministic per seed, same plant for every seed, wrong texture size, column missing
# from the lock ground, ivy present before it grew, ground not the palette ink, a consumer left on the
# old palette, the live layer absent or reserving space, Hyprland rejecting the config.
def run(*args):
    return subprocess.run(args, check=True, capture_output=True, text=True).stdout

def pixel(image, x, y):
    out = run('magick', str(image), '-format', f'%[fx:int(255*p{{{x},{y}}}.r)],%[fx:int(255*p{{{x},{y}}}.g)],%[fx:int(255*p{{{x},{y}}}.b)]', 'info:')
    return tuple(int(v) for v in out.split(','))

def size(image):
    return tuple(int(v) for v in run('magick', 'identify', '-format', '%w %h', str(image)).split())

def lit(image, crop):
    out = run('magick', str(image), '-crop', crop, '+repage', '-threshold', '12%', '-format', '%[fx:mean]', 'info:')
    return float(out)

def check(name, ok, detail=''):
    if not ok:
        raise SystemExit(f'FAIL {name} {detail}')
    print(f'PASS {name}')

def main():
    palette = json.loads((HYPR / 'generated' / 'shell-colors.json').read_text())
    with tempfile.TemporaryDirectory(prefix='pillar-e2e-') as temporary:
        root = Path(temporary)
        a, b, c = root / 'a.png', root / 'b.png', root / 'c.png'
        run('node', str(PILLAR), 'bake', '--rows', '702', '--seed', '7', '--out', str(a))
        run('node', str(PILLAR), 'bake', '--rows', '702', '--seed', '7', '--out', str(b))
        out = json.loads(run('node', str(PILLAR), 'bake', '--rows', '702', '--seed', '8', '--out', str(c)))
        digest = lambda p: hashlib.sha256(p.read_bytes()).hexdigest()
        check('bake is deterministic per seed', digest(a) == digest(b))
        check('each seed grows its own plant', digest(a) != digest(c))
        check('data texture is three texels per column pixel', size(a) == (396, 702), str(size(a)))
        check('plant finishes growing within twenty minutes', 60 < out['end'] < 1200, str(out['end']))

        dark = root / 'dark.json'
        dark.write_text(json.dumps({'mode': 'dark', 'bg': '#000000', 'fg': '#e8e8e5'}))
        seedling, grown = root / 'seedling.json', root / 'grown.json'
        seedling.write_text(json.dumps({'seed': 7, 'planted': 0}))
        grown.write_text(json.dumps({'seed': 7, 'planted': 1}))
        young, old, bare = root / 'young.png', root / 'old.png', root / 'bare.png'
        run('node', str(PILLAR), 'render', '--palette', str(dark), '--state', str(seedling), '--y', '54', '--out', str(young))
        run('node', str(PILLAR), 'render', '--palette', str(dark), '--state', str(grown), '--y', '54', '--out', str(old))
        run('node', str(PILLAR), 'render', '--palette', str(dark), '--no-pillar', '--out', str(bare))
        check('lock ground is 4K', size(old) == (3840, 2160), str(size(old)))
        check('ground is the palette ink', max(pixel(bare, 3700, 2100)) <= 2, str(pixel(bare, 3700, 2100)))
        check('top glow lifts the ground', sum(pixel(bare, 1920, 4)) > sum(pixel(bare, 1920, 2100)))
        check('column sits on the left edge under the bar', lit(old, '336x2000+0+100') > 0.02 and lit(bare, '336x2000+0+100') == 0)
        check('a seedling carries no ivy yet', lit(young, '336x2000+0+100') < lit(old, '336x2000+0+100'))

    gen = HYPR / 'generated'
    bg = palette['bg'].lstrip('#')
    check('Hyprland ground follows the palette', f'bg = "{bg}"' in (gen / 'colors.lua').read_text())
    check('launcher follows the palette', f'background={bg}' in (gen / 'fuzzel.ini').read_text())
    check('notifications follow the palette', palette['lineStrong'] in (gen / 'dunstrc').read_text())
    check('lock screen follows the palette', f'rgb({bg})' in (gen / 'hyprlock.conf').read_text())
    check('wallpaper rendered', (gen / 'wallpaper.png').exists())

    layers = json.loads(run('hyprctl', 'layers', '-j'))
    pillar = [l for mon in layers.values() for level in mon['levels'].values() for l in level if l['namespace'] == 'altura-pillar']
    check('live pillar layer is mapped', len(pillar) > 0)
    check('live pillar reserves no space', pillar and pillar[0]['x'] == 0 and pillar[0]['w'] == 224, str(pillar[:1]))
    check('Hyprland accepts the config', run('hyprctl', 'configerrors').strip() == '')
    print('PASS pillar E2E: bake, lock ground, palette consumers, live layer. Repeat: python3 pillar/test/pillar-e2e.py')

if __name__ == '__main__':
    main()
