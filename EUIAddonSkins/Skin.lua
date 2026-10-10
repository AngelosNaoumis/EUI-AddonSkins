-- Standalone integration. No Forever Companion files or gameplay handlers are replaced.
local ADDON = ...
local EUI, API = _G.EllesmereUI, _G.ForeverCompanionAPI
local S, installed, registered
local unpack = unpack or table.unpack
local roots = setmetatable({}, { __mode = "k" })
local seen = setmetatable({}, { __mode = "k" })
local hooked = setmetatable({}, { __mode = "k" })
local paints = setmetatable({}, { __mode = "k" })
local pending, queued = {}, false
local Scan, Queue
local failures = {}

local function Print(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|cff0cd29fEUI AddonSkins:|r " .. msg)
end

local function Enabled()
    return S and not (EUIAddonSkinsDB and EUIAddonSkinsDB.disabled)
        and (not S.IsEnabled or S.IsEnabled())
end

local function Safe(fn, ...)
    local ok, err = pcall(fn, ...)
    if not ok and not failures[tostring(err)] then
        failures[tostring(err)] = true
        geterrorhandler()(ADDON .. ": " .. tostring(err))
    end
end

local function Allowed(f)
    return f and f.GetObjectType and not (f.IsForbidden and f:IsForbidden())
        and not (f.IsProtected and f:IsProtected())
end

local function Paint(t, kind)
    if not t or not t.SetColorTexture then return end
    local r, g, b = S.GetAccentColor()
    if kind == "accent" then t:SetColorTexture(r, g, b, 0.9)
    elseif kind == "selection" then t:SetColorTexture(r, g, b, 0.18)
    elseif kind == "light" then t:SetColorTexture(1, 1, 1, 0.045)
    elseif kind == "header" then t:SetColorTexture(r, g, b, 0.09)
    elseif kind == "pane" then t:SetColorTexture(0.025, 0.025, 0.03, 0.85)
    else t:SetColorTexture(0, 0, 0, 0.12) end
    paints[t] = kind
end

-- Change the existing color table in place: FC caches it in several files.
local function Palette()
    local c = API.COLORS
    if not c then return end
    local r, g, b = S.GetAccentColor()
    c.pane = { 0.025, 0.025, 0.03 }
    c.border = { 0.18, 0.18, 0.20 }
    c.bar = { 0.065, 0.065, 0.075 }
    c.light = { center = { 0.085, 0.085, 0.095 }, edge = { 0.055, 0.055, 0.065 } }
    c.dark = { center = { 0.05, 0.05, 0.06 }, edge = { 0.025, 0.025, 0.035 } }
    c.header = { center = { r * 0.18, g * 0.18, b * 0.18 }, edge = { 0.025, 0.025, 0.035 } }
    c.sep = { r, g, b, 0.22 }
end

local function HookMethod(f, name, callback)
    if type(f[name]) ~= "function" then return end
    local h = hooked[f]
    if not h then h = {}; hooked[f] = h end
    if h[name] then return end
    h[name] = true
    hooksecurefunc(f, name, callback)
end

local function SkinNode(f)
    if not Allowed(f) then return end
    local fresh = not seen[f]
    if fresh then
        seen[f] = true
        local kind = f:GetObjectType()
        if kind == "CheckButton" then S.Checkbox(f)
        elseif kind == "EditBox" then S.EditBox(f)
        elseif kind == "Slider" or kind == "EventFrame" then
            -- MinimalScrollBar is an EventFrame; normal option sliders stay intact.
            if f.ThumbTexture or f.GetThumbTexture or f.Track then S.ScrollBar(f) end
        elseif kind == "DropdownButton" then S.Dropdown(f)
        elseif kind == "Button" and not f.itemId and not f.spellId then
            local label = (f.GetFontString and f:GetFontString()) or f.Text or f.text
            if label and not f.icon then
                S.Button(f, { "Icon", "sel", "selL", "selR", "accent" })
                if S.StateButtonLabel then S.StateButtonLabel(f) end
            end
        end
        if f:GetObjectType() ~= "GameTooltip" then
            for _, region in ipairs({ f:GetRegions() }) do
                if region:GetObjectType() == "FontString" then S.Font(region) end
            end
        end
    end
    -- FC selection hooks must retain their original behavior.
    if f.accent then
        Paint(f.accent, "accent")
        if f.text then f.text:SetTextColor(1, 1, 1) end
    end
    if f.selL then Paint(f.selL, "selection") end
    if f.selR then Paint(f.selR, "selection") end
    if f.icon and f.sel then Paint(f.sel, "selection") end
    HookMethod(f, "SetSelected", function() if Enabled() then Safe(SkinNode, f) end end)
    for _, method in ipairs({ "ShowPage", "Render", "RenderList", "Update", "RefreshAll" }) do
        HookMethod(f, method, function() Queue(f) end)
    end
end

Scan = function(f, depth)
    if not Enabled() or not Allowed(f) or (depth or 0) > 16 then return end
    if f:GetObjectType() == "GameTooltip" then return end
    SkinNode(f)
    for _, child in ipairs({ f:GetChildren() }) do Scan(child, (depth or 0) + 1) end
end

-- One deferred pass coalesces construction/refresh bursts. No polling/OnUpdate.
Queue = function(f)
    if not Enabled() or not Allowed(f) then return end
    pending[f] = true
    if queued then return end
    queued = true
    C_Timer.After(0, function()
        queued = false
        local batch = pending
        pending = {}
        if not Enabled() then return end
        for frame in pairs(batch) do Safe(Scan, frame) end
    end)
end

local function Window(f)
    if not Allowed(f) or roots[f] then return end
    roots[f] = true
    -- Only call Shell on initial construction: a later call would fade content icons.
    -- Already-built options windows carry a content icon directly on the root.
    local headAlpha = f.headIcon and f.headIcon:GetAlpha()
    S.Shell(f)
    if headAlpha then f.headIcon:SetAlpha(headAlpha) end
    if f.NineSlice then S.FadeNineSlice(f.NineSlice) end
    if f.Bg then f.Bg:SetAlpha(0) end
    if f.Inset then S.Inset(f.Inset) end
    if f.TitleBg then f.TitleBg:SetAlpha(0) end
    if f.TitleContainer then
        S.FadeRegions(f.TitleContainer)
        if f.TitleContainer.TitleText then S.Font(f.TitleContainer.TitleText, 1, 1, 1) end
    elseif f.TitleText then S.Font(f.TitleText, 1, 1, 1) end
    if f.CloseButton then S.CloseButton(f.CloseButton) end
    f:HookScript("OnShow", function() Queue(f) end)
    Queue(f)
end

local function Pack(...) return { n = select("#", ...), ... } end

-- Factories return frames which post-hooks cannot see. Wrap only FC's public factories,
-- preserving all return values (including nils) and propagating original errors.
local function Wrap(name, after)
    local original = API[name]
    if type(original) ~= "function" then return end
    API[name] = function(...)
        local result = Pack(original(...))
        if Enabled() then Safe(after, result, ...) end
        return unpack(result, 1, result.n)
    end
end

local function Install(skin)
    if installed then return end
    S = skin
    if not Enabled() then return end
    installed = true
    Palette()
    Wrap("CreateWindow", function(v) Window(v[1]) end)
    Wrap("CreateMenuButton", function(v)
        S.Button(v[1]); if S.StateButtonLabel then S.StateButtonLabel(v[1]) end
        Queue(v[1])
    end)
    Wrap("CreateSearchBox", function(v) S.EditBox(v[1]); Queue(v[1]) end)
    Wrap("CreateDropdown", function(v)
        if v[1] and v[1].frame then S.Dropdown(v[1].frame); Queue(v[1].frame) end
    end)
    Wrap("CreateScrollFrame", function(v)
        local sf, bar = v[1], v[2]
        bar = bar or (sf and sf.ScrollBar)
        if bar then S.ScrollBar(bar) end
        if sf then sf:HookScript("OnShow", function() Queue(sf) end); Queue(sf) end
    end)
    Wrap("AddInset", function(v)
        Paint(v[1], "pane"); if v[2] then S.Inset(v[2]) end
    end)
    Wrap("StripedBackground", function(v, _, style)
        Paint(v[1], style); Paint(v[2], style)
    end)
    Wrap("CreateSideTab", function(v)
        local tab = v[1]
        S.Button(tab, { "icon", "sel" })
        if tab.mask and tab.icon and tab.icon.RemoveMaskTexture then tab.icon:RemoveMaskTexture(tab.mask) end
        if tab.bg then tab.bg:SetAlpha(0) end
        if tab.border then tab.border:SetAlpha(0) end
        if tab.hl then tab.hl:SetAlpha(0) end
        if tab.icon then S.SquareIcon(tab.icon) end
        Paint(tab.sel, "selection")
        Queue(tab)
    end)
    Wrap("CreateOptionsButton", function(v) S.Button(v[1], { "icon" }); Queue(v[1]) end)
    Wrap("VirtualList", function(v, _, sc)
        HookMethod(v[1], "Layout", function() Queue(sc) end)
        HookMethod(v[1], "Refresh", function() Queue(sc) end)
        Queue(sc)
    end)
    -- Windows may already exist when the skin callback is dispatched at login.
    for _, name in ipairs({
        "Frame", "RotationFrame", "TalentFrame", "ConsumeFrame", "OptionsFrame",
        "LootFrame", "ProfessionsFrame", "MarketFrame", "StatsPanel", "SpecChooser",
        "NewsFrame", "TourFrame", "TourHint", "PawnFrame", "ScanFrame", "PickFrame",
        "RecipePicker", "RecipeExport", "ScalePreview",
    }) do
        local f = _G["ForeverCompanion" .. name]
        if f then Safe(Window, f) end
    end
    if S.OnLooksChanged then S.OnLooksChanged(function()
        if not Enabled() then return end
        Palette()
        for texture, kind in pairs(paints) do Safe(Paint, texture, kind) end
        for f in pairs(roots) do Queue(f) end
    end) end
end

local function Register()
    if registered or not (EUI and EUI.RegisterSkin and API) then return end
    registered = true
    EUI.RegisterSkin(ADDON, Install)
end

Register()
local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGIN")
events:SetScript("OnEvent", function(self)
    self:UnregisterEvent("PLAYER_LOGIN")
    EUIAddonSkinsDB = EUIAddonSkinsDB or {}
    Register()
    if not registered then
        Print("Skin API saknas. Uppdatera EllesmereUI och aktivera Blizzard Skins+.")
    end
end)

SLASH_EUIADDONSKINS1 = "/euiskins"
SLASH_EUIADDONSKINS2 = "/fcskin"
SlashCmdList.EUIADDONSKINS = function(msg)
    local command = (msg or ""):lower():match("^%s*(%S*)")
    EUIAddonSkinsDB = EUIAddonSkinsDB or {}
    if command == "off" or command == "on" then
        EUIAddonSkinsDB.disabled = command == "off"
        Print((command == "off" and "Avstängt." or "Aktiverat.") .. " Kör /reload för att tillämpa.")
    elseif command == "refresh" then
        for f in pairs(roots) do Queue(f) end
        Print("Uppdatering begärd.")
    else
        Print("v0.1.0 | " .. (Enabled() and installed and "aktivt" or "inaktivt")
            .. " | /fcskin on, off, refresh. Kräver EllesmereUI Blizzard Skins+ och dess skin API.")
    end
end
