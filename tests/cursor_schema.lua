dofile("tests/mock.lua")
T.Load()
local H=AzerothHub
-- Minimal Cursor surface matching 1.2 public API.
AzerothCursor={
 colors={{"Cyan",0,1,1},{"Magenta",1,.12,.85},{"Lime",.45,1,.05},{"Gold",1,.8,.05},
  {"White",1,1,1},{"Orange",1,.35,.02},{"Red",1,.08,.08},{"Blue",.25,.5,1}},
 classIcons={WARRIOR="war",PALADIN="pal",HUNTER="hunt",ROGUE="rogue",PRIEST="priest",
  SHAMAN="sham",MAGE="mage",WARLOCK="lock",DRUID="druid"},
 db={enabled=false,size=64,thickness=2,opacity=100,halo=45,crosshair=24,dot=5,iconSize=28,
  pulse=false,classIcon=false,color=1,language="fr"},
 Apply=function() end,
}
function AzerothCursor.ClassIconToken()
 return AzerothCursor.db.classIconToken or "WARRIOR"
end
function AzerothCursor.L(token) return token end
SlashCmdList.AZEROTHCURSOR=function() end
H.Scan()
assert(H.CanOpen("AzerothCursor"))
local opts=H.Options("AzerothCursor")
local seen={}
for _,o in ipairs(opts) do seen[o.id]=o end
for _,id in ipairs({"enabled","classIcon","pulse","thickness","size","opacity","halo","crosshair","dot","iconSize","classIconToken","color","language"}) do
 assert(seen[id], "missing "..id)
end
assert(H.SetOption(seen.classIcon,true) and AzerothCursor.db.classIcon==true)
assert(H.SetOption(seen.iconSize,55) and AzerothCursor.db.iconSize==55 and AzerothCursor.db.classIcon==true)
assert(H.SetOption(seen.classIconToken,4) and AzerothCursor.db.classIconToken=="ROGUE")
assert(H.SetOption(seen.color,3) and AzerothCursor.db.color==3 and AzerothCursor.db.rgb==nil)
assert(H.SetOption(seen.language,2) and AzerothCursor.db.language=="en")
print("PASS: Cursor 1.2 Hub schema complete")
