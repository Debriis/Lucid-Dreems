"""Package an exported Godot Web directory with itch-compatible root paths."""
import hashlib
from pathlib import Path
import sys
import zipfile

source, destination = map(Path, sys.argv[1:3])
source = source.resolve()
destination = destination.resolve()
assert source.is_dir() and (source / "index.html").is_file(), "Missing Web/index.html"
assert not destination.is_relative_to(source), "Write the archive outside the export"
files = sorted(p for p in source.rglob("*") if p.is_file())
assert len(files) <= 1000, "itch.io file count limit exceeded"
assert sum(p.stat().st_size for p in files) < 500_000_000, "itch.io total size limit exceeded"
for path in files:
    assert path.stat().st_size < 200_000_000, f"File too large: {path.name}"
    assert len(path.relative_to(source).as_posix()) <= 240, "Path too long"
destination.parent.mkdir(parents=True, exist_ok=True)
with zipfile.ZipFile(destination, "w", zipfile.ZIP_DEFLATED, compresslevel=9) as archive:
    for path in files:
        archive.write(path, path.relative_to(source).as_posix())
with zipfile.ZipFile(destination) as archive:
    assert "index.html" in archive.namelist()
    assert archive.testzip() is None, "Archive CRC failed"
digest = hashlib.file_digest(destination.open("rb"), "sha256").hexdigest()
destination.with_suffix(".zip.sha256").write_text(f"{digest}  {destination.name}\n", encoding="utf-8")
print(f"Validated {len(files)} files; ZIP {destination.stat().st_size:,} bytes")
print(destination)
