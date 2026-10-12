local ADDON, ns = ...

local function Monitor(C)
    local H, S, window = C.H, C.S, _G.ThreatClassic2BarFrame
    if not H.Allowed(window) then return end
    local exclude = {}
    local function Text(text)
        if not H.Allowed(text) or text:GetObjectType() ~= "FontString" then return end
        C.painting = true
        H.Font(text)
        C.painting = false
        H.Hook(text, "SetFont", function() if not C.painting then C.module.refresh() end end)
    end
    -- Only appearance/profile changes trigger this walk. SetValue, threat events
    -- and the addon's combat OnUpdate are never hooked or replaced.
    for _, child in ipairs(H.Children(window)) do
        exclude[child] = true
        if H.Allowed(child) then
            if child:GetObjectType() == "StatusBar" then
                for _, region in ipairs(H.Regions(child)) do Text(region) end
                if H.Allowed(child.edgeBackdrop) then H.ThinBackdrop(child.edgeBackdrop) end
            end
        end
    end
    if H.Allowed(window.header) then ns.AttachAccent(S, window.header) end
    if H.Allowed(window.resize) then H.Resize(window.resize, true) end
    -- Keep the monitor's configured opacity and its grow-up/header geometry.
    if H.Texture(window.bg) and S.GetPanelColor then
        local _, _, _, alpha = window.bg:GetVertexColor()
        local r, g, b = S.GetPanelColor()
        window.bg:SetVertexColor(r, g, b, alpha)
    end
    return {frame = window, mode = "controls", exclude = exclude}
end

ns.RegisterScopedSkin("ThreatClassic2", "ThreatClassic2", {
    available = function() return _G.ThreatClassic2BarFrame ~= nil end,
    preserveTextColors = true,
    roots = function(C)
        local roots = {}
        local monitor = Monitor(C)
        if monitor then roots[1] = monitor end
        if LibStub then
            local dialog = LibStub("AceConfigDialog-3.0", true)
            local function Add(widget, embedded)
                local f = type(widget) == "table" and (widget.frame or widget)
                if C.H.Allowed(f) then
                    roots[#roots + 1] = {frame = f, mode = embedded and "controls" or nil}
                    if embedded then ns.AttachAccent(C.S, f) end
                end
            end
            Add(dialog and dialog.OpenFrames and dialog.OpenFrames.ThreatClassic2)
            local function Categories(t, depth)
                if type(t) ~= "table" or depth > 4 then return end
                if C.H.Allowed(t.frame or t) then Add(t, true); return end
                for _, value in pairs(t) do Categories(value, depth + 1) end
            end
            Categories(dialog and dialog.BlizOptions and dialog.BlizOptions.ThreatClassic2, 0)
        end
        return roots
    end,
    hooks = function(C, refresh)
        C.H.Hook(_G.ThreatClassic2BarFrame, "SetSize", refresh)
        if LibStub then
            local dialog = LibStub("AceConfigDialog-3.0", true)
            for _, name in ipairs({"FeedGroup", "AddToBlizOptions"}) do
                C.H.Hook(dialog, name, function(_, addon) if addon == "ThreatClassic2" then refresh() end end)
            end
        end
    end,
    visit = function(C, f, kind)
        if kind == "Slider" then C.H.LegacySlider(f); return true end
    end,
})
