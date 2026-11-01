local H=AzerothHub
H.buttons={}
local known={AzerothStatsMinimap="AzerothStats",FieldKitMinimapButton="AzerothFieldKit",AzerlootMinimapButton="Azerloot",
 AzerothCursorMinimapButton="AzerothCursor",LuckyOddsMinimapButton="LuckyOdds",SurvivorUIMinimapButton="SurvivorUI",
 SurvivorUIHistoryButton="SurvivorUI"}
local excluded={MinimapZoomIn=true,MinimapZoomOut=true,MiniMapTracking=true,MiniMapTrackingFrame=true,
 MiniMapMailFrame=true,MiniMapBattlefieldFrame=true,MiniMapWorldMapButton=true,MiniMapMeetingStoneFrame=true,
 GameTimeFrame=true,AzerothHubMinimapButton=true}
local function identity(f)
 if not f.GetName or not f.GetObjectType or not f.GetScript or not f.GetAlpha or not f.SetAlpha then return nil end
 local name=f:GetName()
 if not name or excluded[name] or string.find(name,"^AzerothHub") then return nil end
 local addon=known[name]
 -- Only buttons with an actual click callback; never chest/lair pins, world-map arrows or icons.
 if not addon and (f:GetObjectType()~="Button" or not f:GetScript("OnClick")) then return nil end
 if not addon then
  for _,r in ipairs(H.rows) do
   if string.find(string.lower(name),string.lower(r.name),1,true) then addon=r.name;break end
  end
 end
 if not addon then return nil end
 -- Never suppress a source with no verified way back into it.
 if type(f.Click)~="function" and not H.CanOpen(addon) then return nil end
 return addon,name
end
function H.GatherButtons()
 if not H.db.gather then H.ReleaseButtons();return end
 if not Minimap or not Minimap.GetChildren then return end
 local candidates={Minimap:GetChildren()}
 for _,f in ipairs(candidates) do
  if not H.buttons[f] then
   local addon,name=identity(f)
   if addon then
    H.buttons[f]={frame=f,name=name,addon=addon,alpha=f:GetAlpha()};H.launcherDirty=true
   end
  end
 end
 for f,r in pairs(H.buttons) do
  if H.launcherEntries and H.launcherEntries[r.addon] then
  if f:GetAlpha()~=0 then r.alpha=f:GetAlpha();f:SetAlpha(0) end
  if f.IsMouseEnabled and f.EnableMouse then
   local mouse=f:IsMouseEnabled() and true or false
   if r.mouse==nil then r.mouse=mouse elseif mouse then r.mouse=true end
   if mouse then f:EnableMouse(false) end
  end
  else
   if f:GetAlpha()==0 then f:SetAlpha(r.alpha) end
   if r.mouse~=nil and f.IsMouseEnabled and not f:IsMouseEnabled() then f:EnableMouse(r.mouse) end
  end
 end
end
function H.ReleaseButtons()
 for f,r in pairs(H.buttons) do
  if f:GetAlpha()==0 then f:SetAlpha(r.alpha) end
  if r.mouse~=nil and f.IsMouseEnabled and not f:IsMouseEnabled() then f:EnableMouse(r.mouse) end
 end
 H.buttons={}
end
function H.LaunchButton(record,right)
 local f=record.frame
 if type(f.Click)=="function" then
  local ok,err=H.Call(f.Click,f,right and "RightButton" or "LeftButton")
  if not ok then H.Say("Bouton non declenche : "..tostring(err)) end
  return ok
 end
 return H.Open(record.addon)
end
function H.CreateMinimap()
 if H.mini or not Minimap then return end
 local b=CreateFrame("Button","AzerothHubMinimapButton",Minimap);H.mini=b
 b:SetWidth(32);b:SetHeight(32);b:SetFrameStrata("HIGH")
 local icon=b:CreateTexture(nil,"ARTWORK");icon:SetAllPoints(b)
 icon:SetTexture("Interface\\Icons\\INV_Misc_Gear_01")
 b:RegisterForClicks("LeftButtonUp","RightButtonUp")
 b:SetScript("OnClick",function() if arg1=="RightButton" then H.ToggleUI() elseif H.ToggleLauncher then H.ToggleLauncher() end end)
 b:SetScript("OnEnter",function()
  if not GameTooltip then return end
  GameTooltip:SetOwner(this,"ANCHOR_LEFT");GameTooltip:SetText("Azeroth Hub")
  GameTooltip:AddLine(H.T("Click: launcher. Right-click: manager."),1,1,1);GameTooltip:Show()
 end)
 b:SetScript("OnLeave",function() if GameTooltip then GameTooltip:Hide() end end)
 b:RegisterForDrag("LeftButton")
 b:SetScript("OnDragStart",function() b.dragging=true end)
 b:SetScript("OnDragStop",function() b.dragging=false end)
 local function place()
  local a=math.rad(H.db.miniAngle)
  b:ClearAllPoints();b:SetPoint("CENTER",Minimap,"CENTER",math.cos(a)*80,math.sin(a)*80)
 end
 b:SetScript("OnUpdate",function()
  if not b.dragging then return end
  local x,y=GetCursorPosition();local mx,my=Minimap:GetCenter();local s=Minimap:GetEffectiveScale()
  H.db.miniAngle=math.deg(math.atan2(y/s-my,x/s-mx));place()
 end)
 place()
end
