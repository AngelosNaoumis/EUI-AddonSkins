local ADDON, ns = ...
ns.RegisterModule("TwitchEmotes", "TwitchEmotes", function()
    return _G.EmoticonMiniMapDropDown ~= nil
end, function(S, module)
    local function refresh()
        ns.BindPopupOwner(S, module, _G.EmoticonMiniMapDropDown)
    end
    refresh()
    module.refresh = refresh
    if S.OnLooksChanged then S.OnLooksChanged(refresh) end
end)
