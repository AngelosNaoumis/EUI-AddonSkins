# EUI AddonSkins

A modular collection of World of Warcraft addon skins using the official
EllesmereUI skinning API. Each skin activates only when its target addon is installed
and loaded. You do not need Forever Companion to use EUI AddonSkins.

Version **0.2.0** includes **Forever Companion** as its first optional skin.
More integrations can be added as separate modules.

## Requirements

- EllesmereUI with `EllesmereUI.RegisterSkin` and the public skinning API.
- EllesmereUI **Blizzard Skins+**, enabled.
- Any supported target addon you want to skin. None of the target addons is mandatory.

The included Forever Companion integration was developed against the supplied
Forever Companion 1.0.0 build for WoW Forever (Interface 16001).
Other Forever Companion variants have not been tested.

## Installation

1. Extract the download. If you download GitHub's source ZIP, open its outer project folder.
2. Copy only the `EUIAddonSkins` folder into your WoW client's `Interface/AddOns/` folder.
3. Check that the TOC file is at `Interface/AddOns/EUIAddonSkins/EUIAddonSkins.toc`.
4. Enable EUI AddonSkins, EllesmereUI and EllesmereUI Blizzard Skins+ in the addon list.
5. Restart the game if you installed while it was running. Open your supported addons normally.

EllesmereUI selects the EllesmereUI or Modern theme using its own window settings.
The collection appears as `EUIAddonSkins` in its third-party skins list.
Theme and accent changes update the skinned elements live.

## Included skins

| Addon | Status | Coverage |
| --- | --- | --- |
| Forever Companion | Optional, first test version | BiS, rotation, talents, consumables, loot, professions, market, options and companion dialogs |

The Forever Companion skin covers window backgrounds, borders, close buttons,
ordinary buttons, search fields, dropdown controls, scrollbars, icon tabs,
checkboxes, row backgrounds and dynamically created controls.
Item icons, equipped-item indicators, talent artwork and click actions are preserved.
Game tooltips, minimap buttons, map markers, dropdown popup menus, regular options
sliders and Blizzard auction-house frames retain their existing appearance.

## Commands

- `/euiskins` or `/euiskins list` — version and module status.
- `/euiskins off` — disable the collection, then run `/reload`.
- `/euiskins on` — enable the collection, then run `/reload`.
- `/euiskins refresh` — discover new controls and refresh loaded modules.

`/fcskin` remains a compatibility alias. You can also disable the collection through
EllesmereUI's third-party skins settings. Disabling requires `/reload` to remove
visual changes already applied. To uninstall, remove only the `EUIAddonSkins` folder
and restart the game.

## Validation and troubleshooting

Lua syntax and integration behavior are tested in a simulated WoW environment,
including missing targets, load-on-demand activation and independent skin modules.
Appearance and behavior still need verification in WoW.

For Forever Companion, open each side tab, change class/spec/phase and scroll.
Switch options pages; test checkboxes, search and dropdowns. Check tooltips, clicks,
equipped-item borders, close buttons and Escape. Try changing the EUI theme/accent
and disabling the collection followed by `/reload`.

If a problem occurs, enable Lua errors with `/console scriptErrors 1`, run `/reload`
and report the error. Include the affected addon/version and a screenshot if useful.
An absent target is reported as `not installed or not loaded`; this is normal.

## Adding skins

Each integration lives in `Skins/` and calls
`ns.RegisterModule(id, label, available, install)`. The core registers one collection
with EllesmereUI, passes the official skin facade to available modules and checks
again on `ADDON_LOADED` for load-on-demand targets. Failed installers are isolated.
Optional target dependencies provide load ordering without requiring those addons.

The Forever Companion module wraps its public frame factories and preserves return
values and callbacks. Deferred scans coalesce refresh bursts; it uses no global
`CreateFrame` hook, polling or `OnUpdate`. Forbidden/protected frames are skipped.

To propose another skin, provide the addon's ZIP, version and the windows you want
covered. Reference screenshots help verify the result. Future target updates that
change frame factories may require corresponding skin updates.

## Development

Run `python3 tests/run_lua.py` from the repository root. The harness requires Python 3
and the system library `liblua5.4.so.0` on Linux.

API reference: https://github.com/EllesmereGaming/EllesmereUI/blob/main/SKINNING_API.md

This is an independent community project, not an official EllesmereUI release.
