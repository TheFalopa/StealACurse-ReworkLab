"""Generate runtime mappings only from exact current-source Studio evidence."""
from pathlib import Path
import json
import math
import re
import update_rework_progress

ROOT = update_rework_progress.ROOT


def vec(values):
    return "Vector3.new(" + ", ".join(format(v, ".12g") for v in values) + ")"


def main():
    update_rework_progress.main()
    ledger = json.loads(update_rework_progress.LEDGER.read_text(encoding="utf-8"))
    projectpath = ROOT / "default.project.json"
    project = json.loads(projectpath.read_text(encoding="utf-8"))
    kit = project["tree"]["ServerStorage"]["CurseMeshKit"]
    lines = ["-- Generated from the current FBX ledger and observed Studio imports.",
             "-- Run assets/source/blender/curses_expansion/apply_rework_assets.py.", "return {"]
    mapped = 0
    for row in ledger["curses"]:
        cid, stages = row["id"], row["stages"]
        shape = row.get("geometry", {})
        imported = row.get("robloxImport", {}) if stages["realRobloxImportRecorded"] else {}
        approved = all(stages[k] for k in update_rework_progress.STAGES[:-1]) and stages["enabled"]
        if imported:
            assert stages["locallyValidated"], f"Unvalidated local export: {cid}"
            expected = shape["robloxIntendedSize"]
            size, meshsize = imported["size"], imported["meshSize"]
            assert math.dist(size, expected) < .02 and math.dist(meshsize, expected) < .02, f"Observed size mismatch: {cid}"
            assert math.sqrt(sum(v*v for v in size)) < 7, f"Clearance failure: {cid}"
            kit[cid] = {"$className": "MeshPart", "$properties": {
                "MeshId": imported["meshId"], "InitialSize": meshsize, "Size": size}}
            if imported.get("textureId"):
                kit[cid]["$properties"]["TextureID"] = imported["textureId"]
            mapped += 1
        status = "VALIDATED" if stages["gameplayChecked"] else "IMPORTED" if imported else "EXPORTED" if stages["fbxExported"] else "PLANNED"
        lines.append(f'\t{cid} = {{ status = "{status}", enabled = {str(approved).lower()},')
        lines.append(f'\t\tsourceReference = "{row["sourceReference"]}", fbxSha256 = "{row.get("currentFbxSha256") or ""}",')
        lines.append(f'\t\tvfxHook = {vec(shape.get("vfxHookRoblox", [0,0,0]))}, vfxProfile = "{shape.get("vfxProfile", "planned")}",')
        lines.append(f'\t\toriginalVertexColors = {str(bool(imported.get("studioAppearanceChecked"))).lower()}, meshId = "{imported.get("meshId", "")}" }},')
        if shape.get("vfxHooksRoblox"):
            hooks = ", ".join(f'{name} = {vec(point)}' for name, point in shape["vfxHooksRoblox"].items())
            lines[-1] = lines[-1].replace(' },', f', vfxHooks = {{ {hooks} }} }},')
    lines.append("}")
    (ROOT / "src/shared/CurseExpansionAssets.luau").write_text("\n".join(lines)+"\n", encoding="utf-8")
    catalogpath = ROOT / "src/shared/CurseCatalog.luau"
    catalog = catalogpath.read_text(encoding="utf-8")
    # Remove obsolete first-wave focal points; current exports author these.
    catalog = re.sub(r"local waveHooks = \{.*?\n\}\n", "", catalog, flags=re.S)
    catalogpath.write_text(catalog, encoding="utf-8")
    projectpath.write_text(json.dumps(project, indent=2)+"\n", encoding="utf-8")
    print("CURRENT_REWORK_RUNTIME_IMPORTS", mapped)


if __name__ == "__main__":
    main()
