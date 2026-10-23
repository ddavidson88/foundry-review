"""EMULATED Lua 5.1 tests; no claim of native client validation."""
from pathlib import Path
import unittest
from lupa.lua51 import LuaRuntime

ROOT=Path(__file__).resolve().parents[1]
MOCK=r'''
now=0; level=2; xp=100; maxxp=900; grouped=false; locale='enUS'
player='Player-1-TEST'; mob='Creature-0-1-1-1-100-0001'; mob2='Creature-0-1-1-1-100-0002'
units={target={guid=mob,level=2},nameplate1={guid=mob2,level=2}}
messages={}; frames={}; SlashCmdList={}
DEFAULT_CHAT_FRAME={AddMessage=function(_,s) messages[#messages+1]=s end}
function GetBuildInfo() return '1.15.9','70003','Sep 23 2026',interface end
function GetTime() return now end
function GetServerTime() return 1792780000+math.floor(now) end
function GetLocale() return locale end
function UnitLevel(u) if u=='player' then return level end return units[u] and units[u].level end
function UnitXP() return xp end
function UnitXPMax() return maxxp end
function UnitName(u) return u=='player' and 'Test' or 'Boar' end
function UnitGUID(u) if u=='player' then return player elseif u=='pet' then return pet end return units[u] and units[u].guid end
function UnitIsTapDenied(u) return units[u] and units[u].tap or false end
function IsInGroup() return grouped end
function IsInRaid() return false end
function CreateFrame()
 local f={events={},scripts={}}
 function f:RegisterEvent(e) self.events[e]=true end
 function f:UnregisterEvent(e) self.events[e]=nil end
 function f:SetScript(e,fn) self.scripts[e]=fn end
 frames[#frames+1]=f; return f
end
function step(t) now=t; if G.frame and G.frame.scripts.OnUpdate then G.frame.scripts.OnUpdate() end end
function event(e,...) G.frame.scripts.OnEvent(G.frame,e,...) end
function hit(t,g,e) now=t; G.combat(t,e or 'SWING_DAMAGE',player,'Test',g or mob,'Boar') end
function died(t,g) now=t; G.combat(t,'UNIT_DIED',nil,nil,g or mob,'Boar') end
function award(t,amount) now=t; G.message('Boar dies, you gain '..amount..' experience.') end
function update(t,newxp,newlevel,newmax) now=t; xp=newxp; level=newlevel or level; maxxp=newmax or maxxp; G.sampleXP() end
function finish(t) now=t; G.stop(); step(t+3.3) end
'''

class Tests(unittest.TestCase):
    def make(self,interface=11509,start=True):
        l=LuaRuntime(unpack_returned_tuples=True); l.globals().interface=interface; l.execute(MOCK)
        g=l.table(); l.globals().G=g
        for file in ('Core.lua','Capture.lua','UI.lua'):
            l.execute('return function(...)\n'+(ROOT/'ForeverGrindProbe'/file).read_text()+'\nend')('ForeverGrindProbe',g)
        if start: l.execute("G.start('Boar L2')")
        return l,g
    def clean(self,extra='',open_event='SWING_DAMAGE'):
        l,g=self.make(); l.execute(extra+f"hit(1,nil,'{open_event}'); died(10); award(10,55); update(10,155); step(10.3); step(13.2)")
        return l,g,g.session.records[1]
    def test_miss_first(self):
        l,g,r=self.clean(open_event='SWING_MISSED'); self.assertEqual(r.t_first_player_action,1)
        self.assertEqual(r.player_before_award.level,2); self.assertEqual(r.xp_base,55)
        l.execute('finish(14)'); self.assertEqual(g.db.sessions[1].summary.median_ttk,9)
    def test_mob_first(self):
        l,g=self.make(); l.execute("G.combat(1,'SWING_MISSED',mob,'Boar',player,'Test'); hit(3)")
        r=g.session.records[1]; self.assertEqual(r.t_engage,1); self.assertEqual(r.t_first_player_action,3)
    def test_add(self):
        l,g=self.make(); l.execute('hit(1); hit(2,mob2)')
        self.assertTrue(g.session.records[1].flags.multi_engaged); self.assertTrue(g.session.records[2].flags.multi_engaged)
    def test_tap(self):
        l,g,r=self.clean('units.target.tap=true;'); self.assertTrue(r.flags.tap_denied)
    def test_evade_timeout_and_guid_unique(self):
        l,g=self.make(); l.execute('hit(1); step(32); hit(33)')
        self.assertEqual(len(g.session.records),1); self.assertTrue(g.session.records[1].flags.evade_or_flee)
    def test_explicit_evade(self):
        l,g=self.make(); l.execute("hit(1); G.combat(2,'SWING_MISSED',player,'Test',mob,'Boar','EVADE')")
        self.assertTrue(g.session.records[1].flags.evade_or_flee)
    def test_player_death(self):
        l,g=self.make(); l.execute("hit(1); event('PLAYER_DEAD')")
        self.assertTrue(g.session.records[1].flags.player_died)
    def test_pause(self):
        l,g=self.make(); l.execute('hit(1); now=2; G.pause(); step(20); G.resume(); step(21)')
        self.assertEqual(g.session.elapsed,3); self.assertTrue(g.session.records[1].flags.paused_midfight)
    def test_levelup_between_death_and_xp(self):
        l,g=self.make(); l.execute("xp=880; G.baseline=G.xp(); hit(1); died(10); now=10; event('PLAYER_LEVEL_UP',3); level=3; G.sampleXP(); award(10.1,55); update(10.2,35,3,1400); step(10.5); step(13.4)")
        r=g.session.records[1]; self.assertEqual(r.player_before_award.level,2); self.assertTrue(r.flags.level_up)
    def test_xp_before_death(self):
        l,g=self.make(); l.execute('hit(1); award(9.8,55); update(9.8,155); died(10); step(10.1); step(13.1)')
        self.assertEqual(g.session.records[1].xp_total,55)
    def test_two_same_name_ambiguous(self):
        l,g=self.make(); l.execute('hit(1); hit(2,mob2); died(10); award(10,55); died(11,mob2); step(13.2)')
        self.assertTrue(g.session.records[1].flags.ambiguous_xp); self.assertIsNone(g.session.records[1].xp_total)
    def test_rested(self):
        l,g=self.make(); a=g.parse('Boar dies, you gain 110 experience. (55 exp Rested bonus)')
        self.assertEqual((a.total,a.base,a.rested),(110,55,55))
    def test_record_cap(self):
        l,g=self.make(); g.maxRecords=1; l.execute('hit(1); hit(2,mob2); step(3); step(7)')
        self.assertIsNone(g.session); self.assertEqual(len(g.db.sessions[1].records),1)
        self.assertEqual(g.db.sessions[1].stop_reason,'storage_cap')
    def test_byte_cap(self):
        l,g=self.make(); g.maxBytes=65537; l.execute('hit(1); step(2); step(6)')
        self.assertIsNone(g.session); self.assertEqual(g.db.sessions[1].stop_reason,'storage_cap')
    def test_forever_inert(self):
        l,g=self.make(16001,False); self.assertFalse(g.enabled); self.assertEqual(len(l.globals().frames),0)
        self.assertIsNone(l.globals().SlashCmdList.FOREVERGRINDPROBE)
    def test_idle_no_events(self):
        l,g=self.make(start=False); self.assertEqual(len(list(g.frame.events.items())),0)
        self.assertIsNone(g.frame.scripts.OnUpdate)
    def test_group_and_pet(self):
        l,g=self.make(); l.execute("grouped=true; pet='Pet-1'; now=1; G.combat(1,'SWING_DAMAGE',pet,'Pet',mob,'Boar')")
        r=g.session.records[1]; self.assertTrue(r.flags.group); self.assertTrue(r.flags.pet)
    def test_other_player(self):
        l,g=self.make(); l.execute("hit(1); G.combat(2,'SWING_DAMAGE','Player-2','Other',mob,'Boar')")
        self.assertTrue(g.session.records[1].flags.external_damage)
    def test_unobserved_level(self):
        l,g,r=self.clean('units={};'); l.execute('finish(14)')
        self.assertTrue(r.flags.no_level); self.assertEqual(g.db.sessions[1].summary.clean_single,0)
    def test_quest_message_ignored(self):
        l,g=self.make(); l.execute("G.message('You gain 450 experience.')")
        self.assertEqual(len(g.session.awards),0)
    def test_export_json(self):
        import json
        l,g,r=self.clean(); l.execute('finish(14)'); out=json.loads(g.exportText())
        self.assertEqual(out['session']['records']['1']['xp_total'],55)
    def test_mixed_transitional_max(self):
        l,g=self.make(); l.execute('hit(1); maxxp=1400; G.sampleXP(); step(2)')
        self.assertEqual(g.baseline.max,900); self.assertEqual(len(g.transitions),0)
    def test_duplicate_awards(self):
        l,g=self.make(); l.execute('hit(1); died(10); award(10,55); award(10.5,55); step(14)')
        self.assertTrue(g.session.records[1].flags.ambiguous_xp)
    def test_stop_incomplete(self):
        l,g=self.make(); l.execute('hit(1); finish(5)')
        self.assertTrue(g.db.sessions[1].records[1].flags.incomplete)
    def test_no_saved_data_overwrite(self):
        l,g=self.make(start=False); l.execute('ForeverGrindProbeDB={schema=99,precious=true}; G.start("x")')
        self.assertIsNone(g.session); self.assertTrue(l.globals().ForeverGrindProbeDB.precious)

if __name__=='__main__': unittest.main(verbosity=2)
