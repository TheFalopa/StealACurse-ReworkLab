"""Audit actual Studio observations before granting current-Curse stage credit.

Default is read-only except the eligibility report. --apply is an explicit final
step after the orchestrator supplies complete observed JSON, never a substitute
for running Studio. Legacy log rows remain useful scoped route observations but
cannot satisfy the immutable-source gate. Generated enabling files and fixture
source hashes are recorded as provenance, not approval invalidation inputs.
"""
from pathlib import Path
from datetime import datetime, timezone
import argparse
import hashlib
import importlib.util
import json
import math
import re

ROOT = Path(__file__).resolve().parents[1]
PROGRESS_PATH = ROOT / "assets/source/blender/curses_expansion/update_rework_progress.py"
spec = importlib.util.spec_from_file_location("rework_progress", PROGRESS_PATH)
progress = importlib.util.module_from_spec(spec)
spec.loader.exec_module(progress)


def read_json(path):
    return json.loads(path.read_text(encoding="utf-8-sig"),
                      parse_constant=lambda value: (_ for _ in ()).throw(ValueError("Nonfinite JSON: " + value)))


def finite(value):
    return isinstance(value, (int, float)) and not isinstance(value, bool) and math.isfinite(value)


def v3(value):
    return isinstance(value, list) and len(value) == 3 and all(finite(v) for v in value)


def close_vector(a, b, tolerance=.001):
    return v3(a) and v3(b) and math.dist(a, b) < tolerance


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--route", type=Path, help="Complete fresh native Route report JSON")
    parser.add_argument("--purchase", type=Path, help="Complete fresh PurchaseAndStress report JSON")
    parser.add_argument("--mobile", type=Path, help="Complete actual mobile Stress JSON; may be the same mobile PurchaseAndStress file")
    parser.add_argument("--desktop-stress", type=Path, help="Separate actual desktop Stress JSON when purchase ran with TouchEnabled")
    parser.add_argument("--legacy-route", type=Path, help="Optional old route log observations, never credited as immutable-source proof")
    parser.add_argument("--output", type=Path, default=ROOT / "assets/review/curse-rework/verification-eligibility.json")
    parser.add_argument("--apply", action="store_true", help="Explicitly record eligible actual-test VFX/gameplay stages; never enable")
    args = parser.parse_args()
    ledger = read_json(progress.LEDGER)
    current = {row["id"]: row for row in ledger["curses"]}
    sources = progress.production_source_fingerprints()
    shapes, geometry_reports = {}, {}
    for path in (PROGRESS_PATH.parent / "rework").glob("*_geometry.json"):
        geometry_reports[path.relative_to(ROOT).as_posix()] = progress.digest(path)
        for row in read_json(path).get("assets", []):
            if row["id"] in shapes:
                raise ValueError("Duplicate current geometry: " + row["id"])
            shapes[row["id"]] = row
    profiles = {}
    for line in (ROOT / "src/shared/CurseVFXProfiles.luau").read_text(encoding="utf-8").splitlines():
        found = re.match(r'\s*([a-z_]+) = profile\(', line)
        if found:
            profiles[found[1]] = re.findall(r'"([^"]+)"', line)[-1]
    original = {"cursed_doll", "haunted_mirror", "crying_mask", "watching_eye", "soul_chains", "the_void"}
    failures, inputs, results, checks = [], {}, {}, 0

    def check(condition, label):
        nonlocal checks
        checks += 1
        if not condition:
            failures.append(label)
        return bool(condition)

    def load_observation(name, path):
        if not path:
            check(False, f"Missing actual {name} observation file")
            return {}
        if not path.is_absolute():
            path = ROOT / path
        if not check(path.is_file(), f"Missing actual {name} observation: {path}"):
            return {}
        raw = read_json(path)
        data = raw.get("report", raw.get("observedReport", raw))
        if not check(isinstance(data, dict), f"{name} does not contain a complete JSON report"):
            return {}
        inputs[name] = {"path": path.relative_to(ROOT).as_posix() if path.is_relative_to(ROOT) else str(path),
                        "sha256": progress.digest(path), "builtAtUtc": data.get("builtAtUtc")}
        check(data.get("phase") == "passed", f"{name} native fixture did not finish passed")
        check(data.get("failures") == [], f"{name} contains failures or missing failure list")
        check(data.get("currentImportedCount") == 50, f"{name} did not contain all fifty imported definitions")
        seen_sources = data.get("sourceFingerprints", {})
        for source, sha in sources.items():
            if name == "route" and source == "src/shared/NumberFormat.luau":
                inputs[name]["formattingScope"] = "Formatter hash required from actual purchase/label/stress proof; route movement proof does not credit label formatting"
                continue
            check(seen_sources.get(source) == sha, f"{name} stale/missing production source: {source}")
        for source, sha in geometry_reports.items():
            check(seen_sources.get(source) == sha, f"{name} stale/missing authored geometry hook report: {source}")
        assets = data.get("assets", [])
        check(len(assets) == 50 and {r.get("id") for r in assets} == set(current), f"{name} roster differs from exact fifty current IDs")
        for row in assets:
            cid = row.get("id")
            if cid not in current:
                continue
            expected = current[cid]
            check(row.get("fbxSha256") == expected.get("currentFbxSha256") == progress.digest(ROOT / shapes[cid]["export"]), f"{name}/{cid} FBX bytes differ")
            check(row.get("meshId") == expected.get("robloxImport", {}).get("meshId"), f"{name}/{cid} real MeshId differs")
        metadata = data.get("catalogMetadata", {})
        entries = metadata.get("entries", [])
        check(metadata.get("total") == 56 and metadata.get("original") == 6 and metadata.get("expansion") == 50
              and len(entries) == 56 and {r.get("id") for r in entries} == original | set(current), f"{name} lacks exact56 metadata proof")
        for entry in entries:
            check(bool(entry.get("displayName")) and entry.get("rarity") in {"COMMON", "RARE", "LEGENDARY", "MYTHIC", "SECRET"}
                  and finite(entry.get("price")) and entry["price"] > 0 and finite(entry.get("income")) and entry["income"] > 0
                  and bool(entry.get("futureEffectId")) and str(entry.get("meshId", "")).startswith("rbxassetid://"), f"{name} incomplete metadata {entry.get('id')}")
        world = data.get("worldPolish", {})
        check(world.get("status") == "PASS" and finite(world.get("parts")) and 0 < world["parts"] <= 214
              and finite(world.get("lights")) and world["lights"] <= 2 and world.get("missingTemplates") == 0
              and world.get("collidingParts") == 0 and world.get("collisionHulls") == 0, f"{name} world scoped budget/collision proof missing")
        check(finite(world.get("groundedMeshes")) and world["groundedMeshes"] > 0 and world.get("groundingAttributesMissing") == 0
              and finite(world.get("maximumGroundingBoundError")) and world["maximumGroundingBoundError"] < .003
              and len(world.get("grounding", [])) == world.get("groundedMeshes"), f"{name} actual production grounding proof missing")
        return data

    route = load_observation("route", args.route)
    purchase = load_observation("purchase", args.purchase)
    purchase_mobile = purchase.get("stress", {}).get("client", {}).get("touchEnabled")
    if args.mobile:
        mobile = load_observation("mobile", args.mobile)
    elif purchase_mobile is True:
        mobile = purchase
        inputs["mobile"] = inputs["purchase"] | {"sharedObservation": "purchase"}
    else:
        mobile = load_observation("mobile", None)
    if args.desktop_stress:
        desktop = load_observation("desktop", args.desktop_stress)
    elif purchase_mobile is False:
        desktop = purchase
        inputs["desktop"] = inputs["purchase"] | {"sharedObservation": "purchase"}
    else:
        desktop = load_observation("desktop", None)
    check(len(current) == 50 and set(shapes) == set(current), "Current ledger/geometry must contain exact fifty IDs")
    for cid, row in current.items():
        check(all(row.get("stages", {}).get(stage) for stage in progress.STAGES[:6]), f"{cid} needs reference/source/FBX/validation/real import/appearance before runtime approval")

    route_header = route.get("route", {})
    points = route_header.get("points", [])
    check(len(points) == 16 and all(v3(point) for point in points), "Fresh route lacks numeric observed sixteen production waypoints")
    length = sum(math.dist(points[i], points[i+1]) for i in range(len(points)-1)) if points and all(v3(p) for p in points) else 0
    check(finite(route_header.get("lengthStuds")) and abs(route_header["lengthStuds"] - length) < .002 and length > 600,
          "Route observed numeric points and service length differ")
    check(route_header.get("speedStudsPerSecond") == 6.5 and route_header.get("maxConcurrency") == 6
          and route_header.get("cadenceSeconds") == 10 and route_header.get("firstDelaySeconds") == 3,
          "Fresh route does not retain production speed/max6/cadence10/delay3")
    check(route_header.get("completed") == 50 and route_header.get("segments") == 15
          and finite(route_header.get("maximumActive")) and 0 < route_header["maximumActive"] <= 6,
          "Production route completion/concurrency proof missing")
    check(route_header.get("authoredMapWaypoints") == 16 and finite(route_header.get("authoredMapLengthStuds"))
          and abs(route_header["authoredMapLengthStuds"] - length) < .002, "Observed map authored route attributes differ")
    route_rows = {r["id"]: r for r in route.get("assets", [])}
    purchase_rows = {r["id"]: r for r in purchase.get("assets", [])}
    check(purchase.get("requestedPhase") in {"All", "PurchaseAndStress"} and purchase.get("purchase", {}).get("completed") == 50,
          "Fresh purchase must include all fifty plus native stress")
    claim = purchase.get("purchase", {}).get("claimInput", {})
    check(claim.get("inputAPI") == "InputHoldBegin/InputHoldEnd" and finite(claim.get("nativePromptInputCount")) and claim["nativePromptInputCount"] > 0,
          "Sanctuary claim needs actual native prompt input")

    def inspect_client(cid, client, state):
        motion = profiles.get(cid)
        check(client.get("id") == cid and client.get("state") == state and client.get("fbxSha256") == current[cid].get("currentFbxSha256"), f"{cid}/{state} client identity/state/provenance differs")
        check(client.get("profileMotion") == motion and client.get("nativeEmitterCount") == 1 and client.get("nativeFocusCount") == 1
              and finite(client.get("nativeLightCount")) and client["nativeLightCount"] <= 1, f"{cid}/{state} real native effect count/profile missing")
        check(finite(client.get("observedSeconds")) and client["observedSeconds"] >= 4.19 and finite(client.get("samples")) and client["samples"] > 10,
              f"{cid}/{state} did not observe full four-second semantic cycle")
        check(finite(client.get("hookMovementStuds")) and finite(client.get("pulseRange"))
              and (client["hookMovementStuds"] > .005 or client["pulseRange"] > .015), f"{cid}/{state} actual native motion/pulse missing")
        check(finite(client.get("emittingSamples")) and client["emittingSamples"] > 0 and finite(client.get("particleRateMax")) and client["particleRateMax"] > 0,
              f"{cid}/{state} actual emitter never ran")
        low, high = client.get("particleRateMin"), client.get("particleRateMax")
        if motion in {"tick", "heartbeat"}:
            check(finite(low) and finite(high) and low > 0 and high > low * 1.5, f"{cid}/{state} rhythmic burst observation missing")
        if motion in {"erase", "silence"}:
            check(low == 0 and finite(client.get("pausedSamples")) and client["pausedSamples"] > 0, f"{cid}/{state} interrupted emission pause missing")
        visits = client.get("semanticHookVisits", {})
        for name in {"choir": ("leftHead", "middleHead", "rightHead"), "scales": ("leftPan", "rightPan"), "gramophone": ("hornMouth",)}.get(motion, ()):
            check(visits.get(name) is True, f"{cid}/{state} native effect did not visit authored {name}")
        if motion == "gramophone":
            check(client.get("hookMovementStuds", 0) > .4, f"{cid}/{state} gramophone phrase transition missing")
        expected_hooks = shapes[cid].get("vfxHooksRoblox", {})
        actual_hooks = client.get("semanticHookPositions", {})
        check(set(actual_hooks) == set(expected_hooks), f"{cid}/{state} semantic attachment names differ")
        for name, position in expected_hooks.items():
            check(close_vector(actual_hooks.get(name), position), f"{cid}/{state} authored {name} position differs")
        if cid == "thorn_reliquary":
            check(client.get("nativeGlassPaneCount") == 4, f"{cid}/{state} four tested noncolliding native Glass panes missing")
        fields = client.get("labelFields", {})
        check(set(fields) == {"InfoName", "InfoRarity", "InfoIncome", "InfoPrice"}, f"{cid}/{state} label fields missing")
        for name, field in fields.items():
            check(bool(field.get("text")) and all(finite(field.get(key)) for key in ("width", "height", "textWidth", "textHeight"))
                  and field["width"] > 0 and field["height"] > 0 and field["textWidth"] <= field["width"] + 2
                  and field["textHeight"] <= field["height"] + 2, f"{cid}/{state}/{name} actual rendered text overflows")

    for cid in current:
        before = len(failures)
        trace = route_rows.get(cid, {}).get("route", {})
        check(trace.get("status") == "PASS" and trace.get("preExitState") == "PROCESSION" and trace.get("postExitStateAbsent") is True
              and trace.get("coveredSegmentCount") == 15 and set(trace.get("coveredSegments", {})) == {str(i) for i in range(1, 16)}
              and all(trace.get("coveredSegments", {}).values()), f"{cid} actual production exit/segment coverage failed")
        check(all(finite(trace.get(key)) for key in ("samples", "maximumLateralError", "endDistance", "distanceStuds", "elapsedSeconds", "expectedSeconds"))
              and trace["samples"] > 50 and trace["maximumLateralError"] < .03 and trace["endDistance"] < 3
              and trace["distanceStuds"] >= length - 3 and abs(trace["elapsedSeconds"] - length / 6.5) < 6
              and abs(trace["expectedSeconds"] - length / 6.5) < .002, f"{cid} route distance/speed/timing proof failed")
        row = purchase_rows.get(cid, {})
        bought = row.get("purchase", {})
        prompt = bought.get("promptInput", {})
        check(bought.get("status") == "PASS" and bought.get("state") == "PLACED" and bought.get("usedActualClientPrompt") is True
              and prompt.get("inputAPI") == "InputHoldBegin/InputHoldEnd" and finite(prompt.get("nativePromptInputCount"))
              and prompt["nativePromptInputCount"] > 0, f"{cid} actual prompt purchase/delivery proof missing")
        check(finite(bought.get("followDistance")) and bought["followDistance"] > 5 and finite(bought.get("pedestalError")) and bought["pedestalError"] < .05
              and finite(bought.get("incomeEarned")) and bought["incomeEarned"] > 0 and finite(bought.get("incomeObservedSeconds")) and bought["incomeObservedSeconds"] >= 1.1
              and bought.get("group") in range(1, 11) and bought.get("slot") in range(1, 6), f"{cid} follow/physical pedestal/income/five-slot cleanup proof failed")
        check(row.get("vfxChecked") is True and row.get("gameplayChecked") is True, f"{cid} actual fixture checks incomplete")
        runtime = row.get("runtime", {})
        check(runtime.get("meshId") == current[cid].get("robloxImport", {}).get("meshId") and runtime.get("fbxSha256") == current[cid].get("currentFbxSha256")
              and runtime.get("material") == "SmoothPlastic" and runtime.get("color") == [1, 1, 1]
              and close_vector(runtime.get("size"), shapes[cid].get("robloxIntendedSize"), .03)
              and close_vector(runtime.get("size"), runtime.get("meshSize"), .02), f"{cid} real imported root/material/size proof differs")
        inspect_client(cid, bought.get("deliveryClient", {}), "DELIVERING")
        inspect_client(cid, bought.get("placedClient", {}), "PLACED")
        results[cid] = {"rowChecksPassed": len(failures) == before,
                        "fbxSha256": current[cid].get("currentFbxSha256"),
                        "meshId": current[cid].get("robloxImport", {}).get("meshId"),
                        "geometryHookSha256": progress.geometry_hook_fingerprint(shapes[cid])}

    def inspect_stress(name, data, is_mobile):
        stress = data.get("stress", {})
        client = stress.get("client", {})
        check(stress.get("status") == "PASS" and stress.get("presentationOnlyDisplays") == 40 and stress.get("actualProductionOffers") == 6
              and stress.get("totalNativeVfxModels") == 46 and stress.get("ownedDisplaysAdded") == 0 and stress.get("earnedIncomeFromPresentation") == 0
              and stress.get("metadataCount") == 56, f"{name} actual forty visual displays/six offers scope failed")
        cap, light = (12, 0) if is_mobile else (20, 2)
        check(client.get("touchEnabled") is is_mobile and client.get("liveEffectCap") == cap and client.get("lightCap") == light,
              f"{name} actual device/emulation budget differs")
        for phase in ("near", "far"):
            sample = client.get(phase, {})
            counts = sample.get("finalNativeCounts", {})
            check(finite(sample.get("observedSeconds")) and sample["observedSeconds"] >= 15 and finite(sample.get("frameCount")) and sample["frameCount"] > 10
                  and finite(sample.get("countSamples")) and sample["countSamples"] > 10 and all(finite(sample.get(k)) and sample[k] > 0 for k in
                  ("meanFrameMs", "p50FrameMs", "p95FrameMs", "p99FrameMs", "maximumFrameMs")), f"{name}/{phase} actual fifteen-second frame statistics missing")
            check(counts.get("emitters") == 46 and counts.get("focuses") == 46 and finite(sample.get("maximumActiveLights")) and sample["maximumActiveLights"] <= light,
                  f"{name}/{phase} actual native46 instances/light cap failed")
            check(sample.get("maximumActiveEmitters") == (cap if phase == "near" else 0), f"{name}/{phase} actual cap exercise/distance culling failed")
        cleanup = stress.get("cleanup", {})
        check(cleanup.get("cleanedModels") == 46 and cleanup.get("remainingLiveExpansionTags") == 0, f"{name} actual46 native cleanup failed")

    inspect_stress("desktop", desktop, False)
    inspect_stress("mobile", mobile, True)
    legacy = None
    if args.legacy_route:
        legacy_path = args.legacy_route if args.legacy_route.is_absolute() else ROOT / args.legacy_route
        legacy_data = read_json(legacy_path)
        legacy = {"path": str(legacy_path), "sha256": progress.digest(legacy_path), "scope": legacy_data.get("scope"),
                  "creditedToEligibility": False, "reason": "Old route rows lack immutable loaded-source fingerprints; fresh strict Route is required."}
    eligible = not failures
    output = {"schemaVersion": 1, "capturedAtUtc": datetime.now(timezone.utc).isoformat(),
              "status": "ACTUAL_TESTS_ELIGIBLE" if eligible else "PENDING_OR_FAILED_ACTUAL_EVIDENCE",
              "eligible": eligible, "applied": bool(args.apply and eligible), "checks": checks,
              "testedCount": 50 if eligible else 0, "inputs": inputs, "legacyRoute": legacy,
              "productionSourceFingerprints": sources, "failures": failures, "assets": results,
              "scope": "Actual unchanged production route/prompt/follow/delivery/income plus full native semantic cycles and desktop/mobile46 visual stress. Studio device emulation is not a physical mobile benchmark."}
    args.output = args.output.resolve()
    if not args.output.is_relative_to(ROOT):
        raise ValueError("Eligibility output must stay in the project")
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(output, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    if args.apply:
        if not eligible:
            raise SystemExit("No stages written: actual evidence is incomplete, failed, or stale.")
        evidence_path = args.output.relative_to(ROOT).as_posix() if args.output.is_relative_to(ROOT) else str(args.output)
        for cid, row in current.items():
            proof = results[cid] | {"productionSourceFingerprints": sources, "inputs": inputs,
                                    "verifiedAtUtc": output["capturedAtUtc"], "eligibilityReport": evidence_path}
            row["verification"] = proof
            row["stages"]["vfxChecked"] = row["stages"]["gameplayChecked"] = True
            row["evidence"]["vfxReview"] = row["evidence"]["gameplayReview"] = evidence_path
            row.pop("verificationInvalidated", None)
        ledger["counts"] = {stage: sum(row["stages"][stage] for row in current.values()) for stage in progress.STAGES}
        progress.LEDGER.write_text(json.dumps(ledger, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({"status": output["status"], "checks": checks, "failures": len(failures), "applied": output["applied"]}))
    return 0 if eligible else 1


if __name__ == "__main__":
    raise SystemExit(main())
