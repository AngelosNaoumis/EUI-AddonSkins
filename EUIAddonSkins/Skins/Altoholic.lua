local ADDON, ns = ...
ns.RegisterScopedSkin("Altoholic", "Altoholic", {
    available = function() return _G.Altoholic ~= nil end,
    roots = function() return ns.SkinRoots({"AltoholicFrame", "AltoMessageBox"}, {bottomBar = 24}) end,
    hooks = function(C, refresh)
        for _, method in ipairs({"SwitchToTab", "SetTabs", "ToggleUI"}) do C.H.Hook(_G.AltoholicFrame, method, refresh) end
    end,
    visit = function(C, f, kind)
        local main = _G.AltoholicFrame
        if kind == "Button" and main then
            for index, tab in ipairs(main.Tabs or {}) do
                if f == tab then return C.H.Tab(f, main.selectedTab == index) end
            end
        end
        if f.icon and f.icon.GetObjectType and f.icon:GetObjectType() == "Texture" then
            local path = f.icon.GetTexture and f.icon:GetTexture()
            if type(path) == "string" and path:lower():find("interface[/\\]icons") then C.S.SquareIcon(f.icon) end
        end
    end,
})
