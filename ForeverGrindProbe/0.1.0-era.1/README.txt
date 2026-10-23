ForeverGrindProbe 0.1.0-era.1 — REVIEW CANDIDATE, NOT CLEARED FOR INSTALL

Purpose: measure uncontested Era grinding, independently of ForeverRouteProbe.
No Probe files, events, saved variables, commands, tripwire or defaults are modified.
No RestedXP content, third-party addon assets, or user logs are included.

Client: interface 11500–11599 only. Entire addon inert on Forever (16001).
XP parser is deliberately English enUS/enGB only; other locales cannot start via /grind.
No auto-start, automatic installation, auto-combatlog, network calls or automation of gameplay.

AFTER independent clearance, install only ForeverGrindProbe/ into the Era
client's Interface/AddOns folder. Do not install this candidate before review.
No installer included; the exact Era client folder is an owner-side fact.

Commands:
 /grind start <one species / gear / ability policy label>
 /grind mark <manual levels, gear change, observations>
 /grind pause
 /grind resume
 /grind stop
 /grind export
Stop closes timing immediately, then waits 3.2 seconds to settle XP/death ordering.
Wait for the summary before export or logout. /reload/logout while recording
terminates the test, flags unfinished fights, and forces best-effort matching.
This is not a resumable cross-login recording.

Export: latest test as deterministic JSON, numeric table keys are string keys.
Ctrl+A/Ctrl+C in the export window. Export does not delete or reset anything.
Above 200 KB use the FULL per-character file after normal logout:
 WTF/Account/<account>/<realm>/<character>/SavedVariables/ForeverGrindProbe.lua
Keep its .bak too. All tests are in that file; window exports only the latest.
Limits: 2,000 encounter records per character across tests, 50 tests, 100 notes
per test, 2,000 XP awards per test, 100 unsettled awards. A conservative
SavedVariables-size estimate stops before 1.5 MB with 64 KiB headroom; the
byte limit may be reached well before 2,000 records. Archive files while WoW
is closed before any manual reset. There is no delete/reset command.
Unlike RouteProbe, this small standalone recorder has no independent account
tripwire. SavedVariables files are not a backup; archive valuable pilot data.

Metrics:
 - Uncontested Era rate = recorded kill XP / all unpaused test seconds.
 - Includes looting, skinning, searching, normal recovery; pause only for breaks.
 - Excludes quest XP and XP messages received during a pause. Late XP for a
   death before stop can settle into the stopped test. Ambiguous/unmatched
   awards remain in the raw sustained total and have separate counts.
 - Median TTK is for clean single pulls only, engage to death. First engagement
   is the first observed player/pet->mob or mob->player/pet action, including
   misses and targeted SPELL_CAST_SUCCESS. It is NOT spell wind-up time.
 - Two-target pulls are retained in a separate multi bucket, not clean singles.
 - xp_base/rested summary fields cover clean singles only, NOT total test XP.
 - Exclusion reason counts overlap. Raw records preserve every reason.
 - One species per segment avoids falsely assigning downtime across species.
 - A level-up award is bucketed by validated pre-award level, not a transient
   post-level-up UnitLevel sample. Gear/ability changes should get a new test.

Known limitations / conservative handling:
No proximity or XP-formula inference of mob levels. No predicted-XP display.
GUID must be observable as target/mouseover/softenemy/nameplate to get level.
No raw combat-log stream is saved. Other-player damage is detected only after
engagement; a trustworthy tap observation and native pilot remain important.
No damage for 30 seconds is an evade/flee proxy, not proof of an actual reset.
Same-name deaths +/-1.5 seconds are ambiguous. XP state changes are separately
matched by unique equal delta in that window; coalesced XP updates or multiple
same-value updates/awards may be marked xp_state_unknown rather than guessed.
English rested messages are recognized; group/other modifiers are retained
with xp_parse_unknown and excluded from clean comparisons.
Stopped/exported data remains available. Session labels/notes/messages are
bounded. A fresh start following a client reload creates a new test.

Native pilot AFTER clearance: 5–10 solo kills with manual player/mob level notes.
Include a miss-first opener, mob-initiated pull, double pull, level-up kill and
rested kill if available. Verify GUID, level/source, engagement/death timestamps,
XP match, pre-award state, exclusion flags and stopwatch duration. Pause/resume
once and ensure the break disappears while normal recovery remains. Stop,
wait for summary, export, log out and compare saved file with export. These
are uncontrolled Era observations, NOT launch-congestion or Forever forecasts.

Tests: python -m unittest discover -s tests -v (Python with lupa, Lua 5.1).
Build: python BUILD.py. Reproducible ZIPs and manifest appear in dist/.
