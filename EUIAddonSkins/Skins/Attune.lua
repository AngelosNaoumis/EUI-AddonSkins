local ADDON, ns = ...
ns.RegisterScopedSkin("Attune", "Attune", {
    available = function() return _G.Attune ~= nil end,
    roots = function()
        local result = ns.SkinRoots({"Attune_MainFrame", "AttuneBronzeChrome", "Attune_MainRaidFrame", "Attune_SurveyMenuFrame",
            "Attune_SyncProgress_Frame", "AttuneQuestRewardFrame", "AttuneQuestDetail"}, {bottomBar = 24})
        for _, target in ipairs(result) do
            target.exclude = {}
            if target.frame ~= _G.AttuneBronzeChrome and _G.AttuneBronzeChrome then target.exclude[_G.AttuneBronzeChrome] = true end
            if _G.Attune_GraphRoot then target.exclude[_G.Attune_GraphRoot] = true end
            if target.frame.map then target.exclude[target.frame.map] = true end
        end
        return result
    end,
    hooks = function(C, refresh)
        for _, method in ipairs({"Attune_Frame", "Attune_RaidPlannerFrame", "Attune_ShowQuestRewards", "Attune_ShowQuestDetail",
            "Attune_ShowWebsiteURL", "Attune_UpdateTreeGroup", "Attune_ShowResultList", "Attune_ShowProfileList", "Attune_StartSync", "Attune_RaidPlannerRoster"}) do C.H.Hook(_G, method, refresh) end
    end,
    visit = function(C, f)
        if f == _G.AttuneBronzeChrome then
            if f.NineSlice then C.S.FadeNineSlice(f.NineSlice) end
            if f.CloseButton then C.S.CloseButton(f.CloseButton) end
            -- Keep portrait art and the title's drag handlers.
        end
    end,
})
