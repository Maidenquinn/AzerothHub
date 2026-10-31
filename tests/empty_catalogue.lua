dofile("tests/mock.lua")
GetNumAddOns=function() return 0 end
GetAddOnInfo=function() error("No server-backed catalogue") end
IsAddOnLoaded=function() return nil end
local opened=0
SlashCmdList.FieldKit=function() opened=opened+1 end
FieldKitUI={sections={}}
-- A genuine on-disk inventory, independent of the native catalogue.
dofile("Inventory.lua")
AzerothHubDB={gather=true} -- grouping resumes with the new launcher construction guard
T.Load();local H=AzerothHub
assert(H.nativeCount==0 and table.getn(H.rows)==table.getn(AzerothHubInventory))
assert(table.getn(H.rows)>5 and H.byName.AzerothFieldKit.loaded)
assert(H.db.gather and not H.byName.AzerothFieldKit.activationKnown)
H.ToggleUI();local ui=AzerothHubWindow
assert(string.find(string.lower(ui.count:GetText()),"addons",1,true))
assert(ui.rows[1]:IsShown() and ui.rows[1].title:GetText()~="")
assert(T.writes==0)
local button=CreateFrame("Button","AzerothStatsMinimap",Minimap)
button:SetScript("OnClick",function() opened=opened+10 end)
H.GatherButtons();assert(button:GetAlpha()==1 and button:IsMouseEnabled())
H.CreateMinimap();arg1=.2;AzerothHubDriver:GetScript("OnUpdate")()
assert(not AzerothHubLauncher:IsShown() and button:GetAlpha()==0)
H.ToggleLauncher()
assert(AzerothHubLauncher.rows[1].addon=="AzerothFieldKit")
AzerothHubLauncher.rows[1]:Click();assert(opened==1)
-- Grouping also remains available after closing and opening the launcher.
H.db.gather=true;H.ToggleLauncher()
assert(button:GetAlpha()==0 and H.launcherEntries.AzerothStats)
local found
for _,row in ipairs(AzerothHubLauncher.rows) do
 if row:IsShown() and row.addon=="AzerothStats" then found=row end
end
assert(found);found:Click();assert(opened==11)
H.ReleaseButtons();assert(button:GetAlpha()==1 and button:IsMouseEnabled())
-- Unknown activation states cannot trigger speculative native writes.
local p=H.Snapshot();p.addons.AzerothFieldKit=false
local plan,err=H.Plan(p);assert(not plan and string.find(err,"Options > AddOns",1,true))
assert(T.writes==0 and T.optionWrites==0 and T.reloads==0)
print("PASS: zero native catalogue, real inventory, automatic quiet launcher, visible list, working shortcuts, gated hiding, guarded activation")
