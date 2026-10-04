"""Read-only delivery check for the locally built polished-animation place.

Run with the bundled Python runtime, or any Python 3.10+:
    python tools/Verify-PolishedBuild.py

The only write is the JSON proof (default assets/review/animations-polished/
build-proof.json). Exit 0 means all static checks passed; exit 1 means a
mismatch/missing input. This does not open Studio or assert Play approval.

SharedString *payloads* are compared, not serialization keys: Rojo can remap
those keys and convert MeshId/url to MeshContent/uri without changing data.
The current observed import ledger is authoritative. Historical repair
manifests are intentionally not consulted or rewritten.
"""
from __future__ import annotations

import argparse
import base64
import hashlib
import json
import math
import re
import sys
import xml.etree.ElementTree as ET
from datetime import datetime, timezone
from pathlib import Path

SCRIPT_CLASSES = {"Script", "LocalScript", "ModuleScript"}
SCRIPT_SUFFIXES = (".server.luau", ".client.luau", ".server.lua", ".client.lua", ".luau", ".lua")
PHYSICS_PROPERTIES = (
    "HasSkinnedMesh", "HasJointOffset", "JointOffset", "InitialSize",
    "PhysicsData", "PhysicalConfigData", "AeroMeshData", "InertiaMigrated",
    "UnscaledCofm", "UnscaledVolInertiaDiags", "UnscaledVolInertiaOffDiags",
    "UnscaledVolume", "VertexCount", "FluidFidelityInternal",
)
FORBIDDEN_SCRIPT_NAME = re.compile(r"qa|test|review|fixture|diagnostic", re.I)


def sha(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def normalized_source(text: str) -> str:
    return text.removeprefix("\ufeff").replace("\r\n", "\n").replace("\r", "\n")


def script_file(path: Path) -> tuple[str, str] | None:
    for suffix in SCRIPT_SUFFIXES:
        if path.name.endswith(suffix):
            cls = "Script" if ".server." in suffix else "LocalScript" if ".client." in suffix else "ModuleScript"
            return path.name[:-len(suffix)], cls
    return None


def properties(item: ET.Element) -> dict[str, ET.Element]:
    return {p.get("name", ""): p for p in item.findall("Properties/*")}


def item_name(item: ET.Element) -> str:
    return item.findtext('Properties/string[@name="Name"]') or item.get("class", "<unnamed>")


def item_index(root: ET.Element) -> tuple[dict[str, ET.Element], list[str]]:
    index, duplicate = {}, []
    def visit(item: ET.Element, parent: str) -> None:
        path = parent + "." + item_name(item)
        if path in index:
            duplicate.append(path)
        index[path] = item
        for child in item.findall("Item"):
            visit(child, path)
    for item in root.findall("Item"):
        visit(item, "game")
    return index, duplicate


def script_mapping(project: dict, root: Path) -> dict[str, dict]:
    result = {}
    def add(file: Path, path: str, cls: str) -> None:
        if path in result:
            raise ValueError(f"Multiple source files map to {path}")
        result[path] = {"file": file, "class": cls}
    def directory(folder: Path, path: str, class_override: str | None = None) -> None:
        if not folder.is_dir():
            raise ValueError(f"Missing source directory: {folder}")
        children = sorted(folder.iterdir())
        init = [file for file in children if file.is_file() and script_file(file) and script_file(file)[0] == "init"]
        if len(init) > 1:
            raise ValueError(f"Multiple Rojo init scripts in {folder}")
        if init:
            add(init[0], path, class_override or script_file(init[0])[1])
        for file in children:
            if file.is_dir() and not file.name.startswith("."):
                directory(file, path + "." + file.name)
            elif file.is_file() and file not in init:
                kind = script_file(file)
                if kind:
                    add(file, path + "." + kind[0], kind[1])
    def node(data: dict, path: str) -> None:
        source = data.get("$path")
        if source:
            if not isinstance(source, str):
                raise ValueError(f"Unsupported non-string $path at {path}")
            file = root / source
            if file.is_dir():
                directory(file, path, data.get("$className"))
            else:
                kind = script_file(file)
                if kind:
                    if not file.is_file():
                        raise ValueError(f"Missing script source: {file}")
                    add(file, path, data.get("$className") or kind[1])
        for name, child in data.items():
            if not name.startswith("$") and isinstance(child, dict):
                node(child, path + "." + name)
    node(project["tree"], "game")
    return result


def decode_binary(text: str | None) -> bytes:
    return base64.b64decode("".join((text or "").split()), validate=True)


def shared_strings(root: ET.Element) -> tuple[dict[str, bytes], list[str]]:
    result, errors = {}, []
    for entry in root.findall("SharedStrings/SharedString"):
        key = entry.get("md5")
        if not key:
            errors.append("SharedString table entry has no key")
            continue
        try:
            payload = decode_binary(entry.text)
        except (ValueError, base64.binascii.Error) as exc:
            errors.append(f"Invalid SharedString payload {key}: {exc}")
            continue
        if key in result and result[key] != payload:
            errors.append(f"Conflicting SharedString payload for {key}")
        result[key] = payload
    for ref in root.iter("SharedString"):
        if ref.get("name") and (ref.text or "").strip() not in result:
            errors.append(f"Unresolved SharedString property {ref.get('name')}: {(ref.text or '').strip()}")
    return result, errors


def content(props: dict[str, ET.Element], *names: str) -> str | None:
    for name in names:
        element = props.get(name)
        if element is not None:
            return element.findtext("url") or element.findtext("uri") or element.findtext("string") or None
    return None


def semantic(element: ET.Element, shared: dict[str, bytes]):
    if element.tag == "SharedString":
        return ("binary", sha(shared[(element.text or "").strip()]))
    if element.tag == "BinaryString":
        return ("binary", sha(decode_binary(element.text)))
    if list(element):
        return (element.tag, [(child.tag, semantic(child, shared)) for child in element])
    text = (element.text or "").strip()
    if element.tag in {"float", "double", "X", "Y", "Z", "R", "G", "B"} or re.fullmatch(r"R[0-2][0-2]", element.tag):
        return ("number", float(text))
    if element.tag in {"int", "int64", "token"}:
        return ("number", int(text))
    return (element.tag, text)


def equal_value(a, b) -> bool:
    if isinstance(a, tuple) and isinstance(b, tuple):
        if a[0] == b[0] == "number":
            return math.isclose(a[1], b[1], rel_tol=1e-6, abs_tol=1e-6)
        return a[0] == b[0] and equal_value(a[1], b[1])
    if isinstance(a, list) and isinstance(b, list):
        return len(a) == len(b) and all(equal_value(x, y) for x, y in zip(a, b))
    return a == b


def vector(props: dict[str, ET.Element], name: str) -> list[float] | None:
    element = props.get(name)
    # BasePart.Size is serialized as the historical lowercase property "size".
    if element is None:
        element = next((prop for key, prop in props.items() if key.lower() == name.lower()), None)
    return [float(element.findtext(axis)) for axis in ("X", "Y", "Z")] if element is not None else None


def bone_index(mesh: ET.Element) -> dict[str, tuple[str | None, ET.Element]]:
    result = {}
    def visit(item: ET.Element, parent: str | None) -> None:
        if item.get("class") == "Bone":
            name = item_name(item)
            if name in result:
                raise ValueError(f"Duplicate bone {name} in {item_name(mesh)}")
            result[name] = (parent, item)
            parent = name
        for child in item.findall("Item"):
            visit(child, parent)
    visit(mesh, None)
    return result


def verify(args) -> dict:
    root = args.root.resolve()
    build = args.build if args.build.is_absolute() else root / args.build
    report = {"schema": "steal-a-curse-polished-build-proof-v1", "verifiedAtUTC": datetime.now(timezone.utc).isoformat(),
              "root": str(root), "build": str(build.resolve()), "passed": False,
              "verificationScope": "Static source, native-template and binary-payload integrity; not a Play or visual approval.",
              "ledgerAuthority": "assets/imports/curse-animation-current.json; historical repair snapshots are not consulted.",
              "errors": [], "warnings": [], "scripts": [], "templates": []}
    errors = report["errors"]
    def fail(message: str) -> None:
        errors.append(message)
    inputs = {"build": build, "project": root / "default.project.json", "ledger": root / "assets/imports/curse-animation-current.json",
              "nativeKit": root / "assets/imports/CurseMeshKit.rbxmx", "animationAssets": root / "src/shared/CurseAnimationAssets.luau"}
    report["inputs"] = {}
    for label, file in inputs.items():
        if not file.is_file():
            fail(f"Missing {label}: {file}")
        else:
            report["inputs"][label] = {"path": str(file), "bytes": file.stat().st_size, "sha256": sha(file.read_bytes())}
    if errors:
        return report
    report["buildSHA256"] = report["inputs"]["build"]["sha256"]
    try:
        document = ET.parse(build).getroot()
        native = ET.parse(inputs["nativeKit"]).getroot()
        project = json.loads(inputs["project"].read_text(encoding="utf-8-sig"))
        ledger = json.loads(inputs["ledger"].read_text(encoding="utf-8-sig"))
        index, duplicates = item_index(document)
        mapping = script_mapping(project, root)
        kit_source = project.get("tree", {}).get("ServerStorage", {}).get("CurseMeshKit", {}).get("$path")
        if not isinstance(kit_source, str) or (root / kit_source).resolve() != inputs["nativeKit"].resolve():
            fail("Rojo CurseMeshKit must reference assets/imports/CurseMeshKit.rbxmx to preserve native skinning on reconstruction")
        for path in duplicates:
            fail(f"Duplicate instance path in build: {path}")
    except (OSError, ValueError, ET.ParseError, KeyError) as exc:
        fail(f"Cannot parse build or source mapping: {exc}")
        return report
    source_inventory = {file.resolve() for file in (root / "src").rglob("*") if file.is_file() and script_file(file)}
    mapped_files = {data["file"].resolve() for data in mapping.values()}
    for file in sorted(source_inventory - mapped_files):
        fail(f"Current production source is not mapped by Rojo: {file.relative_to(root)}")
    for path, data in sorted(mapping.items()):
        file = data["file"]
        raw = file.read_bytes()
        expected = normalized_source(raw.decode("utf-8-sig"))
        item = index.get(path)
        record = {"path": path, "source": file.relative_to(root).as_posix(), "sourceFileSHA256": sha(raw),
                  "expectedSourceSHA256": sha(expected.encode()), "expectedClass": data["class"], "present": item is not None}
        if item is None:
            fail(f"Missing production script: {path} ({record['source']})")
        else:
            actual_prop = properties(item).get("Source")
            actual = normalized_source(actual_prop.text or "") if actual_prop is not None else None
            record["actualClass"] = item.get("class")
            record["buildSourceSHA256"] = sha(actual.encode()) if actual is not None else None
            record["exactSourceMatch"] = actual == expected
            if item.get("class") != data["class"]:
                fail(f"Script class mismatch: {path}: {item.get('class')} vs {data['class']}")
            if actual != expected:
                diff = next((i for i, (a, b) in enumerate(zip(expected, actual or "")) if a != b), min(len(expected), len(actual or "")))
                record["firstMismatchLine"] = expected[:diff].count("\n") + 1
                fail(f"Script source mismatch: {path}, first difference at line {record['firstMismatchLine']}")
        report["scripts"].append(record)
    actual_scripts = {path for path, item in index.items() if item.get("class") in SCRIPT_CLASSES}
    for path in sorted(actual_scripts - mapping.keys()):
        fail(f"Unexpected script in delivery (possible QA/review/test): {path}")
    for path in sorted(actual_scripts):
        if FORBIDDEN_SCRIPT_NAME.search(item_name(index[path])):
            fail(f"QA/review/test script name present in delivery: {path}")
    report["scriptSummary"] = {"currentSourceFiles": len(source_inventory), "expectedScripts": len(mapping),
                               "buildScripts": len(actual_scripts), "exactMatches": sum(r.get("exactSourceMatch", False) for r in report["scripts"]),
                               "unexpectedScripts": sorted(actual_scripts - mapping.keys())}
    build_shared, shared_errors = shared_strings(document)
    native_shared, native_shared_errors = shared_strings(native)
    for error in shared_errors:
        fail("Build " + error)
    for error in native_shared_errors:
        fail("Native kit " + error)
    report["sharedStrings"] = {"buildEntries": len(build_shared), "nativeKitEntries": len(native_shared),
                               "allBuildReferencesResolved": not shared_errors,
                               "nativePayloadsComparedAfterResolvingKeys": True}
    native_kits = [item for item in native.iter("Item") if item_name(item) == "CurseMeshKit"]
    kit = index.get("game.ServerStorage.CurseMeshKit")
    if kit is None or len(native_kits) != 1:
        fail("Expected one current native CurseMeshKit and game.ServerStorage.CurseMeshKit in build")
        return report
    templates = {item_name(item): item for item in kit.findall("Item")}
    reference = {item_name(item): item for item in native_kits[0].findall("Item")}
    if len(templates) != 56 or len(ledger) != 56 or len(reference) != 56:
        fail(f"Expected 56 Curses: build={len(templates)}, ledger={len(ledger)}, native kit={len(reference)}")
    if len(templates) != len(kit.findall("Item")):
        fail("Duplicate native template names in build CurseMeshKit")
    for label, ids in [("build kit", set(templates)), ("native kit", set(reference))]:
        if ids != set(ledger):
            fail(f"Identity mismatch in {label}: missing={sorted(set(ledger)-ids)}, extra={sorted(ids-set(ledger))}")
    assets_text = inputs["animationAssets"].read_text(encoding="utf-8-sig")
    assets = {match[0]: {"meshId": match[1], "fbxSHA256": match[2], "boneCount": int(match[3])}
              for match in re.findall(r'([a-z][a-z0-9_]*)\s*=\s*\{\s*meshId\s*=\s*"(rbxassetid://[0-9]+)"\s*,\s*fbxSha256\s*=\s*"([0-9a-f]{64})"\s*,\s*boneCount\s*=\s*([0-9]+)', assets_text)}
    if set(assets) != set(ledger):
        fail(f"CurseAnimationAssets identities mismatch ledger: missing={sorted(set(ledger)-set(assets))}, extra={sorted(set(assets)-set(ledger))}")
    for ident, imported in sorted(ledger.items()):
        item, original = templates.get(ident), reference.get(ident)
        if item is None or original is None:
            continue
        props, old_props = properties(item), properties(original)
        local_errors = []
        def template_fail(message: str) -> None:
            local_errors.append(message)
            fail(f"{ident}: {message}")
        asset = content(props, "MeshContent", "MeshId")
        has_skin = props.get("HasSkinnedMesh")
        skin_true = has_skin is not None and (has_skin.text or "").strip() == "true"
        record = {"id": ident, "meshId": asset, "expectedMeshId": imported.get("meshId"), "hasSkinnedMesh": skin_true,
                  "nativePhysicsProperties": {}, "errors": local_errors}
        if item.get("class") != "MeshPart":
            template_fail(f"Expected MeshPart, got {item.get('class')}")
        if not skin_true:
            template_fail("HasSkinnedMesh is missing or false; bones alone do not establish skinning")
        if not imported.get("realImportRecorded"):
            template_fail("Current ledger does not record a real native import")
        if asset != imported.get("meshId") or content(old_props, "MeshContent", "MeshId") != imported.get("meshId"):
            template_fail("Build/native-kit Mesh ID does not match current observed ledger")
        row = assets.get(ident)
        if row and (row["meshId"] != asset or row["fbxSHA256"] != imported.get("fbxSHA256") or row["boneCount"] != len(imported.get("nativeBones", []))):
            template_fail("CurseAnimationAssets mesh/FBX hash/bone count does not match current observed ledger")
        record["size"] = vector(props, "Size")
        expected_size = imported.get("observedSize")
        if expected_size and (not record["size"] or any(abs(a-b) > 0.001 for a, b in zip(record["size"], expected_size))):
            template_fail("Visible Size does not match observed native import")
        for name in PHYSICS_PROPERTIES:
            expected_prop, actual_prop = old_props.get(name), props.get(name)
            if expected_prop is None:
                continue
            if actual_prop is None:
                template_fail(f"Native property lost: {name}")
                record["nativePhysicsProperties"][name] = {"preserved": False}
                continue
            try:
                original_value, actual_value = semantic(expected_prop, native_shared), semantic(actual_prop, build_shared)
                preserved = equal_value(original_value, actual_value)
                proof = {"preserved": preserved}
                if expected_prop.tag in {"SharedString", "BinaryString"}:
                    expected_bytes = native_shared[(expected_prop.text or "").strip()] if expected_prop.tag == "SharedString" else decode_binary(expected_prop.text)
                    actual_bytes = build_shared[(actual_prop.text or "").strip()] if actual_prop.tag == "SharedString" else decode_binary(actual_prop.text)
                    proof.update(expectedBytes=len(expected_bytes), buildBytes=len(actual_bytes),
                                 expectedPayloadSHA256=sha(expected_bytes), buildPayloadSHA256=sha(actual_bytes))
                record["nativePhysicsProperties"][name] = proof
                if not preserved:
                    template_fail(f"Native property payload/value changed: {name}")
            except (KeyError, ValueError, base64.binascii.Error) as exc:
                template_fail(f"Cannot resolve native property {name}: {exc}")
        try:
            bones, original_bones = bone_index(item), bone_index(original)
            record["boneCount"] = len(bones)
            record["boneNames"] = sorted(bones)
            observed_names = {bone["name"] for bone in imported.get("nativeBones", [])}
            if set(bones) != set(original_bones) or set(bones) != observed_names:
                template_fail("Bone names differ from current native template/observed import")
            for name in set(bones) & set(original_bones):
                parent, bone = bones[name]
                old_parent, old_bone = original_bones[name]
                if parent != old_parent:
                    template_fail(f"Native bone parent changed: {name}")
                a, b = properties(bone).get("CFrame"), properties(old_bone).get("CFrame")
                if a is None or b is None or not equal_value(semantic(a, build_shared), semantic(b, native_shared)):
                    template_fail(f"Native rest CFrame changed/missing: {name}")
        except ValueError as exc:
            template_fail(str(exc))
        record["passed"] = not local_errors
        report["templates"].append(record)
    report["templateSummary"] = {"expected": 56, "checked": len(report["templates"]),
                                 "skinned": sum(r["hasSkinnedMesh"] for r in report["templates"]),
                                 "passed": sum(r["passed"] for r in report["templates"])}
    report["passed"] = not errors
    return report


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parents[1])
    parser.add_argument("--build", type=Path, default=Path("build-curse-animations-polished.rbxlx"))
    parser.add_argument("--output", type=Path, default=Path("assets/review/animations-polished/build-proof.json"))
    args = parser.parse_args()
    try:
        report = verify(args)
    except Exception as exc:
        report = {"schema": "steal-a-curse-polished-build-proof-v1", "passed": False,
                  "errors": [f"Unexpected verification error: {type(exc).__name__}: {exc}"]}
    output = args.output if args.output.is_absolute() else args.root.resolve() / args.output
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(report, indent=2, ensure_ascii=False) + "\n", encoding="utf8")
    print("POLISHED_BUILD_STATIC", "PASS" if report["passed"] else "FAIL", json.dumps({"scripts": report.get("scriptSummary"), "templates": report.get("templateSummary")}))
    for error in report["errors"]:
        print("MISMATCH", error)
    print("PROOF", output)
    return 0 if report["passed"] else 1


if __name__ == "__main__":
    sys.exit(main())
