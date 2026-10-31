dofile("tests/mock.lua")
local long="Description volontairement tres longue pour verifier que le texte du reglage ne depasse jamais sur les boutons, les curseurs ou la valeur affichee a droite de la ligne."
FieldKitUI={sections={{id="display",title="Affichage",items={
 {id="alpha",kind="check",label="Transparence",tip=long,get=function() return true end,set=function() end},
 {id="beta",kind="slider",label="Echelle",min=0,max=100,step=1,get=function() return 40 end,set=function() end},
},windowTabs={{id="extra",title="Details",items={{id="nested",kind="check",label="Detail cache",get=function() return true end,set=function() end}}}}},
 {id="audio",title="Sons",items={{id="sound",kind="check",label="Activer les sons",get=function() return false end,set=function() end}}}}}
AzerothCursor={db={enabled=false,size=48,thickness=2,opacity=80,halo=20,crosshair=10,dot=4,pulse=false},
 CreateVisual=function(_,parent) local f=CreateFrame("Frame",nil,parent);f.ring=f:CreateTexture();f.halo=f:CreateTexture();return f end,
 Style=function() end,Apply=function() end}
T.Load();local H=AzerothHub
H.ToggleUI();local ui=AzerothHubWindow
local function left(f) return f.points[4] end
local function right(f) return f.points[4]+f:GetWidth() end
local function bottom(f) return -f.points[5]+f:GetHeight() end
local function overlaps(a,b)
 return left(a)<right(b) and left(b)<right(a) and -a.points[5]<bottom(b) and -b.points[5]<bottom(a)
end
H.selected="AzerothFieldKit";H.RefreshUI()
assert(ui.tabView:IsShown())
assert(string.find(ui.description:GetText(),H.profile,1,true))
assert(string.find(ui.description:GetText(),">",1,true))
assert(ui.options[1].value:GetWidth()>=64)
local tip
for _,row in ipairs(ui.options) do if row:IsShown() and row.option and row.option.tip==long then tip=row.section:GetText() end end
assert(tip and string.len(tip)<string.len(long) and string.find(tip,"...",1,true))
ui.optionSearch:SetText("Detail");H.RefreshUI()
assert(string.find(ui.options[1].section:GetText(),"Affichage > Details",1,true))
ui.optionSearch:SetText("");H.RefreshUI()
H.selected="AzerothCursor";H.RefreshUI();local frames=table.getn(T.all)
for _,mode in ipairs({"grimoire","atelier","compact"}) do
 H.SetAppearance(mode);H.selected="AzerothCursor";H.RefreshUI()
 assert(ui.cursorPreview:IsShown())
 assert(right(ui.optionView)<=left(ui.cursorPreview))
 assert(right(ui.cursorPreview)<=ui:GetWidth()-8)
 assert(right(ui.details)<=left(ui.peek))
 assert(right(ui.peek)<=left(ui.original))
 assert(right(ui.original)<=ui:GetWidth()-8)
 assert(bottom(ui.optionPages)<=-ui.gather.points[5]+1)
 assert(ui.header.points[4]+ui.header:GetWidth()<ui.styleButton.points[4])
 assert(ui.header.points[4]+ui.header:GetWidth()<ui.close.points[4])
 if ui.drag:IsShown() then
  assert(right(ui.drag)<=left(ui.styleButton))
  assert(not overlaps(ui.drag,ui.styleButton) and not overlaps(ui.drag,ui.close))
  if ui.profile:IsShown() then assert(right(ui.profile)<=left(ui.drag)) end
  if ui.manage:IsShown() then assert(right(ui.manage)<=left(ui.drag)) end
 end
 if ui.profile:IsShown() then assert(right(ui.header)<=left(ui.profile)) end
 if ui.manage:IsShown() then assert(right(ui.manage)<left(ui.styleButton)) end
 for _,row in ipairs(ui.options) do
  assert(bottom(row.title)<=row:GetHeight() and bottom(row.section)<=row:GetHeight())
  for _,c in ipairs({row.toggle,row.choice,row.slider,row.minus,row.plus,row.value}) do
   assert(left(c)>=0 and right(c)<=row:GetWidth()-10)
   assert(-c.points[5]>=0 and bottom(c)<=row:GetHeight())
  end
 end
end
assert(table.getn(T.all)==frames)
H.SetAppearance("compact")
assert(not ui.addons:IsShown())
ui.profile:Click();assert(ui.profiles:IsShown() and not ui.addons:IsShown())
ui.shade:Click();ui.manage:Click();assert(ui.addons:IsShown() and not ui.profiles:IsShown())
H.SetAppearance("grimoire");assert(not ui.manage:IsShown() and not ui.categoryButton:IsShown())
for _,size in ipairs({{800,600},{1024,768},{1920,1080}}) do
 UIParent:SetWidth(size[1]);UIParent:SetHeight(size[2]);H.LayoutManager();H.RefreshUI()
 local scale=ui:GetEffectiveScale()
 assert(scale<=1 and ui:GetWidth()*scale<=size[1] and ui:GetHeight()*scale<=size[2])
 if size[1]<ui:GetWidth() then assert(scale<1) end
end
local huge="Configuration personnelle beaucoup trop longue"
H.db.profiles[huge]=H.Clone(H.db.profiles[H.profile])
assert(H.UseConfigProfile(huge));H.RefreshUI()
local cap=ui.profile.caption:GetText()
assert(string.len(cap)<string.len("Profil : "..huge) and string.find(cap,"...",1,true))
H.message=nil;H.needsReload=true;H.RefreshUI()
assert(ui.reload:IsShown() and string.find(string.lower(ui.status:GetText()),"rechargement",1,true))
H.needsReload=nil;H.RefreshUI();assert(not ui.reload:IsShown())
ui.profile.points=nil;ui.manage.points=nil
assert(H.SetAppearance("compact"));assert(ui.drag:IsShown() and ui.manage:IsShown())
assert(H.SetAppearance("grimoire"));assert(ui.drag:IsShown() and not ui.manage:IsShown())
assert(T.writes==0 and T.reloads==0)
print("PASS: hierarchy, clipped text, separated hit rectangles, preview column, scales, reload affordance")
