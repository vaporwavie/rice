#!/usr/bin/env python3
import json
import os
from pathlib import Path
import shutil
import subprocess
import re
import tempfile
import time

SHELL = Path(__file__).resolve().parents[1]

# Failures: wrong CPU math, first-read spike, stalled counters read as idle, loopback or tunnels counted
# on a live link, offline link counted as zero, missing sensor, top parsing with spaced names or other
# locales, top running while closed, cell routing to the wrong panel, broken network panel switch.
STAT_A = '''cpu  100 0 100 800 0 0 0 0 0 0
cpu0 50 0 50 400 0 0 0 0 0 0
cpu1 50 0 50 400 0 0 0 0 0 0
intr 1
'''
STAT_B = '''cpu  200 0 200 1000 0 0 0 0 0 0
cpu0 170 0 50 480 0 0 0 0 0 0
cpu1 70 0 70 460 0 0 0 0 0 0
intr 2
'''
MEMINFO = '''MemTotal:       16777216 kB
MemFree:         1000000 kB
MemAvailable:    4194304 kB
SwapTotal:       8388608 kB
SwapFree:        6291456 kB
'''
TOP = '''top - 10:00:00 up 1 day,  1 user,  load average: 0.10, 0.20, 0.30
Tasks:   3 total

    PID USER      PR  NI    VIRT    RES    SHR S  %CPU  %MEM     TIME+ COMMAND
      1 root      20   0       0      0      0 S   0.0   0.0   0:00.00 stale
'''
TOP_FRAME = '''top - 10:00:01 up 1 day,  1 user,  load average: 0.10, 0.20, 0.30
Tasks:   3 total

    PID USER      PR  NI    VIRT    RES    SHR S  %CPU  %MEM     TIME+ COMMAND
   4242 me        20   0  100000  50000  10000 R  93.5  12.5   1:00.00 next-server (v1
   4243 me        20   0  100000  50000  10000 S   4.0   1.5   0:10.00 kitty
   4244 me        20   0  100000  50000  10000 R   0.1   0.0   0:00.01 top
'''


def net_dev(eth, tun, lo):
    head = ('Inter-|   Receive                                                |  Transmit\n'
            ' face |bytes    packets errs drop fifo frame compressed multicast|bytes    packets errs drop fifo colls carrier compressed\n')
    row = lambda name, rx, tx: f'{name:>6}: {rx} 0 0 0 0 0 0 0 {tx} 0 0 0 0 0 0 0\n'
    return head + row('lo', lo, lo) + row('eth9', *eth) + row('tailscale0', *tun)


def replace(path, text):
    pending = path.with_suffix('.next')
    pending.write_text(text)
    pending.replace(path)


def main():
    with tempfile.TemporaryDirectory(prefix='activity-e2e-') as temporary:
        root = Path(temporary)
        config = root / 'shell'
        config.mkdir()
        for source in SHELL.iterdir():
            if source.suffix in {'.qml', '.js', '.mjs'}:
                shutil.copy2(source, config / source.name)
        shutil.copytree(SHELL.parent / 'generated', root / 'generated')

        proc = root / 'proc'
        (proc / 'net').mkdir(parents=True)
        (proc / 'sys/kernel').mkdir(parents=True)
        (proc / 'sys/kernel/hostname').write_text('fixture\n')
        (proc / 'uptime').write_text('93784.00 1.00\n')
        (proc / 'loadavg').write_text('1.50 0.75 0.25 1/100 1\n')
        (proc / 'meminfo').write_text(MEMINFO)
        replace(proc / 'stat', STAT_A)
        replace(proc / 'net/dev', net_dev((1000, 1000), (0, 0), 0))
        hwmon = root / 'hwmon'
        for name, value in [('acpitz', '99000'), ('k10temp', '61500')]:
            (hwmon / name).mkdir(parents=True)
            (hwmon / name / 'name').write_text(name + '\n')
            (hwmon / name / 'temp1_input').write_text(value + '\n')

        bin_dir = root / 'bin'
        bin_dir.mkdir()
        link = root / 'link'
        link.write_text('up')
        top_calls = root / 'top-calls'
        (bin_dir / 'nmcli').write_text(f'''#!/bin/sh
case "$*" in
  *monitor*) exec sleep 3600 ;;
  *"device show"*) printf 'GENERAL.DEVICE:eth9\\nGENERAL.TYPE:ethernet\\nGENERAL.STATE:100 (connected)\\nGENERAL.CONNECTION:Wired\\nIP4.ADDRESS[1]:10.0.0.5/24\\n' ;;
  *"connection show"*) if [ "$(cat {link})" = up ]; then echo 'Wired:802-3-ethernet:eth9:yes'; else echo 'Wired:802-3-ethernet::no'; fi ;;
esac
''')
        (bin_dir / 'top').write_text(f'''#!/bin/sh
echo "$LC_ALL" >> {top_calls}
cat <<'EOF'
{TOP}
{TOP_FRAME}EOF
''')
        for script in bin_dir.iterdir():
            script.chmod(0o755)

        (config / 'shell.qml').write_text('''import QtQuick
import Quickshell
import Quickshell.Io
import QtTest
import qs
ShellRoot {
    Window {
        width: 400; height: 36
        visible: true
        Item {
            id: bar
            anchors.fill: parent
            function togglePanel(name) { Panels.toggle(name, "") }
            function panelOpen(name) { return Panels.isOpen(name, "") }
            ActivityButton { id: cell; bar: bar }
        }
    }
    TestCase { id: input; when: false }
    IpcHandler {
        target: "test"
        function state(): string {
            return JSON.stringify({ panel: Panels.open, reads: Activity.reads, cpu: Activity.cpu,
                cores: Activity.cores, history: Activity.cpuHistory, temp: Activity.temp, host: Activity.host,
                mem: Activity.mem, swapUsed: Activity.swapUsed, online: Activity.online, iface: Activity.iface,
                rxHistory: Activity.rxHistory, txHistory: Activity.txHistory, top: Activity.top,
                load: Activity.load, uptime: Activity.since(Activity.uptime), cellWidth: cell.width,
                text: cell.text, colors: cell.readouts.map(function(r) { return String(r.tone) }) })
        }
        function click(button: string): void {
            input.mouseClick(cell, cell.width / 2, cell.height / 2, button === "right" ? Qt.RightButton : Qt.LeftButton)
        }
        function toggle(name: string): void { Panels.toggle(name, "") }
        function close(): void { Panels.close() }
        function refresh(): void { Nm.refresh() }
    }
}
''')
        env = {**os.environ, 'QT_QPA_PLATFORM': 'offscreen', 'ACTIVITY_PROC': str(proc),
               'ACTIVITY_HWMON': str(hwmon), 'PATH': f'{bin_dir}:{os.environ["PATH"]}', 'LC_ALL': 'de_DE.UTF-8'}
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

                def wait_for(predicate, label, timeout=15):
                    deadline = time.monotonic() + timeout
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

                s = wait_for(lambda s: s['reads'] >= 2 and s['online'] and s['iface'] == 'eth9' and s['temp'] >= 0
                             and s['cellWidth'] > 0, 'cell renders with link, sensor, and first reads')
                assert s['history'] == [] and s['cpu'] == 0, s
                assert s['temp'] == 62 and s['host'] == 'fixture' and s['uptime'] == '1d 2h', s
                assert s['mem'] == 75 and s['swapUsed'] == 2097152 and s['load'] == [1.5, 0.75, 0.25], s
                print('PASS no first-read spike, stalled counters ignored, CPU sensor chosen over ACPI', flush=True)
                assert re.fullmatch(r'0% 62° \d+\.\dG 0', s['text']), s['text']
                assert s['colors'] == ['', '', '#d6b370', ''], s['colors']
                (hwmon / 'k10temp' / 'temp1_input').write_text('92500\n')
                s = wait_for(lambda s: ' 93° ' in s['text'], 'sensor change reaches the readout')
                assert s['colors'][1] == '#d8826f', s['colors']
                (hwmon / 'k10temp' / 'temp1_input').write_text('61500\n')
                wait_for(lambda s: ' 62° ' in s['text'], 'sensor cools back down')
                print('PASS text readouts: cpu, temp, mem, net; mem at 75% yellow, temp past 90 red', flush=True)
                assert not top_calls.exists(), 'top ran with the panel closed'

                replace(proc / 'stat', STAT_B)
                s = wait_for(lambda s: len(s['history']) == 1, 'CPU delta sampled once')
                assert s['cpu'] == 50 and s['cores'] == [60, 40], s
                time.sleep(4.5)
                assert state()['history'] == [50], state()
                print('PASS CPU and per-core math from deltas, no repeat samples on stalled counters', flush=True)

                replace(proc / 'net/dev', net_dev((3001000, 1001000), (9000000, 9000000), 50000000))
                s = wait_for(lambda s: any(v > 0 for v in s['rxHistory']), 'link traffic sampled')
                rx, tx = max(s['rxHistory']), max(s['txHistory'])
                assert 3e6 / 4 < rx < 3e6 / 1.5 and 1e6 / 4 < tx < 1e6 / 1.5, (rx, tx)
                assert abs(rx / tx - 3) < 0.01, (rx, tx)
                print('PASS rates come from the link only, loopback and tunnel excluded', flush=True)

                link.write_text('down')
                ipc('refresh')
                wait_for(lambda s: not s['online'] and s['iface'] == '', 'offline link falls back to every device')
                before = len(state()['rxHistory'])
                replace(proc / 'net/dev', net_dev((3001000, 1001000), (13000000, 9000000), 90000000))
                s = wait_for(lambda s: len(s['rxHistory']) > before and s['rxHistory'][-1] > 0,
                             'offline traffic still visible')
                assert 4e6 / 4 < s['rxHistory'][-1] < 4e6 / 1.5 and s['txHistory'][-1] == 0, s
                print('PASS offline sums non-loopback devices', flush=True)

                ipc('click', 'left')
                s = wait_for(lambda s: s['panel'] == 'activity' and s['top'], 'cell opens the situation panel and samples top')
                assert [p['name'] for p in s['top']] == ['next-server (v1', 'kitty'], s['top']
                assert s['top'][0]['cpu'] == 93.5 and s['top'][0]['mem'] == 12.5 and s['top'][0]['pid'] == 4242
                assert top_calls.read_text().split()[0] == 'C'
                print('PASS second top frame parsed, spaced names kept, top hidden, C locale forced', flush=True)

                ipc('toggle', 'network')
                assert state()['panel'] == 'network'
                ipc('close')
                calls = len(top_calls.read_text().split())
                time.sleep(2.5)
                assert len(top_calls.read_text().split()) == calls, 'top kept running after close'
                ipc('click', 'right')
                assert state()['panel'] == 'network'
                ipc('click', 'left')
                assert state()['panel'] == 'activity'
                ipc('click', 'left')
                assert state()['panel'] == ''
                print('PASS right-click opens connections, left toggles situation, top stops when closed', flush=True)

                assert not any(term in log.read_text() for term in
                               ['ReferenceError:', 'TypeError:', 'SyntaxError:', 'Failed to load configuration',
                                'is not a type', 'Cannot assign'])
                print('PASS activity E2E. Repeat: python3 shell/test/activity-e2e.py', flush=True)
            finally:
                process.terminate()
                try:
                    process.wait(timeout=5)
                except subprocess.TimeoutExpired:
                    process.kill()
                    process.wait()


if __name__ == '__main__':
    main()
