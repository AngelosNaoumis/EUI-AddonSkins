-- Synthetic modern auction house with Auctionator; Lua 5.4 host CPU/heap, not WoW profiling.
-- BENCH_ROOT points at the addon directory to measure.
local timers, modules = {}, {}
local ns = {IsEnabled = function() return true end, AttachAccent = function() end}
function ns.RegisterModule(id, _, available, install) modules[id] = {available = available, install = install} end
C_Timer = {After = function(_, fn) timers[#timers + 1] = fn end}
InCombatLockdown = function() return false end
geterrorhandler = function() return function(e) error(e) end end
NORMAL_FONT_COLOR = {GetRGB = function() return 1, 0.82, 0 end}
PixelUtil = {GetNearestPixelSize = function() return 1 end}
for _, name in ipairs({'AuctionFrame', 'LibStub', 'EllesmereUI', 'AuctionatorTabs_Shopping'}) do _G[name] = nil end
hooksecurefunc = function(obj, key, callback)
    local original = obj[key]
    obj[key] = function(...) original(...); callback(...) end
end
local function flush()
    while #timers > 0 do local batch = timers; timers = {}; for _, fn in ipairs(batch) do fn() end end
end
local function anchors(o)
    function o:ClearAllPoints() self.n = 0 end
    function o:SetPoint() self.n = (self.n or 0) + 1 end
    function o:GetNumPoints() return 0 end
    function o:SetAllPoints() end
end
local Texture = {}
Texture.__index = Texture
anchors(Texture)
function Texture:GetObjectType() return 'Texture' end
function Texture:IsForbidden() return false end
function Texture:GetDrawLayer() return self.layer end
function Texture:GetTexture() return self.path end
function Texture:GetAtlas() return self.atlas end
function Texture:SetTexture(p) self.path = p end
function Texture:SetAtlas(a) self.atlas = a end
function Texture:SetColorTexture() end
function Texture:SetVertexColor() end
function Texture:GetVertexColor() return 0.1, 1, 0, 1 end
function Texture:SetDesaturated() end
function Texture:SetAlpha(a) self.alpha = a end
function Texture:GetAlpha() return self.alpha or 1 end
function Texture:GetSize() return 16, 16 end
function Texture:SetSize() end
function Texture:SetHeight() end
function Texture:SetWidth() end
function Texture:SetShown() end
function Texture:SetTexCoord() end
function Texture:GetNumMaskTextures() return 0 end
local Frame = {}
Frame.__index = Frame
anchors(Frame)
function Frame:GetObjectType() return self.kind end
function Frame:IsForbidden() return false end
function Frame:IsProtected() return false end
function Frame:GetName() end
function Frame:GetParent() return self.parent end
function Frame:GetChildren() return table.unpack(self.children) end
function Frame:GetRegions() return table.unpack(self.regions) end
function Frame:GetNumChildren() return #self.children end
function Frame:GetNumRegions() return #self.regions end
function Frame:GetFrameLevel() return 4 end
function Frame:SetFrameLevel() end
function Frame:GetEffectiveScale() return 1 end
function Frame:GetHeight() return 24 end
function Frame:SetHeight() end
function Frame:GetWidth() return 100 end
function Frame:SetWidth() end
function Frame:GetLeft() return self.l end
function Frame:GetRight() return self.r end
function Frame:GetTop() return self.t end
function Frame:GetBottom() return self.b end
function Frame:SetAlpha() end
function Frame:GetAlpha() return 1 end
function Frame:IsShown() return self.shown end
function Frame:IsVisible() return self.shown and (not self.parent or self.parent:IsVisible()) end
function Frame:SetHitRectInsets() end
function Frame:HookScript(key, fn) self.scripts[key] = fn end
function Frame:SetScript(key, fn) self.scripts[key] = fn end
function Frame:RegisterEvent() end
function Frame:GetFontString() return self.label end
function Frame:GetNormalTexture() return self.normal end
function Frame:GetID() return self.id end
function Frame:CreateTexture(_, layer)
    local t = setmetatable({layer = layer}, Texture); self.regions[#self.regions + 1] = t; return t
end
local function frame(kind, parent)
    local f = setmetatable({kind = kind or 'Frame', children = {}, regions = {}, scripts = {}, shown = true}, Frame)
    if parent then f.parent = parent; parent.children[#parent.children + 1] = f end
    return f
end
CreateFrame = function(kind, _, parent) return frame(kind, parent) end
local label = {GetObjectType = function() return 'FontString' end, IsForbidden = function() return false end,
    GetText = function() return 'Label' end, GetTextColor = function() return 1, 0.82, 0 end, SetTextColor = function() end}
local S = {}
for _, key in ipairs({'Shell', 'Panel', 'Inset', 'SetTabSelection', 'EditBox', 'Button', 'ScrollBar', 'SquareIcon',
    'White', 'Font', 'FadeNineSlice', 'CloseButton', 'Checkbox', 'Dropdown', 'StateButtonLabel', 'PageButton'}) do
    S[key] = function() end
end
function S.Tab(f) if not f.tabbed then f.tabbed = true; f:CreateTexture(nil, 'BACKGROUND') end end
function S.GetAccentColor() return 0.1, 0.8, 0.6 end
assert(loadfile(BENCH_ROOT .. '/Widgets.lua'))('EUIAddonSkins', ns)
assert(loadfile(BENCH_ROOT .. '/Skins/Auctionator.lua'))('EUIAddonSkins', ns)

-- Host, two Auctionator panels (Selling open, Shopping hidden): 10 groups of 30 controls,
-- 40 bag items, a 6-column listing of 60 rows.
AuctionHouseFrame = frame(); AuctionHouseFrame.SetDisplayMode = function() end
AuctionHouseFrame.Tabs = {frame('Button', AuctionHouseFrame)}
Auctionator = {Tabs = {State = {knownTabs = {{name = 'Shopping', tabFrameName = 'AuctionatorShoppingFrame'},
    {name = 'Selling', tabFrameName = 'AuctionatorSellingFrame'}}}}}
AuctionatorShoppingFrame = frame('Frame', AuctionHouseFrame); AuctionatorSellingFrame = frame('Frame', AuctionHouseFrame)
AuctionatorAHTabsContainer = {Tabs = {}}
for _, view in ipairs({AuctionatorShoppingFrame, AuctionatorSellingFrame}) do
    local tab = frame('Button'); tab.frameRef = view; view.shown = false
    table.insert(AuctionatorAHTabsContainer.Tabs, tab)
end
AuctionatorSellingFrame.shown = true
for group = 1, 10 do
    local g = frame('Frame', group % 2 == 0 and AuctionatorSellingFrame or AuctionatorShoppingFrame)
    for index = 1, 30 do
        local c = frame(index % 3 == 0 and 'Button' or index % 3 == 1 and 'EditBox' or 'Frame', g)
        if c.kind == 'Button' then c.label = label; c.normal = c:CreateTexture(nil, 'ARTWORK') end
    end
end
for _ = 1, 40 do
    local item = frame('Button', AuctionatorSellingFrame)
    item.Icon = item:CreateTexture(nil, 'ARTWORK'); item.IconBorder = item:CreateTexture(nil, 'OVERLAY')
end
local listing = frame('Frame', AuctionatorSellingFrame)
listing.l, listing.r = 100, 600
listing.HeaderContainer = frame('Frame', listing); listing.HeaderContainer.l, listing.HeaderContainer.r = 86, 600
for _ = 1, 6 do local col = frame('Button', listing.HeaderContainer); col.label = label end
listing.ScrollArea = frame('Frame', listing); listing.ScrollArea.l, listing.ScrollArea.r = 95, 640
local box = frame('Frame', listing.ScrollArea); listing.ScrollArea.ScrollBox = box
local rows = {}
for _ = 1, 60 do
    local row = frame('Button', box); row.cells = {}
    row.NormalTexture = row:CreateTexture(nil, 'BACKGROUND'); row.HighlightTexture = row:CreateTexture(nil, 'HIGHLIGHT')
    for c = 1, 6 do local cell = frame('Frame', row); cell.Icon = c == 1 and cell:CreateTexture(nil, 'ARTWORK') or nil; row.cells[c] = cell end
    rows[#rows + 1] = row
end
box.ForEachFrame = function(_, fn) for _, row in ipairs(rows) do fn(row) end end
box.Update = function() end

modules.Auctionator.install(S, modules.Auctionator); flush()
local function measure(label, count, fn)
    collectgarbage('collect'); collectgarbage('stop')
    local heap, started = collectgarbage('count'), os.clock()
    for _ = 1, count do fn() end
    local elapsed, allocated = os.clock() - started, collectgarbage('count') - heap
    collectgarbage('restart')
    return string.format('%s %.6f %.3f', label, elapsed, allocated)
end
local refresh = measure('refresh', 200, function() modules.Auctionator.refresh(); flush() end)
local update = measure('update', 2000, function() box:Update() end)
print('MEASURE ' .. refresh .. ' ' .. update)
