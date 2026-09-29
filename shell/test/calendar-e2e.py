#!/usr/bin/env python3
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import time

from fake_td import FakeTd, task

SHELL = Path(__file__).resolve().parents[1]

# Failures: redirected panels, hidden Notion access, mixed feeds, lost alerts, stale or broken feeds.
def main():
    with tempfile.TemporaryDirectory(prefix='calendar-e2e-') as temporary:
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
    Window {
        width: 1600; height: 30
        visible: true
        Item {
            id: bar
            anchors.fill: parent
            function togglePanel(name) { Panels.toggle(name, "") }
            Row {
                Clock { bar: bar }
                TodoistButton { bar: bar }
                NextEvent { bar: bar }
            }
        }
    }
    TestCase { id: input; when: false }
    Calendar { id: calendar; anchorItem: bar }
    EventsPanel { id: events; anchorItem: bar }
    IpcHandler {
        target: "test"
        function find(item: var, type: string): var {
            if (String(item).startsWith(type + "_QMLTYPE") || String(item).startsWith(type + "(")) return item
            for (var child of item.children || []) {
                var match = find(child, type)
                if (match) return match
            }
            return null
        }
        function state(): string {
            var button = find(bar, "NextEvent")
            return JSON.stringify({ panel: Panels.open,
                calendarOpen: Panels.isOpen(calendar.name, Panels.screenName),
                eventsOpen: Panels.isOpen(events.name, Panels.screenName),
                notionVisible: button !== null && button.visible && button.width > 0,
                notionLive: NotionCalendar.live, notionEvents: NotionCalendar.events,
                notionNext: NotionCalendar.next, alert: NotionCalendar.alert,
                todoistLoaded: Todoist.loaded,
                todoistItems: Todoist.items, todoistError: Todoist.error })
        }
        function toggle(name: string): void { Panels.toggle(name, "") }
        function close(): void { Panels.close() }
        function click(type: string): void {
            var button = find(bar, type)
            input.mouseClick(button, button.width / 2, button.height / 2, Qt.LeftButton)
        }
        function refresh(): void { Todoist.refresh() }
        function dismiss(): void { NotionCalendar.dismiss() }
    }
}
''')
        feed = root / 'panel.json'
        td = FakeTd(root)

        def write_feed(events, age=0):
            pending = feed.with_suffix('.next')
            pending.write_text(json.dumps({'updatedAt': int(time.time() * 1000) - age, 'events': events}))
            pending.replace(feed)

        write_feed([])
        env = {**os.environ, 'QT_QPA_PLATFORM': 'offscreen',
               'TD_BIN': str(td.bin), 'NOTION_CALENDAR_FEED': str(feed)}
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
                    deadline = time.monotonic() + 20
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

                wait_for(lambda s: s['todoistLoaded'] and s['notionLive'] and s['notionVisible'],
                         'both calendars load and Notion stays available with no events')
                for name in ['events', 'calendar', 'events']:
                    ipc('toggle', name)
                    s = state()
                    assert s['panel'] == name, s
                    assert s['eventsOpen'] == (name == 'events'), s
                    assert s['calendarOpen'] == (name == 'calendar'), s
                ipc('toggle', 'events')
                assert state()['panel'] == ''
                print('PASS independent panel routing, switching, and closing', flush=True)
                for button, panel in [('Clock', 'calendar'), ('NextEvent', 'events'), ('TodoistButton', 'calendar')]:
                    ipc('click', button)
                    assert state()['panel'] == panel, state()
                ipc('close')
                print('PASS actual bar buttons open the correct panels', flush=True)
                td.serve([task('onlyTodoist', 'Only in Todoist', time.strftime('%Y-%m-%dT%H:%M:%S', time.localtime(time.time() + 7200)))])
                ipc('refresh')
                meeting = {'title': 'Only in Notion', 'startsAt': int(time.time() * 1000) + 50000,
                           'join': 'Join meeting'}
                write_feed([meeting])
                s = wait_for(lambda s: len(s['todoistItems']) == 1 and len(s['notionEvents']) == 1
                             and s['alert'] is not None,
                             'independent live feeds and Notion meeting alert')
                assert s['todoistItems'][0]['title'] == 'Only in Todoist'
                assert s['notionEvents'][0]['title'] == 'Only in Notion'
                ipc('dismiss')
                assert state()['alert'] is None
                print('PASS Notion alert dismissal', flush=True)
                write_feed([meeting], age=120000)
                wait_for(lambda s: not s['notionLive'] and not s['notionEvents']
                         and s['notionVisible'] and len(s['todoistItems']) == 1,
                         'stale Notion feed keeps its launcher and Todoist available')
                write_feed([])
                wait_for(lambda s: s['notionLive'] and not s['notionEvents'], 'empty Notion feed recovers')
                feed.write_text('{broken')
                wait_for(lambda s: not s['notionLive'] and s['notionVisible'] and not s['todoistError'],
                         'broken Notion feed does not break Todoist')
                write_feed([{'title': 'Recovered', 'startsAt': int(time.time() * 1000) + 3600000}])
                wait_for(lambda s: s['notionLive'] and len(s['notionEvents']) == 1
                         and s['notionEvents'][0]['title'] == 'Recovered', 'Notion feed recovers')
                assert not td.completes() and td.calls(), td.calls()
                assert not any(term in log.read_text() for term in
                               ['ReferenceError:', 'TypeError:', 'SyntaxError:', 'Failed to load configuration'])
                print('PASS calendar coexistence E2E. Repeat: python3 shell/test/calendar-e2e.py', flush=True)
            finally:
                process.terminate()
                try:
                    process.wait(timeout=5)
                except subprocess.TimeoutExpired:
                    process.kill()
                    process.wait()


if __name__ == '__main__':
    main()
