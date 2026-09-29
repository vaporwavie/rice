#!/usr/bin/env python3
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import time

SHELL = Path(__file__).resolve().parents[1]
NEXT = 1790711820

# Failures: missing reports dir crashes or shows stale text, malformed verdict lines break parsing, history order
# or length wrong, the body vanishing while a run deletes push.txt, priority and failed runs not flagged, Run now
# starting twice or not at all, finished runs not reaching the card, the next run time misread.
def status(state, result, finished):
    return (f'NextElapseUSecRealtime=@{NEXT}\nActiveState=active\nResult=success\n\n'
            f'ActiveState={state}\nResult={result}\nExecMainExitTimestamp=@{finished}\n')


def main():
    with tempfile.TemporaryDirectory(prefix='overseer-e2e-') as temporary:
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
import QtTest
import qs
ShellRoot {
    Window {
        width: 400; height: 560
        visible: true
        OverseerView { id: view; anchors.fill: parent }
    }
    TestCase { id: input; when: false }
    QtObject {
        id: util
        function search(item, name) {
            if (item.objectName === name) return item
            for (var child of item.children || []) {
                var match = search(child, name)
                if (match) return match
            }
            return null
        }
    }
    IpcHandler {
        target: "test"
        function state(): string {
            var tag = util.search(view, "tag"), run = util.search(view, "runNow")
            return JSON.stringify({ verdicts: Overseer.verdicts, headline: util.search(view, "headline").text,
                details: util.search(view, "details").text, earlier: view.earlier.map(v => v.stamp),
                tag: tag.text, tagColor: String(view.tagColor), red: String(Theme.red), running: Overseer.running,
                runEnabled: run.enabled, next: Overseer.next, error: Overseer.error })
        }
        function refresh(): void { Overseer.refresh() }
        function run(): void {
            var button = util.search(view, "runNow")
            input.mouseClick(button, button.width / 2, button.height / 2, Qt.LeftButton)
        }
    }
}
''')
        reports = root / 'reports'
        bin_dir = root / 'bin'
        bin_dir.mkdir()
        unit = root / 'unit'
        unit.write_text(status('inactive', 'success', NEXT - 28800))
        calls = root / 'calls'
        (bin_dir / 'systemctl').write_text(f'''#!/bin/sh
echo "$*" >> {calls}
case "$*" in
  *show*) cat {unit} ;;
esac
''')
        (bin_dir / 'systemctl').chmod(0o755)

        env = {**os.environ, 'QT_QPA_PLATFORM': 'offscreen', 'OVERSEER_DIR': str(reports),
               'PATH': f'{bin_dir}:{os.environ["PATH"]}'}
        log = root / 'quickshell.log'
        with log.open('w') as output:
            process = subprocess.Popen(['qs', '-p', str(config), '--no-color'], env=env, stdout=output, stderr=subprocess.STDOUT)
            try:
                def ipc(method, *args):
                    return subprocess.run(['qs', 'ipc', '--pid', str(process.pid), 'call', 'test', method, *args],
                                          env=env, check=True, text=True, capture_output=True).stdout.strip()

                def wait_for(predicate, label):
                    deadline = time.monotonic() + 12
                    last = None
                    while time.monotonic() < deadline:
                        if process.poll() is not None:
                            raise AssertionError(log.read_text())
                        try:
                            last = json.loads(ipc('state'))
                            if predicate(last):
                                print('PASS ' + label, flush=True)
                                return last
                        except (subprocess.CalledProcessError, json.JSONDecodeError):
                            pass
                        time.sleep(0.1)
                    raise AssertionError(f'{label}: {last}\n{log.read_text()}')

                wait_for(lambda s: s['verdicts'] == [] and s['headline'] == '' and s['earlier'] == [] and s['tag'] == ''
                         and s['next'] == NEXT * 1000, 'no reports yet, next run read from the timer')

                reports.mkdir()
                lines = [f'2026-09-2{d}-{h}57 Next: run {d}{h}' for d in range(7, 9) for h in ('00', '08', '16')]
                (reports / 'verdicts.log').write_text('\n'.join(lines[:3] + ['2026-08-06 undated legacy line'] + lines[3:]) + '\n')
                (reports / 'push.txt').write_text('Next: reboot for kernel 7.2.8\n\n- Kernel landed this morning.\n- Disk 22%.\n')
                (reports / 'priority.txt').write_text('high\n')
                ipc('refresh')
                s = wait_for(lambda s: len(s['verdicts']) == 6 and s['headline'] == 'Next: reboot for kernel 7.2.8',
                             'reports load, malformed lines skipped')
                assert s['verdicts'][0]['stamp'] == '2026-09-28-1657', s['verdicts'][0]
                assert s['earlier'] == ['2026-09-28-0857', '2026-09-28-0057', '2026-09-27-1657', '2026-09-27-0857'], s['earlier']
                assert s['details'] == '- Kernel landed this morning.\n- Disk 22%.', s['details']
                assert s['tag'] == 'high' and s['tagColor'] == s['red'], s
                print('PASS newest first, four earlier verdicts, body split into headline and details, high priority in red')

                unit.write_text(status('inactive', 'failed', NEXT - 28800))
                (reports / 'priority.txt').write_text('default\n')
                ipc('refresh')
                wait_for(lambda s: s['tag'] == 'last run failed' and s['tagColor'] == s['red'], 'failed service run flagged')

                calls.write_text('')
                unit.write_text(status('activating', 'success', NEXT - 28800))
                ipc('run')
                ipc('run')
                s = wait_for(lambda s: s['running'] and not s['runEnabled'] and s['tag'] == 'running…', 'Run now shows the run')
                (reports / 'push.txt').unlink()
                time.sleep(0.5)
                s = wait_for(lambda s: s['headline'] == 'Next: reboot for kernel 7.2.8', 'body kept while the run deletes push.txt')
                starts = [c for c in calls.read_text().splitlines() if 'start' in c]
                assert starts == ['--user start --no-block overseer.service'], starts
                print('PASS Run now starts the service exactly once')

                (reports / 'push.txt').write_text('Next: nothing\n\n- All clear.\n')
                with (reports / 'verdicts.log').open('a') as f:
                    f.write('2026-09-29-0857 Next: nothing\n')
                unit.write_text(status('inactive', 'success', NEXT - 60))
                ipc('refresh')
                s = wait_for(lambda s: not s['running'] and s['runEnabled'] and s['headline'] == 'Next: nothing'
                             and s['verdicts'][0]['stamp'] == '2026-09-29-0857' and s['tag'] == '', 'finished run reaches the card')

                assert not any(term in log.read_text() for term in
                               ['ReferenceError:', 'TypeError:', 'SyntaxError:', 'Failed to load configuration', 'is not a type', 'Cannot assign']), log.read_text()
                print('PASS overseer E2E: fixture reports, fake systemctl, Quickshell card. Repeat: python3 shell/test/overseer-e2e.py')
            finally:
                process.terminate()
                try:
                    process.wait(timeout=5)
                except subprocess.TimeoutExpired:
                    process.kill()
                    process.wait()


if __name__ == '__main__':
    main()
