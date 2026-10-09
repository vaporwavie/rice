#!/usr/bin/env python3
import json
import os
from pathlib import Path
import subprocess
import tempfile
import time

HYPR = Path(__file__).resolve().parents[1]

# Failures: rows missing windows or the icon hint, focused window not last, cancel or junk output
# moving focus, the first row not landing on the previously focused window.
def run(*args, env=None):
    return subprocess.run(args, check=True, capture_output=True, text=True, env=env).stdout

def check(name, ok, detail=''):
    if not ok:
        raise SystemExit(f'FAIL {name} {detail}')
    print(f'PASS {name}')

def clients():
    return [c for c in json.loads(run('hyprctl', 'clients', '-j')) if c['mapped'] and not c['hidden']]

def active():
    return json.loads(run('hyprctl', 'activewindow', '-j')).get('address')

def focus(address):
    run('hyprctl', 'dispatch', f'hl.dsp.focus({{ window = "address:{address}" }})')
    time.sleep(0.3)

def main():
    windows = clients()
    if len(windows) < 2:
        raise SystemExit('SKIP needs at least two open windows')
    original = active()
    previous = next(c['address'] for c in windows if c['focusHistoryID'] == 1)
    with tempfile.TemporaryDirectory(prefix='windows-e2e-') as temporary:
        root = Path(temporary)
        picker = root / 'pick'
        picker.write_text(f'#!/usr/bin/bash\ncat > {root}/rows\n'
                          'case $PICK in cancel) exit 1 ;; junk) echo nope ;; *) echo "$PICK" ;; esac\n')
        picker.chmod(0o755)

        def pick(choice):
            run(str(HYPR / 'windows'), env={**os.environ, 'WINDOWS_PICKER': str(picker), 'PICK': choice})
            time.sleep(0.3)
            return [row.split(b'\0') for row in (root / 'rows').read_bytes().splitlines()]

        try:
            rows = pick('cancel')
            check('cancel keeps focus', active() == original)
            check('every window is listed', len(rows) == len(windows), f'{len(rows)} of {len(windows)}')
            check('rows carry an icon hint', all(len(r) == 2 and r[1].startswith(b'icon\x1f') for r in rows))
            focused = next(c for c in windows if c['address'] == original)
            check('focused window is last', rows[-1][0].decode().split('  ')[1] == focused['class'])
            pick('junk')
            check('junk output keeps focus', active() == original)
            pick('0')
            check('first row focuses the previous window', active() == previous)
        finally:
            focus(original)
    check('focus restored', active() == original)
    print('PASS windows picker E2E. Repeat: python3 test/windows-e2e.py')

if __name__ == '__main__':
    main()
