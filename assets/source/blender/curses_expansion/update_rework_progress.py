"""Maintain an evidence-separated ledger for the current 50-Curse rework.

Local files can establish export/validation stages, never Studio or gameplay
approval. Those stages require explicit evidence carrying the same FBX hash.
Historical first-wave imports are retained as history and are not credited to
changed geometry. Run using the bundled Python or Blender Python.
"""
from pathlib import Path
from datetime import datetime, timedelta, timezone
import hashlib
import json
import re

SOURCE = Path(__file__).resolve().parent
ROOT = SOURCE.parents[3]
LEDGER = ROOT / "assets/curse-expansion-progress.json"
MANIFEST = SOURCE / "curse_expansion_manifest.json"
STAGES = ("referenceReviewed", "blenderModelComplete", "locallyValidated",
          "fbxExported", "realRobloxImportRecorded", "studioAppearanceChecked",
          "vfxChecked", "gameplayChecked", "enabled")


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def production_source_fingerprints():
    """Sources that can change a runtime approval, excluding generated gates.

    ExpansionAssets/default.project and tests are retained in test build
    evidence but excluded here: enabling an approved definition rewrites those
    files. Catalog is authored and has no generated enable block; its full hash
    gates names/economy/references/effects. VFX, number formatting, labels, all
    gameplay services and every Map module are gated.
    """
    paths = ["src/shared/CurseVFXProfiles.luau", "src/shared/CurseCatalog.luau",
             "src/shared/NumberFormat.luau", "src/client/CurseVFX.luau",
             "src/client/init.client.luau", "src/client/UI/CurseLabels.luau"]
    paths += [p.relative_to(ROOT).as_posix() for folder in
              (ROOT / "src/server/Gameplay", ROOT / "src/server/Map")
              for p in folder.glob("*.luau")]
    return {path: digest(ROOT / path) for path in sorted(set(paths))}


def geometry_hook_fingerprint(shape):
    payload = {key: shape.get(key) for key in
               ("vfxHookRoblox", "vfxHooksRoblox", "vfxProfile")}
    return hashlib.sha256(json.dumps(payload, sort_keys=True, separators=(",", ":"),
                                    allow_nan=False).encode("utf-8")).hexdigest()


def verification_invalidation_reasons(review, fbx_hash, mesh_id, hook_hash, sources):
    """An approval is reusable only with the exact tested geometry and code."""
    if not review:
        return ["No immutable actual-test verification proof recorded."]
    reasons = []
    for key, expected in (("fbxSha256", fbx_hash), ("meshId", mesh_id),
                          ("geometryHookSha256", hook_hash)):
        if review.get(key) != expected:
            reasons.append(f"Changed or missing tested {key}.")
    observed = review.get("productionSourceFingerprints", {})
    changed = [path for path, value in sources.items() if observed.get(path) != value]
    if changed:
        reasons.append("Changed or missing tested production sources: " + ", ".join(changed))
    return reasons


def main():
    catalog = (ROOT / "src/shared/CurseCatalog.luau").read_text(encoding="utf-8")
    refblock = catalog.split("local referenceFiles = {", 1)[1].split("\n}", 1)[0]
    refs = re.findall(r'"([^"]+\.png)"', refblock)
    conceptblock = catalog.split("local concepts = {", 1)[1].split("\n}", 1)[0]
    concepts = re.findall(r'\{ "([a-z_]+)", "([^"]+)", "(COMMON|RARE|LEGENDARY|MYTHIC|SECRET)", (\d+) \}', conceptblock)
    assert len(concepts) == 50 and len(refs) == 12
    manifest = json.loads(MANIFEST.read_text(encoding="utf-8"))
    historical = {r["id"]: r for r in manifest["concepts"]}
    old = json.loads(LEDGER.read_text(encoding="utf-8")) if LEDGER.exists() else {}
    prior = {r["id"]: r for r in old.get("curses", [])}
    current_sources = production_source_fingerprints()
    shapes = {}
    imports = {}
    importpath = ROOT / "assets/imports/curse_rework_2026-10-01.json"
    if importpath.exists():
        imports = {r["id"]: r for r in json.loads(importpath.read_text(encoding="utf-8"))["imports"]}
    for reportpath in (SOURCE / "rework").glob("*_geometry.json"):
        report = json.loads(reportpath.read_text(encoding="utf-8"))
        for shape in report.get("assets", []):
            assert shape["id"] not in shapes, f"Duplicate rework geometry {shape['id']}"
            shapes[shape["id"]] = (shape, reportpath)
    records = []
    for cid, name, rarity, sheet in concepts:
        ref = refs[int(sheet) - 1]
        reference = ROOT / "assets/reference" / ref
        assert reference.is_file(), f"Missing current reference {reference}"
        previous = prior.get(cid, {})
        record = {"id": cid, "displayName": name, "rarity": rarity,
                  "sourceReference": ref, "referenceSha256": digest(reference),
                  "stages": {stage: False for stage in STAGES}, "evidence": {},
                  "notes": [], "currentFbxSha256": None}
        # All 12 current sheets were opened and visually reviewed by this task.
        record["stages"]["referenceReviewed"] = True
        legacy = historical[cid]
        record["historicalFirstWave"] = legacy.get("historicalFirstWave") or {key: legacy.get(key) for key in
            ("fbxExport", "fbxSha256", "meshId", "robloxImportVerified", "robloxAppearanceVerified")}
        if cid in shapes:
            shape, reportpath = shapes[cid]
            path = ROOT / shape["export"]
            actualhash = digest(path)
            record["currentFbxSha256"] = actualhash
            record["geometry"] = shape
            record["evidence"]["geometryReport"] = reportpath.relative_to(ROOT).as_posix()
            record["stages"]["fbxExported"] = True
            blend = ROOT / shape["blendSource"]
            record["stages"]["blenderModelComplete"] = blend.is_file()
            validationpath = reportpath.with_name(reportpath.name.replace("_geometry.json", "_validation.json"))
            if validationpath.exists():
                validation = json.loads(validationpath.read_text(encoding="utf-8"))
                result = next((v for v in validation.get("assets", []) if v["id"] == cid), {})
                if result.get("fbxSha256") == actualhash and result.get("status") == "FBX_ROUND_TRIP_PASS":
                    record["stages"]["locallyValidated"] = True
                    record["evidence"]["localValidation"] = validationpath.relative_to(ROOT).as_posix()
            imported = imports.get(cid, {})
            current_import = imported if imported.get("fbxSha256") == actualhash else {}
            # Imported appearance is independent of gameplay/VFX verification.
            if previous.get("currentFbxSha256") == actualhash:
                previous_mesh = previous.get("robloxImport", {}).get("meshId")
                current_mesh = current_import.get("meshId", previous_mesh)
                for stage in STAGES[4:6]:
                    if previous_mesh != current_mesh:
                        continue
                    record["stages"][stage] = previous.get("stages", {}).get(stage, False)
                record["evidence"].update(previous.get("evidence", {}))
                for field in ("robloxImport", "studioReview", "gameplayReview", "verification", "blockers"):
                    if field in previous:
                        record[field] = previous[field]
                proof = previous.get("verification", {})
                reasons = verification_invalidation_reasons(proof, actualhash, current_mesh,
                    geometry_hook_fingerprint(shape), current_sources)
                if not reasons:
                    for stage in STAGES[6:]:
                        record["stages"][stage] = previous.get("stages", {}).get(stage, False)
                elif any(previous.get("stages", {}).get(stage) for stage in STAGES[6:]):
                    record["verificationInvalidated"] = {"reasons": reasons,
                        "priorVerification": proof,
                        "atUtc": datetime.now(timezone.utc).isoformat()}
                    for key in ("vfx", "gameplay", "vfxReview", "gameplayReview"):
                        record["evidence"].pop(key, None)
            record["notes"] = shape.get("designNotes", [])
            if imported.get("fbxSha256") == actualhash and imported.get("meshId", "").startswith("rbxassetid://"):
                record["robloxImport"] = imported
                record["stages"]["realRobloxImportRecorded"] = True
                record["evidence"]["robloxImport"] = importpath.relative_to(ROOT).as_posix()
                if imported.get("studioAppearanceChecked"):
                    record["stages"]["studioAppearanceChecked"] = True
                    record["evidence"]["studioAppearance"] = imported["appearanceEvidence"]
            # A stale/incomplete prerequisite cannot remain enabled.
            if not all(record["stages"][stage] for stage in STAGES[:-1]):
                record["stages"]["enabled"] = False
        else:
            record["notes"] = ["Current reference rework not yet exported; historical import is not current-design approval."]
        records.append(record)
        legacy["sourceReference"] = ref
        legacy["referenceSheet"] = int(sheet)
    counts = {s: sum(r["stages"][s] for r in records) for s in STAGES}
    report = {"schemaVersion": 3, "task": "50-Curse current-reference rework",
              "initialBranch": "feature/final-map-polish-v2", "initialHead": "21dbc52",
              "initialWorkingTree": "Untracked assets/reference/ supplied by the user; no tracked changes.",
              "initialUserDate": old.get("initialUserDate", old.get("userDate", "2026-10-01 America/Bogota")),
              "userDate": datetime.now(timezone(timedelta(hours=-5))).date().isoformat() + " America/Bogota",
              "updatedAtUtc": datetime.now(timezone.utc).isoformat(),
              "productionSourceFingerprints": current_sources, "newCurseCount": 50,
              "preservedOriginalCount": 6, "counts": counts,
              "rules": "Stages are independent. Import/appearance evidence must match current FBX SHA256 and MeshId. VFX/gameplay/enabled approvals additionally require exact tested authored Catalog, NumberFormat, production sources and semantic geometry hooks. Generated enable ExpansionAssets/default/tests do not invalidate approval. Enable only after every required stage passes.",
              "curses": records}
    LEDGER.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    MANIFEST.write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print("CURSE_REWORK_PROGRESS", json.dumps(counts))


if __name__ == "__main__":
    main()
