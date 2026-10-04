"""Regenerate the factual full concept manifest from the shared catalog.

This asset-pipeline report includes all 50 distinct labels (the written list
omits sheet10's three Mythics). Exports are not treated as Roblox imports.
Existing Studio-recorded evidence is preserved, never synthesized.
Run with Blender or any Python3 runtime; the generation workflow calls it.
"""
from pathlib import Path
import hashlib
import json
import re

SOURCE=Path(__file__).resolve().parent
ROOT=Path(__file__).resolve().parents[4]
MANIFEST=SOURCE/"curse_expansion_manifest.json"


def main():
    if any((SOURCE/"rework").glob("*_geometry.json")):
        from write_rework_manifest import main as write_current
        return write_current()
    catalog=(ROOT/"src/shared/CurseCatalog.luau").read_text(encoding="utf-8")
    reference_block=catalog.split("local referenceFiles = {",1)[1].split("\n}",1)[0]
    references=re.findall(r'"([^"]+\.png)"',reference_block)
    concept_block=catalog.split("local concepts = {",1)[1].split("\n}",1)[0]
    concepts=re.findall(r'\{ "([a-z_]+)", "([^"]+)", "(COMMON|RARE|LEGENDARY|MYTHIC|SECRET)", (\d+) \}',concept_block)
    geometry=json.loads((SOURCE/"first_wave_geometry.json").read_text(encoding="utf-8"))
    wave={r["id"]:r for r in geometry["assets"]}
    previous={r["id"]:r for r in json.loads(MANIFEST.read_text(encoding="utf-8")).get("concepts",[])} if MANIFEST.exists() else {}
    records=[]
    counts={}
    for id,name,rarity,reference in concepts:
        shape=wave.get(id)
        export=shape["export"] if shape else None
        digest=hashlib.sha256((ROOT/export).read_bytes()).hexdigest() if export else None
        record={"id":id,"displayName":name,"rarity":rarity,"visualKey":id,
                "sourceReference":references[int(reference)-1],"referenceSheet":int(reference),
                "implementationStatus":"EXPORTED" if shape else "PLANNED","enabled":False,
                "productionWave":1 if shape else 0,"blendSource":"assets/source/blender/curses_expansion/steal_a_curse_expansion_wave1.blend" if shape else None,
                "generator":"assets/source/blender/curses_expansion/generate_expansion.py" if shape else None,
                "fbxExport":export,"fbxSha256":digest,"meshId":None,"textureId":None,
                "robloxImportVerified":False,"robloxAppearanceVerified":False,"gameplayValidated":False}
        if shape:
            for field in ("triangles","vertices","robloxIntendedSize","vfxProfile","vfxHookRoblox","colorPipeline","fbxGlobalScale"):
                record[field]=shape[field]
        old=previous.get(id,{})
        if old.get("fbxSha256")==digest and old.get("robloxImportVerified"):
            for field in ("implementationStatus","meshId","textureId","robloxImportVerified","robloxAppearanceVerified","gameplayValidated","importedSize","importedInitialSize","importEvidence"):
                if field in old:
                    record[field]=old[field]
        records.append(record)
        counts[rarity]=counts.get(rarity,0)+1
    if len(records)!=50 or len({r["id"] for r in records})!=50 or len(wave)!=15:
        raise RuntimeError("Concept/wave count mismatch; inspect every reference before reporting completion")
    report={"schemaVersion":1,"conceptCount":50,"preservedExistingCount":6,"totalPlannedCatalogCount":56,
            "firstWaveCount":15,"remainingUnmodeledCount":35,"rarityCounts":counts,
            "countDiscrepancy":"The written list contains47, but sheet10 adds3 distinct Mythics: Worldroot, The Undertow, The Last Funeral. All50 labeled concepts are retained.",
            "duplicateReference":"Image13 repeats Image5; no duplicate Curse entries.",
            "statusRules":{"PLANNED":"Concept/data only, no model or upload claimed",
                           "EXPORTED":"Original .blend/FBX with local round-trip validation; no Roblox upload claimed",
                           "IMPORTED":"Studio MeshId/InitialSize/Size actually recorded; remains disabled",
                           "VALIDATED":"Imported appearance and gameplay verified; enablement is a separate reviewed decision"},
            "concepts":records}
    MANIFEST.write_text(json.dumps(report,indent=2)+"\n",encoding="utf-8")
    print("CURSE_EXPANSION_MANIFEST",len(records),counts,"first_wave",len(wave))


if __name__=="__main__":
    main()
