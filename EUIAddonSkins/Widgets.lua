local ADDON, ns = ...

-- Scoped utilities for integrations without public frame factories. Never scan UIParent.
function ns.CreateSkinHelper(S, module)
    local H = {}
    local known, hooks, shells, tabs = {}, {}, {}, {}
    local pending, queued = {}, false
    local failures = {}
    local empty, faded, scrolls = {}, {}, {}
    function H.Children(f)
        if f.GetNumChildren and f:GetNumChildren() == 0 then return empty end
        return {f:GetChildren()}
    end
    function H.Regions(f)
        if f.GetNumRegions and f:GetNumRegions() == 0 then return empty end
        return {f:GetRegions()}
    end
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
            for key, fn in pairs(batch) do
                -- A queued full integration refresh already covers scroll subtrees.
                if not (batch[module] and scrolls[key]) then H.Safe(fn) end
            end
        end)
    end
    function H.Fade(texture)
        if not texture or not texture.SetAlpha then return end
        if not texture.GetAlpha or texture:GetAlpha() ~= 0 then texture:SetAlpha(0) end
        if faded[texture] then return end
        faded[texture] = true
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
            for _, region in ipairs(H.Regions(f)) do
                if region.GetTexture then
                    local path = region:GetTexture()
                    if type(path) == "string" and path:lower():find("interface[/\\]icons") then
                        icons[region] = region:GetAlpha()
                    end
                end
            end
            S.Shell(f, options)
            ns.AttachAccent(S, f)
            for region, alpha in pairs(icons) do region:SetAlpha(alpha) end
            -- BackdropTemplate backgrounds are separate from the engine's new shell.
            if f.SetBackdrop then f:SetBackdrop(nil) end
            if f.NineSlice then S.FadeNineSlice(f.NineSlice) end
        end
        H.Script(f, "OnShow", refresh)
    end
    function H.Tab(f, selected)
        if not H.Allowed(f) or not S.Tab then return false end
        if not tabs[f] then S.Tab(f); tabs[f] = true end
        if S.SetTabSelection then S.SetTabSelection(f, selected) end
        return true
    end
    function H.Scan(root, refresh, visit, exclude)
        -- Update existing scroll contexts even when an ancestor becomes excluded.
        for _, context in pairs(scrolls) do
            if context.root == root then
                context.refresh, context.visit, context.exclude = refresh, visit, exclude
            end
        end
        local function walk(f, depth)
            if depth > 16 or not H.Allowed(f) or (exclude and exclude[f]) then return end
            local kind = f:GetObjectType()
            if kind == "GameTooltip" or kind == "PlayerModel" or kind == "ModelScene" then return end
            if kind == "ScrollFrame" then
                local context = scrolls[f]
                if not context then
                    context = {root = root}; scrolls[f] = context
                    context.apply = function() H.Scan(f, context.refresh, context.visit, context.exclude) end
                    H.Script(f, "OnVerticalScroll", function()
                        -- Exclusions can belong to ancestors outside this subtree.
                        if context.exclude then context.refresh() else H.Queue(f, context.apply) end
                    end)
                end
                context.refresh, context.visit, context.exclude = refresh, visit, exclude
            end
            local handled = visit and visit(f, kind)
            if not known[f] then
                known[f] = true
                if handled then -- Integration-owned tab/control.
                elseif kind == "StatusBar" and S.ApplyBarFill then
                    S.ApplyBarFill(f)
                    local painting = false
                    H.Hook(f, "SetStatusBarColor", function()
                        if painting then return end
                        painting = true; S.ApplyBarFill(f); painting = false
                    end)
                elseif kind == "CheckButton" then S.Checkbox(f)
                elseif kind == "EditBox" then S.EditBox(f, {padInput = true})
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
                if S.SquareIcon and kind == "Button" and (f.icon or f.Icon) then
                    -- The optional border surrounds the supplied frame. Only
                    -- use it for square icon controls, never full-width item rows.
                    local square = f.GetWidth and f.GetHeight and f:GetWidth() == f:GetHeight()
                    S.SquareIcon(f.icon or f.Icon, square and f or nil)
                end
                for _, region in ipairs(H.Regions(f)) do
                    if region:GetObjectType() == "FontString" then S.Font(region) end
                end
                if kind == "Button" or kind == "CheckButton" then
                    H.Script(f, "OnClick", refresh)
                    H.Script(f, "OnEnable", refresh)
                    H.Script(f, "OnDisable", refresh)
                end
                H.Script(f, "OnShow", refresh)
                if kind == "ScrollFrame" then
                    if f.ScrollBar then S.ScrollBar(f.ScrollBar) end
                end
            end
            if S.SortHeaderBar and f.HeaderContainer and f.HeaderContainer.GetChildren then S.SortHeaderBar(f) end

            for _, child in ipairs(H.Children(f)) do walk(child, depth + 1) end
        end
        if ns.IsEnabled(module) then walk(root, 0) end
    end
    return H
end
