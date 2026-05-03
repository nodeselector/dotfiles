#!/usr/bin/env python3
"""Disable iTerm2 profile hotkey bindings for dotfiles profiles."""

from __future__ import annotations

import argparse
import plistlib
from pathlib import Path
import shutil
import tempfile
import sys

DOTFILES_GUIDS = {
    "EF56683E-FF62-482A-A5A4-4345EE0B3593",
    "53D012C0-31AC-44CD-861A-F9D97AC559F8",
}

def _load_plist(plist_path: Path):
    with plist_path.open("rb") as f:
        return plistlib.load(f)


def _write_plist(data, plist_path: Path) -> None:
    with tempfile.NamedTemporaryFile(delete=False) as tmp:
        tmp_path = Path(tmp.name)
        plistlib.dump(data, tmp, fmt=plistlib.FMT_BINARY)

    shutil.copy2(tmp_path, plist_path)


def disable_hotkeys_for_profiles(path: Path, guids: set[str]) -> bool:
    data = _load_plist(path)
    bookmarks = data.get("New Bookmarks")
    if not isinstance(bookmarks, list):
        print("No Bookmarks section found in preferences", file=sys.stderr)
        return False

    hotkey_keys = [
        "HotKey Activated By Modifier",
        "HotKey Alternate Shortcuts",
        "HotKey Characters",
        "HotKey Characters Ignoring Modifiers",
        "HotKey Key Code",
        "HotKey Modifier Activation",
        "HotKey Modifier Flags",
    ]

    changed = False
    for b in bookmarks:
        if not isinstance(b, dict):
            continue

        guid = b.get("Guid")
        chars = b.get("HotKey Characters Ignoring Modifiers")
        key_code = b.get("HotKey Key Code")
        modifier_flags = b.get("HotKey Modifier Flags")

        should_disable = False
        if guid in guids:
            should_disable = True
        elif (
            b.get("Has Hotkey") and
            (chars == "'" or key_code == 39 and modifier_flags in (524288, 786432))
        ):
            should_disable = True

        if not should_disable:
            continue

        if b.get("Has Hotkey"):
            changed = True
            b["Has Hotkey"] = False

        for key in hotkey_keys:
            if key in b:
                changed = True
                b.pop(key, None)

    if not changed:
        return False

    backup = path.with_suffix('.plist.bak')
    if backup.exists():
        backup = path.with_name(path.name + ".bak." + str(int(path.stat().st_mtime_ns)))
    shutil.copy2(path, backup)

    _write_plist(data, path)
    print(f"Updated {path} to disable iTerm hotkeys for known dotfiles profiles")
    print(f"Backup written to {backup}")
    return True


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--plist",
        default="~/Library/Preferences/com.googlecode.iterm2.plist",
        help="Path to iTerm2 plist file",
    )
    parser.add_argument(
        "--guid",
        action="append",
        dest="guids",
        default=[],
        help="Add extra profile GUID to disable hotkey for",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    guids = set(DOTFILES_GUIDS)
    guids.update(args.guids)
    path = Path(args.plist).expanduser()

    if not path.exists():
        print(f"iTerm2 plist not found: {path}", file=sys.stderr)
        return 1

    if disable_hotkeys_for_profiles(path, guids):
        return 0

    print("No matching dotfiles profile hotkeys found to disable")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
