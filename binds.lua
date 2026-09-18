return function(ctx)
    local home, cfg, has = ctx.home, ctx.cfg, ctx.has
    local mod = "SUPER"
    local terminal = home .. "/.local/bin/kitty"
    local launcher = "fuzzel --config=" .. cfg .. "/generated/fuzzel.ini"

    -- Apps
    hl.bind(mod .. " + Return", hl.dsp.exec_cmd(terminal))
    hl.bind(mod .. " + space", hl.dsp.exec_cmd(launcher))
    hl.bind("ALT + space", hl.dsp.exec_cmd(launcher))
    hl.bind("ALT + F2", hl.dsp.exec_cmd(launcher))
    hl.bind(mod .. " + E", hl.dsp.exec_cmd("dolphin"))
    hl.bind(mod .. " + B", hl.dsp.exec_cmd(cfg .. "/browser"))
    hl.bind(mod .. " + Page_Down", hl.dsp.exec_cmd("qs -p " .. cfg .. "/shell ipc call panel toggle keevy"))

    -- Session
    hl.bind(mod .. " + CTRL + L", hl.dsp.exec_cmd(cfg .. "/lock"))
    hl.bind(mod .. " + SHIFT + E", hl.dsp.exec_cmd("qs -p " .. cfg .. "/shell ipc call panel toggle power"))
    hl.bind(mod .. " + SHIFT + T", hl.dsp.exec_cmd(cfg .. "/theme toggle"))

    -- Windows
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
    hl.bind(mod .. " + bracketright", hl.dsp.group.next())
    hl.bind(mod .. " + bracketleft", hl.dsp.group.prev())
    hl.bind("ALT + Tab", function()
        hl.dispatch(hl.dsp.window.cycle_next())
        hl.dispatch(hl.dsp.window.bring_to_top())
    end)
    hl.bind("ALT + SHIFT + Tab", function()
        hl.dispatch(hl.dsp.window.cycle_next({ direction = "prev" }))
        hl.dispatch(hl.dsp.window.bring_to_top())
    end)

    -- Focus, swap, resize
    local directions = { left = "left", right = "right", up = "up", down = "down", H = "left", L = "right", K = "up", J = "down" }
    for key, direction in pairs(directions) do
        local focus_mod = (key == "left" or key == "right") and (mod .. " + CTRL") or mod
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
    hl.bind(mod .. " + right", hl.dsp.focus({ workspace = "e+1" }))
    hl.bind(mod .. " + left", hl.dsp.focus({ workspace = "e-1" }))
    hl.bind(mod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
    hl.bind(mod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))
    hl.bind(mod .. " + Tab", hl.dsp.focus({ workspace = "previous" }))
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
