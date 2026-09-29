#!/usr/bin/env python3
import datetime
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import time

from fake_td import READ, FakeTd, task

SHELL = Path(__file__).resolve().parents[1]
os.environ['TZ'] = 'America/Sao_Paulo'
time.tzset()


def local_ms(moment):
    return int(time.mktime(moment.timetuple()) * 1000)


# Failures: UTC-shifted all-day dates, misplaced overdue items, broken or failed reads, hidden dates,
# unsafe argv, failed or duplicate completion, recurring tasks completed forever, calls reaching the real account.
def main():
    now = datetime.datetime.now().replace(microsecond=0)
    today = now.date()
    day = datetime.timedelta(days=1)
    tomorrow_ten = datetime.datetime.combine(today + day, datetime.time(10))
    fixed_utc = datetime.datetime.combine(today + 2 * day, datetime.time(12), datetime.timezone.utc)
    title = 'Widget "quoted" $(literal) <b>title</b>'
    tasks = [
        task('timedOverdue', title, datetime.datetime.combine(today, datetime.time()).isoformat(), priority=4),
        task('allDayOverdue', 'Yesterday all day', (today - day).isoformat()),
        task('allDayToday', 'Today all day', today.isoformat()),
        task('timedTomorrow', 'Tomorrow at ten', tomorrow_ten.isoformat()),
        task('fixedZone', 'Fixed zone meeting', fixed_utc.strftime('%Y-%m-%dT%H:%M:%SZ'), timezone='Europe/Berlin'),
        task('recurring', 'Weekly recurring', (today + 3 * day).isoformat(), recurring=True),
    ] + [task(f'future{n}', f'Future {n}', (today + n * day).isoformat()) for n in range(4, 10)]

    with tempfile.TemporaryDirectory(prefix='todoist-e2e-') as temporary:
        root = Path(temporary)
        config = root / 'shell'
        config.mkdir()
        for source in SHELL.iterdir():
            if source.suffix in {'.qml', '.js', '.mjs'} and source.name != 'shell.qml':
                shutil.copy2(source, config / source.name)
        shutil.copytree(SHELL.parent / 'generated', root / 'generated')
        (config / 'shell.qml').write_text('''import QtQuick
import Quickshell
import Quickshell.Io
import qs
ShellRoot {
    Item { id: anchor; width: 800; height: 30 }
    Calendar { id: calendar; anchorItem: anchor }
    IpcHandler {
        target: "test"
        function state(): string {
            return JSON.stringify({ loaded: Todoist.loaded, loading: Todoist.loading, error: Todoist.error,
                actionError: Todoist.actionError, busy: Todoist.busy, items: Todoist.items,
                overdue: Todoist.overdue.map(item => item.id), next: Todoist.next,
                groups: calendar.groups, selected: calendar.selected,
                shown: calendar.shown, cells: calendar.cells(), days: Todoist.dayCounts })
        }
        function refresh(): void { Todoist.refresh() }
        function done(id: string): void { Todoist.markDone(id) }
        function select(day: string): void { calendar.selectDate(new Date(day + "T12:00:00")) }
        function shift(months: int): void { calendar.shift(months) }
        function reset(): void { calendar.reset() }
    }
}
''')
        td = FakeTd(root)
        env = {**os.environ, 'QT_QPA_PLATFORM': 'offscreen', 'TD_BIN': str(td.bin)}
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
                    deadline = time.monotonic() + 12
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

                def item(s, id):
                    return next((i for i in s['items'] if i['id'] == id), None)

                wait_for(lambda s: s['loaded'] and not s['loading'] and not s['error'] and not s['items'], 'empty Todoist')
                assert td.calls() and all(call == READ for call in td.calls()), td.calls()
                print('PASS reads go through TD_BIN as `td upcoming 30 --json --all`', flush=True)

                td.serve(tasks)
                ipc('refresh')
                s = wait_for(lambda s: len(s['items']) == len(tasks) and not s['loading'], 'fixture reaches agenda')
                assert item(s, 'timedOverdue')['title'] == title, item(s, 'timedOverdue')
                assert [i['id'] for i in s['items'][:4]] == ['allDayOverdue', 'timedOverdue', 'allDayToday', 'timedTomorrow'], s['items']
                assert sorted(s['overdue']) == ['allDayOverdue', 'timedOverdue'], s['overdue']
                assert s['next']['id'] == 'allDayToday', s['next']
                assert [g['title'] for g in s['groups']] == ['Overdue', 'Today', 'Upcoming'], s['groups']
                assert [i['id'] for i in s['groups'][1]['items']] == ['allDayToday'], s['groups'][1]
                assert len(s['groups'][2]['items']) == len(tasks) - 3, s['groups'][2]
                print('PASS sorting with priority tiebreak, overdue, today, and upcoming groups, literal titles, all future dates', flush=True)

                assert item(s, 'allDayToday')['allDay'] and item(s, 'allDayToday')['at'] == local_ms(datetime.datetime.combine(today, datetime.time()))
                assert s['days'].get(today.isoformat()) == 2 and s['days'].get((today - day).isoformat()) == 1, s['days']
                assert not item(s, 'timedTomorrow')['allDay'] and item(s, 'timedTomorrow')['at'] == local_ms(tomorrow_ten)
                assert item(s, 'fixedZone')['at'] == int(fixed_utc.timestamp() * 1000), item(s, 'fixedZone')
                assert item(s, 'recurring')['recurring'] and not item(s, 'future4')['recurring']
                assert sum(s['days'].values()) == len(tasks), s['days']
                print('PASS all-day dates stay local, floating and fixed-zone times map exactly', flush=True)

                ipc('select', (today + 3 * day).isoformat())
                s = state()
                assert len(s['groups']) == 1 and [i['id'] for i in s['groups'][0]['items']] == ['recurring'], s['groups']
                ipc('select', today.isoformat())
                assert [i['id'] for i in state()['groups'][0]['items']] == ['timedOverdue', 'allDayToday']
                ipc('shift', '1')
                assert state()['selected'] == ''
                ipc('reset')
                assert state()['selected'] == ''
                print('PASS date filtering, month navigation, and reset', flush=True)

                td.serve_raw('{broken')
                ipc('refresh')
                wait_for(lambda s: bool(s['error']) and not s['loading'] and len(s['items']) == len(tasks),
                         'read failure retains last agenda with error')
                td.serve(tasks)
                ipc('refresh')
                wait_for(lambda s: not s['error'] and not s['loading'], 'recovery before a failing td')
                message = 'No API token found. Run td auth login.'
                td.fail_reads(message)
                ipc('refresh')
                wait_for(lambda s: s['error'] == message and not s['loading'] and len(s['items']) == len(tasks),
                         'td JSON error on stderr shows only its message and keeps the agenda')
                td.fail_reads(None)
                td.serve(tasks[:3] + [tasks[5]])
                ipc('refresh')
                wait_for(lambda s: not s['error'] and not s['loading'] and len(s['items']) == 4, 'recovery after a good read')

                td.fail_complete('timedOverdue')
                ipc('done', 'timedOverdue')
                wait_for(lambda s: bool(s['actionError']) and not s['busy'] and not s['loading']
                         and len(s['items']) == 4, 'failed completion is visible')
                td.fail_complete(None)

                sent = len(td.completes())
                ipc('done', 'timedOverdue')
                ipc('done', 'timedOverdue')
                wait_for(lambda s: not s['busy'] and not s['loading'] and not s['actionError'] and len(s['items']) == 3,
                         'completion persists and refreshes')
                assert td.completes()[sent:] == [['task', 'complete', 'id:timedOverdue']], td.completes()
                print('PASS duplicate click sends one complete', flush=True)

                before = item(state(), 'recurring')['at']
                ipc('done', 'recurring')
                s = wait_for(lambda s: not s['busy'] and not s['loading'] and len(s['items']) == 3
                             and item(s, 'recurring') is not None and item(s, 'recurring')['at'] > before, 'recurring completion advances to the next occurrence')
                assert td.completes()[-1] == ['task', 'complete', 'id:recurring'], td.completes()

                td.slow_reads(True)
                ipc('refresh')
                wait_for(lambda s: s['loading'], 'slow read in flight')
                stale = item(state(), 'recurring')['at']
                ipc('done', 'recurring')
                deadline = time.monotonic() + 8
                while True:
                    s = state()
                    current = item(s, 'recurring')
                    assert current is None or current['at'] != stale, 'completed occurrence came back from a stale read'
                    if current is not None and not s['loading'] and not s['busy']:
                        break
                    assert time.monotonic() < deadline, s
                    time.sleep(0.05)
                assert td.completes()[-1] == ['task', 'complete', 'id:recurring'], td.completes()
                print('PASS a read that started before a completion cannot bring the completed occurrence back', flush=True)
                td.slow_reads(False)

                ipc('done', 'allDayOverdue')
                wait_for(lambda s: not s['busy'] and not s['loading'] and len(s['items']) == 2, 'second completion')
                ipc('done', 'allDayToday')
                wait_for(lambda s: not s['busy'] and not s['loading'] and len(s['items']) == 1, 'third completion')
                td.serve([tasks[3]])
                ipc('refresh')
                wait_for(lambda s: not s['loading'] and [i['id'] for i in s['items']] == ['timedTomorrow'], 'single task left')
                ipc('done', 'timedTomorrow')
                wait_for(lambda s: not s['busy'] and not s['loading'] and not s['items'] and s['next'] is None,
                         'last completion returns empty state')

                calls = td.calls()
                assert all(call == READ or (len(call) == 3 and call[:2] == ['task', 'complete'] and call[2].startswith('id:'))
                           for call in calls), calls
                assert not any('--forever' in call for call in calls), calls
                print(f'PASS every td call was a read or a single-occurrence complete ({len(calls)} calls, fake td only)', flush=True)
                assert not any(term in log.read_text() for term in ['ReferenceError:', 'TypeError:', 'SyntaxError:', 'Failed to load configuration'])
                print('PASS Todoist E2E: fake td, Quickshell agenda and completion. Repeat: python3 shell/test/todoist-e2e.py')
            finally:
                process.terminate()
                try:
                    process.wait(timeout=5)
                except subprocess.TimeoutExpired:
                    process.kill()
                    process.wait()


if __name__ == '__main__':
    main()
