# Details development alpha

Version: `1.2.0-alpha.6`. This is an **untagged** development build on `details-alpha`.
Do not create a Git tag or GitHub Release until CurseForge distribution is wanted.
The existing tag-only CurseForge webhook does not package this branch push.

## Included

- Meter backgrounds, an independent dark header, EUI title/timer styling, native toolbar controls, row fonts, bar textures, height and spacing.
- Native total (DPS/HPS) formatting with the value column at the right edge; header and footer art suppressed without removing native actions.
- Options, breakdown and report windows; ordinary buttons, switches, dropdowns, inputs, scrollbars and sliders.
- Details-owned Cooltip menus and submenus. Shared popup backdrops/fonts are restored when ownership changes.
- Optional EUI meter appearance matching, without a dependency on its renderer.

Install the test ZIP's `EUIAddonSkins` folder in `Interface/AddOns/`, replacing the previous folder. Details, EllesmereUI and EllesmereUIBlizzardSkin are installed separately. The Details! master toggle appears with the other third-party skins in EllesmereUI. Open `/euidetails` (or Settings > AddOns > EUI AddonSkins: Details) for two independent switches:

- **Skin menus and options**: enabled by default; reload after changing it.
- **Match EUI meter appearance**: disabled by default. Enabling it captures the current managed appearance settings. Disabling restores those settings; UI work waits until out of combat.

Backups are scoped to character, realm, Details profile and window ID. A recovery path restores saved row settings even if EUI does not dispatch the disabled skin after a reload. Settings captured by an older alpha cannot be reconstructed retroactively. The original first alpha changed cosmetic row settings without a backup; this version captures the current settings when first enabled.

## Boundaries

This is a first styling preview, not a replacement for Details' renderer. Additional plugin windows and exact pixel parity with EUI's meter are not guaranteed. Native button visibility and actions are preserved, so the toolbar can have different controls. The combat timer uses the selected Details segment; unavailable/secret times are left blank. Installed EUI meter icons are referenced only when that module is loaded; otherwise native icons are retained. Details retains its class/spec icons, combat data, window positions and actions. Matching temporarily supersedes right-hand custom formats; they are backed up and restored when it is disabled. While meter matching is enabled, the skin manages row height, spacing, texture and native combined-number formatting, plus runtime fonts/header decoration and toolbar positions. Those settings follow EUI until matching is switched off. Other Details appearance settings remain native. The meter design is still a preview; these switches establish the modular behaviour before further layout refinement.

Fonts use EUI's public font getters. The optional `_EDM_DB.profile.dm` and `_EDM_BarTextures` exports are read only and guarded; these are compatibility reads, not a promised public skinning contract. If unavailable, the skin uses EUI fonts with conservative meter defaults. No EUI or Details code/assets are bundled. The meter's special Blizzard/Classic/Forever border renderers are not copied. Meter-only setting changes can be picked up with `/euiskins refresh` if EUI does not broadcast a theme refresh.

Source inspection used the supplied upstream repositories' current default branches. Automated tests simulate WoW frames, Details events and styling APIs; they cannot verify the actual client appearance. No in-game verification is claimed.

## Verification

Run `python3 scripts/package.py`. It validates Lua syntax, executes all regression suites, checks TOC paths and includes all nineteen skins and the MIT license in the install-ready ZIP. Development files and upstream reference sources stay outside the package.

The Details suite covers optional loading, new windows/rows, native return values/actions, untouched data/positions, theme changes, combat deferral, disabled skins, shared menu restoration and warm refresh reuse, independent modes, restoration after repeated toggles and disabled-skin reload recovery, hidden native title bars, toolbar redraws and late startup width/height changes, timer changes and secret-value guards. No polling or combat parser hooks are introduced.

Header icons are drawn on the matching header independently of native button opacity. Native visibility, hover tooltips and click actions remain in use.

Details-owned Cooltip pop-outs and submenus use flat EUI panels, accent hover fills and subtle separators. Native rounded/background layers are suppressed only for Details; warning icons, arrows, status values and actions stay native. Original artwork, fonts and corner mode are restored on hide, owner transfer or disabling menu styling.
