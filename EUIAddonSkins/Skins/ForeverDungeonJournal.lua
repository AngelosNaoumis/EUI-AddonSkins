local ADDON, ns = ...
ns.RegisterModule("ForeverDungeonJournal", "Forever Dungeon Journal", function()
    local journal = _G.ForeverDungeonJournal_NS
    return journal and type(journal.ToggleJournal) == "function"
end, function(S, module)
    local journal = _G.ForeverDungeonJournal_NS
    local H = ns.CreateSkinHelper(S)
    local refresh
    local panels, watched = {}, {}
    local unpack = unpack or table.unpack

    local function Palette()
        local r, g, b = S.GetAccentColor()
        -- Journal.lua caches this table; recolor in place without changing saved settings.
        for _, theme in pairs(journal.THEMES or {}) do
            theme.frame = {0.025, 0.025, 0.03, 0.98}
            theme.content = {0.035, 0.035, 0.04, 0.96}
            theme.header = {0.055, 0.055, 0.065, 0.96}
            theme.left = {0.025, 0.025, 0.03, 0.96}
            theme.right = {0.035, 0.035, 0.04, 0.96}
            theme.row = {0.06, 0.06, 0.07, 0.92}
            theme.lootRow = {0.06, 0.06, 0.07, 0.92}
            theme.rowSelected = {r * 0.25, g * 0.25, b * 0.25, 0.95}
            theme.border = {0.2, 0.2, 0.22, 1}
            theme.title = {r, g, b}
            theme.text = {0.9, 0.9, 0.92}
            theme.muted = {0.65, 0.65, 0.68}
        end
    end

    local function Panel(f)
        if not H.Allowed(f) or panels[f] then return end
        panels[f] = true
        -- Preserve foreground portrait/artwork regions while replacing the background.
        local artwork = {}
        for _, region in ipairs({f:GetRegions()}) do
            if region.GetTexture and region.GetDrawLayer then
                local layer = region:GetDrawLayer()
                if layer == "ARTWORK" or layer == "OVERLAY" then artwork[region] = region:GetAlpha() end
            end
        end
        S.Panel(f)
        for region, alpha in pairs(artwork) do region:SetAlpha(alpha) end
        if f.SetBackdrop then f:SetBackdrop(nil) end
    end

    local function Visit(f)
        -- Brown text from the original parchment becomes unreadable on a dark panel.
        -- Keep item names/rarity, quest status indicators and portrait artwork intact.
        for _, key in ipairs({"slot", "meta"}) do H.Font(f[key], 0.65, 0.65, 0.68) end
    end

    local function Watch(f)
        if not H.Allowed(f) then return end
        H.Shell(f, refresh)
        if not watched[f] then
            watched[f] = true
            -- Private page renderers change panel colors; schedule after the whole render.
            H.Hook(f, "SetBackdropColor", refresh)
            H.Hook(f, "SetBackdropBorderColor", refresh)
        end
        H.Scan(f, refresh, Visit, f.dungeonMapArtHolder and {[f.dungeonMapArtHolder] = true})
    end

    local function Apply()
        local f = _G.ForeverDungeonJournalFrame
        if f then
            Watch(f)
            for _, key in ipairs({"contentPanel", "headerPanel", "homePanel", "leftPanel", "rightPanel",
                "questLeftPanel", "questRightPanel", "questTextInset", "routePanel"}) do Panel(f[key]) end
            for _, key in ipairs({"homeParchment", "contentParchment", "headerParchment", "leftParchment",
                "rightParchment", "questLeftParchment", "questRightParchment", "questParchment", "atmosphere"}) do H.Fade(f[key]) end
            for _, edge in ipairs(f.questInsetEdges or {}) do
                edge:SetColorTexture(0.18, 0.18, 0.2, 1)
            end
            for _, key in ipairs({"questDetailText", "questTurninText", "questRewardSummary", "selectedQuestMeta",
                "questStartsText", "questNotesText", "noQuestMessage", "selectedBossQuestion",
                "selectedBossDescription", "lootTitle"}) do
                H.Font(f[key], 0.85, 0.85, 0.88)
            end
            local r, g, b = S.GetAccentColor()
            H.Font(f.mainTitle, 1, 1, 1)
            H.Font(f.selectedQuestName, r, g, b)
            H.Font(f.dungeonTitle, r, g, b)
            H.Font(f.selectedBossName, r, g, b)
            for _, key in ipairs({"questsTab", "bossesTab", "mapTab", "backButton"}) do
                if H.Allowed(f[key]) then S.Button(f[key]) end
            end
            if H.Allowed(f.questPrevStepButton) and S.PageButton then S.PageButton(f.questPrevStepButton, "<") end
            if H.Allowed(f.questNextStepButton) and S.PageButton then S.PageButton(f.questNextStepButton, ">") end
            for _, key in ipairs({"bugReportWindow", "lootFilterWindow", "favouritesWindow"}) do
                if f[key] then Watch(f[key]) end
            end
        end
        for _, name in ipairs({"ForeverDungeonJournalSettings", "ForeverDungeonJournalNotice",
            "ForeverDungeonJournalOptionsPanel", "ForeverDungeonJournalLootFilter",
            "ForeverDungeonJournalLootFilterResults", "ForeverDungeonJournalFavourites",
            "ForeverDungeonJournalFavouriteContextMenu"}) do
            local window = _G[name]
            -- The Blizzard Settings category is embedded, so only style its controls.
            if window then
                if name == "ForeverDungeonJournalOptionsPanel" then H.Scan(window, refresh)
                else Watch(window) end
            end
        end
        for _, name in ipairs({"OpenBossPage", "OpenQuestPage", "RefreshLootNow", "OpenSearchResult"}) do
            H.Hook(journal, name, refresh) -- Some exports appear only after first opening.
        end
    end
    refresh = function() H.Queue(module, Apply) end
    for _, name in ipairs({"ToggleJournal", "ShowUpdateNotice", "ToggleSettingsPanel", "ToggleLootFilterWindow",
        "ToggleFavouritesWindow", "ToggleBugReportWindow", "RefreshHomeCards", "GoBackPage",
        "RefreshLootFilterResults", "RebuildLootFilterPage", "RefreshFavouritesWindow",
        "ShowItemFavouriteMenu", "ShowLootFilterResults", "RelocalizeLootFilter"}) do H.Hook(journal, name, refresh) end
    -- Quest events schedule a private renderer for the next frame; hook its completion.
    if journal.questRefreshWorker then H.Script(journal.questRefreshWorker, "OnUpdate", refresh) end
    Palette()
    refresh()
    module.refresh = refresh
    if S.OnLooksChanged then S.OnLooksChanged(function()
        if ns.IsEnabled() then Palette(); refresh() end
    end) end
end)
