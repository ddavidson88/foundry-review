-- Verbatim excerpts from RestedXP/RXPGuides commit 9536b5a9ee7e55745618a57dad43df2c4312ea16.
-- GPL-3.0; see LICENSE. See PROVENANCE.json for hashes of complete source files.
local function applies(textEntry,customClass,func)
    if textEntry then
        --if not(textEntry:match("Alliance") or textEntry:match("Horde")) then return true end
        local function parse(text,customClass)
            local isMatch = false
            text = text:gsub("(!?)%(%s*(.-)%s*%)",function(op,m)
                if parse(m,customClass) ~= (op == "!") then
                    return class
                else
                    return "NULL"
                end
            end)
            local faction = addon.player.faction
            local playerLevel = UnitLevel("player") or 1
            for str in string.gmatch(text, "[^/]+") do
                local v = true
                for entry in string.gmatch(str, "!?[%w%d]+") do
                    local state = false
                    local gendercheck
                    if entry:sub(1, 1) == "!" then
                        entry = entry:sub(2, -1)
                        state = true
                    end
                    local level = tonumber(entry) or 0xfff
                    local uppercase = strupper(entry)
                    if entry == "Undead" then
                        entry = "Scourge"
                    elseif uppercase == "DK" then
                        uppercase = "DEATHKNIGHT"
                    elseif uppercase == "MALE" and UnitSex("player") == 2 or
                        uppercase == "FEMALE" and UnitSex("player") == 3 then
                        gendercheck = true
                    elseif uppercase == "SOD" and addon.player.season == 2 then
                        entry = faction
                    elseif uppercase == "DF" then
                        entry = "RETAIL"
                    elseif faction == "Neutral" and not customClass and (entry == "Alliance" or entry == "Horde") then
                        entry = faction
                    elseif entry == "Haranir" then
                        entry = "Harronir"
                    end
                    local customCheck = func and func(entry, uppercase)
                    v = (not(gendercheck or uppercase == class or entry == race or
                             entry == faction or playerLevel >= level or uppercase == addon.game or entry == customClass or entry == locale or customCheck) ==
                             state)
                    if not v then
                        break
                    end
                end
                if v then
                    isMatch = true
                    break
                end
            end
            --print(isMatch and "TRUE" or "FALSE",'-',text)
            return isMatch
        end
        local match
        if not aCache[textEntry] then
            match = parse(textEntry,customClass)
            aCache[textEntry] = match
            return match
        else
            return aCache[textEntry]
        end
    end
    return true
end


addon.affix = function(smin, smax)
    if smax:len() == 1 then smax = "0" .. smax end
    return "0" .. smin .. "-" .. smax
end

function addon.RegisterGroup(guideGroup, parentGroup)
    if not RXPGuides[guideGroup] then RXPGuides[guideGroup] = {} end
    local group = RXPGuides[guideGroup]
    if parentGroup then
        if not RXPGuides[parentGroup] then RXPGuides[parentGroup] = {} end
        local parent = RXPGuides[parentGroup]
        parent.__index = parent
        setmetatable(parent, addon.functions)
        setmetatable(group, parent)
    else
        setmetatable(group, addon.functions)
    end
end


function addon.RegisterGuide(groupOrContent, text, defaultFor)
    if not groupOrContent then
        return error(L'Error: Guide has no contents')
    elseif addon.addonLoaded or
      (addon.addonLoaded == false and addon.settings.profile and
       (addon.settings.profile.preLoadData or not addon.player.hardcore)) then
        local importedGuide, errorMsg = addon.ParseGuide(groupOrContent, text,
                                                        defaultFor)

        return not errorMsg and addon.AddGuide(importedGuide)
    else
        tinsert(embeddedGuides, {
            groupOrContent = groupOrContent,
            text = text,
            defaultFor = defaultFor
        })
    end
end


function addon.BuildGuideKey(arg1,arg2,arg3)
    if type(arg1) == "table" then
        return fmt("%s|%s|%s", arg1.group, arg1.subgroup or '',
                         arg1.name)
    elseif arg1 and arg3 then
        return fmt("%s|%s|%s", arg1, arg2 or '',
                         arg3)
    end
end


local function parseLine(linetext,step,parsingLogic)
    if not parsingLogic then
        parsingLogic = addon.functions
    end
    addon.step = step
    if addon.lastObjective and addon.lastObjective.step ~= step then
        addon.lastObjective = nil
    end
    if addon.lastElement and addon.lastElement.step ~= step then
        addon.lastElement = nil
    end

    local line = linetext
    local classtag
    line = line:gsub("%s*<<%s*(.+)", function(t)
        classtag = t
        return ""
    end)
    if classtag and not applies(classtag) then return end

    if step then
        local steptag, assignment, value = line:match("^#(%S+)%s*(=?)%s*(.*)")
        if steptag and steptag ~= "" then
            if not step[steptag] then
                if assignment == "=" then
                    step[steptag] = parsingLogic[value]
                else
                    step[steptag] = value
                end
            end
            return
        end
    end

    local element
    local text
    line = line:gsub("%s*>>%s*(.*)", function(t)
        if t ~= "" then text = t end
        return ""
    end)

    line:gsub("^%.(%S+)%s*(.*)", function(tag, args)
        local t = {}

        if addon.separators[tag] then
            addon.separators[tag](t,args)
        else
            args = args:gsub("%s*,%s*", ",")
            for arg in string.gmatch(args, "[^,]+") do
                tinsert(t, arg)
            end
        end
        -- print(tag,args,type(guide))
        if parsingLogic[tag] then
            element = parsingLogic[tag](linetext, text, unpack(t))
            if not element then return end
            element.tag = tag
            element.step = step
            if element.parent then
                element.parent = addon.lastObjective
            end
        else
            local ltext
            if #linetext > 150 then
                ltext = linetext:sub(1,150)
            else
                ltext = linetext
            end
            return addon.error(L("Error parsing guide") .. " " ..
                                   addon.currentGuideName ..
                                   ": Invalid function call (." .. tag ..
                                   ")\n" .. ltext)
        end
    end)

    if text and not element then
        element = {text = text, textOnly = true, step = step}
    elseif line:sub(1, 1) == "+" then
        element = {text = line:sub(2, -1), step = step}
        addon.lastObjective = element
    elseif line:sub(1, 1) == "*" then
        element = {
            text = line:sub(2, -1):gsub("\\n", "\n"),
            step = step,
            hideTooltip = true,
            textOnly = true
        }
        -- else
        -- error('Error parsing guide at line '..linenumber..'/ '..guide.name)
    end
    if element and (element.text and not element.textOnly or element.dynamicText) then
        addon.lastObjective = element
    end

    --[[if RXPData.localeTable and element and element.text then
        RXPData.localeTable[element.text] = ""
    end]]
    if not step then
        if element then
            element.parent = nil
        --[[else
            addon.error(L("Error parsing ") .. addon.currentGuideName .. ':'
                 .. linetext)
        ]]
        end
    elseif step.elements and element then
        tinsert(step.elements, element)
        addon.lastElement = element
    end
    return element
end
addon.ParseLine = parseLine

function addon.ParseGuide(groupOrContent, text, defaultFor, isEmbedded, group, key)

    addon.lastObjective = nil
    if not groupOrContent then return end

    local playerLevel = UnitLevel("player")
    local parentGroup
    local length
    if isEmbedded then
        length = groupOrContent:len()
    else
        length = groupOrContent:match("^%-%-(%d+)")
    end
    if not (groupOrContent and text) then
        local currentGroup = group
        if type(length) ~= "string" then
            text = groupOrContent:gsub("%-%-[^\r\n]*[\r\n]+", "\n")
        else
            text = groupOrContent
        end
        if not group then
            text = text:gsub(
                    "(#group[ \t]*)([^\r\n]-)[ \t]*<<[ \t]*([^\r\n]-)[ \t]*[\r\n]+",
                    function(prefix, group, t)
                    if not applies(t) then
                        return "\n"
                    else
                        currentGroup = group
                        return prefix .. group .. "\n"
                    end
                end)
        end
        if currentGroup then
            groupOrContent = currentGroup
        else
            groupOrContent = text:match("^%s*#group%s+(.-)%s*[\r\n]") or
                                 text:match("[\r\n]%s*#group%s+(.-)%s*[\r\n]")
            if not groupOrContent then
                addon.comms.PrettyDebug("\n%s: Invalid guide group %s",
                                        text:match("#name%s+.-%s*[\r\n]") or "", L("Error parsing guide") or "")
                return
            end
        end
    else
        text = text:gsub("%-%-[^\r\n]*[\r\n]", "\n")
    end

    local guide = {}
    if groupOrContent:sub(1, 1) == "+" then
        addon.farmGuides = addon.farmGuides + 1
        guide.farm = true
    end
    addon.guide = guide

    guide.group = groupOrContent
    addon.currentGuideGroup = groupOrContent

    local currentStep = 0
    guide.steps = {}

    local parsingLogic
    local step
    local skip
    local skipGuide
    local linenumber = 0
    local game = strlower(addon.game)
    local hasGameTag, isGameCompatible, hasGuideMetadata

    for line in string.gmatch(text, "[^\n\r]+") do
        linenumber = linenumber + 1
        line = line:gsub("^%s+", "")
        line = line:gsub("%s+$", "")
        -- print(line)
        if line:sub(1, 4) == "step" then
            if not addon.currentGuideName then
                error(L("Error parsing guide") .. ": " .. L("Guide has no name") .. "\n" .. text)
            end
            if currentStep == 0 then
                if guide.df then guide.retail = true end

                hasGameTag = guide.classic or guide.tbc or guide.wotlk or guide.df or guide.retail or guide.cata
                isGameCompatible = guide[game] or (addon.game == "FOREVER" and guide.classic)
                hasGuideMetadata = guide.name and guide.group

                if (hasGameTag and not isGameCompatible) or not hasGuideMetadata then
                    -- print(game,guide[game],guide.name)
                    skipGuide = "#0"
                end
                --debug purposes
                addon.lastGuideName = guide.name
                addon.lastGuideGroup = guide.group
            end
            if skipGuide then
                guide.version = tonumber(guide.version) or 0
                addon.minGuideVersion = math.min(guide.version,addon.minGuideVersion)
                addon.maxGuideVersion = math.max(guide.version,addon.maxGuideVersion)
                addon.guide = false
                addon.lastObjective = nil
                guide.key = guide.key or key
                return guide, skipGuide
            elseif currentStep == 0 then
                guide.key = guide.key or key or addon.BuildGuideKey(guide)
                guide.guideId = addon.A32(guide.key)
                addon.RegisterGroup(guide.group)
            end
            local classtag = line:match("<<%s*(.+)")
            if classtag and not applies(classtag) then
                skip = true
            else
                skip = false
                if step and step.elements and #step.elements == 0 then
                    step.hidewindow = true
                end
                currentStep = currentStep + 1
                guide.steps[currentStep] = {}
                guide.steps[currentStep].elements = {}
                step = guide.steps[currentStep]
                step.stepId = linenumber + guide.guideId
                --step.index = currentStep
                addon.step = step
                --addon.lastObjective = nil
                parsingLogic = addon.functions
            end
        elseif not skip then
            if currentStep > 0 then
                parseLine(line,step,parsingLogic)
            else
                -- print(line)
                line = line:gsub("(.-)%s*<<%s*(.+)", function(code, tag)
                    local isValid = applies(tag)
                    if #code == 0 then
                        skipGuide = not isValid and tag
                        guide.enabledFor = guide.enabledFor or tag
                        -- print("$"..code.."$",tag,#code)
                    elseif not isValid then
                        return ""
                    end
                    return code
                end)

                if line ~= "" then
                    line:gsub("^#(%S+)%s*(=?)%s*(.*)",
                              function(tag, assignment, value)
                        -- print(tag,string.len(tag))
                        if tag and tag ~= "" and not guide[tag] then
                            if assignment == "=" then
                                local func = addon.functions[value]
                                guide[tag] = func and func() or value
                            else
                                guide[tag] = value
                            end
                            if tag == "name" then
                                addon.currentGuideName = value
                            end
                        end
                    end)
                end
            end
        end
    end
    -- print(guide)
    addon.step = false
    if not guide.name then error(L('Guide has no name')) end

    defaultFor = guide.defaultfor or defaultFor
    guide.group = guide.group or groupOrContent
    groupOrContent = addon.GroupOverride(guide) or groupOrContent

    if addon.game == "TBC" and guide.classic and not guide.wotlk and not groupOrContent:find("TBC") and groupOrContent:sub(1,1) ~= "+" then
        if guide.subgroup then
            local range = guide.subgroup:match("( %d+%-%d+)$")
            if range then
                guide.subgroup = L"Classic"..range
            end
        end
        if groupOrContent:sub(1,8) == "RestedXP" then
            groupOrContent = addon.classicPrefix..groupOrContent
            guide.group = groupOrContent
        end
        defaultFor = "!tbc"
    end
    if defaultFor then
        local boost58
        if defaultFor == "58Boost" then
            if playerLevel >= 60 or playerLevel < 58 then
                parentGroup = groupOrContent
                guide.lowPrio = "*" .. groupOrContent
            end
            boost58 = true
        elseif not applies(defaultFor) then
            parentGroup = groupOrContent
            guide.lowPrio = "*" .. groupOrContent
        end
        addon.RegisterGroup(groupOrContent, parentGroup)
        guide.boost58 = boost58
        --guide.lowPrio = groupOrContent
    end

    guide.displayname = addon.settings.ReplaceColors(guide.displayname or guide.name)
    guide.name = guide.name:gsub("^(%d)-(%d%d?)", addon.affix)

    guide.key = addon.BuildGuideKey(guide)
    guide.version = tonumber(guide.version) or 0
    addon.minGuideVersion = math.min(guide.version,addon.minGuideVersion)
    addon.maxGuideVersion = math.max(guide.version,addon.maxGuideVersion)

    addon.guide = false
    addon.lastObjective = nil
    -- print(guide.name,"\n",guide.enabledFor)

    local metadata = {length = length}

    for k,v in pairs(guide) do
        if not (type(v) == "table" or type(v) == "function") then
            metadata[k] = v
        end
    end
    metadata.lowPrio = nil
    metadata.defaultFor = defaultFor
    return guide,nil,metadata
end


function addon.functions.accept(self, ...)
    if type(self) == "string" then -- on parse
        local text, id, flags, arg1 = ...
        id = tonumber(id)
        flags = tonumber(flags) or 0
        if not id then
            return addon.error(
                L("Error parsing guide") .. " " .. addon.currentGuideName ..
                ": Invalid quest ID\n" .. self)
        end
        local element = {title = "", flags = flags}
        element.questId = GetQuestId(id)
        -- element.title = addon.GetQuestName(id)
        if text and text ~= "" then
            element.text = text
        else
            element.text = _G.ACCEPT .. " *quest*"
            element.requestFromServer = true
        end
        if element.text:find("%*quest%*") then
            element.retrieveText = true
        end
        --element.tooltipText = addon.icons.accept .. element.text

        --[[
        flags:
            1 - disable auto accept
            2 - mark element as complete if quest Id defined by arg1 is not turned in
        ]]
        if bit.band(flags,0x2) == 0x2 then
            element.requiredTurnIn = tonumber(arg1)
        end
        addon.InsertQuestGuide(id,addon.pickUpList)
        return element
    else
        local element = self.element
        local step = element.step
        local event, arg1, questId = ...
        local id = element.questId
        local isCompleted = element.completed
        local index = step.index
        local isQuestAccepted

        if event == "QUEST_ACCEPTED" then
            questId = questId or arg1
            isQuestAccepted = questId == id or IsQuestTurnedIn(id) or IsOnQuest(id)
            if questId == id then
                addon.recentAccept[id] = GetTime()
            end
        else
            isQuestAccepted = IsQuestTurnedIn(id) or IsOnQuest(id)
        end

        if step.active or element.retrieveText or
            (index and index > 1 and
                addon.currentGuide.steps[index - 1].active) then
            local autoAccept = bit.band(element.flags,0x1) ~= 0x1 and not addon.disabledQuests[id]
            if autoAccept then addon.questAccept[id] = element end
            local quest = addon.GetQuestName(id, element)
            if quest then
                element.title = quest
                if autoAccept then
                    addon.questAccept[id] = element
                    addon.questAccept[quest] = addon.questAccept[id]
                end
                element.text = element.text:gsub("%*quest%*", quest)
                if element.requestFromServer then
                    element.requestFromServer = nil
                    addon.UpdateStepText(self)
                end
            else
                element.title = ""
                element.requestFromServer = true
            end
        end

        local icon = addon.icons[element.tag]
        -- local skip
        if step.active and db and type(db.QueryQuest) == "function" and
            not isQuestAccepted and not addon.skipPreReq[id] and not element.multiple then
            local quest = db:GetQuest(id)
            if quest then
                local doable = db:IsDoable(id)
                local requiredQuests

                if not doable then
                    requiredQuests = GetRequiredQuests(quest)
                end
                if requiredQuests and #requiredQuests > 0 then
                    local tooltip = addon.colors.tooltip ..
                                        L("Missing pre-requisites") .. ":|r\n"
                    for i, qid in ipairs(requiredQuests) do
                        tooltip = format("%s\n%s%s (%d)", tooltip,
                                         addon.icons.turnin,
                                         db:GetQuest(qid).name, qid)
                    end
                    element.tooltip = tooltip
                    element.icon = addon.icons.error
                    -- skip = RXPData.skipMissingPreReqs
                --[[elseif not doable then
                    local tooltip = addon.colors.tooltip ..
                                        L("Missing pre-requisites") .. "|r"
                    element.tooltip = tooltip
                    element.icon = addon.icons.error
                    -- skip = RXPData.skipMissingPreReqs]]
                else
                    element.icon = icon
                    element.tooltip = nil
                end
            end
        elseif element.icon then
            element.icon = icon
            element.tooltip = nil
        end

        if addon.settings.profile.debug then
            element.tooltip = element.questId
        end

        element.tooltipText = addon.icons.accept .. element.text
        local completed = element.completed

        if isQuestAccepted then
            addon.SetElementComplete(self, true)
            -- elseif skip then
            --    addon.SetElementComplete(self)
        elseif event == "QUEST_REMOVED" and arg1 == id and not element.skip then
            addon.SetElementIncomplete(self)
        end

        if step.active then
            if element.requiredTurnIn and not IsQuestTurnedIn(element.requiredTurnIn) then
                addon.SetElementComplete(self, true)
            elseif not event then
                ProcessItems(true, step, id)
            elseif completed ~= element.completed then
                ProcessItems(not element.completed, step, id)
                addon.UpdateItemFrame()
            end
            if element.completed and not isCompleted then
                if element.timer then
                    addon.StartTimer(element.timer,element.timerText)
                end

                -- TODO prevent when replaying a guide step
                addon.comms.grouping:ShareQuest(id)
            end
        end

    end
    addon.IsOnTurnInGuide(self)
end


function addon.functions.turnin(self, ...)

    if type(self) == "string" then -- on parse
        local text, id, reward, flags = ...
        id = tonumber(id)
        if not id then
            return addon.error(
                        L("Error parsing guide") .. " " .. addon.currentGuideName ..
                           ": Invalid quest ID\n" .. self)
        end
        reward = tonumber(reward) or 0
        local element = {title = "", questId = GetQuestId(id)}
        element.flags = tonumber(flags) or 0
        --setting the lsb to 1 disables auto turn in
        if id < 0 then
            id = math.abs(id)
            element.skipIfMissing = true
            element.questId = GetQuestId(id)
            if reward > 0 then
                element.skipIfIncomplete = true
            end
            reward = nil
        end
        element.reward = reward
        -- element.title = addon.GetQuestName(id)
        if text and text ~= "" then
            element.text = text
        else
            element.text = _G.TURN_IN_QUEST .. " *quest*"
            element.requestFromServer = true
        end
        if element.text:find("%*quest%*") then
            element.retrieveText = true
        end
        --element.tooltipText = addon.icons.turnin .. element.text
        addon.InsertQuestGuide(id,addon.turnInList)

        return element
    else
        local element = self.element
        local step = element.step
        local event, questId = ...
        if UNIT_QUEST_LOG_CHANGED and event == UNIT_QUEST_LOG_CHANGED and questId ~= "player" then
            return
        end
        local id = GetQuestId(element.questId,nil,true)
        local isComplete = IsQuestTurnedIn(id)

        if step.active or element.retrieveText then
            local autoTurnIn = (not element.flags or element.flags % 2 == 0) and element
            addon.questTurnIn[id] = autoTurnIn
            -- addon.questAccept[id] = addon.questAccept[id] or element
            local quest = addon.GetQuestName(id)
            if quest then
                element.title = quest
                addon.questTurnIn[quest] = autoTurnIn
                -- addon.questAccept[quest] = addon.questAccept[quest] or element
                element.text = element.text:gsub("%*quest%*", quest)
                if element.requestFromServer then
                    element.requestFromServer = nil
                    addon.UpdateStepText(self)
                end
            else
                element.title = ""
                element.requestFromServer = true
            end
        end

        local icon = addon.icons[element.tag]
        -- local skip
        if step.active and db and type(db.QueryQuest) == "function" and
            addon.pickUpList[id] and not addon.questAccept[id] and
            not addon.skipPreReq[id] and not element.multiple and not isComplete then
            local quest = db:GetQuest(id)
            if not IsOnQuest(id) and quest and not quest.IsRepeatable then
                local requiredQuests
                local doable = db:IsDoable(id)

                if not doable then
                    requiredQuests = GetRequiredQuests(quest)
                    tinsert(requiredQuests, id)
                else
                    requiredQuests = {id}
                end
                local tooltip
                if requiredQuests and #requiredQuests > 0 then
                tooltip = addon.colors.tooltip ..
                                    L("Missing pre-requisites") .. ":|r\n"
                end
                for i, qid in ipairs(requiredQuests) do
                    if i < #requiredQuests then
                        tooltip = format("%s\n%s%s (%d)", tooltip,
                                         addon.icons.turnin,
                                         db:GetQuest(qid).name, qid)
                    else
                        tooltip = format("%s\n%s%s (%d)", tooltip,
                                         addon.icons.accept,
                                         db:GetQuest(qid).name, qid)
                    end
                end
                element.tooltip = tooltip or element.tooltip
                -- skip = RXPData.skipMissingPreReqs
            elseif element.icon then
                element.icon = icon
                element.tooltip = nil
            end
        else
            element.icon = icon
            element.tooltip = nil
        end

        if addon.settings.profile.debug then
            element.tooltip = id
        end
        --element.tooltipText = element.icon .. element.text
        addon.UpdateStepText(self)
        local completed = element.completed

        if questId == id then -- repeatable quests
            if element.timer then
                addon.StartTimer(element.timer,element.timerText)
            end

            --Scryer/Aldor quests
            if id == 10551 or id == 10552 then
                return addon.ReloadGuide()
            end
            SetRecentTurnIn(id)
            addon.SetElementComplete(self)
        elseif isComplete and event ~= "WindowUpdate" and step.active then
            SetRecentTurnIn(id)
            addon.SetElementComplete(self, true)
        end

        if step.active then
            if (element.skipIfMissing and not IsOnQuest(id)) or (element.skipIfIncomplete and not IsQuestComplete(id)) then
                addon.SetElementComplete(self, true)
                ProcessItems(false, step, id, true)
                addon.UpdateItemFrame()
            elseif not event then
                ProcessItems(true, step, id, true)
                if C_SuperTrack and not step.track and not element.completed then
                    C_SuperTrack.SetSuperTrackedQuestID(id)
                end
            elseif completed ~= element.completed then
                ProcessItems(not element.completed, step, id, true)
                addon.UpdateItemFrame()
            end
        end

    end
    addon.IsOnTurnInGuide(self)
end


function addon.functions.complete(self, ...)
    if type(self) == "string" then -- on parse

        local text, id, obj, objMax, flags = ...

        flags = tonumber(flags) or 0
        id = GetQuestId(tonumber(id))
        obj = tonumber(obj)
        if not (id and obj) then
            addon.error(L("Error parsing guide") .. " " .. addon.currentGuideName ..
                            ": Invalid objective or quest ID\n" .. self)
            return
        end
        objMax = tonumber(objMax)
        if objMax and objMax <= 0 then
            objMax = nil
        end
        id = id and GetQuestId(id)
        local element = {questId = id, dynamicText = true, obj = obj,
                         objMax = objMax, requestFromServer = true,
                         text = " ", flags = flags, textOnly = (flags % 2) == 1,
                         rawtext = text
                        }
        if id and id < 0 then
            id = math.abs(id)
            element.skipIfMissing = true
            element.questId = id
        end

        -- element.title = addon.GetQuestName(id)
        -- local objectives = addon.GetQuestObjectives(id)--queries the server for items/creature names associated with the quest
        return element
    end
    local event,arg1 = ...
    if UNIT_QUEST_LOG_CHANGED and event == UNIT_QUEST_LOG_CHANGED and arg1 ~= "player" then
        return
    end
    local element = self.element
    local step = element.step
    local id = self.element.questId
    id = GetQuestId(id,nil,true)
    if IsQuestTurnedIn(id) then
        addon.SetElementComplete(self,true)
    end
    if not event then
        if step.active and addon.questCompleteItems[id] then
            local qItem = addon.questCompleteItems[id]
            if not step.activeItems then step.activeItems = {} end
            if type(qItem) == "table" then
                for _, item in pairs(qItem) do
                    step.activeItems[item] = true
                end
            else
                step.activeItems[qItem] = true
            end
        end
        addon.UpdateQuestCompletionData(self)
        if step.active and element.skipIfMissing and not IsOnQuest(element.questId) then
            addon.SetElementComplete(self,true)
        end
        if step.active and C_SuperTrack and not step.track and not element.completed then
            C_SuperTrack.SetSuperTrackedQuestID(id)
        end
    else
        if not step.active and step.index then
            if math.abs(addon.GetGuideProgress() - step.index) > 2 then
                local update = true
                for _,v in pairs(addon.updateInactiveQuest) do
                    if v == self then
                        update = false
                        break
                    end
                end
                if update and element.requestFromServer then
                    tinsert(addon.updateInactiveQuest,self)
                end
            else
                addon.updateActiveQuest[self] = addon.UpdateQuestCompletionData
            end
        elseif step.active and event ~= "WindowUpdate" then
            if element.skipIfMissing and not IsOnQuest(element.questId) then
                addon.SetElementComplete(self,true)
            else
                addon.updateActiveQuest[self] = addon.UpdateQuestCompletionData
            end
        elseif element.requestFromServer and step.active then
            addon.updateActiveQuest[self] = addon.UpdateQuestCompletionData
        end
    end
    addon.IsOnTurnInGuide(self)
end


addon.functions["goto"] = function(self, ...)
    if type(self) == "string" then -- on parse
        --element.tag = "goto"
        local text, zone, x, y, radius, optional = ...
        local element = {arrow = true, parent = true, textOnly = true}
        if zone then
            lastZone = zone
        else
            zone = lastZone
        end
        --print(zone)
        local subzone,continent = zone:match("(.-)/(%d+)")
        if subzone then
            element.fixedMapID = true
            zone,x,y,continent = addon.GetMapInfo(subzone,x,y,tonumber(continent))
            if addon.mapConversion[zone] then
                zone = addon.mapConversion[zone]
            end

            if not (x and y) then
                return addon.comms.PrettyDebug("Error parsing guide " .. (addon.currentGuideName or _G.NONE) ..
                           ": Invalid coordinates or map name\n" .. self, zone)
            end
            local zx,zy = HBD:GetZoneCoordinatesFromWorld(x, y, zone)
            if zx and zy then
                element.wx = x
                element.wy = y
                element.x = zx*100
                element.y = zy*100
                element.zone = zone
                element.instance = addon.mapConversion[continent] or tonumber(continent)
            end
        else
            element.zone, element.x , element.y = addon.GetMapInfo(zone,x,y)
        end
        if not (element.x and element.y and element.zone) then
            return addon.comms.PrettyDebug(
                        L("Error parsing guide") .. " "  .. addon.currentGuideName ..
                           ": Invalid coordinates or map name\n" .. self, element.zone or zone)
        end

        element.radius = tonumber(radius)
        radius = element.radius
        if not subzone then
            element.wx, element.wy, element.instance =
              HBD:GetWorldCoordinatesFromZone(element.x / 100, element.y / 100,
                                            element.zone)

            if addon.mapConversion[element.zone] then
                zone = addon.mapConversion[element.zone]
                local zx,zy = HBD:GetZoneCoordinatesFromWorld(element.wx, element.wy, zone)
                if not (zx and zy) then
                    local info = C_Map.GetMapInfo(zone)
                    zone = info.parentMapID
                    zx,zy = HBD:GetZoneCoordinatesFromWorld(element.wx, element.wy, zone)
                end
                if not (zx and zy) then
                    return addon.error(
                        L("Error parsing guide") .. " "  .. addon.currentGuideName ..
                           ": Invalid coordinates or map name\n" .. self, element.zone or zone)
                end
                element.x = zx * 100
                element.y = zy * 100
                element.zone = zone
            end
        end
        element.text = text

        if radius then
            if optional then
                if radius == 0 then
                    element.lowPrio = true
                    element.radius = nil
                elseif radius > 0 then
                    element.hidePin = true
                    element.parent = true
                end
            elseif radius > 0 then
                if not text or text == "" then
                    element.text = fmt(L("Go to") .. " %.1f,%.1f (%s)",
                                                 element.x, element.y, zone)
                end
                element.parent = nil
                element.textOnly = nil
                element.tooltipText = addon.icons["goto"] .. element.text
            elseif radius == 0 then
                element.arrow = nil
                element.radius = nil
            end
            if radius < 0 then
                element.radius = nil
                element.dynamic = true
            end
        end
        return element
    end

    UpdateInstanceData(self,...)

end


function addon.functions.fp(self, ...)
    if type(self) == "string" then -- on parse
        local element = {}
        local text, location, args = ...
        element.tag = "fp"
        element.confirm = 0
        local args = tonumber(args)
        if args then
            element.text = text
            element.textOnly = args % 2 == 1
            element.ignoreOnClick = bit.band(args,2) == 2
        elseif text and text ~= "" then
            element.text = text
        else
            element.text = fmt(L("Get the %s flight path"), location)
        end

        if location and location ~= "" and location:find("%w+") then
            local l = location:gsub("%-","%%-")
            for id, fp in pairs(addon.FPDB[addon.player.faction] or {}) do
                if strupper(fp.name):find(strupper(l)) then
                    element.fpId = id
                    break
                end
            end
        end

        if element.text then
            element.tooltipText = addon.icons.fp .. element.text
        end
        return element
    end
    local event, arg1, arg2 = ...
    local element = self.element
    local fpId = element.fpId
    if (event == nil and element.step.active) then
        local g = GossipGetOptions()
        if type(g) == "table" and #g > 0 then
            event = "GOSSIP_SHOW"
        end
    end
    --print('v',element.fpId,RXPCData.flightPaths[element.fpId])
    if self.element.step.active then
        --print(element.fpId,'-',RXPCData.flightPaths[element.fpId])
        local fpDiscovered = fpId and RXPCData.flightPaths[fpId]
        if element.textOnly and fpDiscovered and not element.text then
            element.step.completed = true
            addon.updateSteps = true
        elseif fpDiscovered or fpId and (addon.flightInfo.lastFlightSrc == fpId or
                                  addon.flightInfo.lastFlightDest == fpId) then
            addon.SetElementComplete(self)
        elseif event == "UI_INFO_MESSAGE" and (arg2 == _G.ERR_NEWTAXIPATH or arg2 == _G.ERR_TAXINOPATHS) and not element.ignoreOnClick then
            local currentMap = C_Map.GetBestMapForUnit("player")
            local validFP = false
            if addon.FPbyZone then
                for mapId,flightId in pairs(addon.FPbyZone[addon.player.faction] or {}) do
                    if currentMap == mapId then
                        validFP = true
                        if not RXPCData.flightPaths[flightId] then
                            RXPCData.flightPaths[flightId] = addon.FPDB[addon.player.faction][flightId] and addon.FPDB[addon.player.faction][flightId].name
                        end
                    end
                end
                if not validFP or fpId and RXPCData.flightPaths[fpId] then
                    addon.SetElementComplete(self)
                end
            else
                local nearestFP = addon.GetNearestFp()
                if nearestFP then
                    RXPCData.flightPaths[nearestFP] = addon.FPDB[addon.player.faction][nearestFP] and addon.FPDB[addon.player.faction][nearestFP].name
                end
                addon.SetElementComplete(self)
            end
        elseif (GetTime() - element.confirm) > 10 and event == "GOSSIP_SHOW" and addon.SelectGossipType("taxi") then
            element.confirm = GetTime()
        end
    end
end


function addon.functions.fly(self, ...)
    if type(self) == "string" then -- on parse
        local element = {}
        local text, location = ...
        element.tag = "fly"

        if text and text ~= "" then
            element.text = text
        elseif not location then
            return addon.error(
                        L("Error parsing guide") .. " "  .. addon.currentGuideName ..
                           ": Invalid text/location\n" .. self)
        else
            element.text = L("Fly to") .. " " .. location
        end
        if location and location ~= "" and location:find("%w") then
            element.location = strupper(location)
        else
            element.location = nil
        end
        element.tooltipText = addon.icons.fly .. element.text
        return element
    end

    if not addon.settings.profile.enableFPAutomation or IsShiftKeyDown() then return end

    local element = self.element
    if not element.step.active then return end
    local event = ...
    if not element.confirm and event == "GOSSIP_SHOW" and addon.SelectGossipType("taxi") then
        element.confirm = true
    elseif event == "TAXIMAP_OPENED" and addon.settings.profile.enableFPAutomation and
        element.location then
        addon:TAXIMAP_OPENED()
        local loc = element.location:gsub("%-","%%-")
        local x,y,_,map = UnitPosition('player')
        for i = 1, NumTaxiNodes() do
            local id = addon.flightInfo[i]
            local name = id and addon.FPDB[addon.player.faction] and addon.FPDB[addon.player.faction][id] and addon.FPDB[addon.player.faction][id].name
            if not name and addon.taxiPos then
                local data = addon.taxiPos[map][id]
                name = data and data.name
            end
            if name and strupper(name):find(loc) then
                local button = getglobal("TaxiButton" .. i)
                if button then
                    _G.TaxiNodeOnButtonEnter(button)
                end
                TakeTaxiNode(i)
                return not _G.GameTooltip:IsForbidden() and _G.GameTooltip:Hide()
            end
        end
    elseif (event and UnitOnTaxi("player")) or
        (event == "PLAYER_CONTROL_LOST" and GetTime() - addon.flightInfo.startFlight < 1.5) then
        addon.SetElementComplete(self)

        -- Only send flight announcements on initial loss
        if event == "PLAYER_CONTROL_LOST" then
            addon.comms:AnnounceStepEvent('.fly', {
                destination = addon.flightInfo.dest,
                duration = addon.flightInfo.timer,
                guideName = RXPCData.currentGuideName
            })
        end

        if element.timer then
            addon.StartTimer(element.timer,element.timerText)
        end
    end
end


function addon.functions.deathskip(self, ...)
    if type(self) == "string" then -- on parse
        local element = {}
        local text = ...
        if text and text ~= "" then
            element.text = text
        else
            element.text = L("Die and respawn at the graveyard")
        end
        element.tooltipText = addon.icons.deathskip .. element.text
        addon.step.softcore = true
        element.targets = {L"Spirit Healer"}
        return element
    end
    if not self.element.step.active then return end
    local event,arg1 = ...
    -- spell=418460 (chill of the grave) is cast every time a player resurrect (forever) through the UNIT_SPELLCAST_FAILED_QUIET event
    if event == "CONFIRM_XP_LOSS" or event == "PLAYER_INTERACTION_MANAGER_FRAME_SHOW" and arg1 == Enum.PlayerInteractionType.SpiritHealer then
        addon.SetElementComplete(self)
        if C_PlayerInteractionManager then
            self:SetScript("OnUpdate", function()
                C_PlayerInteractionManager.ConfirmationInteraction(Enum.PlayerInteractionType.SpiritHealer)
                C_PlayerInteractionManager.ClearInteraction(Enum.PlayerInteractionType.SpiritHealer)
                self:SetScript("OnUpdate",nil)
            end)
        elseif _G.AcceptXPLoss then
            _G.AcceptXPLoss()
            _G.StaticPopup1:Hide()
            _G.StaticPopup2:Hide()
        end
    elseif event == "GOSSIP_SHOW" or event == "PLAYER_INTERACTION_MANAGER_FRAME_SHOW" and arg1 == Enum.PlayerInteractionType.Gossip then
        addon.SelectGossipType("healer")
    end
end


function addon.functions.link(self, ...)
    if type(self) == "string" then -- on parse
        local element = {}
        local text, url = ...
        if not (url and text) then
            return addon.error(
                    L("Error parsing guide") .. " " .. addon.currentGuideName ..
                           ": Invalid text/url\n" .. self)
        end
        element.textOnly = true
        element.url = url:gsub("\\?\\%-","-")
        element.hideTooltip = true
        element.tooltip = L("Click to view the link")
        element.text = text
        return element
    end
    if self and self.highlight then
        self.highlight:Show()
        self:SetScript("OnMouseDown", LinkOnClick)
    end
end


function addon.functions.target(self, text, ...)
    if type(self) == "string" then
        local element = {}

        if text and text ~= "" then element.text = text end
        element.textOnly = true
        local t = {...}
        element.targets = t
        local prefix = t[1]
        if prefix and prefix:sub(1,1) == "+" then
            t[1] = prefix:sub(2,-1)
            element.parent = true
        end
        element.unitlist = t
        CheckNpcIds(element,t)
        return element
    end

    UpdateNpcNames(self.element)
    UpdateTargets(self.element,"targets")
end

