# -*- coding: utf-8 -*-
from pathlib import Path
root = Path(__file__).resolve().parents[1] / "Locales"
T = {
    "pl": ("Bieżący", "Lekki"),
    "cs": ("Aktuální", "Lehký"),
    "de": ("Aktuell", "Leicht"),
    "pt": ("Atual", "Leve"),
    "es": ("Actual", "Ligero"),
    "fr": ("Actuel", "Léger"),
    "ro": ("Curent", "Ușor"),
    "tr": ("Güncel", "Hafif"),
    "ru": ("Текущий", "Лёгкий"),
    "uk": ("Поточний", "Легкий"),
    "zh": ("当前", "轻量"),
    "ja": ("現在", "軽量"),
    "ko": ("현재", "라이트"),
}
for code, (cur, light) in T.items():
    path = root / (code + ".lua")
    text = path.read_text(encoding="utf-8")
    if '["Current"]' in text:
        print("skip", code)
        continue
    insert = ' ["Current"] = "%s",\n ["Light"] = "%s",\n' % (cur, light)
    marker = ' ["Automatic"]'
    idx = text.find(marker)
    if idx >= 0:
        end = text.find("\n", idx)
        text = text[: end + 1] + insert + text[end + 1 :]
    else:
        text = text.replace("\n})", ",\n" + insert + "})", 1)
    path.write_text(text, encoding="utf-8")
    print("ok", code)
keys = Path(__file__).resolve().parents[1] / "tools" / "en_keys.txt"
k = keys.read_text(encoding="utf-8")
if "\nCurrent\n" not in ("\n" + k):
    keys.write_text(k.rstrip("\n") + "\nCurrent\nLight\n", encoding="utf-8")
    print("en_keys updated")
