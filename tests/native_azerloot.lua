-- Load the installed addon's real declarative schema, without its rendering code.
dofile("tests/mock.lua")
local file=assert(arg[1],"Azerloot settings path required")
AzerlootDB={tracker=true,bookSize=1,found={sentinel=987},collected={sentinel=654}}
AZL_LANGS={{code="auto",label="Automatic"},{code="fr",label="French"}}
AZL={Faces={{key="classic",label="Classic"}},FaceKey=function() return AzerlootDB.font or "classic" end}
AzlW={COLORS={{key="red",label="Red"}},SOUNDS={{key="raid",label="Raid"}}}
Azerloot_Toggle=function() end
Azerloot_SetBookSize=function(v) AzerlootDB.bookSize=v end
assert(loadfile(file))()
table.insert(T.addons,{name="Azerloot",enabled=true,loaded=true,deps={}})
T.Load();local H=AzerothHub
local options=H.Options("Azerloot");assert(table.getn(options)>=15)
for _,o in ipairs(options) do assert(o.kind~="action") end
local function find(id)
 for _,o in ipairs(options) do if o.id==id then return o end end
 error("Missing native option "..id)
end
H.EnsureConfigProfiles();assert(H.UseConfigProfile("Solo"))
assert(H.SetOption(find("book/Book/bookSize"),1.2))
assert(H.SetOption(find("wish/Window/tracker"),false))
assert(H.UseConfigProfile("Coop"));assert(AzerlootDB.bookSize==1 and AzerlootDB.tracker)
assert(H.UseConfigProfile("Solo"));assert(AzerlootDB.bookSize==1.2 and not AzerlootDB.tracker)
assert(AzerlootDB.found.sentinel==987 and AzerlootDB.collected.sentinel==654)
assert(T.writes==0 and T.reloads==0)
-- Reuse the native hierarchy, preserving source order and stable profile IDs.
H.ToggleUI();local ui=AzerothHubWindow;H.selected="Azerloot";H.RefreshUI()
assert(table.getn(ui.pageList)==3 and ui.page=="book")
assert(ui.tabs[1].caption:GetText()=="Book" and ui.tabs[2].caption:GetText()=="Wishlist")
assert(ui.options[1].option.header and ui.options[1].option.section=="Reading")
local count=table.getn(T.all)
for _,mode in ipairs({"grimoire","atelier","compact"}) do
 H.SetAppearance(mode)
 for i,key in ipairs({"book","wish","warn"}) do
  ui.tabs[i]:Click();assert(ui.page==key and ui.optionOffset==0)
  for _,o in ipairs(ui.filteredOptions) do assert(o.header or o.page==key) end
  for _,b in ipairs(ui.tabs) do assert(b.points[4]>=0 and b.points[4]+b:GetWidth()<=ui.tabView:GetWidth()) end
 end
 ui.tabs[1]:Click();local before=table.getn(ui.filteredOptions)
 ui.options[1]:Click();assert(table.getn(ui.filteredOptions)<before)
 ui.optionSearch:SetText("Hero")
 assert(table.getn(ui.filteredOptions)==1 and ui.filteredOptions[1].id=="warn/Sounds/soundDown")
 assert(ui.page=="book") -- global search does not change the selected tab
 ui.optionSearch:SetText("");ui.options[1]:Click();assert(table.getn(ui.filteredOptions)==before)
 assert(table.getn(T.all)==count)
end
local nativeOpened=false;H.adapters.Azerloot.configure=function() nativeOpened=true end
ui.original:Click();assert(nativeOpened and not ui:IsShown() and ui.returnBar:IsShown())
AzerlootDB.bookSize=1.1;ui.returnButton:Click()
assert(ui:IsShown() and H.db.profiles[H.profile].settings.Azerloot["book/Book/bookSize"]==1.1)
assert(T.writes==0 and T.reloads==0)
print("PASS: "..table.getn(options).." real installed Azerloot descriptors, native setters, profile round trip, collections preserved")
