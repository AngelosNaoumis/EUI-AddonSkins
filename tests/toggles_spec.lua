-- Model EUI's per-name dispatch and live IsEnabled facade.
local entries, flags, ran, timers, errors = {}, {}, {}, {}, {}
local login, master, eventFrame = false, true
EUIAddonSkinsDB = {}
DEFAULT_CHAT_FRAME = {AddMessage = function() end}
SlashCmdList = {}
geterrorhandler = function() return function(e) errors[#errors + 1] = e end end
CreateFrame = function()
    eventFrame = {RegisterEvent = function() end, SetScript = function(self, _, fn) self.event = fn end}
    return eventFrame
end
C_Timer.After = function(_, fn) timers[#timers + 1] = fn end
local function Dispatch(name)
    local entry = entries[name]
    if login and master and flags[name] ~= false and not entry.fired then
        entry.fired = true
        entry.callback({IsEnabled = function() return master and flags[name] ~= false end})
    end
end
EllesmereUI = {RegisterSkin = function(name, callback)
    assert(not entries[name], 'duplicate EUI registration')
    entries[name] = {callback = callback}; Dispatch(name)
end}
local ns = {}
assert(loadfile('EUIAddonSkins/Core.lua'))('EUIAddonSkins', ns)
assert(loadfile('EUIAddonSkins/Widgets.lua'))('EUIAddonSkins', ns)
local targets = {companion = true, journal = true, rxp = false}
local labels = {companion = 'Forever Companion', journal = 'Forever Dungeon Journal', rxp = 'RestedXP Guides'}
local modules = {}
local callbacks = {}
for _, id in ipairs({'companion', 'journal', 'rxp'}) do
    ns.RegisterModule(id, labels[id], function() return targets[id] end, function(S, module)
        ran[id] = (ran[id] or 0) + 1
        local H = ns.CreateSkinHelper(S, module)
        callbacks[id] = function() H.Queue(module, function() ran[id .. ':refresh'] = (ran[id .. ':refresh'] or 0) + 1 end) end
        module.refresh = callbacks[id]
    end)
    modules[id] = ns.modules[#ns.modules]
end
assert(not entries.EUIAddonSkins, 'obsolete collection toggle remains')
local prefix = 'EUI AddonSkins - '
flags[prefix .. labels.journal] = false
login = true
for name in pairs(entries) do Dispatch(name) end
assert(ran.companion == 1 and not ran.journal and not ran.rxp, 'initial independent gating failed')
flags[prefix .. labels.journal] = true; Dispatch(prefix .. labels.journal)
assert(ran.journal == 1, 'live enable did not install selected module')
targets.rxp = true; eventFrame.event(eventFrame, 'ADDON_LOADED', 'RXPGuides')
assert(ran.rxp == 1, 'late target not activated')
flags[prefix .. labels.journal] = false
callbacks.journal(); callbacks.companion()
assert(#timers == 1, 'disabled module still queued refresh')
flags[prefix .. labels.companion] = false
for _, fn in ipairs(timers) do fn() end; timers = {}
assert(not ran['companion:refresh'], 'queued work ignored toggle change')
flags[prefix .. labels.companion] = true
SlashCmdList.EUIADDONSKINS('refresh')
for _, fn in ipairs(timers) do fn() end; timers = {}
assert(ran['companion:refresh'] == 1 and ran['rxp:refresh'] == 1 and not ran['journal:refresh'], 'slash refresh crossed module gates')
flags[prefix .. labels.journal] = true; Dispatch(prefix .. labels.journal)
assert(ran.journal == 1, 'reenable duplicated installer')
assert(ns.IsEnabled(modules.journal) and ns.IsEnabled(modules.rxp))
master = false
assert(not ns.IsEnabled(modules.companion) and not ns.IsEnabled(modules.journal))
master = true
SlashCmdList.EUIADDONSKINS('off'); assert(not ns.IsEnabled(modules.rxp))
SlashCmdList.EUIADDONSKINS('on'); assert(ns.IsEnabled(modules.rxp))
eventFrame.event(eventFrame, 'PLAYER_LOGIN')
assert(ran.companion == 1 and ran.journal == 1 and ran.rxp == 1, 'repeat event duplicated installs')
-- EUI may become available only after this addon's modules are declared.
EllesmereUI = nil
local late = {}; assert(loadfile('EUIAddonSkins/Core.lua'))('EUIAddonSkins', late)
late.RegisterModule('late', 'Late API', function() return true end, function() ran.late = true end)
EllesmereUI = {RegisterSkin = function(_, fn) fn({IsEnabled = function() return true end}) end}
eventFrame.event(eventFrame, 'ADDON_LOADED', 'EllesmereUI')
assert(ran.late and #errors == 0)
print('PASS: independent EUI toggles, live enable, late target/API, queued disable, scoped refresh, global switches, no duplicate installs')
