dofile("tests/mock.lua")
ASBuilderDB={tracker={scale=1,mode="run"},light=80,builds={keep="MY BUILD"},run={kills=42}}
ASBuilder={ApplyTrackerLayout=function() end,RefreshTracker=function() end}
SlashCmdList.ASBUILDER=function() end
local flag=false
FieldKitUI={}
SlashCmdList.FieldKit=function()
 FieldKitUI.sections={{id="test",title="Test",items={{id="flag",label="Flag",kind="check",
 get=function() return flag end,set=function(v) flag=v end}}}}
 FieldKitUI.frame=CreateFrame("Frame",nil,UIParent)
end
T.Load();local H=AzerothHub
H.EnsureConfigProfiles()
assert(FieldKitUI.sections and not FieldKitUI.frame:IsShown())
assert(table.getn(H.Options("ASBuilder"))==5)
local function find(name,id)
 for _,o in ipairs(H.Options(name)) do if o.id==id then return o end end
 error("Missing option "..id)
end
assert(H.UseConfigProfile("Solo"))
assert(H.SetOption(find("ASBuilder","scale"),.7))
assert(H.db.profiles.Solo.settings.ASBuilder.scale==.7)
assert(H.SetOption(find("AzerothFieldKit","test/flag"),true))
assert(H.UseConfigProfile("Coop"));assert(ASBuilderDB.tracker.scale==1 and flag==false)
assert(H.SetOption(find("ASBuilder","scale"),1.5))
-- Also capture settings changed in the addon's original editor when leaving a profile.
ASBuilderDB.tracker.locked=true
assert(H.UseConfigProfile("Solo"));assert(ASBuilderDB.tracker.scale==.7 and flag==true and not ASBuilderDB.tracker.locked)
assert(H.UseConfigProfile("Coop"));assert(ASBuilderDB.tracker.scale==1.5 and ASBuilderDB.tracker.locked)
assert(ASBuilderDB.builds.keep=="MY BUILD" and ASBuilderDB.run.kills==42)
assert(H.SaveProfile("Raid"));H.SelectProfile("Raid")
assert(H.db.profiles.Raid.settings.ASBuilder.scale==1.5)
-- On failure keep the current profile and restore every attempted change, including a partial setter.
local a,b=1,1
table.insert(T.addons,{name="Failure",enabled=true,loaded=true,deps={}})
H.Register("Failure",{options=function() return {
 {id="a",kind="slider",min=0,max=10,get=function() return a end,set=function(v) a=v end},
 {id="b",kind="slider",min=0,max=10,get=function() return b end,set=function(v) b=v;if v==2 then error("partial failure") end end},
} end})
H.Scan();H.db.profiles.Broken={addons={},settings={Failure={a=2,b=2}}}
local before=H.profile;local ok=H.UseConfigProfile("Broken")
assert(not ok and H.profile==before and a==1 and b==1)
assert(T.writes==0 and T.reloads==0)
print("PASS: lazy native schema, automatic save, Solo/Coop round trip, external editor capture, independent profiles, partial failure rollback, progression preserved")
