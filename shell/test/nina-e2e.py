#!/usr/bin/env python3
import json
import os
from pathlib import Path
import shutil
import socket
import subprocess
import tempfile
import threading
import time

SHELL = Path(__file__).resolve().parents[1]
SECRET = 'sk-ant-e2e-must-not-leak'


# Stands in for Nina's nina.sock: `watch` connections stay open for pushed lines, any other
# line is recorded and answered once, the way single_instance.rs serves them.
class FakeNina:
    def __init__(self, path):
        self.path = path
        self.watchers = []
        self.commands = []
        self.lock = threading.Lock()
        self.server = None

    def start(self):
        self.server = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        self.server.bind(str(self.path))
        self.server.listen()
        threading.Thread(target=self.serve, args=(self.server,), daemon=True).start()

    def serve(self, server):
        while True:
            try:
                conn, _ = server.accept()
            except OSError:
                return
            line = conn.makefile().readline().strip()
            with self.lock:
                if line == 'watch':
                    conn.sendall(b'ok\noverlay hidden\n')
                    self.watchers.append(conn)
                else:
                    self.commands.append(line)
                    conn.sendall(b'ok\n')
                    conn.close()

    def push(self, *lines):
        with self.lock:
            for conn in self.watchers:
                conn.sendall(''.join(line + '\n' for line in lines).encode())

    def stop(self):
        with self.lock:
            for conn in self.watchers:
                conn.close()
            self.watchers = []
        self.server.close()
        self.path.unlink(missing_ok=True)


# Failures: no socket yet, missed reconnect, stale levels after a take, lost error text, API keys
# reaching QML, atomic settings rewrites unseen, broken history lines, new takes unseen, Open Nina
# not launching, copy touching the real clipboard, search not filtering.
def main():
    with tempfile.TemporaryDirectory(prefix='nina-e2e-') as temporary:
        root = Path(temporary)
        config = root / 'shell'
        config.mkdir()
        for source in SHELL.glob('*.qml'):
            if source.name != 'shell.qml':
                shutil.copy2(source, config / source.name)
        for source in SHELL.glob('*.js'):
            shutil.copy2(source, config / source.name)
        for source in SHELL.glob('*.mjs'):
            shutil.copy2(source, config / source.name)
        shutil.copytree(SHELL.parent / 'generated', root / 'generated')
        (config / 'shell.qml').write_text('''import QtQuick
import Quickshell
import Quickshell.Io
import qs
ShellRoot {
    Item { id: anchor; width: 800; height: 30 }
    NinaFull { id: full; anchorItem: anchor }
    IpcHandler {
        target: "test"
        function state(): string {
            return JSON.stringify({ connected: Nina.connected, state: Nina.state, message: Nina.message,
                lastError: Nina.lastError, levels: Nina.levels, model: Nina.modelName, language: Nina.languageLabel,
                hotkey: Nina.hotkeyLabel, fillers: Nina.fillers, history: Nina.history.map(e => e.id),
                copied: Nina.copiedId, shown: full.entries.map(e => e.id), leak: JSON.stringify(Nina) })
        }
        function launch(): void { Nina.openSettings() }
        function copyLatest(): void { Nina.copy(Nina.latest) }
        function search(query: string): void { full.query = query }
        function refresh(): void { Nina.refresh() }
    }
}
''')
        runtime = root / 'run'
        runtime.mkdir(mode=0o700)
        nina_config = root / 'config'
        nina_config.mkdir()
        nina_data = root / 'data'
        nina_data.mkdir()
        bin_dir = root / 'bin'
        bin_dir.mkdir()
        clipboard = root / 'clipboard'
        (bin_dir / 'wl-copy').write_text(f'#!/bin/sh\n[ "$1" = "--" ] && shift\nprintf %s "$1" > {clipboard}\n')
        (bin_dir / 'wl-copy').chmod(0o755)
        launches = root / 'launches'
        (bin_dir / 'nina').write_text(f'#!/bin/sh\necho "$@" >> {launches}\n')
        (bin_dir / 'nina').chmod(0o755)

        settings = nina_config / 'settings.json'
        settings.write_text(json.dumps({'active_model': 'parakeet-tdt-0.6b-v3', 'language': None,
                                        'hotkey': ['KEY_RIGHTCTRL'], 'filter_fillers': True,
                                        'anthropic_api_key': SECRET}))
        history = nina_data / 'history.jsonl'
        history.write_text('\n'.join([
            json.dumps({'id': 1, 'created_at': 1_000, 'text': 'hello world', 'audio_ms': 900, 'duration_ms': 5}),
            '{not json',
            json.dumps({'id': 2, 'created_at': 2_000, 'text': 'second take', 'audio_ms': 1200, 'duration_ms': 5}),
        ]) + '\n')

        env = {**os.environ, 'QT_QPA_PLATFORM': 'offscreen', 'XDG_RUNTIME_DIR': str(runtime),
               'NINA_CONFIG_DIR': str(nina_config), 'NINA_DATA_DIR': str(nina_data),
               'PATH': f'{bin_dir}:{os.environ["PATH"]}'}
        fake = FakeNina(runtime / 'nina.sock')
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

                def wait_for(predicate, label, timeout=12):
                    deadline = time.monotonic() + timeout
                    last = None
                    while time.monotonic() < deadline:
                        if process.poll() is not None:
                            raise AssertionError(log.read_text())
                        try:
                            last = state()
                            if predicate(last):
                                print('PASS ' + label)
                                return last
                        except (subprocess.CalledProcessError, json.JSONDecodeError):
                            pass
                        time.sleep(0.1)
                    raise AssertionError(f'{label}: {last}\n{log.read_text()}')

                s = wait_for(lambda s: not s['connected'] and s['history'] == [2, 1], 'no socket, history newest first, broken line skipped')
                assert s['model'] == 'Parakeet TDT 0.6B v3' and s['language'] == 'Any' and s['hotkey'] == 'Right Ctrl'
                assert SECRET not in json.dumps(s)
                print('PASS settings whitelisted, API key never reaches QML')

                fake.start()
                wait_for(lambda s: s['connected'] and s['state'] == 'hidden', 'reconnects once Nina appears')

                fake.push('overlay recording', *[f'level {i / 40:.2f}' for i in range(30)])
                s = wait_for(lambda s: s['state'] == 'recording' and len(s['levels']) == 24, 'recording streams capped levels')
                assert abs(s['levels'][-1] - 0.72) < 1e-6
                fake.push('overlay transcribing')
                wait_for(lambda s: s['state'] == 'transcribing' and s['levels'] == [], 'transcribing clears the meter')
                fake.push('overlay error Paste failed: uinput not writable')
                wait_for(lambda s: s['state'] == 'error' and s['message'] == 'Paste failed: uinput not writable', 'error keeps its message')

                with history.open('a') as f:
                    f.write(json.dumps({'id': 3, 'created_at': 3_000, 'text': 'fresh dictation', 'audio_ms': 2000, 'duration_ms': 5}) + '\n')
                fake.push('overlay hidden')
                wait_for(lambda s: s['state'] == 'hidden' and s['lastError'].startswith('Paste failed') and s['history'][0] == 3,
                         'new take appears when the take ends')

                replacement = nina_config / 'settings.json.tmp'
                replacement.write_text(json.dumps({'active_model': 'canary-1b-v2', 'language': 'de',
                                                   'hotkey': ['KEY_LEFTMETA', 'KEY_SPACE'], 'filter_fillers': False,
                                                   'openai_api_key': SECRET}))
                replacement.replace(settings)
                ipc('refresh')
                s = wait_for(lambda s: s['model'] == 'Canary 1B v2' and s['hotkey'] == 'Super+Space' and not s['fillers'],
                             'atomic settings rewrite is picked up on refresh')
                assert s['language'] == 'DE' and SECRET not in json.dumps(s)

                ipc('launch')
                wait_for(lambda s: launches.exists() and launches.read_text() == '\n', 'Open Nina launches nina, which shows the running one')

                ipc('copyLatest')
                wait_for(lambda s: s['copied'] == 3 and clipboard.exists() and clipboard.read_text() == 'fresh dictation',
                         'copy hands the latest take to wl-copy')
                wait_for(lambda s: s['copied'] == -1, 'copied flash clears')

                ipc('search', 'TAKE')
                wait_for(lambda s: s['shown'] == [2], 'search filters case-insensitively')
                ipc('search', '')
                wait_for(lambda s: s['shown'] == [3, 2, 1], 'empty search shows every take')

                fake.stop()
                wait_for(lambda s: not s['connected'] and s['state'] == 'hidden', 'Nina quitting resets the state')
                fake = FakeNina(runtime / 'nina.sock')
                fake.start()
                wait_for(lambda s: s['connected'], 'reconnects after a restart')

                assert not any(term in log.read_text() for term in ['ReferenceError:', 'TypeError:', 'SyntaxError:', 'Failed to load configuration']), log.read_text()
                print('PASS Nina E2E: fake socket, temporary settings and history, Quickshell singleton and full panel. Repeat: python3 shell/test/nina-e2e.py')
            finally:
                fake.stop() if fake.server else None
                process.terminate()
                try:
                    process.wait(timeout=5)
                except subprocess.TimeoutExpired:
                    process.kill()
                    process.wait()


if __name__ == '__main__':
    main()
