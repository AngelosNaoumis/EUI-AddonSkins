-- Synthetic UI workload; Lua 5.4 host CPU/heap measurements, not WoW profiling.
local timers, counters = {}, {}
local enabled = true
local ns = {IsEnabled = function() return enabled end}
C_Timer = {After = function(_, fn) timers[#timers + 1] = fn end}
geterrorhandler = function() return function(e) error(e) end end
hooksecurefunc = function(object, key, callback)
    counters.hooks = (counters.hooks or 0) + 1
    local original = object[key]
    object[key] = function(...) original(...); callback(...) end
end
local function flush()
    while #timers > 0 do
        local batch = timers; timers = {}
        for _, fn in ipairs(batch) do fn() end
    end
end
local function frame(kind)
    local f = {kind = kind or 'Frame', children = {}, scripts = {}}
    function f:GetObjectType() return self.kind end
    function f:GetNumChildren() return #self.children end
    function f:GetNumRegions() return 0 end
    function f:GetChildren()
        counters.children = (counters.children or 0) + 1
        return table.unpack(self.children)
    end
    function f:GetRegions() end
    function f:HookScript(key, fn) self.scripts[key] = fn; counters.hooks = (counters.hooks or 0) + 1 end
    function f:HasScript() return true end
    f.bg = {alpha = 1}
    function f.bg:GetAlpha() return self.alpha end
    function f.bg:SetAlpha(v) self.alpha = v; counters.alpha = (counters.alpha or 0) + 1 end
    return f
end
assert(loadfile(BENCH_ROOT .. '/Widgets.lua'))('EUIAddonSkins', ns)
local S = {Font = function() end}
local module = {}
local H = ns.CreateSkinHelper(S, module)
local root = frame()
for i = 1, 10 do
    local group = frame(i == 1 and 'ScrollFrame' or 'Frame')
    root.children[i] = group
    for j = 1, 200 do group.children[j] = frame() end
end
local function visit(f) counters.visits = (counters.visits or 0) + 1; H.Fade(f.bg) end
local function apply() counters.scans = (counters.scans or 0) + 1; H.Scan(root, refresh, visit) end
function refresh() H.Queue(module, apply) end
apply(); flush()
local warmHooks = counters.hooks
counters = {hooks = 0}
collectgarbage('collect'); collectgarbage('stop')
local heap = collectgarbage('count')
local started = os.clock()
for _ = 1, 200 do root.children[1].scripts.OnVerticalScroll(); flush() end
local elapsed = os.clock() - started
local allocated = collectgarbage('count') - heap
collectgarbage('restart')
assert(counters.hooks == 0, 'warm scroll duplicated hooks')
print(string.format('MEASURE %.6f %.3f %d %d %d %d %d', elapsed, allocated,
    counters.visits or 0, counters.children or 0, counters.alpha or 0, counters.scans or 0, warmHooks))
