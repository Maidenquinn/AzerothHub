"""Read installed .toc metadata; write only the Hub inventory, never addon settings."""
from pathlib import Path
import argparse
import json

def inventory(folder):
    rows = []
    for child in sorted(folder.iterdir(), key=lambda p: p.name.lower()):
        toc = child / (child.name + '.toc')
        if not child.is_dir() or not toc.is_file():
            continue
        meta = {}
        for line in toc.read_text(encoding='utf-8-sig', errors='replace').splitlines():
            if line.startswith('##') and ':' in line:
                key, value = line[2:].split(':', 1)
                meta[key.strip().lower()] = ''.join(c for c in value.strip() if ord(c) >= 32)
        rows.append(dict(name=child.name, title=meta.get('title') or child.name,
                         notes=meta.get('notes', ''), version=meta.get('version', '')))
    return rows

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--addons-dir', type=Path, default=Path(__file__).resolve().parent.parent)
    parser.add_argument('--output', type=Path, default=Path(__file__).resolve().parent/'Inventory.lua')
    args = parser.parse_args()
    rows = inventory(args.addons_dir)
    own = inventory(Path(__file__).resolve().parent.parent)
    own_meta = next((r for r in own if r['name'] == 'AzerothHub'), None)
    if own_meta:
        rows = [own_meta if r['name'] == 'AzerothHub' else r for r in rows]
    quote = lambda value: json.dumps(value, ensure_ascii=False)
    lines = ['-- Generated installation snapshot; refresh after adding/removing addon folders.', 'AzerothHubInventory={']
    for row in rows:
        lines.append(' {' + ','.join(key+'='+quote(value) for key, value in row.items()) + '},')
    lines.append('}')
    args.output.write_text('\n'.join(lines)+'\n', encoding='utf-8')
    print(str(len(rows))+' addon folders indexed in '+str(args.output))
