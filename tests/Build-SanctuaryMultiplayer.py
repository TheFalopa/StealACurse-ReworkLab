"""Build an isolated native Studio two-client sanctuary review.

Both players must claim the indicated bases with E in native Studio, then the
owner clicks Start. QA levels/resources are explicit seeds, not progression
achievements. All purchases, placements and contract deliveries use production
services. This fixture is never mounted in the release project.
"""
import argparse
import datetime
import json
import subprocess
from pathlib import Path


def main():
    root = Path(__file__).resolve().parents[1]
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path,
                        default=root / "build-sanctuary-multiplayer.rbxlx")
    parser.add_argument("--namespace", help="Must be unused; fixture rejects existing inventory.")
    args = parser.parse_args()
    namespace = args.namespace or ("qa-sanctuary-multiplayer-" +
                                  datetime.datetime.now().strftime("%Y%m%d-%H%M%S"))
    if not namespace or len(namespace) > 120 or any(c not in "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_" for c in namespace):
        parser.error("Use a short profile namespace containing letters, digits, hyphens or underscores.")
    project = json.loads((root / "default.project.json").read_text(encoding="utf-8-sig"))
    server = project["tree"]["ServerScriptService"]["Server"]
    server["$path"] = str(root / "tests/SanctuaryMultiplayer.server.luau")
    server["Map"] = {"$path": str(root / "src/server/Map")}
    server["Gameplay"] = {"$path": str(root / "src/server/Gameplay")}
    project["tree"]["StarterPlayer"]["StarterPlayerScripts"]["SanctuaryMultiplayerClient"] = {
        "$path": str(root / "tests/SanctuaryMultiplayer.client.luau")
    }
    project["tree"]["ServerStorage"]["LocalProfileBridge"] = {
        "$className": "Folder", "$attributes": {"Namespace": namespace}
    }
    project_file = root / "build-sanctuary-multiplayer.project.json"
    project_file.write_text(json.dumps(project, indent=2), encoding="utf-8")
    output = args.output if args.output.is_absolute() else root / args.output
    subprocess.run([str(Path.home() / ".rokit/bin/rojo.exe"), "build",
                    str(project_file), "--output", str(output)], check=True)
    print("Native two-client fixture:", output.resolve())
    print("Isolated profile namespace:", namespace)
    print("Start native Test with 2 Players. Both claim with E, then Player1 clicks Start.")
    print("Automatic native 30-second capture is on; review and save each client's clips.")
    print("Read ReplicatedStorage.SanctuaryMultiplayerControl: ChecksJSON, SeedsJSON,")
    print("ObservationsJSON, PositionsJSON and SummaryJSON. Bone transforms do not approve pixels.")


if __name__ == "__main__":
    main()
