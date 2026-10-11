local ADDON, ns = ...
local function Public()
    return LibStub and LibStub("Myslot-5.0", true)
end
ns.RegisterScopedSkin("Myslot", "Myslot", {
    available = function() local lib = Public(); return (lib and lib.MainFrame ~= nil) or (C_AddOns and C_AddOns.IsAddOnLoaded("Myslot")) end,
    roots = function()
        local lib = Public()
        return lib and lib.MainFrame and {{frame = lib.MainFrame, options = {bottomBar = 38}}} or {}
    end,
    -- The public library exposes the main import/export/profile window. Its
    -- private UIParent-owned import progress dialog has no stable public handle.
})
