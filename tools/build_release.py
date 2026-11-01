"""Build a reproducible player ZIP and SHA-256 (runtime + README only)."""
from pathlib import Path
import argparse
import hashlib
import re
import zipfile

root = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser()
parser.add_argument("--output", type=Path, default=root / "dist")
args = parser.parse_args()
version = re.search(r"## Version: (\S+)", (root / "AzerothHub.toc").read_text(encoding="utf-8")).group(1)
args.output.mkdir(parents=True, exist_ok=True)
archive = args.output / f"AzerothHub-{version}.zip"

lua_names = []
for line in (root / "AzerothHub.toc").read_text(encoding="utf-8").splitlines():
    line = line.strip()
    if line and not line.startswith("##"):
        lua_names.append(line)

files = [root / "AzerothHub.toc", root / "README.md"] + [root / name for name in lua_names]
for path in files:
    assert path.is_file(), path

with zipfile.ZipFile(archive, "w", zipfile.ZIP_DEFLATED) as z:
    for path in sorted(files, key=lambda p: p.relative_to(root).as_posix()):
        info = zipfile.ZipInfo("AzerothHub/" + path.relative_to(root).as_posix(), (2026, 11, 1, 0, 0, 0))
        info.compress_type = zipfile.ZIP_DEFLATED
        info.external_attr = 0o100644 << 16
        z.writestr(info, path.read_bytes())

with zipfile.ZipFile(archive) as z:
    assert z.testzip() is None
    assert len(z.namelist()) == len(files)

digest = hashlib.sha256(archive.read_bytes()).hexdigest()
archive.with_suffix(".zip.sha256").write_text(digest + "  " + archive.name + "\n", encoding="ascii")
print(archive)
print("SHA256 " + digest)
