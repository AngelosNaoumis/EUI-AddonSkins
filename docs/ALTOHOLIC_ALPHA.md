# Altoholic local alpha

Version: `1.2.1-alpha.1`, based on stable `v1.2.0` (`b8e0125`). This build is local only: do not push its source, tag it or publish a release until requested.

AddonFactory stores scrollbar border textures on the parent ScrollFrame. The Altoholic adapter now fades those named decorative textures and uses an 8 × 18 vertical thumb with full texture coordinates. Slider hit areas, anchors, values, ranges, mouse-wheel handling and native arrow actions remain unchanged.

Altoholic creates twelve summary cells, but `DrawRealmLine` hides only cells 2–10. The adapter hides cells 11–12 on realm rows, including initial scans and subsequent row redraws. Character rows retain access to all cells. No upstream files are modified.

Run `python3 scripts/package.py` for all regression suites and installation ZIP validation. Tests cover native scrollbar art, thumb dimensions, preserved arrow actions/ranges/anchors, realm-to-character row reuse, repeat refreshes, combat deferral and disabled integrations. Actual in-game appearance has not been verified.
