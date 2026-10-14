local ADDON, ns = ...
local unpack = unpack or table.unpack
local WHITE = "Interface\\Buttons\\WHITE8X8"

local function Frame(value)
    local kind = type(value)
    if kind == "table" or kind == "userdata" then return value.frame or value.widget or value end
end
local function Regions(C, frame)
    for _, region in ipairs(C.H.Regions(frame)) do
        local kind = region.GetObjectType and region:GetObjectType()
        if kind == "FontString" then
            local r, g, b, a = region:GetTextColor()
            C.S.Font(region, r, g, b)
            region:SetTextColor(r, g, b, a)
        elseif kind == "Texture" then
            local name = region.GetName and region:GetName() or ""
            -- Spell/class icons only: keep range, death and severity indicators native.
            if name:find("Icon") and C.H.Texture(region) then C.S.SquareIcon(region) end
        end
    end
end
local function BuffButton(C, button)
    if not button or type(button.GetObjectType) ~= "function" or button:IsForbidden()
        or InCombatLockdown and InCombatLockdown() then return end
    -- This path deliberately does not scan or install script/method hooks on
    -- protected controls. Only cosmetic regions and existing backdrops change.
    Regions(C, button)
    local backdrop = button.GetBackdrop and button:GetBackdrop()
    if backdrop and button.SetBackdrop and (backdrop.bgFile ~= WHITE or backdrop.edgeFile ~= WHITE or backdrop.edgeSize ~= 1) then
        local color = button.GetBackdropColor and {button:GetBackdropColor()}
        button:SetBackdrop({bgFile = WHITE, edgeFile = WHITE, edgeSize = 1,
            insets = {left = 1, right = 1, top = 1, bottom = 1}})
        if color and button.SetBackdropColor then button:SetBackdropColor(unpack(color)) end
        if button.SetBackdropBorderColor then button:SetBackdropBorderColor(0.055, 0.055, 0.055, 1) end
    end
end

ns.RegisterScopedSkin("PallyPower", "PallyPower", {
    softBorders = true, preserveTextColors = true, immediateShow = true,
    borderlessButtons = function(frame)
        local name = frame.GetName and frame:GetName() or ""
        return name:find("^PallyPowerBlessingsFrame") ~= nil
    end,
    available = function() return type(_G.PallyPower) == "table" end,
    hooks = function(C, refresh)
        local P = _G.PallyPower
        for _, method in ipairs({"OnInitialize", "CreateLayout", "UpdateLayout", "ApplySkin", "OnProfileChanged", "OpenConfigWindow"}) do
            C.H.Hook(P, method, C.RefreshNow)
        end
        for _, name in ipairs({"PallyPowerBlessings_Toggle", "PallyPowerBlessings_Refresh"}) do C.H.Hook(_G, name, C.RefreshNow) end
        local dialog = LibStub and LibStub("AceConfigDialog-3.0", true)
        C.H.Hook(dialog, "Open", function(_, app) if app == "PallyPower" then C.RefreshNow() end end)
        if ns.BindPopupOwner then ns.BindPopupOwner(C.S, C.module, P.menuFrame or _G.PallyPowerMenuFrame) end
    end,
    roots = function(C)
        local P, roots, seen = _G.PallyPower, {}, {}
        local function Add(value, mode, options)
            local frame = Frame(value)
            if C.H.Allowed(frame) and not seen[frame] then
                seen[frame] = true; roots[#roots + 1] = {frame = frame, mode = mode, options = options}
            end
        end
        Add(_G.PallyPowerBlessingsFrame, nil, {noTopBar = true, noAccent = true})
        Add(_G.PallyPowerConfigFrame, nil, {noTopBar = true})
        Add(P.configFrame, nil, {noTopBar = true})
        Add(P.optionsFrame, "controls")
        local dialog = LibStub and LibStub("AceConfigDialog-3.0", true)
        Add(dialog and dialog.OpenFrames and dialog.OpenFrames.PallyPower, nil, {noTopBar = true})
        C.titleBar = P.titleBar or _G.PallyPowerTitleBar
        if C.H.Allowed(C.titleBar) then Add(C.titleBar, "controls") end
        -- Never shell/scan the secure buff hierarchy or its Forever flyout covers.
        BuffButton(C, P.autoButton or _G.PallyPowerAuto)
        BuffButton(C, P.rfButton or _G.PallyPowerRF)
        BuffButton(C, P.auraButton or _G.PallyPowerAura)
        for _, button in pairs(P.classButtons or {}) do BuffButton(C, button) end
        for _, players in pairs(P.playerButtons or {}) do
            for _, button in pairs(players) do BuffButton(C, button) end
        end
        if C.titleBar and not C.H.Allowed(C.titleBar) then BuffButton(C, C.titleBar) end
        return roots
    end,
    visit = function(C, frame, kind)
        local H, S = C.H, C.S
        if frame == C.titleBar then
            C.Panel(frame); ns.AttachAccent(S, frame)
            if frame.text then local r, g, b = S.GetAccentColor(); H.Font(frame.text, r, g, b) end
            return true
        end
        local name = frame.GetName and frame:GetName() or ""
        if name:find("^PallyPowerBlessingsFrame") then
            -- Native class/aura divider textures are artwork, not shell borders.
            for _, region in ipairs(H.Regions(frame)) do
                local regionName = region.GetName and region:GetName() or ""
                if H.Texture(region) and regionName:find("Line$") then H.Fade(region) end
            end
            if kind == "Button" and frame.SetBackdrop then frame:SetBackdrop(nil) end
        end
        if name == "PallyPowerBlessingsFrameTitle" then
            Regions(C, frame); return true -- Keep drag, credits tooltip and native grid update.
        end
        if kind == "Slider" then H.LegacySlider(frame); return true end
        if kind == "Button" and name:find("CloseButton$") then S.CloseButton(frame); return true end
        if kind == "Button" and name:find("Resize$") then H.Resize(frame, true); return true end
        if kind == "Button" then
            local keep = {"Text", "text"}
            local count = 0
            for _, region in ipairs(H.Regions(frame)) do
                local regionName = region.GetName and region:GetName() or ""
                if H.Texture(region) and regionName:find("Icon") then
                    count = count + 1
                    local key = "euiPallyIcon" .. count
                    frame[key] = region; keep[#keep + 1] = key
                    S.SquareIcon(region)
                end
            end
            if count > 0 then H.Action(frame, keep); return true end
        end
    end,
})
