"""Read-only current Curse source/import/runtime audit (Python standard library).

Run from any directory with Python, or Blender's bundled Python:
  python tests/check_curse_rework.py --require-import-count 50

Only the requested JSON report is written. Geometry assertions are bound to the
actual FBX bytes via the independently saved Blender round-trip report SHA256;
this audit does not claim to rerun Blender or observe Studio gameplay.
"""
from pathlib import Path
from collections import Counter
from datetime import datetime, timezone
import argparse
import hashlib
import importlib.util
import json
import math
import re
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "assets/source/blender/curses_expansion/rework"
ORIGINAL = ("cursed_doll", "haunted_mirror", "crying_mask", "watching_eye", "soul_chains", "the_void")
SHEETS = [
    ("COMMON", ["Candle Wisp", "Grave Hopper", "Grave Key", "Mourning Ribbon", "Wilted Sprout"]),
    ("COMMON", ["Ink Imp", "Lost Locket", "Ashen Book", "Lantern Lurker", "Hourglass Hound"]),
    ("COMMON", ["Nail Beetle", "Pale Guest", "Cold Teacup", "Coin Crawler", "Umbrella Wraith"]),
    ("RARE", ["Marrow Dice", "Veil Mourner", "Grave Compass", "Hollow Violin", "Chime Triplets"]),
    ("RARE", ["Thimble Spider", "Music Box Dancer", "Raven Quill", "Sorrow Chalice", "Pale Gramophone"]),
    ("RARE", ["Thorn Reliquary", "Anchor Crab", "Sundial Sentinel", "Sleepwalker Shoes"]),
    ("LEGENDARY", ["Night Harp", "Thorn Cathedral", "Phantom Marionette", "Blood Moon Rose", "Judgement Scales"]),
    ("LEGENDARY", ["Clockwork Raven", "Eclipse Stag", "Endless Library", "Sunken Crown", "Silent Choir"]),
    ("MYTHIC", ["Cathedral Heart", "Plague Monarch", "Hollow Throne"]),
    ("MYTHIC", ["Worldroot", "The Undertow", "The Last Funeral"]),
    ("SECRET", ["Nameless Door", "Crown of Silence", "The First Grave"]),
    ("SECRET", ["The Unwritten", "The Last Star"]),
]
EXPECTED = {name.lower().replace(" ", "_"): {"id": name.lower().replace(" ", "_"),
    "displayName": name, "rarity": rarity, "referenceSheet": index,
    "sourceReference": f"rework-{index:02d}-{rarity.lower()}.png"}
    for index, (rarity, names) in enumerate(SHEETS, 1) for name in names}
STAGES = ("referenceReviewed", "blenderModelComplete", "locallyValidated", "fbxExported",
          "realRobloxImportRecorded", "studioAppearanceChecked", "vfxChecked", "gameplayChecked", "enabled")
progress_spec = importlib.util.spec_from_file_location("approval_fingerprints",
    ROOT / "assets/source/blender/curses_expansion/update_rework_progress.py")
approval_fingerprints = importlib.util.module_from_spec(progress_spec)
progress_spec.loader.exec_module(approval_fingerprints)


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def close(a, b, tolerance=1e-6):
    return isinstance(a, (list, tuple)) and isinstance(b, (list, tuple)) and len(a) == len(b) and all(
        isinstance(x, (float, int)) and math.isfinite(x) and abs(x-y) <= tolerance for x, y in zip(a, b))


def blocks(text):
    """Read generated identifier = {...} blocks without evaluating Luau."""
    result = {}
    for match in re.finditer(r"(?m)^\s*([a-z][a-z0-9_]*)\s*=\s*\{", text):
        start = text.index("{", match.start()); depth = 0; quoted = False; escaped = False
        for end in range(start, len(text)):
            character = text[end]
            if quoted:
                if escaped: escaped = False
                elif character == "\\": escaped = True
                elif character == '"': quoted = False
            elif character == '"': quoted = True
            elif character == "{": depth += 1
            elif character == "}":
                depth -= 1
                if depth == 0:
                    result[match.group(1)] = text[start:end+1]; break
    return result


def field(block, name, default=None):
    match = re.search(r"\b" + re.escape(name) + r'\s*=\s*("[^"\n]*"|true|false|Vector3\.new\([^)]*\))', block)
    if not match: return default
    value = match.group(1)
    if value.startswith('"'): return value[1:-1]
    if value in ("true", "false"): return value == "true"
    return [float(v.strip()) for v in value[value.index("(")+1:-1].split(",")]


def git_blob(path):
    process = subprocess.run(["git", "show", "HEAD:" + path], cwd=ROOT, capture_output=True)
    return process.stdout if process.returncode == 0 else None


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--require-import-count", type=int, default=0)
    parser.add_argument("--require-enabled-count", type=int, default=-1)
    parser.add_argument("--output", default="assets/review/curse-rework/static-audit.json")
    args = parser.parse_args()
    gated_sources = approval_fingerprints.production_source_fingerprints()
    report = {"schemaVersion": 1, "auditedAtUtc": datetime.now(timezone.utc).isoformat(),
        "method": "Read-only file hashes, frozen actual Blender round-trip reports, observed import evidence, runtime mappings, and Git HEAD comparison",
        "limitations": ["Does not execute Studio, measure mobile device performance, or grant appearance/gameplay stages.",
            "Does not reopen Blender sources; current FBX geometry checks are bound to recorded actual Blender round-trip SHA256."],
        "checks": [], "assets": [], "batches": [], "originalSix": [], "warnings": []}
    def check(value, code, id=None, detail=None):
        entry = {"code": code, "status": "PASS" if value else "FAIL"}
        if id: entry["id"] = id
        if detail is not None: entry["detail"] = detail
        report["checks"].append(entry)
        return bool(value)
    def read_json(path):
        try: return json.loads((ROOT/path).read_text(encoding="utf-8-sig"))
        except (OSError, ValueError) as error:
            check(False, "JSON_READ", detail=f"{path}: {error}"); return {}
    def read_text(path):
        try: return (ROOT/path).read_text(encoding="utf-8-sig")
        except OSError as error:
            check(False, "TEXT_READ", detail=f"{path}: {error}"); return ""
    def safe_file(relative, code, id):
        if not isinstance(relative, str): check(False, code, id, "Missing path"); return None
        path = (ROOT/relative).resolve()
        if not path.is_relative_to(ROOT) or not path.is_file(): check(False, code, id, relative); return None
        check(True, code, id, relative); return path

    ledger = read_json("assets/curse-expansion-progress.json")
    manifest = read_json("assets/source/blender/curses_expansion/curse_expansion_manifest.json")
    import_file = read_json("assets/imports/curse_rework_2026-10-01.json")
    project = read_json("default.project.json")
    catalog = read_text("src/shared/CurseCatalog.luau")
    runtime_text = read_text("src/shared/CurseExpansionAssets.luau")
    vfx_text = read_text("src/shared/CurseVFXProfiles.luau")
    client_text = read_text("src/client/CurseVFX.luau")
    visual_text = read_text("src/server/Gameplay/CurseVisualService.luau")
    runtime = blocks(runtime_text)
    ledger_rows = ledger.get("curses", []); manifest_rows = manifest.get("concepts", [])
    imported_rows = import_file.get("imports", [])
    led = {row["id"]: row for row in ledger_rows}; man = {row["id"]: row for row in manifest_rows}
    imports = {row["id"]: row for row in imported_rows}
    kit = project.get("tree", {}).get("ServerStorage", {}).get("CurseMeshKit", {})
    check(len(ledger_rows) == 50 and set(led) == set(EXPECTED), "LEDGER_EXACT_50_ROSTER")
    check(len(manifest_rows) == 50 and set(man) == set(EXPECTED), "MANIFEST_EXACT_50_ROSTER")
    check(set(runtime) == set(EXPECTED), "RUNTIME_EXACT_50_ROSTER")
    concepts = re.findall(r'\{\s*"([a-z_]+)",\s*"([^"]+)",\s*"(COMMON|RARE|LEGENDARY|MYTHIC|SECRET)",\s*(\d+)\s*\}', catalog)
    expected_tuples = [(id, row["displayName"], row["rarity"], str(row["referenceSheet"])) for id, row in EXPECTED.items()]
    check(concepts == expected_tuples, "CATALOG_EXACT_REFERENCE_ROSTER_ORDER")
    reference_block = re.search(r"local referenceFiles = \{(.*?)\n\}", catalog, re.S)
    references = re.findall(r'"([^"]+)"', reference_block.group(1)) if reference_block else []
    check(references == [f"rework-{i:02d}-{rarity.lower()}.png" for i, (rarity, _) in enumerate(SHEETS, 1)], "CATALOG_EXACT_12_REFERENCE_SHEETS")
    check(manifest.get("schemaVersion") == 2, "MANIFEST_CURRENT_SCHEMA_2")
    check(manifest.get("totalPlannedCatalogCount") == 56 and manifest.get("preservedExistingCount") == 6, "TOTAL_56_METADATA")
    check(manifest.get("rarityCounts") == dict(Counter(r["rarity"] for r in EXPECTED.values())), "MANIFEST_RARITY_COUNTS")
    check(len(imported_rows) == len(imports) and set(imports).issubset(EXPECTED), "IMPORT_IDS_UNIQUE_CURRENT_ROSTER")
    check(len({r.get("meshId") for r in imported_rows}) == len(imported_rows), "IMPORTED_MESH_IDS_DISTINCT")

    geometry, validation, batch_components = {}, {}, {}
    for group, count in (("common", 15), ("rare", 14), ("high", 21)):
        shapes = read_json(f"assets/source/blender/curses_expansion/rework/{group}_geometry.json").get("assets", [])
        validations = read_json(f"assets/source/blender/curses_expansion/rework/{group}_validation.json").get("assets", [])
        expected_group = {id for id, r in EXPECTED.items() if (r["rarity"] == group.upper() or (group == "high" and r["rarity"] in {"LEGENDARY", "MYTHIC", "SECRET"}))}
        check(len(shapes) == count and {r["id"] for r in shapes} == expected_group, "GEOMETRY_GROUP_EXACT_ROSTER", group)
        check(len(validations) == count and {r["id"] for r in validations} == expected_group, "VALIDATION_GROUP_EXACT_ROSTER", group)
        geometry.update({r["id"]: r for r in shapes}); validation.update({r["id"]: r for r in validations})
        batch_report = read_json(f"assets/source/blender/curses_expansion/rework/{group}_import_batch_validation.json")
        batch_path = batch_report.get("export", batch_report.get("batchExport", batch_report.get("batch")))
        batch_hash = batch_report.get("fbxSha256", batch_report.get("batchSha256"))
        path = safe_file(batch_path, "BATCH_EXPORT_EXISTS", group)
        check(path is not None and sha(path) == batch_hash, "BATCH_CURRENT_HASH", group)
        parts = batch_report.get("assets", batch_report.get("components", []))
        check(len(parts) == count and {r["id"] for r in parts} == expected_group, "BATCH_COMPONENT_EXACT_ROSTER", group)
        check("PASS" in batch_report.get("status", ""), "BATCH_ACTUAL_ROUND_TRIP_PASS", group)
        for component in parts:
            component["_batchExport"] = batch_path; component["_batchHash"] = batch_hash
            batch_components[component["id"]] = component
        report["batches"].append({"group": group, "export": batch_path, "sha256": batch_hash, "componentCount": len(parts)})

    profile_matches = list(re.finditer(r'(?m)^\s*([a-z_]+) = profile\(([^\n]*)\),?\s*$', vfx_text))
    profiles = {m.group(1): m.group(2) for m in profile_matches}
    check(len(profile_matches) == 50 and set(profiles) == set(EXPECTED), "NATIVE_VFX_EXACT_50_PROFILES")
    descriptions = [re.match(r'"([^"]+)"', value).group(1) for value in profiles.values()]
    check(len(set(descriptions)) == 50, "NATIVE_VFX_50_DISTINCT_CONCEPT_DESCRIPTIONS")
    check(client_text.count("RunService.Heartbeat:Connect") == 1 and "if started then return end" in client_text, "NATIVE_VFX_ONE_IDEMPOTENT_SHARED_UPDATE")
    check('if mobile then 12 else 20' in client_text and 'if mobile then 58 else 85' in client_text and 'lights < 2 and not mobile' in client_text, "NATIVE_VFX_MOBILE_DESKTOP_BUDGET_GATES")
    check('rbxasset://textures/particles/' in client_text and not re.search(r"https?://", client_text), "NATIVE_VFX_BUILTIN_PARTICLE_TEXTURES")
    check('CollectionService:AddTag(model, "ExpansionCurseVFX")' in visual_text and 'definition.vfxHooks or {}' in visual_text, "SERVER_AUTHORED_SEMANTIC_VFX_HOOKS")
    check('spawnWeight = if asset.enabled then weights[rarity] else 0' in catalog and 'definition.enabled ~= false and definition.spawnWeight > 0' in catalog, "RUNTIME_SPAWN_STAGE_GATE")

    for id, expected in EXPECTED.items():
        row, concept, shape, qa, component = led.get(id, {}), man.get(id, {}), geometry.get(id, {}), validation.get(id, {}), batch_components.get(id, {})
        rt = runtime.get(id, ""); stages = row.get("stages", {})
        start = len(report["checks"])
        for key in ("displayName", "rarity", "sourceReference"):
            check(row.get(key) == expected[key], "LEDGER_REFERENCE_METADATA_" + key.upper(), id)
            check(concept.get(key) == expected[key], "MANIFEST_REFERENCE_METADATA_" + key.upper(), id)
        reference = safe_file("assets/reference/" + expected["sourceReference"], "REFERENCE_EXISTS", id)
        check(reference is not None and sha(reference) == row.get("referenceSha256"), "REFERENCE_CURRENT_SHA256", id)
        check(Path(shape.get("sourceReference", "")).name == expected["sourceReference"], "GEOMETRY_EXACT_REFERENCE", id)
        source = safe_file(shape.get("blendSource"), "EDITABLE_BLEND_EXISTS", id)
        fbx = safe_file(shape.get("export"), "CURRENT_INDIVIDUAL_FBX_EXISTS", id)
        check(shape.get("blendSource") == f"assets/source/blender/curses_expansion/rework/{id}.blend"
              and shape.get("export") == f"assets/export/meshes/curses/rework/{id}.fbx", "DEDICATED_CURRENT_REWORK_SOURCE_EXPORT_PATH", id)
        current = sha(fbx) if fbx else None
        if source:
            header = source.read_bytes()[:8]
            check(source.stat().st_size > 5000 and (header.startswith(b"BLENDER") or header.startswith(b"\x28\xb5\x2f\xfd")), "REAL_BLEND_FILE_HEADER", id)
        check(fbx is not None and fbx.stat().st_size > 1024 and fbx.read_bytes().startswith(b"Kaydara FBX Binary"), "REAL_FBX_FILE_HEADER", id)
        check(current == shape.get("sha256") == row.get("currentFbxSha256") == qa.get("fbxSha256"), "FBX_GEOMETRY_LEDGER_ROUND_TRIP_SHA256", id)
        check(current == concept.get("fbxSha256") == field(rt, "fbxSha256"), "MANIFEST_RUNTIME_CURRENT_FBX_SHA256", id)
        check(concept.get("blendSource") == shape.get("blendSource") and concept.get("fbxExport") == shape.get("export"), "MANIFEST_CURRENT_SOURCE_PATHS", id)
        check(qa.get("status") == "FBX_ROUND_TRIP_PASS" and qa.get("valid") is True, "ACTUAL_INDIVIDUAL_FBX_ROUND_TRIP_PASS", id)
        check(all(qa.get(k) == 0 for k in ("nonManifoldEdges", "looseVertices", "degenerateFaces")), "FINITE_CLOSED_CLEAN_GEOMETRY_QA", id)
        check(shape.get("triangles") == qa.get("triangleCount") and shape.get("vertices", 0) > 0, "ROUND_TRIP_TRIANGLE_VERTEX_COUNTS", id)
        check(qa.get("uvLayers") == 1 and qa.get("materials") == 1 and qa.get("colorCount", 0) >= 20 and shape.get("colorLayer") == "SACPaintedColor", "ROUND_TRIP_AUTHORED_UV_PAINT_MATERIAL", id)
        size = shape.get("robloxIntendedSize", [])
        check(len(size) == 3 and all(math.isfinite(v) and v > 0 for v in size) and math.sqrt(sum(v*v for v in size)) < 7, "INDIVIDUAL_AUTHORED_GAME_SCALE_CLEARANCE", id)
        expected_fbx_size = [size[0]*.01, size[2]*.01, size[1]*.01] if len(size) == 3 else []
        check(close(qa.get("fbxDimensions"), expected_fbx_size, .0001) and close(qa.get("center"), [0, 0, 0], .0001), "FBX_SCALE_PERMUTATION_CENTER", id)
        component_hash = component.get("componentFbxSha256", component.get("individualFBXSha256", component.get("individualFbxSha256")))
        check(component_hash == current and "PASS" in component.get("status", ""), "BATCH_FROZEN_COMPONENT_HASH_ROUND_TRIP", id)
        component_size = component.get("dimensions", component.get("roundtripDimensions"))
        check(close(component_size, qa.get("fbxDimensions"), 1e-6) and component.get("triangles") == shape.get("triangles"), "BATCH_COMPONENT_EXACT_BOUNDS_TRIANGLES", id)
        color_count = component.get("colorCount", component.get("paintedColors", component.get("paintedColorCount")))
        if color_count is not None: check(color_count == qa.get("colorCount"), "BATCH_COMPONENT_PAINT_COUNT", id)
        check(close(field(rt, "vfxHook"), shape.get("vfxHookRoblox"), 1e-8) and field(rt, "vfxProfile") == shape.get("vfxProfile"), "RUNTIME_AUTHORED_VFX_MAIN_HOOK_PROFILE", id)
        for name, hook in shape.get("vfxHooksRoblox", {}).items():
            check(close(field(rt, name), hook, 1e-8), "RUNTIME_AUTHORED_SEMANTIC_VFX_DETAIL_" + name, id)
        check(field(rt, "sourceReference") == expected["sourceReference"], "RUNTIME_CURRENT_REFERENCE", id)
        check(all(isinstance(stages.get(stage), bool) for stage in STAGES), "EXPLICIT_INDEPENDENT_STAGE_FLAGS", id)
        check(stages.get("blenderModelComplete") == bool(shape.get("modelComplete"))
              and stages.get("locallyValidated") == (qa.get("status") == "FBX_ROUND_TRIP_PASS")
              and stages.get("fbxExported") == bool(fbx), "SOURCE_EXPORT_QA_STAGE_COUNTS_BOUND_TO_EVIDENCE", id)
        # Stage prerequisites and enablement are independent of production odds.
        if stages.get("fbxExported"): check(stages.get("blenderModelComplete") and stages.get("referenceReviewed"), "EXPORTED_REQUIRES_REVIEWED_MODEL", id)
        if stages.get("realRobloxImportRecorded"): check(stages.get("locallyValidated") and stages.get("fbxExported"), "IMPORTED_REQUIRES_CURRENT_LOCAL_QA", id)
        for stage in ("studioAppearanceChecked", "vfxChecked", "gameplayChecked"):
            if stages.get(stage): check(stages.get("realRobloxImportRecorded"), "VERIFIED_STAGE_REQUIRES_CURRENT_IMPORT_" + stage, id)
        if any(stages.get(stage) for stage in ("vfxChecked", "gameplayChecked", "enabled")):
            proof = row.get("verification", {})
            invalidations = approval_fingerprints.verification_invalidation_reasons(proof, current,
                imports.get(id, {}).get("meshId"), approval_fingerprints.geometry_hook_fingerprint(shape), gated_sources)
            check(not invalidations, "ACTUAL_APPROVAL_SOURCE_MESH_HOOK_FINGERPRINTS_CURRENT", id, invalidations)
            eligibility = safe_file(proof.get("eligibilityReport"), "ACTUAL_TEST_ELIGIBILITY_REPORT_EXISTS", id)
            if eligibility:
                observed = json.loads(eligibility.read_text(encoding="utf-8-sig"))
                check(observed.get("status") == "ACTUAL_TESTS_ELIGIBLE" and observed.get("eligible") is True
                      and observed.get("testedCount") == 50, "FULL_ACTUAL_ROUTE_PURCHASE_DESKTOP_MOBILE_EVIDENCE_GATE", id)
            for scope, evidence in proof.get("inputs", {}).items():
                evidence_file = safe_file(evidence.get("path"), "ACTUAL_TEST_INPUT_EXISTS_" + scope, id)
                if evidence_file:
                    check(sha(evidence_file) == evidence.get("sha256"), "ACTUAL_TEST_INPUT_SHA256_" + scope, id)
        if stages.get("enabled"): check(all(stages.get(stage) for stage in STAGES[:-1]), "ENABLED_REQUIRES_ALL_CURRENT_STAGES", id)
        expected_enabled = all(stages.get(stage) for stage in STAGES)
        check(field(rt, "enabled") == expected_enabled and concept.get("enabled") == stages.get("enabled"), "RUNTIME_MANIFEST_ENABLEMENT_GATE", id)
        imported = imports.get(id)
        imported_stage = bool(stages.get("realRobloxImportRecorded"))
        check(bool(imported) == imported_stage, "OBSERVED_IMPORT_EQUALS_LEDGER_STAGE", id)
        status = "VALIDATED" if stages.get("gameplayChecked") else "IMPORTED" if imported_stage else "EXPORTED" if stages.get("fbxExported") else "PLANNED"
        check(field(rt, "status") == concept.get("implementationStatus") == status, "RUNTIME_MANIFEST_STAGE_STATUS", id)
        if imported:
            mesh_id = imported.get("meshId", ""); template = kit.get(id, {}).get("$properties", {})
            check(re.fullmatch(r"rbxassetid://[1-9][0-9]+", mesh_id) is not None, "ACTUAL_OBSERVED_MESH_ID", id)
            check(imported.get("fbxSha256") == current, "OBSERVED_IMPORT_CURRENT_SOURCE_HASH", id)
            history = row.get("historicalFirstWave") or {}
            if history.get("meshId"):
                check(mesh_id != history["meshId"] and current != history.get("fbxSha256"), "REWORK_NEVER_REUSES_HISTORICAL_GEOMETRY_IMPORT_ID", id)
            check(Path(imported.get("sourceReference", "")).name == expected["sourceReference"], "OBSERVED_IMPORT_CURRENT_REFERENCE", id)
            check(mesh_id == template.get("MeshId") == field(rt, "meshId") == concept.get("meshId"), "OBSERVED_TEMPLATE_RUNTIME_MANIFEST_REAL_MESH_ID", id)
            check(close(imported.get("size"), size, .02) and close(imported.get("meshSize"), size, .02), "OBSERVED_IMPORTED_AUTHORED_SIZE", id)
            check(close(template.get("Size"), imported.get("size"), 1e-7) and close(template.get("InitialSize"), imported.get("meshSize"), 1e-7), "TEMPLATE_REAL_SIZE_INITIALSIZE", id)
            check(field(rt, "originalVertexColors") == bool(imported.get("studioAppearanceChecked")), "RUNTIME_CURRENT_SURFACE_APPEARANCE_GATE", id)
            if imported.get("sourceBatch"):
                check(imported["sourceBatch"] == component.get("_batchExport") and imported.get("sourceBatchSha256") == component.get("_batchHash"), "OBSERVED_BATCH_PROVENANCE", id)
                check(imported.get("componentFbxSha256") == current, "OBSERVED_BATCH_COMPONENT_SOURCE_HASH", id)
        failures = [c["code"] for c in report["checks"][start:] if c["status"] == "FAIL"]
        report["assets"].append({"id": id, "status": "FAIL" if failures else "PASS", "sourceReference": expected["sourceReference"],
            "fbxSha256": current, "blendSha256": sha(source) if source else None, "triangles": shape.get("triangles"),
            "robloxIntendedSize": size, "realImportRecorded": imported_stage, "meshId": imported.get("meshId") if imported else None,
            "stages": stages, "failedChecks": failures})

    actual_counts = {stage: sum(bool(row.get("stages", {}).get(stage)) for row in ledger_rows) for stage in STAGES}
    check(ledger.get("counts") == actual_counts, "DURABLE_STAGE_COUNTS_EXACT")
    check(manifest.get("stageCounts") == actual_counts, "MANIFEST_STAGE_COUNTS_EXACT")
    check(manifest.get("remainingUnmodeledCount") == 50-actual_counts["blenderModelComplete"], "MANIFEST_REMAINING_MODEL_COUNT_EXACT")
    if args.require_import_count: check(len(imports) == args.require_import_count, "REQUESTED_IMPORT_COUNT", detail={"expected": args.require_import_count, "actual": len(imports)})
    if args.require_enabled_count >= 0: check(actual_counts["enabled"] == args.require_enabled_count, "REQUESTED_ENABLED_COUNT", detail={"expected": args.require_enabled_count, "actual": actual_counts["enabled"]})
    if len(imports) < 50: report["warnings"].append(f"{50-len(imports)} current-source Studio imports are still pending; the audit does not invent them.")
    if actual_counts["gameplayChecked"] < 50: report["warnings"].append(f"{50-actual_counts['gameplayChecked']} current-source gameplay stages are still pending.")

    head_catalog_bytes = git_blob("src/shared/CurseCatalog.luau")
    head_project_bytes = git_blob("default.project.json")
    head_visual_bytes = git_blob("src/server/Gameplay/CurseVisualService.luau")
    check(all((head_catalog_bytes, head_project_bytes, head_visual_bytes)), "ORIGINAL_GIT_HEAD_AVAILABLE")
    head_catalog = head_catalog_bytes.decode() if head_catalog_bytes else ""
    original_now, original_head = blocks(catalog), blocks(head_catalog)
    head_project = json.loads(head_project_bytes) if head_project_bytes else {}
    head_kit = head_project.get("tree", {}).get("ServerStorage", {}).get("CurseMeshKit", {})
    head_visual = head_visual_bytes.decode() if head_visual_bytes else ""
    for id in ORIGINAL:
        unchanged = check(original_now.get(id) == original_head.get(id) and id in original_now, "ORIGINAL_DEFINITION_ECONOMY_COLOR_UNCHANGED", id)
        unchanged &= check(kit.get(id) == head_kit.get(id) and id in kit, "ORIGINAL_TEMPLATE_MESH_ID_SIZE_UNCHANGED", id)
        export_path = f"assets/export/meshes/{id}.fbx"
        original_fbx = git_blob(export_path); actual_fbx = ROOT/export_path
        unchanged &= check(original_fbx is not None and actual_fbx.is_file() and actual_fbx.read_bytes() == original_fbx,
                           "ORIGINAL_FBX_BYTES_UNCHANGED", id)
        pattern = r'(?:if|elseif) definition\.id == "' + id + r'" then(.*?)(?=\n\telseif definition\.|\n\tend\nend)'
        now_branch, old_branch = re.search(pattern, visual_text, re.S), re.search(pattern, head_visual, re.S)
        unchanged &= check(bool(now_branch and old_branch and now_branch.group(1) == old_branch.group(1)), "ORIGINAL_IDENTITY_ACCENTS_UNCHANGED", id)
        report["originalSix"].append({"id": id, "unchangedAgainstHead": bool(unchanged), "meshId": kit.get(id, {}).get("$properties", {}).get("MeshId")})
    for path in ("src/server/Gameplay/BaseService.luau", "src/server/Gameplay/CurseService.luau", "src/server/Gameplay/CurseProcessionService.luau", "src/server/Gameplay/SoulsService.luau", "src/server/Gameplay/Config.luau",
                 "assets/source/blender/generate_curses.py", "assets/source/blender/steal_a_curse_curses.blend"):
        original = git_blob(path)
        check(original is not None and (ROOT/path).read_bytes().replace(b"\r\n", b"\n") == original.replace(b"\r\n", b"\n"), "PRODUCTION_GAMEPLAY_SERVICE_UNCHANGED", detail=path)
    tracked = subprocess.run(["git", "ls-tree", "-r", "--name-only", "HEAD", "assets/export/meshes/curses"], cwd=ROOT, capture_output=True, text=True)
    preserved_exports = 0
    for path in tracked.stdout.splitlines():
        if path.endswith(".fbx"):
            original = git_blob(path); current = ROOT/path
            check(current.is_file() and original is not None and current.read_bytes() == original, "HISTORICAL_CURSE_FBX_PRESERVED", detail=path)
            preserved_exports += 1
    check(preserved_exports >= 6, "HISTORICAL_ORIGINAL_EXPORTS_PRESENT")
    original_order = re.search(r"Catalog.Order = \{(.*?)\n\}", catalog, re.S)
    check(original_order is not None and re.findall(r'"([^"]+)"', original_order.group(1)) == list(ORIGINAL), "ORIGINAL_SIX_ORDER_PRESERVED")

    failures = [c for c in report["checks"] if c["status"] == "FAIL"]
    report["status"] = "FAIL" if failures else "PASS"
    report["summary"] = {"checks": len(report["checks"]), "passed": len(report["checks"])-len(failures), "failed": len(failures),
        "exactNewRoster": len(EXPECTED), "totalCatalogMetadata": 56, "totalTriangles": sum(r.get("triangles", 0) for r in geometry.values()),
        "observedCurrentImports": len(imports), "stageCounts": actual_counts, "historicalExportsPreserved": preserved_exports,
        "originalSixUnchanged": all(r["unchangedAgainstHead"] for r in report["originalSix"])}
    output = (ROOT/args.output).resolve()
    if not output.is_relative_to(ROOT): raise ValueError("Audit output must stay in the project")
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(report, indent=2)+"\n", encoding="utf-8")
    print("CURSE_REWORK_STATIC_AUDIT", json.dumps(report["summary"], separators=(",", ":")))
    for failure in failures[:35]: print("AUDIT_FAIL", failure.get("id", ""), failure["code"], failure.get("detail", ""))
    return 1 if failures else 0


if __name__ == "__main__": sys.exit(main())
