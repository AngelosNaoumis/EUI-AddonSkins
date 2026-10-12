-- Load the actual TOC in game order and verify all optional EUI registrations.
local ns, entries = {}, {}
EUIAddonSkinsDB = nil
ForeverCompanion = nil
ForeverCompanion_NS = nil
ForeverDungeonJournal_NS = nil
RXP = nil
Auctionator = nil
Spy = nil
CrossGambling = nil
WhatsTrainingFrame = nil
ItemRack = nil
KiwiFarm = nil
Myslot = nil
BugSack = nil
Altoholic = nil
Attune = nil
Questie = nil
QuestieLoader = nil
SlashCmdList = {}
DEFAULT_CHAT_FRAME = {AddMessage = function() end}
CreateFrame = function()
    return {RegisterEvent = function() end, SetScript = function() end}
end
EllesmereUI = {RegisterSkin = function(name, callback)
    assert(not entries[name], 'Duplicate registration: ' .. name)
    entries[name] = callback
end}
for line in io.lines('EUIAddonSkins/EUIAddonSkins.toc') do
    if line:match('%.lua$') then
        local path = line:gsub('\\', '/')
        assert(loadfile('EUIAddonSkins/' .. path))('EUIAddonSkins', ns)
    end
end
assert(#ns.modules == 15, 'Package must register all fifteen skins')
for _, label in ipairs({'Forever Companion', 'Forever Dungeon Journal', 'RestedXP Guides', 'Auctionator', 'Spy', 'CrossGambling', "What's Training?", 'ItemRack', 'KiwiFarm', 'Myslot', 'BugSack', 'Altoholic', 'Attune', 'TwitchEmotes', 'Questie'}) do
    assert(entries['EUI AddonSkins - ' .. label], 'Missing EUI toggle: ' .. label)
end
print('PASS: actual TOC loads all fifteen skin modules and registers their EUI toggles')
