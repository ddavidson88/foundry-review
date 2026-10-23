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
