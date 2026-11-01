dofile("tests/mock.lua")
local values={};local items={}
local function option(i)
 values[i]=i
 return {id="option"..i,label="Reglage "..i,kind="slider",section="Affichage",min=0,max=100,step=1,
  get=function() return values[i] end,set=function(v) values[i]=v;T.optionWrites=T.optionWrites+1 end}
end
for i=1,24 do table.insert(items,option(i)) end
FieldKitUI={sections={{id="display",title="Affichage",items=items}}}
for i=1,20 do table.insert(T.addons,{name="Addon"..i,enabled=true,loaded=true,deps={}}) end
T.Load();local H=AzerothHub
H.ToggleUI();local ui=AzerothHubWindow
local function wheel(f,delta) this=f;arg1=delta;assert(f:GetScript("OnMouseWheel"))();this=nil;arg1=nil end
local frameCount=table.getn(T.all)
local profile=H.profile
for _,mode in ipairs({"grimoire","atelier","compact","grimoire","compact","atelier"}) do
 assert(H.SetAppearance(mode));assert(H.db.appearance==mode and ui:GetWidth()==H.appearances[mode].w)
 assert(H.profile==profile and T.optionWrites==0 and T.writes==0 and T.reloads==0)
 assert(table.getn(T.all)==frameCount) -- reflow, no abandoned windows
 assert(ui.profileRail:IsShown()==(mode=="atelier"))
 assert(ui.addons:IsShown()==(mode~="compact"))
 assert(ui.profile:IsShown()==(mode~="atelier"))
 assert(ui.manage:IsShown()==(mode=="compact"))
 assert(not ui.categoryButton:IsShown() and not ui.hint:IsShown() and not ui.saved:IsShown())
 assert(not ui.tabView:IsShown())
 assert(not ui.reload:IsShown())
 assert(not string.find(string.lower(ui.status:GetText() or ""),"molette",1,true))
 assert(not string.find(ui.optionPages:GetText() or "","molette",1,true))
 -- Header hit rectangles must not cover the Appearance or Close buttons.
 assert(ui.header.points[4]+ui.header:GetWidth()<ui.styleButton.points[4])
 assert(ui.header.points[4]+ui.header:GetWidth()<ui.close.points[4])
 for _,row in ipairs(ui.options) do
  for _,control in ipairs({row.toggle,row.choice,row.slider,row.value}) do
   assert(control.points[4]>=0 and control.points[4]+control:GetWidth()<=row:GetWidth()-10)
   assert(-control.points[5]>=0 and -control.points[5]+control:GetHeight()<=row:GetHeight())
  end
 end
 ui.addonOffset=0;ui.optionOffset=0;H.RefreshUI()
 wheel(ui.addonView,-1);assert(ui.addonOffset==1)
 assert(ui.addonBar:GetValue()==1) -- minimum at top; wheel down moves thumb down
 wheel(ui.addonView,-999);assert(ui.addonOffset==table.getn(ui.filteredRows)-ui.addonCount)
 assert(ui.addonBar:GetValue()==ui.addonOffset)
 ui.addonBar:SetValue(0);assert(ui.addonOffset==0)
 wheel(ui.optionView,-1);assert(ui.optionOffset==1)
 assert(ui.optionBar:GetValue()==1)
 wheel(ui.options[1].slider,-999);assert(ui.optionOffset==table.getn(ui.filteredOptions)-ui.optionCount)
 ui.optionPrev:Click();assert(ui.optionOffset<table.getn(ui.filteredOptions)-ui.optionCount)
 assert(ui.optionBar:GetValue()==ui.optionOffset)
 ui.optionBar:SetValue(0);assert(ui.optionOffset==0)
end
H.SetAppearance("compact")
assert(ui.options[1].option.header)
assert(string.find(ui.options[1].section:GetText(),"setting",1,true))
assert(not string.find(ui.options[1].section:GetText() or "","Click",1,true))
local n=table.getn(ui.filteredOptions);ui.options[1]:Click();assert(table.getn(ui.filteredOptions)==1)
ui.options[1]:Click();assert(table.getn(ui.filteredOptions)==n)
ui.manage:Click();assert(ui.addons:IsShown() and not ui.profiles:IsShown())
local picked;for _,row in ipairs(ui.rows) do if row.addon then picked=row;break end end
assert(picked);picked:Click();assert(not ui.addons:IsShown())
ui.profile:Click();assert(ui.profiles:IsShown() and ui.shade:IsShown() and not ui.addons:IsShown())
ui.shade:Click();assert(not ui.profiles:IsShown())
-- Appearance is a client preference, independent of configuration profiles.
assert(H.UseConfigProfile("Solo"));assert(H.db.appearance=="compact")
ui.styleButton:Click();assert(ui.appearance:IsShown() and ui.shade:IsShown());ui.styleChoices.grimoire:Click()
assert(H.db.appearance=="grimoire" and not ui.appearance:IsShown())
local saved=H.Clone(H.db);H.db=nil;AzerothHubDB=saved;H.Init();assert(H.db.appearance=="grimoire")
assert(not H.SetAppearance("invalid") and H.db.appearance=="grimoire")
H.CreateMinimap();H.ToggleLauncher();assert(not ui:IsShown())
H.ToggleUI();assert(ui:IsShown() and not AzerothHubLauncher:IsShown())
assert(T.optionWrites==0 and T.writes==0 and T.reloads==0)
print("PASS: three persisted layouts, wheel and scrollbar boundaries, page arrows, compact folding/picker, stable frame pool, profile independence, mutually exclusive launcher")
