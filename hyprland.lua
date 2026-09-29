local home = os.getenv("HOME")
local cfg = home .. "/.config/hypr"
local testing = os.getenv("HYPRLAND_SETUP_TEST") == "1"

local function has(bin)
    return os.execute("command -v " .. bin .. " >/dev/null 2>&1") == true
end
local function rgb(hex) return "rgb(" .. hex .. ")" end
local function rgba(hex, alpha) return "rgba(" .. hex .. alpha .. ")" end

-- generated/colors.lua is written by ./theme; the fallback keeps a fresh checkout bootable.
local ok, colors = pcall(dofile, cfg .. "/generated/colors.lua")
if not ok then
    colors = {
        mode = "dark", bg = "000000", bg_alt = "0b0b0c", bg_elev = "151517", border = "171717", line_strong = "292929",
        fg = "e8e8e5", fg_dim = "8c8c89", muted = "57574f",
        accent = "f4f2ec", accent_alt = "e8e8e5", red = "d8826f", green = "a3b18a", yellow = "d6b370", cyan = "9fb7bd",
    }
end

------------------
---- MONITORS ----
------------------

hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" })
hl.monitor({ output = "DP-1", mode = "3840x2160@60", position = "0x0", scale = 1.5, vrr = 0 })

-----------------
---- SESSION ----
-----------------

-- KDE stays in the desktop list so Chromium-based apps keep reading their secrets from kwallet6,
-- the store they used under Plasma. Portals still resolve hyprland-portals.conf first.
hl.env("XDG_CURRENT_DESKTOP", "Hyprland:KDE")
hl.env("KDE_SESSION_VERSION", "6")
hl.env("XCURSOR_THEME", "breeze_cursors")
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("QT_QPA_PLATFORMTHEME", "kde")
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")
hl.env("QT_AUTO_SCREEN_SCALE_FACTOR", "1")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")
hl.env("GDK_BACKEND", "wayland,x11,*")
hl.env("NOTION_CALENDAR_MEETING_POPUP", "off")

if not testing then
    hl.on("hyprland.start", function()
        hl.exec_cmd(cfg .. "/session-start")
    end)
    hl.timer(function()
        hl.exec_cmd(cfg .. "/theme auto")
    end, { timeout = 300000, type = "repeat" })
end

-----------------------
---- LOOK AND FEEL ----
-----------------------

-- Altura: ink ground, hairline edges lit from above like the landing's top glow, no blur or shadow.
local lit = colors.mode == "light" and "0b0b0c" or "f4f2ec"
local active_border = { colors = { rgba(lit, "b3"), rgba(lit, "2e") }, angle = 90 }
local inactive_border = rgb(colors.line_strong or colors.border)
local group_active = rgba(lit, "b3")

hl.config({
    general = {
        gaps_in = 4,
        gaps_out = 8,
        border_size = 1,
        col = {
            active_border = active_border,
            inactive_border = inactive_border,
        },
        resize_on_border = true,
        extend_border_grab_area = 12,
        allow_tearing = false,
        layout = "dwindle",
        snap = { enabled = true },
    },
    decoration = {
        rounding = 0,
        shadow = { enabled = false },
        blur = { enabled = false },
        dim_special = 0.5,
    },
    animations = { enabled = true },
    group = {
        col = {
            border_active = active_border,
            border_inactive = inactive_border,
        },
        groupbar = { enabled = false },
    },
    misc = {
        disable_hyprland_logo = true,
        disable_splash_rendering = true,
        disable_scale_notification = true,
        background_color = rgb(colors.bg),
        font_family = "IBM Plex Mono",
        animate_manual_resizes = false,
        animate_mouse_windowdragging = false,
        focus_on_activate = true,
        on_focus_under_fullscreen = 1,
        initial_workspace_tracking = 0,
        key_press_enables_dpms = true,
        mouse_move_enables_dpms = true,
        middle_click_paste = false,
        disable_xdg_env_checks = true,
    },
})

-- One curve, the landing's ease-out-expo: things arrive fast and settle long, never bounce.
-- Entrances rise a few percent while fading in, the desktop version of the site's fadeUp.
hl.curve("expo", { type = "bezier", points = { { 0.16, 1 }, { 0.3, 1 } } })
hl.curve("exit", { type = "bezier", points = { { 0.7, 0 }, { 0.84, 0 } } })

hl.animation({ leaf = "global", enabled = true, speed = 6, bezier = "expo" })
hl.animation({ leaf = "border", enabled = true, speed = 6, bezier = "expo" })
hl.animation({ leaf = "windows", enabled = true, speed = 5, bezier = "expo" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 6, bezier = "expo", style = "popin 94%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 2.5, bezier = "exit", style = "popin 97%" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 5, bezier = "expo" })
hl.animation({ leaf = "fade", enabled = true, speed = 5, bezier = "expo" })
hl.animation({ leaf = "fadeIn", enabled = true, speed = 6, bezier = "expo" })
hl.animation({ leaf = "fadeOut", enabled = true, speed = 2.5, bezier = "exit" })
hl.animation({ leaf = "fadeSwitch", enabled = false })
hl.animation({ leaf = "fadeDim", enabled = true, speed = 6, bezier = "expo" })
hl.animation({ leaf = "layers", enabled = true, speed = 5, bezier = "expo" })
hl.animation({ leaf = "layersIn", enabled = true, speed = 5, bezier = "expo", style = "fade" })
hl.animation({ leaf = "layersOut", enabled = true, speed = 2, bezier = "exit", style = "fade" })
hl.animation({ leaf = "fadeLayersIn", enabled = true, speed = 5, bezier = "expo" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 2, bezier = "exit" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 3.5, bezier = "expo", style = "slide" })
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 3.5, bezier = "expo", style = "slidevert" })
hl.animation({ leaf = "zoomFactor", enabled = true, speed = 5, bezier = "expo" })

-----------------
---- LAYOUTS ----
-----------------

hl.config({
    dwindle = {
        preserve_split = true,
        smart_resizing = true,
        force_split = 2,
    },
    master = {
        new_status = "master",
    },
})

---------------
---- INPUT ----
---------------

hl.config({
    input = {
        kb_layout = "us",
        kb_options = "caps:escape",
        repeat_rate = 40,
        repeat_delay = 350,
        follow_mouse = 1,
        sensitivity = 0,
    },
    cursor = {
        inactive_timeout = 5,
        hide_on_key_press = true,
        warp_on_change_workspace = 1,
    },
    binds = {
        workspace_back_and_forth = true,
        allow_workspace_cycles = true,
        hide_special_on_workspace_change = true,
        scroll_event_delay = 150,
    },
    xwayland = {
        force_zero_scaling = true,
    },
    ecosystem = {
        no_update_news = true,
        no_donation_nag = true,
    },
})

-- Same pointer feel as the KDE session: flat acceleration, speed 0.6, natural scroll.
hl.device({
    name = "mx-master-3s",
    accel_profile = "flat",
    sensitivity = 0.6,
    natural_scroll = true,
    scroll_factor = 1.5,
})
hl.device({
    name = "logitech-mx-master-3s",
    accel_profile = "flat",
    sensitivity = 0.6,
    natural_scroll = true,
    scroll_factor = 1.5,
})

---------------------------
---- BINDS AND RULES ----
---------------------------

local ctx = { home = home, cfg = cfg, has = has, colors = colors, terminal = home .. "/.local/bin/kitty" }
for _, module in ipairs({ "binds", "rules" }) do
    package.loaded[module] = nil
    require(module)(ctx)
end
