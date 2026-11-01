dofile("tests/mock.lua");T.Load()
local H=AzerothHub
assert(H.DetectGameLanguage()=="en")
assert(H.T("Appearance")=="Appearance")
assert(H.T("With settings")=="With settings")
local codes={"pl","cs","de","pt","es","fr","ro","tr","ru","uk","zh","ja","ko"}
for _,code in ipairs(codes) do
 assert(type(H.LOCALES[code])=="table",code)
 assert(type(H.LOCALES[code]["Appearance"])=="string" and H.LOCALES[code]["Appearance"]~="")
 assert(type(H.LOCALES[code]["With settings"])=="string")
 assert(type(H.LOCALES[code]["Launcher"])=="string")
end
assert(H.LOCALES.fr["Appearance"]=="Apparence")
H.db.language="fr";H.ApplyLocale()
assert(H.lang=="fr" and H.T("Appearance")=="Apparence")
assert(H.T("MissingKeyFallsBack")=="MissingKeyFallsBack")
T.lang="ko";H.db.language="auto";H.ApplyLocale()
assert(H.lang=="ko" and H.T("Launcher")==H.LOCALES.ko["Launcher"])
H.db.language="xx";H.ApplyLocale();assert(H.lang=="ko")
local opts=H.Options("AzerothHub");local seen
for _,o in ipairs(opts) do if o.id=="language" then seen=o end end
assert(seen and seen.kind=="choice" and table.getn(seen.values)==15)
assert(H.SetOption(seen,8)) -- Français index: auto+en+pl+cs+de+pt+es+fr = 8
assert(H.db.language=="fr")
print("PASS: 14 locales registered, azsLanguage detection, Hub language option")
