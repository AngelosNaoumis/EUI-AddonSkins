local ADDON, ns = ...
local WHITE = "Interface\\Buttons\\WHITE8X8"

-- The meter module exposes its active profile/texture registry for its options.
-- Read them only when present; never require the module or mutate its profile.
function ns.GetMeterStyle(S)
    local EUI = _G.EllesmereUI or {}
    local db = _G._EDM_DB
    local cfg = db and db.profile and db.profile.dm or {}
    local font, flags = S.GetFont()
    if EUI.GetFontPath then font = EUI.GetFontPath("damageMeters") or font end
    if EUI.GetFontOutlineFlag then flags = EUI.GetFontOutlineFlag("damageMeters") or flags end
    local textures = _G._EDM_BarTextures
    if not textures and EUI.BuildBarTextureTables then textures = EUI.BuildBarTextureTables(true) end
    local texture = textures and textures[cfg.barTexture or "atrocity"] or WHITE
    if EUI.ResolveTexturePath and textures then
        texture = EUI.ResolveTexturePath(textures, cfg.barTexture or "atrocity", WHITE)
    end
    local r, g, b = S.GetAccentColor()
    local title = cfg.hdrTextUseAccent == false and cfg.hdrTextColor or {r = r, g = g, b = b}
    return {font = font, flags = flags or "", texture = texture or WHITE,
        height = cfg.barHeight or 18, spacing = cfg.barSpacing or 2,
        leftSize = cfg.leftFontSize or cfg.fontSize or 11,
        rightSize = cfg.rightFontSize or cfg.fontSize or 11,
        bg = {cfg.bgR or 0, cfg.bgG or 0, cfg.bgB or 0, cfg.bgAlpha or 0.75},
        header = cfg.hdrBgColor or {r = 27/255, g = 27/255, b = 27/255},
        headerAlpha = cfg.hdrBgAlpha or 1, headerHeight = cfg.hdrHeight or 22,
        headerSize = cfg.hdrFontSize or 11, iconSize = cfg.hdrIconSize or 22,
        titleColor = {title and title.r or r, title and title.g or g, title and title.b or b, 1}}
end

