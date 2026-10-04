"""Metadata-only focal corrections measured against frozen editable sources.

Run with Blender --background --python this_file.py. Never saves a blend or FBX.
The generated audit records byte hashes before/after all 50 frozen components.
"""
import hashlib
import json
import math
import re
from pathlib import Path

import bpy
from mathutils import Vector
from mathutils.bvhtree import BVHTree

ROOT = Path(__file__).resolve().parents[5]
HERE = Path(__file__).resolve().parent
AUDIT = ROOT / "assets/review/curse-rework/vfx-semantic-revision.json"


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def load_shape(row):
    bpy.ops.wm.open_mainfile(filepath=str(ROOT / row["blendSource"]))
    obj = bpy.data.objects[row["id"]]
    tree = BVHTree.FromPolygons(
        [obj.matrix_world @ v.co for v in obj.data.vertices],
        [tuple(face.vertices) for face in obj.data.polygons],
        all_triangles=False,
    )
    return obj, tree


def blender_point(point):
    return Vector((point[0], -point[2], point[1]))


def roblox_point(point):
    return [float(point.x), float(point.z), float(-point.y)]


def screen_point(row, tree, point):
    nearest = tree.find_nearest(point)
    half = [value * 0.5 for value in row["robloxIntendedSize"]]
    excess = max(max(0, abs(value) - bound) for value, bound in zip(roblox_point(point), half))
    assert excess <= 0.25 + 1e-5, (row["id"], excess)
    return {
        "pointRoblox": roblox_point(point),
        "nearestSurfaceDistanceStuds": float(nearest[3]),
        "signedNearestSurfaceDistanceStuds": float((point - nearest[0]).dot(nearest[1])),
        "frontRayClear": tree.ray_cast(point, Vector((0, -1, 0)), 10)[0] is None,
        "outsideMeshBoundingBoxStuds": excess,
    }


def expose_front(row, clearance):
    obj, tree = load_shape(row)
    old = Vector(obj["VFXHook_Blender"])
    at = old.copy()
    direction = Vector((0, -1, 0))
    # Follow the source's frontward ray through intersecting closed details.
    # The final intersection is the visible silhouette at this exact X/height.
    last = None
    for _ in range(100):
        hit = tree.ray_cast(at, direction, 10)
        if hit[0] is None:
            break
        last = hit[0]
        at = last + direction * 0.0001
    assert last is not None, row["id"]
    # Verify the entire existing local animation path remains in front of skin.
    for _ in range(24):
        point = last + direction * clearance
        result = screen_point(row, tree, point)
        minimum = math.inf
        for index in range(480):
            t = index * 40 / 480
            if row["id"] == "marrow_dice":
                offset = Vector((math.cos(t * 1.3) * .10, -math.sin(t * 1.3) * .10, math.sin(t * .8) * .045))
            elif row["id"] in {"wilted_sprout", "thimble_spider"}:
                offset = Vector((math.sin(t * 1.6) * .075, 0, math.cos(t) * .025))
            else:
                offset = Vector((0, 0, 0))
            current = point + offset
            near = tree.find_nearest(current)
            minimum = min(minimum, (current - near[0]).dot(near[1]))
        if minimum > .060 and result["frontRayClear"]:
            break
        clearance += .015
    assert minimum > .060, (row["id"], minimum, result)
    result.update({"id": row["id"], "oldPointRoblox": roblox_point(old),
                   "frontSurfacePointRoblox": roblox_point(last),
                   "surfaceClearanceStuds": clearance,
                   "sampledMotionMinimumSignedDistanceStuds": minimum,
                   "purpose": "Expose the focus and emission source in front of the actual painted focal surface."})
    row["vfxHookRoblox"] = roblox_point(point)
    row["vfxHook"] = roblox_point(point)
    row["vfxHookMetadataRevision"] = "semantic-v2; source geometry and exports remain frozen"
    return result


def main():
    documents = {name: json.loads((HERE / (name + "_geometry.json")).read_text())
                 for name in ("common", "rare", "high")}
    rows = {row["id"]: row for document in documents.values() for row in document["assets"]}
    frozen = [{"id": row["id"], "blendSource": row["blendSource"], "export": row["export"],
               "blendSha256Before": sha(ROOT / row["blendSource"]),
               "fbxSha256Before": sha(ROOT / row["export"])} for row in rows.values()]
    corrections = [expose_front(rows[identity], distance) for identity, distance in (
        ("candle_wisp", .075), ("wilted_sprout", .13), ("marrow_dice", .18),
        ("sorrow_chalice", .075), ("thimble_spider", .13))]
    added = []
    definitions = {
        "silent_choir": {"sourcePrimary": (0, -.31, 3.10), "hooks": {
            "leftHead": (-.89, -.24, 2.86 - .44),
            "middleHead": (0, -.24, 3.51 - .44),
            "rightHead": (.94, -.24, 3.04 - .44)},
            "purpose": "Exact opening centers of the three transformed hollow bell heads."},
        "judgement_scales": {"sourcePrimary": (1.28, -.14, 2.03), "hooks": {
            "leftPan": (-1.28, -.24, 1.17 + .44),
            "rightPan": (1.28, -.24, 1.66 + .44)},
            "purpose": "Two pan focal centers above their rims and in front of the bound souls, clearing the front claw tips."},
    }
    for identity, definition in definitions.items():
        row = rows[identity]
        obj, tree = load_shape(row)
        origin_shift = Vector(definition["sourcePrimary"]) - Vector(obj["VFXHook_Blender"])
        hooks = row.setdefault("vfxHooksRoblox", {})
        for name, raw in definition["hooks"].items():
            point = Vector(raw) - origin_shift
            hooks[name] = roblox_point(point)
            result = screen_point(row, tree, point)
            result.update({"id": identity, "name": name, "sourcePointBlender": list(raw),
                           "sourceOriginShiftBlender": list(origin_shift), "purpose": definition["purpose"]})
            assert result["nearestSurfaceDistanceStuds"] > .055 and result["frontRayClear"], (identity, name, result)
            added.append(result)
        row["vfxHookMetadataRevision"] = "semantic-v2; source geometry and exports remain frozen"
    paths = []
    for identity in ("silent_choir", "judgement_scales", "pale_gramophone"):
        row = rows[identity]
        _, tree = load_shape(row)
        hooks = row["vfxHooksRoblox"]
        minimum, exposure, visited = math.inf, 0, set()
        for index in range(800):
            t = index * .05
            if identity == "silent_choir":
                name = ("leftHead", "middleHead", "rightHead")[math.floor(t) % 3]
                offset = Vector((math.sin(t * 1.6) * .03, 0, 0))
            elif identity == "judgement_scales":
                name = ("leftPan", "rightPan")[math.floor(t / 1.6) % 2]
                offset = Vector((0, 0, math.sin(t * 1.4) * .025))
            else:
                record = t % 4 >= 3
                name = "turntable" if record else "hornMouth"
                offset = Vector((math.cos(t * math.pi * 2) * .62, -math.sin(t * math.pi * 2) * .62, .025)) if record else Vector((math.sin(t * 1.5) * .035, 0, math.cos(t * 2) * .02))
            visited.add(name)
            point = blender_point(hooks[name]) + offset
            result = screen_point(row, tree, point)
            minimum = min(minimum, result["nearestSurfaceDistanceStuds"])
            exposure = max(exposure, result["outsideMeshBoundingBoxStuds"])
        assert minimum > .055, (identity, minimum)
        paths.append({"id": identity, "samples": 800, "observedLocalCycleSeconds": 40,
                      "visitedHooks": sorted(visited), "minimumSurfaceDistanceStuds": minimum,
                      "maximumOutsideMeshBoundingBoxStuds": exposure,
                      "status": "ACTUAL_FROZEN_SURFACE_PATH_PASS"})
    for record in frozen:
        record["blendSha256After"] = sha(ROOT / record["blendSource"])
        record["fbxSha256After"] = sha(ROOT / record["export"])
        assert record["blendSha256Before"] == record["blendSha256After"]
        assert record["fbxSha256Before"] == record["fbxSha256After"]
        record["status"] = "FROZEN_BYTES_UNCHANGED"
    for name, document in documents.items():
        (HERE / (name + "_geometry.json")).write_text(json.dumps(document, indent=2) + "\n")
    profile_path = ROOT / "src/shared/CurseVFXProfiles.luau"
    profile_ids = re.findall(r"^\s*(\w+)\s*=\s*profile\(", profile_path.read_text(), re.M)
    assert len(profile_ids) == 50 and set(profile_ids) == set(rows)
    source_paths = [ROOT / "src/client/CurseVFX.luau", profile_path] + [HERE / (name + "_geometry.json") for name in documents]
    revision_inputs = [{"path": path.relative_to(ROOT).as_posix(), "sha256": sha(path)} for path in source_paths]
    revision_payload = {"revision": "semantic-v2", "sourceFiles": revision_inputs,
                        "maximumHookExposureOutsideMeshBoundsStuds": .25}
    revision_hash = hashlib.sha256(json.dumps(revision_payload, sort_keys=True, separators=(",", ":")).encode()).hexdigest()
    AUDIT.parent.mkdir(parents=True, exist_ok=True)
    report = {"schemaVersion": 1, "revision": "semantic-v2", "status": "METADATA_GEOMETRY_PASS",
              "metadataOnly": True, "meshClearanceUnchanged": True,
              "maximumHookExposureOutsideMeshBoundsStuds": .25,
              "surfaceMethod": "BVH intersections against frozen authored triangles; Roblox(X,Y,Z)=Blender(X,Z,-Y).",
              "primaryCorrections": corrections, "addedSemanticHooks": added,
              "semanticMotionPaths": paths,
              "frozenAssets": frozen, "frozenAssetCount": len(frozen),
              "profileCoverageCount": len(profile_ids), "namedHookCount": sum(len(row.get("vfxHooksRoblox", {})) for row in rows.values()),
              "vfxRevisionSha256": revision_hash, "revisionPayload": revision_payload,
              "revisionHashMethod": "SHA256 of revisionPayload serialized as sorted-key compact JSON.",
              "motionSemantics": {"sunken_crown": "Top emission, upward 0.4 acceleration; unchanged low rate and locked source.",
                  "crown_of_silence": "1.2s emission/focus pause in every 3.5s cycle.",
                  "the_unwritten": "1.2s emission/focus pause in every 3.5s cycle.",
                  "heartbeat": "Base rate multiplied by 0.65+0.95*pulse, maximum 1.6.",
                  "clockwork_raven": "0.15s brass tick at 1.6 rate multiplier each second, baseline 0.65.",
                  "silent_choir": "Alternates the three measured head openings each second.",
                  "judgement_scales": "Alternates the two unequal pan focal centers each 1.6s.",
                  "pale_gramophone": "Three seconds of horn resonance, one second of glint circling actual record grooves; clears prior locked phrase on transition."},
              "studioVFXChecked": False}
    AUDIT.write_text(json.dumps(report, indent=2) + "\n")
    print("VFX_METADATA_REVISION_PASS", revision_hash, str(AUDIT), flush=True)


if __name__ == "__main__":
    main()
