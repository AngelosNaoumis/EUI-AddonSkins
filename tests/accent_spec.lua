local enabled, skinEnabled = true, true
local ns = {IsEnabled = function() return enabled end}
assert(loadfile('EUIAddonSkins/Accent.lua'))('EUIAddonSkins', ns)
local callbacks, accent, creates = {}, {0.1, 0.8, 0.6}, 0
local S = {GetAccentColor = function() return table.unpack(accent) end,
    IsEnabled = function() return skinEnabled end,
    OnLooksChanged = function(fn) callbacks[#callbacks + 1] = fn end}
local function frame()
    return {CreateTexture = function(self)
        creates = creates + 1
        local t = {SetPoint = function() end, SetHeight = function(self, v) self.height = v end,
            SetColorTexture = function(self, ...) self.color = {...} end,
            SetAlpha = function(self, a) self.alpha = a end}
        self.bar = t; return t
    end}
end
local function looks() for _, fn in ipairs(callbacks) do fn() end end
EllesmereUIDB = nil
local f = frame(); ns.AttachAccent(S, f)
assert(f.bar.color[2] == 0.8 and f.bar.alpha == 1 and f.bar.height == 2)
ns.AttachAccent(S, f); assert(creates == 1, 'accent added twice')
EllesmereUIDB = {blizzWinAccentBar = {useCustom = true, color = {r = 0.9, g = 0.4, b = 0.2}}}
looks(); assert(f.bar.color[1] == 0.9 and f.bar.color[2] == 0.4, 'window custom accent ignored')
EllesmereUIDB.blizzWinAccentBar.color = nil
looks(); assert(f.bar.color[1] == 1 and f.bar.color[3] == 1, 'custom mode white fallback differs from EUI')
EllesmereUIDB.blizzWinAccentBar.useCustom = false
accent = {0.8, 0.2, 0.7}; looks(); assert(f.bar.color[1] == 0.8, 'linked accent did not update live')
EllesmereUIDB.blizzWinAccentBar.enabled = false
looks(); assert(f.bar.alpha == 0, 'show-accent-bar switch ignored')
local late = frame(); ns.AttachAccent(S, late); assert(late.bar.alpha == 0, 'late window ignored hidden preference')
EllesmereUIDB.blizzWinAccentBar.enabled = true
looks(); assert(f.bar.alpha == 1 and late.bar.alpha == 1)
skinEnabled = false; accent = {0, 0, 0}; looks(); assert(f.bar.color[1] == 0.8, 'disabled skin repainted')
skinEnabled = true; enabled = false; looks(); assert(f.bar.color[1] == 0.8, 'collection disable ignored')
-- Do not create visual regions on protected containers during combat.
InCombatLockdown = function() return true end
local deferred = frame(); ns.AttachAccent(S, deferred); assert(not deferred.bar)
InCombatLockdown = function() return false end
enabled = true; ns.AttachAccent(S, deferred); assert(deferred.bar)
EllesmereUIDB = nil
print('PASS: window accent custom/linked colors, visibility, late frames, toggle gating, combat deferral, idempotence')
