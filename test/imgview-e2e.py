#!/usr/bin/env python3
import json
from pathlib import Path
import subprocess
import tempfile
import time

HYPR = Path(__file__).resolve().parents[1]

# Failures: window never maps, maps tiled, image not drawn, footer missing the folder index,
# next key not stepping to the sibling file, imgview not the default for png and jpeg.
def run(*args):
    return subprocess.run(args, check=True, capture_output=True, text=True).stdout

def check(name, ok, detail=''):
    if not ok:
        raise SystemExit(f'FAIL {name} {detail}')
    print(f'PASS {name}')

def viewer():
    for _ in range(30):
        found = [c for c in json.loads(run('hyprctl', 'clients', '-j')) if c['class'] == 'org.quickshell']
        if found:
            return found[0]
        time.sleep(0.2)
    return None

def mean(image, crop):
    return float(run('magick', str(image), '-crop', crop, '+repage', '-format', '%[fx:mean]', 'info:'))

def main():
    with tempfile.TemporaryDirectory(prefix='imgview-e2e-') as temporary:
        root = Path(temporary)
        run('magick', '-size', '800x600', 'xc:#ff0000', str(root / 'a.png'))
        run('magick', '-size', '800x600', 'xc:#0000ff', str(root / 'b.png'))
        process = subprocess.Popen([str(HYPR / 'imgview'), str(root / 'a.png')], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        try:
            window = viewer()
            check('window maps', window is not None)
            check('window floats', window['floating'])
            time.sleep(1)
            shot = root / 'shot.png'
            geometry = f"{window['at'][0]},{window['at'][1]} {window['size'][0]}x{window['size'][1]}"
            run('grim', '-g', geometry, str(shot))
            w, h = window['size']
            center = f'{w // 4}x{h // 4}+{w * 3 // 8}+{h * 3 // 8}'
            red = run('magick', str(shot), '-crop', center, '+repage', '-format', '%[fx:mean.r] %[fx:mean.b]', 'info:').split()
            check('image is drawn', float(red[0]) > 0.8 and float(red[1]) < 0.2, str(red))
            run('hyprctl', 'dispatch', f'hl.dsp.focus({{ window = "address:{window["address"]}" }})')
            time.sleep(0.3)
            run('hyprctl', 'dispatch', 'hl.dsp.send_shortcut({ mods = "", key = "Right", window = "class:^org\\\\.quickshell$" })')
            for _ in range(15):
                title = viewer()['title']
                if title.endswith('b.png'):
                    break
                time.sleep(0.2)
            check('right steps to the next file', title.endswith('b.png'), title)
        finally:
            process.terminate()
    for mime in ('image/png', 'image/jpeg'):
        check(f'default for {mime}', run('xdg-mime', 'query', 'default', mime).strip() == 'imgview.desktop')

main()
