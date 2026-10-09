#!/usr/bin/env python3
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import time

from fake_td import FakeTd

SHELL = Path(__file__).resolve().parents[1]

# Failures: Escape ignored by panels without their own handler, j/k stuck or landing on hidden or
# disabled rows, no wrap, Enter not reaching the selected row, sliders deaf to h/l, generic keys
# shadowing a panel's own (calendar h/l), pointer opens stealing a selection, selection surviving a reopen,
# keys landing on the bar (keyboard opens) never reaching the panel, text fields deaf to forwarded keys.
def main():
    with tempfile.TemporaryDirectory(prefix='panel-keys-e2e-') as temporary:
        root = Path(temporary)
        config = root / 'shell'
        config.mkdir()
        for source in SHELL.iterdir():
            if source.suffix in {'.qml', '.js', '.mjs'}:
                shutil.copy2(source, config / source.name)
        shutil.copytree(SHELL.parent / 'generated', root / 'generated')
        (config / 'shell.qml').write_text('''import QtQuick
import Quickshell
import Quickshell.Io
import QtTest
import qs
ShellRoot {
    id: shell
    property var clicks: []
    property real level: 0.5
    FloatingWindow {
        implicitWidth: 800; implicitHeight: 30
        Item { id: bar; anchors.fill: parent }
        PanelKeys { }
        TestCase { id: barKeys; when: false }
    }
    Panel {
        id: probe
        anchorItem: bar
        name: "probe"
        open: Panels.isOpen("probe", Panels.screenName)
        Column {
            width: parent.width
            PanelHeader { text: "Probe" }
            Slider { id: level; value: shell.level; onMoved: v => shell.level = v }
            PanelRow { text: "first"; onClicked: shell.clicks = shell.clicks.concat("first") }
            PanelRow { text: "disabled"; enabled: false; onClicked: shell.clicks = shell.clicks.concat("disabled") }
            PanelRow { text: "hidden"; visible: false; onClicked: shell.clicks = shell.clicks.concat("hidden") }
            PanelRow { text: "last"; onClicked: shell.clicks = shell.clicks.concat("last") }
        }
        TestCase { id: probeKeys; when: false }
    }
    Panel {
        id: typer
        anchorItem: bar
        name: "typer"
        open: Panels.isOpen("typer", Panels.screenName)
        extraKeys: event => typer.type(field, event)
        TextInput { id: field; width: 100 }
    }
    Calendar {
        id: calendar
        anchorItem: bar
        open: Panels.isOpen("calendar", Panels.screenName)
        TestCase { id: calendarKeys; when: false }
    }
    IpcHandler {
        target: "test"
        function state(): string {
            var cursor = probe.cursor
            return JSON.stringify({ panel: Panels.open, clicks: shell.clicks, level: shell.level,
                current: cursor === level ? "slider" : cursor ? cursor.text : "",
                month: calendar.shown.getMonth(), typed: field.text, calendarRow: calendar.cursor ? calendar.cursor.text : "" })
        }
        function open(name: string, pointer: bool): void {
            Panels.close()
            Panels.toggle(name, pointer ? "test" : "")
        }
        function target(panel: string): var {
            return panel === "calendar" ? calendarKeys : panel === "bar" ? barKeys : probeKeys
        }
        function activate(panel: string): void { target(panel).Window.window.requestActivate() }
        function key(panel: string, name: string): void { target(panel).keyClick(Qt["Key_" + name]) }
    }
}
''')
        td = FakeTd(root)
        td.serve([])
        env = {**os.environ, 'QT_QPA_PLATFORM': 'offscreen', 'TD_BIN': str(td.bin),
               'NOTION_CALENDAR_FEED': str(root / 'panel.json')}
        log = root / 'quickshell.log'
        with log.open('w') as output:
            process = subprocess.Popen(['qs', '-p', str(config), '--no-color'], env=env,
                                       stdout=output, stderr=subprocess.STDOUT)
            try:
                def ipc(method, *args):
                    return subprocess.run(['qs', 'ipc', '--pid', str(process.pid), 'call', 'test', method, *args],
                                          env=env, check=True, text=True, capture_output=True).stdout.strip()

                def state():
                    return json.loads(ipc('state'))

                def wait_for(predicate, label):
                    deadline = time.monotonic() + 10
                    last = None
                    while time.monotonic() < deadline:
                        if process.poll() is not None:
                            raise AssertionError(log.read_text())
                        try:
                            last = state()
                            if predicate(last):
                                print('PASS ' + label, flush=True)
                                return last
                        except (subprocess.CalledProcessError, json.JSONDecodeError):
                            pass
                        time.sleep(0.1)
                    raise AssertionError(f'{label}: {last}\n{log.read_text()}')

                def opened(name, pointer=False):
                    ipc('open', name, 'true' if pointer else 'false')
                    wait_for(lambda s: s['panel'] == name, f'{name} opens')
                    ipc('activate', name)
                    time.sleep(0.3)

                def keys(panel, *names):
                    for name in names:
                        ipc('key', panel, name)

                wait_for(lambda s: s['panel'] == '', 'shell loads')

                opened('probe')
                wait_for(lambda s: s['panel'] == 'probe' and s['current'] == 'slider',
                         'keyboard open preselects the first row')
                keys('probe', 'L', 'L')
                wait_for(lambda s: abs(s['level'] - 0.6) < 1e-6, 'l nudges the selected slider up')
                keys('probe', 'H')
                wait_for(lambda s: abs(s['level'] - 0.55) < 1e-6, 'h nudges it down')
                keys('probe', 'J')
                wait_for(lambda s: s['current'] == 'first', 'j moves down')
                keys('probe', 'J')
                wait_for(lambda s: s['current'] == 'last', 'j skips disabled and hidden rows')
                keys('probe', 'Down')
                wait_for(lambda s: s['current'] == 'slider', 'down wraps to the top')
                keys('probe', 'K')
                wait_for(lambda s: s['current'] == 'last', 'k wraps to the bottom')
                keys('probe', 'Return')
                wait_for(lambda s: s['clicks'] == ['last'], 'Enter clicks the selected row')
                keys('probe', 'Escape')
                wait_for(lambda s: s['panel'] == '', 'Escape closes a panel with no handler of its own')

                opened('probe', pointer=True)
                s = state()
                assert s['current'] == '', s
                keys('probe', 'Return')
                assert state()['clicks'] == ['last'], state()
                print('PASS pointer open selects nothing and Enter is inert', flush=True)
                keys('probe', 'K')
                wait_for(lambda s: s['current'] == 'last', 'k from nothing starts at the bottom')

                opened('calendar')
                month = state()['month']
                keys('calendar', 'L')
                wait_for(lambda s: s['month'] == (month + 1) % 12, 'calendar keeps l for next month')
                keys('calendar', 'J')
                wait_for(lambda s: s['calendarRow'] != '', 'calendar falls through to generic j')
                keys('calendar', 'Escape')
                wait_for(lambda s: s['panel'] == '', 'calendar closes on Escape from the base panel')

                ipc('open', 'probe', 'false')
                wait_for(lambda s: s['panel'] == 'probe' and s['current'] == 'slider', 'keyboard open with focus left on the bar')
                ipc('activate', 'bar')
                time.sleep(0.3)
                keys('bar', 'J', 'J')
                wait_for(lambda s: s['current'] == 'last', 'bar forwards j to the open panel')
                keys('bar', 'Escape')
                wait_for(lambda s: s['panel'] == '', 'bar forwards Escape')
                ipc('open', 'typer', 'false')
                wait_for(lambda s: s['panel'] == 'typer', 'typer opens')
                keys('bar', 'A', 'B', 'Backspace', 'C')
                wait_for(lambda s: s['typed'] == 'ac', 'forwarded keys type into a text field')
                keys('bar', 'Escape')
                wait_for(lambda s: s['panel'] == '', 'Escape still closes a typing panel')

                assert not any(term in log.read_text() for term in
                               ['ReferenceError:', 'TypeError:', 'SyntaxError:', 'Failed to load configuration'])
                print('PASS panel keys E2E. Repeat: python3 shell/test/panel-keys-e2e.py', flush=True)
            finally:
                process.terminate()
                try:
                    process.wait(timeout=5)
                except subprocess.TimeoutExpired:
                    process.kill()
                    process.wait()


if __name__ == '__main__':
    main()
