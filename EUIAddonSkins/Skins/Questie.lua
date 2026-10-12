local ADDON, ns = ...

local function Module(name)
    local loader = _G.QuestieLoader
    -- ImportModule creates missing modules. Read the existing registry only.
    local modules = type(loader) == "table" and loader._modules
    return type(modules) == "table" and modules[name] or nil
end
local function Frame(widget)
    local kind = type(widget)
    if kind == "table" or kind == "userdata" then return widget.frame or widget end
end
local function Menus(C)
    for _, name in ipairs({"QuestieTrackerMenuFrame", "QuestieTownsfolkMenuFrame",
        "QuestieTownsfolkMenuFrameTownsfolk", "QuestieTownsfolkMenuFrameProfs", "QuestieTownsfolkMenuFrameVendors"}) do
        if C.H.Allowed(_G[name]) then C.MenuOwner(_G[name]) end
    end
    if ns.RefreshPopupMenusNow then ns.RefreshPopupMenusNow() end
end
local function Tracker(C)
    local H, S = C.H, C.S
    local base = _G.Questie_BaseFrame
    if not H.Allowed(base) then return end
    -- Keep Questie's background opacity, movement, resizing and fade behaviour.
    H.ThinBackdrop(base)
    ns.AttachAccent(S, base)
    if H.Allowed(base.sizer) then H.Resize(base.sizer, true) end
    local function walk(f, depth)
        if depth > 16 or not H.Allowed(f) or (f.IsShown and not f:IsShown()) then return end
        for _, region in ipairs(H.Regions(f)) do H.Font(region) end
        for _, child in ipairs(H.Children(f)) do walk(child, depth + 1) end
    end
    walk(base, 0)
    local header = _G.Questie_HeaderFrame
    if H.Allowed(header) then
        local r, g, b = S.GetAccentColor()
        H.Font(header.trackedQuests and header.trackedQuests.label, r, g, b)
        local button = header.questieIcon
        local icon = button and H.Texture(button.texture)
        if H.Allowed(button) and icon then S.SquareIcon(icon, button) end
    end
    -- SecureActionButtonTemplate quest-item buttons are UIParent-owned and are
    -- deliberately never discovered or modified by this skin.
end

ns.RegisterScopedSkin("Questie", "Questie", {
    available = function() return _G.Questie ~= nil and Module("QuestieJourney") ~= nil end,
    preserveTextColors = true,
    roots = function(C)
        Tracker(C); Menus(C)
        local result = {}
        local function Add(widget)
            local f = Frame(widget)
            if C.H.Allowed(f) then result[#result + 1] = {frame = f, options = {bottomBar = 24}} end
        end
        Add(_G.QuestieJourneyFrame); Add(_G.QuestieConfigFrame)
        local journey = Module("QuestieJourney")
        Add(journey and journey.private and journey.private.notePopup)
        if LibStub then
            local dialog = LibStub("AceConfigDialog-3.0", true)
            Add(dialog and dialog.OpenFrames and dialog.OpenFrames.Questie)
        end
        return result
    end,
    hooks = function(C, refresh)
        local H = C.H
        local journey, options = Module("QuestieJourney"), Module("QuestieOptions")
        for _, name in ipairs({"BuildMainFrame", "ToggleJourneyWindow"}) do H.Hook(journey, name, refresh) end
        H.Hook(journey and journey.private, "HandleTabChange", refresh)
        H.Hook(journey and journey.private, "ShowNotePopup", refresh)
        H.Hook(Module("QuestDetailsFrame"), "Draw", refresh)
        H.Hook(options, "Initialize", refresh); H.Hook(options, "ToggleConfigWindow", refresh)
        if LibStub then
            local dialog = LibStub("AceConfigDialog-3.0", true)
            H.Hook(dialog, "FeedGroup", function(_, name) if name == "Questie" then refresh() end end)
        end
        local function UpdateTracker()
            local base = _G.Questie_BaseFrame
            if H.Allowed(base) then
                H.Queue(base, function()
                    if InCombatLockdown and InCombatLockdown() then refresh() else Tracker(C) end
                end)
            else refresh() end
        end
        for _, name in ipairs({"Initialize", "Update", "UpdateFormatting", "Show", "Expand", "Collapse"}) do
            H.Hook(Module("QuestieTracker"), name, UpdateTracker)
        end
        for _, name in ipairs({"TrackerBaseFrame", "TrackerHeaderFrame", "TrackerLinePool"}) do
            H.Hook(Module(name), "Initialize", UpdateTracker)
        end
        H.Hook(Module("TrackerHeaderFrame"), "Update", UpdateTracker)
        local menu = Module("QuestieMenu")
        for _, name in ipairs({"Show", "ShowTownsfolk", "ShowProfessions", "ShowVendors"}) do
            H.Hook(menu, name, function() Menus(C) end)
        end
    end,
    visit = function(C, f, kind, refresh)
        local H, S = C.H, C.S
        if kind == "Slider" then H.LegacySlider(f); return true end
        local widget = f.obj
        if widget and widget.frame == f then
            if widget.type == "TabGroup" then
                for _, tab in pairs(widget.tabs or {}) do
                    if H.Allowed(tab) then H.Tab(tab, tab.selected and true or false) end
                end
                H.Hook(widget, "SelectTab", refresh)
            end
            if widget.closebtn and H.Allowed(widget.closebtn) then
                S.Button(widget.closebtn); if S.StateButtonLabel then S.StateButtonLabel(widget.closebtn) end
            end
            if widget.sizer_se and H.Allowed(widget.sizer_se) then H.Resize(widget.sizer_se, true) end
        end
    end,
})
