# rice

My Hyprland setup on Fedora 44, living next to a Plasma install: Lua config for Hyprland 0.56, a Quickshell bar with panels, and day and night themes that switch at sunrise and sunset.

## Install

```sh
git clone https://github.com/vaporwavie/rice.git ~/.config/hypr
```

The repo replaces `~/.config/hypr`, so move an existing one out of the way first. Then adjust what is specific to my machine:

- `hyprlock.conf` sources `/home/powerstation/.config/hypr/generated/hyprlock.conf`. Change the home directory.
- The `DP-1` line in `hyprland.lua` sets a 4K monitor at scale 1.5. Every other output falls back to its preferred mode.
- The pointer settings in `hyprland.lua` target an MX Master 3S.

Run `./theme auto` once to render `generated/`, which is gitignored.

It expects `quickshell`, `kitty`, `fuzzel`, `dunst`, `hypridle`, `hyprlock`, `grim`, `slurp`, `wl-clipboard`, `jq`, `playerctl`, `nmcli`, `wpctl`, and `ddcutil`. See [Optional packages](#optional-packages) for the rest.

## Sign in

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

```
┌──────────────────────────────────────────────────────────────────────────────────────────┐
│ 1 2 3 4  active window           14:32  standup in 12m   cpu mem net bt dsp vol pwr tray │
├──────────────────────────────────────────────────────────────────────────────────────────┤
│                                  ┌────────────────────┐           ┌────────────────────┐ │
│ ┌────────────────────────────────│ calendar panel     │───────────│ notifications,     │ │
│ │ kitty                          │ (click the clock)  │           │ meeting toast      │ │
│ │                                │                    │           │                    │ │
│ │                                │                    │           └────────────────────┘ │
│ │                                │                    │                                │ │
│ │                                └────────────────────┘  Helium                        │ │
│ │                                         │  │                                         │ │
│ │                                         │  └─────────────────────────────────────────┘ │
│ │                                         │                                              │
│ │                                         │  ┌─────────────────────────────────────────┐ │
│ │                                         │  │ Dolphin                                 │ │
│ │                                         │  │                                         │ │
│ │                                         │  │                                         │ │
│ │                                  ┌────────────────┐                                  │ │
│ │                                  │ Nina overlay   │                                  │ │
│ │                                  └────────────────┘                                  │ │
│ └─────────────────────────────────────────┘  └─────────────────────────────────────────┘ │
│                                                                                          │
└──────────────────────────────────────────────────────────────────────────────────────────┘
```

The bar sits on top. Clicking the clock, the next event, network, Bluetooth, display, audio, or power opens a panel under that item, and tray icons open their menus the same way. Windows tile with dwindle, 10px outer gaps and 5px between them.

| Path | Role |
| --- | --- |
| `hyprland.lua` | Entry point. Requires `binds.lua` and `rules.lua`, starts `session-start`, runs `theme auto` every five minutes |
| `theme` | Renders `themes/*.env` through `templates/` into `generated/` and reloads what changed. Takes `auto`, `day`, `night`, `toggle`, `status` |
| `daynight` | Prints the scheduled mode. `<latitude> <longitude>` in a `location` file gives real sunrise and sunset, otherwise day runs 07:00 to 18:30 |
| `shell/` | The Quickshell bar, panels, meeting toast, and Nina overlay. Run with `qs -p ~/.config/hypr/shell`, test with `node --test shell/test/*.test.mjs` |
| `lock`, `screenshot`, `browser`, `autostart` | Helpers the binds call |

`qs -p ~/.config/hypr/shell ipc call panel toggle <audio|display|network|bluetooth|power|calendar|events>` opens a panel from a bind.

## Ported from KDE

- Keyboard repeat and the MX Master 3S pointer settings (flat acceleration, natural scroll).
- Default browser and file associations come from the shared `mimeapps.list`.
- Apps in `~/.config/autostart` start with the session. The Notion Calendar entry still points at a removed AppImage and needs re-adding from Helium.
- `XDG_CURRENT_DESKTOP` is `Hyprland:KDE`, so Chromium-based apps (Helium, Chrome, Slack, Discord) keep decrypting their saved logins from kwallet6 as they did under Plasma. Portals still resolve `hyprland-portals.conf` first. kwallet asks for its password once per session.
- Day and night switch on the same GrokDay and GrokNight palettes as Plasma and Kitty.

## Optional packages

`quickshell` is required for the bar. `sudo dnf install swww cliphist` adds the wallpaper daemon (falls back to a solid color otherwise) and clipboard history. `swaybg` works as a wallpaper fallback too.

Packages come from Fedora and the restricted [sdegler/hyprland COPR](https://copr.fedorainfracloud.org/coprs/sdegler/hyprland/). Its allowlist is in `/etc/yum.repos.d/hyprland-restricted.repo`. Plasma's default is set in `/etc/plasmalogin.conf.d/90-plasma-default.conf`. Desktop-specific portal files are in `~/.config/xdg-desktop-portal/`.
