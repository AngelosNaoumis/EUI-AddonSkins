local ADDON, ns = ...
local unpack = unpack or table.unpack
local MEDIA = "Interface\\AddOns\\EllesmereUIDamageMeters\\Media\\"

-- Use Details' controls and calculation/formatting APIs. This layer only owns
-- presentation; no actor values, click handlers or combat parser are replaced.
function ns.CreateDetailsLayout(H, active, defer, fade)
    local L, windows, originals = {}, {}, {}
    local function Plain(value) return not (issecretvalue and issecretvalue(value)) end
    local function Capture(f)
        if originals[f] then return originals[f] end
        local old = {points = {}, width = f.GetWidth and f:GetWidth(), height = f.GetHeight and f:GetHeight(), level = f.GetFrameLevel and f:GetFrameLevel()}
        for i = 1, f.GetNumPoints and f:GetNumPoints() or 0 do old.points[i] = {f:GetPoint(i)} end
        originals[f] = old
        return old
    end
    local function CanLayout(instance)
        if not active(instance) then return false end
        if InCombatLockdown and InCombatLockdown() then defer(); return false end
        return true
    end
    function L.Title(instance)
        local entry = windows[instance]
        if not entry or not active(instance) then return end
        local name = instance.GetInstanceAttributeText and instance:GetInstanceAttributeText()
        if not Plain(name) or type(name) ~= "string" then return end
        if entry.lastName ~= name then entry.name:SetText(name); entry.lastName = name end
        local combat = instance.GetShowingCombat and instance:GetShowingCombat()
            or instance.GetCombat and instance:GetCombat()
        local seconds = combat and combat.GetCombatTime and combat:GetCombatTime()
        local timer = ""
        if Plain(seconds) and type(seconds) == "number" and seconds >= 0 then
            seconds = math.floor(seconds)
            timer = string.format(" (%d:%02d)", math.floor(seconds / 60), seconds % 60)
        end
        if entry.lastTimer ~= timer then entry.timer:SetText(timer); entry.lastTimer = timer end
        if entry.name.GetStringWidth then
            local width = math.min(entry.available or 10000, entry.name:GetStringWidth())
            entry.timer:ClearAllPoints(); entry.timer:SetPoint("LEFT", entry.frame, "LEFT", 6 + width, 0)
        end
    end
    local buttons = {
        {"modo_selecao", "dm_settings.png"}, {"segmento", "dm_undo.png"},
        {"atributo", "dm_sheet.png"}, {"report", "dm_report.png"},
        {"reset", "dm_reset.png"}, {"novo", "dm_open.png"}, {"fechar", "dm_close.png"},
    }
    function L.Window(instance, look)
        if not CanLayout(instance) or not H.Allowed(instance.baseframe) then return end
        local f = instance.baseframe
        local entry = windows[instance]
        if not entry then
            entry = {controls = {}}; windows[instance] = entry
            entry.frame = CreateFrame("Frame", nil, f)
            entry.frame:SetPoint("BOTTOMLEFT", f, "TOPLEFT", 0, 0)
            entry.frame:SetPoint("BOTTOMRIGHT", f, "TOPRIGHT", 0, 0)
            entry.frame:SetFrameLevel(f:GetFrameLevel() + 3); entry.frame:EnableMouse(false)
            entry.bg = entry.frame:CreateTexture(nil, "BACKGROUND"); entry.bg:SetAllPoints(entry.frame)
            entry.name = entry.frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            entry.name:SetPoint("LEFT", entry.frame, "LEFT", 6, 0)
            entry.timer = entry.frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            entry.timer:SetPoint("LEFT", entry.name, "RIGHT", 0, 0)
        end
        entry.frame:Show(); entry.frame:SetHeight(look.headerHeight)
        local c = look.header; entry.bg:SetColorTexture(c.r or 0, c.g or 0, c.b or 0, look.headerAlpha)
        entry.name:SetFont(look.font, look.headerSize, look.flags)
        entry.timer:SetFont(look.font, look.headerSize, look.flags)
        entry.name:SetTextColor(unpack(look.titleColor)); entry.timer:SetTextColor(0.75, 0.75, 0.75, 1)
        local nativeTitle = instance.GetTitleBarFontString and instance:GetTitleBarFontString()
        if nativeTitle then fade(nativeTitle.widget or nativeTitle) end
        local header = f.cabecalho or {}
        fade(header.atributo_icon)
        for _, side in ipairs({"resize_direita", "resize_esquerda"}) do
            local grip = f[side]; if grip then fade(grip.texture) end
        end
        if f.lock_button then fade(f.lock_button.label) end
        local count = 0
        for i = #buttons, 1, -1 do
            local key, asset = buttons[i][1], buttons[i][2]
            local value = header[key]
            local button = value and (value.widget or value)
            -- Respect Details' choice of enabled/visible controls.
            if H.Allowed(button) and (not button.IsShown or button:IsShown()) then
                Capture(button)
                local control = entry.controls[button]
                if not control then
                    control = {}; entry.controls[button] = control
                    -- Details fades native button frames separately from their
                    -- hit areas. Keep our artwork on the owned header so those
                    -- fades cannot leave an invisible but hoverable control.
                    control.icon = entry.frame:CreateTexture(nil, "OVERLAY")
                    control.icon:SetPoint("CENTER", button, "CENTER", 0, 0)
                    H.Script(button, "OnEnter", function() if active(instance) then control.icon:SetVertexColor(1, 1, 1, 1) end end)
                    H.Script(button, "OnLeave", function() if active(instance) then control.icon:SetVertexColor(0.55, 0.55, 0.55, 1) end end)
                    H.Script(button, "OnHide", function()
                        control.icon:SetAlpha(0)
                        if active(instance) then defer() end
                    end)
                    H.Script(button, "OnShow", function()
                        if active(instance) then
                            control.icon:SetAlpha(control.hasMedia and 1 or 0)
                            defer()
                        end
                    end)
                end
                local hasMedia = C_AddOns and C_AddOns.IsAddOnLoaded and C_AddOns.IsAddOnLoaded("EllesmereUIDamageMeters")
                control.hasMedia = hasMedia
                -- Native toolbar setup may write width/height separately after
                -- our first pass. Artwork does not inherit those temporary sizes.
                control.icon:SetSize(look.iconSize, look.iconSize)
                if hasMedia then
                    control.icon:SetTexture(MEDIA .. asset); control.icon:SetVertexColor(0.55, 0.55, 0.55, 1); control.icon:SetAlpha(1)
                    for _, getter in ipairs({"GetNormalTexture", "GetHighlightTexture", "GetPushedTexture", "GetDisabledTexture"}) do
                        if button[getter] then fade(button[getter](button)) end
                    end
                    -- DF buttons draw the foreground image in their own texture.
                    for _, key in ipairs({"texture", "icon", "leftTexture", "rightTexture", "centerTexture"}) do fade(button[key]) end
                else control.icon:SetAlpha(0) end
                control.offset = 4 + count * (look.iconSize + 4)
                local function Align()
                    if control.aligning or not CanLayout(instance) then return end
                    control.aligning = true
                    button:ClearAllPoints(); button:SetSize(look.iconSize, look.iconSize)
                    button:SetFrameLevel(f:GetFrameLevel() + 7)
                    -- Independent anchors avoid a cycle when Details briefly restores
                    -- its own sibling-based button layout before our post-hook runs.
                    button:SetPoint("RIGHT", entry.frame, "RIGHT", -control.offset, 0)
                    control.aligning = false
                end
                -- The closure installed once reads current layout through this slot.
                control.align = Align
                if not control.hooked then
                    control.hooked = true
                    H.Hook(button, "SetPoint", function() control.align() end)
                    H.Hook(button, "SetSize", function() control.align() end)
                    H.Script(button, "OnSizeChanged", function() control.align() end)
                end
                Align(); count = count + 1
            end
        end
        -- Keep very narrow windows usable without crowding their controls.
        if entry.name.SetWidth and f.GetWidth then
            local width = math.max(0, f:GetWidth() - count * (look.iconSize + 4) - 65)
            entry.available = width
            entry.name:SetWidth(width)
            entry.name:SetAlpha(width > 0 and 1 or 0); entry.timer:SetAlpha(width > 0 and 1 or 0)
            if entry.name.SetWordWrap then entry.name:SetWordWrap(false) end
            if entry.name.SetJustifyH then entry.name:SetJustifyH("LEFT") end
        end
        L.Title(instance)
    end
    function L.Row(row)
        if not CanLayout() then return end
        for _, key in ipairs({"lineText4", "lineText14"}) do
            local text = row[key]
            if H.Allowed(text) and H.Allowed(row.statusbar) then
                Capture(text); text:ClearAllPoints(); text:SetPoint("RIGHT", row.statusbar, "RIGHT", -4, 0)
            end
        end
    end
    function L.Restore()
        for _, entry in pairs(windows) do
            entry.frame:Hide()
            for _, control in pairs(entry.controls) do control.icon:SetAlpha(0) end
        end
        -- Drop the entire custom anchor graph before rebuilding native links.
        for f in pairs(originals) do f:ClearAllPoints() end
        for f, old in pairs(originals) do
            for _, point in ipairs(old.points) do f:SetPoint(unpack(point)) end
            if old.width and old.height and f.SetSize then f:SetSize(old.width, old.height) end
            if old.level and f.SetFrameLevel then f:SetFrameLevel(old.level) end
        end
        originals = {}
    end
    return L
end
