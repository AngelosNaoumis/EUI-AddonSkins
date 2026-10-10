local ADDON, ns = ...
ns.RegisterModule("RXPGuides", "RestedXP Guides", function()
    return _G.RXP and type(_G.RXP.LoadActiveTheme) == "function"
end, function(S, module)
    local addon = _G.RXP
    local H = ns.CreateSkinHelper(S)
    local refresh
    local targetSeen
    local copies, wrapped = setmetatable({}, {__mode = "k"}), {}
    local unpack = unpack or table.unpack
    local function Copy(t)
        local out = {}; for k, v in pairs(t or {}) do out[k] = v end; return out
    end
    local function Theme(source)
        if type(source) ~= "table" then return source end
        local out = copies[source]
        if not out then out = Copy(source); copies[source] = out end
        local r, g, b = S.GetAccentColor()
        local pr, pg, pb, pa = S.GetPanelColor()
        out.font = S.GetFont()
        -- Session copies leave registered themes, saved choices and semantic colors intact.
        if source.backgroundColors then
            out.backgroundColors = Copy(source.backgroundColors)
            for _, key in ipairs({"common", "guideName", "guideWindow", "scrollbar", "inactivePartyTab", "activeStepCheckbox"}) do
                out.backgroundColors[key] = {pr, pg, pb, pa}
            end
            out.backgroundColors.activeStepCheckboxChecked = {r, g, b, 1}
            out.borderColors = Copy(source.borderColors)
            for _, key in ipairs({"common", "commonEdge", "inactivePartyTab"}) do
                out.borderColors[key] = {0.2, 0.2, 0.22, 1}
            end
            out.borderColors.activeStepCheckboxChecked = {r, g, b, 1}
            out.textColor = Copy(source.textColor)
            out.textColor.common = {0.9, 0.9, 0.92, 1}
            out.textColor.title = {r, g, b, 1}
            out.textColor.inactivePartyTab = {0.65, 0.65, 0.68, 1}
            out.edge = Copy(source.edge)
            out.edge.edgeFile = "Interface/Buttons/WHITE8X8"
            out.edge.edgeSize = 1
            out.edge.texCoords = {top = {0, 1, 0, 1}, bottom = {0, 1, 0, 1}, left = {0, 1, 0, 1}, right = {0, 1, 0, 1}}
        else
            out.background = {pr, pg, pb, pa}
            out.bottomFrameBG = {pr, pg, pb, pa}
            out.bottomFrameHighlight = {r, g, b, 1}
            out.textColor = {0.9, 0.9, 0.92}
        end
        return out
    end
    local function Wrap(object, name, legacy)
        if not object or wrapped[object] or type(object[name]) ~= "function" then return end
        wrapped[object] = true
        local original = object[name]
        object[name] = function(...)
            local function Pack(...) return {n = select("#", ...), ...} end
            local result = Pack(original(...))
            if ns.IsEnabled() and type(result[1]) == "table" then
                result[1] = Theme(result[1])
                object.activeTheme = result[1]
                if legacy then
                    addon.colors, addon.font = result[1], result[1].font
                    local f = addon.RXPFrame or _G.RXPFrame
                    for _, key in ipairs({"edge", "guideName", "bottom"}) do
                        local backdrop = f and f.backdrop and f.backdrop[key]
                        if backdrop then
                            backdrop.bgFile = "Interface/Buttons/WHITE8X8"
                            backdrop.edgeFile = key ~= "bottom" and "Interface/Buttons/WHITE8X8" or nil
                            backdrop.edgeSize = 1
                            -- RXP's original 8px artwork used asymmetric 2-4px
                            -- fill insets. Match the fill to our thin border.
                            local inset = key ~= "bottom" and 1 or 0
                            backdrop.insets = {left = inset, right = inset, top = inset, bottom = inset}
                        end
                    end
                end
            end
            return unpack(result, 1, result.n)
        end
    end
    local function TintBackdrop(f)
        if InCombatLockdown and InCombatLockdown() then return end
        if not f or (f.IsForbidden and f:IsForbidden()) then return end
        if f.GetBackdrop and f.SetBackdropBorderColor then
            local backdrop = f:GetBackdrop()
            if backdrop and backdrop.edgeFile then f:SetBackdropBorderColor(0.2, 0.2, 0.22, 1) end
            H.Hook(f, "SetBackdrop", refresh)
        end
    end
    local function Scan(f)
        if H.Allowed(f) then H.Scan(f, refresh, TintBackdrop) end
    end
    local function CombatLocked()
        return InCombatLockdown and InCombatLockdown()
    end
    local function TargetFrame()
        return addon.targeting and addon.targeting.activeTargetFrame
    end
    local function ApplyTargets()
        local f = TargetFrame()
        if not f or CombatLocked() or (f.IsForbidden and f:IsForbidden()) then return end
        -- The container has secure action-button children. Only touch its visual
        -- backdrop/title outside combat; never scan or skin those buttons.
        if targetSeen ~= f then
            targetSeen = f
            if f.UpdateVisuals then H.Safe(f.UpdateVisuals, f) end
            H.Hook(f, "UpdateVisuals", refresh)
        end
        TintBackdrop(f)
        TintBackdrop(f.title)
        local r, g, b = S.GetAccentColor()
        H.Font(f.title and f.title.text, r, g, b)
    end
    local function Apply()
        Wrap(addon.v2, "GetTheme")
        local legacy = addon.RXPFrame or _G.RXPFrame
        if legacy then
            Scan(legacy)
            -- Secure children may make the guide root implicitly protected. Tint
            -- only the known visual containers, without entering action buttons.
            for _, key in ipairs({"BottomFrame", "GuideName", "Footer"}) do TintBackdrop(legacy[key]) end
            for _, step in pairs(legacy.CurrentStepFrame and legacy.CurrentStepFrame.framePool or {}) do
                TintBackdrop(step)
                TintBackdrop(step.number)
            end
            H.Hook(legacy, "UpdateVisuals", refresh)
            H.Fade(legacy.GuideName and legacy.GuideName.bg)
            H.Fade(legacy.Footer and legacy.Footer.bg)
        end
        -- Inspect only existing widgets; GetGuideWindow would create one eagerly.
        local window = addon.v2 and addon.v2.state and addon.v2.state.guideWindow or _G.RXPV2GuideWindow
        if window then
            Scan(window.frame)
            H.Fade(window.banner)
            H.Hook(window, "UpdateTheme", refresh)
            H.Hook(window, "UpdateSubTheme", refresh)
            H.Hook(window, "RefreshLayout", refresh)
            local r, g, b = S.GetAccentColor()
            H.Font(window.title, r, g, b)
            if window.closebutton and H.Allowed(window.closebutton) then S.CloseButton(window.closebutton) end
        end
        ApplyTargets()
        local importer = addon.guideImporter
        if importer then
            for _, widget in pairs(importer.widgets or {}) do
                if type(widget) == "table" then Scan(widget.frame) end
            end
            H.Hook(importer, "UpdateTheme", refresh)
        end
    end
    refresh = function() H.Queue(module, Apply) end
    local function UpdateTheme()
        if not ns.IsEnabled() or CombatLocked() then return end
        if addon.settings and addon.settings.profile and addon.RXPFrame then
            H.Safe(addon.LoadActiveTheme, addon)
            -- Refresh visuals directly; RenderFrame also reloads the current guide.
            if addon.RXPFrame.UpdateVisuals then H.Safe(addon.RXPFrame.UpdateVisuals, addon.RXPFrame, true) end
        end
        local window = addon.v2 and addon.v2.state and addon.v2.state.guideWindow or _G.RXPV2GuideWindow
        if window and window.UpdateTheme then H.Safe(window.UpdateTheme, window, {updateChildren = true}) end
        if addon.v2 and addon.v2.UpdateActiveStepTheme and addon.v2.state and addon.v2.state.player and addon.player then
            H.Safe(addon.v2.UpdateActiveStepTheme, addon.v2)
        end
        if addon.guideImporter and addon.guideImporter.UpdateTheme then H.Safe(addon.guideImporter.UpdateTheme, addon.guideImporter) end
        local target = TargetFrame()
        if target and not CombatLocked() and target.UpdateVisuals then H.Safe(target.UpdateVisuals, target) end
        refresh()
    end
    Wrap(addon, "LoadActiveTheme", true)
    Wrap(addon.v2, "GetTheme")
    for _, name in ipairs({"RenderFrame", "LoadGuide", "SetStep"}) do H.Hook(addon, name, refresh) end
    for _, name in ipairs({"GetGuideWindow", "UpdateGuideWindow", "UpdateActiveStepTheme"}) do H.Hook(addon.v2, name, refresh) end
    if addon.ui and addon.ui.v2 then H.Hook(addon.ui.v2, "CreateGuideImporter", refresh) end
    for _, name in ipairs({"CreateTargetFrame", "RenderTargetFrameBackground", "UpdateTargetFrame"}) do
        H.Hook(addon.targeting, name, refresh)
    end
    local combatEvents = CreateFrame("Frame")
    combatEvents:RegisterEvent("PLAYER_REGEN_ENABLED")
    combatEvents:SetScript("OnEvent", function() UpdateTheme() end)
    module.refresh = UpdateTheme
    if S.OnLooksChanged then S.OnLooksChanged(UpdateTheme) end
    UpdateTheme()
end)
