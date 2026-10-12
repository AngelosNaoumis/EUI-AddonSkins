local ADDON, ns = ...

local function Window() return _G.DBM_GUI_OptionsFrame end

ns.RegisterScopedSkin("DBM", "Deadly Boss Mods", {
    -- DBM-GUI is load-on-demand. Never force it to load just to apply a skin.
    available = function() return type(_G.DBM_GUI) == "table" and Window() ~= nil end,
    preserveTextColors = true,
    roots = function(C)
        local f = Window()
        local exclude = setmetatable({}, {__index = function(_, child)
            -- Font/warning previews and creature models show DBM's settings.
            return child:GetObjectType() == "ScrollingMessageFrame" or child.mytype == "modelframe"
        end})
        if f and f.searchHighlightFrame then exclude[f.searchHighlightFrame] = true end
        local roots = {}
        if C.H.Allowed(f) then roots[1] = {frame = f, options = {bottomBar = 36}, exclude = exclude} end
        -- Older DBM versions use a private popup instead of Blizzard's Menu API.
        local popup = _G.DBM_GUI_DropDown
        if C.H.Allowed(popup) then roots[#roots + 1] = {frame = popup, exclude = exclude} end
        return roots
    end,
    hooks = function(C, refresh)
        for _, name in ipairs({"CreateNewPanel", "CreateBossModPanel", "CreateDropdown"}) do
            C.H.Hook(_G.DBM_GUI, name, refresh)
        end
        for _, name in ipairs({"ShowTab", "DisplayFrame", "UpdateMenuFrame", "ClearSelection"}) do
            C.H.Hook(Window(), name, refresh)
        end
    end,
    visit = function(C, f, kind)
        local H, S = C.H, C.S
        local name = f.GetName and f:GetName() or ""
        if kind == "Slider" then H.LegacySlider(f); return true end
        if kind == "Button" then
            if name == "DBM_GUI_OptionsFrameClosePanelButton" then S.CloseButton(f); return true end
            local tab = tonumber(name:match("^DBM_GUI_OptionsFrameTab(%d+)$"))
            if tab then H.Tab(f, Window().tab == tab); return true end
            -- Do not fade or recolour DBM's colour-picker swatch textures.
            if type(f.SetColorRGB) == "function" then
                for _, region in ipairs(H.Regions(f)) do H.Font(region) end
                return true
            end
            if f.element and H.Allowed(f.toggle) then
                local window = Window()
                local page = window.tabs and window.tabs[window.tab]
                local selected = window.searchQuery and window.searchQuery ~= ""
                    and _G.DBM_GUI.currentViewing or page and page.selection
                H.Selection(f, selected == f.element)
                H.Toggle(f.toggle, f.element.showSub)
                return true
            end
            H.Resize(f)
        end
        if f.mytype == "dropdown" or f.mytype == "dropdown2" then
            S.Dropdown(f)
            return true
        end
        if f.mytype == "area" then C.Panel(f) end
    end,
})
