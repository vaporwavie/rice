# Quickshell bar and panels

Replace Waybar with a Quickshell bar whose icons open in-shell panels, the way omarchy-shell does, while keeping the current look (flat, Geist Mono, 2px accent borders, GrokDay/GrokNight day-night switching). No omarchy apps, no omarchy-shell code copied wholesale. Reference copy of the omarchy repo (MIT, commit 9c5482c, 2026-09-16) is at `~/.cache/omarchy-ref`, shell under `shell/`.

## State (2026-09-16, evening)

Steps 1 to 9 are done, the shell is live. Left: step 10 (memory) is done too, and the Waybar cleanup in step 8 waits for a full day-night cycle (remove `waybar/`, `templates/waybar-colors.css.in`, the `render waybar-colors.css` and `pkill -USR2 -x waybar` lines in `theme`, and the Waybar line in README).

- Hyprland 0.56.2 Lua config in `~/.config/hypr`, README.md there is current. Scale 1.25 on DP-1.
- `theme` renders `templates/*.in` into `generated/` from `themes/{day,night}.env` and reloads consumers. Any new consumer gets a template plus a reload line in `theme`.
- Quickshell 0.2.1 (Fedora `quickshell-0.2.1^git20260209`) is installed. Modules present: Bluetooth, Hyprland, Io, Networking, Wayland, Widgets, Services/{Pipewire,SystemTray,Mpris,Notifications,UPower,Pam,Polkit,Greetd}.
- Deviations from the decisions below, all verified in a nested session and live: colors are `generated/shell-colors.json` read through `FileView` (a `.qml` palette would need an engine reload), the `theme` script also pokes `qs ipc call theme reload`. `Quickshell.Networking` 0.2.1 models Wi-Fi devices only (`DeviceType` is None or Wifi, no wired devices, no connection profiles), so the network panel lists NetworkManager connections through `nmcli` (`Nm.qml` singleton, `nmcli monitor` for refresh) and uses the native module only for the Wi-Fi radio and network list. Bluetooth panel is in (adapter `box`). Unknown secured Wi-Fi networks get a password field that runs `nmcli device wifi connect`, untested here (Wi-Fi is rfkill-blocked on this machine).
- Untested: hover tooltips and the Wi-Fi password field (no way to drive the pointer or keyboard from the agent). Tray menus were tested with nm-applet's menu via `ipc call panel toggle tray:nm-applet`.
- Waybar quirks that motivated this: `hyprland/workspaces` renders nothing on Hyprland 0.56, `ext/workspaces` has no state icons, bar clicks open GNOME/KDE apps.

## Decisions

- Whole bar in Quickshell, Waybar removed from `session-start` once the bar is at parity. One process, one style source.
- Config lives in `~/.config/hypr/shell/` (Quickshell config dir passed with `qs -p ~/.config/hypr/shell`). Colors come from a generated `generated/shell-colors.qml` (a QtObject with the palette) written by `theme` from a new `templates/shell-colors.qml.in`, and the shell reloads it via Quickshell's `FileView` watcher or the IPC `qs ipc call theme reload`. Never hardcode hex in QML.
- Backends: Pipewire for audio (`Quickshell.Services.Pipewire`), NetworkManager over `nmcli` through `Quickshell.Io.Process` (omarchy does the same; `Quickshell.Networking` exists in newer Quickshell, check if 0.2.1 has it), `Quickshell.Services.SystemTray` for the tray, `Quickshell.Hyprland` for workspaces and the active window (events over socket2 still work on 0.56; dispatches must use Lua syntax, e.g. `Hyprland.dispatch('hl.dsp.focus({ workspace = 3 })')`).
- Panels (in priority order): audio (sink and source pick, volume, mute), network (connections list, connect and disconnect, Wi-Fi off/on), power (lock, suspend, logout, reboot, power off, replaces the `logout` fuzzel menu), clock calendar. Bluetooth only if `bluetoothctl` shows an adapter.
- Fonts and metrics match `waybar/style.css`: Geist Mono 14px logical, bar 30px, icons from JetBrainsMono Nerd Font, accent underline for the active workspace. Panels: opaque `bg`, 2px `accent` border, no radius, 10px padding, rows 28px.
- Keep Dunst, Fuzzel, Hyprlock. Notifications and launcher move into Quickshell only if the panels land cleanly and there is appetite left.

## Steps

1. User: `sudo dnf install quickshell`. Agent: verify `qs --version`, list available `Quickshell.*` imports, run the Quickshell hello example in a nested Hyprland (recipe below) to confirm layer-shell works with 0.56.
2. Bar skeleton: `shell/shell.qml` with a `PanelWindow` top, exclusive zone, three rows (workspaces + title, clock, status icons + tray). Colors from `generated/shell-colors.qml`. Screenshot in nested session, compare with Waybar side by side.
3. Workspaces and active window via `Quickshell.Hyprland`. Click focuses with the Lua dispatch string. Verify events on 0.56 (workspace add, remove, focus, title change).
4. Audio panel. Icon toggles the panel anchored under it. Content: default sink volume slider, mute, sink list, source list with mute. Wire to `wpctl` only as a fallback.
5. Network panel: `nmcli -t -f NAME,TYPE,DEVICE,STATE connection show`, active marked, click to `nmcli connection up/down`, Wi-Fi radio toggle. Refresh on `nmcli monitor` output.
6. Power panel, then clock calendar. Delete `logout` script and rebind `Super+Shift+E` to the panel's IPC toggle.
7. Tray via `Quickshell.Services.SystemTray` with menus.
8. Swap in: `session-start` starts `qs -p "$here/shell"` instead of Waybar; `theme` writes `generated/shell-colors.qml` and pokes the shell. Remove `waybar/` and the Waybar reload line only after a full day-night cycle works.
9. README: replace the Waybar mentions, list the panels, note the Quickshell package.
10. Memory: update `hyprland-rice-powerstation.md` (bar is Quickshell now).

## Call tree diff

```diff
 Hyprland starts (hl.on "hyprland.start")
 └─ session-start
    ├─ theme auto
    │  ├─ render generated/colors.lua, waybar-colors.css, fuzzel.ini, dunstrc, hyprlock.conf
+   │  ├─ render generated/shell-colors.qml
+   │  └─ qs ipc call theme reload (when the shell is running)
-   ├─ waybar -c waybar/config.jsonc -s waybar/style.css
+   ├─ qs -p shell
+   │  ├─ bar PanelWindow
+   │  │  ├─ workspaces + title (Quickshell.Hyprland)
+   │  │  ├─ clock → calendar panel
+   │  │  └─ audio icon → audio panel (Pipewire)
+   │  │     network icon → network panel (nmcli Process)
+   │  │     power icon → power panel
+   │  │     tray (SystemTray)
    ├─ dunst, hypridle, nm-applet, polkit agent, autostart
    └─ wait
 Super+Shift+E
-└─ logout (fuzzel dmenu)
+└─ qs ipc call power toggle
```

## Verification

- Nested session: `WAYLAND_DISPLAY=wayland-1 HYPRLAND_SETUP_TEST=1 hyprland --config <test.lua>`, find its socket with `hyprctl instances -j`, export `HYPRLAND_INSTANCE_SIGNATURE` and `WAYLAND_DISPLAY` for it, run `qs` inside, `grim` a screenshot, read the PNG. The Bash tool's own `WAYLAND_DISPLAY=wayland-0` is stale, the live one is `wayland-1`.
- Live: after swapping, `hyprctl configerrors` empty, `theme toggle` recolors the bar and panels without restart, both `theme night` and `theme day` screenshots reviewed, then `rm generated/override && theme auto`.
- Every panel: open, act, close, no orphan processes (`pgrep -a nmcli`).

## Gotchas

- Never `pkill -f <string>` from the Bash tool with a string that also appears in the command line; it kills the tool's own shell. Kill by PID or `pkill -x`.
- Fresh Lua modules on reload need `package.loaded[name] = nil` (already in `hyprland.lua`).
- `XDG_CURRENT_DESKTOP=Hyprland:KDE` is deliberate (kwallet6 for Chromium apps). Quickshell may read it; check that it does not pick Qt's KDE platform theme in a way that fights the palette (`QT_QPA_PLATFORMTHEME=kde` is set session-wide, override for `qs` with `QT_QPA_PLATFORMTHEME=` if fonts or colors look off).
- Dunst offset `(10, 10)` assumes a 30px top bar exclusive zone; keep the bar height or move the offset.
- `nm-applet` was dropped from `session-start` on 2026-09-16 (its tray icon duplicated the shell's network icon). Editing profiles is `nm-connection-editor` from the launcher.

## Resume

New session: read this file, `~/.config/hypr/README.md`, and the memory `hyprland-rice-powerstation`. If a full day-night cycle has passed with the Quickshell bar (check `generated/current` flipped since 2026-09-16 evening and the bar still looks right), do the Waybar cleanup listed under State. Nested test helper from the last session: start a nested Hyprland, then `qs -p ~/.config/hypr/shell` with that instance's `HYPRLAND_INSTANCE_SIGNATURE` and `WAYLAND_DISPLAY`, drive panels with `qs -p ~/.config/hypr/shell ipc call panel toggle <name>`, screenshot with `grim`. Quickshell hides `console.log`; use `console.warn`. A hand-written `qmldir` in `shell/` hides the sibling types, let Quickshell synthesize it. Do not name a singleton `Network`, it clashes with `Quickshell.Networking`.
