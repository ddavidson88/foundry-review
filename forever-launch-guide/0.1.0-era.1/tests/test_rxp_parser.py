#!/usr/bin/env python3
"""EMULATED: pinned upstream RXP parser/tag functions, with WoW/map adapters.

This exercises real upstream ParseGuide/ParseLine/RegisterGuide and selected
tag parsers. It does not emulate the WoW client, quest events, maps, or UI.
Run: python tests/test_rxp_parser.py [path/to/Guide.lua]
Requires lupa (Lua 5.1 binding).
"""
from pathlib import Path
import hashlib
import json
import sys
from lupa.lua51 import LuaRuntime

ROOT = Path(__file__).resolve().parent
VENDOR = ROOT / 'upstream'
PRELUDE = r'''
local addonName, addon = 'RXPGuides', ...
local class, race = addon.player.class, addon.player.race
local locale = 'enUS'
local fmt, tremove, tinsert = string.format, table.remove, table.insert
local unpack = unpack
local L = function(s) return s end
local aCache, embeddedGuides = {}, {}
local RXPGuides = addon.RXPGuides
local lastZone
local GetQuestId = function(id) return id end
local CheckNpcIds = function(element, ids) end
local UpdateInstanceData = function() end
local HBD = {
 GetWorldCoordinatesFromZone=function(self,x,y,map) return x*1000,y*1000,0 end,
 GetZoneCoordinatesFromWorld=function(self,x,y,map) return x/1000,y/1000 end,
}
'''
SETUP = r'''
strlower=string.lower; strupper=string.upper
UnitLevel=function() return 1 end
UnitSex=function() return 2 end
GetLocale=function() return 'enUS' end
bit={band=function(a,b)
 local x,p=0,1
 while a>0 or b>0 do
  if a%2==1 and b%2==1 then x=x+p end
  a=math.floor(a/2);b=math.floor(b/2);p=p*2
 end
 return x
end}
local maps={Teldrassil=1438,Darnassus=1457,Darkshore=1439,Wetlands=1437,
 ['Dun Morogh']=1426,Ironforge=1455,['Stormwind City']=1453,
 ['Elwynn Forest']=1429,['Redridge Mountains']=1433,Duskwood=1431,Westfall=1436}
addon={player={class='WARRIOR',race='NightElf',faction='Alliance',hardcore=false},
 game='CLASSIC',functions={},separators={},RXPGuides={},mapConversion={},
 guides={},minGuideVersion=0,maxGuideVersion=0,farmGuides=0,
 settings={profile={},ReplaceColors=function(x)return x end},
 comms={PrettyDebug=function(...)error(string.format(...))end},
 icons={goto='',fp='',fly='',deathskip=''},
 pickUpList={},turnInList={},FPDB={Alliance={
 [26]={name='Auberdine'},[27]={name="Rut'theran Village"},
 [2]={name='Stormwind'},[5]={name='Lakeshire'},[12]={name='Darkshire'},
 [4]={name='Sentinel Hill'},[6]={name='Ironforge'},[7]={name='Menethil Harbor'}}}}
addon.error=error
addon.A32=function() return 1000 end -- guide-id hash is outside parse behavior tested
addon.GetMapInfo=function(zone,x,y)
 local map=tonumber(zone) or maps[zone]
 assert(map,'Unknown map: '..tostring(zone))
 x,y=tonumber(x),tonumber(y)
 assert(x and y and x>=0 and x<=100 and y>=0 and y<=100,'Bad coordinates')
 return map,x,y
end
addon.GroupOverride=function(guide)return guide.group end
addon.InsertQuestGuide=function(id,list)list[#list+1]=id end
addon.AddGuide=function(guide)if guide then addon.guides[#addon.guides+1]=guide;return true end end
addon.addonLoaded=true
'''

def runtime(*, race='NightElf', faction='Alliance', game='CLASSIC'):
    meta=json.loads((VENDOR/'PROVENANCE.json').read_text())
    source=(VENDOR/'parser-excerpts.lua').read_bytes()
    assert hashlib.sha256(source).hexdigest()==meta['excerpts_sha256']
    lua=LuaRuntime(unpack_returned_tuples=True)
    lua.execute(SETUP)
    lua.globals().addon.player.race = race
    lua.globals().addon.player.faction = faction
    lua.globals().addon.game = game
    lua.execute(PRELUDE+source.decode(),lua.globals().addon)
    lua.execute('RXPGuides={RegisterGuide=addon.RegisterGuide}')
    return lua

def parse(lua,body):
    result=lua.globals().addon.ParseGuide(body)
    return result[0],result[1]

def checks():
    lua=runtime()
    pre='#classic\n#version 1\n<< Alliance\n#group Test\n#name Test\n'
    g,e=parse(lua,pre+'step\n .goto Teldrassil,62.71,56.40\n +Confirm discovery\n')
    assert not e
    els=g['steps'][1]['elements']
    assert els[1]['textOnly'] is True and els[1]['radius'] is None
    assert els[2]['text']=='Confirm discovery' and not els[2]['textOnly']
    g,e=parse(lua,pre+'step\n .goto Teldrassil,62.71,56.40,10\n')
    assert not e and g['steps'][1]['elements'][1]['radius']==10
    assert not g['steps'][1]['elements'][1]['textOnly']
    g,e=parse(lua,pre+'step\n .accept 62 >> Accept Fargodeep\nstep\n .complete 62,1\nstep\n .turnin 62 >> Turn in Fargodeep\n')
    assert not e and len(g['steps'])==3
    assert g['steps'][2]['elements'][1]['questId']==62
    assert g['steps'][2]['elements'][1]['obj']==1
    g,e=parse(lua,pre+'step\n .deathskip >> Resurrect at healer\n')
    assert not e and g['steps'][1]['softcore'] is True
    g,e=parse(lua,pre+'step\n .fp Auberdine\nstep\n .fly Auberdine\n')
    assert not e and g['steps'][1]['elements'][1]['fpId']==26
    assert g['steps'][2]['elements'][1]['location']=='AUBERDINE'
    g,e=parse(lua,pre+'step\n .target Harlan Bagley\n .link https://www.wowhead.com/forever/quest=458 >> Quest reference\n +Confirm stop complete\n')
    assert not e
    els=g['steps'][1]['elements']
    assert els[1]['targets'][1]=='Harlan Bagley' and els[1]['textOnly'] is True
    assert els[2]['url']=='https://www.wowhead.com/forever/quest=458' and els[2]['textOnly'] is True
    assert not els[3]['textOnly']
    _,e=parse(lua,pre.replace('<< Alliance','<< Horde')+'step\n +Test\n')
    assert e=='Horde'
    _,e=parse(lua,pre.replace('#classic','#tbc')+'step\n +Test\n')
    assert e=='#0'
    g,e=parse(runtime(game='FOREVER'),pre+'step\n +Test\n')
    assert not e and g['classic']=='', '#classic also permits Forever in this upstream parser'
    _,e=parse(runtime(race='Human'),pre.replace('<< Alliance','<< Alliance NightElf')+'step\n +Test\n')
    assert e=='Alliance NightElf'
    for invalid in ['.complete 62','.accept bad','.not_a_tag x']:
        try:parse(lua,pre+'step\n '+invalid+'\n')
        except Exception:pass
        else:raise AssertionError('Parser accepted invalid input '+invalid)
    print('PASS: upstream parser/tag behavior checks (EMULATED)')

def load_guide(path, *, interface=11509, project=2, hardcore=False,
               season=False, race='NightElf', faction='Alliance', rxp_present=True):
    lua=runtime(race=race, faction=faction)
    # These values are adapters, not real client APIs.
    lua.globals().test_interface=interface
    lua.globals().test_project=project
    lua.globals().test_hardcore=hardcore
    lua.globals().test_season=season
    lua.execute('WOW_PROJECT_CLASSIC=2; WOW_PROJECT_ID=test_project; GetBuildInfo=function()return "emulated","0","",test_interface end; C_GameRules={IsHardcoreActive=function()return test_hardcore end}; C_Seasons={HasActiveSeason=function()return test_season end}; DEFAULT_CHAT_FRAME={AddMessage=function()end}; print=function()end')
    if not rxp_present:
        lua.execute('RXPGuides=nil')
    lua.execute(path.read_text())
    return lua.globals().addon.guides

def guide_file(path):
    guides=load_guide(path)
    assert len(guides)>0,'No guide registered'
    count=0
    for _,guide in guides.items():
        assert guide['name'] and guide['group']
        assert len(guide['steps'])>0
        for i,step in guide['steps'].items():
            els=list(step['elements'].values())
            assert any(not e['textOnly'] for e in els),f'Step {i} has no completion objective'
            for e in els:
                assert e['tag']!='xp','Rehearsal must not block on projected Forever XP'
                if e['tag']=='goto':
                    assert e['radius'] is None and e['textOnly'] is True, f'Step {i}: route arrows must leave discovery confirmation manual'
            count+=1
    print(f'PASS: {len(guides)} guide(s), {count} steps parsed with pinned upstream logic (EMULATED)')
    return count

def guard_matrix(path):
    cases=[
        ('Era lower interface bound', {'interface':11500}, True),
        ('Era upper interface bound', {'interface':11599}, True),
        ('Older Classic interface', {'interface':11499}, False),
        ('Future Classic interface', {'interface':11600}, False),
        ('Forever interface', {'interface':16001}, False),
        ('Non-Classic project', {'project':1}, False),
        ('Hardcore', {'hardcore':True}, False),
        ('Season', {'season':True}, False),
        ('Other Alliance race', {'race':'Human'}, False),
        ('Horde', {'race':'Scourge','faction':'Horde'}, False),
        ('Missing RXPGuides', {'rxp_present':False}, False),
    ]
    for name,kwargs,expected in cases:
        guides=load_guide(path,**kwargs)
        assert bool(len(guides))==expected, f'{name}: registration was {bool(len(guides))}, expected {expected}'
    print(f'PASS: {len(cases)} loader/eligibility cases (EMULATED)')

if __name__=='__main__':
    checks()
    target=Path(sys.argv[1]) if len(sys.argv)>1 else ROOT.parent/'ForeverLaunchGuide'/'Guide.lua'
    if target.exists():
        guide_file(target)
        guard_matrix(target)
    else:print('Guide not present yet; parser behavior checks only.')
