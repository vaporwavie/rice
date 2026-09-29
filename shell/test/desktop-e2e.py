#!/usr/bin/env python3
import datetime
import json
import os
from pathlib import Path
import signal
import subprocess
import sys
import tempfile
import time

from fake_td import FakeTd, task

SHELL = Path(__file__).resolve().parents[1]
UNIT = 'quickshell.service'
bar = None

# Failures: cards missing on the desktop or lingering on other workspaces, processes stuck on "sampling",
# top left running after leaving, cards disagreeing with the bar's own data, launches landing on the desktop,
# the user's workspace not restored, QML errors in the bar, the real Todoist account read, the live bar left stopped.
def ipc(*args):
    return subprocess.run(['qs', 'ipc', '--pid', str(bar.pid), 'call', *args], capture_output=True, text=True, check=True).stdout.strip()


def systemctl(*args):
    return subprocess.run(['systemctl', '--user', *args], capture_output=True, text=True)


def live_env():
    pid = systemctl('show', '-p', 'MainPID', '--value', UNIT).stdout.strip()
    try:
        raw = Path(f'/proc/{pid}/environ').read_bytes()
    except (OSError, ValueError):
        return dict(os.environ)
    return dict(entry.split('=', 1) for entry in raw.decode().split('\0') if '=' in entry)


def focus(workspace):
    subprocess.run(['hyprctl', 'dispatch', f'hl.dsp.focus({{ workspace = {json.dumps(workspace)} }})'], capture_output=True, check=True)


def active():
    return json.loads(subprocess.run(['hyprctl', 'activeworkspace', '-j'], capture_output=True, text=True, check=True).stdout)


def wait(check, timeout=6):
    end = time.time() + timeout
    while time.time() < end:
        value = check()
        if value:
            return value
        time.sleep(0.2)
    return check()


def top_running():
    return subprocess.run(['pgrep', '-u', str(os.getuid()), '-f', '^top -b -n 2'], capture_output=True).returncode == 0


def expect(name, ok, detail=''):
    print(('PASS ' if ok else 'FAIL ') + name + (f': {detail}' if detail and not ok else ''))
    return ok


def main():
    global bar
    home = active()
    if home['name'] == 'desktop':
        sys.exit('Run from a normal workspace')
    signal.signal(signal.SIGTERM, lambda *_: sys.exit(1))
    was_live = systemctl('is-active', '--quiet', UNIT).returncode == 0
    env = live_env()
    today = datetime.date.today()
    tasks = [task('overdue', 'Overdue fixture', (today - datetime.timedelta(days=1)).isoformat()),
             task('today', 'Today fixture', today.isoformat()),
             task('later', 'Later fixture', (today + datetime.timedelta(days=2)).isoformat(), recurring=True)]
    results = []
    temporary = tempfile.TemporaryDirectory(prefix='desktop-e2e-')
    root = Path(temporary.name)
    td = FakeTd(root)
    td.serve(tasks)
    log = root / 'quickshell.log'
    try:
        # The live bar would read the real account when the desktop shows, so it pauses for a copy on a fake td.
        if was_live:
            systemctl('stop', UNIT)
        with log.open('w') as output:
            bar = subprocess.Popen(['qs', '-p', str(SHELL), '--no-color'], env={**env, 'TD_BIN': str(td.bin)},
                                   stdout=output, stderr=subprocess.STDOUT)

        def ready():
            try:
                return json.loads(ipc('todoist', 'state'))['loaded']
            except (subprocess.CalledProcessError, json.JSONDecodeError):
                return False
        results.append(expect('test bar loads the fake td', wait(ready, 15), log.read_text()[-2000:]))
        reads = len(td.calls())

        idle = json.loads(ipc('desktop', 'state'))
        results.append(expect('hidden on a normal workspace', not idle['shown'] and idle['visible'] == [], idle))

        focus('name:desktop')
        shown = wait(lambda: (s := json.loads(ipc('desktop', 'state')))['visible'] and s['top'] > 0 and s)
        results.append(expect('cards visible on the desktop', bool(shown) and shown['shown'], shown))
        results.append(expect('processes sampled', bool(shown) and shown['top'] > 0 and shown['watching'], shown))

        todoist = json.loads(ipc('todoist', 'state'))
        events = ipc('events', 'state').split()
        shown = json.loads(ipc('desktop', 'state'))
        results.append(expect('Todoist card matches Todoist', shown['todoist'] == todoist['count'] == len(tasks), (shown['todoist'], todoist['count'])))
        results.append(expect('showing the desktop refreshes through the fake td', wait(lambda: len(td.calls()) > reads), td.calls()))
        results.append(expect('Notion card matches the feed', shown['events'] == int(events[1]), (shown['events'], events)))

        ipc('desktop', 'leave')
        back = wait(lambda: active()['id'] == home['id'])
        results.append(expect('launch actions leave the desktop', bool(back), active()['name']))

        left = wait(lambda: not (s := json.loads(ipc('desktop', 'state')))['shown'] and s['visible'] == [] and s)
        results.append(expect('cards hidden after leaving', bool(left) and not left['watching'], left))
        time.sleep(1.5)
        results.append(expect('top stops after leaving', wait(lambda: not top_running(), 3)))
    finally:
        if active()['id'] != home['id']:
            focus(home['id'])
        if bar is not None:
            bar.terminate()
            try:
                bar.wait(timeout=5)
            except subprocess.TimeoutExpired:
                bar.kill()
                bar.wait()
        if was_live:
            systemctl('start', UNIT)
    results.append(expect('workspace restored', active()['id'] == home['id']))
    results.append(expect('live bar restored', not was_live or systemctl('is-active', '--quiet', UNIT).returncode == 0))
    results.append(expect('only the fake td was called, and only to read', td.calls() and not td.completes(), td.calls()))

    errors = [l for l in log.read_text().splitlines() if any(k in l for k in ('TypeError', 'ReferenceError', 'Binding loop', 'ERROR'))]
    results.append(expect('no QML errors in the bar', not errors, errors))
    temporary.cleanup()
    if all(results):
        print('PASS desktop E2E: desktop cards on a fake td, top sampling, workspace and live bar restore. Repeat: python3 shell/test/desktop-e2e.py')
    sys.exit(0 if all(results) else 1)


main()
