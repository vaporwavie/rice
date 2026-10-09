# rice

My Hyprland setup on Fedora 44: Lua config for Hyprland 0.56, a Quickshell bar with panels, and day and night themes that switch at sunrise and sunset. It wears the altura.software look.

## Install

```sh
git clone https://github.com/vaporwavie/rice.git ~/.config/hypr
```

The repo replaces `~/.config/hypr`, so move an existing one out of the way first. Then adjust what is specific to my machine:

- `hyprlock.conf` sources `/home/powerstation/.config/hypr/generated/hyprlock.conf`. Change the home directory.
- The `DP-1` line in `hyprland.lua` sets a 4K monitor at scale 1.5. Every other output falls back to its preferred mode.
- The pointer settings in `hyprland.lua` target an MX Master 3S.

Run `./theme auto` once to render `generated/`, which is gitignored, and `./install-units` once to link `systemd/` into `~/.config/systemd/user`.

`imgview FILE` opens images in a Quickshell viewer: scroll zooms at the cursor, drag pans, Left/Right steps through the folder, `0` fits, `1` shows actual size, `q` or Escape closes. Link `applications/imgview.desktop` into `~/.local/share/applications` and run `xdg-mime default imgview.desktop image/png` (and the other types it lists) to make it the default.

It expects `quickshell`, `node`, `kitty`, `fuzzel`, `dunst`, `hypridle`, `hyprlock`, `grim`, `slurp`, `wl-clipboard`, `jq`, `playerctl`, `nmcli`, `wpctl`, and `ddcutil`. See [Optional packages](#optional-packages) for the rest.

The lock screen uses IBM Plex Sans, IBM Plex Mono, and Fraunces, and notifications use IBM Plex Sans. Put the Google Fonts files in `~/.local/share/fonts` and run `fc-cache -f`.

`mate-polkit` provides password prompts, `nautilus` opens directories, and the Hyprland and GTK portals handle screen sharing and file dialogs. Keep `kf6-kwallet` and `pam-kwallet` for existing Chromium app logins.

## Sign in

Choose Hyprland in SDDM and sign in. SDDM uses Weston for its login screen. `/etc/sddm.conf.d/90-hyprland.conf` selects the Maldives theme and limits the session list to Hyprland. SDDM's packaged PAM configuration includes GNOME Keyring and KWallet login hooks.

## Keys

| Shortcut | Action |
| --- | --- |
| Super+Enter | Kitty |
| Super+Space, Alt+Space, Alt+F2 | App launcher |
| Super+E | Nautilus |
| Super+B | Default browser |
| Super+PageDown | Keevy machine picker |
| Super+Q, Alt+F4 | Close window |
| Super+Ctrl+Esc | Kill window |
| Super+F | Maximize |
| Super+Shift+F | Fullscreen |
| Super+V | Toggle floating |
| Super+P | Pin floating window |
| Super+C | Center floating window |
| Super+T | Toggle split direction |
| Super+G | Toggle group, Super+[ and Super+] switch tabs |
| Alt+Tab, Alt+Shift+Tab | Cycle windows |
| Super+arrows or HJKL | Focus window |
| Super+Shift+arrows or HJKL | Swap window |
| Super+Alt+arrows | Resize window |
| Super+1 through 0 | Switch workspace, again to go back |
| Super+Shift+1 through 0 | Move window to workspace |
| Super+Ctrl+Left/Right, Super+scroll | Previous or next workspace |
| Super+Tab | Last workspace |
| Super, Super | Show the desktop with the Todoist, Notion Calendar, activity, and overseer widgets, Escape or another double tap returns |
| Super+S | Scratchpad, opens Kitty when empty |
| Super+Shift+S | Move window to scratchpad |
| Super+left/right drag | Move or resize window |
| Super+= and Super+- | Zoom, Super+Ctrl+0 resets |
| Print, Alt+Shift+4 | Screenshot a region |
| Shift+Print | Screenshot the screen |
| Super+Print | Screenshot the window |
| Super+Shift+V | Clipboard history, needs cliphist |
| Super+Shift+T | Toggle day and night theme |
| Super+Ctrl+L | Lock |
| Super+Shift+E | Session menu |

Caps Lock is Escape.

## Look

The palette, type, and motion come from the Altura landing page (`apps/landing` and `packages/design-system` in altura-software). Night is ink black with bone text, day is its inversion on warm bone. Every surface is flat and edged with hairlines. Window borders are 1px and lit from the top, corners are square, and there is no blur or shadow. The bar and launcher stay in Geist Mono. Everything moves on one ease-out-expo curve. Windows and panels fade in with a small rise, workspaces slide horizontally, and nothing bounces.

The landing's dithered Doric column stands on the left edge, under the bar. On start it condenses row by row at the landing hero's pace, and a fresh ivy plant then grows over it for about ten minutes. The lock screen shows the same column and plant as they stand at that moment, under a large Fraunces clock.

## Layout

```
┌──────────────────────────────────────────────────────────────────────────────────────────┐
│ 1 2 3  active window     Tuesday 22nd, 14:32 │ Todoist … │ Notion       net▮▮▮ bt … tray │
├──────────────────────────────────────────────────────────────────────────────────────────┤
│                                  ┌────────────────────┐           ┌────────────────────┐ │
│ ┌────────────────────────────────│ calendar panel     │───────────│ notifications      │ │
│ │ kitty                          │ (click the clock)  │           │                    │ │
│ │                                │                    │           │                    │ │
│ │                                │                    │           └────────────────────┘ │
│ │                                │                    │                                │ │
│ │                                └────────────────────┘  Helium                        │ │
│ │                                         │  │                                         │ │
│ │                                         │  └─────────────────────────────────────────┘ │
│ │                                         │                                              │
│ │                                         │  ┌─────────────────────────────────────────┐ │
│ │                                         │  │ Nautilus                                │ │
│ │                                         │  │                                         │ │
│ │                                         │  │                                         │ │
│ │                                         │  │                                         │ │
│ │                                         │  │                                         │ │
│ │                                         │  │                                         │ │
│ └─────────────────────────────────────────┘  └─────────────────────────────────────────┘ │
│                                                                                          │
└──────────────────────────────────────────────────────────────────────────────────────────┘
```

The bar sits on top. Clicking the clock or Todoist opens the month and task agenda. Notion opens its own meeting agenda. Bluetooth, Keevy, display, audio, power, and tray icons open their panels or menus under the selected item. Windows tile with dwindle, 14px outer gaps and 6px between them.

The activity cell shows the network link icon and three small meters for CPU, memory, and network traffic. The icon turns red when offline, and the CPU and memory meters turn yellow at 75% and red at 90%. Click it for the situation panel: host and uptime, a three-minute CPU graph with per-core bars, temperature and load, memory and swap, link traffic, and the busiest processes. Process CPU is per core, as in `top`. Right-click it, or pick Connections in the panel, for the network panel. Traffic counts only the active link, so Tailscale is not counted twice. With no link, it sums every device except loopback. `top` runs only while the panel is open.

Run `python3 shell/test/activity-e2e.py` to check the cell and panel against a fake `/proc`, hwmon, `nmcli`, and `top`. Inspect the live values with `qs -p ~/.config/hypr/shell ipc call activity state`.

Todoist appears beside the clock with overdue and today counts. Click either to open the month and agenda. Dots mark dates with open tasks in the next 30 days, including the current occurrence of each recurring task. Click a date to filter, use H/L or Left/Right to change months, T to return to today's agenda, R to refresh, and Escape to close. The checkmark completes a task (only the current occurrence for recurring tasks). Open Todoist, or middle-click the bar summary, to add and edit tasks in the browser.

The widget reads `td upcoming 30 --json --all` every 30 seconds, when opened, and after actions. That one call returns overdue tasks, today, and the next 30 days. It runs `td` through the `td` script in this directory, so it needs neither PATH nor fnm's shell setup. The script uses the `@doist/todoist-cli` global install under fnm's default Node. If that Node lacks it, the script falls back to the newest fnm Node that has it, and runs it with that version's own `node`. td keeps its token in the keyring, so the session bus and a running keyring are required. The script only fills in `XDG_RUNTIME_DIR` and `DBUS_SESSION_BUS_ADDRESS` when they are unset. Override the command with `TD_BIN` in Quickshell's environment. Read errors show td's message, not its JSON. Todoist pushes reminders for timed tasks to the phone, so the bar sends no desktop notifications. Failed reads keep the last agenda visible with an error.

Run `python3 shell/test/todoist-e2e.py` to check Quickshell against a fake `td` that serves fixture tasks and records completions, so the real account is never touched. It verifies timed, all-day, overdue, and recurring tasks, date filtering, completion, empty states, and recovery from failed reads and writes. Each check prints PASS. Inspect the live widget with `qs -p ~/.config/hypr/shell ipc call todoist state`.

Notion stays beside Todoist even when no meetings are scheduled today. Click Notion for upcoming meetings, or middle-click it to open Notion Calendar. Its feed comes from `~/.config/notion-calendar-linux/panel.json` (override with `NOTION_CALENDAR_FEED`). Meeting alerts appear one minute before the start, with join and dismiss actions. Todoist tasks and Notion meetings keep separate data and panels.

Run `python3 shell/test/calendar-e2e.py` to verify both widgets together with a fake `td` and a temporary feed. It checks bar buttons, panel switching, empty and stale feeds, meeting alerts, and recovery. Inspect the Notion feed with `qs -p ~/.config/hypr/shell ipc call events state`.

Tapping Super twice switches to the `desktop` workspace, where `DesktopWidgets.qml` lays out a large clock and three cards: the Todoist agenda, Notion Calendar meetings, and the activity readout with the busiest processes. The cards sit on the bottom layer, so a window opened there covers them, and they never take keyboard focus, so Escape and the second tap still return. Actions that launch an app, such as opening Todoist or Notion Calendar, first go back to the previous workspace so the app does not open on the desktop. `top` samples while the desktop is showing, as it does while the activity panel is open.

The overseer card shows the latest 8-hour health report: the push body from `~/reports/overseer/push.txt`, the four previous verdicts from `verdicts.log`, and when `overseer.timer` fires next. Its tag flags a running, failed, or non-default priority run. Run now starts `overseer.service`, and Open report opens that run's Markdown report in Neovim. A run deletes `push.txt` when it starts, so the card keeps the last body until the new one lands. Set `OVERSEER_DIR` in Quickshell's environment to read reports from another directory. Run `python3 shell/test/overseer-e2e.py` to check the card against fixture reports and a fake `systemctl`.

Run `python3 shell/test/desktop-e2e.py` from a normal workspace to check the cards live. It pauses `quickshell.service` and runs the same shell on a fake `td`, so the real Todoist account is never read. It visits the desktop, compares the cards with the fixture and the Notion state, confirms that `top` stops after leaving, and then restores your workspace and the live bar. Inspect it with `qs -p ~/.config/hypr/shell ipc call desktop state`.

Keevy reads machine profiles from `~/Workspace/kvm` each time its panel opens. Number keys 1 to 3 select the Easy-Switch slot. Up/Down or J/K select a row, Enter switches, and Escape closes. It runs the existing Keevy switch scripts and shows failures in the panel. Set `KEEVY_PICKER` in Quickshell's environment if the picker lives elsewhere. Test the integration without switching hardware with `/usr/bin/python3 -m unittest discover -s shell/test -p 'test_keevy.py'`.

| Path | Role |
| --- | --- |
| `hyprland.lua` | Entry point. Requires `binds.lua` and `rules.lua`, starts `session-start`, runs `theme auto` every five minutes |
| `session-start` | Imports the session environment into systemd, starts `hyprland-session.target`, runs `~/.config/autostart`, and stops the target when the compositor exits |
| `systemd/` | The target and the units it wants: bar, Dunst, Hypridle, polkit agent, awww, clipboard history. They restart on failure. `systemctl --user status quickshell` and `journalctl --user -u quickshell` for the bar |
| `theme` | Renders `themes/*.env` through `templates/` into `generated/` and reloads what changed. Takes `auto`, `day`, `night`, `toggle`, `status` |
| `daynight` | Prints the scheduled mode. `<latitude> <longitude>` in a `location` file gives real sunrise and sunset, otherwise day runs 07:00 to 18:30 |
| `pillar/` | `pillar.mjs bake` turns the column pieces and a seeded ivy plant into the data texture the bar's `Pillar.qml` animates through `shell/shaders/pillar.frag`. `pillar.mjs render` paints the wallpaper and the lock ground. After editing the shader, run `/usr/lib64/qt6/bin/qsb --glsl "300 es,330" -o shell/shaders/pillar.frag.qsb shell/shaders/pillar.frag`. Test with `python3 pillar/test/pillar-e2e.py` |
| `shell/` | The Quickshell bar, Todoist agenda, Notion meetings, panels, and Nina (bar button with a live level meter, quick and full panels). Run with `qs -p ~/.config/hypr/shell`, test with `node --test shell/test/*.test.mjs`, `python3 shell/test/todoist-e2e.py`, `python3 shell/test/calendar-e2e.py`, `python3 shell/test/activity-e2e.py`, `python3 shell/test/overseer-e2e.py`, `python3 shell/test/desktop-e2e.py`, and `python3 shell/test/nina-e2e.py` |
| `lock`, `screenshot`, `browser`, `autostart` | Helpers the binds call |
| `td` | Runs the Todoist CLI for the bar under whichever fnm Node has it |

`qs -p ~/.config/hypr/shell ipc call panel toggle <activity|audio|display|network|bluetooth|power|calendar|events>` opens a panel from a bind.

## Ported from KDE

- Keyboard repeat and the MX Master 3S pointer settings (flat acceleration, natural scroll).
- Default browser and file associations come from the shared `mimeapps.list`.
- Apps in `~/.config/autostart` start with the session. The Notion Calendar entry still points at a removed AppImage and needs re-adding from Helium.
- `XDG_CURRENT_DESKTOP` is `Hyprland:KDE`, so Chromium-based apps (Helium, Chrome, Slack, Discord) keep decrypting their saved logins from kwallet6 as they did under Plasma. Portals still resolve `hyprland-portals.conf` first. kwallet asks for its password once per session.
- Day and night switch the AlturaDay and AlturaNight color schemes, written into `kdeglobals` for Qt apps. Kitty follows through its auto theme files.
- Neovim (lean-vim, `~/.config/nvim`) reads `generated/colors.lua` and switches as soon as `theme` rewrites it. Without that file it keeps One Dark and follows the portal. Test with `python3 test/nvim-theme-e2e.py`.

## Optional packages

`quickshell` is required for the bar. `sudo dnf install awww cliphist` adds the wallpaper daemon (falls back to a solid color otherwise) and clipboard history. `swaybg` works as a wallpaper fallback too.

Packages come from Fedora and the restricted [sdegler/hyprland COPR](https://copr.fedorainfracloud.org/coprs/sdegler/hyprland/). The COPR allowlist is in `/etc/yum.repos.d/hyprland-restricted.repo`, and portal configuration lives in `~/.config/xdg-desktop-portal/`.
