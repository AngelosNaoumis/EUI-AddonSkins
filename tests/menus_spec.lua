local timers, errors, looks = {}, {}, {}
local combat, accent = false, 0.4
local ns = {IsEnabled = function(module) return module and module.enabled end,
    AttachAccent = function(_, f) f.accent = true end}
C_Timer.After = function(_, fn) timers[#timers + 1] = fn end
InCombatLockdown = function() return combat end
geterrorhandler = function() return function(e) errors[#errors + 1] = e end end
hooksecurefunc = function(obj, name, callback)
    local original = obj[name]
    obj[name] = function(...)
        local values = table.pack(original(...)); callback(...); return table.unpack(values, 1, values.n)
    end
end
local function flush()
    local rounds = 0
    while #timers > 0 do
        local batch = timers; timers = {}; for _, fn in ipairs(batch) do fn() end
        rounds = rounds + 1; assert(rounds < 15, 'menu refresh loop')
    end
end
local function region(kind)
    local r = {kind = kind or 'Texture', alpha = 0.8, color = {1, 0.82, 0, 1}, font = {'native-font', 13, 'OUTLINE'}, text = '|Temote-art:0|t xqcA'}
    function r:GetObjectType() return self.kind end
    function r:IsShown() return self.shown ~= false end
    function r:SetSize() end
    function r:SetPoint() end
    function r:SetColorTexture(...) self.color = {...} end
    function r:GetAlpha() return self.alpha end
    function r:SetAlpha(a) self.alpha = a end
    function r:GetDrawLayer() return 'BACKGROUND' end
    function r:GetVertexColor() return table.unpack(self.color) end
    function r:SetVertexColor(...) self.color = {...} end
    function r:GetFont() return table.unpack(self.font) end
    function r:SetFont(...) self.font = {...} end
    return r
end
local function frame(kind, name, parent)
    local f = {kind = kind or 'Frame', name = name, shown = false, alpha = 1, children = {}, regions = {}, hooks = {}, scripts = {}}
    function f:GetObjectType() return self.kind end
    function f:CreateTexture() local r = region(); self.regions[#self.regions + 1] = r; return r end
    function f:GetName() return self.name end
    function f:IsProtected() return self.protected end
    function f:IsForbidden() return self.forbidden end
    function f:GetRegions() return table.unpack(self.regions) end
    function f:GetChildren() return table.unpack(self.children) end
    function f:GetAlpha() return self.alpha end
    function f:SetAlpha(a) self.alpha = a end
    function f:GetFrameLevel() return 5 end
    function f:SetFrameLevel(v) self.level = v end
    function f:SetAllPoints() end
    function f:EnableMouse(v) self.mouse = v end
    function f:IsShown() return self.shown end
    function f:HookScript(event, callback) self.hooks[event] = callback end
    function f:RegisterEvent() end
    function f:SetScript(event, callback) self.scripts[event] = callback end
    function f:Hide() self.shown = false; if self.hooks.OnHide then self.hooks.OnHide() end end
    if parent then parent.children[#parent.children + 1] = f end
    if name then _G[name] = f end
    return f
end
local events
CreateFrame = function(kind, _, parent)
    local f = frame(kind, nil, parent)
    if not parent then events = f end
    return f
end
local lib = {ToggleDropDownMenu = function() return 'lib-original' end, UIDropDownMenu_AddButton = function() end}
LibStub = function(name) if name == 'LibUIDropDownMenu-4.0' then return lib end end
ToggleDropDownMenu = function() return 'native-original', nil, 9 end
UIDropDownMenu_AddButton = function() end
local S = {GetFont = function() return 'eui-font', '' end, GetAccentColor = function() return accent, 0.5, 0.6 end,
    OnLooksChanged = function(fn) looks[#looks + 1] = fn end}
function S.Shell(f, options) f.shell = true; assert(options.noTopBar) end
local module = {enabled = true}
assert(loadfile('EUIAddonSkins/Menus.lua'))('EUIAddonSkins', ns)
local owner, unrelated = frame(), frame()
DropDownList1 = frame('Frame', 'DropDownList1')
DropDownList1.MenuBackdrop = frame('Frame', nil, DropDownList1)
local button = frame('Button', 'DropDownList1Button1', DropDownList1)
local text, highlight, arrow = region('FontString'), region(), region()
button.regions = {text}
button.GetFontString = function() return text end
button.GetHighlightTexture = function() return highlight end
button.ExpandArrow = arrow
button.callback = function() return 'emote-insert-original' end
button.disabled = true
DropDownList1.dropdown, DropDownList1.shown = owner, true
ns.BindPopupOwner(S, module, owner); flush()
assert(DropDownList1.MenuBackdrop.alpha == 0 and text.font[1] == 'eui-font')
assert(text.color[2] == 0.82 and text.text == '|Temote-art:0|t xqcA' and button.callback() == 'emote-insert-original' and button.disabled)
assert(arrow.color[1] == accent and highlight.color[4] == 0.1)
local layer = DropDownList1.children[#DropDownList1.children]
assert(layer.shell and layer.accent and layer.mouse == false and layer.level < DropDownList1:GetFrameLevel())
-- Submenus inherit root ownership, retaining independent content/actions.
DropDownList2 = frame('Frame', 'DropDownList2'); DropDownList2.shown = true; DropDownList2.dropdown = button
DropDownList2.Backdrop = frame('Frame', nil, DropDownList2)
local sub = frame('Button', nil, DropDownList2); sub.regions = {region('FontString')}
local a, b, c = ToggleDropDownMenu(); assert(a == 'native-original' and b == nil and c == 9)
assert(DropDownList2.Backdrop.alpha == 0 and sub.regions[1].font[1] == 'eui-font', 'submenu exposed native style until timer')
flush()
assert(DropDownList2.Backdrop.alpha == 0 and sub.regions[1].font[1] == 'eui-font')
accent = 0.9; for _, fn in ipairs(looks) do fn() end; flush(); assert(arrow.color[1] == 0.9)
DropDownList1:Hide(); DropDownList2:Hide()
assert(layer.alpha == 0 and DropDownList1.MenuBackdrop.alpha == 1 and text.font[1] == 'native-font')
assert(arrow.color[2] == 0.82 and highlight.color[4] == 1)
-- Reuse for an unrelated addon must not inherit our overlay or font.
DropDownList1.dropdown, DropDownList1.shown = unrelated, true
ToggleDropDownMenu(); flush()
assert(layer.alpha == 0 and text.font[1] == 'native-font' and DropDownList1.MenuBackdrop.alpha == 1)
-- Native changes during owner replacement win over old snapshot values.
DropDownList1.dropdown = owner; ToggleDropDownMenu(); flush()
DropDownList1.dropdown = unrelated; text:SetFont('other-native-font', 17, 'THICKOUTLINE')
ToggleDropDownMenu(); flush(); assert(text.font[1] == 'other-native-font' and text.font[2] == 17)
-- Library menus, independent module toggles and combat deferral.
local emoteOwner = frame()
local emoteModule = {enabled = true}
L_DropDownList1 = frame('Frame', 'L_DropDownList1'); L_DropDownList1.dropdown, L_DropDownList1.shown = emoteOwner, true
L_DropDownList1.Backdrop = frame('Frame', nil, L_DropDownList1)
ns.BindPopupOwner(S, emoteModule, emoteOwner); assert(lib:ToggleDropDownMenu() == 'lib-original'); flush()
assert(L_DropDownList1.Backdrop.alpha == 0)
emoteModule.enabled = false; for _, fn in ipairs(looks) do fn() end; flush()
assert(L_DropDownList1.Backdrop.alpha == 1)
emoteModule.enabled = true; combat = true; ns.RefreshPopupMenus(); flush(); assert(L_DropDownList1.Backdrop.alpha == 1)
combat = false; events.scripts.OnEvent(events, 'PLAYER_REGEN_ENABLED'); flush(); assert(L_DropDownList1.Backdrop.alpha == 0)
L_DropDownList1:Hide()
-- AddonFactory's unnamed pool is registered explicitly and restores on reuse.
local custom = frame('Button'); custom.Backdrop = frame('Frame', nil, custom)
local customRow = frame('Button', nil, custom); local customText = region('FontString')
customRow.regions = {customText}; customRow.GetFontString = function() return customText end
customRow.callback = function() return 'original-options-action' end
customRow.Check, customRow.UnCheck = region(), region()
customRow.UnCheck.shown = false
function custom:Toggle(dropdown) self.dropdown = dropdown; self.shown = true; return nil, 31 end
ns.BindPopupList(S, emoteModule, emoteOwner, custom)
local missing, extra = custom:Toggle(emoteOwner)
assert(missing == nil and extra == 31 and custom.Backdrop.alpha == 0, 'custom menu first-frame paint/returns lost')
assert(customText.font[1] == 'eui-font' and customRow.callback() == 'original-options-action')
assert(customRow.Check.alpha == 0 and customRow.regions[2].alpha == 1 and customRow.regions[3].alpha == 0)
customRow.Check.shown, customRow.UnCheck.shown = false, true
customRow.hooks.OnClick()
assert(customRow.regions[2].alpha == 0 and customRow.regions[3].alpha == 1, 'live menu marker state lost')
local customLayer = custom.children[#custom.children]
custom:Hide(); assert(custom.Backdrop.alpha == 1 and customLayer.alpha == 0)
assert(customRow.Check.alpha == 0.8 and customRow.regions[2].alpha == 0 and customRow.regions[3].alpha == 0, 'native marker restoration lost')
custom:Toggle(unrelated)
assert(customText.font[1] == 'native-font' and custom.Backdrop.alpha == 1 and customLayer.alpha == 0, 'unrelated pool owner inherited skin')
custom:Toggle(emoteOwner); assert(custom.Backdrop.alpha == 0)
flush()
assert(#errors == 0, table.concat(errors, '\n'))
print('PASS: scoped legacy/library popup/submenu styling, native reuse/restoration, preserved emotes/actions/colors, live accents, independent toggles and combat deferral')
