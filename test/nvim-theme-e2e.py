#!/usr/bin/env python3
import json
import os
from pathlib import Path
import re
import subprocess
import tempfile
import time

HYPR = Path(__file__).resolve().parents[1]

# Failures: palette keys missing from the template, day loading onedark's dark style, a running nvim
# missing the flip because theme renames the file, a half-written file raising errors or blanking
# colors, the previous mode's overrides leaking into the next, and no palette breaking the fallback.
QUERY = '''luaeval("vim.json.encode((function()
  local function hl(name, key)
    local v = vim.api.nvim_get_hl(0, { name = name, link = false })[key]
    return v and string.format('#%06x', v) or vim.NIL
  end
  return { normal = hl('Normal', 'bg'), fg = hl('Normal', 'fg'), string = hl('String', 'fg'),
    keyword = hl('Keyword', 'fg'), comment = hl('Comment', 'fg'), visual = hl('Visual', 'bg'),
    float = hl('NormalFloat', 'bg'), background = vim.o.background, scheme = vim.g.colors_name,
    messages = vim.fn.execute('messages') }
end)())")'''


def palette(mode):
    return dict(re.findall(r'^([A-Z_]+)=(.*)$', (HYPR / 'themes' / f'{mode}.env').read_text(), re.M))


def render(target, mode):
    env = palette(mode)
    names = ' '.join('${' + k + '}' for k in env)
    text = subprocess.run(['envsubst', names], input=(HYPR / 'templates/colors.lua.in').read_text(),
                          env={**os.environ, **env}, text=True, capture_output=True, check=True).stdout
    pending = target.with_name('.colors.lua.tmp')
    pending.write_text(text)
    pending.replace(target)


def main():
    with tempfile.TemporaryDirectory(prefix='nvim-theme-e2e-') as temporary:
        root = Path(temporary)
        colors = root / 'colors.lua'
        socket = root / 'nvim.sock'
        render(colors, 'night')
        env = {**os.environ, 'ALTURA_COLORS': str(colors)}
        process = subprocess.Popen(['nvim', '--headless', '--listen', str(socket)], env=env,
                                   stdout=subprocess.DEVNULL, stderr=subprocess.PIPE, text=True)
        try:
            def state():
                return json.loads(subprocess.run(['nvim', '--server', str(socket), '--remote-expr', QUERY],
                                                 text=True, capture_output=True, check=True).stdout)

            def wait_for(predicate, label):
                deadline = time.monotonic() + 15
                last = None
                while time.monotonic() < deadline:
                    if process.poll() is not None:
                        raise AssertionError(process.stderr.read())
                    try:
                        last = state()
                        if predicate(last):
                            print('PASS ' + label, flush=True)
                            return last
                    except (subprocess.CalledProcessError, json.JSONDecodeError):
                        pass
                    time.sleep(0.1)
                raise AssertionError(f'{label}: {last}')

            def matches(mode):
                p = palette(mode)
                return lambda s: (s['normal'] == '#' + p['BG'] and s['fg'] == '#' + p['FG']
                                  and s['string'] == '#' + p['GREEN'] and s['keyword'] == '#' + p['PURPLE']
                                  and s['comment'] == '#' + p['MUTED'] and s['visual'] == '#' + p['LINE_STRONG']
                                  and s['float'] == '#' + p['BG_ELEV'] and s['background'] == p['MODE'])

            wait_for(matches('night'), 'night palette at startup')
            render(colors, 'day')
            wait_for(matches('day'), 'running nvim follows a renamed-in day palette')
            pending = colors.with_name('.colors.lua.tmp')
            pending.write_text('return {\n    name = "AlturaDay",\n    bg = "f4f')
            pending.replace(colors)
            time.sleep(1)
            s = state()
            assert matches('day')(s), s
            print('PASS half-written palette keeps the current colors', flush=True)
            render(colors, 'night')
            s = wait_for(matches('night'), 'flips back to night without day leftovers')
            assert 'Error' not in s['messages'] and 'E5' not in s['messages'], s['messages']
            print('PASS no errors across flips', flush=True)
        finally:
            process.terminate()
            process.wait(timeout=5)

        fallback = subprocess.run(['nvim', '--headless', '+lua io.stdout:write(vim.g.colors_name or "none", " ", vim.fn.execute("messages"))', '+qa'],
                                  env={**os.environ, 'ALTURA_COLORS': str(root / 'missing.lua')},
                                  text=True, capture_output=True, timeout=30)
        assert fallback.stdout.startswith('onedark') and 'Error' not in fallback.stdout + fallback.stderr, fallback
        print('PASS no palette falls back to onedark with the portal', flush=True)
        print('PASS nvim theme E2E. Repeat: python3 test/nvim-theme-e2e.py', flush=True)


if __name__ == '__main__':
    main()
