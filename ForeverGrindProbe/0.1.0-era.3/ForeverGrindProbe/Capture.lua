local _, G = ...
if not G.enabled then return end
local function creature(guid) return guid and guid:match("^Creature%-%d+%-%d+%-%d+%-%d+%-(%d+)%-") end
local function group() return IsInGroup() or IsInRaid() end
local function own(guid) return guid==G.player or (guid and guid==UnitGUID("pet")) end
function G.observe(unit)
    local guid=UnitGUID(unit); local r=guid and G.live and G.live[guid]
    if not r then return end
    local level=UnitLevel(unit)
    if not r.mob_level and type(level)=="number" and level>0 then
        r.mob_level=level; r.level_source=unit; r.t_observed=G.now(); r.flags.no_level=nil
    end
    if r.tap_denied==nil then
        r.tap_denied=UnitIsTapDenied(unit) and true or false
        if r.tap_denied then r.flags.tap_denied=true end
    end
end
function G.scan()
    for _,unit in ipairs({"target","mouseover","softenemy"}) do G.observe(unit) end
    for i=1,40 do G.observe("nameplate"..i) end
end
function G.engage(guid,name,t)
    local r=G.byGuid[guid]
    if r then return r end
    if G.closing or G.capacityClosing then return end
    if G.count()>=G.maxRecords or G.storageSize(G.db)>=G.maxBytes-65536 then
        G.capacityClosing=true; return
    end
    r={guid=guid,npc_id=tonumber(creature(guid)),name=G.clip(name,120),t_engage=t,last_action=t,
        player_at_engage=G.xp(),flags={}}
    if group() then r.flags.group=true end
    if G.paused then r.flags.paused_midfight=true end
    for _,other in pairs(G.live) do
        if not other.t_death and not other.flags.evade_or_flee then other.flags.multi_engaged=true; r.flags.multi_engaged=true end
    end
    G.session.records[#G.session.records+1]=r; G.live[guid]=r; G.byGuid[guid]=r
    G.scan(); return r
end
function G.combat(t,event,source,sourceName,dest,destName,missType)
    if not G.session then return end
    local r=G.byGuid[dest]
    if event=="UNIT_DIED" then
        if dest==G.player then
            for _,x in pairs(G.live) do if not x.t_death then x.flags.player_died=true end end
        elseif r and not r.t_death then
            r.t_death=t; r.player_at_death=G.xp()
            if G.closing and t>G.closing then r.flags.incomplete=true end
        end
        return
    end
    if event=="PARTY_KILL" then
        if r then r.killing_blow=source==G.player; if source==UnitGUID("pet") then r.flags.pet=true end end
        return
    end
    local action=event=="SWING_DAMAGE" or event=="SWING_MISSED" or event=="RANGE_DAMAGE" or event=="RANGE_MISSED"
        or event:match("^SPELL.*_DAMAGE$") or event:match("^SPELL.*_MISSED$") or event=="SPELL_CAST_SUCCESS"
    if not action then return end
    if r and not own(source) and event:match("DAMAGE$") then r.flags.external_damage=true end
    if G.closing then return end
    local playerAction=own(source) and creature(dest)
    local mobAction=creature(source) and own(dest)
    if not playerAction and not mobAction then return end
    if mobAction then r=G.engage(source,sourceName,t) else r=G.engage(dest,destName,t) end
    if not r or r.t_death then return end
    r.last_action=t
    if playerAction then r.t_first_player_action=r.t_first_player_action or t
    else r.t_first_mob_action=r.t_first_mob_action or t end
    if source==UnitGUID("pet") or dest==UnitGUID("pet") then r.flags.pet=true end
    if group() then r.flags.group=true end
    if G.paused then r.flags.paused_midfight=true end
    if missType=="EVADE" then r.flags.evade_or_flee=true end
    G.scan()
end
function G.sampleXP()
    local b=G.baseline; local c=G.xp(); local t=G.now()
    if not G.validXP(c) then return end
    if (G.announced and c.level<G.announced) or (c.level==b.level and c.max~=b.max)
        or (c.level==b.level+1 and c.xp==b.xp) then return end
    local delta=G.delta(b,c)
    if delta==nil then return end -- preserve baseline; uncertainty is not invented XP
    if delta==0 then G.candidate=nil; return end
    local a=G.candidate
    if not a or a.after.level~=c.level or a.after.xp~=c.xp or a.after.max~=c.max then
        G.candidate={before=b,after=c,delta=delta,t=t}; return
    end
    if t-a.t<0.20 then return end
    G.transitions[#G.transitions+1]=a; G.baseline=c; G.candidate=nil; G.announced=nil
end
-- English clients only in this candidate. Unsupported formats retained, never guessed.
function G.parse(message)
    local name,total,tail=message:match("^(.-) dies, you gain (%d+) experience%.(.*)$")
    if not name then return nil end
    local a={name=name,total=tonumber(total),raw=G.clip(message,512),rested=0}
    if tail:match("%S") then
        local rested=tail:match("^ %(%+?(%d+) exp Rested bonus%)$")
        if rested then a.rested=tonumber(rested) else a.parse_unknown=true end
    end
    if not a.parse_unknown and a.rested<=a.total then a.base=a.total-a.rested else a.parse_unknown=true end
    return a
end
function G.message(message)
    if not G.session then return end
    local a=G.parse(message)
    if not a then
        -- Quest awards are not grinding XP. Retain only bounded diagnostics for unknown kill syntax.
        if message:find(" dies,",1,true) and #G.session.marks<100 then
            G.session.marks[#G.session.marks+1]={t=G.now(),note="Unparsed XP: "..G.clip(message,512)}
        end
        return
    end
    if #G.session.awards>=G.maxRecords or #G.pending>=100 then G.capacityClosing=true; return end
    a.t=G.now(); a.paused=G.paused and true or false
    if G.closing then a.after_stop=true end
    G.session.awards[#G.session.awards+1]=a; G.pending[#G.pending+1]=a
end
function G.resolve(force)
    local t=G.now()
    for _,a in ipairs(G.pending) do
        if not a.resolved and (force or t-a.t>G.window+0.25) then
            local candidates={}
            -- Full retained records, not just live cache: same-name ambiguity survives cleanup.
            for _,r in ipairs(G.session.records) do
                if r.name==a.name and r.t_death and math.abs(r.t_death-a.t)<=G.window then candidates[#candidates+1]=r end
            end
            -- Wait another window: catches later XP messages competing for the same death.
            if force or t-a.t>G.window*2+0.1 then
                a.resolved=true
                if #candidates==1 then
                    local r=candidates[1]; local competitors=0
                    for _,b in ipairs(G.session.awards) do
                        if b.name==r.name and math.abs(b.t-r.t_death)<=G.window then competitors=competitors+1 end
                    end
                    if competitors~=1 or r.xp_total then
                        r.flags.ambiguous_xp=true; a.match="ambiguous"
                    else
                        a.match=r.guid; r.xp_total=a.total; r.xp_base=a.base; r.xp_rested=a.rested
                        r.raw_message=a.raw; r.matched_by="unique_name_death_window"; r.t_xp=a.t
                        if a.parse_unknown then r.flags.xp_parse_unknown=true end
                        if a.paused then r.flags.paused_midfight=true end
                        if a.after_stop and r.t_death<=G.closing then a.after_stop=nil end
                        local states={}
                        for _,x in ipairs(G.transitions) do
                            if math.abs(x.t-a.t)<=G.window and x.delta==a.total then states[#states+1]=x end
                        end
                        if #states==1 then
                            local x=states[1]; local shares=0
                            for _,b in ipairs(G.session.awards) do
                                if b.total==x.delta and math.abs(b.t-x.t)<=G.window then shares=shares+1 end
                            end
                            if shares==1 then
                                r.player_before_award=x.before; r.player_after_award=x.after
                                r.player_level_bucket=x.before.level
                                if x.after.level>x.before.level then r.flags.level_up=true end
                            else r.flags.xp_state_unknown=true end
                        else r.flags.xp_state_unknown=true end
                    end
                elseif #candidates>1 then
                    a.match="ambiguous"
                    for _,r in ipairs(candidates) do r.flags.ambiguous_xp=true end
                else a.match="unmatched" end
            end
        end
    end
    local keep={}
    for _,a in ipairs(G.pending) do if not a.resolved then keep[#keep+1]=a end end
    G.pending=keep
end
function G.tick()
    local s=G.session; if not s then return end
    local t=G.now()
    if not G.paused and not G.closing then s.elapsed=s.elapsed+math.max(0,t-G.lastTick) end
    G.lastTick=t; s.last_t=t
    G.sampleXP(); G.resolve(false)
    for guid,r in pairs(G.live) do
        if not r.t_death and t-r.last_action>30 then r.flags.evade_or_flee=true; G.live[guid]=nil
        elseif r.t_death and t-r.t_death>5 then G.live[guid]=nil end
    end
    local keep={}; for _,x in ipairs(G.transitions) do if t-x.t<6 then keep[#keep+1]=x end end; G.transitions=keep
    if G.closing and t-G.closing>=3.2 then G.finish() end
end
local frame=CreateFrame("Frame"); G.frame=frame
local events={"COMBAT_LOG_EVENT_UNFILTERED","CHAT_MSG_COMBAT_XP_GAIN","PLAYER_XP_UPDATE","PLAYER_LEVEL_UP",
    "PLAYER_TARGET_CHANGED","UPDATE_MOUSEOVER_UNIT","NAME_PLATE_UNIT_ADDED","PLAYER_DEAD","PLAYER_LOGOUT","PLAYER_ENTERING_WORLD","GROUP_ROSTER_UPDATE"}
function G.register(on)
    for _,e in ipairs(events) do if on then frame:RegisterEvent(e) else frame:UnregisterEvent(e) end end
    frame:SetScript("OnUpdate",on and function()
        if G.now()-(G.lastPoll or 0)<0.1 then return end
        G.lastPoll=G.now(); G.tick()
        if G.session and not G.closing then
            if not G.lastSizeCheck or G.now()-G.lastSizeCheck>=1 then
                G.lastSizeCheck=G.now(); if G.storageSize(G.db)>=G.maxBytes-65536 then G.capacityClosing=true end
            end
            if G.capacityClosing then G.stop("storage_cap") end
        end
    end or nil)
end
frame:SetScript("OnEvent",function(_,event,...)
    if event=="COMBAT_LOG_EVENT_UNFILTERED" then
        local v={CombatLogGetCurrentEventInfo()}
        local miss=v[2]=="SWING_MISSED" and v[12] or (v[2]:match("MISSED$") and v[15])
        G.combat(G.now(),v[2],v[4],v[5],v[8],v[9],miss)
    elseif event=="CHAT_MSG_COMBAT_XP_GAIN" then G.message((...))
    elseif event=="PLAYER_XP_UPDATE" then G.sampleXP()
    elseif event=="PLAYER_LEVEL_UP" then G.announced=tonumber((...))
    elseif event=="PLAYER_DEAD" then for _,r in pairs(G.live) do if not r.t_death then r.flags.player_died=true end end
    elseif event=="GROUP_ROSTER_UPDATE" then if group() then for _,r in pairs(G.live) do r.flags.group=true end end
    elseif event=="PLAYER_LOGOUT" or event=="PLAYER_ENTERING_WORLD" then
        G.stop(event); if G.session then G.finish() end
    elseif event=="NAME_PLATE_UNIT_ADDED" then G.observe((...))
    else G.scan() end
end)
