dofile("tests/mock.lua")
dofile("Inventory.lua")
T.Load()
local H=AzerothHub
assert(H.version=="0.7.5")
assert(H.adapters.BigCursor and H.adapters.AetherHUD and H.adapters.VulchansCombatText)
assert(H.adapters.BlackwellUI and H.adapters.KeijinUI and H.adapters.MoveAnything)
-- Inventory lists community addons even when not loaded.
assert(H.byName.AetherHUD and H.byName.BigCursor and H.byName.LuckyOdds)
assert(not H.byName.AetherHUD.loaded)
-- Later install: mark loaded via IsAddOnLoaded, scan refreshes row.
local previous=IsAddOnLoaded
IsAddOnLoaded=function(name)
 if name=="AetherHUD" or name=="BigCursor" then return 1 end
 return previous(name)
end
SlashCmdList.AETHERHUD=function() end
SlashCmdList.BIGCURSOR=function(msg) T.bigCursorMsg=msg end
AetherHUD={db={scale=1,modules={chrono=true,hero=false}},MODULES={{key="chrono",label="Run clock"},{key="hero",label="Hero frame"}},PlaceAll=function() T.aetherPlaced=true end}
BigCursorDB={enabled=true,size=46}
H.Scan()
assert(H.byName.AetherHUD.loaded and H.CanOpen("AetherHUD"))
assert(H.byName.BigCursor.loaded and H.CanOpen("BigCursor"))
local opts=H.Options("AetherHUD")
assert(table.getn(opts)>=3)
local scale;for _,o in ipairs(opts) do if o.id=="scale" then scale=o end end
assert(scale and H.SetOption(scale,1.1) and AetherHUD.db.scale==1.1 and T.aetherPlaced)
local big=H.Options("BigCursor")
local size;for _,o in ipairs(big) do if o.id=="size" then size=o end end
assert(size and H.SetOption(size,64) and BigCursorDB.size==64)
-- Published catalog still wins for brand-new addons.
AzerothHubCatalog={FreshPack={available=function() return true end,open=function() T.fresh=true end,
 options=function() return {{id="on",label="On",kind="check",get=function() return true end,set=function() end}} end}}
H.Scan()
assert(H.byName.FreshPack and H.CanOpen("FreshPack") and table.getn(H.Options("FreshPack"))==1)
print("PASS: known inventory, late install detection, catalog")
