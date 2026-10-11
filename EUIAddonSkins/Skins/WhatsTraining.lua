local ADDON, ns = ...
ns.RegisterScopedSkin("WhatsTraining", "What's Training?", {
    available = function() return _G.WhatsTrainingFrame ~= nil or (C_AddOns and C_AddOns.IsAddOnLoaded("WhatsTraining")) end,
    roots = function()
        local roots = ns.SkinRoots({"WhatsTrainingFrame"}, {noTopBar = true})
        if _G.WhatsTrainingSkillsButton then roots[#roots + 1] = {frame = _G.WhatsTrainingSkillsButton, mode = "controls"} end
        return roots
    end,
    hooks = function(C, refresh) C.H.Hook(_G.WhatsTrainingFrame, "Refresh", refresh) end,
    visit = function(C, f)
        if f.spell and f.spell.icon then C.S.SquareIcon(f.spell.icon) end
        if f.groupingPopup then C.Panel(f.groupingPopup) end
        if f.scrollBar and f.scrollBar.ScrollBar then C.S.ScrollBar(f.scrollBar.ScrollBar) end
        -- Spell/city indicators keep their colors and artwork. Only UI icons crop.
        if f.icon and f.icon.GetObjectType and f.icon:GetObjectType() == "Texture" then C.S.SquareIcon(f.icon) end
    end,
})
