local ADDON, ns = ...
local unpack = unpack or table.unpack
local WHITE = "Interface\\Buttons\\WHITE8X8"
local MEDIA_NAME = "EUI AddonSkins Meter"

local function Frame(value)
    if type(value) == "table" or type(value) == "userdata" then
        return value.widget or value.frame or value
    end
end

-- The meter module exposes its active profile/texture registry for its options.
-- Read them only when present; never require the module or mutate its profile.
local function Look(S)
    local EUI = _G.EllesmereUI or {}
    local db = _G._EDM_DB
    local cfg = db and db.profile and db.profile.dm or {}
    local font, flags = S.GetFont()
    if EUI.GetFontPath then font = EUI.GetFontPath("damageMeters") or font end
    if EUI.GetFontOutlineFlag then flags = EUI.GetFontOutlineFlag("damageMeters") or flags end
    local textures = _G._EDM_BarTextures
    if not textures and EUI.BuildBarTextureTables then textures = EUI.BuildBarTextureTables(true) end
    local texture = textures and textures[cfg.barTexture or "atrocity"] or WHITE
    if EUI.ResolveTexturePath and textures then
        texture = EUI.ResolveTexturePath(textures, cfg.barTexture or "atrocity", WHITE)
    end
    return {font = font, flags = flags or "", texture = texture or WHITE,
        height = cfg.barHeight or 18, spacing = cfg.barSpacing or 2,
        leftSize = cfg.leftFontSize or cfg.fontSize or 11,
        rightSize = cfg.rightFontSize or cfg.fontSize or 11,
        bg = {cfg.bgR or 0, cfg.bgG or 0, cfg.bgB or 0, cfg.bgAlpha or 0.75},
        header = cfg.hdrBgColor or {r = 27/255, g = 27/255, b = 27/255},
        headerAlpha = cfg.hdrBgAlpha or 1, headerHeight = cfg.hdrHeight or 22}
end

local function Setup(C, refresh)
    if C.details then return C.details end
    local S, H, D = C.S, C.H, _G.Details
    local state = {meters = {}, roots = {}, snapshots = {}, applying = false}
    C.details = state
    local function Busy()
        if InCombatLockdown and InCombatLockdown() then
            if not state.combatPending then state.combatPending = true; refresh() end
            return true
        end
    end
    local function Owned(frame)
        frame = Frame(frame)
        for _ = 1, 24 do
            if not H.Allowed(frame) then return false end
            if state.roots[frame] or state.meters[frame] then return true end
            frame = frame.GetParent and frame:GetParent()
        end
        return false
    end
    local function Row(row)
        if not H.Allowed(row) or Busy() then return end
        local look = state.look
        if not look then return end
        -- Only appearance: never read actor GUIDs, names, values or combat data.
        if H.Allowed(row.statusbar) and row.statusbar.SetStatusBarTexture then
            local texture = H.Texture(row.textura)
            if texture then
                if texture:GetTexture() ~= look.texture then texture:SetTexture(look.texture) end
            else row.statusbar:SetStatusBarTexture(look.texture) end
        end
        for _, key in ipairs({"lineText1", "lineText2", "lineText3", "lineText4",
            "lineText11", "lineText12", "lineText13", "lineText14"}) do
            local text = row[key]
            if H.Allowed(text) and text.SetFont and look.font then
                local size = (key == "lineText1" or key == "lineText11") and look.leftSize or look.rightSize
                local oldFont, oldSize, oldFlags = text:GetFont()
                if oldFont ~= look.font or oldSize ~= size or (oldFlags or "") ~= look.flags then
                    text:SetFont(look.font, size, look.flags)
                end
            end
        end
        -- Details owns class/spec atlas coordinates, highlights and row actions.
    end
    local function Rows(instance)
        if state.applying or not ns.IsEnabled(C.module) or Busy() then return end
        for _, row in pairs(instance.barras or {}) do Row(row) end
    end
    state.Row = Row
    state.Meter = function(instance)
        local f = instance and instance.baseframe
        if not H.Allowed(f) then return end
        local look = state.look
        local entry = state.meters[f]
        if not entry then
            entry = {}; state.meters[f] = entry
            local bg = CreateFrame("Frame", nil, f)
            bg:SetAllPoints(f); bg:SetFrameLevel(math.max(0, f:GetFrameLevel() - 1)); bg:EnableMouse(false)
            entry.bg = bg:CreateTexture(nil, "BACKGROUND"); entry.bg:SetAllPoints(bg)
            H.Script(f, "OnShow", refresh)
        end
        entry.bg:SetColorTexture(unpack(look.bg))
        -- Hide only named native decoration, never the frame, rows or buttons.
        for _, key in ipairs({"barra_esquerda", "barra_direita", "barra_fundo", "wallpaper"}) do H.Fade(f[key]) end
        local header = f.cabecalho or {}
        for _, key in ipairs({"ball", "ball_r", "emenda", "top_bg"}) do H.Fade(header[key]) end
        local title = f.titleBar
        if H.Allowed(title) then
            title:SetHeight(look.headerHeight)
            H.Fade(title.texture)
            if not entry.header then entry.header = title:CreateTexture(nil, "BACKGROUND"); entry.header:SetAllPoints(title) end
            local c = look.header; entry.header:SetColorTexture(c.r or 0, c.g or 0, c.b or 0, look.headerAlpha)
        end
        if f.SetBackdrop then f:SetBackdrop(nil) end
        if H.Allowed(instance.bgdisplay) and instance.bgdisplay.SetBackdrop then instance.bgdisplay:SetBackdrop(nil) end
        if H.Allowed(header.fechar) then S.CloseButton(header.fechar) end
        H.Font(instance.attribute_text)
        -- Native setters maintain Details' row geometry. Do not change window
        -- anchors, size, groups, segment, custom text, data or click scripts.
        local info = instance.row_info
        local media = LibStub and LibStub("LibSharedMedia-3.0", true)
        local textureName
        if media and media.Register then media:Register("statusbar", MEDIA_NAME, look.texture); textureName = MEDIA_NAME end
        if info and instance.SetBarSettings and (info.height ~= look.height
            or not info.space or info.space.between ~= look.spacing
            or textureName and info.texture ~= textureName) then
            state.applying = true
            H.Safe(instance.SetBarSettings, instance, look.height, textureName, nil, nil, nil, nil, nil, nil, nil, nil, look.spacing)
            state.applying = false
        end
        Rows(instance)
    end

    local function MenuTexts(frame, callback)
        for _, line in pairs(frame.Lines or {}) do
            if H.Allowed(line) then
                -- Cooltip fontstrings belong to the line's statusbar child,
                -- but are also exposed through these documented line fields.
                for _, key in ipairs({"leftText", "rightText"}) do
                    local text = line[key]
                    if H.Allowed(text) then callback(text) end
                end
            end
        end
    end
    -- Cooltip is shared with other addons: change its existing native backdrop
    -- only while owned by Details, and restore it on transfer or hiding.
    local function Restore(frame)
        local old = state.snapshots[frame]
        if not old then return end
        state.snapshots[frame] = nil
        frame:SetBackdrop(old.backdrop)
        frame:SetBackdropColor(unpack(old.color)); frame:SetBackdropBorderColor(unpack(old.border))
        for text, data in pairs(old.fonts) do text:SetFont(unpack(data)) end
    end
    local function Cooltip()
        local tip = _G.GameCooltip
        if not tip or Busy() then return end
        local owner = tip.GetOwner and tip:GetOwner()
        local owned = Owned(owner)
        for _, f in pairs({tip.frame1, tip.frame2}) do
            if H.Allowed(f) and f.SetBackdrop and f.GetBackdropColor and f.GetBackdropBorderColor then
                if not owned then Restore(f)
                else
                    if not state.snapshots[f] then
                        local old = {backdrop = f:GetBackdrop(), color = {f:GetBackdropColor()}, border = {f:GetBackdropBorderColor()}, fonts = {}}
                        state.snapshots[f] = old
                        MenuTexts(f, function(text)
                            local font, size, flags = text:GetFont()
                            if font then old.fonts[text] = {font, size, flags or ""} end
                        end)
                    end
                    f:SetBackdrop({bgFile = WHITE, edgeFile = WHITE, edgeSize = 1})
                    local r, g, b, a = S.GetPanelColor(); f:SetBackdropColor(r, g, b, a)
                    f:SetBackdropBorderColor(0.055, 0.055, 0.055, 1)
                    MenuTexts(f, function(text)
                        -- Pooled submenu lines can appear after the first show.
                        local old = state.snapshots[f]
                        if not old.fonts[text] then
                            local font, size, flags = text:GetFont()
                            if font then old.fonts[text] = {font, size, flags or ""} end
                        end
                        H.Font(text)
                    end)
                    H.Script(f, "OnHide", function() Restore(f) end)
                end
            end
        end
    end
    state.Cooltip = Cooltip
    state.Restore = Restore
    if D.CreateEventListener then
        state.listener = D:CreateEventListener()
        for _, event in ipairs({"DETAILS_STARTED", "DETAILS_INSTANCE_OPEN", "DETAILS_INSTANCE_SIZECHANGED", "DETAILS_PROFILE_APPLYED"}) do
            state.listener:RegisterEvent(event, function() if ns.IsEnabled(C.module) then refresh() end end)
        end
        state.listener:RegisterEvent("DETAILS_INSTANCE_NEWROW", function(_, _, row)
            if ns.IsEnabled(C.module) then H.Safe(Row, row) end
        end)
    end
    H.Hook(D, "InstanceRefreshRows", Rows)
    for _, name in ipairs({"ChangeSkin", "SetBarSettings", "SetBarTextSettings", "ApplyProfile", "CreateInstance"}) do
        H.Hook(D, name, function() if not state.applying then refresh() end end)
    end
    for _, name in ipairs({"OpenOptionsWindow", "InitializeOptionsWindow", "OpenBreakdownWindow", "OpenSpecificBreakdownWindow",
        "FastReportWindow", "SendReportWindow", "SendReportTextWindow", "Reportar"}) do
        H.Hook(D, name, C.RefreshNow)
    end
    return state
end

ns.RegisterScopedSkin("Details", "Details!", {
    available = function() return type(_G.Details) == "table" and type(_G.Details.GetAllInstances) == "function" end,
    softBorders = true, preserveTextColors = true, immediateShow = true,
    hooks = function(C, refresh)
        local state = Setup(C, refresh)
        local tip = _G.GameCooltip
        for _, name in ipairs({"ShowCooltip", "BuildCooltip", "BuildTooltip", "BuildTooltipSecondFrame", "SetHost"}) do
            C.H.Hook(tip, name, state.Cooltip)
        end
    end,
    roots = function(C)
        local state = C.details
        state.combatPending = false; state.look = Look(C.S)
        for _, instance in pairs(_G.Details:GetAllInstances() or {}) do state.Meter(instance) end
        local result = {}
        local function Add(value)
            local f = Frame(value)
            if C.H.Allowed(f) then
                state.roots[f] = true
                result[#result + 1] = {frame = f, options = {noTopBar = true}}
            end
        end
        for _, name in ipairs({"DetailsOptionsWindow", "DetailsPluginContainerWindow", "DetailsBreakdownWindow",
            "DetailsReportWindow", "DetailsCopyPasteFrame2"}) do Add(_G[name]) end
        Add(_G.Details.BreakdownWindowFrame); Add(_G.Details.janela_report)
        state.Cooltip()
        return result
    end,
    visit = function(C, f, kind, refresh)
        local H, S = C.H, C.S
        -- Preserve displayed values and semantic colours in breakdown bars.
        if kind == "StatusBar" then
            local texture = C.details.look.texture
            if f.SetStatusBarTexture then f:SetStatusBarTexture(texture) end
            for _, text in ipairs(H.Regions(f)) do H.Font(text) end
            return true
        end
        local widget = f.MyObject
        if type(widget) == "table" and widget.type == "switch" then
            f.euiDetailsCheck = widget.checked_texture
            S.Button(f, {"euiDetailsCheck", "text", "Text", "label"})
            if H.Texture(widget.checked_texture) then widget.checked_texture:SetVertexColor(S.GetAccentColor()) end
            H.Hook(widget, "SetTemplate", refresh)
            return true
        end
        if type(widget) == "table" and widget.type == "dropdown" then
            S.Dropdown(f)
            H.Fade(f.statusbar)
            H.Hook(widget, "SetTemplate", refresh)
            H.Script(f.dropdownframe, "OnShow", C.RefreshNow)
            if H.Allowed(f.dropdownframe) then C.Panel(f.dropdownframe) end
            return true
        end
        if kind == "Slider" then
            H.LegacySlider(f)
            local thumb = f.GetThumbTexture and H.Texture(f:GetThumbTexture())
            if thumb and thumb.SetSize and f.GetOrientation and f:GetOrientation() == "HORIZONTAL" then thumb:SetSize(8, 14) end
            return true
        end
        if f.spellId or f.spellID or f.itemId or f.itemID then
            for _, text in ipairs(H.Regions(f)) do H.Font(text) end
            return true
        end
    end,
})
