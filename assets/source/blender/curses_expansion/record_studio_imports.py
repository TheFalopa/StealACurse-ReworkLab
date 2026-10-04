"""Merge a direct Studio observation; fail rather than infer mismatched imports."""
from pathlib import Path
import hashlib
import json
import math
import sys
import update_rework_progress

ROOT = update_rework_progress.ROOT


def main():
    observedpath = ROOT / (sys.argv[1] if len(sys.argv) > 1 else "assets/imports/curse_rework_observed.json")
    evidencepath = ROOT / "assets/imports/curse_rework_2026-10-01.json"
    report = json.loads(evidencepath.read_text(encoding="utf-8"))
    records = {r["id"]: r for r in report["imports"]}
    shapes = {}
    for path in (update_rework_progress.SOURCE / "rework").glob("*_geometry.json"):
        shapes.update({r["id"]: r for r in json.loads(path.read_text(encoding="utf-8"))["assets"]})
    added = []
    for observed in json.loads(observedpath.read_text(encoding="utf-8")):
        cid = observed["id"]
        if cid not in shapes:
            continue
        shape = shapes[cid]
        assert observed["observedPath"].startswith("Workspace."), f"Wrong observation scope {cid}"
        assert observed["meshId"].startswith("rbxassetid://"), f"Missing actual asset ID {cid}"
        assert math.dist(observed["meshSize"], shape["robloxIntendedSize"]) < .02, f"Imported geometry mismatch {cid}"
        assert math.dist(observed["size"], observed["meshSize"]) < .02, f"Imported scaling mismatch {cid}"
        digest = hashlib.sha256((ROOT / shape["export"]).read_bytes()).hexdigest()
        batchinfo = {}
        for validationpath in (update_rework_progress.SOURCE / "rework").glob("*_import_batch_validation.json"):
            batch = json.loads(validationpath.read_text(encoding="utf-8"))
            batchpath = batch.get("export") or batch.get("batch") or batch.get("batchExport")
            if not observed["observedPath"].startswith("Workspace." + Path(batchpath).stem + "."):
                continue
            batchhash = batch.get("batchSha256") or batch.get("fbxSha256")
            assert hashlib.sha256((ROOT / batchpath).read_bytes()).hexdigest() == batchhash, f"Changed import batch {cid}"
            component = next(r for r in batch.get("assets", batch.get("components", [])) if r["id"] == cid)
            componenthash = component.get("componentFbxSha256") or component.get("individualFBXSha256") or component.get("individualFbxSha256")
            assert componenthash == digest and "PASS" in component["status"], f"Batch no longer matches component {cid}"
            batchinfo = {"sourceBatch": batchpath, "sourceBatchSha256": batchhash,
                "batchValidation": validationpath.relative_to(ROOT).as_posix(),
                "componentFbxSha256": digest}
            break
        old = records.get(cid, {})
        if old and old["fbxSha256"] != digest:
            assert old["meshId"] != observed["meshId"], f"Changed FBX needs fresh Studio import {cid}"
            old = {}
        records[cid] = {**old, **observed, **batchinfo, "name": cid, "export": shape["export"],
            "source": shape["export"], "fbxSha256": digest,
            "sourceReference": shape["sourceReference"], "status": "IMPORTED",
            "gameplayValidated": False}
        added.append(cid)
    report["imports"] = list(records.values())
    evidencepath.write_text(json.dumps(report, indent=2)+"\n", encoding="utf-8")
    print("REAL_STUDIO_IMPORTS", len(records), "OBSERVED", ", ".join(added))


if __name__ == "__main__":
    main()
