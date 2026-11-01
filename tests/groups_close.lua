dofile("tests/mock.lua")
FieldKitUI={frame=CreateFrame("Frame","FieldKitPanel",UIParent),sections={}}
FieldKitUI.frame:Show()
SlashCmdList.FieldKit=function() FieldKitUI.frame:Show() end
T.Load();local H=AzerothHub
H.ToggleUI();local ui=AzerothHubWindow
-- Hub language option listed first among settings.
local first
for _,row in ipairs(ui.rows) do if row.addon then first=row.addon;break end end
assert(first=="AzerothHub")
-- Fold left group "settings"
local header
for _,row in ipairs(ui.rows) do if row.groupKey=="settings" then header=row;break end end
assert(header and not string.find(header.title:GetText(),">",1,true))
local before=table.getn(ui.filteredRows)
header:Click()
assert(H.db.foldedGroups.settings==true)
assert(table.getn(ui.filteredRows)<before)
local foldedTitle
for _,row in ipairs(ui.rows) do if row:IsShown() and row.groupKey=="settings" then foldedTitle=row.title:GetText() end end
assert(foldedTitle and string.find(foldedTitle,">",1,true))
header=nil
for _,row in ipairs(ui.rows) do if row.groupKey=="settings" then header=row;break end end
header:Click();assert(H.db.foldedGroups.settings~=true)
-- Original options → Back to Hub closes native FieldKit frame
H.selected="AzerothFieldKit";H.RefreshUI()
FieldKitUI.frame:Show()
ui.original:Click()
assert(ui.openedNative=="AzerothFieldKit" and ui.returnBar:IsShown() and FieldKitUI.frame:IsShown())
ui.returnButton:Click()
assert(not FieldKitUI.frame:IsShown() and ui:IsShown() and not ui.openedNative)
-- Header language dropdown lists all game languages.
assert(ui.langHeader and ui.langMenu)
ui.langHeader:Click()
assert(ui.langMenu:IsShown())
local langs=0
for _,b in ipairs(ui.langRows) do if b:IsShown() and b.lang then langs=langs+1 end end
assert(langs==15)
local fr
for _,b in ipairs(ui.langRows) do if b.lang=="fr" then fr=b;break end end
assert(fr);fr:Click()
assert(H.db.language=="fr" and not ui.langMenu:IsShown())
print("PASS: foldable addon groups, Hub language first, native close on return, header language dropdown")
