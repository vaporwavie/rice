return function(ctx)
    local function rule(match, props)
        props.match = type(match) == "table" and match or { class = match }
        return hl.window_rule(props)
    end

    rule(".*", { suppress_event = "maximize" })
    rule(".*", { idle_inhibit = "fullscreen" })
    rule({ class = "^$", title = "^$", xwayland = true, float = true, fullscreen = false, pin = false }, { no_focus = true })

    rule("((google-)?[cC]hrom(e|ium)|helium|[bB]rave-browser|crx_.*)", { tag = "+browser" })
    rule("([fF]irefox|zen|librewolf)", { tag = "+browser" })

    rule({ title = "(Picture.?in.?[Pp]icture)" }, { tag = "+pip" })
    rule({ tag = "pip" }, {
        float = true,
        pin = true,
        size = "600 338",
        keep_aspect_ratio = true,
        border_size = 0,
        move = "(monitor_w-window_w-40) (monitor_h*0.04)",
    })

    rule("^(nm-connection-editor|pavucontrol|blueman-manager|org\\.kde\\.polkit-kde-authentication-agent-1|xdg-desktop-portal-kde|xdg-desktop-portal-gtk|localsend|software\\.altura\\.keevy|org\\.kde\\.ksecretd)$", { tag = "+floating-window" })
    rule({ title = "^(Open File|Open Folder|Open Files|Save File|Save As|Choose Files|File Upload|Select a File|Select Folder)$" }, { tag = "+floating-window" })
    rule({ tag = "floating-window" }, { float = true })
    rule({ tag = "floating-window" }, { center = true })
    rule({ tag = "floating-window" }, { size = "875 600" })

    hl.layer_rule({ name = "selection-still", match = { namespace = "^(selection)$" }, no_anim = true })
    hl.layer_rule({ name = "wallpaper-still", match = { namespace = "^(wallpaper|awww-daemon)$" }, no_anim = true })

    hl.workspace_rule({ workspace = "special:scratch", gaps_out = 60, on_created_empty = ctx.terminal })
end
