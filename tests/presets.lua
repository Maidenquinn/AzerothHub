dofile("tests/mock.lua")
local flag=true
local function o(label,id)
 return {id=id,label=label,kind="check",get=function() return flag end,set=function() T.optionWrites=T.optionWrites+1 end}
end
FieldKitUI={sections={{id="windows",title="Windows",items={},windowTabs={
 {id="display",title="Display",items={o("Group damage meter"),o("Stats","statsFrame")}},
 {id="coop",title="Coop",items={o("Co-op teammate cards")}},
}}}}
T.Load();local H=AzerothHub
assert(H.db.profiles.Solo.settings.AzerothFieldKit["windows/display/Group damage meter"]==false)
assert(H.db.profiles.Coop.settings.AzerothFieldKit["windows/display/Group damage meter"]==true)
assert(H.db.profiles.Leger.settings.AzerothFieldKit["windows/display/statsFrame"]==false)
assert(T.optionWrites==0 and T.writes==0)
T.Row("Known").deps={"library"}
local plan=assert(H.Plan({addons={Known=true,Library=false},settings={}}));assert(plan.target.Library)
local original=DisableAddOn;DisableAddOn=nil
local ok=H.Apply({addons={Known=false},settings={}});assert(not ok and T.writes==0)
DisableAddOn=original
H.db.pending=nil
H.db=nil;AzerothHubDB={profiles={Personnalise={addons={AzerothHub=true},settings={}}}}
H.Init();assert(H.profile=="Personnalise")
H.ToggleUI();assert(AzerothHubWindow:IsShown() and H.draft)
print("PASS: meaningful default profiles, no implicit writes, case-insensitive dependencies, missing mutation API, restored custom-only profiles")
