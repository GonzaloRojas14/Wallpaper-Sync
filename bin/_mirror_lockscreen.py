#!/usr/bin/env python3
# Espeja la config de Desktop sobre Idle (lock screen) en el Index.plist
# del WallpaperAgent de macOS. Uso:
#   _mirror_lockscreen.py            # espeja y reinicia WallpaperAgent
#   _mirror_lockscreen.py --dry-run  # sólo informa
import plistlib, copy, datetime, os, sys, tempfile, subprocess

INDEX = os.path.expanduser("~/Library/Application Support/com.apple.wallpaper/Store/Index.plist")

def mirror(node, touched):
    if not isinstance(node, dict): return touched
    if "Desktop" in node and "Idle" in node:
        desk, idle = node["Desktop"], node["Idle"]
        if isinstance(desk, dict) and isinstance(idle, dict) and "Content" in desk:
            idle["Content"] = copy.deepcopy(desk["Content"])
            now = datetime.datetime.utcnow()
            idle["LastSet"] = now
            idle["LastUse"] = now
            touched += 1
    for v in list(node.values()):
        if isinstance(v, dict):
            touched = mirror(v, touched)
    return touched

def main():
    dry = "--dry-run" in sys.argv
    if not os.path.exists(INDEX):
        print("no existe el Index.plist del WallpaperAgent", file=sys.stderr); sys.exit(1)

    with open(INDEX, "rb") as f:
        d = plistlib.load(f)

    touched = 0
    touched = mirror(d.get("SystemDefault", {}), touched)
    for dv in d.get("Displays", {}).values():
        touched = mirror(dv, touched)
    for sv in d.get("Spaces", {}).values():
        if isinstance(sv, dict):
            if "Default" in sv: touched = mirror(sv["Default"], touched)
            for dv in sv.get("Displays", {}).values():
                touched = mirror(dv, touched)

    asd = d.get("AllSpacesAndDisplays", {})
    sysdef = d.get("SystemDefault", {})
    if "Idle" in asd and "Desktop" in sysdef and "Content" in sysdef["Desktop"]:
        asd["Idle"]["Content"] = copy.deepcopy(sysdef["Desktop"]["Content"])
        now = datetime.datetime.utcnow()
        asd["Idle"]["LastSet"] = now
        asd["Idle"]["LastUse"] = now
        touched += 1

    print(f"nodos a espejar: {touched}")
    if dry or touched == 0:
        return

    # write atómico: tmp → rename
    fd, tmp = tempfile.mkstemp(dir=os.path.dirname(INDEX), prefix=".Index.plist.tmp-")
    try:
        with os.fdopen(fd, "wb") as f:
            plistlib.dump(d, f, fmt=plistlib.FMT_BINARY)
        os.replace(tmp, INDEX)
    except Exception:
        try: os.unlink(tmp)
        except: pass
        raise

    # reiniciar WallpaperAgent (se relanza solo vía launchd)
    subprocess.run(["killall", "WallpaperAgent"], stderr=subprocess.DEVNULL)

if __name__ == "__main__":
    main()
