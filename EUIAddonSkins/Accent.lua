local ADDON, ns = ...

-- The public facade exposes the global accent, but not Window Skins' separate
-- accent-bar preference. Read those EUI preferences without modifying its DB.
function ns.AccentBarColor(S)
    local option = EllesmereUIDB and EllesmereUIDB.blizzWinAccentBar
    if option and option.useCustom then
        local c = option.color or {}
        return c.r or 1, c.g or 1, c.b or 1
    end
    return S.GetAccentColor()
end

function ns.AccentBarShown()
    local option = EllesmereUIDB and EllesmereUIDB.blizzWinAccentBar
    return not (option and option.enabled == false)
end

local bars = setmetatable({}, {__mode = "k"})
function ns.AttachAccent(S, frame)
    if not frame or not frame.CreateTexture or bars[frame]
        or (frame.IsForbidden and frame:IsForbidden())
        or (InCombatLockdown and InCombatLockdown()) then return end
    -- Overlay keeps the line above nested backdrop textures without fading art.
    local t = frame:CreateTexture(nil, "OVERLAY", nil, 7)
    t:SetPoint("TOPLEFT", frame, "TOPLEFT", 1, -1)
    t:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -1, -1)
    t:SetHeight(2)
    local function Refresh()
        if not ns.IsEnabled() or (S.IsEnabled and not S.IsEnabled()) then return end
        local r, g, b = ns.AccentBarColor(S)
        t:SetColorTexture(r, g, b, 1)
        t:SetAlpha(ns.AccentBarShown() and 1 or 0)
    end
    bars[frame] = t
    Refresh()
    if S.OnLooksChanged then S.OnLooksChanged(Refresh) end
end
