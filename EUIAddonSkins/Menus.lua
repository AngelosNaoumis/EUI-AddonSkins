local ADDON, ns = ...
local owners = setmetatable({}, {__mode = "k"})
local records = setmetatable({}, {__mode = "k"})
local hooks, lookHooks, queued = {}, {}, false
local unpack = unpack or table.unpack
local extraLists = setmetatable({}, {__mode = "k"})
local applying = false

local function Allowed(f)
    return f and f.GetObjectType and not (f.IsForbidden and f:IsForbidden())
        and not (f.IsProtected and f:IsProtected())
end
local function Enabled(binding)
    return binding and ns.IsEnabled(binding.module)
end
local function Restore(f)
    local r = records[f]
    if not r or not r.active then return end
    for object, value in pairs(r.alpha) do
        if object:GetAlpha() == 0 then object:SetAlpha(value) end
    end
    for text, value in pairs(r.fonts) do
        local font, size, flags = text:GetFont()
        local applied = r.appliedFonts[text]
        if applied and font == applied[1] and size == applied[2] and (flags or "") == applied[3] then
            text:SetFont(unpack(value))
        end
    end
    for texture, value in pairs(r.colors) do
        local current = {texture:GetVertexColor()}
        local applied = r.appliedColors[texture]
        local same = applied ~= nil
        for i = 1, 4 do if current[i] ~= applied[i] then same = false end end
        if same then texture:SetVertexColor(unpack(value)) end
    end
    if r.layer then r.layer:SetAlpha(0) end
    for _, marker in pairs(r.markers or {}) do marker:SetAlpha(0) end
    r.active = false
end
local function Hook(object, method, callback)
    if not object or type(object[method]) ~= "function" then return end
    local entry = hooks[object]
    if not entry then entry = {}; hooks[object] = entry end
    if entry[method] == object[method] then return end
    hooksecurefunc(object, method, callback)
    entry[method] = object[method]
end
local function Font(r, text, S)
    if not text or not text.GetFont or not text.SetFont then return end
    if not r.fonts[text] then r.fonts[text] = {text:GetFont()} end
    local current, size, currentFlags = text:GetFont()
    local path, flags = S.GetFont()
    flags = flags or ""
    if current ~= path or (currentFlags or "") ~= flags then text:SetFont(path, size or 12, flags) end
    r.appliedFonts[text] = {path, size or 12, flags}
end
local function Fade(r, object)
    if not object or not object.GetAlpha or not object.SetAlpha then return end
    if r.alpha[object] == nil then r.alpha[object] = object:GetAlpha() end
    if object:GetAlpha() ~= 0 then object:SetAlpha(0) end
end
local function Tint(r, texture, red, green, blue, alpha)
    if not texture or not texture.GetVertexColor or not texture.SetVertexColor then return end
    if not r.colors[texture] then r.colors[texture] = {texture:GetVertexColor()} end
    texture:SetVertexColor(red, green, blue, alpha)
    r.appliedColors[texture] = {red, green, blue, alpha}
end
local function Marker(r, button, native, checked, S)
    if not native or not native.IsShown or not button.CreateTexture then return end
    r.markers = r.markers or {}
    local marker = r.markers[native]
    if not marker then
        marker = button:CreateTexture(nil, "OVERLAY")
        marker:SetSize(8, 8); marker:SetPoint("CENTER", native, "CENTER")
        r.markers[native] = marker
    end
    local red, green, blue = S.GetAccentColor()
    marker:SetColorTexture(checked and red or 0.3, checked and green or 0.3, checked and blue or 0.3, 1)
    marker:SetAlpha(native:IsShown() and 1 or 0)
    Fade(r, native)
end
local function Style(f, binding, owner)
    if not Allowed(f) or not Enabled(binding) then Restore(f); return end
    if InCombatLockdown and InCombatLockdown() then return end
    local r = records[f]
    if not r then
        r = {layers = {}, rowHooks = {}}; records[f] = r
        f:HookScript("OnHide", function() Restore(f); ns.RefreshPopupMenus() end)
        f:HookScript("OnShow", function() ns.RefreshPopupMenusNow() end)
    end
    owner = owner or f.dropdown
    if r.active and (r.binding ~= binding or r.owner ~= owner) then Restore(f) end
    if not r.active then
        r.alpha, r.fonts, r.colors = {}, {}, {}
        r.appliedFonts, r.appliedColors = {}, {}
        r.binding, r.owner, r.active = binding, owner, true
    end
    local S = binding.S
    local layer = r.layers[binding.module]
    if not layer then
        -- Style only our visual child. Never register the pooled native menu or
        -- its rows with EUI's persistent skin registry.
        layer = CreateFrame("Frame", nil, f)
        layer:SetAllPoints(f)
        layer:SetFrameLevel(math.max(0, f:GetFrameLevel() - 1))
        layer:EnableMouse(false)
        S.Shell(layer, {noTopBar = true})
        ns.AttachAccent(S, layer)
        layer:SetAlpha(0)
        r.layers[binding.module] = layer
    end
    r.layer = layer
    layer:SetAlpha(1)
    local name = f.GetName and f:GetName() or ""
    Fade(r, f.Backdrop or _G[name .. "Backdrop"])
    Fade(r, f.MenuBackdrop or _G[name .. "MenuBackdrop"])
    if f.GetOwnerRegion then Fade(r, f.NineSlice) end
    -- Older dropdown implementations draw their border directly on the list.
    for _, region in ipairs({f:GetRegions()}) do
        if region.GetObjectType and region:GetObjectType() == "Texture" and region.GetDrawLayer then
            local drawLayer = region:GetDrawLayer()
            if drawLayer == "BACKGROUND" or drawLayer == "BORDER" then Fade(r, region) end
        end
    end
    for _, button in ipairs({f:GetChildren()}) do
        if Allowed(button) and button:GetObjectType() == "Button" then
            Font(r, button.GetFontString and button:GetFontString(), S)
            for _, region in ipairs({button:GetRegions()}) do
                if region.GetObjectType and region:GetObjectType() == "FontString" then Font(r, region, S) end
            end
            local arrow = button.ExpandArrow or _G[(button.GetName and button:GetName() or "") .. "ExpandArrow"]
            if arrow and arrow.GetNormalTexture then arrow = arrow:GetNormalTexture() end
            local red, green, blue = S.GetAccentColor()
            Tint(r, arrow, red, green, blue, 1)
            local highlight = button.Highlight or (button.GetHighlightTexture and button:GetHighlightTexture())
            Tint(r, highlight, 1, 1, 1, 0.1)
            Marker(r, button, button.Check, true, S)
            Marker(r, button, button.UnCheck, false, S)
            if not r.rowHooks[button] and button.HookScript then
                r.rowHooks[button] = true
                button:HookScript("OnClick", ns.RefreshPopupMenusNow)
            end
            -- Checkmarks, disabled/title colors, embedded emotes and row actions
            -- retain their native state. No labels, anchors or handlers change.
        end
    end
end
local function Apply()
    if InCombatLockdown and InCombatLockdown() then return end
    for f, expected in pairs(extraLists) do
        local owner = f.GetOwnerRegion and f:GetOwnerRegion() or f.dropdown
        if f.IsShown and f:IsShown() and owner == expected then Style(f, owners[owner], owner) else Restore(f) end
    end
    for _, prefix in ipairs({"DropDownList", "L_DropDownList", "L_DropDownListQuestie"}) do
        local root = _G[prefix .. "1"]
        local owner = root and root.dropdown
        local binding = owner and root.IsShown and root:IsShown() and owners[owner]
        -- The root menu owns the entire submenu chain, even when submenu
        -- dropdown fields refer to a row instead of the original launcher.
        for level = 1, 8 do
            local f = _G[prefix .. level]
            if f then
                if f.IsShown and f:IsShown() and Enabled(binding) then Style(f, binding)
                else Restore(f) end
            end
        end
    end
end
-- Render-completion hooks must paint in this frame, before the next screen draw.
function ns.RefreshPopupMenusNow()
    if applying then return end
    applying = true
    local ok, err = pcall(Apply)
    applying = false
    if not ok then geterrorhandler()(ADDON .. " / popup menus: " .. tostring(err)) end
end
function ns.BindPopupList(S, module, owner, list)
    if not Allowed(list) then return end
    ns.BindPopupOwner(S, module, owner)
    extraLists[list] = owner
    Hook(list, "Toggle", ns.RefreshPopupMenusNow)
    ns.RefreshPopupMenusNow()
end
function ns.RefreshPopupMenus()
    if queued then return end
    queued = true
    C_Timer.After(0, function()
        queued = false
        local ok, err = pcall(Apply)
        if not ok then geterrorhandler()(ADDON .. " / popup menus: " .. tostring(err)) end
    end)
end
function ns.BindPopupOwner(S, module, owner)
    if not owner then return end
    local binding = owners[owner]
    local changed = not binding or binding.module ~= module or binding.S ~= S
    if changed then
        binding = {S = S, module = module}; owners[owner] = binding
    end
    if not lookHooks[module] and S.OnLooksChanged then
        lookHooks[module] = true
        S.OnLooksChanged(ns.RefreshPopupMenus)
    end
    if changed then ns.RefreshPopupMenusNow() end
end
-- Observe shared renderer completion, with all mutation gated by known owner.
local function InstallHooks()
    Hook(_G, "ToggleDropDownMenu", ns.RefreshPopupMenusNow)
    Hook(_G, "UIDropDownMenu_AddButton", ns.RefreshPopupMenusNow)
    if LibStub then
        for _, name in ipairs({"LibUIDropDownMenu-4.0", "LibUIDropDownMenuQuestie-4.0"}) do
            local lib = LibStub(name, true)
            if lib then
                Hook(lib, "ToggleDropDownMenu", ns.RefreshPopupMenusNow)
                Hook(lib, "UIDropDownMenu_AddButton", ns.RefreshPopupMenusNow)
            end
        end
    end
end
local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("PLAYER_REGEN_ENABLED")
events:SetScript("OnEvent", function() InstallHooks(); ns.RefreshPopupMenus() end)
InstallHooks()
