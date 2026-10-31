local H=AzerothHub
function H.PrepareConfigs()
 for name,a in pairs(H.adapters) do
  if H.CanOpen(name) and a.prepare then
   local ok,err=H.Call(a.prepare);if not ok then H.Say("Integration "..name.." : "..tostring(err)) end
  end
 end
 H.Scan()
end
function H.CaptureConfig(name)
 local p=H.db.profiles[name];if not p then return end
 local live=H.Snapshot();p.settings=p.settings or {}
 -- Keep settings for unavailable integrations; update only currently readable controls.
 for addon,values in pairs(live.settings) do
  p.settings[addon]=p.settings[addon] or {}
  for id,v in pairs(values) do p.settings[addon][id]=v end
 end
end
function H.EnsureConfigProfiles()
 H.PrepareConfigs()
 if H.db.configProfiles==1 then return end
 local baseline=H.Snapshot().settings
 for _,p in pairs(H.db.profiles) do
  p.settings=p.settings or {}
  for addon,values in pairs(baseline) do
   p.settings[addon]=p.settings[addon] or {}
   for id,v in pairs(values) do if p.settings[addon][id]==nil then p.settings[addon][id]=v end end
  end
 end
 H.db.configProfiles=1
end
function H.UseConfigProfile(name)
 local p=H.db.profiles[name];if not p then return false,"Profil inconnu" end
 H.EnsureConfigProfiles()
 if name~=H.profile then H.CaptureConfig(H.profile) end
 local ops,skipped={},0
 for addon,values in pairs(p.settings or {}) do
  local options={};for _,o in ipairs(H.Options(addon)) do options[o.id]=o end
  for id,value in pairs(values) do
   local o=options[id];local ok,before=H.Call(o and o.get)
   if o and o.profile~=false and ok and H.Valid(o,before) and H.Valid(o,value) then
    if before~=value then table.insert(ops,{o=o,before=before,value=value}) end
   else skipped=skipped+1 end
  end
 end
 table.sort(ops,function(a,b) return a.o.id<b.o.id end)
 H.switchingConfig=true
 local done={}
 for _,op in ipairs(ops) do
  table.insert(done,op)
  local ok,err=H.SetOption(op.o,op.value)
  if not ok then
   local failed=0
   for i=table.getn(done),1,-1 do if not H.SetOption(done[i].o,done[i].before) then failed=failed+1 end end
   H.switchingConfig=nil
   return false,"Profil non applique : "..tostring(err)..(failed>0 and " ; restauration incomplete" or " ; reglages precedents restaures")
  end
 end
 H.switchingConfig=nil;H.SelectProfile(name);H.db.activeProfile=name
 H.CaptureConfig(name)
 local note="Profil "..name.." applique."
 if skipped>0 then note=note.." Certains reglages sont indisponibles." end
 if H.needsReload then note=note.." Rechargement necessaire." end
 H.Say(note)
 return true
end
