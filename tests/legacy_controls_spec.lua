-- Native-control fixtures: actions, geometry, status colours, redraws and reuse.
local enabled, combat, accent, timers, events = true, false, 0.4, {}, {}
local ns = {IsEnabled = function() return enabled end, AttachAccent = function(_, f) f.accent = true end}
C_Timer = {After = function(_, fn) timers[#timers + 1] = fn end}
InCombatLockdown = function() return combat end
geterrorhandler = function() return function(e) error(e) end end
hooksecurefunc = function(object, name, callback)
    local original = object[name]
    object[name] = function(...)
        local values = table.pack(original(...)); callback(...); return table.unpack(values, 1, values.n)
    end
end
local function texture(kind, parent)
    local t = {kind = kind or 'Texture', alpha = 1, path = 'native', parent = parent, points = {}}
    function t:GetObjectType() return self.kind end
    function t:GetTexture() return self.path end
    function t:SetTexture(v) self.path = v end
    function t:GetAlpha() return self.alpha end
    function t:SetAlpha(v) self.alpha = v end
    function t:GetDrawLayer() return self.layer or 'ARTWORK' end
    function t:SetColorTexture(...) self.color = {...}; self.path = 'solid' end
    function t:SetVertexColor(...) self.color = {...} end
    function t:SetPoint(...) self.points[#self.points + 1] = {...} end
    function t:SetAllPoints() end
    function t:SetSize(w, h) self.width, self.height = w, h end
    function t:SetHeight(h) self.height = h end
    function t:SetWidth(w) self.width = w end
    function t:SetTexCoord(...) self.crop = {...} end
    function t:GetNumMaskTextures() return self.masked and 1 or 0 end
    function t:SetText(s) assert(self.font, "FontString:SetText(): Font not set"); self.text = s end
    function t:GetFont() return self.font, self.font and 12, '' end
    function t:SetFont(v) self.font = v end
    function t:SetTextColor(...) self.textColor = {...} end
    function t:GetParent() return self.parent end
    return t
end
local function frame(kind, name, parent)
    local f = {kind = kind or 'Frame', name = name, parent = parent, regions = {}, children = {}, hooks = {}}
    function f:GetObjectType() return self.kind end
    function f:GetName() return self.name end
    function f:GetParent() return self.parent end
    function f:IsForbidden() return self.forbidden end
    function f:IsProtected() return self.protected end
    function f:GetChildren() return table.unpack(self.children) end
    function f:GetRegions() return table.unpack(self.regions) end
    function f:HookScript(event, fn) self.hooks[event] = fn end
    function f:RegisterEvent(e) self.events = self.events or {}; self.events[e] = true end
    function f:SetScript(e, fn) self.hooks[e] = fn end
    function f:GetBackdrop() return self.backdrop end
    function f:SetBackdrop(b) assert(not combat); self.backdrop = b; self.color, self.border = {0, 0, 0, 1}, {0, 0, 0, 1} end
    function f:GetBackdropColor() return table.unpack(self.color) end
    function f:GetBackdropBorderColor() return table.unpack(self.border) end
    function f:SetBackdropColor(...) self.color = {...} end
    function f:SetBackdropBorderColor(...) self.border = {...} end
    function f:CreateTexture() local t = texture(nil, self); self.regions[#self.regions + 1] = t; return t end
    function f:CreateFontString(_, _, template) local t = texture('FontString', self); t.font = template; self.regions[#self.regions + 1] = t; return t end
    function f:GetNormalTexture() return self.normal end
    function f:GetWidth() return 24 end
    function f:GetHeight() return 24 end
    function f:GetFontString() return self.label end
    if parent then parent.children[#parent.children + 1] = f end
    if name then _G[name] = f end
    return f
end
CreateFrame = function(kind, name, parent) local f = frame(kind, name, parent); events[#events + 1] = f; return f end
local S = {GetAccentColor = function() return accent, 0.6, 0.7 end}
function S.Font(t, r, g, b) t:SetFont('eui'); if r then t:SetTextColor(r, g, b) end end
function S.Button(f, keys)
    local keep = {}; for _, key in ipairs(keys or {}) do keep[f[key] or false] = true end
    for _, t in ipairs(f.regions) do if t.kind == 'Texture' and not keep[t] then t:SetAlpha(0) end end
    f.button = true
end
function S.SquareIcon(t, parent) if t:GetNumMaskTextures() > 0 then return end; t:SetTexCoord(0.08, 0.92, 0.08, 0.92); t.borderParent = parent end
function S.PageButton(f, label) f.glyph = label end
function S.ScrollBar(f) f.scroll = true end
function S.Panel(f) f.panel = true end
function S.Shell(f) f.shell = true end
function S.Tab(f) f.tab = true end
function S.SetTabSelection(f, selected) f.selected = selected end
function S.CloseButton(f) f.close = true end
function S.FadeNineSlice() end
SetPortraitTexture = function(t) t:SetTexture('player-face') end
assert(loadfile('EUIAddonSkins/Widgets.lua'))('EUIAddonSkins', ns)
local H = ns.CreateSkinHelper(S, {})
-- Asset identifiers must never reach SquareIcon; mixed rows retain the real Texture.
for _, asset in ipairs({134400, "Interface/Icons/Test", true}) do
    local row = frame('Button'); row.icon = asset; row.Icon = texture()
    H.Scan(row, function() end)
    assert(row.Icon.crop and H.Icon(row) == row.Icon)
    local primitive = frame('Button'); primitive.icon = asset
    H.Scan(primitive, function() end)
    assert(not H.Icon(primitive))
end
local forbidden = texture(); forbidden.IsForbidden = function() return true end
assert(not H.Texture(forbidden) and not H.Texture(texture('FontString')))
local node = frame('Button', 'Attune_Node_Test')
node:SetBackdrop({bgFile = 'native-fill', edgeFile = 'native-bevel', edgeSize = 16})
node:SetBackdropColor(0.37, 0.72, 0.27, 0.3); node:SetBackdropBorderColor(0.37, 0.72, 0.27, 1)
node.action = function() return 'quest-original' end
H.ThinBackdrop(node)
assert(node.backdrop.edgeSize == 1 and node.color[1] == 0.37 and node.border[2] == 0.72 and node.action() == 'quest-original')
node:SetBackdrop({bgFile = 'native-fill', edgeFile = 'native-bevel', edgeSize = 16})
assert(node.backdrop.edgeSize == 1, 'native redraw restored bevel')
local button = frame('Button'); button.normal = texture(); button.regions = {button.normal}
button.action = function() return 'original-toggle' end
H.Toggle(button, false); H.Toggle(button, true)
assert(button.regions[2].text == '-' and #button.regions == 2 and button.normal.alpha == 0 and button.action() == 'original-toggle')
local slider = frame('Slider'); local thumb = texture(); slider.regions = {texture(), thumb}
slider.GetThumbTexture = function() return thumb end; slider.GetOrientation = function() return 'HORIZONTAL' end
slider.value, slider.min, slider.max, slider.step = 0.75, 0.5, 1, 0.01
slider.hooks.OnValueChanged = function() return 'zoom-original' end
H.LegacySlider(slider); local count = #slider.regions
accent = 0.8; H.LegacySlider(slider)
assert(slider.regions[#slider.regions].alpha == 1 and thumb.color[1] == 0.8 and #slider.regions == count and slider.value == 0.75 and slider.hooks.OnValueChanged() == 'zoom-original')
local chrome = frame(); chrome.PortraitContainer = frame()
local portrait = texture(); portrait.path = 'quest-scroll'; portrait.masked = true
chrome.PortraitContainer.portrait = portrait; chrome.PortraitContainer.regions = {portrait}
H.Portrait(chrome)
local square = chrome.regions[1]
assert(square.path == 'quest-scroll' and square.width == 28 and square.points[1][4] == 8 and portrait.alpha == 0 and square.borderParent == chrome)
H.Portrait(chrome); assert(#chrome.regions == 1 and chrome.accent)
H.Portrait(chrome, true); assert(square.path == 'player-face' and square.crop[1] == 0.2)
-- Exercise the adapters, not just utility primitives.
local modules = {}
function ns.RegisterModule(id, _, _, install) modules[id] = {install = install} end
assert(loadfile('EUIAddonSkins/Scoped.lua'))('EUIAddonSkins', ns)
assert(loadfile('EUIAddonSkins/Skins/Attune.lua'))('EUIAddonSkins', ns)
Attune_MainFrame = frame('Frame', 'Attune_MainFrame'); Attune_GraphRoot = frame('Frame', 'Attune_GraphRoot', Attune_MainFrame)
local card = frame('Button', 'Attune_Node_42', Attune_GraphRoot)
card:SetBackdrop({edgeFile = 'native', bgFile = 'fill'}); card:SetBackdropColor(0.8, 0.6, 0, 0.3)
local text = card:CreateFontString(); text:SetTextColor(1, 0.8, 0)
local icon = frame('Button', 'Attune_Icon_42', card); icon.normal = texture(); icon.normal.path = 'quest-icon'
local graphLine = Attune_GraphRoot:CreateTexture(); graphLine.color = {0.8, 0.6, 0, 1}
modules.Attune.install(S, modules.Attune)
local function flush()
    while #timers > 0 do local batch = timers; timers = {}; for _, fn in ipairs(batch) do fn() end end
end
flush()
assert(card.backdrop.edgeSize == 1 and card.color[1] == 0.8 and text.font == 'eui' and text.textColor[1] == 1)
assert(not card.button and icon.normal.path == 'quest-icon' and icon.normal.crop and graphLine.color[1] == 0.8)
local tree = frame('Button', nil, Attune_MainFrame)
tree.treeline, tree.selected, tree.text, tree.icon = {}, true, tree:CreateFontString(), tree:CreateTexture()
tree.icon.path = 'dungeon-status-art'; tree.toggle = frame('Button', nil, tree)
tree.toggle.normal = texture(); tree.toggle.normal.path = 130821
modules.Attune.refresh(); flush()
assert(tree.icon.path == 'dungeon-status-art' and tree.icon.alpha == 1 and tree.euiSelection.color[4] == 0.2)
assert(tree.toggle.regions[1].text == '-')
assert(loadfile('EUIAddonSkins/Skins/Altoholic.lua'))('EUIAddonSkins', ns)
AltoholicFrame = frame('Frame', 'AltoholicFrame'); AltoholicFrame.Tabs = {}
local mixedRow = frame('Button', nil, AltoholicFrame); mixedRow.icon = 134400; mixedRow.Icon = texture()
local assetRow = frame('Button', nil, AltoholicFrame); assetRow.icon = 134400
local owner = frame('Frame', nil, AltoholicFrame)
owner.AddButtonInfo = function() end
owner.Initialize = function(self) self.initialize = function() end; return 'init-original' end
owner.Toggle = function() return 'toggle-original' end
local pool = frame('Button')
local mvc = {BindViewToController = function(_, proxy) proxy.GetListFromPool = function(_, level) if level == 1 then return pool end end end}
LibStub = function(name) if name == 'LibMVC-1.0' then return mvc end end
local bindings = 0
ns.BindPopupOwner = function() end
ns.BindPopupList = function(_, _, boundOwner, list) assert(boundOwner == owner and list == pool); bindings = bindings + 1 end
modules.Altoholic.install(S, modules.Altoholic); flush()
assert(mixedRow.Icon.crop and mixedRow.button)
assert(owner:Initialize() == 'init-original' and owner:Toggle() == 'toggle-original' and bindings >= 3)
assert(loadfile('EUIAddonSkins/Skins/ForeverDungeonJournal.lua'))('EUIAddonSkins', ns)
ForeverDungeonJournal_NS = {THEMES = {}, ToggleJournal = function() end}
ForeverDungeonJournalFrame = frame('Frame')
local journal = ForeverDungeonJournalFrame
journal.homePanel = frame('Frame', nil, journal)
journal.homeTitle = journal.homePanel:CreateFontString()
local cover = frame('Button', nil, journal.homePanel)
cover.dungeonName = 'Dalaran'; cover.art = cover:CreateTexture(); cover.art.path = 'dungeon-art'
cover.title = cover:CreateFontString(); cover.counts = cover:CreateFontString(); cover.counts.textColor = {1, 0.9, 0.5}
cover:SetBackdrop({bgFile = 'native', edgeFile = 'bevel'}); cover.action = function() return 'open-dungeon' end
journal.bugReportButton = frame('Button', nil, journal)
local bug = journal.bugReportButton:CreateTexture(); bug.path = 'bug-icon'
local bugLabel = journal.bugReportButton:CreateFontString()
journal.languageSelectorButton = frame('Button', nil, journal)
journal.languageSelectorText = journal.languageSelectorButton:CreateFontString()
local caret = journal.languageSelectorButton:CreateTexture(); caret.path = 'native-caret'
modules.ForeverDungeonJournal.install(S, modules.ForeverDungeonJournal); flush()
assert(cover.backdrop.edgeSize == 1 and cover.art.path == 'dungeon-art' and cover.art.alpha == 1 and cover.counts.textColor[1] == 1 and cover.action() == 'open-dungeon')
assert(journal.homeTitle.textColor[1] == accent and journal.bugReportButton.button and bug.alpha == 1)
assert(caret.alpha == 0 and journal.languageSelectorButton.euiCaret.text == 'v')
combat = true
local late = frame('Button', 'Attune_Node_43', Attune_GraphRoot); late.SetBackdrop = nil
modules.Attune.refresh(); flush(); assert(not late.button)
combat = false; enabled = false; modules.Attune.refresh(); flush()
print('PASS: thin semantic nodes, graph/icon preservation, toggle actions, legacy slider geometry, square contained portraits, live colours and idempotence')
