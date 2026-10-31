local H=AzerothHub
local ui
local styles={
 grimoire={name="Grimoire",w=1120,h=740,bg={.105,.09,.07},panel={.15,.13,.10},field={.075,.07,.055},line={.32,.27,.19},accent={.83,.68,.42},text={.94,.89,.79}},
 atelier={name="Atelier",w=1280,h=740,bg={.10,.125,.14},panel={.14,.17,.19},field={.075,.095,.11},line={.25,.31,.33},accent={.56,.77,.70},text={.91,.95,.94}},
 compact={name="Compact",w=840,h=680,bg={.115,.115,.125},panel={.16,.16,.175},field={.08,.08,.09},line={.29,.28,.27},accent={.83,.67,.43},text={.94,.92,.88}},
}
H.appearances=styles
local surfaces,labels,buttons={},{},{}
local function theme() return styles[H.db and H.db.appearance or "grimoire"] or styles.grimoire end
local function put(f,s) if f.caption then f.caption:SetText(s or "") else f:SetText(s or "") end end
local function place(f,parent,x,y,w,h)
 f:ClearAllPoints();f:SetPoint("TOPLEFT",parent,"TOPLEFT",x,-y)
 if w then f:SetWidth(w) end;if h then f:SetHeight(h) end
 if w and f.caption then f.caption:SetWidth(math.max(8,w-16)) end
 if w and f.placeholder then f.placeholder:SetWidth(math.max(8,w-16)) end
end
local function show(f,on) if on then f:Show() else f:Hide() end end
local function paint(f)
 local t=theme();local c=t[f.hubSurface or "panel"] or t.panel
 f:SetBackdropColor(c[1],c[2],c[3],1)
 local edge=f.hubSelected and t.accent or t.line;f:SetBackdropBorderColor(edge[1],edge[2],edge[3],1)
end
local function surface(f,kind)
 f.hubSurface=type(kind)=="string" and kind or "panel"
 f:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})
 table.insert(surfaces,f);paint(f)
end
local function label(parent,x,y,w,h,text,size,role)
 local f=parent:CreateFontString(nil,"OVERLAY");f.hubSize=size or 12;f.hubRole=role or "text"
 f:SetFont("Fonts\\FRIZQT__.TTF",f.hubSize);place(f,parent,x,y,w,h)
 f:SetJustifyH("LEFT");f:SetJustifyV("MIDDLE");f:SetText(text or "")
 table.insert(labels,f);return f
end
local function button(parent,x,y,w,h,text,fn)
 local b=CreateFrame("Button",nil,parent);place(b,parent,x,y,w,h);surface(b,"field")
 local captionHeight=h<=36 and 18 or h-16
 b.caption=label(b,8,(h-captionHeight)/2,w-16,captionHeight,text or "",12);b.caption:SetJustifyH("CENTER")
 b:SetScript("OnClick",fn)
 b:SetScript("OnEnter",function() local c=theme().accent;b:SetBackdropBorderColor(c[1],c[2],c[3],1) end)
 b:SetScript("OnLeave",function() paint(b) end)
 table.insert(buttons,b);return b
end
local function edit(parent,x,y,w,callback,hint)
 local f=CreateFrame("EditBox",nil,parent);place(f,parent,x,y,w,28);surface(f,"field")
 f:SetFont("Fonts\\FRIZQT__.TTF",12);f:SetAutoFocus(false);f:SetMaxLetters(64)
 if f.SetTextInsets then f:SetTextInsets(8,8,0,0) end
 f:SetScript("OnEscapePressed",function() f:ClearFocus() end)
 if hint then f.placeholder=label(f,8,0,w-16,28,hint,11,"muted") end
 if callback then f:SetScript("OnTextChanged",function() if ui and ui.ready then callback() end end) end
 return f
end
local function skin()
 local t=theme()
 for _,f in ipairs(surfaces) do paint(f) end
 for _,f in ipairs(labels) do
  local c=f.hubRole=="accent" and t.accent or f.hubRole=="muted" and {.66,.66,.63} or t.text
  if f.SetTextColor then f:SetTextColor(c[1],c[2],c[3]) end
  f:SetFont(f.hubRole=="heading" and H.db.appearance=="grimoire" and "Fonts\\MORPHEUS.TTF" or "Fonts\\FRIZQT__.TTF",f.hubSize)
 end
end
H.NativeUI={surface=surface,label=label,button=button,put=put}
function H.DisplayTitle(r)
 return string.gsub(r.title or r.name or "","%s*%b()","")
end
local function names()
 local out={};for n in pairs(H.db.profiles) do table.insert(out,n) end;table.sort(out);return out
end
local function result(ok,err) if not ok then H.Say(err or "Action indisponible") end;H.RefreshUI() end
function H.FormatOptionValue(o,v)
 if not H.Number(v) then return tostring(v) end
 local n=math.floor(v*(o.displayScale or 1)*100+.5)/100
 return string.format("%g",n)..(o.unit and (" "..o.unit) or "")
end
local function previewAvailable()
 local a=getglobal("AzerothCursor")
 return H.selected=="AzerothCursor" and type(a)=="table" and type(a.db)=="table" and type(a.CreateVisual)=="function" and type(a.Style)=="function"
end
local function fit(text,width,size)
 text=tostring(text or "")
 local maxc=math.max(4,math.floor((width or 40)/(math.max(size or 12,8)*0.5)))
 if string.len(text)<=maxc then return text end
 return string.sub(text,1,maxc-3).."..."
end
local function updatePreview()
 local p=ui.cursorPreview
 if not previewAvailable() then p:Hide();return end
 p:Show();local a=AzerothCursor;local ph=p:GetHeight()
 local function unavailable(msg)
  if p.visual then p.visual:Hide() end
  show(p.note,true);place(p.note,p,8,28,184,36);p.note:SetText(msg)
 end
 if not p.visual then
  local ok,v=H.Call(a.CreateVisual,nil,p)
  if not ok or not v then unavailable("Apercu indisponible dans cette version.");return end
  p.visual=v
 end
 local ok=H.Call(a.Style,p.visual)
 if not ok then unavailable("Apercu indisponible dans cette version.");return end
 local d=a.db;local extent=math.max(d.size*1.8,d.crosshair*2+16,d.dot*2,1)
 local reserve=ph>=240 and 112 or 74
 local room=math.max(28,ph-reserve-22)
 local scale=math.min(1,(room-4)/extent)
 local half=extent*scale/2
 local visualY=math.max(24+half,22+math.floor(room/2))
 p.visual:ClearAllPoints();p.visual:SetPoint("CENTER",p,"TOP",0,-visualY)
 p.visual:SetScale(scale);p.visual:Show()
 p.pointer:ClearAllPoints();p.pointer:SetPoint("CENTER",p,"TOP",10,-(visualY+10))
 show(p.note,ph>=240)
 if ph>=240 then place(p.note,p,8,ph-104,184,22);p.note:SetText("Taille reelle : "..tostring(d.size).." px") end
 place(p.state,p,8,ph-74,184,24)
 place(p.activate,p,8,ph-36,184,26)
 p.state:SetText(d.enabled and "Actif en jeu." or "Inactif en jeu. L'apercu ne l'active pas.")
 put(p.activate,d.enabled and "Desactiver" or "Activer en jeu")
 if p.visual.halo then p.visual.halo:SetAlpha(d.pulse and (.72+.28*math.sin((GetTime and GetTime() or 0)*4)) or 1) end
end
function H.PeekInGame()
 H.HideManager();ui.returnBar:Show()
end
function H.HideManager()
 if ui then
  ui:Hide();ui.profiles:Hide();ui.appearance:Hide();ui.categories:Hide();ui.shade:Hide();ui.returnBar:Hide()
  if ui.tipOwned and GameTooltip then GameTooltip:Hide();ui.tipOwned=nil end
 end
end
function H.LaunchAddon(name,right)
 H.HideManager()
 for _,r in pairs(H.buttons) do if r.addon==name then return H.LaunchButton(r,right) end end
 return H.Open(name)
end
local translations={book="Livre",Reading="Lecture",Book="Livre",Wishlist="Liste de souhaits",wish="Liste de souhaits",Window="Affichage",Contents="Contenu",warn="Alertes",Display="Affichage",Colours="Couleurs",Sounds="Sons",General="General",Windows="Fenetres",Layout="Disposition",Coop="Cooperation"}
local optionLabels={Font="Police",Language="Langue",["Book size"]="Taille du livre",["Wishlist window"]="Afficher la liste de souhaits",Locked="Verrouiller la position",["Wishlist size"]="Taille de la liste",["Wishlist opacity"]="Opacite de la liste",["Spell tracker"]="Suivi des sorts",Warnings="Avertissements",["Boss in the wishlist"]="Boss dans la liste",["Boss warnings"]="Alertes de boss",["Guardians and waves"]="Gardiens et vagues",["Small notices"]="Petites notifications",["Boss appears in 10 sec."]="Apparition du boss",["Phase change"]="Changement de phase",["Hero down (co-op)"]="Allie a terre (coop)"}
local function section(s)
 s=s or "General";local out={}
 for part in string.gfind(s,"[^/]+") do part=string.gsub(string.gsub(part,"^%s+",""),"%s+$","");table.insert(out,translations[part] or part) end
 return table.concat(out," / ")
end
local function wheel(f,fn)
 if f.EnableMouseWheel then f:EnableMouseWheel(true);f:SetScript("OnMouseWheel",function() fn(arg1 or 0) end) end
end
local function move(kind,delta)
 local key=kind=="addons" and "addonOffset" or "optionOffset"
 ui[key]=math.max(0,(ui[key] or 0)+delta);H.RefreshUI()
end
local function scrollBar(parent,kind)
 local s=CreateFrame("Slider",nil,parent);s:SetOrientation("VERTICAL");s:SetWidth(14);surface(s,"field")
 s:SetThumbTexture("Interface\\Buttons\\UI-ScrollBar-Knob");s:SetValueStep(1)
 if s.GetThumbTexture then local thumb=s:GetThumbTexture();if thumb then thumb:SetWidth(14);thumb:SetHeight(28) end end
 s:SetScript("OnValueChanged",function()
  if ui.rendering then return end
  local key=kind=="addons" and "addonOffset" or "optionOffset"
  -- This client's vertical slider places its minimum at the top.
  ui[key]=math.floor(s:GetValue()+.5);H.RefreshUI()
 end)
 wheel(s,function(d) move(kind,-d) end);return s
end
local function updateBar(s,n,count,offset)
 s.limit=math.max(0,n-count);s:SetMinMaxValues(0,math.max(1,s.limit));s:SetValue(offset)
 show(s,s.limit>0)
end
local function selectAddon(name)
 H.selected=name;ui.optionOffset=0;ui.category=nil;ui.page=nil;ui.tabOffset=0;ui.closed={};ui.categories:Hide()
 if H.db.appearance=="compact" then ui.addons:Hide() end
 ui.optionSearch:SetText("");H.RefreshUI()
end
function H.SetAppearance(mode)
 if not styles[mode] then return false,"Presentation inconnue" end
 H.db.appearance=mode
 if ui then ui.appearance:Hide();ui.categories:Hide();ui.profiles:Hide();ui.shade:Hide();ui.nameEdit:ClearFocus();H.LayoutManager();H.RefreshUI() end
 return true
end
function H.ShowAppearance()
 ui.profiles:Hide();ui.categories:Hide();if H.db.appearance=="compact" then ui.addons:Hide() end
 ui.shade:Show();ui.appearance:Show();skin()
end
local function showProfiles()
 ui.categories:Hide();ui.appearance:Hide();if H.db.appearance=="compact" then ui.addons:Hide() end
 show(ui.profiles,not ui.profiles:IsShown());show(ui.shade,ui.profiles:IsShown());H.RefreshUI()
end
local function categoryMenu()
 ui.categories.offset=ui.categories.offset or 0
 show(ui.categories,not ui.categories:IsShown());H.RefreshUI()
end
local function placeBody()
 local t=theme();local mode=H.db.appearance;local w=t.w
 local top,bottom=ui.bodyTop,ui.bodyBottom
 local mx,mw=ui.mainX,ui.mainW
 local pages=ui.pageList or {}
 local showTabs=table.getn(pages)>1
 show(ui.tabView,showTabs);show(ui.categoryButton,false)
 show(ui.hint,false);show(ui.saved,false);show(ui.subtitle,false)
 local y=top
 place(ui.description,ui,mx,y,mw,16);y=y+20
 local titleW=math.max(80,mw-300)
 place(ui.details,ui,mx,y,titleW,24)
 place(ui.peek,ui,w-286,y,96,24)
 place(ui.original,ui,w-182,y,170,24)
 y=y+32
 if showTabs then place(ui.tabView,ui,mx,y,mw,28);y=y+34 end
 local arrows=showTabs and table.getn(pages)>3
 local inset=arrows and 26 or 0
 local tabWidth=math.floor(math.max(36,(mw-inset*2-8)/3))
 for i,b in ipairs(ui.tabs) do place(b,ui.tabView,inset+(i-1)*(tabWidth+4),1,tabWidth,26) end
 place(ui.tabPrev,ui.tabView,0,1,22,26);place(ui.tabNext,ui.tabView,mw-22,1,22,26)
 place(ui.optionSearch,ui,mx,y,mw,26);y=y+32
 local preview=previewAvailable();local gap=preview and 216 or 0;local contentW=math.max(160,mw-gap)
 local listRoom=math.max(46,bottom-y-28);local rowH=46
 ui.optionCount=math.min(12,math.max(1,math.floor(listRoom/rowH)))
 local listH=ui.optionCount*rowH
 local viewW=contentW-20;local rowW=math.max(180,viewW-16);ui.rowW=rowW;ui.labelW=120
 place(ui.optionView,ui,mx,y,viewW,listH)
 place(ui.optionBar,ui,mx+viewW+4,y,12,listH)
 place(ui.empty,ui,mx+8,y+12,math.max(80,viewW-24),40)
 local valueW,btn=72,22;local right=rowW-10
 local sliderW=math.min(150,math.max(48,math.floor(rowW*0.22)))
 local block=btn+6+sliderW+6+btn+6+valueW;local left=right-block
 if left<100 then sliderW=math.max(36,sliderW-(100-left));block=btn+6+sliderW+6+btn+6+valueW;left=right-block end
 if left<8 then left=8 end
 ui.labelW=math.max(40,left-14)
 for i,r in ipairs(ui.options) do
  place(r,ui.optionView,0,(i-1)*rowH,rowW,rowH-4)
  place(r.title,r,8,2,ui.labelW,18);place(r.section,r,8,20,ui.labelW,16)
  place(r.toggle,r,left,7,block,26);place(r.choice,r,left,7,block,26)
  place(r.minus,r,left,7,btn,26);place(r.slider,r,left+btn+6,12,sliderW,16)
  place(r.plus,r,left+btn+6+sliderW+6,7,btn,26);place(r.value,r,right-valueW,7,valueW,26)
 end
 place(ui.optionPrev,ui,mx,y+listH+4,24,22)
 place(ui.optionNext,ui,mx+28,y+listH+4,24,22)
 place(ui.optionPages,ui,mx+58,y+listH+4,200,22)
 show(ui.cursorPreview,preview)
 place(ui.cursorPreview,ui,mx+contentW+8,y,200,listH)
 place(ui.cursorPreview.activate,ui.cursorPreview,8,math.max(28,listH-36),184,26)
 place(ui.categories,ui,mx+math.max(0,mw-320),y+30,300,250)
end
function H.LayoutManager()
 local t=theme();local mode=H.db.appearance;local compact=mode=="compact";local atelier=mode=="atelier"
 local w,h=t.w,t.h;ui:SetWidth(w);ui:SetHeight(h)
 local sw,sh=UIParent:GetWidth() or 0,UIParent:GetHeight() or 0
 if sw>64 and sh>64 then ui:SetScale(math.min(1,(sw-32)/w,(sh-32)/h)) else ui:SetScale(1) end
 place(ui.header,ui,0,0,216,48);place(ui.title,ui.header,12,8,190,30)
 place(ui.close,ui,w-40,10,28,28);place(ui.styleButton,ui,w-156,10,108,28)
 place(ui.profile,ui,228,10,compact and 172 or 206,28)
 place(ui.manage,ui,408,10,compact and 214 or 28,28)
 show(ui.profile,not atelier);show(ui.manage,compact)
 show(ui.hint,false);show(ui.saved,false);show(ui.subtitle,false)
 local dragL=216
 if ui.profile:IsShown() then dragL=math.max(dragL,ui.profile.points[4]+ui.profile:GetWidth()+8) end
 if ui.manage:IsShown() then dragL=math.max(dragL,ui.manage.points[4]+ui.manage:GetWidth()+8) end
 local dragR=w-164
 if dragR-dragL>20 then place(ui.drag,ui,dragL,0,dragR-dragL,48);show(ui.drag,true) else show(ui.drag,false) end
 local top,bottom=56,h-44;ui.bodyTop,ui.bodyBottom=top,bottom
 show(ui.profileRail,atelier);place(ui.profileRail,ui,10,top,168,bottom-top)
 for i,b in ipairs(ui.railProfiles) do place(b,ui.profileRail,8,32+(i-1)*38,152,34) end
 place(ui.railManage,ui.profileRail,8,bottom-top-42,152,30)
 local ax,aw=atelier and 188 or 12,atelier and 236 or 248
 if compact then
  place(ui.addons,ui,12,52,320,math.min(460,h-78));ui.addons:SetFrameStrata("FULLSCREEN_DIALOG");ui.addons:Hide()
 else place(ui.addons,ui,ax,top,aw,bottom-top);ui.addons:SetFrameStrata("DIALOG");ui.addons:Show() end
 local ah,arw=ui.addons:GetHeight(),ui.addons:GetWidth()
 place(ui.count,ui.addons,10,6,arw-24,18);place(ui.search,ui.addons,10,28,arw-20,26)
 local listY,rowH=62,38
 ui.addonCount=math.min(12,math.max(1,math.floor((ah-listY-30)/rowH)))
 local listH=ui.addonCount*rowH
 place(ui.addonView,ui.addons,8,listY,arw-22,listH)
 for i,r in ipairs(ui.rows) do
  place(r,ui.addonView,0,(i-1)*rowH,arw-40,rowH-4)
  place(r.title,r,8,1,arw-56,16);place(r.state,r,8,17,arw-56,14)
 end
 place(ui.addonBar,ui.addons,arw-16,listY,12,listH)
 place(ui.addonPrev,ui.addons,8,listY+listH+4,24,22)
 place(ui.addonNext,ui.addons,arw-32,listY+listH+4,24,22)
 place(ui.pages,ui.addons,36,listY+listH+4,math.max(40,arw-76),22)
 ui.mainX=compact and 12 or ax+aw+12;ui.mainW=w-ui.mainX-12;ui.previewFor=H.selected
 place(ui.gather,ui,12,h-34,176,24);place(ui.status,ui,196,h-36,math.max(40,w-392),26)
 place(ui.reload,ui,w-184,h-34,172,24)
 placeBody();skin()
end
function H.RefreshUI()
 if not ui or not ui.ready or ui.rendering then return end
 if ui.previewFor~=H.selected then H.LayoutManager() end
 if not H.draft then H.SelectProfile(H.profile) end
 ui.rendering=true
 for _,f in ipairs({ui.search,ui.optionSearch,ui.nameEdit}) do if f.placeholder then show(f.placeholder,(f:GetText() or "")=="") end end
 local addonTitle=H.byName[H.selected or ""] and H.DisplayTitle(H.byName[H.selected]) or "Choisir"
 put(ui.profile,fit("Profil : "..H.profile,ui.profile:GetWidth()-16,12))
 put(ui.manage,fit("Addon : "..addonTitle,ui.manage:GetWidth()-16,12))
 ui.manage:SetScript("OnClick",function() if H.db.appearance=="compact" then show(ui.addons,not ui.addons:IsShown()) else showProfiles() end end)
 if ui.nameProfile~=H.profile then ui.nameProfile=H.profile;ui.nameEdit:SetText("") end
 local ns=names();ui.profileOffset=math.max(0,math.min(ui.profileOffset or 0,math.max(0,table.getn(ns)-6)))
 for i,b in ipairs(ui.profileRows) do
  local name=ns[ui.profileOffset+i];show(b,name~=nil);b.profile=name
  if name then b.hubSelected=name==H.profile;put(b,fit(name..(name==H.profile and " - actif" or ""),b:GetWidth()-16,12));paint(b) end
 end
 for i,b in ipairs(ui.railProfiles) do
  local name=ns[i];show(b,name~=nil);b.profile=name
  if name then b.hubSelected=name==H.profile;put(b,fit(name,b:GetWidth()-16,12));paint(b) end
 end
 local shownRails=0;for _,b in ipairs(ui.railProfiles) do if b:IsShown() then shownRails=shownRails+1 end end
 place(ui.railManage,ui.profileRail,8,math.min(ui.profileRail:GetHeight()-42,32+shownRails*38+6),152,30)
 local rows={};local q=string.lower(ui.search:GetText() or "")
 for _,r in ipairs(H.rows) do if q=="" or string.find(string.lower(r.name.." "..r.title),q,1,true) then table.insert(rows,r) end end
 ui.filteredRows=rows;ui.addonOffset=math.max(0,math.min(ui.addonOffset or 0,math.max(0,table.getn(rows)-ui.addonCount)))
 ui.count:SetText("Addons  "..table.getn(H.rows))
 for i,row in ipairs(ui.rows) do
  local r=i<=ui.addonCount and rows[ui.addonOffset+i] or nil;show(row,r~=nil);row.addon=r and r.name
  if r then
   local n=table.getn(H.Options(r.name))
   row.title:SetText(fit(H.DisplayTitle(r),row.title:GetWidth(),12))
   row.state:SetText(r.loaded and (n>0 and "Charge" or "Options d'origine") or "Installe")
   row.hubSelected=H.selected==r.name;paint(row)
  end
 end
 updateBar(ui.addonBar,table.getn(rows),ui.addonCount,ui.addonOffset)
 ui.pages:SetText(table.getn(rows)==0 and "Aucun addon" or ((ui.addonOffset+1).."-"..math.min(table.getn(rows),ui.addonOffset+ui.addonCount).." / "..table.getn(rows)))
 local r=H.byName[H.selected or ""];local opts=r and H.Options(r.name) or {};local pages,pageSeen={},{}
 if ui.navigationFor~=H.selected then ui.navigationFor=H.selected;ui.page=nil;ui.category=nil;ui.closed={};ui.tabOffset=0;ui.optionOffset=0 end
 for _,o in ipairs(opts) do
  local key=o.page or "general"
  if not pageSeen[key] then pageSeen[key]={key=key,label=section(o.pageLabel or "General")};table.insert(pages,pageSeen[key]) end
 end
 if not pageSeen[ui.page or ""] then ui.page=pages[1] and pages[1].key end
 ui.pageList=pages;ui.tabOffset=math.max(0,math.min(ui.tabOffset or 0,math.max(0,table.getn(pages)-3)))
 placeBody()
 local pageLabel="General"
 for _,p in ipairs(pages) do if p.key==ui.page then pageLabel=p.label end end
 for i,b in ipairs(ui.tabs) do
  local p=pages[ui.tabOffset+i];b.page=p and p.key;show(b,p~=nil and table.getn(pages)>1)
  if p then put(b,fit(p.label,b:GetWidth()-12,12));b.hubSelected=p.key==ui.page;paint(b) end
 end
 show(ui.tabPrev,table.getn(pages)>3 and ui.tabOffset>0);show(ui.tabNext,table.getn(pages)>3 and ui.tabOffset+3<table.getn(pages))
 q=string.lower(ui.optionSearch:GetText() or "")
 local cats,seen={},{}
 for _,o in ipairs(opts) do if q~="" or (o.page or "general")==ui.page then local s=section(o.section);if not seen[s] then table.insert(cats,s);seen[s]=true end end end
 ui.categoryList=cats
 if ui.category and not seen[ui.category] then ui.category=nil end
 ui.categories.offset=math.max(0,math.min(ui.categories.offset or 0,math.max(0,table.getn(cats)-7)))
 for i,b in ipairs(ui.categoryRows) do
  local name=i==1 and "Toutes les sections" or cats[ui.categories.offset+i-1]
  b.category=i~=1 and name or nil;show(b,name~=nil);if name then put(b,fit(name,b:GetWidth()-16,12)) end
 end
 local filtered,last={},nil
 for _,o in ipairs(opts) do
  local s=section(o.section);local title=optionLabels[o.label] or o.label or o.id
  if (q~="" or (o.page or "general")==ui.page) and (q~="" or not ui.category or ui.category==s) and (q=="" or string.find(string.lower(title.." "..s.." "..section(o.pageLabel)),q,1,true)) then
   local group=(o.page or "general").."/"..s
   if q=="" and (table.getn(cats)>1 or H.db.appearance=="compact" or ui.closed[group]) and last~=group then table.insert(filtered,{header=true,section=s,group=group});last=group end
   if not ui.closed[group] or q~="" then table.insert(filtered,o) end
  end
 end
 ui.filteredOptions=filtered;ui.optionOffset=math.max(0,math.min(ui.optionOffset or 0,math.max(0,table.getn(filtered)-ui.optionCount)))
 local hits=0;for _,o in ipairs(filtered) do if not o.header then hits=hits+1 end end
 local crumb
 if not r then crumb="Choisir un addon"
 elseif q~="" then crumb=hits.." resultat"..(hits>1 and "s" or "").."  >  tous les onglets"
 elseif table.getn(opts)==0 then crumb=H.profile.."  >  "..addonTitle.."  >  options d'origine"
 elseif table.getn(pages)<=1 then crumb=H.profile.."  >  "..addonTitle
 else crumb=H.profile.."  >  "..addonTitle.."  >  "..pageLabel end
 ui.description:SetText(fit(crumb,ui.description:GetWidth(),11))
 ui.details:SetText(fit(r and addonTitle or "Choisir un addon",ui.details:GetWidth(),16))
 show(ui.empty,table.getn(filtered)==0)
 ui.empty:SetText(q~="" and "Aucun reglage trouve." or (table.getn(opts)==0 and "Utiliser Options d'origine." or "Section vide."))
 H.refreshing=true
 for i,row in ipairs(ui.options) do
  local o=i<=ui.optionCount and filtered[ui.optionOffset+i] or nil;show(row,o~=nil);row.option=o
  row.toggle:Hide();row.choice:Hide();row.slider:Hide();row.minus:Hide();row.plus:Hide();row.value:SetText("")
  if o and o.header then
   row.hubSelected=true;place(row.title,row,8,10,ui.labelW,20);row.section:SetText("")
   row.title:SetText(fit((ui.closed[o.group] and "+  " or "-  ")..o.section,ui.labelW,13));paint(row)
  elseif o then
   row.hubSelected=false;paint(row)
   local label=optionLabels[o.label] or o.label or o.id
   local detail=""
   if q~="" then local page,sec=section(o.pageLabel),section(o.section);detail=page==sec and page or (page.." > "..sec)
   elseif o.reload then detail="Apres rechargement"
   elseif type(o.tip)=="string" and o.tip~="" and o.tip~=label then detail=o.tip end
   if detail=="" then place(row.title,row,8,10,ui.labelW,20);row.section:SetText("")
   else place(row.title,row,8,2,ui.labelW,18);place(row.section,row,8,20,ui.labelW,16);row.section:SetText(fit(detail,ui.labelW,10)) end
   row.title:SetText(fit(label,ui.labelW,13))
   local ok,v=H.Call(o.get)
   if ok and H.Valid(o,v) then
    if o.kind=="check" then put(row.toggle,v and "Active" or "Inactif");row.toggle.hubSelected=v;paint(row.toggle);row.toggle:Show()
    elseif o.kind=="choice" then put(row.choice,fit(tostring(o.values[v]).."  >",row.choice:GetWidth()-12,12));row.choice:Show()
    elseif o.kind=="slider" then
     local low=o.min or 0;if o.minimum then local valid,n=H.Call(o.minimum);if valid and H.Number(n) then low=n end end
     row.slider:SetMinMaxValues(low,o.max);row.slider:SetValueStep(o.step or 1);row.slider:SetValue(v);row.slider:Show()
     row.minus:Show();row.plus:Show();row.value:SetText(fit(H.FormatOptionValue(o,v),row.value:GetWidth(),11))
    end
   else row.value:SetText("N/D") end
  end
 end
 H.refreshing=false
 if previewAvailable() then updatePreview() end
 updateBar(ui.optionBar,table.getn(filtered),ui.optionCount,ui.optionOffset)
 local n=table.getn(filtered)
 ui.optionPages:SetText(n==0 and "" or ((ui.optionOffset+1).."-"..math.min(n,ui.optionOffset+ui.optionCount).." / "..n))
 put(ui.gather,H.db.gather and "Minimap regroupee" or "Minimap separee")
 local note=H.error or H.message or ""
 if note=="" and H.needsReload then note="Certains reglages attendent un rechargement." end
 ui.status:SetText(fit(note,ui.status:GetWidth(),10))
 show(ui.reload,H.needsReload);put(ui.reload,"Recharger l'interface")
 for mode,b in pairs(ui.styleChoices) do b.hubSelected=H.db.appearance==mode;paint(b) end
 ui.rendering=nil
end
local function makeDialog(name,w,h,title)
 local f=CreateFrame("Frame",name,ui);f:SetWidth(w);f:SetHeight(h);f:SetPoint("CENTER",ui,"CENTER",0,0)
 f:SetFrameStrata("FULLSCREEN_DIALOG");if f.SetFrameLevel then f:SetFrameLevel(100) end;f:EnableMouse(true);surface(f,"panel")
 label(f,20,18,w-65,28,title,20,"heading");button(f,w-44,18,26,26,"X",function() f:Hide();ui.shade:Hide() end)
 f:Hide();return f
end
local function nudge(row,dir)
 local o=row.option;if not o or o.header then return end
 local ok,v=H.Call(o.get);if not ok then return end
 local low=o.min or 0;if o.minimum then local valid,n=H.Call(o.minimum);if valid and H.Number(n) then low=n end end
 local step=o.step or 1;v=math.floor((v+dir*step)/step+.5)*step
 result(H.SetOption(o,math.min(o.max,math.max(low,v))))
end
local function optionHint(f,row)
 f:SetScript("OnEnter",function()
  paint(f)
  local o=row.option;if not o or not GameTooltip then return end
  GameTooltip:SetOwner(f,"ANCHOR_RIGHT")
  if o.header then
   GameTooltip:SetText(o.section or "Section")
   GameTooltip:AddLine(ui.closed[o.group] and "Cliquer pour afficher ces reglages." or "Cliquer pour replier cette section.",.8,.8,.8,true)
   GameTooltip:Show();ui.tipOwned=true;return
  end
  GameTooltip:SetText(optionLabels[o.label] or o.label or o.id)
  if type(o.tip)=="string" then GameTooltip:AddLine(o.tip,1,1,1,true) end
  if o.kind=="slider" then GameTooltip:AddLine("De "..H.FormatOptionValue(o,o.min or 0).." a "..H.FormatOptionValue(o,o.max)..". Boutons - / + pour ajuster finement.",.8,.8,.8,true) end
  if o.reload then GameTooltip:AddLine("Ce reglage peut demander un rechargement.",1,.75,.3,true) end
  GameTooltip:Show();ui.tipOwned=true
 end)
 f:SetScript("OnLeave",function() paint(f);if ui.tipOwned and GameTooltip then GameTooltip:Hide();ui.tipOwned=nil end end)
end
local function build()
 ui=CreateFrame("Frame","AzerothHubWindow",UIParent);ui:SetPoint("CENTER",UIParent,"CENTER",0,0);ui:SetFrameStrata("DIALOG")
 if ui.SetFrameLevel then ui:SetFrameLevel(50) end
 if ui.SetClampedToScreen then ui:SetClampedToScreen(true) end
 if type(UISpecialFrames)=="table" then table.insert(UISpecialFrames,"AzerothHubWindow") end
 surface(ui,"bg");ui:EnableMouse(true);ui:SetMovable(true)
 ui.header=CreateFrame("Frame",nil,ui);ui.header:EnableMouse(true);ui.header:RegisterForDrag("LeftButton")
 ui.header:SetScript("OnDragStart",function() ui:StartMoving() end);ui.header:SetScript("OnDragStop",function() ui:StopMovingOrSizing() end)
 ui.drag=CreateFrame("Frame",nil,ui);ui.drag:EnableMouse(true);ui.drag:RegisterForDrag("LeftButton")
 ui.drag:SetScript("OnDragStart",function() ui:StartMoving() end);ui.drag:SetScript("OnDragStop",function() ui:StopMovingOrSizing() end)
 ui.title=label(ui.header,12,8,190,30,"Azeroth Hub",20,"heading")
 ui.subtitle=label(ui.header,12,32,8,8,"",11,"muted");ui.subtitle:Hide()
 ui.close=button(ui,0,0,28,28,"X",H.HideManager);ui.styleButton=button(ui,0,0,108,28,"Apparence",H.ShowAppearance)
 ui.saved=label(ui,0,0,8,8,"",11,"accent");ui.saved:Hide()
 ui.profile=button(ui,0,0,190,28,"Profil",showProfiles);ui.manage=button(ui,0,0,180,28,"Addon",showProfiles)
 ui.hint=label(ui,0,0,8,8,"",11,"muted");ui.hint:Hide()
 ui.profileRail=CreateFrame("Frame",nil,ui);surface(ui.profileRail,"field");label(ui.profileRail,10,6,148,22,"Profils",11,"accent")
 ui.railProfiles={};for i=1,8 do local b=button(ui.profileRail,0,0,148,36,"",function() end);b:SetScript("OnClick",function() if b.profile then result(H.UseConfigProfile(b.profile)) end end);ui.railProfiles[i]=b end
 ui.railManage=button(ui.profileRail,0,0,148,30,"Gerer les profils",showProfiles)
 ui.addons=CreateFrame("Frame",nil,ui);surface(ui.addons,"panel");ui.count=label(ui.addons,12,10,220,22,"MES ADDONS",11,"accent")
 ui.search=edit(ui.addons,0,0,200,function() ui.addonOffset=0;H.RefreshUI() end,"Rechercher un addon...")
 ui.addonView=CreateFrame("Frame",nil,ui.addons);ui.rows={}
 for i=1,12 do
  local row=button(ui.addonView,0,0,240,36,"",function() end);row.caption:Hide()
  row.title=label(row,0,0,200,16,"",12);row.state=label(row,0,0,200,14,"",10,"muted")
  row:SetScript("OnClick",function() if row.addon then selectAddon(row.addon) end end)
  wheel(row,function(d) move("addons",-d) end);ui.rows[i]=row
 end
 wheel(ui.addonView,function(d) move("addons",-d) end);wheel(ui.addons,function(d) move("addons",-d) end)
 ui.addonBar=scrollBar(ui.addons,"addons")
 ui.addonPrev=button(ui.addons,0,0,28,24,"<",function() move("addons",-ui.addonCount) end)
 ui.addonNext=button(ui.addons,0,0,28,24,">",function() move("addons",ui.addonCount) end)
 ui.pages=label(ui.addons,0,0,160,24,"",10,"muted");ui.pages:SetJustifyH("CENTER")
 ui.details=label(ui,0,0,400,24,"",16,"heading");ui.description=label(ui,0,0,650,16,"",11,"muted")
 ui.original=button(ui,0,0,200,28,"Options d'origine",function()
  if not H.selected then return end;local a=H.adapters[H.selected];H.HideManager()
  local ok,err
  if a and a.configure then ok,err=H.Call(a.configure) else ok,err=H.Open(H.selected) end
  if ok then ui.returnBar:Show() else H.Say(err or "Options indisponibles") end
 end)
 ui.peek=button(ui,0,0,118,28,"Voir en jeu",H.PeekInGame)
 ui.tabView=CreateFrame("Frame",nil,ui);ui.tabs={}
 local function shiftTabs(d) ui.tabOffset=math.max(0,(ui.tabOffset or 0)+d);H.RefreshUI() end
 wheel(ui.tabView,function(d) shiftTabs(-d) end)
 ui.tabPrev=button(ui.tabView,0,0,24,30,"<",function() shiftTabs(-1) end)
 ui.tabNext=button(ui.tabView,0,0,24,30,">",function() shiftTabs(1) end)
 for i=1,3 do
  local b=button(ui.tabView,0,0,160,30,"",function() end)
  b:SetScript("OnClick",function() if b.page then ui.page=b.page;ui.category=nil;ui.optionOffset=0;ui.optionSearch:SetText("");H.RefreshUI() end end)
  wheel(b,function(d) shiftTabs(-d) end);ui.tabs[i]=b
 end
 ui.categoryButton=button(ui,0,0,210,28,"Categories",categoryMenu)
 ui.optionSearch=edit(ui,0,0,420,function() ui.optionOffset=0;H.RefreshUI() end,"Rechercher un reglage...")
 ui.optionView=CreateFrame("Frame",nil,ui);wheel(ui.optionView,function(d) move("options",-d) end)
 ui.options={}
 for i=1,12 do
  local row=button(ui.optionView,0,0,700,42,"",function() end);row.caption:Hide()
  row.title=label(row,0,0,350,18,"",13);row.section=label(row,0,0,350,16,"",10,"muted");row.value=label(row,0,0,72,26,"",11,"accent")
  row.value:SetJustifyH("RIGHT")
  row:SetScript("OnClick",function() local o=row.option;if o and o.header then ui.closed[o.group]=not ui.closed[o.group];H.RefreshUI() end end)
  row.toggle=button(row,0,0,220,30,"",function() local o=row.option;if not o or o.header then return end;local ok,v=H.Call(o.get);if ok then result(H.SetOption(o,not v)) end end)
  row.choice=button(row,0,0,220,30,"",function() local o=row.option;if not o or o.header then return end;local ok,v=H.Call(o.get);if ok then result(H.SetOption(o,math.mod(v,table.getn(o.values))+1)) end end)
  row.slider=CreateFrame("Slider",nil,row);surface(row.slider,"field");row.slider:SetOrientation("HORIZONTAL");row.slider:SetThumbTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")
  if row.slider.GetThumbTexture then local thumb=row.slider:GetThumbTexture();if thumb then thumb:SetWidth(16);thumb:SetHeight(24) end end
  row.slider:SetScript("OnValueChanged",function()
   if H.refreshing then return end;local o=row.option;if not o or o.header then return end
   local step=o.step or 1;local v=math.floor(row.slider:GetValue()/step+.5)*step
   local low=o.min or 0;if o.minimum then local ok,n=H.Call(o.minimum);if ok and H.Number(n) then low=n end end
   result(H.SetOption(o,math.min(o.max,math.max(low,v))))
  end)
  row.minus=button(row,0,0,22,26,"-",function() nudge(row,-1) end)
  row.plus=button(row,0,0,22,26,"+",function() nudge(row,1) end)
  for _,f in ipairs({row,row.toggle,row.choice,row.slider,row.minus,row.plus}) do wheel(f,function(d) move("options",-d) end);optionHint(f,row) end
  ui.options[i]=row
 end
 ui.optionBar=scrollBar(ui,"options")
 ui.optionPrev=button(ui,0,0,28,24,"<",function() move("options",-ui.optionCount) end)
 ui.optionNext=button(ui,0,0,28,24,">",function() move("options",ui.optionCount) end)
 ui.optionPages=label(ui,0,0,240,24,"",11,"muted");ui.empty=label(ui,0,0,500,90,"",13,"muted")
 ui.gather=button(ui,0,0,176,24,"",function() H.db.gather=not H.db.gather;if H.db.gather then H.ToggleLauncher(true) else H.ReleaseButtons() end;H.RefreshUI() end)
 ui.gather:SetScript("OnEnter",function()
  local c=theme().accent;ui.gather:SetBackdropBorderColor(c[1],c[2],c[3],1)
  if not GameTooltip then return end
  GameTooltip:SetOwner(ui.gather,"ANCHOR_RIGHT");GameTooltip:SetText("Boutons de la minimap")
  GameTooltip:AddLine(H.db.gather and "Les raccourcis sont dans le lanceur. Cliquer pour les separer." or "Chaque addon a son bouton. Cliquer pour les regrouper.",1,1,1,true)
  GameTooltip:Show();ui.tipOwned=true
 end)
 ui.gather:SetScript("OnLeave",function() paint(ui.gather);if ui.tipOwned and GameTooltip then GameTooltip:Hide();ui.tipOwned=nil end end)
 ui.status=label(ui,0,0,450,32,"",10,"muted");ui.reload=button(ui,0,0,150,26,"Recharger",function() H.Call(ReloadUI) end)
 ui.cursorPreview=CreateFrame("Frame","AzerothHubCursorPreview",ui);surface(ui.cursorPreview,"panel");ui.cursorPreview:EnableMouse(false)
 label(ui.cursorPreview,8,4,184,16,"Apercu du curseur",12,"accent")
 ui.cursorPreview.note=label(ui.cursorPreview,12,164,204,36,"",11,"muted")
 ui.cursorPreview.state=label(ui.cursorPreview,12,204,204,28,"",11)
 ui.cursorPreview.pointer=ui.cursorPreview:CreateTexture(nil,"OVERLAY");ui.cursorPreview.pointer:SetTexture("Interface\\Cursor\\Point")
 ui.cursorPreview.pointer:SetWidth(24);ui.cursorPreview.pointer:SetHeight(24);ui.cursorPreview.pointer:SetPoint("CENTER",ui.cursorPreview,"TOP",10,-108)
 ui.cursorPreview.activate=button(ui.cursorPreview,12,279,204,28,"Activer en jeu",function()
  for _,o in ipairs(H.Options("AzerothCursor")) do if o.id=="enabled" then result(H.SetOption(o,not AzerothCursor.db.enabled));return end end
 end)
 ui.cursorPreview:SetScript("OnUpdate",function()
  if ui.cursorPreview:IsShown() and previewAvailable() and ui.cursorPreview.visual and ui.cursorPreview.visual.halo then
   ui.cursorPreview.visual.halo:SetAlpha(AzerothCursor.db.pulse and (.72+.28*math.sin((GetTime and GetTime() or 0)*4)) or 1)
  end
 end)
 ui.cursorPreview:Hide()
 ui.returnBar=CreateFrame("Frame","AzerothHubReturn",UIParent);ui.returnBar:SetWidth(350);ui.returnBar:SetHeight(42)
 ui.returnBar:SetPoint("TOP",UIParent,"TOP",0,-75);ui.returnBar:SetFrameStrata("DIALOG")
 if ui.returnBar.SetFrameLevel then ui.returnBar:SetFrameLevel(200) end;surface(ui.returnBar,"panel")
 ui.returnButton=button(ui.returnBar,8,7,296,28,"Retour au Hub",function()
  H.CaptureConfig(H.profile);ui.returnBar:Hide();if not ui:IsShown() then H.ToggleUI() end
 end)
 button(ui.returnBar,312,7,28,28,"X",function() ui.returnBar:Hide() end);ui.returnBar:Hide()
 ui.categories=CreateFrame("Frame",nil,ui);surface(ui.categories,"panel");ui.categories:SetFrameStrata("FULLSCREEN_DIALOG");ui.categories:EnableMouse(true);ui.categoryRows={}
 for i=1,8 do local b=button(ui.categories,8,8+(i-1)*34,304,30,"",function() end);b:SetScript("OnClick",function() ui.category=b.category;ui.optionOffset=0;ui.categories:Hide();H.RefreshUI() end);ui.categoryRows[i]=b end
 wheel(ui.categories,function(d) ui.categories.offset=math.max(0,(ui.categories.offset or 0)-d);H.RefreshUI() end);ui.categories:Hide()
 ui.shade=CreateFrame("Button",nil,ui);ui.shade:SetAllPoints(ui);ui.shade:SetFrameStrata("FULLSCREEN_DIALOG")
 if ui.shade.SetFrameLevel then ui.shade:SetFrameLevel(90) end
 ui.shade:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8"});ui.shade:SetBackdropColor(0,0,0,.60);ui.shade:Hide()
 ui.shade:SetScript("OnClick",function() ui.profiles:Hide();ui.appearance:Hide();ui.categories:Hide();ui.shade:Hide() end)
 ui.profiles=makeDialog("AzerothHubProfileMenu",490,470,"Vos profils");ui.profileRows={};ui.profiles.rows=ui.profileRows
 label(ui.profiles,20,50,450,40,"Ce profil enregistre les reglages integres des addons.\nCollections, historique et activation ne sont pas copies.",11,"muted")
 for i=1,6 do local b=button(ui.profiles,20,96+(i-1)*40,450,34,"",function() end);b:SetScript("OnClick",function() if b.profile then ui.profiles:Hide();ui.shade:Hide();result(H.UseConfigProfile(b.profile)) end end);wheel(b,function(d) ui.profileOffset=ui.profileOffset-d;H.RefreshUI() end);ui.profileRows[i]=b end
 wheel(ui.profiles,function(d) ui.profileOffset=ui.profileOffset-d;H.RefreshUI() end)
 label(ui.profiles,20,344,450,22,"Nouveau profil a partir des reglages actuels",12,"accent")
 ui.nameEdit=edit(ui.profiles,20,374,270,function() if ui.nameEdit.placeholder then show(ui.nameEdit.placeholder,(ui.nameEdit:GetText() or "")=="") end end,"Nom du nouveau profil...")
 ui.nameEdit:SetMaxLetters(48)
 ui.createProfile=button(ui.profiles,302,374,168,28,"Copier ce profil",function()
  local name=string.gsub(string.gsub(ui.nameEdit:GetText() or "","^%s+",""),"%s+$","")
  if H.db.profiles[name] then result(false,"Ce nom existe deja. Choisir un nouveau nom.");return end
  H.CaptureConfig(H.profile);local ok,err=H.SaveProfile(name)
  if ok then H.SelectProfile(name);H.db.activeProfile=name;ui.profiles:Hide();ui.shade:Hide() end;result(ok,err)
 end)
 ui.apply=button(ui.profiles,20,424,450,28,"Reappliquer les reglages enregistres",function() result(H.UseConfigProfile(H.profile)) end)
 ui.appearance=makeDialog("AzerothHubAppearance",510,370,"Apparence du Hub");ui.styleChoices={}
 label(ui.appearance,20,52,470,36,"Le choix reste enregistre ici. Changer de profil ne change pas l'apparence.",11,"muted")
 local descriptions={grimoire="Grimoire : addons a gauche, reglages a droite",atelier="Atelier : les profils restent dans une colonne",compact="Compact : fenetre courte, addon dans l'en-tete"}
 for i,mode in ipairs({"grimoire","atelier","compact"}) do
  local key=mode;ui.styleChoices[key]=button(ui.appearance,20,100+(i-1)*76,470,62,descriptions[key],function() result(H.SetAppearance(key)) end)
 end
 ui.closed={};ui.addonOffset=0;ui.optionOffset=0;ui.ready=true
 ui:SetScript("OnHide",function() ui.profiles:Hide();ui.appearance:Hide();ui.categories:Hide();ui.shade:Hide() end)
 H.selected=H.selected or (H.byName.AzerothFieldKit and "AzerothFieldKit") or (H.rows[1] and H.rows[1].name)
 H.LayoutManager();H.RefreshUI()
end
function H.ToggleUI()
 H.Init();H.EnsureConfigProfiles();H.Scan()
 if H.launcher then H.launcher:Hide() end
 if ui then ui.returnBar:Hide() end
 if ui then
  if ui:IsShown() then H.HideManager() else H.LayoutManager();ui:Show();H.RefreshUI() end
 else build() end
end
