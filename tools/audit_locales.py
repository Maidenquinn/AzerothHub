#!/usr/bin/env python3
"""Audit AzerothHub locale files against tools/en_keys.txt.

en_keys.txt lists every English key, one per line, in Lua source-escaped form
(a literal \\n in the file stands for a newline escape in the Lua key).
Each Locales/<code>.lua must define exactly the same key set, with no duplicates,
no empty values, and the same ordered %s placeholders as the English key.
"""
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
EN_KEYS = ROOT / "tools" / "en_keys.txt"
LOCALES = ROOT / "Locales"
CODES = ["pl", "cs", "de", "pt", "es", "fr", "ro", "tr", "ru", "uk", "zh", "ja", "ko"]

ENTRY = re.compile(r'^\s*\["((?:[^"\\]|\\.)*)"\]\s*=\s*"((?:[^"\\]|\\.)*)"\s*,?\s*$')
HEADER = re.compile(r'^AzerothHub\.RegisterLocale\("([a-z]{2})"\s*,\s*\{\s*$')


def load_en_keys():
    keys = [l.rstrip("\r\n") for l in EN_KEYS.read_text(encoding="utf-8").split("\n")]
    keys = [k for k in keys if k != ""]
    assert len(keys) == len(set(keys)), "duplicate keys in en_keys.txt"
    return keys


def load_locale(code):
    path = LOCALES / (code + ".lua")
    text = path.read_text(encoding="utf-8")
    assert not text.startswith("\ufeff"), "%s: BOM not allowed" % path.name
    lines = text.splitlines()
    problems = []
    if not lines or lines[0] != "-- Azeroth Hub locale: " + code:
        problems.append("bad header comment")
    pairs = []
    registered = None
    for n, line in enumerate(lines, 1):
        m = HEADER.match(line)
        if m:
            registered = m.group(1)
            continue
        m = ENTRY.match(line)
        if m:
            pairs.append((m.group(1), m.group(2)))
        elif line.strip() and not line.startswith("--") and line.strip() not in ("})",):
            problems.append("line %d unparsed: %r" % (n, line[:60]))
    if registered != code:
        problems.append("RegisterLocale code is %r" % registered)
    if not text.rstrip().endswith("})"):
        problems.append("missing closing })")
    return pairs, problems


def placeholders(s):
    return re.findall(r"%s", s)


def main():
    en = load_en_keys()
    en_set = set(en)
    print("English keys: %d" % len(en))
    failed = False
    for code in CODES:
        path = LOCALES / (code + ".lua")
        if not path.exists():
            print("%s: MISSING FILE" % code)
            failed = True
            continue
        pairs, problems = load_locale(code)
        keys = [k for k, _ in pairs]
        key_set = set(keys)
        dups = sorted({k for k in keys if keys.count(k) > 1})
        missing = [k for k in en if k not in key_set]
        extra = sorted(key_set - en_set)
        for k, v in pairs:
            if v.strip() == "":
                problems.append("empty value: %r" % k)
            elif k in en_set and placeholders(k) != placeholders(v):
                problems.append("placeholder mismatch: %r -> %r" % (k, v))
        if dups:
            problems.append("duplicates: %r" % dups)
        if missing:
            problems.append("missing: %r" % missing)
        if extra:
            problems.append("extra: %r" % extra)
        if problems:
            failed = True
            print("%s: FAIL (%d keys)" % (code, len(key_set)))
            for p in problems:
                print("   - " + p)
        else:
            print("%s: OK (%d keys)" % (code, len(key_set)))
    if failed:
        print("AUDIT FAILED")
        sys.exit(1)
    assert all(True for _ in CODES)
    print("AUDIT PASSED")


if __name__ == "__main__":
    main()
