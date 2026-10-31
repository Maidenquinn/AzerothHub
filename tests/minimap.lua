dofile("tests/mock.lua");T.Load()
local H=AzerothHub
local source=CreateFrame("Button","KnownMinimapButton",Minimap);source.alpha=.6
local calls=0;source:SetScript("OnClick",function() assert(this==source and arg1=="RightButton");calls=calls+1 end)
local original=source:GetScript("OnClick")
local zoom=CreateFrame("Button","MinimapZoomIn",Minimap);zoom:SetScript("OnClick",function() end)
local pin=CreateFrame("Frame","KnownChestPin",Minimap)
local unsupported=CreateFrame("Button","UnrelatedMinimapButton",Minimap);unsupported.Click=false;unsupported:SetScript("OnClick",function() end)
assert(H.db.gather==true) -- grouping requested; masking still requires a rendered entry
H.db.gather=true
H.GatherButtons()
assert(source.alpha==.6 and source.mouse) -- no launcher entry: keep it accessible
H.launcherEntries={Known=true};H.GatherButtons()
assert(source.alpha==0 and not source.mouse and source:GetParent()==Minimap and source:GetScript("OnClick")==original)
assert(zoom.alpha==1 and pin.alpha==1 and unsupported.alpha==1)
assert(H.LaunchButton(H.buttons[source],true));assert(calls==1)
source:SetAlpha(.8);H.GatherButtons();H.ReleaseButtons();assert(source.alpha==.8 and source.mouse)
source:Hide();H.GatherButtons();H.ReleaseButtons();assert(not source:IsShown())
H.db.gather=false;H.GatherButtons();assert(next(H.buttons)==nil)
H.CreateMinimap();assert(H.mini and H.mini:GetParent()==Minimap)
print("PASS: minimap source actions, native exclusions, no reparent/scripts, late opacity, original visibility, restoration, unsupported fallback")
