# Source and evidence notes

The guide's route and prose are original, authored from the owner's decisions
and their Era scouting run. No premium RXP guide or paid video output is used
as a route source. Private character/account logs are excluded from this package.

## Owner route evidence

- Era scout raw file SHA-256:
  `f32f0ac33f88a1638e0875d285fbaec92d48519a9d342a133b66aabfc8640158`.
  The reviewer has its Drive link in the private handoff.
- Owner-entered waypoints: Lakeridge 19.8/73.4; Fishing 47.6/62.2;
  hill path 50.19/56.55; Jasperlode dropdown 60.52/51.29.
- Most discovery points are the preceding logged player position, not a measured
  polygon interior. They require manual living discovery confirmation.
- Fargodeep objective complete: event2712, Elwynn39.55/80.44.
  Jasperlode objective complete: event2915, Elwynn60.23/49.48.
  Discovery is a separate event from quest completion.
- Rut'theran: Darnassus29.82/41.24 is the portal; actual arrival is
  Teldrassil55.93/89.78 and flightmaster58.35/94.00.
- The Menethil coastal swim and Kharanos resurrection use sparse observed
  breadcrumbs. Cause of the coastal death is not established. Harbor-equivalent
  Stormwind35.06/40.39 is inferred from the scouting pause, not an owner-confirmed
  final timing marker. Confirm it during the first native pass.
- Raven Hill Cemetery21.60/40.74 is an interior candidate derived from the
  project's Surveyor Forever70450 area492 grid. It was not discovered in the Era
  scout and is not an Era-validated entry point. The graveyard ghost flicker is
  not used as evidence of discovery.
- Hushed Bank is moved before Westfall in the approved proposal; the scout
  visited it after Dust Plains and Dead Acre. Discovery XP may change with order.
- Woodland Protector control-run interactions: Melithar59.8901/42.5401 and
  Tarindrella57.8081/45.0249; turn-in awarded40XP.

## Public quest and NPC data

Read 2026-10-23; map formats are kept separate.

- [QuestieDB Classic NPC data](https://github.com/Questie/QuestieDB/blob/1f538335cfbb240c14a97c340f48c555fdc8a52b/data/Classic/classicNpcDB.lua):
  Era Stormwind NPCs1427,1428,1429,1431,1432 supply Harlan, Rema, Thurman,
  Suzetta and Renato coordinates. These are NPC positions, not copied route prose.
- [QuestieDB SoD corrections](https://github.com/Questie/QuestieDB/blob/1f538335cfbb240c14a97c340f48c555fdc8a52b/src/corrections/Sod/sodNPCFixes.lua):
  Garion211033 at old-map37.8/80.2 supplies a manual tower visit waypoint only.
  This does not assert that Garion or the book quests exist on Era.
- [QuestieDB Forever traces](https://github.com/Questie/QuestieDB/blob/1f538335cfbb240c14a97c340f48c555fdc8a52b/src/corrections/Forever/traces/foreverNpcTraces.lua):
  Sam263399 at44.90/63.36 and Garion at Forever49/86.5. The latter coordinate
  is deliberately not used for the smaller Era Stormwind map.
- Owner-accepted Wowhead Forever quest records:
  [458](https://www.wowhead.com/forever/quest=458/the-woodland-protector),
  [332](https://www.wowhead.com/forever/quest=332/wine-shop-advert),
  [333](https://www.wowhead.com/forever/quest=333/harlan-needs-a-resupply),
  [334](https://www.wowhead.com/forever/quest=334/package-for-thurman),
  [79092](https://www.wowhead.com/forever/quest=79092),
  [79093](https://www.wowhead.com/forever/quest=79093),
  [95998](https://www.wowhead.com/forever/quest=95998/the-great-outdoors),
  [76](https://www.wowhead.com/forever/quest=76/the-jasperlode-mine).
  Three Stormwind errands are also available on Era; only the books and camping
  are missing quest content. #458 exists on Era, but its Forever profession-book
  reward does not. No optional Camping101 quest is added.

## XP ledger

Observed scout:4920 =3200 discoveries +1675 quest XP +45 incidental wolf XP.
Fixed-award plan:
`4920 -240 Era transport -45 wolf -65 Pools +670 SW errands/books +40 Woodland
+140 recovery +70 Raven Hill Cemetery +410 camping -10 Jasperlode =5890`.
The last correction substitutes the accepted Forever840 for observed Era850;
it does not change the native log. Recovery140 and Cemetery70 are assumptions
for planning. Start-up copper farming and discovery order/level changes remain
outside this fixed ledger. The control stopwatch32:20 ended near5916 total XP;
its longer Probe wall time includes pauses and must not replace the stopwatch.

## Parser provenance and rights

The test-only RXP parser excerpts are from the public GPLv3 RXPGuides code, not
its proprietary guide content. Exact commit, whole-file hashes and excerpt hash
are in tests/upstream/PROVENANCE.json. The full upstream license is included.
The adapted test harness is distributed under that same GPLv3 license.
This is emulated parsing, not a claim of native client or installed4.11.27 parity.
