# Details development alpha

Version: `1.2.0-alpha`. This is an **untagged** development build on `details-alpha`.
Do not create a Git tag or GitHub Release until CurseForge distribution is wanted.
The existing tag-only CurseForge webhook does not package this branch push.

## Included

- Meter backgrounds, header decoration, close control, row fonts, bar textures, height and spacing.
- Options, breakdown and report windows; ordinary buttons, switches, dropdowns, inputs, scrollbars and sliders.
- Details-owned Cooltip menus and submenus. Shared popup backdrops/fonts are restored when ownership changes.
- Optional EUI meter appearance matching, without a dependency on its renderer.

Install the test ZIP's `EUIAddonSkins` folder in `Interface/AddOns/`, replacing the previous folder. Details, EllesmereUI and EllesmereUIBlizzardSkin are installed separately. The Details! toggle appears with the other third-party skins in EllesmereUI.

## Boundaries

This is a first styling preview, not a replacement for Details' renderer. Additional plugin windows and exact pixel parity with EUI's meter are not guaranteed. Details retains its own information layout, class/spec icons, custom text, combat data, window positions and actions. Native row appearance setters intentionally update Details' cosmetic row settings; they do not change window placement or combat configuration.

Fonts use EUI's public font getters. The optional `_EDM_DB.profile.dm` and `_EDM_BarTextures` exports are read only and guarded; these are compatibility reads, not a promised public skinning contract. If unavailable, the skin uses EUI fonts with conservative meter defaults. No EUI or Details code/assets are bundled. The meter's special Blizzard/Classic/Forever border renderers are not copied. Meter-only setting changes can be picked up with `/euiskins refresh` if EUI does not broadcast a theme refresh.

Source inspection used the supplied upstream repositories' current default branches. Automated tests simulate WoW frames, Details events and styling APIs; they cannot verify the actual client appearance. No in-game verification is claimed.

## Verification

Run `python3 scripts/package.py`. It validates Lua syntax, executes all regression suites, checks TOC paths and includes all nineteen skins and the MIT license in the install-ready ZIP. Development files and upstream reference sources stay outside the package.

The Details suite covers optional loading, new windows/rows, native return values/actions, untouched data/positions, theme changes, combat deferral, disabled skins, shared menu restoration and warm refresh reuse. No polling or combat parser hooks are introduced.
