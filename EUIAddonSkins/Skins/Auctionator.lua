local ADDON, ns = ...
ns.RegisterModule("Auctionator", "Auctionator", function()
    return _G.Auctionator and _G.Auctionator.Tabs and _G.Auctionator.Tabs.State
end, function(S, module)
    local A = _G.Auctionator
    local H = ns.CreateSkinHelper(S, module)
    local roots, shells, panels = {}, {}, {}
    local refresh, waiting
    local events = CreateFrame("Frame")
    events:RegisterEvent("AUCTION_HOUSE_SHOW")
    events:RegisterEvent("ADDON_LOADED")
    events:RegisterEvent("PLAYER_REGEN_ENABLED")

    local function Remember(f, shell)
        if not f or not f.GetObjectType then return end
        roots[f] = shell or roots[f] or "controls"
        refresh()
    end
    local function Visit(f)
        if H.Allowed(f.NineSlice) then S.FadeNineSlice(f.NineSlice) end
        -- Auctionator's simple panels expose their decorative rock background.
        if f.Bg then H.Fade(f.Bg) end
        if H.Allowed(f.Border) then
            S.FadeNineSlice(f.Border)
            for _, region in ipairs({f.Border:GetRegions()}) do
                if region.GetTexture then H.Fade(region) end
            end
        end
        if f.Inset and H.Allowed(f.Inset) and not panels[f.Inset] then
            panels[f.Inset] = true
            S.Panel(f.Inset)
            if f.Inset.SetBackdrop then f.Inset:SetBackdrop(nil) end
        end
        if H.Allowed(f.CloseButton) then S.CloseButton(f.CloseButton) end
        -- WowTrimScrollBar is an EventFrame rather than a Slider.
        if H.Allowed(f.ScrollBar) then S.ScrollBar(f.ScrollBar) end
    end
    local function Apply()
        if InCombatLockdown() then waiting = true; return end
        waiting = false
        for _, details in ipairs(A.Tabs.State.knownTabs or {}) do
            local f = _G[details.tabFrameName]
            if f then roots[f] = "content" end
            local tab = _G["AuctionatorTabs_" .. details.name]
            if H.Allowed(tab) then
                H.Tab(tab, f and f.IsShown and f:IsShown() or false)
                for _, method in ipairs({"Selected", "DeselectTab"}) do H.Hook(tab, method, refresh) end
                H.Script(tab, "OnClick", refresh)
                if tab.wrapperFrame then roots[tab.wrapperFrame] = "content" end
                if f then H.Script(f, "OnHide", refresh); H.Script(f, "OnShow", refresh) end
            end
        end
        -- Only addon-owned globals, never a scan of the Blizzard auction house.
        for name, f in pairs(_G) do
            if type(name) == "string" and name:match("^AuctionatorConfig.*Frame$") and (type(f) == "table" or type(f) == "userdata") then
                if f.GetObjectType then roots[f] = roots[f] or "controls" end
            end
        end
        for _, name in ipairs({"AuctionatorShoppingTabItemFrame", "AuctionatorExportListFrame",
            "AuctionatorImportListFrame", "AuctionatorItemHistoryFrame"}) do
            if _G[name] then roots[_G[name]] = "dialog" end
        end
        for f, mode in pairs(roots) do
            if H.Allowed(f) then
                if mode ~= "controls" and not shells[f] then
                    shells[f] = true
                    H.Shell(f, refresh, {noTopBar = mode == "content", bottomBar = mode == "dialog" and 32 or nil})
                end
                H.Scan(f, refresh, Visit)
            end
        end
        -- Standard confirmation dialogs are private, but have numbered owned globals.
        local index = 1
        while _G["AuctionatorDialog" .. index] do
            local f = _G["AuctionatorDialog" .. index]
            if H.Allowed(f) then H.Shell(f, refresh); H.Scan(f, refresh, Visit) end
            index = index + 1
        end
    end
    refresh = function() H.Queue(module, Apply) end
    -- Post-hooks see complete controls without replacing constructors or callbacks.
    for _, entry in ipairs({
        {"AuctionatorTabContainerMixin", "OnLoad", "controls"},
        {"AuctionatorConfigFrameMixin", "OnLoad", "controls"},
        {"AuctionatorShoppingTabFrameMixin", "OnLoad", "content"},
        {"AuctionatorListExportFrameMixin", "OnLoad", "dialog"},
        {"AuctionatorListImportFrameMixin", "OnLoad", "dialog"},
        {"AuctionatorExportTextFrameMixin", "OnLoad", "dialog"},
    }) do
        H.Hook(_G[entry[1]], entry[2], function(f) Remember(f, entry[3]) end)
    end
    if A.Dialogs then
        for _, method in ipairs({"ShowEditBox", "ShowConfirm", "ShowConfirmAlt", "ShowMoney"}) do
            H.Hook(A.Dialogs, method, refresh)
        end
    end
    H.Hook(A.Config, "InternalInitializeFrames", refresh)
    -- OnLoad already ran for frames created before this skin was enabled.
    local shopping = _G.AuctionatorShoppingFrame
    if shopping then
        for _, key in ipairs({"exportCSVDialog", "exportDialog", "importDialog", "itemDialog", "itemHistoryDialog"}) do
            if shopping[key] then roots[shopping[key]] = "dialog" end
        end
        if shopping.exportDialog and shopping.exportDialog.copyTextDialog then roots[shopping.exportDialog.copyTextDialog] = "dialog" end
    end
    events:SetScript("OnEvent", function(_, event)
        if ns.IsEnabled(module) and (event ~= "PLAYER_REGEN_ENABLED" or waiting) then refresh() end
    end)
    module.refresh = refresh
    if S.OnLooksChanged then S.OnLooksChanged(refresh) end
    refresh()
end)
