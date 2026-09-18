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
        bg = "141414", bg_alt = "1c1c1c", bg_elev = "262626", border = "2c2c2c",
        fg = "e1e1e1", fg_dim = "8c8c8c", muted = "6c6c6c",
        accent = "7aa2f7", accent_alt = "bb9af7", red = "f7768e", green = "9ece6a", yellow = "e0af68", cyan = "7dcfff",
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

-- Flat: square corners, solid 2px borders, no blur, no shadows, a hair of transparency.
local active_border = rgb(colors.accent)
local inactive_border = rgba(colors.muted, "aa")

hl.config({
    general = {
        gaps_in = 5,
        gaps_out = 10,
        border_size = 2,
        col = {
            active_border = active_border,
            inactive_border = inactive_border,
        },
        resize_on_border = true,
        extend_border_grab_area = 10,
        allow_tearing = false,
        layout = "dwindle",
        snap = { enabled = true },
    },
    decoration = {
        rounding = 0,
        shadow = { enabled = false },
        blur = { enabled = false },
        dim_special = 0.3,
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
        font_family = "Geist Mono",
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

-- Short, decelerating curves.
hl.curve("easeOutQuint", { type = "bezier", points = { { 0.23, 1 }, { 0.32, 1 } } })
hl.curve("quick", { type = "bezier", points = { { 0.15, 0 }, { 0.1, 1 } } })
hl.curve("linear", { type = "bezier", points = { { 0, 0 }, { 1, 1 } } })

hl.animation({ leaf = "global", enabled = true, speed = 10, bezier = "default" })
hl.animation({ leaf = "border", enabled = true, speed = 3, bezier = "easeOutQuint" })
hl.animation({ leaf = "windows", enabled = true, speed = 2.5, bezier = "easeOutQuint" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 2.5, bezier = "easeOutQuint", style = "popin 87%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 1.2, bezier = "linear", style = "popin 87%" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 2.5, bezier = "easeOutQuint" })
hl.animation({ leaf = "fade", enabled = true, speed = 2, bezier = "quick" })
hl.animation({ leaf = "fadeIn", enabled = true, speed = 1.5, bezier = "quick" })
hl.animation({ leaf = "fadeOut", enabled = true, speed = 1.2, bezier = "linear" })
hl.animation({ leaf = "fadeSwitch", enabled = false })
hl.animation({ leaf = "layers", enabled = true, speed = 2.5, bezier = "easeOutQuint" })
hl.animation({ leaf = "layersIn", enabled = true, speed = 2.5, bezier = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "layersOut", enabled = true, speed = 1.2, bezier = "linear", style = "fade" })
hl.animation({ leaf = "fadeLayersIn", enabled = true, speed = 1.5, bezier = "quick" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 1.2, bezier = "linear" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 2, bezier = "easeOutQuint", style = "slide" })
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 2, bezier = "easeOutQuint", style = "slidevert" })
hl.animation({ leaf = "zoomFactor", enabled = true, speed = 3, bezier = "easeOutQuint" })

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
