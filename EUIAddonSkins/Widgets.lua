local ADDON, ns = ...

-- Scoped utilities for integrations without public frame factories. Never scan UIParent.
function ns.CreateSkinHelper(S, module)
    local H = {}
    local known, hooks, shells = {}, {}, {}
    local pending, queued = {}, false
    local failures = {}
    function H.Allowed(f)
        return f and f.GetObjectType and not (f.IsForbidden and f:IsForbidden())
            and not (f.IsProtected and f:IsProtected())
    end
    function H.Safe(fn, ...)
        local ok, err = pcall(fn, ...)
        if not ok and not failures[tostring(err)] then
            failures[tostring(err)] = true
            geterrorhandler()(ADDON .. ": " .. tostring(err))
        end
    end
    function H.Hook(object, name, callback)
        if not object or type(object[name]) ~= "function" then return end
        local h = hooks[object]
        if not h then h = {}; hooks[object] = h end
        if h[name] then return end
        h[name] = true
        hooksecurefunc(object, name, function(...)
            if ns.IsEnabled(module) then H.Safe(callback, ...) end
        end)
    end
    function H.Script(f, name, callback)
        if not H.Allowed(f) or not f.HookScript then return end
        if f.HasScript and not f:HasScript(name) then return end
        local h = hooks[f]
        if not h then h = {}; hooks[f] = h end
        local key = "script:" .. name
        if h[key] then return end
        h[key] = true
        f:HookScript(name, function(...)
            if ns.IsEnabled(module) then H.Safe(callback, ...) end
        end)
    end
    function H.Queue(key, callback)
        if not ns.IsEnabled(module) then return end
        pending[key] = callback
        if queued then return end
        queued = true
        C_Timer.After(0, function()
            queued = false
            local batch = pending; pending = {}
            if not ns.IsEnabled(module) then return end
            for _, fn in pairs(batch) do H.Safe(fn) end
        end)
    end
    function H.Fade(texture)
        if not texture or not texture.SetAlpha then return end
        texture:SetAlpha(0)
        local lock = false
        H.Hook(texture, "SetAlpha", function(_, value)
            if value == 0 or lock then return end
            lock = true; texture:SetAlpha(0); lock = false
        end)
    end
    function H.Font(text, r, g, b)
        if text and text.GetObjectType and text:GetObjectType() == "FontString" then S.Font(text, r, g, b) end
    end
    function H.Shell(f, refresh, options)
        if not H.Allowed(f) then return end
        if not shells[f] then
            shells[f] = true
            local icons = {}
            for _, region in ipairs({f:GetRegions()}) do
                if region.GetTexture then
                    local path = region:GetTexture()
                    if type(path) == "string" and path:lower():find("interface[/\\]icons") then
                        icons[region] = region:GetAlpha()
                    end
                end
            end
            S.Shell(f, options)
            for region, alpha in pairs(icons) do region:SetAlpha(alpha) end
            -- BackdropTemplate backgrounds are separate from the engine's new shell.
            if f.SetBackdrop then f:SetBackdrop(nil) end
            if f.NineSlice then S.FadeNineSlice(f.NineSlice) end
        end
        H.Script(f, "OnShow", refresh)
    end
    function H.Scan(root, refresh, visit, exclude)
        local function walk(f, depth)
            if depth > 16 or not H.Allowed(f) or (exclude and exclude[f]) then return end
            local kind = f:GetObjectType()
            if kind == "GameTooltip" or kind == "PlayerModel" or kind == "ModelScene" then return end
            if not known[f] then
                known[f] = true
                if kind == "CheckButton" then S.Checkbox(f)
                elseif kind == "EditBox" then S.EditBox(f)
                elseif kind == "DropdownButton" then S.Dropdown(f)
                elseif kind == "Slider" and f.GetThumbTexture and f.GetOrientation and f:GetOrientation() == "VERTICAL" then S.ScrollBar(f)
                elseif kind == "Button" then
                    local label = f.GetFontString and f:GetFontString()
                    -- A real template label identifies an ordinary text button.
                    -- Custom icon/item/quest rows are styled by the integration.
                    if label and not f.icon and not f.Icon then
                        S.Button(f); if S.StateButtonLabel then S.StateButtonLabel(f) end
                    elseif f.GetNormalTexture then
                        local t = f:GetNormalTexture()
                        local path = t and t.GetTexture and t:GetTexture()
                        if type(path) == "string" and path:find("UI%-Panel%-MinimizeButton") then S.CloseButton(f) end
                    end
                end
                for _, region in ipairs({ f:GetRegions() }) do
                    if region:GetObjectType() == "FontString" then S.Font(region) end
                end
                if kind == "Button" or kind == "CheckButton" then H.Script(f, "OnClick", refresh) end
                H.Script(f, "OnShow", refresh)
                if kind == "ScrollFrame" then
                    H.Script(f, "OnVerticalScroll", refresh)
                    if f.ScrollBar then S.ScrollBar(f.ScrollBar) end
                end
            end
            if visit then visit(f, kind) end
            for _, child in ipairs({ f:GetChildren() }) do walk(child, depth + 1) end
        end
        if ns.IsEnabled(module) then walk(root, 0) end
    end
    return H
end
