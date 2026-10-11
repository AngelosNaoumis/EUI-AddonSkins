-- Scroll scoping must preserve discovery, exclusions, toggles and native redraws.
local timers, enabled, visits, hooks, painted = {}, true, {}, 0, 0
local ns = {IsEnabled = function() return enabled end}
C_Timer = {After = function(_, fn) timers[#timers + 1] = fn end}
geterrorhandler = function() return function(e) error(e) end end
hooksecurefunc = function(o, key, fn)
    hooks = hooks + 1
    local original = o[key]
    o[key] = function(...) original(...); fn(...) end
end
local function flush()
    while #timers > 0 do
        local batch = timers; timers = {}
        for _, fn in ipairs(batch) do fn() end
    end
end
local function frame(kind)
    local f = {children = {}, scripts = {}, kind = kind or 'Frame'}
    function f:GetObjectType() return self.kind end
    function f:GetNumChildren() return #self.children end
    function f:GetNumRegions() return 0 end
    function f:GetChildren() return table.unpack(self.children) end
    function f:GetRegions() end
    function f:IsProtected() return self.protected end
    function f:HookScript(key, fn) self.scripts[key] = fn; hooks = hooks + 1 end
    return f
end
assert(loadfile('EUIAddonSkins/Widgets.lua'))('EUIAddonSkins', ns)
local S = {Font = function() end, EditBox = function(f) f.skinned = true; painted = painted + 1 end}
local module, exclude = {}, nil
local H = ns.CreateSkinHelper(S, module)
local root, scroll, sibling = frame(), frame('ScrollFrame'), frame()
root.children = {scroll, sibling}
local function visit(f) visits[f] = (visits[f] or 0) + 1 end
local refresh
local function apply() H.Scan(root, refresh, visit, exclude) end
refresh = function() H.Queue(module, apply) end
apply()
local initialHooks = hooks
for _ = 1, 100 do scroll.scripts.OnVerticalScroll() end
assert(#timers == 1); flush()
assert(visits[scroll] == 2 and visits[sibling] == 1 and hooks == initialHooks)
local late = frame('EditBox'); scroll.children = {late}
scroll.scripts.OnVerticalScroll(); flush()
assert(late.skinned and painted == 1, 'new scroll child missed')
local replacement = frame('EditBox'); scroll.children = {replacement}
scroll.scripts.OnVerticalScroll(); flush()
assert(replacement.skinned and painted == 2, 'same-count child replacement missed')
local before = visits[scroll]
scroll.scripts.OnVerticalScroll(); refresh(); flush()
assert(visits[scroll] == before + 1, 'partial and full scans were duplicated')
exclude = {[scroll] = true}; refresh(); flush()
before = visits[scroll]
scroll.scripts.OnVerticalScroll(); flush()
assert(visits[scroll] == before, 'excluded scroll ancestor bypassed')
exclude = nil; refresh(); flush()
replacement.protected = true
local previous = visits[replacement]
scroll.scripts.OnVerticalScroll(); flush()
assert(visits[replacement] == previous, 'protected child visited')
enabled = false; before = visits[scroll]
scroll.scripts.OnVerticalScroll(); refresh(); flush()
assert(visits[scroll] == before, 'disabled integration traversed')
enabled = true
local writes = 0
local texture = {alpha = 1, GetAlpha = function(self) return self.alpha end,
    SetAlpha = function(self, value) self.alpha = value; writes = writes + 1 end}
H.Fade(texture)
local fadeHooks = hooks
for _ = 1, 100 do H.Fade(texture) end
assert(writes == 1 and hooks == fadeHooks, 'warm fade rewrote texture or duplicated hook')
texture:SetAlpha(0.8)
assert(texture.alpha == 0 and writes == 3, 'native redraw suppression lost')
print('PASS: scoped/coalesced scrolling, dynamic replacement, exclusions/protected/toggles, idempotent fade and native redraw')
