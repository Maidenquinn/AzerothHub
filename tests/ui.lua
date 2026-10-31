dofile("tests/mock.lua")
local flag=false;local number=5;local choice=1
FieldKitUI={sections={{id="test",title="Test",items={
 {id="flag",kind="check",label="Flag",get=function() return flag end,set=function(v) flag=v;T.optionWrites=T.optionWrites+1 end},
 {id="size",kind="slider",label="Size",min=1,max=10,step=1,get=function() return number end,set=function(v) number=v;T.optionWrites=T.optionWrites+1 end},
 {id="choice",kind="choice",label="Choice",values={"A","B"},get=function() return choice end,set=function(v) choice=v;T.optionWrites=T.optionWrites+1 end},
},windowTabs={{id="nested",title="Nested",items={{id="other",kind="check",label="Other",get=function() return false end,set=function() end}}}}}}}
T.Load();local H=AzerothHub
assert(table.getn(H.Options("AzerothFieldKit"))==4)
H.ToggleUI();local ui=AzerothHubWindow
assert(ui:IsShown() and H.selected=="AzerothFieldKit")
assert(ui.nameEdit.HasFocus==nil)
ui.nameEdit:SetText("Mon profil perso")
for i=1,10 do H.RefreshUI() end
assert(ui.nameEdit:GetText()=="Mon profil perso")
H.SelectProfile("Coop");H.RefreshUI();assert(ui.nameEdit:GetText()=="")
assert(T.optionWrites==0 and T.writes==0 and T.reloads==0)
ui.optionSearch:SetText("Flag");ui.options[1].toggle:Click();assert(flag==true and T.optionWrites==1)
ui.optionSearch:SetText("Size");ui.options[1].slider:SetValue(7);assert(number==7 and T.optionWrites==2)
ui.optionSearch:SetText("Choice");ui.options[1].choice:Click();assert(choice==2 and T.optionWrites==3)
-- Navigation and configuration never write addon activation flags.
assert(T.writes==0)
ui.apply:Click();assert(not H.preview and T.writes==0)
assert(ui.options[1]:IsShown())
ui.optionSearch:SetText("Size");assert(ui.options[1].option.id=="test/size" and not ui.options[2]:IsShown())
ui.optionSearch:SetText("")
ui.profile:Click();assert(AzerothHubProfileMenu:IsShown())
for _,row in ipairs(AzerothHubProfileMenu.rows) do if row.profile=="Solo" then row:Click() end end
assert(H.profile=="Solo" and H.db.activeProfile=="Solo" and not AzerothHubProfileMenu:IsShown())
-- The launcher's native frames are pooled across repeated open/close cycles.
H.CreateMinimap();H.ToggleLauncher();H.ToggleLauncher()
local count=table.getn(T.all)
for i=1,20 do H.ToggleLauncher();H.ToggleLauncher() end
assert(table.getn(T.all)==count)
print("PASS: shared schema, read-only rendering, user setting callbacks, profile menu, settings search, pooled launcher")
