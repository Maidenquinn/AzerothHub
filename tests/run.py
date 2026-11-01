from pathlib import Path
import os, subprocess, sys
root=Path(__file__).resolve().parents[1]
lua=Path(os.environ["AZHUB_LUA"]) if os.environ.get("AZHUB_LUA") else root.parent/'azeroth-stats-audit/toolchain/lua50.exe'
if not lua.exists():
    sys.exit("Lua 5.0 introuvable : "+str(lua)+" — definir AZHUB_LUA")
for path in list(root.glob('*.lua'))+list((root/'Locales').glob('*.lua')):
    rel=path.relative_to(root).as_posix()
    subprocess.run([str(lua),'-e',f'assert(loadfile("{rel}"))'],cwd=root,check=True)
for case in ('core','minimap','ui','presets','compatibility','empty_catalogue','config_profiles','appearances','layout','catalog','known','cursor_schema','locale'):
    subprocess.run([str(lua),f'tests/{case}.lua'],cwd=root,check=True)
addons=Path(os.environ.get('AZHUB_ADDONS', r'H:/Users/kevin/Desktop/AzerothSurvivors/Jeu/benilla-config/AddOns'))
native=addons/'Azerloot/modules/Settings.lua'
if native.exists():
    subprocess.run([str(lua),'tests/native_azerloot.lua',str(native)],cwd=root,check=True)
cursor=addons/'AzerothCursor/Core.lua'
if cursor.exists():
    subprocess.run([str(lua),'tests/native_cursor_preview.lua',str(cursor)],cwd=root,check=True)
