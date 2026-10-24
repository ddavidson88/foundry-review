local _, G = ...
G.version = "0.1.0-era.2"
local _, _, _, interface = GetBuildInfo()
G.enabled = type(interface)=="number" and interface>=11500 and interface<11600
if not G.enabled then return end
G.interface = interface
G.maxRecords, G.maxSessions, G.maxBytes = 2000, 50, 1500000
G.window = 1.5
function G.now() return GetTime() end
function G.say(s) DEFAULT_CHAT_FRAME:AddMessage("Grind Probe: "..s) end
function G.clip(s,n) return tostring(s or ""):sub(1,n or 160) end
function G.xp() return {level=UnitLevel("player"),xp=UnitXP("player"),max=UnitXPMax("player")} end
-- Adapted from ForeverRouteProbe beta.3 Core.lua; original remains untouched.
function G.validXP(x)
    return x and type(x.level)=="number" and x.level>0 and type(x.xp)=="number" and x.xp>=0
        and type(x.max)=="number" and x.max>0 and x.xp<x.max
end
function G.delta(a,b)
    if not G.validXP(a) or not G.validXP(b) then return nil end
    if b.level==a.level and b.xp>=a.xp then return b.xp-a.xp end
    if b.level==a.level+1 then return a.max-a.xp+b.xp end
end
local function quote(s)
    return '"'..s:gsub('[%z\1-\31\\"]',function(c)
        if c=='"' then return '\\"' elseif c=='\\' then return '\\\\' end
        return string.format('\\u%04x',string.byte(c))
    end)..'"'
end
-- Deterministic JSON: arrays represented as objects with numeric string keys.
function G.json(v)
    local t=type(v)
    if t=="string" then return quote(v) end
    if t=="boolean" then return tostring(v) end
    if t=="number" then return string.format("%.17g",v) end
    if t~="table" then return "null" end
    local keys,out={},{}
    for k in pairs(v) do keys[#keys+1]=k end
    table.sort(keys,function(a,b) return tostring(a)<tostring(b) end)
    for _,k in ipairs(keys) do out[#out+1]=quote(tostring(k))..":"..G.json(v[k]) end
    return "{"..table.concat(out,",").."}"
end
-- Conservative SavedVariables-size estimate, not just compact JSON bytes.
-- Includes quoted keys, punctuation and four-space indentation per nesting level.
function G.storageSize(v,depth)
    depth=depth or 0
    if type(v)~="table" then return #G.json(v)+8 end
    local n=16+depth*4
    for k,x in pairs(v) do n=n+#G.json(tostring(k))+24+(depth+1)*4+G.storageSize(x,depth+1) end
    return n
end
function G.load()
    if ForeverGrindProbeDB==nil then ForeverGrindProbeDB={schema=1,sessions={}} end
    local d=ForeverGrindProbeDB
    if type(d)~="table" or d.schema~=1 or type(d.sessions)~="table" then
        G.say("Unsupported saved data; recording blocked. Archive the saved file. Nothing replaced."); return
    end
    G.db=d
    for _,s in ipairs(d.sessions) do
        if not s.stopped then s.stopped=s.last_t or s.started; s.stop_reason="interrupted_reload" end
    end
end
function G.count()
    local n=0
    for _,s in ipairs(G.db.sessions) do n=n+#s.records end
    return n
end
function G.start(label)
    if G.session then G.say("Stop the current test first."); return end
    if not G.db then G.load() end
    if not G.db then return end
    if G.count()>=G.maxRecords or #G.db.sessions>=G.maxSessions or G.storageSize(G.db)>=G.maxBytes-65536 then
        G.say("Archive saved data before more tests; storage cap reached."); return
    end
    if not G.validXP(G.xp()) then G.say("Player XP state unavailable; try again after loading."); return end
    local t=G.now()
    local s={id=tostring(GetServerTime())..":"..(#G.db.sessions+1),label=G.clip(label),version=G.version,
        interface=G.interface,character=UnitName("player"),guid=UnitGUID("player"),locale=GetLocale(),
        started=t,wall_start=GetServerTime(),last_t=t,elapsed=0,records={},awards={},marks={},pauses={}}
    G.db.sessions[#G.db.sessions+1]=s; G.session=s
    G.live={}; G.byGuid={}; G.pending={}; G.transitions={}; G.baseline=G.xp(); G.candidate=nil; G.announced=nil
    G.player=UnitGUID("player"); G.lastTick=t; G.closing=nil; G.paused=nil; G.capacityClosing=nil
    G.register(true); G.say("Started: "..s.label..". One species per test; /grind pause for breaks.")
end
function G.pause()
    if not G.session or G.closing or G.paused then return end
    G.tick(); G.paused=G.now()
    for _,r in pairs(G.live) do if not r.t_death then r.flags.paused_midfight=true end end
    G.session.pauses[#G.session.pauses+1]={start=G.paused}
    G.say("Paused. Combat during a break is excluded.")
end
function G.resume()
    if not G.session or not G.paused or G.closing then return end
    local p=G.session.pauses[#G.session.pauses]; p.stop=G.now()
    G.paused=nil; G.lastTick=G.now(); G.say("Resumed.")
end
function G.stop(reason)
    if not G.session or G.closing then return end
    G.tick(); if not G.session then return end
    G.closing=G.now(); G.session.stopped=G.closing; G.session.stop_reason=reason or "manual"
    if G.paused then G.session.pauses[#G.session.pauses].stop=G.closing end
    for _,r in pairs(G.live) do if not r.t_death then r.flags.incomplete=true end end
    G.say("Stopped; settling final XP messages for 3.2 seconds.")
end
local exclusions={"tap_denied","no_xp","group","pet","evade_or_flee","player_died","paused_midfight",
    "ambiguous_xp","no_level","xp_state_unknown","xp_parse_unknown","external_damage","incomplete"}
function G.summary(s)
    local q={xp_actual=0,xp_base=0,xp_rested=0,kills=0,clean_single=0,multi=0,excluded=0,reasons={},
        unmatched_awards=0,ambiguous_awards=0}
    local durations={}
    for _,a in ipairs(s.awards) do if not a.paused and not a.after_stop then q.xp_actual=q.xp_actual+(a.total or 0) end end
    for _,a in ipairs(s.awards) do
        if a.match=="unmatched" then q.unmatched_awards=q.unmatched_awards+1 end
        if a.match=="ambiguous" then q.ambiguous_awards=q.ambiguous_awards+1 end
    end
    for _,r in ipairs(s.records) do
        if r.t_death then q.kills=q.kills+1 end
        if not r.xp_total then r.flags.no_xp=true end
        if not r.mob_level then r.flags.no_level=true end
        local bad=false
        for _,f in ipairs(exclusions) do if r.flags[f] then bad=true; q.reasons[f]=(q.reasons[f] or 0)+1 end end
        if bad then q.excluded=q.excluded+1
        elseif r.flags.multi_engaged then q.multi=q.multi+1
        else
            q.clean_single=q.clean_single+1
            durations[#durations+1]=r.t_death-r.t_engage
            q.xp_base=q.xp_base+(r.xp_base or 0); q.xp_rested=q.xp_rested+(r.xp_rested or 0)
        end
    end
    table.sort(durations); local n=#durations
    if n>0 then q.median_ttk=(durations[math.floor((n+1)/2)]+durations[math.ceil((n+1)/2)])/2 end
    q.elapsed=s.elapsed; q.xp_per_min=s.elapsed>0 and q.xp_actual*60/s.elapsed or 0
    s.summary=q
    return q
end
function G.finish()
    local s=G.session; if not s then return end
    G.resolve(true)
    local q=G.summary(s)
    G.register(false); G.session=nil; G.live=nil; G.pending=nil; G.transitions=nil
    G.say(string.format("Uncontested Era rate: %.1f XP/min; %d deaths; %d clean singles; median TTK %s; %d excluded. /grind export",
        q.xp_per_min,q.kills,q.clean_single,q.median_ttk and string.format("%.2fs",q.median_ttk) or "n/a",q.excluded))
    if next(q.reasons) then G.say("Exclusions (overlap): "..G.json(q.reasons)) end
    if q.unmatched_awards+q.ambiguous_awards>0 then
        G.say("Award attribution: "..q.unmatched_awards.." unmatched, "..q.ambiguous_awards.." ambiguous; retained in raw test totals, not clean TTK.")
    end
end
