local _,G=...
if not G.enabled then return end
function G.exportText()
    if not G.db then G.load() end
    if not G.db then return end
    local s=G.db.sessions[#G.db.sessions]
    if not s then G.say("No tests recorded."); return end
    return G.json({schema=1,kind="ForeverGrindProbe",session=s})
end
function G.export()
    if G.session then G.say("Stop the test and wait for the summary before exporting."); return end
    local text=G.exportText(); if not text then return end
    if #text>200000 then
        G.say("Export over 200 KB. Log out normally, then copy WTF/Account/<account>/<realm>/<character>/SavedVariables/ForeverGrindProbe.lua (and .bak). No data deleted."); return
    end
    if not G.exportFrame then
        local f=CreateFrame("Frame",nil,UIParent,"BasicFrameTemplateWithInset")
        f:SetSize(700,450); f:SetPoint("CENTER"); f.TitleText:SetText("Grind Probe — Ctrl+A, Ctrl+C")
        local scroll=CreateFrame("ScrollFrame",nil,f,"UIPanelScrollFrameTemplate")
        scroll:SetPoint("TOPLEFT",12,-34); scroll:SetPoint("BOTTOMRIGHT",-32,12)
        local box=CreateFrame("EditBox",nil,scroll)
        box:SetMultiLine(true); box:SetFontObject(ChatFontNormal); box:SetWidth(640)
        box:SetAutoFocus(false); box:SetMaxLetters(0); box:SetScript("OnEscapePressed",function() f:Hide() end)
        scroll:SetScrollChild(box); f.box=box; G.exportFrame=f
    end
    local f=G.exportFrame; f:Show(); f.box:SetText(text); f.box:SetFocus(); f.box:HighlightText()
end
SLASH_FOREVERGRINDPROBE1="/grind"
SlashCmdList.FOREVERGRINDPROBE=function(msg)
    local cmd,rest=msg:match("^(%S*)%s*(.-)%s*$"); cmd=cmd:lower()
    if cmd=="start" then
        if GetLocale()~="enUS" and GetLocale()~="enGB" then G.say("Candidate supports English XP messages only; recording not started."); return end
        G.start(rest)
    elseif cmd=="pause" then G.pause()
    elseif cmd=="resume" then G.resume()
    elseif cmd=="stop" then G.stop()
    elseif cmd=="mark" then
        if G.session and not G.closing and #G.session.marks<100 then
            G.session.marks[#G.session.marks+1]={t=G.now(),note=G.clip(rest,512)}; G.say("Mark saved.")
        else G.say("No active test, or mark cap reached.") end
    elseif cmd=="export" then G.export()
    else G.say("/grind start <species / gear label> | pause | resume | stop | mark <note> | export") end
end

-- The lightweight panel lives separately from the opt-in capture frame.
-- It never calls start on login, reload, or refresh.
local function timeText(seconds)
    seconds=math.floor(math.max(0,seconds or 0))
    return string.format("%02d:%02d",math.floor(seconds/60),seconds%60)
end
function G.refreshPanel()
    local f=G.panel; if not f then return end
    local s=G.session
    local last=G.db and G.db.sessions[#G.db.sessions]
    local status,r,g,b="Idle",0.8,0.8,0.8
    if not G.db then status,r,g,b="Data blocked",1,0.3,0.3
    elseif s and G.closing then status,r,g,b="Finishing…",0.6,0.8,1
    elseif s and G.paused then status,r,g,b="Paused",1,0.8,0.2
    elseif s then status,r,g,b="Recording",0.3,1,0.4 end
    f.status:SetText(status); f.status:SetTextColor(r,g,b)
    local shown=s or last
    local elapsed=shown and shown.elapsed or 0
    if s and not G.paused and not G.closing then elapsed=elapsed+math.max(0,G.now()-G.lastTick) end
    local kills=0
    if shown then for _,record in ipairs(shown.records) do if record.t_death then kills=kills+1 end end end
    f.stats:SetText((s and "" or (last and "Last: " or ""))..timeText(elapsed).."  |  "..kills.." kills")
    f.start:SetEnabled(G.db~=nil and s==nil)
    f.pause:SetEnabled(s~=nil and not G.closing)
    f.pause:SetText(G.paused and s and "Resume" or "Pause")
    f.stop:SetEnabled(s~=nil and not G.closing)
    f.mark:SetEnabled(s~=nil and not G.closing and #s.marks<100)
    f.export:SetEnabled(G.db~=nil and last~=nil and s==nil)
    f.label:SetEnabled(G.db~=nil and s==nil)
    f.note:SetEnabled(s~=nil and not G.closing)
    -- A slash-command start should show its actual label too.
    if s and f.label:GetText()~=s.label then f.label:SetText(s.label) end
end
function G.savePanelPosition()
    if not G.panel or not G.db then return end
    local point,_,relativePoint,x,y=G.panel:GetPoint(1)
    G.db.ui=G.db.ui or {}
    G.db.ui.position={point=point,relativePoint=relativePoint,x=x,y=y}
end
function G.createPanel()
    if G.panel then return end
    if not G.db then G.load() end
    local f=CreateFrame("Frame","ForeverGrindProbePanel",UIParent,"BackdropTemplate")
    G.panel=f
    f:SetSize(286,186); f:SetFrameStrata("MEDIUM")
    f:SetClampedToScreen(true); f:SetMovable(true); f:EnableMouse(true)
    f:SetBackdrop({bgFile="Interface\\Tooltips\\UI-Tooltip-Background",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",
        tile=true,tileSize=16,edgeSize=12,insets={left=3,right=3,top=3,bottom=3}})
    f:SetBackdropColor(0.04,0.04,0.06,0.92)
    local anchors={TOPLEFT=true,TOP=true,TOPRIGHT=true,LEFT=true,CENTER=true,RIGHT=true,BOTTOMLEFT=true,BOTTOM=true,BOTTOMRIGHT=true}
    local p=G.db and G.db.ui and G.db.ui.position
    if type(p)=="table" and anchors[p.point] and anchors[p.relativePoint]
        and type(p.x)=="number" and type(p.y)=="number" and math.abs(p.x)<10000 and math.abs(p.y)<10000 then
        f:SetPoint(p.point,UIParent,p.relativePoint,p.x,p.y)
    else f:SetPoint("TOPLEFT",UIParent,"TOPLEFT",30,-180) end

    local title=f:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
    title:SetPoint("TOPLEFT",10,-9); title:SetText("Grind Probe  •  drag here")
    local drag=CreateFrame("Frame",nil,f)
    drag:SetPoint("TOPLEFT",4,-4); drag:SetPoint("TOPRIGHT",-4,-4); drag:SetHeight(22)
    drag:EnableMouse(true); drag:RegisterForDrag("LeftButton")
    drag:SetScript("OnDragStart",function() f:StartMoving() end)
    drag:SetScript("OnDragStop",function() f:StopMovingOrSizing(); G.savePanelPosition() end)
    f.drag=drag
    f.status=f:CreateFontString(nil,"OVERLAY","GameFontNormal")
    f.status:SetPoint("TOPLEFT",10,-31)
    f.stats=f:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
    f.stats:SetPoint("TOPRIGHT",-10,-33)

    local function input(width,x,y,maxLetters)
        local box=CreateFrame("EditBox",nil,f,"InputBoxTemplate")
        box:SetSize(width,22); box:SetPoint("TOPLEFT",x,y); box:SetAutoFocus(false)
        box:SetMaxLetters(maxLetters); box:SetScript("OnEscapePressed",function(self) self:ClearFocus() end)
        box:SetScript("OnEnterPressed",function(self) self:ClearFocus() end)
        return box
    end
    f.label=input(258,14,-54,160)
    f.label:SetText(G.db and G.db.ui and G.db.ui.label or "Grind test — enter species / gear")
    f.note=input(188,14,-116,512); f.note:SetText("")
    local function button(text,width,x,y,action)
        local b=CreateFrame("Button",nil,f,"UIPanelButtonTemplate")
        b:SetSize(width,24); b:SetPoint("TOPLEFT",x,y); b:SetText(text)
        b:SetScript("OnClick",function()
            f.label:ClearFocus(); f.note:ClearFocus()
            action(); G.refreshPanel()
        end)
        return b
    end
    f.start=button("Start",84,10,-83,function()
        local label=f.label:GetText():match("^%s*(.-)%s*$")
        if label=="" then label="Grind test" end
        SlashCmdList.FOREVERGRINDPROBE("start "..label)
        if G.session and G.db then G.db.ui=G.db.ui or {}; G.db.ui.label=G.session.label end
    end)
    f.pause=button("Pause",84,101,-83,function()
        SlashCmdList.FOREVERGRINDPROBE(G.paused and "resume" or "pause")
    end)
    f.stop=button("Stop",84,192,-83,function() SlashCmdList.FOREVERGRINDPROBE("stop") end)
    f.mark=button("Mark",64,212,-115,function()
        local note=f.note:GetText():match("^%s*(.-)%s*$")
        if note~="" then SlashCmdList.FOREVERGRINDPROBE("mark "..note); f.note:SetText("")
        else G.say("Type a note beside Mark first.") end
    end)
    f.export=button("Export last test",266,10,-150,function() SlashCmdList.FOREVERGRINDPROBE("export") end)
    local elapsed=0
    f:SetScript("OnUpdate",function(_,dt)
        elapsed=elapsed+dt
        if elapsed>=0.25 then elapsed=0; G.refreshPanel() end
    end)
    f:Show(); G.refreshPanel()
end
local panelLoader=CreateFrame("Frame")
G.panelLoader=panelLoader
panelLoader:RegisterEvent("PLAYER_LOGIN")
panelLoader:SetScript("OnEvent",function(self)
    self:UnregisterEvent("PLAYER_LOGIN"); G.createPanel()
end)
