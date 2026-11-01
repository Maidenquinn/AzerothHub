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
-- Labels must be real language names, not truncated UTF-8 garbage.
local en
for _,b in ipairs(ui.langRows) do if b.lang=="en" then en=b;break end end
assert(en and en.caption:GetText()=="English")
local pt
for _,b in ipairs(ui.langRows) do if b.lang=="pt" then pt=b;break end end
assert(pt and string.find(pt.caption:GetText(),"Portug",1,true))
local fr
for _,b in ipairs(ui.langRows) do if b.lang=="fr" then fr=b;break end end
assert(fr);fr:Click()
assert(H.db.language=="fr" and not ui.langMenu:IsShown())
assert(ui.search.placeholder:GetText()==H.T("Search for an addon..."))
assert(ui.profiles.titleLabel:GetText()==H.T("Your profiles"))
assert(ui.appearance.titleLabel:GetText()==H.T("Hub appearance"))
-- Switch to English: static chrome must follow (no leftover FR/PT).
local enBtn
for _,b in ipairs(ui.langRows) do if b.lang=="en" then enBtn=b;break end end
ui.langHeader:Click();assert(enBtn);enBtn:Click()
assert(H.db.language=="en")
assert(ui.search.placeholder:GetText()=="Search for an addon...")
assert(ui.optionSearch.placeholder:GetText()=="Search for a setting...")
assert(ui.profiles.titleLabel:GetText()=="Your profiles")
assert(ui.appearance.titleLabel:GetText()=="Hub appearance")
assert(ui.appearanceHelp:GetText()=="This choice is saved here. Changing profile does not change appearance.")
assert(string.find(ui.profile.caption:GetText(),"Current",1,true))
assert(not string.find(ui.search.placeholder:GetText(),"Buscar",1,true))
assert(not string.find(ui.profiles.titleLabel:GetText(),"Seus",1,true))
print("PASS: foldable addon groups, Hub language first, native close on return, header language dropdown")
