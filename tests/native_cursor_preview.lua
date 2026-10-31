dofile("tests/mock.lua")
-- Run the actual installed renderer, not a substitute preview implementation.
assert(loadfile(assert(arg[1])))()
local A=AzerothCursor
AzerothCursorDB={schema=2,enabled=false,size=64,thickness=2,opacity=100,halo=45,crosshair=24,dot=5,pulse=false}
A.InitDB();A.visual=A.CreateVisual("NativeCursor",UIParent);A.visual:Hide()
local original=A.CreateVisual("OriginalCursorPreview",UIParent);A.preview=original
SlashCmdList.AZEROTHCURSOR=function() end
T.Load();local H=AzerothHub
H.ToggleUI();local ui=AzerothHubWindow
H.selected="AzerothCursor";H.RefreshUI()
local p=ui.cursorPreview
assert(p:IsShown() and p.visual and p.visual:GetParent()==p)
assert(p.visual.ring:GetWidth()==64 and A.preview==original)
assert(A.db.enabled==false and not A.visual:IsShown())
local function row(id)
 local terms={size="Diametre",opacity="Opacite"}
 ui.optionSearch:SetText(terms[id] or id)
 for _,r in ipairs(ui.options) do if r:IsShown() and r.option and r.option.id==id then return r end end
 error("Missing visible option "..id)
end
row("size").plus:Click()
assert(A.db.size==65 and p.visual.ring:GetWidth()==65 and original.ring:GetWidth()==65)
assert(H.db.profiles[H.profile].settings.AzerothCursor.size==65)
assert(A.db.enabled==false) -- a preview is not an implicit activation
row("opacity").slider:SetValue(70)
assert(p.visual.ring.color[4]==.7 and row("opacity").value:GetText()=="70 %")
assert(H.FormatOptionValue({unit="%",displayScale=100},.85)=="85 %")
local count=table.getn(T.all)
for _,mode in ipairs({"atelier","compact","grimoire"}) do
 H.SetAppearance(mode);assert(ui.cursorPreview.visual==p.visual and A.preview==original)
 assert(table.getn(T.all)==count)
 for _,r in ipairs(ui.options) do
  for _,c in ipairs({r.minus,r.plus,r.slider,r.value}) do
   assert(c.points[4]>=0 and c.points[4]+c:GetWidth()<=r:GetWidth()-10)
  end
 end
end
H.PeekInGame();assert(not ui:IsShown() and ui.returnBar:IsShown())
ui.returnButton:Click();assert(ui:IsShown() and not ui.returnBar:IsShown())
assert(H.selected=="AzerothCursor" and ui.cursorPreview.visual==p.visual)
local before=H.profile
assert(H.UseConfigProfile("Coop"));H.RefreshUI();assert(p.visual.ring:GetWidth()==64)
assert(H.UseConfigProfile(before));H.RefreshUI();assert(p.visual.ring:GetWidth()==65)
p.activate:Click();assert(A.db.enabled==true)
p.activate:Click();assert(A.db.enabled==false)
local pulse
for _,o in ipairs(H.Options("AzerothCursor")) do if o.id=="pulse" then pulse=o end end
assert(H.SetOption(pulse,true));H.RefreshUI();p:GetScript("OnUpdate")()
assert(p.visual.halo:GetAlpha()~=1)
assert(T.writes==0 and T.reloads==0 and A.preview==original)
print("PASS: installed Cursor renderer, disabled preview without activation, live size/opacity/pulse, native preview preserved, profile round trip, three layouts, peek and return")
