local ADDON, ns = ...
ns.RegisterScopedSkin("ItemRack", "ItemRack", {
    available = function() return _G.ItemRack ~= nil end,
    roots = function()
        local result = ns.SkinRoots({"ItemRackOptFrame", "ItemRackLogFrame"}, {bottomBar = 24})
        if _G.ItemRackOpt and _G.ItemRackOpt.QueueIconPicker then result[#result + 1] = {frame = _G.ItemRackOpt.QueueIconPicker} end
        return result
    end,
    hooks = function(C, refresh)
        C.H.Hook(_G.ItemRack, "ToggleOptions", refresh)
        C.H.Hook(_G.ItemRack, "SlashHandler", refresh)
        for _, method in ipairs({"TabOnClick", "ShowPrevSubFrame", "ToggleEventEditor", "OpenQueueIconPicker",
            "QueueIconPickerUpdate", "RefreshQueueIconPage", "LayoutQueueControls", "UpdateInv"}) do C.H.Hook(_G.ItemRackOpt, method, refresh) end
    end,
    visit = function(C, f, kind)
        if (kind == "Button" or kind == "CheckButton") and f.GetName then
            local name = f:GetName() or ""
            if name:match("^ItemRackOptTab%d+$") then return C.H.Tab(f, f.IsEnabled and not f:IsEnabled()) end
            if name == "ItemRackOptClose" or name == "ItemRackOptSetListClose" or name == "ItemRackOptSortListClose" then
                C.S.CloseButton(f); return true
            end
            if name:match("^ItemRackOpt.*Icon%d+$") or name:match("^ItemRackOptInv%d+$") then
                local t = _G[name .. "Icon"] or (f.GetNormalTexture and f:GetNormalTexture())
                if t then C.S.SquareIcon(t, f) end
                return true
            end
        end
        -- Equipment/action buttons outside options are protected and stay intact.
    end,
})
