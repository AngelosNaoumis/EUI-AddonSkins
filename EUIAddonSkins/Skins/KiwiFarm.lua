local ADDON, ns = ...
ns.RegisterScopedSkin("KiwiFarm", "KiwiFarm", {
    available = function() return _G.KiwiFarm ~= nil end,
    panels = false,
    roots = function() return ns.SkinRoots({"KiwiFarm"}, {noTopBar = true}) end,
    hooks = function(C, refresh)
        C.H.Hook(_G.KiwiFarm, "ShowMenu", refresh)
        C.H.Hook(_G.KiwiFarm, "PLAYER_REGEN_ENABLED", refresh)
    end,
    -- KiwiFarm's native whole-frame alpha/visibility still controls its shell.
    -- Shared Blizzard StaticPopup and dropdown-menu frames belong to EUI itself.
})
