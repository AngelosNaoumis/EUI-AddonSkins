-- Integration regressions for optional, lazy targets and session-only RXP themes.
local timers, errors, modules, looks = {}, {}, {}, {}
local enabled = true
local ns = {IsEnabled = function() return enabled end}
function ns.RegisterModule(id, label, available, install)
    modules[id] = {available = available, install = install}
end
geterrorhandler = function() return function(e) errors[#errors + 1] = e end end
C_Timer.After = function(_, fn) timers[#timers + 1] = fn end
hooksecurefunc = function(object, key, fn)
    local original = object[key]
    object[key] = function(...)
        local result = table.pack(original(...)); fn(...); return table.unpack(result, 1, result.n)
    end
end
local function flush()
    local rounds = 0
    while #timers > 0 do
        local batch = timers; timers = {}
        for _, fn in ipairs(batch) do fn() end
        rounds = rounds + 1; assert(rounds < 15, 'refresh loop')
    end
end
local function region(path, layer)
    return {alpha = 0.8, GetObjectType = function() return 'Texture' end,
        GetTexture = function() return path end, GetDrawLayer = function() return layer end,
        GetAlpha = function(self) return self.alpha end, SetAlpha = function(self, a) self.alpha = a end}
end
local function frame(kind)
    local f = {kind = kind or 'Frame', children = {}, regions = {}, hooks = {}}
    function f:GetObjectType() return self.kind end
    function f:IsProtected() return self.protected end
    function f:GetChildren() return table.unpack(self.children) end
    function f:GetRegions() return table.unpack(self.regions) end
    function f:HookScript(key, fn) self.hooks[key] = fn end
    function f:SetBackdrop(v) self.backdropValue = v end
    function f:SetBackdropColor() end
    function f:SetBackdropBorderColor() end
    return f
end
local S = {GetAccentColor = function() return 0.1, 0.8, 0.6 end,
    GetPanelColor = function() return 0.03, 0.03, 0.04, 0.95 end,
    GetFont = function() return 'EUI-font', 'OUTLINE' end,
    OnLooksChanged = function(fn) looks[#looks + 1] = fn end}
local shells, edits = 0, 0
function S.Shell(f) shells = shells + 1; for _, r in ipairs(f.regions) do r:SetAlpha(0) end end
function S.Panel(f) for _, r in ipairs(f.regions) do r:SetAlpha(0) end end
function S.EditBox(f) edits = edits + 1; assert(not f.protected) end
for _, key in ipairs({'Font', 'Button', 'StateButtonLabel', 'Checkbox', 'Dropdown', 'ScrollBar', 'CloseButton', 'FadeNineSlice', 'PageButton'}) do S[key] = function() end end
for _, file in ipairs({'Widgets.lua', 'Skins/ForeverDungeonJournal.lua', 'Skins/RXPGuides.lua'}) do
    assert(loadfile('EUIAddonSkins/' .. file))('EUIAddonSkins', ns)
end
RXP = nil; ForeverDungeonJournal_NS = nil
assert(not modules.RXPGuides.available() and not modules.ForeverDungeonJournal.available(), 'targets must be optional')
local source = {font = 'original-font', background = {1, 1, 1, 1}, textColor = {1, 0, 0}, mapPins = {1, 0, 0}, tooltip = {1, 1, 0}}
local source2 = {font = 'original-v2', backgroundColors = {common = {1, 1, 1}}, borderColors = {common = {1, 1, 1}}, textColor = {title = {1, 1, 0}}, edge = {}, mapPins = {0, 1, 1}, navigationArrow = 'arrow'}
local guide = frame()
guide.backdrop = {edge = {}, guideName = {}, bottom = {}}
guide.GuideName = {bg = region('banner', 'BACKGROUND'), icon = region('logo', 'ARTWORK')}
guide.Footer = {bg = region('footer', 'BACKGROUND')}
local secret, input = frame('EditBox'), frame('EditBox'); secret.protected = true
guide.children = {secret, input}
local guideCreates, originalCalls, renders = 0, 0, 0
RXP = {RXPFrame = guide, settings = {profile = {activeTheme = 'Custom', guideFontSize = 12}},
    LoadActiveTheme = function() originalCalls = originalCalls + 1; return source, nil, 'tail' end,
    RenderFrame = function() renders = renders + 1; return nil, 'render-tail' end,
    v2 = {state = {}, GetTheme = function() return source2 end,
        GetGuideWindow = function(self)
            guideCreates = guideCreates + 1
            local window = {frame = frame(), banner = region('v2-banner', 'ARTWORK'), UpdateTheme = function() end}
            self.state.guideWindow = window; return window
        end}}
assert(modules.RXPGuides.available())
modules.RXPGuides.install(S, modules.RXPGuides); flush()
assert(guideCreates == 0, 'skin must not create lazy guide windows')
assert(edits == 1 and guide.GuideName.icon.alpha == 0.8, 'restricted controls and icons must survive')
assert(guide.GuideName.bg.alpha == 0, 'legacy banner remains visible')
local theme, empty, tail = RXP:LoadActiveTheme()
assert(theme ~= source and empty == nil and tail == 'tail', 'theme wrapper lost returns')
assert(theme.font == 'EUI-font' and source.font == 'original-font' and source.background[1] == 1)
assert(theme.mapPins == source.mapPins and theme.tooltip == source.tooltip, 'semantic colors changed')
assert(RXP.settings.profile.activeTheme == 'Custom' and RXP.settings.profile.guideFontSize == 12)
assert(RXP.colors == theme and RXP.RXPFrame.backdrop.edge.edgeSize == 1)
local v2 = RXP.v2:GetTheme()
assert(v2 ~= source2 and v2.backgroundColors ~= source2.backgroundColors)
assert(source2.backgroundColors.common[1] == 1 and v2.mapPins == source2.mapPins and v2.navigationArrow == 'arrow')
local window = RXP.v2:GetGuideWindow(); flush()
assert(window.banner.alpha == 0 and guideCreates == 1)
window.banner:SetAlpha(1); assert(window.banner.alpha == 0, 'banner alpha lock missing')
local originalTheme = {frame = {1, 0, 0}}
ForeverDungeonJournal_NS = {THEMES = {dungeon = originalTheme}, ToggleJournal = function()
    local root = frame(); root.rightPanel = frame()
    local portrait = region(12345, 'ARTWORK'); root.rightPanel.regions = {portrait}
    root.portrait = portrait
    root.children = {root.rightPanel}
    root.dungeonMapArtHolder = frame(); root.dungeonMapArtHolder.children = {frame('EditBox')}
    root.children[#root.children + 1] = root.dungeonMapArtHolder
    ForeverDungeonJournalFrame = root
    return nil, 'journal-tail'
end}
modules.ForeverDungeonJournal.install(S, modules.ForeverDungeonJournal); flush()
assert(shells == 0, 'journal skin created a window eagerly')
local missing, result = ForeverDungeonJournal_NS.ToggleJournal(); flush()
assert(missing == nil and result == 'journal-tail')
assert(ForeverDungeonJournalFrame.portrait.alpha == 0.8, 'boss portrait faded')
assert(edits == 1, 'map contents must not be scanned')
local icon = region('Interface\\Icons\\INV_Misc_Book_09', 'ARTWORK')
ForeverDungeonJournalSettings = frame(); ForeverDungeonJournalSettings.regions = {icon}
modules.ForeverDungeonJournal.refresh(); flush()
assert(icon.alpha == 0.8, 'settings icon faded')
local previous = shells
modules.ForeverDungeonJournal.refresh(); flush(); assert(shells == previous, 'shell faded twice')
for _, fn in ipairs(looks) do fn() end; flush()
assert(RXP.settings.profile.activeTheme == 'Custom' and source2.font == 'original-v2')
enabled = false
local passthrough = RXP:LoadActiveTheme(); assert(passthrough == source, 'disabled theme wrapper still active')
assert(renders == 0, 'skin refresh must not reload guide content')
local r1, r2 = RXP.RenderFrame(); assert(r1 == nil and r2 == 'render-tail')
assert(originalCalls >= 2 and renders == 1)
assert(#errors == 0, table.concat(errors, '\n'))
print('PASS: optional/lazy targets, RXP source/profile immutability, semantic colors, preserved returns, protected controls, portraits/icons/maps, repeat refresh, disable')
