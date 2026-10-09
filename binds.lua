return function(ctx)
    local home, cfg, has = ctx.home, ctx.cfg, ctx.has
    local mod = "SUPER"
    local terminal = home .. "/.local/bin/kitty"
    local launcher = "fuzzel --config=" .. cfg .. "/generated/fuzzel.ini"
    local function shell(call) return hl.dsp.exec_cmd("qs -p " .. cfg .. "/shell ipc call " .. call) end
    local function panel(name) return shell("panel toggle " .. name) end

    -- One-shot submap: a listed key runs its action and leaves, anything else just leaves.
    local function oneshot(name, actions)
        hl.define_submap(name, function()
            for key, action in pairs(actions) do
                hl.bind(key, function()
                    hl.dispatch(hl.dsp.submap("reset"))
                    hl.dispatch(action)
                end, { ignore_mods = true })
            end
            -- Release binds consume modifier presses before catchall.
            for _, key in ipairs({ "Super_L", "Super_R", "Shift_L", "Shift_R", "Control_L", "Control_R", "Alt_L", "Alt_R" }) do
                hl.bind(key, hl.dsp.no_op(), { ignore_mods = true, release = true })
            end
            hl.bind("Escape", hl.dsp.submap("reset"), { ignore_mods = true })
            hl.bind("catchall", hl.dsp.submap("reset"), { ignore_mods = true })
        end)
    end

    -- Apps
    hl.bind(mod .. " + Return", hl.dsp.exec_cmd(terminal))
    hl.bind(mod .. " + space", hl.dsp.exec_cmd(launcher))
    hl.bind("ALT + space", hl.dsp.exec_cmd(launcher))
    hl.bind("ALT + F2", hl.dsp.exec_cmd(launcher))
    hl.bind(mod .. " + E", hl.dsp.exec_cmd("nautilus --new-window"))
    hl.bind(mod .. " + B", hl.dsp.exec_cmd(cfg .. "/browser"))
    hl.bind(mod .. " + Page_Down", panel("keevy"))

    -- Panels: Super+A, then a letter.
    hl.bind(mod .. " + A", hl.dsp.submap("panels"))
    oneshot("panels", {
        C = panel("calendar"), E = panel("events"), A = panel("audio"), D = panel("display"),
        B = panel("bluetooth"), N = panel("network"), I = panel("activity"), K = panel("keevy"),
        P = panel("power"), M = panel("nina"), H = panel("nina-full"),
        J = shell("events join"), X = shell("events dismiss"),
    })

    -- Session
    hl.bind(mod .. " + Escape", hl.dsp.exec_cmd(cfg .. "/lock"))
    hl.bind(mod .. " + SHIFT + E", panel("power"))
    hl.bind(mod .. " + SHIFT + T", hl.dsp.exec_cmd(cfg .. "/theme toggle"))

    -- Windows
    hl.bind(mod .. " + SHIFT + Q", hl.dsp.window.kill())
    hl.bind(mod .. " + Q", hl.dsp.window.close())
    hl.bind("ALT + F4", hl.dsp.window.close())
    hl.bind(mod .. " + CTRL + Escape", hl.dsp.window.kill())
    hl.bind(mod .. " + F", hl.dsp.window.fullscreen({ mode = "maximized" }))
    hl.bind(mod .. " + SHIFT + F", hl.dsp.window.fullscreen({ mode = "fullscreen" }))
    hl.bind(mod .. " + V", hl.dsp.window.float({ action = "toggle" }))
    hl.bind(mod .. " + P", hl.dsp.window.pin({ action = "toggle" }))
    hl.bind(mod .. " + C", hl.dsp.window.center())
    hl.bind(mod .. " + T", hl.dsp.layout("togglesplit"))
    hl.bind(mod .. " + G", hl.dsp.group.toggle())
    hl.bind(mod .. " + SHIFT + G", hl.dsp.submap("join-group"))
    local join = {}
    for key, direction in pairs({ L = "left", R = "right", U = "up", D = "down" }) do
        join[key] = hl.dsp.window.move({ into_group = direction })
    end
    oneshot("join-group", join)
    hl.bind(mod .. " + bracketright", hl.dsp.group.next())
    hl.bind(mod .. " + bracketleft", hl.dsp.group.prev())
    -- Steps in stable id order so the bar's window tabs (shell/windows.js) show exactly where Alt+Tab lands.
    local function cycle(step)
        local current = hl.get_active_window()
        local workspace = current and current.workspace or hl.get_active_workspace()
        if not workspace then return end
        local targets = {}
        for _, window in ipairs(hl.get_workspace_windows(workspace)) do
            if window.mapped and not window.hidden then table.insert(targets, window) end
        end
        if #targets == 0 then return end
        table.sort(targets, function(a, b) return a.stable_id < b.stable_id end)
        local index = 0
        for i, window in ipairs(targets) do
            if current and window.address == current.address then index = i end
        end
        if index == 0 then index = step > 0 and 0 or 1 end
        local target = targets[(index - 1 + step) % #targets + 1]
        hl.dispatch(hl.dsp.focus({ window = target }))
        hl.dispatch(hl.dsp.window.bring_to_top())
    end
    hl.bind("ALT + Tab", function() cycle(1) end)
    hl.bind("ALT + SHIFT + Tab", function() cycle(-1) end)

    -- Focus, swap, resize
    local directions = { left = "left", right = "right", up = "up", down = "down", H = "left", L = "right", K = "up", J = "down" }
    for key, direction in pairs(directions) do
        local focus_mod = (key == "H" or key == "L") and (mod .. " + CTRL") or mod
        hl.bind(focus_mod .. " + " .. key, hl.dsp.focus({ direction = direction }))
        hl.bind(mod .. " + SHIFT + " .. key, hl.dsp.window.swap({ direction = direction }))
    end
    local resize = { left = { -40, 0 }, right = { 40, 0 }, up = { 0, -40 }, down = { 0, 40 } }
    for key, direction in pairs(directions) do
        local delta = resize[direction]
        hl.bind(mod .. " + ALT + " .. key, hl.dsp.window.resize({ x = delta[1], y = delta[2], relative = true }), { repeating = true })
    end

    -- Workspaces
    for workspace = 1, 10 do
        local key = workspace % 10
        hl.bind(mod .. " + " .. key, hl.dsp.focus({ workspace = workspace }))
        hl.bind(mod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = workspace }))
    end
    hl.bind(mod .. " + L", hl.dsp.focus({ workspace = "e+1" }))
    hl.bind(mod .. " + H", hl.dsp.focus({ workspace = "e-1" }))
    hl.bind(mod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
    hl.bind(mod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))
    hl.bind(mod .. " + Tab", hl.dsp.focus({ workspace = "previous" }))
    -- Tapping Super twice clears the screen to an empty desktop; Escape or another double tap returns.
    local desktop = "name:desktop"
    local away_from = nil
    local armed = 0
    local function on_desktop()
        local ws = hl.get_active_workspace()
        return ws and ws.name == "desktop"
    end
    local function leave_desktop()
        hl.dispatch(hl.dsp.focus({ workspace = away_from or "previous" }))
        away_from = nil
    end
    hl.bind("Super_L", function()
        armed = armed + 1
        if armed == 1 then
            hl.timer(function() armed = 0 end, { timeout = 350, type = "oneshot" })
            return
        end
        armed = 0
        if on_desktop() then
            leave_desktop()
        else
            local ws = hl.get_active_workspace()
            away_from = ws and ws.id or nil
            hl.dispatch(hl.dsp.focus({ workspace = desktop }))
        end
    end, { release = true, ignore_mods = true })
    hl.bind("Escape", function()
        if on_desktop() then leave_desktop() end
    end, { non_consuming = true })
    hl.bind(mod .. " + S", hl.dsp.workspace.toggle_special("scratch"))
    hl.bind(mod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:scratch", silent = true }))

    -- Mouse
    hl.bind(mod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
    hl.bind(mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

    -- Zoom
    local zoom = 1.0
    local function set_zoom(factor)
        zoom = math.max(1.0, math.min(4.0, factor))
        hl.config({ cursor = { zoom_factor = zoom } })
    end
    hl.bind(mod .. " + equal", function() set_zoom(zoom * 1.25) end)
    hl.bind(mod .. " + minus", function() set_zoom(zoom / 1.25) end)
    hl.bind(mod .. " + CTRL + 0", function() set_zoom(1.0) end)

    -- Screenshots
    hl.bind("Print", hl.dsp.exec_cmd(cfg .. "/screenshot region"))
    hl.bind("ALT + SHIFT + 4", hl.dsp.exec_cmd(cfg .. "/screenshot region"))
    hl.bind("SHIFT + Print", hl.dsp.exec_cmd(cfg .. "/screenshot screen"))
    hl.bind(mod .. " + Print", hl.dsp.exec_cmd(cfg .. "/screenshot window"))

    -- Clipboard history
    if has("cliphist") then
        hl.bind(mod .. " + SHIFT + V", hl.dsp.exec_cmd("sh -c 'cliphist list | " .. launcher .. " --dmenu --width 60 | cliphist decode | wl-copy'"))
    end

    -- Notifications
    hl.bind(mod .. " + N", hl.dsp.exec_cmd("dunstctl close"))
    hl.bind(mod .. " + SHIFT + N", hl.dsp.exec_cmd("dunstctl close-all"))
    hl.bind(mod .. " + grave", hl.dsp.exec_cmd("dunstctl history-pop"))
    hl.bind(mod .. " + CTRL + N", hl.dsp.exec_cmd("dunstctl context"))

    -- Media
    hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
    hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"), { locked = true, repeating = true })
    hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true })
    hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), { locked = true })
    hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
    hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
    hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
    hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })
    hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("qs -p " .. cfg .. "/shell ipc call display brightness 5"), { locked = true, repeating = true })
    hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("qs -p " .. cfg .. "/shell ipc call display brightness -5"), { locked = true, repeating = true })
end
