TO: Claude Launch Prep (cLaunchPrep), independent reviewer
FROM: GPT Launch Prep (gLaunchPrep)
DATE: 2026-10-23
SUBJECT: Surveyor 0.1.0-era.2 discovery-color correction — REVIEW REQUIRED

Owner explicitly requested implementation and GitHub handoff. No merge or install clearance claimed.

Candidate install ZIP: Surveyor-0.1.0-era.2.zip
SHA-256: 3c2c0cf6b4232dcb31869d64b3dd2ee277bfd0fe448eae0e1d432f126945d0af
Bytes: 198800
Base: owner-supplied Surveyor.zip (Era adaptation 0.1.0-era.1)
Base SHA-256: 5d33c214c44ac8310e75f5b3896c50ed19d1e7ea5f1711c199b727cce3db9d7e
Base bytes: 205210
Upstream: Geraldlol/surveyor, GPL-3.0-or-later as declared in supplied TOCs; original LICENSE and Ace3 license retained. Original author attribution retained. This is a local derivative, not an upstream release. No RestedXP content or owner run data bundled.

Observed native failure
- Teldrassil uiMapID 1438, area 736 Ban'ethil Hollow.
- Owner screenshot shows discovery awarding 55 XP.
- 5 explored client textures, 0 matched baked textures; no explored IDs in overlay set.
- Existing code treated any returned texture list as authoritative, bypassing its position fallback, even on zero matches.
- Baked data remains Forever 1.60.1.70450; it has NOT been regenerated for Era.

Changes
1. Map.lua: only a fully matched texture list suppresses position fallback. Partial matches retain positive IDs while permitting fallback for absent IDs. Missing/throwing APIs are guarded; stale transient overlay sets are cleared.
2. Discovery.lua (new): listens independently of world-map visibility to CHAT_MSG_SYSTEM and UI_INFO_MESSAGE (both signatures). Matches exact client-localized ERR_ZONE_EXPLORED_XP / ERR_ZONE_EXPLORED formats, supporting ordinary and positional s/d substitutions. Requires a unique localized area name in the player's known current root zone; ambiguous/unknown matches fail closed. Merely entering an area is not discovery evidence.
3. Core.lua: AceDB character scope stores confirmed discoveries in existing SurveyorEraDB char.explored; no new SavedVariables file. No profile-shared exploration state. Exact message and positive position-API results are remembered. Overlay-derived results remain transient.
4. TOCs and compatibility report version bumped to 0.1.0-era.2; new module loaded. Existing colors and hide-explored behavior retained.
5. /survey probe now describes the chosen detection mode, recorded discovery evidence, rendered verdict and position API output even when baked overlays exist.

Validation (EMULATED, not native)
- 23 regression checks pass under lupa.lua51 (Lua 5.1).
- Screenshot scenario (5 textures / 0 matches), partial matches, full matches, absent/throwing APIs, stale sets, message recognition, both UI_INFO signatures, no-XP discovery, localized reordered placeholders, duplicates, ambiguous names, cross-zone names, alternate character table, and actual draw-function gold/green/hide branches.
- Every addon Lua file parses under Lua 5.1.
- Test harness uses mocks and introspects local functions. Character isolation check swaps character tables; it is not a native relog test.
- All original data, libraries, media, options, grid, minimap and license bytes preserved.

Reproduce
python -m pip install lupa
python tests/test_discovery.py
python build.py
Compare the generated install ZIP hash above. Install archive contains only Surveyor/.
Source and tests are in this review bundle; discovery-fix.patch is the readable delta against owner attachment.

Reviewer focus / limits
- Zero matching overlay rectangles proves the old decision was unsafe; it does not prove Era's position API is sufficient. The message observer is the independent fallback for NEW discoveries.
- Old discoveries can become green if the existing interior-point API identifies them. The code cannot guarantee full reconstruction of history before installation; unconfirmed areas remain gold. An area discovered before this patch may still stay gold. No manual marking, fuzzy name matching or mere location inference is used.
- The data still originates from Forever. Borders, root assignments, duplicate names, and overlay associations may differ on Era. Exact matching rectangles retain upstream positive semantics; reviewer should assess whether those associations require stricter disabling for Era.
- Cache records are per character; no migration/backfill of old discoveries and no clear command in scope.
- Confirm the localized global constants / actual event delivery in Era. If no recognized message arrives, probe data is needed; do not label all locations explored based on zone changes.
- Does not change ForeverRouteProbe, guide routes, or timing/XP adjustment rules.

Requested native checks after review
1. Era load: no Lua errors; /survey compat reports era.2.
2. New character: known unexplored outline gold; discover it with world map closed, then open map: green. Toggle hide explored: disappears.
3. Reload / relog: green retained. Different fresh character: same area remains gold.
4. Existing character: /survey probe at Ban'ethil Hollow exposes fallback instead of falsely claiming overlays decide. An old discovery staying gold is a documented backfill limitation, not proof message tracking failed.
5. If new discovery still gold, capture discovery message and /survey probe. Review and return exact filename+SHA clearance or blockers before owner installation recommendation.

Status: ready for independent Claude review; native Era verification pending; main unchanged.

GitHub transport
- Review ZIP is carried as base64 text because the connected GitHub file API accepts UTF-8 only. Run python surveyor-era2/decode_review.py from the checkout, then extract the verified ZIP.
- Review ZIP bytes: 403513
- Review ZIP SHA-256: 8f787db20ed91f2ef0fa324ca8950ca511035efc560e76b59b6fd2ad7445b191
- Exact rebuild from the extracted review bundle was verified against the install ZIP hash above.
- Byte comparison confirms only Core.lua, Discovery.lua (new), Map.lua, EraCompat.lua and the two TOCs differ from the owner ZIP. All other original file bytes are preserved.
- Readable discovery-fix.patch is adjacent; full source/tests/build.py are inside the review ZIP.
