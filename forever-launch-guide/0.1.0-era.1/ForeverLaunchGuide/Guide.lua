-- Original owner-directed route. Version 0.1.0-era.1, independent review candidate.
-- Coordinates are approach points, not automatic proof of discovery.
-- No SavedVariables, stopwatch controls, direct quest API calls, or hearth changes.
-- Standard RXP settings govern its own quest automation.
local _, _, _, interface = GetBuildInfo()
if WOW_PROJECT_ID ~= WOW_PROJECT_CLASSIC or not interface or interface < 11500 or interface >= 11600 then
    return
end
if C_GameRules and C_GameRules.IsHardcoreActive and C_GameRules.IsHardcoreActive() then
    return
end
if C_Seasons and C_Seasons.HasActiveSeason and C_Seasons.HasActiveSeason() then
    return
end
if not RXPGuides or not RXPGuides.RegisterGuide then
    return
end

RXPGuides.RegisterGuide([[
#classic
#version 3
<< NightElf
#group Forever Launch (Era)
#name NE Exploration Rehearsal
step
    >>Start on a fresh Night Elf on a normal Era realm. This rehearses the launch fallback; normal RXP leveling remains Plan A.
    >>Start Probe and your stopwatch yourself. Pause for breaks, and note each break. This guide does not control either addon.
    >>Check discovery objectives only after the living character discovers the area. If already explored, confirm that explicitly. Arrows are approach points, not guaranteed paths through enemies.
    >>Keep your chosen hearth binding. No step binds Goldshire or chooses your next leveling chapter.
    +Ready to rehearse from Shadowglen; stopwatch and Probe checked
step
    .goto Teldrassil,59.90,42.50
    .target Melithar Staghelm
    .accept 458 >>Accept The Woodland Protector from Melithar Staghelm
step
    .goto Teldrassil,57.81,45.02
    .target Tarindrella
    .turnin 458 >>Turn in The Woodland Protector to Tarindrella
step
    >>Forever plan: choose the Mining or Skinning book, train the other profession with copper, and obtain the tools you need. The book reward is not available in Era.
    >>Rehearse only the training and purchases available to this character. Record any copper farming separately; the amount is not fixed. Do not grind levels solely to imitate a missing Forever reward.
    +Profession preparation completed or Era limitations noted
step
    .goto Teldrassil,61.18,47.65
    .target Porthannius
    .accept 2159 >>Accept Dolanaar Delivery
step
    .goto Teldrassil,62.71,56.40
    +Confirm Starbreeze Village discovery while alive
step
    .goto Teldrassil,58.34,61.49
    +Confirm Dolanaar discovery while alive
step
    .goto Teldrassil,57.29,63.90
    +Confirm Lake Al'Ameth discovery while alive
step
    .goto Teldrassil,55.60,59.80
    .target Innkeeper Keldamyr
    .turnin 2159 >>Turn in Dolanaar Delivery; keep your chosen hearth binding
step
    .goto Teldrassil,48.64,52.58
    >>Skirt Ban'ethil Hollow; there is no cave quest here.
    +Confirm Ban'ethil Hollow discovery while alive
step
    .goto Teldrassil,40.97,41.18
    +Confirm Wellspring Lake discovery while alive
step
    .goto Teldrassil,40.92,39.15
    +Confirm The Oracle Glade discovery while alive
step
    .goto Teldrassil,41.58,38.76
    +Confirm Wellspring River discovery while alive
step
    .goto Teldrassil,42.29,38.04
    >>After all three northern discoveries, make the planned death skip. Release and use the Darnassus Spirit Healer manually. Check the destination before accepting resurrection.
    >>Do not add the southern Pools of Arlithrien detour.
    +Resurrected at the Darnassus graveyard
    +Confirm Darnassus discovery while alive
step
    .goto Darnassus,29.82,41.24
    >>Cross Darnassus to the pink portal for Rut'theran Village.
    +Taken the portal out of Darnassus
step
    .goto Teldrassil,55.93,89.78
    +Confirm Rut'theran Village discovery while alive
step
    .goto Teldrassil,58.35,94.00
    >>Speak to the flight master. Take the flight to Auberdine if available; otherwise use the Auberdine boat and record the changed transport. Keep this intended travel on the timer.
    +Arrived in Auberdine
step
    .goto Darkshore,36.40,45.64
    +Confirm Auberdine discovery while alive
step
    .goto Darkshore,33.36,42.30
    >>Go to the dock. PAUSE the stopwatch here for the Era-only replacement journey to Stormwind. Keep Probe recording.
    >>Note your level, XP and stopwatch reading. Menethil, Kharanos and Ironforge discoveries belong to the Era transport adjustment, not the intended Forever route.
    +Stopwatch paused at Auberdine dock; XP noted
step
    >>ERA BRIDGE: take the Menethil Harbor boat. This replaces the Forever connection to Stormwind. Keep the stopwatch paused through the following bridge steps.
    +Arrived alive in Menethil Harbor
step
    .goto Wetlands,6.01,57.52
    >>Enter the water by Menethil and swim southwest along the coast toward Dun Morogh. Keep near the coast; these are sparse breadcrumbs from the scouting run, not a validated safe swim line.
    +Ready to follow the coastal swim south
step
    .goto Wetlands,2.62,61.02
    +Passed the observed Baradin Bay approach
step
    .goto 1415,44.48,49.32
    >>Continue along the coast toward the Dun Morogh shoreline. This arrow uses the Eastern Kingdoms map.
    +Passed the middle coastal breadcrumb
step
    .goto 1415,42.84,50.45
    +Reached the southern coastal approach to Dun Morogh
step
    .goto Dun Morogh,17.71,15.94
    >>Enter Dun Morogh, then make the Era bridge death skip. Release and use the Kharanos Spirit Healer manually. Confirm the graveyard destination first.
    +Resurrected at Kharanos; stopwatch remains paused
step
    .goto Dun Morogh,49.05,41.29
    >>Follow the road north toward Ironforge.
    +On the Ironforge approach road
step
    .goto Dun Morogh,51.82,36.97
    >>Enter Ironforge through its main gate.
    +Entered Ironforge
step
    .goto Ironforge,53.33,81.10
    >>Follow the southern city ring through the Military Ward toward Tinker Town; do not cut across buildings toward the arrow.
    +Passed the southern ring approach
step
    .goto Ironforge,68.00,63.16
    >>Cross the city to Tinker Town.
    +Reached Tinker Town
step
    .goto Ironforge,77.20,51.35
    >>Enter the Deeprun Tram and ride to Stormwind. Leave the tram through the Stormwind exit.
    +Arrived in Stormwind; stopwatch remains paused
step
    .goto Stormwind City,35.06,40.39
    >>Reach this provisional harbor-side marker in old Stormwind, then RESUME the stopwatch. Era has no built harbor; this marker is inferred from the scouting stop and still needs confirmation in play.
    >>Record the resume reading and XP. Stormwind discovery belongs to the intended route; the extra bridge discoveries are reconciled from Probe afterwards. This guide does not subtract XP or simulate Forever boat time.
    +Stopwatch resumed at the Stormwind harbor-equivalent marker
step
    .goto Elwynn Forest,48.12,42.85
    .target Deputy Willem
    .accept 783 >>Leave Stormwind for Northshire and accept A Threat Within
    .accept 5261 >>Accept Eagan Peltskinner from Deputy Willem
    +Confirm Northshire Valley discovery while alive
step
    .goto Elwynn Forest,48.89,41.63
    .target Marshal McBride
    .turnin 783 >>Turn in A Threat Within; no follow-up kill quest is required
step
    .goto Elwynn Forest,48.91,40.17
    .target Eagan Peltskinner
    .turnin 5261 >>Turn in Eagan Peltskinner
step
    >>Skin other players' eligible kills here if useful and available. This is an opportunity, not a mandatory grind or a scripted wolf kill.
    +Finished the optional Northshire skinning stop
step
    .goto Elwynn Forest,45.53,48.06
    .target Falkhaan Isenstrider
    .accept 2158 >>Accept Rest and Relaxation
step
    .goto Elwynn Forest,45.50,60.87
    +Confirm Goldshire discovery while alive
step
    .goto Elwynn Forest,43.77,65.82
    .target Innkeeper Farley
    .turnin 2158 >>Turn in Rest and Relaxation; do not change your hearth for this guide
step
    .goto Elwynn Forest,46.96,68.39
    +Confirm Crystal Lake discovery while alive
step
    .goto Elwynn Forest,63.87,70.95
    +Confirm Tower of Azora discovery while alive
step
    .goto Elwynn Forest,65.40,70.10
    >>FOREVER STOP: visit the Tower of Azora book location. The book quest is absent in Era; practice the approach and mark this stop manually. Do not wait for a quest to appear.
    +Azora book stop rehearsed; Forever pickup deferred
step
    .goto Elwynn Forest,69.46,75.52
    +Confirm Brackwell Pumpkin Patch discovery while alive
step
    .goto Elwynn Forest,78.97,72.49
    +Confirm Eastvale Logging Camp discovery while alive
step
    .goto Elwynn Forest,85.95,74.77
    +Confirm Ridgepoint Tower discovery while alive
step
    .goto Redridge Mountains,8.93,71.66
    +Confirm Three Corners discovery while alive
step
    .goto Redridge Mountains,25.75,56.64
    +Confirm Lake Everstill discovery while alive
step
    .goto Redridge Mountains,30.53,59.56
    >>Pick up the Lakeshire flight path if available.
    +Flight master visited
step
    .goto Redridge Mountains,19.80,73.40
    >>Use the owner's Lakeridge approach. Continue into the area as needed; the point itself is not proof of discovery.
    +Confirm Lakeridge Highway discovery while alive
step
    .goto Redridge Mountains,33.05,48.01
    +Confirm Lakeshire discovery while alive
step
    .goto Duskwood,90.93,12.36
    >>Approach The Darkened Bank alive. The scout lost discovery XP around a death here; avoid pulling enemies across the boundary.
    +Confirm The Darkened Bank discovery and check the XP message while alive
step
    .goto Duskwood,75.12,59.05
    +Confirm Darkshire discovery while alive
step
    .goto Duskwood,77.50,44.30
    >>Visit Darkshire's flight master and collect the flight path if available.
    +Darkshire flight master visited
step
    .goto Duskwood,84.43,33.95
    +Confirm Beggar's Haunt discovery while alive
step
    .goto Duskwood,83.70,33.69
    +Confirm Manor Mistmantle discovery while alive
step
    .goto Duskwood,76.87,65.39
    +Confirm Tranquil Gardens Cemetery discovery while alive
step
    .goto Duskwood,67.52,58.13
    +Confirm Brightwood Grove discovery while alive
step
    .goto Duskwood,65.81,62.71
    +Confirm The Rotting Orchard discovery while alive
step
    .goto Duskwood,57.62,68.51
    +Confirm The Yorgen Farmstead discovery while alive
step
    .goto Duskwood,41.77,68.86
    +Confirm Vul'Gol Ogre Mound discovery while alive
step
    .goto Duskwood,19.91,49.08
    +Confirm Raven Hill discovery while alive
step
    .goto Duskwood,21.60,40.74
    >>Raven Hill Cemetery was missed in scouting. This interior approach is untested in Era; move carefully until the actual Cemetery discovery appears.
    +Confirm Raven Hill Cemetery discovery while alive
step
    .goto Duskwood,21.19,62.44
    >>Approach Addle's Stead alive. Do not repeat the scouting death at its boundary.
    +Confirm Addle's Stead discovery and check the XP message while alive
step
    .goto Duskwood,7.58,59.82
    >>Collect The Hushed Bank before crossing into Westfall. This is earlier than in the scouting log.
    +Confirm The Hushed Bank discovery while alive
step
    .goto Westfall,66.52,65.00
    +Confirm The Dust Plains discovery while alive
step
    .goto Westfall,67.48,60.07
    +Confirm The Dead Acre discovery while alive
step
    .goto Westfall,51.74,49.64
    +Confirm Sentinel Hill discovery while alive
step
    .goto Westfall,52.70,53.80
    >>FOREVER STOP: visit the Sentinel Hill inn book location. The book quest is absent in Era; rehearse the visit and mark it manually.
    +Sentinel Hill book stop rehearsed; Forever pickup deferred
step
    .goto Westfall,56.56,52.60
    >>Pick up the Sentinel Hill flight path if available.
    +Flight master visited
step
    .goto Westfall,57.47,32.48
    +Confirm Saldean's Farm discovery while alive
step
    .goto Westfall,52.38,24.83
    +Confirm Furlbrow's Pumpkin Farm discovery while alive
step
    .goto Westfall,56.60,23.79
    +Confirm The Jansen Stead discovery while alive
step
    .goto Elwynn Forest,21.21,79.47
    +Confirm Forest's Edge discovery while alive
step
    .goto Elwynn Forest,24.80,76.78
    +Confirm Westbrook Garrison discovery while alive
step
    .goto Elwynn Forest,29.60,79.64
    +Confirm The Stonefield Farm discovery while alive
step
    .goto Elwynn Forest,31.77,80.91
    >>Make the planned Stonefield death skip after the second Elwynn batch. Release and resurrect at the Goldshire Spirit Healer manually.
    +Resurrected at Goldshire; ready for the Stormwind errands
step
    .goto Stormwind City,56.98,63.53
    >>Travel to Stormwind's Trade District. Find Renato Gallina and accept Wine Shop Advert. These three errands exist in Era; do them on this pass.
    .target Renato Gallina
    .accept 332 >>Accept Wine Shop Advert
step
    .goto Stormwind City,55.11,56.23
    >>Find Harlan Bagley in the Trade District.
    .target Harlan Bagley
    .accept 333 >>Accept Harlan Needs a Resupply
step
    .goto Stormwind City,49.65,55.64
    >>Find Rema Schneider in the tailor's shop on the canal side of the Trade District.
    .target Rema Schneider
    .turnin 333 >>Turn in Harlan Needs a Resupply
    .accept 334 >>Accept Package for Thurman
step
    .goto Stormwind City,52.48,67.61
    >>Find Suzetta Gallina at Gallina Winery, by the canal south of the Trade District.
    .target Suzetta Gallina
    .turnin 332 >>Turn in Wine Shop Advert
step
    .goto Stormwind City,42.53,76.20
    >>Find Thurman Schneider at Larson Clothiers in the Mage Quarter.
    .target Thurman Schneider
    .turnin 334 >>Turn in Package for Thurman
step
    .goto Stormwind City,37.80,80.20
    >>FOREVER STOP: both books are handed to Librarian Garion Wendell at the Mage Quarter tower. Rehearse that tower visit in Era; the NPC and turn-ins may not exist here.
    >>Do not use Forever Stormwind map coordinates on the smaller Era city map.
    +Both book hand-ins rehearsed as a tower visit; no Era quest gates
step
    .goto Elwynn Forest,42.13,65.87
    >>Return to Goldshire and speak to Marshal Dughan. Fargodeep and Jasperlode require level 4. If Era's missing rewards leave you below 4, note that and choose a separate leveling adjustment; the guide does not silently add a grind.
    .target Marshal Dughan
    .accept 62 >>Accept The Fargodeep Mine
step
    .goto Elwynn Forest,45.75,82.81
    +Confirm Jerod's Landing discovery while alive
step
    .goto Elwynn Forest,45.10,83.86
    +Confirm The Maclure Vineyards discovery while alive
step
    .goto Elwynn Forest,40.92,83.00
    +Confirm Fargodeep Mine discovery while alive
step
    .goto Elwynn Forest,39.55,80.44
    >>Go far enough into Fargodeep to scout it. Wait for the actual quest objective; discovery alone is not completion.
    .complete 62,1 >>Scout the Fargodeep Mine
step
    >>After scouting is complete, make the planned return death skip. Release and resurrect at the Goldshire Spirit Healer manually.
    +Back at Goldshire after the completed Fargodeep scout
step
    .goto Elwynn Forest,42.13,65.87
    .target Marshal Dughan
    .turnin 62 >>Turn in The Fargodeep Mine
    .accept 76 >>Accept The Jasperlode Mine
step
    .goto Elwynn Forest,44.90,63.36
    >>FOREVER STOP: The Great Outdoors with Sam Sarsaparilla belongs here, after the Fargodeep return. It requires sitting by his campfire until Boosted Rest, then turning in.
    >>Era has no equivalent quest. Rehearse the stop manually; no additional Camping 101 quest is included.
    +Camping stop rehearsed; Forever quest deferred
step
    .goto Elwynn Forest,47.60,62.20
    .target Lee Brown
    >>Visit Lee Brown at Crystal Lake and learn Fishing if this Era character is eligible. If the trainer refuses, note it and continue; do not add a leveling grind to this stop.
    +Fishing learned or Era training restriction noted
step
    .goto Elwynn Forest,50.19,56.55
    >>Use the owner's path up the hill.
    +Reached the hill path
step
    .goto Elwynn Forest,60.52,51.29
    >>Use the owner's dropdown toward Jasperlode Mine; check your landing before jumping.
    +Reached the Jasperlode approach
step
    .goto Elwynn Forest,59.66,52.18
    +Confirm Jasperlode Mine discovery while alive
step
    .goto Elwynn Forest,60.23,49.48
    >>Reach the scout objective alive if possible. The earlier scouting death near the entrance was accidental and is not part of this route.
    .complete 76,1 >>Scout the Jasperlode Mine
step
    .goto Elwynn Forest,42.13,65.87
    >>Return to Goldshire by your chosen method. Walking or an intentional return death skip are possible; keep your chosen hearth binding unless you have independently decided otherwise.
    .target Marshal Dughan
    .turnin 76 >>Turn in The Jasperlode Mine
step
    >>STOP the stopwatch now, after the Jasperlode turn-in. Record time, level, current XP, deaths and break notes. Log out or reload when ready to flush Probe's saved data.
    >>This route ends here even if you passed level 5 earlier. Choose your next RXP chapter separately. Cooking, if wanted, is after this loop and outside its timing.
    +Jasperlode finished; final stopwatch and XP recorded
]])
