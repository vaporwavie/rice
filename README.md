# Hyprland

Log out. At the bottom left of the login screen, click the text `Desktop Session: Plasma`, choose Hyprland, and sign in. The text is a button even though it has no dropdown arrow. Plasma remains preselected on later visits to the login screen.

## Keys

| Shortcut | Action |
| --- | --- |
| Super+Enter | Kitty |
| Super+Space, Alt+Space, Alt+F2 | App launcher |
| Super+E | Dolphin |
| Super+B | Default browser |
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

Omarchy-style: square corners, solid 2px accent borders, no blur or shadows, a flat opaque bar in Geist Mono, bordered cards for the bar panels, launcher, notifications, and the lock field. Windows are opaque. Workspace switches use a short horizontal slide.

## Layout

Configuration lives in this directory. Hyprland reads `hyprland.lua`, which requires `binds.lua` and `rules.lua` and starts `session-start`. Display scale is the `scale` value on the DP-1 line in `hyprland.lua` (1.5, a 2560x1440 logical desktop). Bar, launcher, and notification font sizes are in logical pixels, so bump them when lowering the scale.

- `theme` renders `themes/day.env` or `themes/night.env` through `templates/` into `generated/` (Hyprland colors, shell palette, Waybar colors, Fuzzel, Dunst, Hyprlock) and reloads whatever changed. It also sets the wallpaper, the GTK and portal color scheme, and the Plasma color scheme, so Kitty, Helium, and Qt apps follow. `theme auto` follows the schedule, `day`, `night`, and `toggle` hold until the next scheduled switch, `status` prints the current mode. Hyprland runs `theme auto` every five minutes.
- `daynight` prints the scheduled mode. Put `<latitude> <longitude>` in a `location` file here for real sunrise and sunset. Without it, day runs 07:00 to 18:30.
- `session-start` starts `hyprland-session.target` (which the portals require), the bar, Dunst, Hypridle, KDE's authentication agent, gnome-keyring, clipboard history when cliphist is installed, and the entries in `~/.config/autostart`.
- `shell/` is the Quickshell bar (`qs -p ~/.config/hypr/shell`). Workspaces and the active window on the left, the clock and the next event of the day in the middle, CPU, memory, network, Bluetooth, display, audio, power, and the tray on the right. Clicking the clock, network, Bluetooth, display, audio, or power icons opens a panel under the icon: calendar, connections (up and down, Wi-Fi radio, Wi-Fi networks), Bluetooth devices, monitor brightness, contrast, color preset and input over DDC/CI (`ddcutil`, scrolling the icon or XF86MonBrightness keys step brightness), sinks and sources with volume and mute, and the session menu. Tray icons open their menus in the same style. Colors come from `generated/shell-colors.json`, so `theme` recolors it in place. `qs -p ~/.config/hypr/shell ipc call panel toggle <audio|display|network|bluetooth|power|calendar|events>` opens a panel from a bind.
- `shell/NotionCalendar.qml` reads `~/.config/notion-calendar-linux/panel.json`, the feed Notion Calendar Linux (`~/Documents/Codex/2026-09-11/mak/outputs/notion-calendar-linux`) writes every 15 s while it runs. `shell/NextEvent.qml` shows today's next event and its countdown beside the clock, accent colored in the last five minutes, hidden when nothing is left today or the feed is older than 90 s. Clicking it opens `shell/EventsPanel.qml`, the upcoming events grouped by day, and middle click opens the app. The parsing lives in `shell/calendar-feed.mjs`, tested with `node --test shell/test/*.test.mjs`. `qs -p ~/.config/hypr/shell ipc call events state` prints the feed state.
- `shell/NinaOverlay.qml` is Nina's recording panel as a layer-shell surface, bottom center of the focused monitor, red border and level bars while recording, amber while transcribing. `shell/Nina.qml` follows `$XDG_RUNTIME_DIR/nina.sock` (`watch` stream, reconnects every 5 s while Nina is down). Nina itself runs with Overlay set to Hide and On launch set to Stay hidden. `qs -p ~/.config/hypr/shell ipc call nina state` prints the connection and overlay state.
- `waybar/` is the previous bar, kept until the Quickshell one has survived a full day-night cycle.
- `wallpapers/` holds the day and night images, `hypridle.conf` the lock and screen-off timers.
- `lock`, `screenshot`, `browser`, and `autostart` are the helpers the binds call.

## Ported from KDE

- Keyboard repeat and the MX Master 3S pointer settings (flat acceleration, natural scroll).
- Default browser and file associations come from the shared `mimeapps.list`.
- Apps in `~/.config/autostart` start with the session. The Notion Calendar entry still points at a removed AppImage and needs re-adding from Helium.
- `XDG_CURRENT_DESKTOP` is `Hyprland:KDE`, so Chromium-based apps (Helium, Chrome, Slack, Discord) keep decrypting their saved logins from kwallet6 as they did under Plasma. Portals still resolve `hyprland-portals.conf` first. kwallet asks for its password once per session.
- Day and night switch on the same GrokDay and GrokNight palettes as Plasma and Kitty.

## Optional packages

`quickshell` is required for the bar. `sudo dnf install swww cliphist` adds the wallpaper daemon (falls back to a solid color otherwise) and clipboard history. `swaybg` works as a wallpaper fallback too.

Packages come from Fedora and the restricted [sdegler/hyprland COPR](https://copr.fedorainfracloud.org/coprs/sdegler/hyprland/). Its allowlist is in `/etc/yum.repos.d/hyprland-restricted.repo`. Plasma's default is set in `/etc/plasmalogin.conf.d/90-plasma-default.conf`. Desktop-specific portal files are in `~/.config/xdg-desktop-portal/`.
