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
H.Register("AzerothCursor",{open=command("AZEROTHCURSOR"),configure=command("AZEROTHCURSOR"),options=function()
 local a=getglobal("AzerothCursor");if type(a)~="table" or type(a.db)~="table" then return {} end
 local function apply() if a.Apply then a.Apply() end end
 local function num(key,fallback)
  local n=tonumber(a.db[key]);if n then return n end;return fallback
 end
 local function check(key,label,section,tip)
  return {id=key,label=label,kind="check",section=section,tip=tip,
   get=function() return a.db[key] and true or false end,
   set=function(v) a.db[key]=v and true or false;apply() end}
 end
 local function slider(key,label,section,low,high,tip,unit)
  return {id=key,label=label,kind="slider",min=low,max=high,step=1,section=section,unit=unit,tip=tip,
   get=function() return num(key,low) end,
   set=function(v) a.db[key]=v;apply() end}
 end
 local out={
  check("enabled","Repere actif","Visibilite","Affiche l'anneau autour de la souris. Independant de l'icone de classe."),
  check("classIcon","Icone de classe","Visibilite","Blason de classe au curseur. Independant du repere."),
  check("pulse","Halo anime","Animation","Fait varier doucement l'intensite du halo."),
  slider("thickness","Epaisseur","Apparence",1,3,"Epaisseur de l'anneau.","px"),
  slider("size","Diametre du repere","Apparence",24,160,"Diametre de l'anneau.","px"),
  slider("opacity","Opacite","Apparence",20,100,"Visibilite globale.","%"),
  slider("halo","Intensite du halo","Apparence",0,100,"Force du halo lumineux.","%"),
  slider("crosshair","Reticule","Apparence",0,100,"Longueur du reticule. Zero = masque.","px"),
  slider("dot","Point central","Apparence",0,24,"Rayon du point. Zero = masque.","px"),
  {id="iconSize",label="Taille de l'icone",kind="slider",min=8,max=120,step=1,section="Icone de classe",unit="px",
   tip="Taille du blason. Active aussi l'icone de classe.",
   get=function() return num("iconSize",28) end,
   set=function(v) a.db.iconSize=v;a.db.classIcon=true;apply() end},
 }
 local tokens={"WARRIOR","PALADIN","HUNTER","ROGUE","PRIEST","SHAMAN","MAGE","WARLOCK","DRUID"}
 local classLabels={"Guerrier","Paladin","Chasseur","Voleur","Pretre","Chaman","Mage","Demoniste","Druide"}
 if type(a.L)=="function" then
  for i,token in ipairs(tokens) do
   local ok,s=H.Call(a.L,token)
   if ok and type(s)=="string" and s~="" then classLabels[i]=s end
  end
 end
 table.insert(out,{id="classIconToken",label="Classe du blason",kind="choice",section="Icone de classe",values=classLabels,
  tip="Quelle classe afficher. Active aussi l'icone.",
  get=function()
   local tok=a.ClassIconToken and a.ClassIconToken() or a.db.classIconToken
   for i,t in ipairs(tokens) do if tok==t then return i end end
   return 1
  end,
  set=function(i)
   a.db.classIconToken=tokens[i];a.db.classIcon=true;apply()
  end})
 local colorLabels={}
 for i,c in ipairs(a.colors or {}) do colorLabels[i]=c[1] or ("Couleur "..i) end
 if table.getn(colorLabels)>0 then
  table.insert(out,{id="color",label="Couleur predefinie",kind="choice",section="Couleur",values=colorLabels,
   tip="Applique une couleur nommee et efface une couleur RVB personnalisee.",
   get=function()
    local i=tonumber(a.db.color) or 1
    if i<1 then i=1 end;if i>table.getn(colorLabels) then i=1 end;return i
   end,
   set=function(i) a.db.color=i;a.db.rgb=nil;apply() end})
 end
 table.insert(out,{id="language",label="Langue",kind="choice",section="Interface",values={"Francais","English"},
  tip="Langue des options Azeroth Cursor. Aleatoire : /azcursor random ou Options d'origine.",
  get=function() return a.db.language=="en" and 2 or 1 end,
  set=function(i) a.db.language=(i==2) and "en" or "fr";apply() end})
 return out
end})
-- Observe registered entry points; never execute them to detect an addon.
local commands={ASBuilder="ASBUILDER",AZSSpellMeter="AZSSPELLMETER",AzerothChallenges="AZEROTHCHALLENGES",
 AzerothCollector="AZEROTHCOLLECTOR",AzerothDeathRecap="AZEROTHDEATHRECAP",AzerothMover="AZEROTHMOVER",
 AzerothClarity="AZCLARITY",AzerothFieldKit="FieldKit",AzerothStats="AZEROTHSTATS",AzerothCursor="AZEROTHCURSOR"}
local function registered(key)
 return function() return type(SlashCmdList)=="table" and type(SlashCmdList[key])=="function" end
end
for name,key in pairs(commands) do H.adapters[name].available=registered(key) end
H.adapters.AzerothCursor.available=function()
 local a=getglobal("AzerothCursor")
 return (type(a)=="table" and type(a.db)=="table") or (type(SlashCmdList)=="table" and type(SlashCmdList.AZEROTHCURSOR)=="function")
end
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

-- Survivor UI publishes no Hub schema. These modules use its public toggles only.
local function survivorOn(key)
 return function() return type(SurvivorUIDB)=="table" and SurvivorUIDB[key]~=false end
end
local function survivorOnly(key)
 return function() return type(SurvivorUIDB)=="table" and SurvivorUIDB[key]==true end
end
local function survivorFlip(name,isOn)
 return function(v) local fn=getglobal(name);if type(fn)=="function" and isOn()~=v then fn() end end
end
local function survivorFeature(key)
 return function() return type(SurvivorUI_Feature)~="function" or SurvivorUI_Feature(key) end
end
local function survivorFeatureSet(key,live)
 return function(v)
  if type(SurvivorUI_SetFeature)~="function" or type(SurvivorUI_Feature)~="function" then return end
  if SurvivorUI_Feature(key)==v then return end
  SurvivorUI_SetFeature(key,v)
 end
end
local function survivorCheck(id,label,section,tip,isOn,set,reload)
 return {id=id,label=label,kind="check",section=section,tip=tip,reload=reload,get=isOn,set=set}
end
H.Register("SurvivorUI",{
 available=function() return type(SurvivorUI_ToggleOptions)=="function" or (type(SlashCmdList)=="table" and type(SlashCmdList.SURVIVORUI)=="function") end,
 open=function()
  if type(SurvivorUI_ToggleOptions)=="function" then SurvivorUI_ToggleOptions()
  elseif type(SlashCmdList)=="table" and type(SlashCmdList.SURVIVORUI)=="function" then SlashCmdList.SURVIVORUI("opt")
  else error("Survivor UI non charge") end
 end,
 configure=function()
  if type(SurvivorUI_ToggleOptions)=="function" then SurvivorUI_ToggleOptions()
  elseif type(SlashCmdList)=="table" and type(SlashCmdList.SURVIVORUI)=="function" then SlashCmdList.SURVIVORUI("opt")
  else error("Survivor UI non charge") end
 end,
 options=function()
  if type(SurvivorUIDB)~="table" and type(SurvivorUI_ToggleOptions)~="function" then return {} end
  SurvivorUIDB=SurvivorUIDB or {}
  local out={
   survivorCheck("tracker","Suivi de run","Partie","Sous la minimap : zone, horloge, boss et gardiens.",survivorOn("tracker"),survivorFlip("SurvivorUI_ToggleTracker",survivorOn("tracker"))),
   survivorCheck("pace","Rythme de kills","Partie","Orbe a cote de l'horloge du suivi.",survivorOn("pace"),survivorFlip("SurvivorUI_TogglePace",survivorOn("pace"))),
   survivorCheck("guardians","Gardiens","Partie","Liste ou barre des antres.",survivorOn("guardians"),survivorFlip("SurvivorUI_ToggleGuardians",survivorOn("guardians"))),
   survivorCheck("bossBars","Barres de boss","Partie","Boss et gardiens eveilles avec leurs debuffs.",survivorOn("bossBars"),survivorFlip("SurvivorUI_BossBars",survivorOn("bossBars"))),
   survivorCheck("tally","Kills et or","Partie","Compteurs de kills, or et prix du coffre.",survivorOn("tally"),survivorFlip("SurvivorUI_Tally",survivorOn("tally"))),
   survivorCheck("xpBar","Barre d'XP","Partie","Niveau et experience sur une barre separee.",survivorOnly("xpBar"),survivorFlip("SurvivorUI_ToggleXpBar",survivorOnly("xpBar"))),
   survivorCheck("lootLog","Liste de butin","Partie","Objets tombes pendant la run.",survivorOn("lootLog"),survivorFlip("SurvivorUI_ToggleLoot",survivorOn("lootLog"))),
   survivorCheck("meter","Compteur de degats","Combat","Sources, critiques et soins.",survivorOn("meter"),survivorFlip("SurvivorUI_ToggleMeter",survivorOn("meter"))),
   survivorCheck("runPanel","Cette run","Combat","Chiffres de la run en cours.",survivorOn("runPanel"),survivorFlip("SurvivorUI_ToggleRun",survivorOn("runPanel"))),
   survivorCheck("critBox","Plus gros critiques","Combat","Meilleur critique par capacite.",survivorOnly("critBox"),survivorFlip("SurvivorUI_ToggleCrits",survivorOnly("critBox"))),
   survivorCheck("counters","Compteurs de sorts","Combat","DoT, peurs et totems au-dessus des boutons.",survivorOn("counters"),function(v) if survivorOn("counters")()~=v then SurvivorUIDB.counters=v and true or false end end),
   survivorCheck("buildList","Liste de build","Personnage","Sorts, rangs et bijoux.",survivorOn("buildList"),survivorFlip("SurvivorUI_ToggleBuild",survivorOn("buildList"))),
   survivorCheck("unitFrames","Cadres d'unites","Interface","Cadres joueur et cible plats.",survivorFeature("unitFrames"),survivorFeatureSet("unitFrames"),true),
   survivorCheck("actionBar","Barre d'actions","Interface","Boutons 1 a 6 et = sur une ligne.",survivorFeature("actionBar"),survivorFeatureSet("actionBar"),true),
   survivorCheck("buffs","Ameliorations","Interface","Buffs et debuffs au-dessus du cadre.",survivorFeature("buffs"),survivorFeatureSet("buffs"),true),
   survivorCheck("chat","Chat plat","Interface","Chat sans cadre d'origine.",survivorFeature("chat"),survivorFeatureSet("chat"),true),
   survivorCheck("minimap","Minimap carree","Interface","Minimap carree et boutons ranges.",survivorFeature("minimap"),survivorFeatureSet("minimap"),true),
   survivorCheck("hover","Contour blanc","Interface","Contour autour de l'element sous la souris.",survivorOn("hover"),survivorFlip("SurvivorUI_ToggleHover",survivorOn("hover"))),
  }
  if type(SurvivorUI_DamageMode)=="function" and type(SurvivorUI_SetDamageMode)=="function" then
   table.insert(out,1,survivorCheck("combatText","Texte de combat Survivor","Combat","Nombres de combat de Survivor UI. Desactive : ceux du jeu.",
    function() return SurvivorUI_DamageMode()=="survivor" end,
    function(v) SurvivorUI_SetDamageMode(v and "survivor" or "game") end))
  end
  if type(SlashCmdList)=="table" and type(SlashCmdList.SURVIVORPLATES)=="function" then
   table.insert(out,survivorCheck("plates","Nameplates Survivor","Interface","Plaques de Survivor Plates autour des ennemis.",
    function() return not (SurvivorPlatesDB and SurvivorPlatesDB.hidden) end,
    function(v) local hidden=SurvivorPlatesDB and SurvivorPlatesDB.hidden;if (not hidden)~=v then SlashCmdList.SURVIVORPLATES("none") end end))
  end
  return out
 end
})
H.Register("SurvivorPlates",{
 available=registered("SURVIVORPLATES"),
 open=command("SURVIVORPLATES"),
 options=function()
  if type(SlashCmdList)~="table" or type(SlashCmdList.SURVIVORPLATES)~="function" then return {} end
  SurvivorPlatesDB=SurvivorPlatesDB or {}
  local function shown(kind)
   return function() return type(SurvivorPlates_Shown)~="function" or SurvivorPlates_Shown(kind) end
  end
  local function flipKind(kind)
   return function(v) if shown(kind)()~=v then SlashCmdList.SURVIVORPLATES(kind=="elite" and "elites" or kind=="guardian" and "guardians" or kind=="boss" and "bosses" or kind) end end
  end
  return {
   survivorCheck("hidden","Nameplates actives","Affichage","Masque ou rappelle toutes les plaques.",
    function() return not (SurvivorPlatesDB and SurvivorPlatesDB.hidden) end,
    function(v) local on=not (SurvivorPlatesDB and SurvivorPlatesDB.hidden);if on~=v then SlashCmdList.SURVIVORPLATES("none") end end),
   survivorCheck("names","Noms sur chaque plaque","Affichage","Sinon : elites, gardiens et boss seulement.",
    function() return SurvivorPlatesDB and SurvivorPlatesDB.names and true or false end,
    function(v) if (SurvivorPlatesDB.names and true or false)~=v then SlashCmdList.SURVIVORPLATES("names") end end),
   survivorCheck("click","Clic a travers","Affichage","Le clic traverse la plaque vers le monde.",
    function() return type(SurvivorPlates_ClickThrough)=="function" and SurvivorPlates_ClickThrough() end,
    function(v) if (type(SurvivorPlates_ClickThrough)=="function" and SurvivorPlates_ClickThrough())~=v then SlashCmdList.SURVIVORPLATES("click") end end),
   {id="scale",label="Echelle",kind="slider",min=.5,max=2,step=.05,section="Affichage",unit="%",displayScale=100,
    tip="Taille des plaques.",
    get=function() return type(SurvivorPlates_GetScale)=="function" and SurvivorPlates_GetScale() or 1 end,
    set=function(v) if type(SurvivorPlates_SetScale)=="function" then SurvivorPlates_SetScale(v) end end},
   survivorCheck("normal","Troupes","Filtres","Plaques des ennemis ordinaires.",shown("normal"),flipKind("normal")),
   survivorCheck("elite","Elites","Filtres","Plaques des elites.",shown("elite"),flipKind("elite")),
   survivorCheck("guardian","Gardiens","Filtres","Plaques des gardiens.",shown("guardian"),flipKind("guardian")),
   survivorCheck("boss","Boss","Filtres","Plaques des boss.",shown("boss"),flipKind("boss")),
   survivorCheck("party","Groupe","Filtres","Plaques des allies en coop.",shown("party"),flipKind("party")),
  }
 end
})
