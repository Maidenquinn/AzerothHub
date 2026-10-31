local H=AzerothHub
local function command(key,message)
 return function()
  local fn=SlashCmdList and SlashCmdList[key]
  if type(fn)~="function" then error("Addon non charge ou commande indisponible") end
  fn(message or "")
 end
end
H.Register("Azerloot",{open=command("AZERLOOT"),options=function() return {} end})
-- Azerloot exposes a public book toggle even where its slash key changes.
H.adapters.Azerloot.open=function()
 if type(Azerloot_Toggle)=="function" then Azerloot_Toggle() else error("Azerloot non charge") end
end
H.Register("ASBuilder",{open=command("ASBUILDER")})
H.Register("AZSSpellMeter",{open=command("AZSSPELLMETER")})
H.Register("AzerothChallenges",{open=command("AZEROTHCHALLENGES")})
H.Register("AzerothCollector",{open=command("AZEROTHCOLLECTOR")})
H.Register("AzerothDeathRecap",{open=command("AZEROTHDEATHRECAP","settings")})
H.Register("AzerothMover",{open=command("AZEROTHMOVER")})
H.Register("AzerothClarity",{open=command("AZCLARITY"),options=function()
 local a=getglobal("AzerothClarity");if type(a)~="table" then return {} end
 local function check(id,label,get,on,off)
  return {id=id,label=label,kind="check",profile=false,get=get,set=function(v) if v then on() else off() end end}
 end
 return {
  check("chests","Suivi des coffres",function() return a.chestsEnabled==true end,a.ChestsOn,a.ChestsOff),
  check("allies","Secours coop",function() return a.alliesEnabled==true end,a.AlliesOn,a.AlliesOff),
  check("clear","Ecran degage",function() return a.active==true end,function() if not a.active then a.Toggle() end end,function() if a.active then a.Hold(false);a.toggled=false;a.Refresh() end end),
 }
end})
H.Register("AzerothFieldKit",{open=command("FieldKit"),options=function()
 local u=getglobal("FieldKitUI")
 if type(u)~="table" or type(u.sections)~="table" then return {} end
 local out={}
 local function add(items,path,title)
  for _,item in ipairs(items or {}) do
   if (item.kind=="check" or item.kind=="slider" or item.kind=="choice") and type(item.get)=="function" and type(item.set)=="function" then
    local o={}
    for k,v in pairs(item) do o[k]=v end
    o.id=path.."/"..(item.id or item.label or "")
    o.reload=item.id=="compactBar"
    o.section=title
    o.page=path; o.pageLabel=title
    if type(item.tip)=="string" then o.tip=item.tip end
    local translate=getglobal("FieldKit_L")
    if type(translate)=="function" then
     local ok,s=H.Call(translate,item.label or "")
     if ok and type(s)=="string" and s~="" then o.label=s end
     if type(item.tip)=="string" then local valid,tip=H.Call(translate,item.tip);if valid and type(tip)=="string" and tip~="" then o.tip=tip end end
    end
    table.insert(out,o)
   end
  end
 end
 for _,s in ipairs(u.sections) do
  local path=s.id or s.title or "section"
  add(s.items,path,s.title)
  for _,tab in ipairs(s.windowTabs or {}) do
   local first=table.getn(out)+1
   add(tab.items,path.."/"..(tab.id or tab.title),tab.title)
   for i=first,table.getn(out) do out[i].page=path;out[i].pageLabel=s.title end
  end
 end
 return out
end})
local function stat(key,label,kind,low,high,step,tip)
 return {id=key,label=label,kind=kind,min=low,max=high,step=step,tip=tip,
  section=key=="recordSound" and "Sons" or "Affichage",
  unit=(key=="scale" or key=="opacity") and "%" or nil,displayScale=(key=="scale" or key=="opacity") and 100 or nil,
  get=function() return AzerothStats.db.settings[key] end,
  set=function(v) AzerothStats.db.settings[key]=v;AzerothStats.ApplyUI() end}
end
H.Register("AzerothStats",{open=command("AZEROTHSTATS"),options=function()
 local a=getglobal("AzerothStats");if type(a)~="table" or not a.db or not a.db.settings then return {} end
 return {stat("bar","Barre de statistiques","check",nil,nil,nil,"Affiche la barre pendant la partie."),
  stat("locked","Verrouiller les positions","check",nil,nil,nil,"Empeche de deplacer la barre."),
  stat("recordSound","Sons des records","check",nil,nil,nil,"Joue un son a chaque record."),
  stat("scale","Echelle","slider",.65,1.5,.05,"100 % correspond a la taille d'origine."),
  stat("opacity","Opacite","slider",.45,1,.05,"100 % est entierement opaque.")}
end})
local function cursor(key,label,kind,low,high)
 local hints={enabled="Affiche le repere autour de la souris en jeu. L'apercu reste visible meme si ce bouton est desactive.",
  pulse="Fait varier doucement l'intensite du halo.",thickness="Epaisseur du cercle autour du curseur.",size="Diametre du cercle, en pixels.",
  opacity="Visibilite du cercle, du reticule et du point central.",halo="Intensite du halo lumineux autour du cercle.",
  crosshair="Longueur du reticule. Zero masque le reticule.",dot="Rayon du point central. Zero masque le point."}
 return {id=key,label=label,kind=kind,min=low,max=high,step=1,
  section=key=="enabled" and "Visibilite" or key=="pulse" and "Animation" or "Apparence",
  unit=(key=="opacity" or key=="halo") and "%" or kind=="slider" and "px" or nil,tip=hints[key],
  get=function() return AzerothCursor.db[key] end,
  set=function(v) AzerothCursor.db[key]=v;AzerothCursor.Apply() end}
end
H.Register("AzerothCursor",{open=command("AZEROTHCURSOR"),options=function()
 local a=getglobal("AzerothCursor");if type(a)~="table" or not a.db then return {} end
 return {cursor("enabled","Repere actif","check"),cursor("pulse","Halo anime","check"),cursor("thickness","Epaisseur","slider",1,3),
  cursor("size","Diametre","slider",24,160),cursor("opacity","Opacite","slider",20,100),
  cursor("halo","Intensite du halo","slider",0,100),cursor("crosshair","Reticule","slider",0,100),cursor("dot","Point central","slider",0,24)}
end})
-- Observe registered entry points; never execute them to detect an addon.
local commands={ASBuilder="ASBUILDER",AZSSpellMeter="AZSSPELLMETER",AzerothChallenges="AZEROTHCHALLENGES",
 AzerothCollector="AZEROTHCOLLECTOR",AzerothDeathRecap="AZEROTHDEATHRECAP",AzerothMover="AZEROTHMOVER",
 AzerothClarity="AZCLARITY",AzerothFieldKit="FieldKit",AzerothStats="AZEROTHSTATS",AzerothCursor="AZEROTHCURSOR"}
local function registered(key)
 return function() return type(SlashCmdList)=="table" and type(SlashCmdList[key])=="function" end
end
for name,key in pairs(commands) do H.adapters[name].available=registered(key) end
H.adapters.Azerloot.available=function() return type(Azerloot_Toggle)=="function" end
H.adapters.Azerloot.configure=command("AZERLOOT","settings")
H.adapters.AZSSpellMeter.configure=command("AZSSPELLMETER","settings")

-- Import Azerloot's published settings descriptors, using the original setters.
local function lootOption(d,section)
 local o={id=section.."/"..d.key,label=d.label,section=section,get=d.get,set=d.set,
  min=d.min,max=d.max,step=d.step,reload=d.reload~=nil,tip=d.desc,
  unit=d.kind=="range" and "%" or nil,displayScale=d.kind=="range" and 100 or nil}
 if d.kind=="toggle" then o.kind="check"
 elseif d.kind=="range" then o.kind="slider"
 elseif d.kind=="choice" then
  local ok,choices=H.Call(d.options);if not ok or type(choices)~="table" or table.getn(choices)==0 then return nil end
  o.kind="choice";o.values={}
  for i,v in ipairs(choices) do o.values[i]=v.label end
  o.get=function()
   local value=d.get();for i,v in ipairs(choices) do if value==v.value then return i end end
  end
  o.set=function(i) d.set(choices[i].value) end
 else return nil end
 -- This native switch deletes learned spell data when turned off: keep it a session action.
 if d.key=="spellTracker" then o.profile=false end
 return o
end
H.adapters.Azerloot.options=function()
 if type(AzlSettings)~="table" or type(AzlSettings.TABS)~="table" then return {} end
 local out={}
 for _,tab in ipairs(AzlSettings.TABS) do for _,s in ipairs(tab.sections or {}) do for _,d in ipairs(s.rows or {}) do
  if type(d.get)=="function" and type(d.set)=="function" then
   local o=lootOption(d,tab.key.."/"..s.label)
   if o then o.page=tab.key;o.pageLabel=tab.label;o.section=s.label;table.insert(out,o) end
  end
 end end end
 return out
end
H.adapters.AzerothFieldKit.prepare=function()
 if FieldKitUI and not FieldKitUI.sections and H.CanOpen("AzerothFieldKit") then
  SlashCmdList.FieldKit("")
  if FieldKitUI.frame then FieldKitUI.frame:Hide() end
 end
end

local function field(db,path,label,kind,default,low,high,step,apply,values)
 return {id=path,label=label,kind=kind,min=low,max=high,step=step,values=values,
  get=function() local v=db[path];if v==nil then return default end;return v end,
  set=function(v) db[path]=v;if apply then apply() end end}
end
local function stringChoice(db,key,label,keys,labels,default,apply)
 return {id=key,label=label,kind="choice",values=labels,
  get=function() for i,k in ipairs(keys) do if (db[key] or default)==k then return i end end end,
  set=function(i) db[key]=keys[i];if apply then apply() end end}
end
H.adapters.ASBuilder.options=function()
 if type(ASBuilderDB)~="table" or type(ASBuilderDB.tracker)~="table" or type(ASBuilder)~="table" then return {} end
 local t=ASBuilderDB.tracker
 local function refresh()
  if ASBuilder.ApplyTrackerLayout then ASBuilder.ApplyTrackerLayout() end
  if ASBuilder.RefreshTracker then ASBuilder.RefreshTracker() end
 end
 local out={stringChoice(t,"mode","Afficher le suivi",{"run","always","hidden"},{"Pendant la partie","Toujours","Masquer"},"run",refresh),
  field(t,"locked","Verrouiller le suivi","check",false,nil,nil,nil,refresh),
  field(t,"collapsed","Replier le suivi","check",false,nil,nil,nil,refresh),
  field(t,"scale","Echelle du suivi","slider",1,.5,2,.05,refresh),
  field(ASBuilderDB,"light","Luminosite des choix","slider",80,0,100,5,refresh)}
 local tips={mode="Choisit quand le suivi reste visible.",locked="Empeche de deplacer le suivi.",
  collapsed="Reduit le suivi a son titre.",scale="100 % correspond a la taille d'origine.",light="0 % sombre, 100 % clair."}
 for _,o in ipairs(out) do
  o.section=o.id=="light" and "Choix de niveau" or "Suivi du build"
  o.tip=tips[o.id]
  if o.id=="scale" then o.unit="%";o.displayScale=100 elseif o.id=="light" then o.unit="%" end
 end
 return out
end
H.adapters.AZSSpellMeter.options=function()
 if type(AZSSpellMeterDB)~="table" or not H.CanOpen("AZSSpellMeter") then return {} end
 local d=AZSSpellMeterDB
 return {
  {id="shown",label="Afficher le compteur",kind="check",section="Affichage",tip="Montre le compteur pendant la partie.",
   get=function() return d.shown~=false end,set=function(v) SlashCmdList.AZSSPELLMETER(v and "show" or "hide") end},
  {id="locked",label="Verrouiller le compteur",kind="check",section="Affichage",tip="Empeche de deplacer la fenetre.",
   get=function() return d.locked and true or false end,
   set=function(v) if (d.locked and true or false)~=v then SlashCmdList.AZSSPELLMETER("lock") end end},
 }
end
H.Register("AZSEliteTracker",{open=command("AZSELITE"),available=registered("AZSELITE"),options=function()
 if type(AZSEliteDB)~="table" then return {} end
 local d=AZSEliteDB
 local function toggle(key,label,cmd,default)
  local o=field(d,key,label,"check",default)
  o.set=function(v) if o.get()~=v then SlashCmdList.AZSELITE(cmd or (v and "show" or "hide")) end end
  return o
 end
 local shown,locked,alert=toggle("shown","Afficher les antres",nil,true),toggle("locked","Verrouiller la fenetre","lock",false),toggle("alert","Annonces dans le chat","alert",true)
 shown.section,locked.section,alert.section="Affichage","Affichage","Annonces"
 shown.tip,locked.tip,alert.tip="Montre les antres suivis.","Empeche de deplacer la fenetre.","Ecrit les annonces dans le chat."
 return {shown,locked,alert}
end})
