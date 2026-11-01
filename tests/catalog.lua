dofile("tests/mock.lua")
T.Load();local H=AzerothHub
local kept=H.adapters.AzerothFieldKit.options
local gauge=true
local published={{id="wide",label="Large",kind="check",section="Affichage",get=function() return true end,set=function() end}}
AzerothHubCatalog={
 AzerothFieldKit={options=function() return {{id="nope",kind="check",get=function() return true end,set=function() end}} end},
 FutureGauge={
  available=function() return true end,
  open=function() T.opened=true end,
  options=function() return {{id="alpha",label="Alpha",kind="check",section="Affichage",tip="Oui",get=function() return gauge end,set=function(v) gauge=v end}} end,
 },
 ["mauvais nom"]={options=function() return {{id="x",kind="check",get=function() return true end,set=function() end}} end},
 {name="PlainMeter",available=function() return true end,options=published},
}
H.Scan()
assert(H.adapters.AzerothFieldKit.options==kept)
assert(not H.adapters["mauvais nom"])
assert(H.byName.FutureGauge and H.byName.FutureGauge.loaded)
local opts=H.Options("FutureGauge")
assert(table.getn(opts)==1 and opts[1].label=="Alpha")
assert(H.SetOption(opts[1],false) and gauge==false)
assert(H.Open("FutureGauge") and T.opened)
local plain=H.Options("PlainMeter")
assert(H.byName.PlainMeter and table.getn(plain)==1 and plain[1].id=="wide")
H.ToggleUI();local ui=AzerothHubWindow
ui.search:SetText("Future");H.RefreshUI()
local found=false
for _,r in ipairs(ui.filteredRows) do if r.name=="FutureGauge" then found=true end end
assert(found)
AzerothHubInventory={{name="FreshAddon",title="Fresh Addon",notes="",version="1"}}
local previousLoaded=IsAddOnLoaded
IsAddOnLoaded=function(name) if name=="FreshAddon" then return 1 end return previousLoaded(name) end
H.Scan()
assert(H.byName.FreshAddon and H.byName.FreshAddon.loaded)
local history=CreateFrame("Button","FreshAddonHistoryButton",Minimap)
local primary=CreateFrame("Button","FreshAddonMinimapButton",Minimap)
local hit
history:SetScript("OnClick",function() hit="history" end)
primary:SetScript("OnClick",function() hit="options" end)
H.db.gather=true;H.GatherButtons();assert(H.LaunchAddon("FreshAddon") and hit=="options")
local previousLoaded=IsAddOnLoaded
IsAddOnLoaded=function(name)
 if name=="LiveAddon" then return 1 end
 return previousLoaded(name)
end
CreateFrame("Button","LiveAddonMinimapButton",Minimap)
H.Scan();assert(H.byName.LiveAddon and H.byName.LiveAddon.loaded)
SurvivorUIDB={tracker=true,meter=false}
SurvivorUI_ToggleOptions=function() end
SurvivorUI_ToggleTracker=function() SurvivorUIDB.tracker=not SurvivorUIDB.tracker end
SurvivorUI_ToggleMeter=function() SurvivorUIDB.meter=not (SurvivorUIDB.meter~=false);if SurvivorUIDB.meter then SurvivorUIDB.meter=nil end end
H.Scan()
local sui=H.Options("SurvivorUI");assert(table.getn(sui)>5)
local tracker;for _,o in ipairs(sui) do if o.id=="tracker" then tracker=o end end
assert(tracker and tracker.get()==true);assert(H.SetOption(tracker,false) and SurvivorUIDB.tracker==false)
print("PASS: published catalog, explicit adapter preserved, unknown addon listed with settings")
