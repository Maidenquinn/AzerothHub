local H=AzerothHub
local launcher
local surface,label,button,put=H.NativeUI.surface,H.NativeUI.label,H.NativeUI.button,H.NativeUI.put
local function show(f,on) if on then f:Show() else f:Hide() end end
local function launch(name,right) return H.LaunchAddon(name,right) end
function H.ToggleLauncher(quiet)
 H.Init();H.Scan();H.GatherButtons()
 if not quiet then H.HideManager() end
 local wasShown=launcher and launcher:IsShown()
 if not quiet and wasShown then launcher:Hide();return end
 if not launcher then
  launcher=CreateFrame("Frame","AzerothHubLauncher",UIParent)
  H.launcher=launcher
  launcher:SetWidth(290);launcher:SetFrameStrata("DIALOG");surface(launcher)
  if launcher.SetClampedToScreen then launcher:SetClampedToScreen(true) end
  launcher:SetPoint("TOPRIGHT",H.mini or Minimap,"BOTTOMRIGHT",0,-8)
  label(launcher,12,10,266,25,"Lanceur",15);launcher.rows={}
  launcher.manage=button(launcher,12,44,266,28,"Gestionnaire et profils",function() launcher:Hide();H.ToggleUI() end)
  launcher.empty=label(launcher,12,44,266,35,"Aucun raccourci disponible.\nDiagnostic : /azhub diag",11)
 end
 for _,row in ipairs(launcher.rows) do row:Hide() end
 local y=44
 local used=0
 local items,seen={},{}
 local function add(name,title)
  if not seen[name] then table.insert(items,{name=name,title=title or name});seen[name]=true end
 end
 for _,r in ipairs(H.rows) do if H.CanOpen(r.name) then add(r.name,r.title) end end
 for name in pairs(H.adapters) do if H.CanOpen(name) then add(name) end end
 for _,record in pairs(H.buttons) do
  local r=H.byName[record.addon];add(record.addon,r and r.title)
 end
 table.sort(items,function(a,b) return string.lower(a.name)<string.lower(b.name) end)
 local represented={}
 for _,r in ipairs(items) do
  if y<600 then
   used=used+1
   local row=launcher.rows[used]
   if not row then
    row=button(launcher,12,y,266,26,"",function() end);launcher.rows[used]=row
    row:SetScript("OnClick",function() launcher:Hide();launch(row.addon,false) end)
   end
   row.addon=r.name;put(row,H.DisplayTitle(r));row:Show()
   represented[r.name]=true
   y=y+30
  end
 end
 show(launcher.empty,used==0)
 if used==0 then y=y+40 end
 launcher.manage:ClearAllPoints();launcher.manage:SetPoint("TOPLEFT",launcher,"TOPLEFT",12,-y)
 launcher:SetHeight(y+40)
 if not quiet or wasShown then launcher:Show() else launcher:Hide() end
 H.launcherEntries=represented;H.launcherDirty=nil;H.GatherButtons()
end
