local ADDON, ns = ...
ns.RegisterScopedSkin("CrossGambling", "CrossGambling", {
    available = function() return _G.CrossGambling ~= nil end,
    roots = function()
        return ns.SkinRoots({"CrossGamblingSlick", "CrossGamblingClassic", "CrossGamblingAuditLogFrame",
            "CrossGamblingPaymentLedger", "CrossGamblingLedgerExport", "CrossGamblingPlayerCardFrame",
            "CrossGamblingStatsTransferFrame", "CrossGamblingStatProfilesFrame", "CrossGamblingThemePicker"}, {bottomBar = 24})
    end,
    hooks = function(C, refresh)
        for _, method in ipairs({"DrawMainEvents", "toggleUi", "ShowSlick", "ToggleGUI", "ShowThemePicker", "ShowPaymentLedger", "ShowPaymentLedgerExport",
            "RestylePaymentLedger", "RestylePlayerCard", "RefreshAuditFrame", "ShowStatsTransferFrame", "ShowStatProfilesFrame"}) do
            C.H.Hook(_G.CrossGambling, method, refresh)
        end
        for _, method in ipairs({"Ensure", "Show", "Toggle", "Refresh"}) do C.H.Hook(_G.CrossGamblingPlayerCard, method, refresh) end
        for _, method in ipairs({"Switch", "ApplyColors", "ApplyFont"}) do C.H.Hook(_G.CGTheme, method, refresh) end
    end,
})
