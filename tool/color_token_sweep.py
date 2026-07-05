#!/usr/bin/env python3
"""One-shot sweep: replace hardcoded Color(0x...) literals with AppColors tokens.

Only hexes present in TOKENS are touched; everything else stays inline.
Handles `const Color(0x...)` and `Color(0x...)` forms (static-const token
references remain valid inside const expressions). Adds the relative import
when a file is modified. Run from repo root; safe to re-run (idempotent).
"""
import os
import re
import sys

LIB = "lib"
TOKENS_FILE = os.path.join(LIB, "core", "presentation", "app_colors.dart")

TOKENS = {
    "0XFFB7FF00": "accent",
    "0XFFB2ED00": "accentDim",
    "0XFFBEFC00": "accentBright",
    "0XFFC0FF00": "accentBright",  # merge: 1 use, ~identical to BEFC00
    "0XFF445D00": "accentDeep",
    "0XFF00E3FD": "cyan",
    "0XFF00E6FF": "cyan",          # merge: ~identical
    "0XFF00CFFF": "cyanDeep",
    "0XFF00FF9F": "mint",
    "0XFF4ADE80": "success",
    "0XFF7B61FF": "violet",
    "0XFF6C63FF": "violetSoft",
    "0XFFFF4D9E": "pink",
    "0XFFFF7351": "coral",
    "0XFFFF8C42": "orange",
    "0XFFFFA726": "amber",
    "0XFFFF9933": "amberDeep",
    "0XFFFFD600": "yellow",
    "0XFFFF4D4D": "danger",
    "0XFFFF5252": "danger",        # merge: ~identical
    "0XFFF0F4FF": "textPrimary",
    "0XFF8A8FA8": "textMuted",
    "0XFFADAAAA": "textSoft",
    "0XFF888888": "textGray",
    "0XFF666666": "textFaint",
    "0XFF444444": "textDim",
    "0XFF050806": "scaffold",
    "0XFF1C2029": "surfaceCard",
    "0XFF14171C": "surfaceDark",
    "0XFF2A2F3D": "surfaceSlate",
    "0XFF1A1C1F": "surfaceMuted",
    "0XFF111317": "surfacePanel",
    "0XFF0D0F12": "surfaceDeep",
    "0XFF0E0E0E": "ink",
    "0XFF1A1A1A": "inkCard",
    "0XFF201F1F": "inkWarm",
    "0XFF262626": "inkElevated",
    "0XFF2E2E2E": "inkSoft",
    "0XFF131313": "inkDeep",
    # One-off colors (second pass — full centralization).
    "0XFFEAFFB8": "limeCream",
    "0XFFD4F08A": "limeSoft",
    "0XFF7BAF2A": "limeOlive",
    "0XFF354900": "limeShadow",
    "0XFF1A2800": "limeInk",
    "0XFF0D1A00": "limeInkDim",
    "0XFF0A1600": "limeInkDeep",
    "0XFFFFD54F": "scoreAmber",
    "0XFFFF6D4E": "scoreCoral",
    "0XFF4CAF50": "statusGreen",
    "0XFFFF9800": "statusOrange",
    "0XFF80CBC4": "tealSoft",
    "0XFF2A9B8B": "categoryTeal",
    "0XFF3B6FD4": "categoryBlue",
    "0XFF7B4FBF": "categoryPurple",
    "0XFF8B6B3D": "categoryBrown",
    "0XFFE07B2A": "categoryBurntOrange",
    "0XFFFFD700": "gold",
    "0XFF7B9CFF": "periwinkle",
    "0XFFFFFFFF": "white",
    "0XFFE0E0E0": "grayBright",
    "0XFFCCCCCC": "grayLight",
    "0XFF8E8E93": "grayIos",
    "0XFF6B7280": "graySlate",
    "0XFF4B5563": "graySlateDeep",
    "0XFF555555": "gray55",
    "0XFF3A3A3A": "gray3A",
    "0XFF333333": "gray33",
    "0XFF2A2A2A": "gray2A",
    "0XFF6B6767": "grayWarm",
    "0XFF0B0D10": "dark0B0D10",
    "0XFF0D1117": "dark0D1117",
    "0XFF0F0F1A": "dark0F0F1A",
    "0XFF111111": "dark111111",
    "0XFF121212": "dark121212",
    "0XFF151718": "dark151718",
    "0XFF181818": "dark181818",
    "0XFF1A1919": "dark1A1919",
    "0XFF1A1D22": "dark1A1D22",
    "0XFF1A2535": "dark1A2535",
    "0XFF1E1E1E": "dark1E1E1E",
    "0XFF1E1E2E": "dark1E1E2E",
    "0XFF1E2A2A": "dark1E2A2A",
    "0XFF1F2026": "dark1F2026",
    "0XFF222528": "dark222528",
    "0XFF2A2D32": "dark2A2D32",
    "0XFF2A2D33": "dark2A2D33",
    "0XFF2B2D31": "dark2B2D31",
    "0XFF2C2C2C": "dark2C2C2C",
    "0X14FFFFFF": "whiteBorder8",
    "0X33FFFFFF": "whiteGlow20",
    "0X3300E3FD": "cyanBorder20",
    "0X801A1A1A": "blackScrim50",
}

COLOR_RE = re.compile(r"(?:const\s+)?Color\(\s*(0x[0-9A-Fa-f]{8})\s*\)")
IMPORT_RE = re.compile(r"^import\s+['\"].*['\"];\s*$", re.MULTILINE)


def replace_colors(src: str):
    count = 0

    def sub(m):
        nonlocal count
        token = TOKENS.get(m.group(1).upper())
        if token is None:
            return m.group(0)
        count += 1
        return f"AppColors.{token}"

    return COLOR_RE.sub(sub, src), count


def ensure_import(src: str, file_path: str) -> str:
    rel = os.path.relpath(TOKENS_FILE, os.path.dirname(file_path)).replace(os.sep, "/")
    stmt = f"import '{rel}';"
    if stmt in src or "app_colors.dart'" in src:
        return src
    imports = list(IMPORT_RE.finditer(src))
    if imports:
        last = imports[-1]
        return src[: last.end()] + "\n" + stmt + src[last.end():]
    return stmt + "\n\n" + src


def main():
    changed = []
    total = 0
    for root, _dirs, files in os.walk(LIB):
        for name in files:
            if not name.endswith(".dart"):
                continue
            path = os.path.join(root, name)
            if os.path.abspath(path) == os.path.abspath(TOKENS_FILE):
                continue
            with open(path, encoding="utf-8") as f:
                src = f.read()
            new_src, n = replace_colors(src)
            if n == 0:
                continue
            new_src = ensure_import(new_src, path)
            with open(path, "w", encoding="utf-8") as f:
                f.write(new_src)
            changed.append((path, n))
            total += n
    for path, n in sorted(changed, key=lambda x: -x[1]):
        print(f"{n:4d}  {path}")
    print(f"\n{total} literals replaced across {len(changed)} files")


if __name__ == "__main__":
    sys.exit(main())
