local ADDON, ns = ...

local function Frame(item)
    local kind = type(item)
    if kind == "table" or kind == "userdata" then return item.frame or item end
end
local function Font(S, text, r, g, b)
    if type(text._SetFont) ~= "function" then return S.Font(text, r, g, b) end
    -- Gargul overloads SetFont(rem, flags). Use its saved native method without
    -- replacing that wrapper or changing its scale, text markup or callbacks.
    local _, size = text:GetFont()
    local path, flags = S.GetFont()
    text:_SetFont(path, size or 12, flags or "")
    if r ~= nil then text:SetTextColor(r, g, b) end
end

ns.RegisterScopedSkin("Gargul", "Gargul", {
    available = function() return type(_G.Gargul) == "table" and type(_G.Gargul.Interface) == "table" end,
    font = function(S, text, r, g, b)
        local cr, cg, cb, ca
        if r == nil and text.GetTextColor then cr, cg, cb, ca = text:GetTextColor() end
        Font(S, text, r, g, b)
        if cr then text:SetTextColor(cr, cg, cb, ca) end
    end,
    roots = function(C)
        C.windows = C.windows or setmetatable({}, {__mode = "k"})
        C.scopes = C.scopes or setmetatable({}, {__mode = "k"})
        local roots, added = {}, {}
        local function Add(item)
            local f = Frame(item)
            if C.H.Allowed(f) and not added[f] then added[f] = true; roots[#roots + 1] = {frame = f} end
        end
        local function Items(t, depth)
            if type(t) ~= "table" or depth > 4 then return end
            for key, item in pairs(t) do
                local f = Frame(item)
                if C.H.Allowed(f) then
                    if key == "Window" or item.type == "Frame" or f:GetObjectType() == "Frame" and f:GetParent() == UIParent then Add(item) end
                elseif type(item) == "table" then Items(item, depth + 1) end
            end
        end
        local seen = {}
        local function Scopes(t, depth)
            if type(t) ~= "table" or seen[t] or depth > 6 or C.H.Allowed(Frame(t)) then return end
            seen[t] = true
            Items(t.InterfaceItems, 0)
            for _, value in pairs(t) do if type(value) == "table" then Scopes(value, depth + 1) end end
        end
        Scopes(_G.Gargul.Interface, 0)
        for scope in pairs(C.scopes) do Items(scope.InterfaceItems, 0) end
        Items(_G.Gargul.MasterLooterUI and _G.Gargul.MasterLooterUI.InterfaceItems, 0)
        for f in pairs(C.windows) do Add(f) end
        local ui = _G.Gargul.UI
        for _, f in pairs(ui and ui.components or {}) do
            if C.H.Allowed(f) and f:GetObjectType() == "Frame" and f:GetParent() == UIParent then Add(f) end
        end
        for _, name in ipairs({"GARGUL_SETTING_WINDOW", "GargulUI_RollerUI_Window", "GARGUL_GDKP_BIDDER_WINDOW"}) do Add(_G[name]) end
        return roots
    end,
    hooks = function(C, refresh)
        C.windows = C.windows or setmetatable({}, {__mode = "k"})
        C.scopes = C.scopes or setmetatable({}, {__mode = "k"})
        local interface = _G.Gargul.Interface
        C.H.Hook(interface, "set", function(_, scope)
            if type(scope) == "table" then C.scopes[scope] = true end
            refresh()
        end)
        C.H.Hook(interface, "createWindow", function(_, details)
            local f = type(details) == "table" and _G[details.name]
            if C.H.Allowed(f) then C.windows[f] = true end
            refresh()
        end)
        C.H.Hook(interface, "addMinimizeButton", function(_, window)
            if C.H.Allowed(window.Minimized) then C.windows[window.Minimized] = true end
            refresh()
        end)
        for _, name in ipairs({"AceGUIDefaults", "createDropdown", "addWindowOptions", "release"}) do C.H.Hook(interface, name, refresh) end
        C.H.Hook(_G.Gargul.UI, "createFrame", refresh)
    end,
    visit = function(C, f, kind, refresh)
        local H, S = C.H, C.S
        for _, text in ipairs(H.Regions(f)) do
            if text:GetObjectType() == "FontString" and type(text._SetFont) == "function" then
                H.Hook(text, "SetFont", refresh)
            end
        end
        if kind == "StatusBar" then return true end -- Countdown values/colours are owned by Gargul.
        if kind == "Slider" then H.LegacySlider(f); return true end
        if kind == "EditBox" and type(f._SetFont) == "function" then
            S.Font(f)
            H.Hook(f, "SetFont", refresh)
            if not (f.IsMultiLine and f:IsMultiLine()) then S.EditBox(f, {padInput = true}) end
            return true
        end
        if type(f.initialize) == "function" then C.MenuOwner(f); S.Dropdown(f) end
        local widget = f.obj
        if widget and widget.frame == f then
            if widget.closebtn and H.Allowed(widget.closebtn) then H.Action(widget.closebtn) end
            if widget.sizer_se then H.Resize(widget.sizer_se, true) end
            if widget.type == "Icon" and H.Texture(widget.image) then S.SquareIcon(widget.image); return true end
            if widget.type == "TabGroup" then
                for _, tab in pairs(widget.tabs or {}) do if H.Allowed(tab) then H.Tab(tab, tab.selected and true or false) end end
                H.Hook(widget, "SelectTab", refresh)
            end
        end
        if kind == "Button" then
            if H.Allowed(f.MinimizeButton) then H.Toggle(f.MinimizeButton, true) end
            if H.Allowed(f.MaximizeButton) then H.Toggle(f.MaximizeButton, false) end
            H.Resize(f)
            local icon = H.Texture(f.Texture)
            if icon then
                H.Action(f, {"Texture", "Count", "IconBorder", "Cooldown"})
                S.SquareIcon(icon, f:GetWidth() == f:GetHeight() and f or nil)
                return true
            end
        end
    end,
})
