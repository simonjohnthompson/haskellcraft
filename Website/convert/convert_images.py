#!/usr/bin/env python3
"""Render the figures referenced by Website/chapters/*.md into
Website/chapters/Pictures/ as web-friendly PNGs.

Most figures exist only as PDF in Book/Pictures/ (converted here via
macOS's `sips`); a handful were already PNG/JPEG in the source and are
just copied across unchanged.

Usage:
    python3 convert_images.py
"""
import re
import shutil
import subprocess
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent.parent
CHAPTERS_DIR = REPO_ROOT / "Website" / "chapters"
SOURCE_PICTURES = REPO_ROOT / "Book" / "Pictures"
OUT_PICTURES = CHAPTERS_DIR / "Pictures"

RASTER_EXTS = (".png", ".jpg", ".jpeg", ".gif")


def referenced_image_names():
    names = set()
    pattern = re.compile(r"Pictures/([A-Za-z0-9_.\-]+)\.png")
    for md in CHAPTERS_DIR.glob("*.md"):
        names.update(pattern.findall(md.read_text(encoding="utf-8")))
    return sorted(names)


def main():
    if shutil.which("sips") is None:
        print(
            "This script shells out to macOS's `sips` for PDF -> PNG "
            "conversion; on Linux/Windows substitute pdftoppm/pdftocairo "
            "(poppler) or ImageMagick.",
            file=sys.stderr,
        )
        sys.exit(1)

    OUT_PICTURES.mkdir(parents=True, exist_ok=True)

    names = referenced_image_names()
    converted, copied, missing = [], [], []

    for name in names:
        dest = OUT_PICTURES / f"{name}.png"

        raster_src = next(
            (SOURCE_PICTURES / f"{name}{ext}" for ext in RASTER_EXTS
             if (SOURCE_PICTURES / f"{name}{ext}").exists()),
            None,
        )
        if raster_src is not None:
            shutil.copyfile(raster_src, dest)
            copied.append(name)
            continue

        pdf_src = SOURCE_PICTURES / f"{name}.pdf"
        if pdf_src.exists():
            result = subprocess.run(
                ["sips", "-s", "format", "png", "-Z", "900", str(pdf_src), "--out", str(dest)],
                capture_output=True, text=True,
            )
            if result.returncode != 0:
                print(f"FAILED converting {pdf_src}: {result.stderr.strip()}", file=sys.stderr)
                missing.append(name)
            else:
                converted.append(name)
            continue

        missing.append(name)

    print(f"Converted (PDF->PNG): {len(converted)}")
    print(f"Copied (already raster): {len(copied)}")
    if missing:
        print(f"MISSING (no source found): {len(missing)}", file=sys.stderr)
        for name in missing:
            print(f"  - {name}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
