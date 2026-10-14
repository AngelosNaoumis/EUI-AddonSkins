local ADDON, ns = ...

function ns.DetailsSettings()
    EUIAddonSkinsDB = EUIAddonSkinsDB or {}
    local db = EUIAddonSkinsDB
    db.details = db.details or {menus = true, meter = false}
    if db.details.tiny == nil then db.details.tiny = db.details.meter == true end
    return db.details
end

function ns.SetDetailsSetting(key, value)
    if key ~= "menus" and key ~= "meter" and key ~= "tiny" then return end
    ns.DetailsSettings()[key] = value == true
    if ns.DetailsSettingsChanged then ns.DetailsSettingsChanged(key) end
end

local panel, category
function ns.CreateDetailsSettingsPanel()
    if panel then return panel end
    panel = CreateFrame("Frame", "EUIAddonSkinsDetailsSettings", UIParent)
    panel.name = "EUI AddonSkins: Details"
    local function Text(value, template, y)
        local text = panel:CreateFontString(nil, "ARTWORK", template)
        text:SetPoint("TOPLEFT", 16, y); text:SetText(value)
        return text
    end
    Text(panel.name, "GameFontNormalLarge", -16)
    Text("Choose which parts of Details use EUI styling.", "GameFontHighlight", -46)
    local function Check(key, label, description, y)
        local button = CreateFrame("CheckButton", nil, panel, "InterfaceOptionsCheckButtonTemplate")
        button:SetPoint("TOPLEFT", 16, y)
        local text = button:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        text:SetPoint("LEFT", button, "RIGHT", 4, 0); text:SetText(label)
        button:SetScript("OnClick", function(self) ns.SetDetailsSetting(key, self:GetChecked() == true) end)
        button:HookScript("OnShow", function(self) self:SetChecked(ns.DetailsSettings()[key] == true) end)
        Text(description, "GameFontHighlightSmall", y - 34)
        return button
    end
    panel.menus = Check("menus", "Skin menus and options", "Styles Details dialogs, dropdowns and options. Reload after changing this setting.", -76)
    panel.meter = Check("meter", "Match EUI meter appearance", "Manages meter fonts, bars, headers and spacing. Off by default.", -166)
    panel.tiny = Check("tiny", "Style Tiny Threat", "Independent styling for Tiny Threat rows and their Details window.", -256)
    Text("Turning meter matching off restores the visual settings captured when it was enabled.", "GameFontHighlightSmall", -342)
    Text("Window positions, sizes, groups, statistics and interactions remain controlled by Details.", "GameFontHighlightSmall", -366)
    Text("Quick access: hover the meter settings icon > EUI AddonSkins.", "GameFontHighlightSmall", -400)
    if Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory then
        category = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
        Settings.RegisterAddOnCategory(category)
    elseif InterfaceOptions_AddCategory then InterfaceOptions_AddCategory(panel) end
    return panel
end

SLASH_EUIDETAILS1 = "/euidetails"
function ns.OpenDetailsSettings()
    ns.CreateDetailsSettingsPanel()
    if Settings and Settings.OpenToCategory and category then Settings.OpenToCategory(category:GetID())
    elseif InterfaceOptionsFrame_OpenToCategory then InterfaceOptionsFrame_OpenToCategory(panel) end
end
SlashCmdList.EUIDETAILS = ns.OpenDetailsSettings

-- Always register the controls, including when the Details skin itself is off.
local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGIN")
events:SetScript("OnEvent", function() ns.CreateDetailsSettingsPanel() end)
