-- Community addons from the Desktop catalog. Open/settings only use public slash
-- commands and SavedVariables already exposed by those addons — their sources are
-- never modified. Authors who want richer Hub controls should publish AzerothHubCatalog
-- (see docs/INTEGRATION.md).
local H=AzerothHub
local function command(key,message)
 return function()
  local fn=SlashCmdList and SlashCmdList[key]
  if type(fn)~="function" then error("Addon not loaded or command unavailable") end
  fn(message or "")
 end
end
local function registered(key)
 return function() return type(SlashCmdList)=="table" and type(SlashCmdList[key])=="function" end
end
local function bind(name,key,message,options)
 local a={open=command(key,message),available=registered(key)}
 if type(options)=="function" then a.options=options end
 if not H.adapters[name] then H.Register(name,a)
 else
  local cur=H.adapters[name]
  if type(cur.open)~="function" then cur.open=a.open end
  if type(cur.available)~="function" then cur.available=a.available end
  if type(cur.options)~="function" and a.options then cur.options=a.options end
 end
end

-- Full UI suites: open their native options; detailed Hub schemas stay optional via catalog.
-- Blackwell registers BLACKWELLUI and sometimes BLACKWALLUI.
do
 local function blackwellReady()
  return type(SlashCmdList)=="table" and (type(SlashCmdList.BLACKWELLUI)=="function" or type(SlashCmdList.BLACKWALLUI)=="function")
 end
 local function blackwellOpen()
  if type(SlashCmdList.BLACKWELLUI)=="function" then SlashCmdList.BLACKWELLUI("")
  elseif type(SlashCmdList.BLACKWALLUI)=="function" then SlashCmdList.BLACKWALLUI("")
  else error("Addon not loaded or command unavailable") end
 end
 H.Register("BlackwellUI",{available=blackwellReady,open=blackwellOpen,configure=blackwellOpen})
end
bind("BordoUI","BORDOU")
-- Also accept BORDOUI if present.
if H.adapters.BordoUI then
 local prev=H.adapters.BordoUI.available
 H.adapters.BordoUI.available=function()
  if type(SlashCmdList)=="table" and type(SlashCmdList.BORDOUI)=="function" then return true end
  return prev and prev() or false
 end
end
bind("KeijinUI","KEIJINUI")
bind("SurvivorsDragonUi","SURVIVORSDRAGONUILAYOUT")
bind("SurvivorUIClassic","SURVIVORUICLASSIC")
bind("MoveAnything","MOVEANYTHING")
bind("MoveUI","MOVEANYTHING")
bind("ASTinyPlates","ASTINYPLATESDEBUG")
bind("LuckyOdds","LUCKYODDS")
bind("AzerothPilotBridge","AZEROTHPILOTBRIDGE")
bind("AZS_DeathRecap","DEATHRECAP")

-- BigCursor: size + enable from its public DB.
bind("BigCursor","BIGCURSOR",nil,function()
 if type(BigCursorDB)~="table" then return {} end
 local function apply() end
 return {
  {id="enabled",label="Enlarged cursor",kind="check",section="Display",tip="Enables the resized cursor during the run.",
   get=function() return BigCursorDB.enabled~=false end,
   set=function(v) BigCursorDB.enabled=v and true or false;if SlashCmdList.BIGCURSOR then SlashCmdList.BIGCURSOR(v and "on" or "off") end end},
  {id="size",label="Size",kind="slider",min=24,max=512,step=2,section="Display",unit="px",tip="Cursor size in pixels.",
   get=function() return tonumber(BigCursorDB.size) or 46 end,
   set=function(v) BigCursorDB.size=v;if SlashCmdList.BIGCURSOR then SlashCmdList.BIGCURSOR("size "..tostring(v)) end end},
 }
end)

-- LocalClock: public DB fields.
bind("LocalClock","LOCALCLOCK",nil,function()
 if type(LocalClockDB)~="table" then return {} end
 local d=LocalClockDB
 local modes={"clock","stopwatch","alarm"}
 local modeLabels={"Clock","Stopwatch","Alarm"}
 return {
  {id="shown",label="Show the clock",kind="check",section="Display",
   get=function() return d.shown~=false end,
   set=function(v)
    d.shown=v and true or false
    if SlashCmdList.LOCALCLOCK then SlashCmdList.LOCALCLOCK(v and "show" or "hide") end
   end},
  {id="locked",label="Lock position",kind="check",section="Display",
   get=function() return d.locked and true or false end,
   set=function(v)
    d.locked=v and true or false
    if SlashCmdList.LOCALCLOCK then SlashCmdList.LOCALCLOCK(v and "lock" or "unlock") end
   end},
  {id="use12Hour",label="12-hour format",kind="check",section="Display",
   get=function() return d.use12Hour and true or false end,
   set=function(v)
    d.use12Hour=v and true or false
    if SlashCmdList.LOCALCLOCK then SlashCmdList.LOCALCLOCK(v and "12" or "24") end
   end},
  {id="displayMode",label="Mode",kind="choice",section="Display",values=modeLabels,
   get=function()
    local m=d.displayMode or "clock"
    for i,k in ipairs(modes) do if m==k then return i end end
    return 1
   end,
   set=function(i)
    d.displayMode=modes[i]
    if SlashCmdList.LOCALCLOCK then SlashCmdList.LOCALCLOCK(modes[i]) end
   end},
 }
end)
-- Prefer DB presence so Hub marks the addon loaded even if IsAddOnLoaded is mute.
if H.adapters.LocalClock then
 H.adapters.LocalClock.available=function()
  return type(LocalClockDB)=="table" or (type(SlashCmdList)=="table" and type(SlashCmdList.LOCALCLOCK)=="function")
 end
end

-- AZS Max Hit: public DB + slash.
bind("AZSMaxHit","AZSMAXHIT",nil,function()
 if type(AZSMaxHitDB)~="table" then return {} end
 local d=AZSMaxHitDB
 local views={"me","party"}
 local viewLabels={"Personal","Group"}
 return {
  {id="shown",label="Show Max Hit",kind="check",section="Display",
   get=function() return d.shown~=false end,
   set=function(v) if (d.shown~=false)~=v and SlashCmdList.AZSMAXHIT then SlashCmdList.AZSMAXHIT(v and "show" or "hide") end end},
  {id="locked",label="Lock the window",kind="check",section="Display",
   get=function() return d.locked and true or false end,
   set=function(v) if (d.locked and true or false)~=v and SlashCmdList.AZSMAXHIT then SlashCmdList.AZSMAXHIT("lock") end end},
  {id="showIcons",label="Spell icons",kind="check",section="Display",
   get=function() return d.showIcons~=false end,
   set=function(v) d.showIcons=v and true or false;if SlashCmdList.AZSMAXHIT then SlashCmdList.AZSMAXHIT("refresh") end end},
  {id="showAt",label="Timestamp",kind="check",section="Display",
   get=function() return d.showAt and true or false end,
   set=function(v) d.showAt=v and true or false;if SlashCmdList.AZSMAXHIT then SlashCmdList.AZSMAXHIT("refresh") end end},
  {id="view",label="View",kind="choice",section="Display",values=viewLabels,
   get=function()
    local v=d.view or "me"
    for i,k in ipairs(views) do if v==k then return i end end
    return 1
   end,
   set=function(i)
    d.view=views[i]
    if SlashCmdList.AZSMAXHIT then SlashCmdList.AZSMAXHIT(views[i]) end
   end},
 }
end)
if H.adapters.AZSMaxHit then
 H.adapters.AZSMaxHit.available=function()
  return type(AZSMaxHitDB)=="table" or (type(SlashCmdList)=="table" and type(SlashCmdList.AZSMAXHIT)=="function")
 end
end

-- Vulchan's Combat Text.
bind("VulchansCombatText","VCT",nil,function()
 if type(VCTDB)~="table" then return {} end
 local d=VCTDB
 return {
  {id="enabled",label="Custom numbers",kind="check",section="Display",
   get=function() return d.enabled~=false end,
   set=function(v) if SlashCmdList.VCT then SlashCmdList.VCT(v and "on" or "off") else d.enabled=v and true or false end end},
  {id="showIcons",label="Spell icons",kind="check",section="Display",
   get=function() return d.showIcons~=false end,
   set=function(v) if SlashCmdList.VCT then SlashCmdList.VCT(v and "icons on" or "icons off") else d.showIcons=v and true or false end end},
  {id="scale",label="Scale",kind="slider",min=50,max=200,step=5,section="Display",unit="%",
   get=function() return tonumber(d.scale) or 100 end,
   set=function(v) if SlashCmdList.VCT then SlashCmdList.VCT("scale "..tostring(v)) else d.scale=v end end},
  {id="layout",label="Layout",kind="choice",section="Display",values={"Vertical","Horizontal"},
   get=function() return (d.layout=="horizontal") and 2 or 1 end,
   set=function(i) if SlashCmdList.VCT then SlashCmdList.VCT(i==2 and "horizontal" or "vertical") else d.layout=(i==2 and "horizontal" or "vertical") end end},
 }
end)

-- AetherHUD: modules + scale from public AetherHUD / AetherHUDDB.
H.Register("AetherHUD",{
 available=registered("AETHERHUD"),
 open=command("AETHERHUD"),
 configure=command("AETHERHUD"),
 options=function()
  local A=getglobal("AetherHUD")
  if type(A)~="table" or type(A.db)~="table" then return {} end
  local out={
   {id="scale",label="Global scale",kind="slider",min=.5,max=2,step=.05,section="Display",unit="%",displayScale=100,
    tip="Overall HUD size.",
    get=function() return tonumber(A.db.scale) or 1 end,
    set=function(v) A.db.scale=v;if A.PlaceAll then A.PlaceAll() elseif SlashCmdList.AETHERHUD then SlashCmdList.AETHERHUD("scale "..tostring(v)) end end},
  }
  if type(A.MODULES)=="table" then
   for _,m in ipairs(A.MODULES) do
    if type(m)=="table" and type(m.key)=="string" then
     local key=m.key
     table.insert(out,{id="mod_"..key,label=m.label or key,kind="check",section="Modules",reload=true,
      tip="Reload required after a module change.",
      get=function() return A.db.modules and A.db.modules[key] and true or false end,
      set=function(v) if type(A.db.modules)~="table" then A.db.modules={} end;A.db.modules[key]=v and true or false end})
    end
   end
  end
  return out
 end
})

-- Azeroth Cursor full schema lives in Adapters.lua (1.2: class icon, couleur, langue, aleatoire).
