local timers, errors, calls = {}, {}, {}
local function count(k) calls[k] = (calls[k] or 0) + 1 end
local function texture(kind)
    return { GetObjectType = function() return kind or "Texture" end,
        SetColorTexture = function(self, ...) self.color = {...} end,
        SetAlpha = function(self, a) self.alpha = a end }
end
local function frame(kind, name, parent)
    local f = { kind = kind or "Frame", regions = {}, children = {}, scripts = {}, hooks = {} }
    function f:GetObjectType() return self.kind end
    function f:IsForbidden() return self.forbidden end
    function f:IsProtected() return self.protected end
    function f:GetRegions() return table.unpack(self.regions) end
    function f:GetChildren() return table.unpack(self.children) end
    function f:HookScript(event, fn)
        self.hooks[event] = self.hooks[event] or {}; table.insert(self.hooks[event], fn)
    end
    function f:SetScript(event, fn) self.scripts[event] = fn end
    function f:RegisterEvent() end
    function f:UnregisterEvent() end
    if parent then table.insert(parent.children, f) end
    if name then _G[name] = f end
    return f
end
CreateFrame = function(kind, name, parent) return frame(kind, name, parent) end
DEFAULT_CHAT_FRAME = { AddMessage = function() end }
SlashCmdList = {}
geterrorhandler = function() return function(err) errors[#errors + 1] = err end end
C_Timer = { After = function(_, fn) timers[#timers + 1] = fn end }
hooksecurefunc = function(object, name, callback)
    local original = object[name]
    object[name] = function(...)
        local out = table.pack(original(...)); callback(...); return table.unpack(out, 1, out.n)
    end
end
local function flush()
    local rounds = 0
    while #timers > 0 do
        local batch = timers; timers = {}; for _, fn in ipairs(batch) do fn() end
        rounds = rounds + 1; assert(rounds < 20, "timer loop")
    end
end
local enabled = true
local looks
local skin = {
    IsEnabled = function() return enabled end,
    GetAccentColor = function() return 0.047, 0.824, 0.616 end,
    OnLooksChanged = function(fn) looks = fn end,
}
for _, name in ipairs({ "Shell", "Button", "EditBox", "Dropdown", "Inset", "FadeRegions",
    "FadeNineSlice", "Font", "CloseButton", "ScrollBar", "SquareIcon", "Checkbox", "StateButtonLabel" }) do
    skin[name] = function(f) assert(f, name .. " missing frame"); count(name) end
end
local callback
EllesmereUI = { RegisterSkin = function(name, fn) count("registration"); callback = fn end }
ForeverCompanionAPI = {
    COLORS = {},
    CreateWindow = function(name) return frame("Frame", name), nil, "sentinel" end,
    CreateMenuButton = function(parent)
        local f = frame("Button", nil, parent); f.Text = texture("FontString"); return f
    end,
    CreateSearchBox = function(parent) return frame("EditBox", nil, parent) end,
    CreateDropdown = function(parent) return { frame = frame("DropdownButton", nil, parent) } end,
    CreateScrollFrame = function(parent) return frame("ScrollFrame", nil, parent), frame("EventFrame", nil, parent) end,
    AddInset = function() return texture(), frame() end,
    StripedBackground = function() return texture(), texture() end,
    CreateSideTab = function(parent)
        local f = frame("Button", nil, parent); f.icon = texture(); f.sel = texture(); return f
    end,
    CreateOptionsButton = function(parent) local f = frame("Button", nil, parent); f.icon = texture(); return f end,
    VirtualList = function() return { Layout = function() end, Refresh = function() end } end,
}
local chunk = assert(loadfile("EUIAddonSkins/Skin.lua"))
chunk("EUIAddonSkins")
assert(calls.registration == 1 and not calls.Shell, "must wait for API dispatch")
callback(skin)
local api = ForeverCompanionAPI
local f, missing, sentinel = api.CreateWindow("ForeverCompanionFrame")
assert(f and missing == nil and sentinel == "sentinel", "factory return values changed")
local b = api.CreateMenuButton(f)
local clicks = 0; b:SetScript("OnClick", function() clicks = clicks + 1 end)
api.CreateSearchBox(f); api.CreateDropdown(f); api.CreateScrollFrame(f)
local sc = frame("Frame", nil, f)
local list = api.VirtualList(nil, sc)
local tab = api.CreateSideTab(f)
local light, right = api.StripedBackground(f, "light")
local inset = api.AddInset(f)
local check = frame("CheckButton", nil, f)
local secret = frame("EditBox", nil, f); secret.forbidden = true
local protected = frame("EditBox", nil, f); protected.protected = true
local edits = calls.EditBox
flush()
assert(calls.EditBox == edits + 1, "must skin the ordinary input exactly once; skip restricted frames")
assert(light.color[4] == 0.045 and right.color[4] == 0.045)
assert(inset.color[1] == 0.025)
assert(tab.sel.color[2] == 0.824)
b.scripts.OnClick(); assert(clicks == 1, "lost click callback")
local shells = calls.Shell
list:Layout(); list:Layout(); assert(#timers == 1, "updates not coalesced"); flush()
assert(calls.Shell == shells, "rescan must not fade window content again")
local newCheck = frame("CheckButton", nil, sc)
local checks = calls.Checkbox; list:Layout(); flush()
assert(calls.Checkbox == checks + 1, "new pooled row control not discovered")
looks(); flush()
enabled = false
local before = calls.Shell; api.CreateWindow("AnotherWindow"); flush()
assert(calls.Shell == before, "EUI master/per-addon disable ignored")
enabled = true
SlashCmdList.EUIADDONSKINS("off")
api.CreateWindow("DisabledWindow"); assert(calls.Shell == before)
SlashCmdList.EUIADDONSKINS("on")
api.CreateWindow("EnabledWindow"); flush(); assert(calls.Shell == before + 1)
assert(#errors == 0, table.concat(errors, "\n"))
-- Missing API must leave FC unchanged and expose a usable status command.
EllesmereUI = nil
local original = api.CreateWindow
chunk("EUIAddonSkins")
assert(api.CreateWindow == original)
SlashCmdList.EUIADDONSKINS("")
print("PASS: syntax, registration, preserved nil returns/clicks, lazy rows, coalescing, restricted frames, theme updates, toggles, missing API")
