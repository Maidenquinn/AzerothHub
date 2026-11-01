-- WoW 1.12 / native Lua 5.0. No disk reads, downloaded code, or arbitrary SavedVariables writes.
-- Keep any fields already registered by Locale.lua (LOCALES / RegisterLocale).
AzerothHub=AzerothHub or {}
local H=AzerothHub
H.version="0.7.4"
H.adapters=H.adapters or {}
H.rows=H.rows or {}
H.byName=H.byName or {}
H.page=H.page or 1
H.optionPage=H.optionPage or 1
H.log=H.log or {}
function H.Truth(v) return v==true or v==1 end
function H.Number(v)
 if type(v)~="number" or v~=v or math.abs(v)>1e8 then return nil end
 return v
end
function H.Call(fn,...)
 if type(fn)~="function" then return false,H.T and H.T("API unavailable") or "API unavailable" end
 return pcall(fn,unpack(arg))
end
function H.Say(s)
 H.message=tostring(s)
 table.insert(H.log,tostring(s));if table.getn(H.log)>30 then table.remove(H.log,1) end
 if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage("|cffffd36aAzeroth Hub|r : "..tostring(s)) end
end
local function T(key) return H.T and H.T(key) or key end
local function TF(key,...) if H.TF then return H.TF(key,unpack(arg)) end;return key end
function H.Metadata(name,key)
 local ok,v=H.Call(GetAddOnMetadata,name,key)
 return ok and type(v)=="string" and v or ""
end
local function fillMissing(adapter,entry,key)
 if type(adapter[key])~="function" and type(entry[key])=="function" then adapter[key]=entry[key] end
end
-- Another addon can publish this global before or after the Hub loads.
-- An integration already written here keeps its own functions.
function H.AdoptCatalog()
 local catalog=getglobal("AzerothHubCatalog")
 if type(catalog)~="table" then return end
 local function consider(name,entry)
  if type(name)~="string" or not string.find(name,"^[%w_]+$") or string.len(name)>80 or type(entry)~="table" then return end
  if not H.adapters[name] then H.adapters[name]={} end
  local adapter=H.adapters[name]
  fillMissing(adapter,entry,"open");fillMissing(adapter,entry,"configure")
  fillMissing(adapter,entry,"available");fillMissing(adapter,entry,"prepare")
  if type(adapter.options)~="function" then
   if type(entry.options)=="function" then adapter.options=entry.options
   elseif type(entry.options)=="table" then local published=entry.options;adapter.options=function() return published end end
  end
 end
 for key,entry in pairs(catalog) do
  if type(entry)=="table" then
   if type(key)=="string" then consider(key,entry) elseif type(entry.name)=="string" then consider(entry.name,entry) end
  end
 end
end
function H.Scan()
 H.AdoptCatalog()
 local ok,n=H.Call(GetNumAddOns)
 if not ok or not H.Number(n) or n<0 then n=0 end
 local rows,byName,byLower={},{},{}
 for i=1,math.min(1000,n) do
  local success,name,title,notes,enabled,loadable,reason=H.Call(GetAddOnInfo,i)
  if success and type(name)=="string" and name~="" then
   local loaded,l=H.Call(IsAddOnLoaded,name)
   local indexed,il=H.Call(IsAddOnLoaded,i)
   local nativeLoaded=(loaded and H.Truth(l)) or (indexed and H.Truth(il))
   local a=H.adapters[name]
   local available,present=H.Call(a and a.available)
   local row={name=name,index=i,title=type(title)=="string" and title or name,notes=type(notes)=="string" and notes or "",
    enabled=H.Truth(enabled),activationKnown=true,loaded=nativeLoaded or (available and present==true),
    loadedKnown=loaded or indexed or (available and present==true),
    reason=reason,version=H.Metadata(name,"Version"),dependencies={}}
   local deps={H.Call(GetAddOnDependencies,name)}
   if deps[1] then for j=2,table.getn(deps) do if type(deps[j])=="string" then table.insert(row.dependencies,deps[j]) end end end
   table.insert(rows,row);byName[name]=row;byLower[string.lower(name)]=row
  end
 end
 -- Local folders are not necessarily exposed by the server-backed addon index.
 -- This installation snapshot is generated outside the game from .toc metadata.
 local function observe(name,title,notes,version)
  if type(name)~="string" or byName[name] then return end
 local a=H.adapters[name];local success,present=H.Call(a and a.available)
 local native,flag=H.Call(IsAddOnLoaded,name)
 local loaded=name=="AzerothHub" or (success and present==true) or (native and H.Truth(flag))
  local row={name=name,title=title or name,notes=notes or "",version=version or "",
   enabled=loaded,activationKnown=false,loaded=loaded,loadedKnown=loaded,dependencies={}}
  table.insert(rows,row);byName[name]=row;byLower[string.lower(name)]=row
 end
 if type(AzerothHubInventory)=="table" then
  for _,r in ipairs(AzerothHubInventory) do if type(r)=="table" then observe(r.name,r.title,r.notes,r.version) end end
 end
 -- A folder missing from Inventory.lua can still be found once the client has loaded it.
 -- Also re-check inventoried names: a player may install one after Hub and /reload.
 local function live(name)
  if type(name)~="string" then return end
  local ok,flag=H.Call(IsAddOnLoaded,name)
  local loaded=ok and H.Truth(flag)
  if byName[name] then
   if loaded then
    byName[name].loaded=true;byName[name].loadedKnown=true
    if not byName[name].activationKnown then byName[name].enabled=true end
    local title,notes,version=H.Metadata(name,"Title"),H.Metadata(name,"Notes"),H.Metadata(name,"Version")
    if title~="" then byName[name].title=title end
    if notes~="" then byName[name].notes=notes end
    if version~="" then byName[name].version=version end
   end
   return
  end
  if not loaded then return end
  local title,notes,version=H.Metadata(name,"Title"),H.Metadata(name,"Notes"),H.Metadata(name,"Version")
  observe(name,title~="" and title or name,notes,version)
 end
 if type(AzerothHubInventory)=="table" then
  for _,r in ipairs(AzerothHubInventory) do if type(r)=="table" and type(r.name)=="string" then live(r.name) end end
 end
 local function addonFromFrameName(name)
  local s=name
  while type(s)=="string" and string.len(s)>=3 do
   local ok,flag=H.Call(IsAddOnLoaded,s)
   if ok and H.Truth(flag) then return s end
   local shorter=string.gsub(s,"[A-Z][a-z0-9_]*$","")
   if shorter==s or shorter=="" then s=string.sub(s,1,string.len(s)-1) else s=shorter end
  end
 end
 if Minimap and Minimap.GetChildren then
  local kids={Minimap:GetChildren()}
  for _,f in ipairs(kids) do
   if f.GetName and f.GetObjectType and f:GetObjectType()=="Button" then
    local found=addonFromFrameName(f:GetName() or "")
    if found then live(found) end
   end
  end
 end
 for name,a in pairs(H.adapters) do
  local listed=H.CanOpen(name)
  if not listed and type(a.available)=="function" then
   local ready,present=H.Call(a.available);listed=ready and present==true
  end
  if listed then observe(name);live(name) end
 end
 H.nativeCount=n
 table.sort(rows,function(a,b) return string.lower(a.name)<string.lower(b.name) end)
 H.rows=rows;H.byName=byName;H.byLower=byLower;H.error=nil;return true
end
function H.Clone(v,depth)
 depth=depth or 0;if depth>5 then return nil end
 if type(v)=="boolean" or type(v)=="string" or H.Number(v) then return v end
 if type(v)~="table" then return nil end
 local out={};local n=0
 for k,x in pairs(v) do
  if type(k)=="string" and string.len(k)<=240 and n<1500 then
   local value=H.Clone(x,depth+1);if value~=nil then out[k]=value;n=n+1 end
  end
 end
 return out
end
function H.Register(name,adapter)
 if type(name)=="string" and type(adapter)=="table" then H.adapters[name]=adapter end
end
function H.CanOpen(name)
 local a=H.adapters[name]
 if not a or type(a.open)~="function" then return false end
 if type(a.available)=="function" then
  local ok,present=H.Call(a.available);return ok and present==true
 end
 return H.byName[name] and H.byName[name].loaded==true or false
end
function H.Options(name)
 H.AdoptCatalog()
 local a=H.adapters[name]
 if not a or type(a.options)~="function" then return {} end
 local ok,options=H.Call(a.options)
 if not ok or type(options)~="table" then return {} end
 local out,seen={},{}
 for _,o in ipairs(options) do
  if type(o)=="table" and type(o.id)=="string" and not seen[o.id] and
   type(o.get)=="function" and type(o.set)=="function" then
   table.insert(out,o);seen[o.id]=true
  end
 end
 return out
end
function H.Valid(o,value)
 if o.kind=="check" then return type(value)=="boolean" end
 if o.kind=="choice" then return type(o.values)=="table" and H.Number(value) and value==math.floor(value) and value>=1 and value<=table.getn(o.values) end
 if o.kind=="slider" then
  local low=o.min or 0
  if o.minimum then local ok,n=H.Call(o.minimum);if ok and H.Number(n) then low=n end end
  return H.Number(low) and H.Number(o.max) and H.Number(value) and value>=low and value<=o.max
 end
 return false
end
function H.SetOption(o,value)
 if not H.Valid(o,value) then return false,T("Value rejected") end
 local read,before=H.Call(o.get)
 if not read or not H.Valid(o,before) then return false,T("Setting unavailable in this version") end
 if read and before==value then return true end
 local ok,err=H.Call(o.set,value)
 if not ok then H.Say(TF("Setting not confirmed: %s",err));return false,err end
 local checked,after=H.Call(o.get)
 local same=after==value or (H.Number(after) and H.Number(value) and math.abs(after-value)<.00001)
 if not checked or not same then return false,TF("Setting not confirmed: %s",o.label or o.id) end
 if o.reload then H.needsReload=true end
 if H.CaptureConfig and H.db and not H.switchingConfig then H.CaptureConfig(H.profile) end
 return true
end
function H.Snapshot()
 local p={addons={},settings={}}
 for _,r in ipairs(H.rows) do
  p.addons[r.name]=r.name=="AzerothHub" or r.enabled
  if r.loaded then
   local values={}
   for _,o in ipairs(H.Options(r.name)) do
    local ok,v=H.Call(o.get)
    if ok and o.profile~=false and H.Valid(o,v) then values[o.id]=v end
   end
   if next(values) then p.settings[r.name]=values end
  end
 end
 return p
end
function H.Init()
 if H.db then return end
 local raw=type(AzerothHubDB)=="table" and AzerothHubDB or {}
 H.db={schema=1,profiles={},gather=raw.gatherConsent~=3 or raw.gather==true,
  gatherConsent=3,configProfiles=raw.configProfiles==1 and 1 or nil,
  activeProfile=type(raw.activeProfile)=="string" and string.len(raw.activeProfile)<=48 and raw.activeProfile or nil,
  miniAngle=H.Number(raw.miniAngle) or 225}
 H.db.appearance=(raw.appearance=="atelier" or raw.appearance=="compact") and raw.appearance or "grimoire"
 H.db.language=(type(raw.language)=="string" and (raw.language=="auto" or (H.IsKnownLanguage and H.IsKnownLanguage(raw.language))) and raw.language) or "auto"
 H.db.foldedGroups=type(raw.foldedGroups)=="table" and raw.foldedGroups or {}
 if H.ApplyLocale then H.ApplyLocale() end
 if type(raw.profiles)=="table" then
  local count=0
  for name,p in pairs(raw.profiles) do
   if type(name)=="string" and string.len(name)>0 and string.len(name)<=48 and type(p)=="table" and count<30 then
    H.db.profiles[name]=H.Clone(p);count=count+1
   end
  end
 end
 H.db.pending=type(raw.pending)=="table" and H.Clone(raw.pending) or nil
 H.db.undo=type(raw.undo)=="table" and H.Clone(raw.undo) or nil
 AzerothHubDB=H.db
 H.Scan()
 if not next(H.db.profiles) and not H.error then
  local current=H.Snapshot();H.db.profiles.Actuel=current
  H.db.profiles.Solo=H.Clone(current);H.db.profiles.Coop=H.Clone(current)
  H.db.profiles.Leger=H.Clone(current)
  for _,name in ipairs({"AZSSpellMeter","ASBuilder","AzerothChallenges","AZSEliteTracker"}) do
   if H.byName[name] then H.db.profiles.Leger.addons[name]=false;H.db.profiles.Leger.settings[name]=nil end
  end
  local function preset(profile,addon,id,value)
   local values=H.db.profiles[profile].settings[addon]
   if values and values[id]~=nil then values[id]=value end
  end
  preset("Solo","AzerothFieldKit","windows/display/Group damage meter",false)
  preset("Solo","AzerothFieldKit","windows/coop/Co-op teammate cards",false)
  preset("Coop","AzerothFieldKit","windows/display/Group damage meter",true)
  preset("Coop","AzerothFieldKit","windows/coop/Co-op teammate cards",true)
  for _,id in ipairs({"windows/display/statsFrame","windows/display/takenFrame","windows/display/gearFrame","windows/display/Run mode card"}) do
   preset("Leger","AzerothFieldKit",id,false)
  end
  preset("Leger","AzerothStats","bar",false)
  preset("Leger","AzerothCursor","pulse",false)
 end
 H.profile="Actuel"
 if not H.db.profiles.Actuel then for name in pairs(H.db.profiles) do H.profile=name;break end end
 if H.db.profiles[H.db.activeProfile or ""] then H.profile=H.db.activeProfile end
 H.pendingStarted=GetTime and GetTime() or 0
end
function H.SaveProfile(name)
 name=string.gsub(string.gsub(name or "","^%s+",""),"%s+$","")
 if name=="" or string.len(name)>48 then return false,T("Profile name: 1 to 48 characters") end
 if not H.Scan() then return false,H.error end
 local n=0;for _ in pairs(H.db.profiles) do n=n+1 end
 if not H.db.profiles[name] and n>=30 then return false,T("Maximum 30 profiles") end
 H.db.profiles[name]=H.Snapshot();H.profile=name
 H.Say(TF("Profile saved: %s",name));return true
end
function H.SaveDraft(name)
 local draft=H.draft and H.Clone(H.draft.addons)
 local ok,err=H.SaveProfile(name);if not ok then return false,err end
 if draft then
  for addon,value in pairs(draft) do if H.byName[addon] and type(value)=="boolean" then H.db.profiles[H.profile].addons[addon]=value end end
 end
 H.db.profiles[H.profile].addons.AzerothHub=true
 H.draft=H.Clone(H.db.profiles[H.profile]);return true
end
function H.SelectProfile(name)
 local p=H.db.profiles[name];if not p then return end
 H.profile=name;H.draft=H.Clone(p);H.preview=nil;H.page=1
end
function H.Undo()
 if not H.db.undo then return false,T("No previous profile") end
 local prior=H.Clone(H.db.undo)
 H.db.pending=nil;H.waitReload=false
 return H.Apply(prior)
end
function H.Plan(profile)
 if not H.Scan() then return nil,H.error end
 if type(profile)~="table" or type(profile.addons)~="table" then return nil,T("Invalid profile") end
 if profile.settings~=nil and type(profile.settings)~="table" then return nil,T("Invalid profile settings") end
 for name,values in pairs(profile.settings or {}) do if type(name)~="string" or type(values)~="table" then return nil,"Reglages de profil invalides" end end
 local target,changes,needed={},{},{}
 for _,r in ipairs(H.rows) do
  local v=profile.addons[r.name]
  if type(v)~="boolean" then v=r.enabled end -- New addons stay as the user configured them.
  target[r.name]=v
 end
 target.AzerothHub=true
 local function requireAddon(name,path)
  local r=H.byName[name] or H.byLower[string.lower(name)];if not r then return false,TF("Missing dependency: %s",name) end
  name=r.name
  if path[name] then return false,TF("Dependency cycle: %s",name) end
  if needed[name] then return true end
  path[name]=true
  for _,dep in ipairs(r.dependencies) do
   local dependency=H.byName[dep] or H.byLower[string.lower(dep)]
   target[dependency and dependency.name or dep]=true
   local ok,err=requireAddon(dep,path);if not ok then return false,err end
  end
  path[name]=nil;needed[name]=true;return true
 end
 for _,r in ipairs(H.rows) do if target[r.name] then local ok,err=requireAddon(r.name,{});if not ok then return nil,err end end end
 for _,r in ipairs(H.rows) do if target[r.name]~=r.enabled then
  if not r.activationKnown then return nil,TF("Activation not exposed for %s: use Options > AddOns.",r.name) end
  table.insert(changes,{name=r.name,before=r.enabled,after=target[r.name]})
 end end
 local settingChanges={}
 for name,values in pairs(profile.settings or {}) do
  if target[name] then
   local byId={};for _,o in ipairs(H.Options(name)) do byId[o.id]=o end
   for id,value in pairs(values) do
    local o=byId[id];local ok,before
    if o then ok,before=H.Call(o.get) end
    if not ok or before~=value then
     table.insert(settingChanges,{name=name,id=id,label=o and o.label or id,before=ok and tostring(before) or "non disponible",after=tostring(value)})
    end
   end
  end
 end
 table.sort(settingChanges,function(a,b) return a.name..a.id<b.name..b.id end)
 return {target=target,changes=changes,settingChanges=settingChanges,profile=profile}
end
local function setEnabled(name,value)
 local fn=DisableAddOn;if value then fn=EnableAddOn end
 local ok,err=H.Call(fn,name)
 if not ok then return false,err end
 local success,_,_,_,enabled=H.Call(GetAddOnInfo,name)
 if not success or H.Truth(enabled)~=value then return false,TF("State not confirmed: %s",name) end
 return true
end
function H.Apply(profile)
 if H.db.pending then return false,T("Pending settings: reload or cancel first") end
 local plan,err=H.Plan(profile);if not plan then return false,err end
 for _,change in ipairs(plan.changes) do
  if (change.after and type(EnableAddOn)~="function") or (not change.after and type(DisableAddOn)~="function") then
   return false,T("Activation change unavailable on this client")
  end
 end
 local undo=H.Snapshot();local done={}
 for _,change in ipairs(plan.changes) do
  table.insert(done,change)
  local ok,reason=setEnabled(change.name,change.after)
  if not ok then
   local failed={}
   for i=table.getn(done),1,-1 do if not setEnabled(done[i].name,done[i].before) then table.insert(failed,done[i].name) end end
   H.Scan()
   return false,tostring(reason)..(table.getn(failed)>0 and (" ; restauration non confirmee : "..table.concat(failed,", ")) or " ; activation precedente restauree")
  end
 end
 local settings={}
 for _,change in ipairs(plan.settingChanges) do
  if H.byName[change.name] then
   settings[change.name]=settings[change.name] or {}
   settings[change.name][change.id]=profile.settings[change.name][change.id]
  end
 end
 H.db.pending=next(settings) and settings or nil
 if table.getn(done)>0 or H.db.pending then H.db.undo=undo end
 H.pendingStarted=GetTime and GetTime() or 0
 -- Settings apply only after the next load, never silently later during this session.
 H.waitReload=H.db.pending~=nil;H.needsReload=H.needsReload or table.getn(done)>0 or H.waitReload
 H.Scan();H.Say(H.needsReload and T("Profile prepared. Reload required to finish.") or T("Profile already matches: no changes needed."))
 return true
end
function H.ApplyPending()
 if not H.db or not H.db.pending or H.waitReload then return end
 local age=(GetTime and GetTime() or 0)-H.pendingStarted
 for name,values in pairs(H.db.pending) do
  local r=H.byName[name];local options=H.Options(name)
  if type(values)~="table" then H.db.pending[name]=nil
  elseif r and r.enabled and r.loaded and table.getn(options)>0 then
   local byId={};for _,o in ipairs(options) do byId[o.id]=o end
   for id,value in pairs(values) do
    local o=byId[id]
    if not o or o.profile==false or not H.SetOption(o,value) then H.Say(TF("Option ignored: %s / %s",name,id)) end
   end
   H.db.pending[name]=nil
  elseif age>45 then H.Say(TF("Settings not applied: %s (integration unavailable)",name));H.db.pending[name]=nil end
 end
 if not next(H.db.pending) then H.db.pending=nil end
end
function H.Open(name)
 local a=H.adapters[name]
 if a and type(a.open)=="function" then
  local ok,err=H.Call(a.open);if not ok then H.Say(tostring(err)) end;return ok
 end
 H.Say(TF("No known launcher for %s",name));return false
end
function H.Diagnose()
 H.Scan()
 local captured=0;for _ in pairs(H.buttons or {}) do captured=captured+1 end
 H.Say(TF("Version %s | %s addons | %s gathered buttons",H.version,table.getn(H.rows),captured))
 H.Say("API catalogue="..type(GetNumAddOns)..", infos="..type(GetAddOnInfo)..", chargement="..type(IsAddOnLoaded))
 for i,r in ipairs(H.rows) do
  if i<=25 then
   local ok,v=H.Call(IsAddOnLoaded,r.name)
   -- Rows are alphabetically sorted, so use the original catalogue index.
   local indexed,iv=H.Call(IsAddOnLoaded,r.index)
   H.Say(r.name.." | actif="..tostring(r.enabled).." | charge="..tostring(r.loaded)..
    " | natif(nom)="..(ok and (type(v)..":"..tostring(v)) or "absent/erreur")..
    " | natif(index)="..(indexed and (type(iv)..":"..tostring(iv)) or "absent/erreur")..
    " | raccourci="..tostring(H.CanOpen(r.name)))
  end
 end
end
SLASH_AZEROTHHUB1="/azhub";SLASH_AZEROTHHUB2="/hub"
SlashCmdList.AZEROTHHUB=function(msg)
 H.Init()
 if msg=="release" then H.db.gather=false;if H.ReleaseButtons then H.ReleaseButtons() end
 elseif msg=="scan" then H.Scan();H.Say(TF("%s addons detected",table.getn(H.rows)))
 elseif msg=="diag" then H.Diagnose()
 elseif msg=="cancel" then H.db.pending=nil;H.waitReload=false;H.Say(T("Deferred settings cancelled; activations already written are kept."))
 elseif H.ToggleUI then H.ToggleUI() end
end
local driver=CreateFrame("Frame","AzerothHubDriver",UIParent)
driver:RegisterEvent("PLAYER_LOGIN");driver:RegisterEvent("PLAYER_LOGOUT");driver:RegisterEvent("ADDON_LOADED")
driver:SetScript("OnEvent",function()
 if event=="PLAYER_LOGIN" then H.Init();if H.CreateMinimap then H.CreateMinimap() end
 elseif event=="PLAYER_LOGOUT" and H.ReleaseButtons then
  if H.CaptureConfig and H.db then H.CaptureConfig(H.profile) end
  H.ReleaseButtons()
 elseif event=="ADDON_LOADED" and H.db then H.Scan() end
end)
local elapsed,collect=0,0
driver:SetScript("OnUpdate",function()
 if not H.db then return end
 local dt=arg1 or 0;elapsed=elapsed+dt;collect=collect+dt
 -- Minimap child walks are costly with many buttons; one check per second is enough.
 if collect>=1 then
  collect=0;if H.GatherButtons then H.GatherButtons() end
  if H.db.gather and (not H.launcherEntries or H.launcherDirty) and H.ToggleLauncher then H.ToggleLauncher(true) end
 end
 if elapsed<1 then return end;elapsed=0
 if H.db.pending and not H.waitReload then H.Scan();H.ApplyPending();if H.RefreshUI then H.RefreshUI() end end
end)
