local ADDON, ns = ...

ns.RegisterScopedSkin("GTFO", "GTFO", {
    softBorders = true,
    available = function() return type(_G.GTFO) == "table" end,
    preserveTextColors = true,
    roots = function(C)
        local roots = {}
        for _, name in ipairs({"GTFO_MainFrame", "GTFO_IgnoreOptionsFrame"}) do
            local frame = _G[name]
            if C.H.Allowed(frame) then
                -- These are canvas categories inside Blizzard's settings window.
                -- Keep the host's geometry instead of adding another window shell.
                ns.AttachAccent(C.S, frame)
                roots[#roots + 1] = {frame = frame, mode = "controls"}
            end
        end
        return roots
    end,
    hooks = function(C, refresh)
        C.H.Hook(_G, "GTFO_RenderOptions", refresh)
        C.H.Hook(_G, "GTFO_RefreshOptions", refresh)
    end,
    visit = function(C, f, kind)
        if kind == "Slider" then C.H.LegacySlider(f); return true end
    end,
})
