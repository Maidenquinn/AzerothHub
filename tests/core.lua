dofile("tests/mock.lua");T.Load()
local H=AzerothHub
assert(table.getn(H.rows)==7 and H.byName.Known.enabled and H.byName.Known.loaded)
assert(H.db.profiles.Leger.addons.ASBuilder==false and H.db.profiles.Leger.addons.Unrelated==false)
assert(T.writes==0 and T.reloads==0)
-- Plan is read-only, keeps the manager, and enables dependencies before any write.
local p={addons={Known=true,Library=false,AzerothHub=false},settings={}}
local plan=assert(H.Plan(p));assert(plan.target.Library and plan.target.AzerothHub and T.writes==0)
T.Row("Known").deps={"Missing"};assert(not H.Plan(p));assert(T.writes==0)
T.Row("Known").deps={"Library"};T.Row("Library").deps={"Known"};assert(not H.Plan(p));T.Row("Library").deps={}
-- New/unmentioned addons keep their enable state, whether enabled or disabled.
table.insert(T.addons,{name="NewAddon",enabled=true,loaded=true,deps={}})
plan=assert(H.Plan(p));assert(plan.target.NewAddon and not plan.target.Unrelated)
-- Native writes can fail; restore every attempted flag, do not apply settings or reload.
local bad={addons={AzerothCursor=false,Known=false},settings={}}
T.fail="Known";local ok,err=H.Apply(bad);assert(not ok and T.Row("AzerothCursor").enabled and T.Row("Known").enabled)
assert(not H.db.pending and T.reloads==0);T.fail=nil
local value=false
H.Register("Known",{options=function() return {{id="flag",kind="check",get=function() return value end,set=function(v) value=v;T.optionWrites=T.optionWrites+1 end}} end})
-- Loaded and enabled are distinct. Deferred settings are not executed during Apply.
local chosen={addons={AzerothCursor=false,Known=true},settings={Known={flag=true}}}
assert(H.Apply(chosen));assert(not T.Row("AzerothCursor").enabled and T.Row("AzerothCursor").loaded)
assert(H.waitReload and H.db.pending and T.optionWrites==0 and T.reloads==0)
H.ApplyPending();assert(T.optionWrites==0)
-- Simulate next load. Apply only the registered descriptor, never arbitrary tables.
H.waitReload=nil;H.pendingStarted=T.time;H.Scan();H.ApplyPending()
assert(value==true and T.optionWrites==1 and H.db.pending==nil)
local o=H.Options("Known")[1];assert(H.SetOption(o,true));assert(T.optionWrites==1)
local writes=T.writes
assert(H.Apply(H.Snapshot()));assert(not H.db.pending and T.writes==writes and T.optionWrites==1)
assert(not H.SetOption(o,1));assert(not H.Valid({kind="choice",values="bad"},1))
assert(not H.Valid({kind="slider",min="bad",max=20},10))
assert(not H.Plan({addons={},settings="bad"}))
H.db.pending={Known="bad"};H.ApplyPending();assert(not H.db.pending)
-- Save selection, not whatever happens to be enabled in the current running VM.
H.SelectProfile("Solo");H.draft.addons.ASBuilder=false
assert(H.SaveDraft("Ma selection"));assert(H.db.profiles["Ma selection"].addons.ASBuilder==false)
-- Missing integrations expire with an explicit diagnostic, not a future surprise write.
H.db.pending={Unrelated={unknown=true}};H.waitReload=false;T.time=T.time+46;H.ApplyPending();assert(not H.db.pending)
print("PASS: native discovery, read-only plans, dependency closure, cycles/missing deps, rollback, loaded-vs-enabled, delayed settings, validation, saved draft")
