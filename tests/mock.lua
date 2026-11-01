T={frames={},all={},time=10,writes=0,optionWrites=0,reloads=0}
local env=getfenv(0)
local function run(f,eventName,...)
 local before,button=env.this,env.arg1;env.this=f;env.arg1=arg[1]
 local fn=f.scripts[eventName];if fn then fn() end
 env.this=before;env.arg1=button
end
local function frame(kind,name,parent)
 local f={kind=kind,name=name,parent=parent,scripts={},children={},alpha=1,mouse=true,shown=true,text="",value=0,width=100,height=30,points={}}
 function f:GetName() return self.name end
 function f:GetObjectType() return self.kind end
 function f:GetScript(s) return self.scripts[s] end
 function f:SetScript(s,fn) self.scripts[s]=fn end
 function f:RegisterEvent() end
 function f:RegisterForClicks() end
 function f:RegisterForDrag() end
 function f:Click(button) run(self,"OnClick",button or "LeftButton") end
 function f:GetAlpha() return self.alpha end
 function f:SetAlpha(v) self.alpha=v end
 function f:IsMouseEnabled() return self.mouse end
 function f:EnableMouse(v) self.mouse=v end
 function f:EnableMouseWheel(v) self.wheel=v end
 function f:GetParent() return self.parent end
 function f:GetChildren() return unpack(self.children) end
 function f:SetWidth(v) self.width=v end
 function f:SetHeight(v) self.height=v end
 function f:GetWidth() return self.width end
 function f:GetHeight() return self.height end
 function f:SetScale(v) self.scale=v end
 function f:GetEffectiveScale() return self.scale or 1 end
 function f:SetPoint(...) self.points=arg end
 function f:ClearAllPoints() self.points={} end
 function f:SetAllPoints() end
 function f:Show() self.shown=true end
 function f:Hide() self.shown=false end
 function f:IsShown() return self.shown end
 function f:SetText(v) self.text=tostring(v);run(self,"OnTextChanged") end
 function f:GetText() return self.text end
 function f:ClearFocus() end
 function f:SetValue(v) self.value=v;run(self,"OnValueChanged") end
 function f:GetValue() return self.value end
 function f:SetMinMaxValues(a,b) self.low=a;self.high=b end
 function f:SetValueStep(v) self.step=v end
 function f:GetCenter() return 500,300 end
 for _,m in ipairs({"SetBackdrop","SetBackdropColor","SetBackdropBorderColor","SetFrameStrata","SetFrameLevel","SetTextColor","SetFont","SetJustifyH","SetJustifyV","SetTexture","SetVertexColor","SetTexCoord","SetAutoFocus","SetMaxLetters","SetOrientation","SetThumbTexture","SetMovable","StopMovingOrSizing","StartMoving"}) do f[m]=function() end end
 function f:SetVertexColor(r,g,b,a) self.color={r,g,b,a} end
 function f:CreateTexture(n) return frame("Texture",n,self) end
 function f:CreateFontString(n) return frame("FontString",n,self) end
 if parent then table.insert(parent.children,f) end
 if name then env[name]=f;T.frames[name]=f end
 table.insert(T.all,f)
 return f
end
CreateFrame=frame
getglobal=function(n) return env[n] end
setglobal=function(n,v) env[n]=v end
UIParent=frame("Frame","UIParent");UIParent.width=1920;UIParent.height=1080
Minimap=frame("Frame","Minimap",UIParent)
SlashCmdList={}
DEFAULT_CHAT_FRAME={AddMessage=function() end}
GetTime=function() return T.time end
GetCursorPosition=function() return 20,20 end
ReloadUI=function() T.reloads=T.reloads+1 end
T.addons={
 {name="AzerothHub",enabled=true,loaded=true,deps={}},
 {name="Library",enabled=true,loaded=true,deps={}},
 {name="Known",enabled=true,loaded=true,deps={"Library"}},
 {name="AzerothCursor",enabled=true,loaded=true,deps={}},
 {name="AzerothFieldKit",enabled=true,loaded=true,deps={}},
 {name="ASBuilder",enabled=true,loaded=true,deps={}},
 {name="Unrelated",enabled=false,loaded=false,deps={}},
}
function T.Row(key)
 if type(key)=="number" then return T.addons[key] end
 for _,a in ipairs(T.addons) do if a.name==key then return a end end
end
GetNumAddOns=function() return table.getn(T.addons) end
GetAddOnInfo=function(key)
 local a=assert(T.Row(key),"missing addon")
 return a.name,a.name,"Notes "..a.name,a.enabled and 1 or nil,1,nil,"INSECURE"
end
GetAddOnMetadata=function(key,field) return field=="Version" and "1.0" or "" end
GetAddOnDependencies=function(key) return unpack(T.Row(key).deps) end
IsAddOnLoaded=function(key) return T.Row(key).loaded and 1 or nil end
EnableAddOn=function(key) T.writes=T.writes+1;if T.fail==key then error("injected failure") end;T.Row(key).enabled=true end
DisableAddOn=function(key) T.writes=T.writes+1;if T.fail==key then error("injected failure") end;T.Row(key).enabled=false end
function T.Load()
 -- Inventory.lua is optional in unit tests (empty_catalogue / known load it explicitly).
 assert(loadfile("Core.lua"))();assert(loadfile("Adapters.lua"))();assert(loadfile("AdaptersKnown.lua"))()
 assert(loadfile("Profiles.lua"))();assert(loadfile("Minimap.lua"))();assert(loadfile("Manager.lua"))();assert(loadfile("UI.lua"))()
 AzerothHub.Init()
end
