dofile("tests/mock.lua")
local opened={}
SlashCmdList.FieldKit=function() opened.kit=(opened.kit or 0)+1 end
SlashCmdList.ASBUILDER=function() opened.builder=(opened.builder or 0)+1 end
IsAddOnLoaded=nil
T.Load();local H=AzerothHub
-- Missing loaded API must not hide working entry points or claim every addon is loaded.
assert(H.byName.AzerothFieldKit.loaded and H.byName.ASBuilder.loaded)
assert(not H.byName.Known.loaded and not H.byName.Known.loadedKnown)
assert(not H.CanOpen("AzerothCursor")) -- registered adapter, absent actual command
H.ToggleUI();assert(AzerothHubWindow.rows[1].title:GetText()~="")
H.CreateMinimap();H.ToggleLauncher()
local launch=AzerothHubLauncher
assert(table.getn(launch.rows)==2 and not launch.empty:IsShown())
for _,row in ipairs(launch.rows) do row:Click() end
assert(opened.kit==1 and opened.builder==1)
assert(T.writes==0 and T.optionWrites==0 and T.reloads==0)
-- A captured source button can launch an addon without a slash command or loaded API.
local clicks=0
H.db.gather=true
local b=CreateFrame("Button","KnownMinimapButton",Minimap)
b:SetScript("OnClick",function() clicks=clicks+1 end)
H.ToggleLauncher()
local found
for _,row in ipairs(launch.rows) do if row:IsShown() and row.addon=="Known" then found=row end end
assert(found);found:Click();assert(clicks==1 and b:GetAlpha()==0)
H.ReleaseButtons();assert(b:GetAlpha()==1 and b:IsMouseEnabled())
-- False native answers cannot suppress a demonstrably registered launcher.
IsAddOnLoaded=function() return nil end
H.Scan();assert(H.byName.AzerothFieldKit.loaded and H.CanOpen("AzerothFieldKit"))
-- Clients accepting only catalogue indices still report loaded-only addons correctly.
IsAddOnLoaded=function(key) assert(type(key)=="number");return T.Row(key).loaded and 1 or nil end
H.Scan();assert(H.byName.Known.loaded)
H.Diagnose()
-- Explicit zero and absent handlers must never count as a live launcher.
IsAddOnLoaded=function() return 0 end
SlashCmdList.FieldKit=nil;SlashCmdList.ASBUILDER=nil
b:SetScript("OnClick",nil)
H.Scan();assert(not H.byName.AzerothFieldKit.loaded and not H.CanOpen("ASBuilder"))
H.ToggleLauncher();assert(launch.empty:IsShown())
assert(T.writes==0 and T.optionWrites==0 and T.reloads==0)
print("PASS: no HasFocus, absent/false/index-only loaded API, registered launchers, captured clicks, empty state, diagnostic without writes")
