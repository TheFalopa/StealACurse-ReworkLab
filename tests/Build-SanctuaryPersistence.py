"""Build native local persistence/migration QA; reuse the SAME namespace/file.

First Play seeds a genuine old schema-1 shape only if this isolated user key is
absent, migrates it with production code, and leaves a real contract relic
pending. Stop and reopen/replay the file to test manual recovery in Base04.
Native E claims the base; native F advances the labelled QA checkpoint.
"""
import argparse
import datetime
import json
import subprocess
from pathlib import Path


def main():
    root = Path(__file__).resolve().parents[1]
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--namespace", help="Reuse for reload; must start qa-sanctuary-persistence-.")
    parser.add_argument("--output", type=Path, default=root / "build-sanctuary-persistence.rbxlx")
    args = parser.parse_args()
    namespace = args.namespace or ("qa-sanctuary-persistence-" +
                                  datetime.datetime.now().strftime("%Y%m%d-%H%M%S-%f"))
    if (not namespace.startswith("qa-sanctuary-persistence-") or len(namespace) > 120 or
            any(c not in "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_" for c in namespace)):
        parser.error("Use an isolated qa-sanctuary-persistence- namespace with letters/digits/hyphens/underscores.")
    project = json.loads((root / "default.project.json").read_text(encoding="utf-8-sig"))
    server = project["tree"]["ServerScriptService"]["Server"]
    server["$path"] = str(root / "tests/SanctuaryPersistence.server.luau")
    server["Map"] = {"$path": str(root / "src/server/Map")}
    server["Gameplay"] = {"$path": str(root / "src/server/Gameplay")}
    project["tree"]["ServerStorage"]["LocalProfileBridge"] = {
        "$className": "Folder", "$attributes": {"Namespace": namespace}
    }
    project_file = root / "build-sanctuary-persistence.project.json"
    project_file.write_text(json.dumps(project, indent=2), encoding="utf-8")
    output = args.output if args.output.is_absolute() else root / args.output
    subprocess.run([str(Path.home() / ".rokit/bin/rojo.exe"), "build",
                    str(project_file), "--output", str(output)], check=True)
    print("Native persistence fixture:", output.resolve())
    print("Durable isolated namespace:", namespace)
    print("Play 1: native E claim Base03, then F Continue QA. Stop at PENDING_SAVED.")
    print("Play 2: reopen same file/namespace, native E claim Base04, F Continue QA.")
    print("Read RS.SanctuaryPersistenceReview ResultsJSON, LegacySeedJSON, LoadedJSON,")
    print("PendingJournalJSON, FinalJournalJSON and SummaryJSON. No online persistence claim.")


if __name__ == "__main__":
    main()
