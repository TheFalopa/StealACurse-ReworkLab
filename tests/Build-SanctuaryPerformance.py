"""Build local Studio draw-load QA alongside unchanged full production startup.

Run Play and click Medir carga de QA. Eight real level-10 architectures are QA
draw load, and 56 native Curse representations occupy Base01/02 (30/26). They
are not seeded owned accounts and grant no income. Production presentation,
animation, loading and VFX remain the sole visual writers. Measurements cover
baseline, near, mid, far, revisit and actual model destruction.
"""
import argparse
import datetime
import hashlib
import json
import subprocess
from pathlib import Path


def main():
    root = Path(__file__).resolve().parents[1]
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path,
                        default=root / "build-sanctuary-performance.rbxlx")
    parser.add_argument("--namespace", help="Isolated local profile namespace.")
    parser.add_argument("--check-only", action="store_true",
                        help="Validate inputs without writing a project or place.")
    args = parser.parse_args()
    namespace = args.namespace or ("qa-sanctuary-performance-" +
                                  datetime.datetime.now().strftime("%Y%m%d-%H%M%S"))
    allowed = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_"
    if not namespace or len(namespace) > 120 or any(c not in allowed for c in namespace):
        parser.error("Use letters, digits, hyphens or underscores in a short QA namespace.")
    project = json.loads((root / "default.project.json").read_text(encoding="utf-8-sig"))
    # Keep src/server/init.server.luau intact. A separate sibling server Script
    # waits for its generated map instead of building a second map/services.
    if project["tree"]["ServerScriptService"]["Server"]["$path"] != "src/server":
        parser.error("Expected the full production server entrypoint in default.project.json.")
    project["tree"]["ServerScriptService"]["SanctuaryPerformance"] = {
        "$path": str(root / "tests/SanctuaryPerformance.server.luau")
    }
    project["tree"]["StarterPlayer"]["StarterPlayerScripts"]["SanctuaryPerformance"] = {
        "$path": str(root / "tests/SanctuaryPerformance.client.luau")
    }
    project["tree"]["ServerStorage"]["LocalProfileBridge"] = {
        "$className": "Folder", "$attributes": {"Namespace": namespace}
    }
    # The final facade correction must preserve tested colliders and stable IDs.
    # Run only the affected architecture checks, against disposable bases.
    project["tree"]["ServerStorage"]["UnitTest"] = {
        "$className": "Folder",
        "RunUnitTest": {"$path": str(root / "tests/Unit/RunUnitTest.luau")},
        "Cases": {"$className": "Folder", "Architecture": {
            "$path": str(root / "tests/SanctuaryArchitecture.spec.luau")}}
    }
    before = root / "assets/review/sanctuary-restoration/checkpoints/08-performance-native/src/server/Map/RestorationArchitecture.luau"
    if before.is_file():
        project["tree"]["ServerStorage"]["ArchitectureBefore"] = {
            "$className": "Folder", "RestorationArchitecture": {"$path": str(before)},
            **{name: {"$path": str(root / ("src/server/Map/" + name + ".luau"))}
               for name in ["Config", "Primitives", "AssetKit"]}
        }
    sources = [root / "src/server/init.server.luau",
               root / "src/client/init.client.luau",
               root / "src/client/CursePresentation.luau",
               root / "src/client/CurseAnimation.luau",
               root / "src/client/CurseVFX.luau",
               root / "src/server/Map/RestorationArchitecture.luau",
               root / "assets/imports/CurseMeshKit.rbxmx",
               root / "tests/SanctuaryPerformance.server.luau",
               root / "tests/SanctuaryPerformance.client.luau"]
    for source in sources:
        if not source.is_file():
            parser.error("Required source is missing: " + str(source))
    hashes = {str(path.relative_to(root)).replace("\\", "/"):
              hashlib.sha256(path.read_bytes()).hexdigest() for path in sources}
    if args.check_only:
        print(json.dumps({"status": "INPUTS_READY_NOT_EXECUTED",
                          "productionServer": "src/server",
                          "productionClient": "src/client",
                          "namespace": namespace, "sourceSHA256": hashes}, indent=2))
        return
    project_file = root / "build-sanctuary-performance.project.json"
    project_file.write_text(json.dumps(project, indent=2), encoding="utf-8")
    output = args.output if args.output.is_absolute() else root / args.output
    subprocess.run([str(Path.home() / ".rokit/bin/rojo.exe"), "build",
                    str(project_file), "--output", str(output)], check=True)
    print("Native performance fixture:", output.resolve())
    print("Isolated profile namespace:", namespace)
    print("Full production startup plus separate QA scripts. Requires the local profile plugin.")
    print("Play, then click Medir carga de QA; automatic 30-second native capture follows bounded loading.")
    print("Read LocalPlayer attributes with prefix SanctuaryPerformance: Status / ObservedJSON / ChecksJSON /")
    print("FailuresJSON / LoadSeconds / CapturesJSON; read control ArchitectureJSON / PopulationJSON.")
    print("RenderStepped durations include Studio, natural offers and any active native capture; record viewport/touch mode.")
    print("QA_NON_OWNED draw load is not an owned-account test or a physical-mobile benchmark.")
    print("Production source SHA256:", json.dumps(hashes, sort_keys=True))


if __name__ == "__main__":
    main()
