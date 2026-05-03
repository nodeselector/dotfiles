#!/usr/bin/env python3
"""
Cleanup iTerm2 static profiles that conflict with dotfiles-managed dynamic profiles.
Run this if iTerm2 shows: "Dynamic profile with Guid ... conflicts with non-dynamic profile with same Guid".
"""
import plistlib
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

# Old GUIDs previously used by dotfiles dynamic profiles
GUIDS_TO_REMOVE = [
    "61C8BA73-2D5D-47A6-B3EE-57BCA9D14A87",
    "D649C857-1E4F-493B-942D-776DB281DB26",
]


def main() -> int:
    plist_path = Path("~/Library/Preferences/com.googlecode.iterm2.plist").expanduser()
    if not plist_path.exists():
        print("No iTerm2 preferences found; skipping")
        return 0

    with plist_path.open("rb") as f:
        data = plistlib.load(f)

    bookmarks = data.get("New Bookmarks")
    if not bookmarks:
        print("No profiles found in preferences; nothing to do")
        return 0

    keep = []
    removed = []
    for b in bookmarks:
        guid = b.get("Guid")
        if guid in GUIDS_TO_REMOVE:
            removed.append(guid)
        else:
            keep.append(b)

    if not removed:
        print("No conflicting static profiles found; nothing to do")
        return 0

    data["New Bookmarks"] = keep

    backup = plist_path.with_suffix(".plist.bak")
    shutil.copy2(plist_path, backup)

    with tempfile.NamedTemporaryFile(delete=False) as tmp:
        plistlib.dump(data, tmp)
        tmp_path = Path(tmp.name)

    subprocess.run(["/usr/bin/plutil", "-convert", "binary1", str(tmp_path)], check=True)
    shutil.copy2(tmp_path, plist_path)

    print(f"Removed {len(removed)} profile(s): {sorted(set(removed))}")
    print(f"Backup saved at {backup}")
    print("Restart iTerm2 to reload preferences.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
