# Releases

Use CurseForge's official Auto-Packager. GitHub is the source of truth; ordinary commits must not publish files. No GitHub Actions uploader is required.

## One-time integration

In the CurseForge project's source/repository settings, select GitHub, use `https://github.com/oopsie-glitch/EUI-AddonSkins`, and select **Package tagged commits only**. The repository is public.

Create a CurseForge API token in the account's API tokens page. In GitHub repository **Settings > Webhooks**, add the project's CurseForge packaging endpoint with that token, using the exact project ID from CurseForge. Keep GitHub's default push event, active webhook and SSL verification enabled. Tag pushes are push events; a release-event-only webhook will not implement this workflow. Follow the official guide's remaining defaults.

Treat the token-bearing webhook URL as a secret. Enter it directly in the account settings; never put it in this repository, documentation, screenshots or chat. A GitHub webhook Secret field is not a substitute for CurseForge's API token.

Confirm tag-only mode on CurseForge and a successful webhook delivery before the first release tag. A successful GitHub ping/delivery verifies endpoint reachability, not a published addon package. Validate the generated CurseForge file after the first tag. Keep the project license set to MIT License. .pkgmeta declares the verified EllesmereUI project slug as a required dependency; confirm that relation on the generated CurseForge file. Supported addons remain optional.

## Versions

Update both `EUIAddonSkins/EUIAddonSkins.toc` (`## Version`) and `EUIAddonSkins/Core.lua` (`ns.VERSION`). Maintain matching release headings in root `CHANGELOG.md` and the addon copy. Version metadata excludes the tag's leading `v`.

| Tag | Addon version | CurseForge type |
| --- | --- | --- |
| v1.0.0 | 1.0.0 | Release |
| v1.0.1 | 1.0.1 | Release: fixes |
| v1.1.0 | 1.1.0 | Release: features/skins |
| v2.0.0 | 2.0.0 | Release: major change |
| v1.1.0-beta | 1.1.0-beta | Beta |
| v1.1.0-alpha | 1.1.0-alpha | Alpha |

CurseForge classifies tags containing `alpha` or `beta` accordingly; other release tags use Release. Do not use untagged packaging. Keep GitHub prerelease status consistent for alpha/beta releases.

## Release procedure

1. Update versions/changelog and review the diff. Keep dependencies optional except EllesmereUI and its Blizzard Skins+ module.
2. Run `python3 tests/run_lua.py` and `python3 scripts/package.py`. Inspect the validated local ZIP against the intended CurseForge manifest. This existing script is a local check only; it does not upload or trigger CurseForge.
3. Commit and push preparation to main. Confirm the CurseForge source setting, tag-only mode, webhook endpoint and delivery status. Stop if authorization or validation is outstanding.
4. Only after those checks, create the annotated version tag on the validated preparation commit and push it:

   ```sh
   git tag -a v1.0.0 -m "EUI AddonSkins 1.0.0"
   git push origin v1.0.0
   ```

5. CurseForge's push webhook queues the tagged build. Check packaging logs and the generated file's release type, game versions and approval/publication status.
6. Download and inspect the generated ZIP: one `EUIAddonSkins/` installation directory, its TOC, all referenced Lua files, all fourteen skins and the exact MIT LICENSE. No development directories or nested `EUIAddonSkins/EUIAddonSkins/`. Any packager-generated changelog must not create another installation directory.
7. Publish the corresponding GitHub Release from the existing tag, using the prepared notes in `docs/releases/v1.0.0.md`. Do not let GitHub create a tag on an unvalidated commit. Prefer the verified CurseForge addon ZIP if attaching a binary; GitHub's automatic source archives include development files and are not installation packages.

Published tags are immutable release identifiers. Fixes require a new patch version; do not delete/recreate a release tag to hide a packaging failure.

## Packaging layout

`.pkgmeta` sets `package-as: EUIAddonSkins`. CurseForge initially wraps the checkout under that name. Its `move-folders` mapping promotes `EUIAddonSkins/EUIAddonSkins` into `EUIAddonSkins`, keeping the existing repository layout without nesting. Ignore paths refer to the checkout before that move.

The addon LICENSE is already tracked and matches the repository's canonical MIT LICENSE. No externals or generated license override is needed. Root and addon README/changelog copies remain in GitHub but are excluded from installation files. The root changelog supplies the CurseForge file-page changelog through `manual-changelog`.

Expected payload: 21 files, all inside `EUIAddonSkins/`: the TOC, Core.lua, Accent.lua, Widgets.lua, Scoped.lua, Menus.lua, LICENSE and the fourteen files under Skins/. There are no separate runtime assets or bundled third-party notices required by the current source inventory.

## Current preparation status

- Runtime version: 1.0.0; unchanged by packaging preparation.
- No tags or GitHub Releases existed when preparation began.
- Repository source inventory and an in-memory ignore/move projection were checked. All TOC paths, load order, fourteen skins and matching licenses were verified.
- The ten Lua suites and the previous 23-file local ZIP passed before this task on the unchanged 1.0.0 runtime. The new intended installation payload omits the two Markdown documents and contains 21 files.
- The current local execution environment is unavailable. Lua syntax/mock suites and the updated local packaging script could not be rerun, and no new ZIP was generated or opened in this turn. The in-memory manifest check is not an executed official packager build.
- The official CurseForge service could not be executed or inspected with the available tools. Account source settings, webhook presence/deliveries, supported game-version interpretation (including Forever's 16001 TOC value), generated metadata and publication status remain unverified.
- **v1.0.0 is deliberately untagged and unpublished.** Verify integration and rerun the existing checks before tagging.

## Official references

- [Preparing the PackageMeta File](https://support.curseforge.com/support/solutions/articles/9000197952-preparing-the-packagemeta-file): package-as, Source: Destination moves, ignore-before-move behavior, manual changelogs and dependencies.
- [Automatic Packaging](https://support.curseforge.com/support/solutions/articles/9000197281): webhook setup, push/tag packaging and alpha/beta classification.

The compatible BigWigs packager's source was inspected as a secondary implementation reference for promoting a child into its parent. It is not the configured release service and was not installed or executed. Official-service output must still be inspected before calling the workflow verified.
