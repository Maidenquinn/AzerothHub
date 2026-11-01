-- Language detection + Hub UI strings. Keys are English; missing keys fall back to English.
-- Game language lives in CVar azsLanguage (en, pl, cs, de, pt, es, fr, ro, tr, ru, uk, zh, ja, ko).
-- GetLocale() is often enUS on this client and is only a fallback.
AzerothHub=AzerothHub or {}
local H=AzerothHub
H.LANGUAGES={
 {code="en",name="English"},
 {code="pl",name="Polski"},
 {code="cs",name="Čeština"},
 {code="de",name="Deutsch"},
 {code="pt",name="Português (Brasil)"},
 {code="es",name="Español"},
 {code="fr",name="Français"},
 {code="ro",name="Română"},
 {code="tr",name="Türkçe"},
 {code="ru",name="Русский"},
 {code="uk",name="Українська"},
 {code="zh",name="简体中文"},
 {code="ja",name="日本語"},
 {code="ko",name="한국어"},
}
local KNOWN={}
for i=1,table.getn(H.LANGUAGES) do KNOWN[H.LANGUAGES[i].code]=H.LANGUAGES[i] end
local FROM_WOW={
 enUS="en",enGB="en",plPL="pl",csCZ="cs",deDE="de",ptBR="pt",ptPT="pt",
 esES="es",esMX="es",frFR="fr",roRO="ro",trTR="tr",ruRU="ru",ukUA="uk",
 zhCN="zh",zhTW="zh",jaJP="ja",koKR="ko",
}
H.LOCALES={}
H.L=setmetatable({},{__index=function(_,key) return key end})
function H.RegisterLocale(code,strings)
 if KNOWN[code] and type(strings)=="table" then H.LOCALES[code]=strings end
end
function H.IsKnownLanguage(code) return KNOWN[code]~=nil end
function H.LanguageName(code)
 local e=KNOWN[code];return (e and e.name) or tostring(code or "")
end
function H.DetectGameLanguage()
 if type(GetCVar)=="function" then
  local ok,value=pcall(GetCVar,"azsLanguage")
  if ok and type(value)=="string" and KNOWN[value] then return value end
 end
 if type(GetLocale)=="function" then
  local mapped=FROM_WOW[GetLocale()];if mapped then return mapped end
 end
 return "en"
end
function H.ApplyLocale()
 local wanted=H.db and H.db.language
 H.GAME_LANG=H.DetectGameLanguage()
 if wanted and wanted~="auto" and KNOWN[wanted] then H.lang=wanted else H.lang=H.GAME_LANG end
 local L=H.L
 for k in pairs(L) do rawset(L,k,nil) end
 local pack=H.LOCALES[H.lang]
 if pack then
  for k,v in pairs(pack) do if type(v)=="string" and v~="" then rawset(L,k,v) end end
 end
end
function H.T(key)
 if key==nil then return "" end
 key=tostring(key)
 local L=H.L
 return (L and L[key]) or key
end
function H.TF(key,...)
 local s=H.T(key)
 if arg.n==0 then return s end
 -- Lua 5.0: sequential %s replacements only (no string.format named args).
 local i=1
 s=string.gsub(s,"%%s",function()
  local v=arg[i];i=i+1;return tostring(v==nil and "" or v)
 end)
 return s
end
function H.LanguageChoices()
 local values={"Automatic"}
 local codes={"auto"}
 for i=1,table.getn(H.LANGUAGES) do
  table.insert(codes,H.LANGUAGES[i].code)
  table.insert(values,H.LANGUAGES[i].name)
 end
 return codes,values
end
