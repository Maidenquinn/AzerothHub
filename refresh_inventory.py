"""Build Inventory.lua from installed AddOns folders and/or community ZIP archives.

Never reads or writes other addons' SavedVariables. Only .toc metadata is used.
"""
from pathlib import Path
import argparse
import json
import zipfile


def parse_toc(text):
    meta = {}
    for line in text.splitlines():
        if line.startswith("##") and ":" in line:
            key, value = line[2:].split(":", 1)
            meta[key.strip().lower()] = "".join(c for c in value.strip() if ord(c) >= 32)
    return meta


def row_from_meta(name, meta):
    return {
        "name": name,
        "title": meta.get("title") or name,
        "notes": meta.get("notes", ""),
        "version": meta.get("version", ""),
    }


def inventory_dirs(folder: Path):
    rows = {}
    if not folder or not folder.is_dir():
        return rows
    for child in sorted(folder.iterdir(), key=lambda p: p.name.lower()):
        toc = child / (child.name + ".toc")
        if not child.is_dir() or not toc.is_file():
            continue
        meta = parse_toc(toc.read_text(encoding="utf-8-sig", errors="replace"))
        rows[child.name] = row_from_meta(child.name, meta)
    return rows


def inventory_zips(folder: Path):
    rows = {}
    if not folder or not folder.is_dir():
        return rows
    for zpath in sorted(folder.glob("*.zip")):
        try:
            with zipfile.ZipFile(zpath) as z:
                tocs = [n for n in z.namelist() if n.lower().endswith(".toc") and n.count("/") <= 2]
                for toc in tocs:
                    name = toc.split("/")[0] if "/" in toc else Path(toc).stem
                    meta = parse_toc(z.read(toc).decode("utf-8-sig", errors="replace"))
                    # Prefer richer/newer metadata when several zips share a folder name.
                    prev = rows.get(name)
                    row = row_from_meta(name, meta)
                    if not prev or (row["version"] and row["version"] >= (prev.get("version") or "")):
                        rows[name] = row
        except zipfile.BadZipFile:
            continue
    return rows


def write_inventory(rows, output: Path, hub_meta=None):
    ordered = [rows[k] for k in sorted(rows, key=str.lower)]
    if hub_meta:
        ordered = [hub_meta if r["name"] == "AzerothHub" else r for r in ordered]
        if not any(r["name"] == "AzerothHub" for r in ordered):
            ordered.append(hub_meta)
            ordered.sort(key=lambda r: r["name"].lower())
    quote = lambda value: json.dumps(value, ensure_ascii=False)
    lines = [
        "-- Generated installation snapshot; refresh after adding/removing addon folders.",
        "-- Also regenerated from community ZIP catalogs so Hub lists them before install.",
        "AzerothHubInventory={",
    ]
    for row in ordered:
        lines.append(" {" + ",".join(key + "=" + quote(value) for key, value in row.items()) + "},")
    lines.append("}")
    output.write_text("\n".join(lines) + "\n", encoding="utf-8")
    return len(ordered)


if __name__ == "__main__":
    hub_root = Path(__file__).resolve().parent
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--addons-dir", type=Path, default=None, help="Live AddOns folder (preferred metadata)")
    parser.add_argument("--zips-dir", type=Path, default=None, help="Folder of community addon ZIP archives")
    parser.add_argument("--output", type=Path, default=hub_root / "Inventory.lua")
    args = parser.parse_args()

    rows = {}
    rows.update(inventory_zips(args.zips_dir))
    rows.update(inventory_dirs(args.addons_dir))  # installed wins on conflicts

    own = inventory_dirs(hub_root.parent if (hub_root.parent / "AzerothHub").is_dir() else hub_root)
    # Hub lives in its own folder; prefer this checkout's toc.
    hub_rows = inventory_dirs(hub_root)
    hub_meta = hub_rows.get("AzerothHub") or own.get("AzerothHub")
    if not hub_meta and (hub_root / "AzerothHub.toc").is_file():
        meta = parse_toc((hub_root / "AzerothHub.toc").read_text(encoding="utf-8-sig", errors="replace"))
        hub_meta = row_from_meta("AzerothHub", meta)

    n = write_inventory(rows, args.output, hub_meta)
    print(f"{n} addon folders indexed in {args.output}")
