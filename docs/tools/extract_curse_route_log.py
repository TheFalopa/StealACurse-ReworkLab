"""Preserve actual Studio route marker rows and separate current core proof.

Reads logs and Git only. The route rows are not upgraded to VFX/gameplay approval.
Missing immutable fingerprints from the old fixture are explicitly not rebuilt.
"""

from __future__ import annotations

from datetime import datetime, timezone
import hashlib
import json
from pathlib import Path
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "assets/review/curse-rework"
CORE = [
    "src/server/Gameplay/CurseProcessionService.luau",
    "src/server/Gameplay/CurseService.luau",
    "src/server/Gameplay/Config.luau",
    "src/server/Gameplay/BaseService.luau",
    "src/server/Gameplay/SoulsService.luau",
    "src/server/Map/Config.luau",
    "src/server/Map/Layout.luau",
]


def sha(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def write(name: str, value: dict) -> None:
    (OUT / name).write_text(json.dumps(value, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def main() -> None:
    source = Path(sys.argv[1]).resolve()
    captured = datetime.now(timezone.utc).isoformat(timespec="seconds")
    data = source.read_bytes()
    raw_lines = data.splitlines(keepends=True)
    rows = []
    trace = []
    ready = []
    final_reports = []
    purchase_markers = []
    final_trace = []
    completion_markers = []
    for line_number, raw in enumerate(raw_lines, 1):
        line = raw.decode("utf-8", errors="replace").rstrip("\r\n")
        for marker, sink in (("CURSE_REWORK_ROUTE", rows), ("CURSE_REWORK_READY", ready),
                             ("CURSE_REWORK_REPORT", final_reports),
                             ("CURSE_REWORK_PURCHASE", purchase_markers)):
            needle = marker + " "
            if needle not in line:
                continue
            prefix, text = line.split(needle, 1)
            try:
                payload = json.loads(text)
                parse_error = None
            except json.JSONDecodeError as error:
                if marker == "CURSE_REWORK_ROUTE":
                    raise
                payload = None
                parse_error = str(error)
            metadata = {
                "sourceLineNumber": line_number,
                "timestampUtc": prefix.split(",", 1)[0],
                "studioLogElapsedSeconds": float(prefix.split(",")[1]),
                "rawMarker": marker,
            }
            if marker == "CURSE_REWORK_ROUTE":
                payload["logEvidence"] = metadata
                sink.append(payload)
                trace.append(raw)
            else:
                sink.append({"logEvidence": metadata, "payload": payload,
                             "completeJson": payload is not None,
                             "literalPayloadText": text if payload is None else None,
                             "parseError": parse_error})
                if marker in ("CURSE_REWORK_REPORT", "CURSE_REWORK_PURCHASE"):
                    final_trace.append(raw)
        for marker in ("CURSE_REWORK_DONE", "CURSE_REWORK_FAIL", "CURSE_REWORK_STRESS"):
            needle = marker + " "
            if needle in line:
                prefix, payload_text = line.split(needle, 1)
                completion_markers.append({"marker": marker, "timestampUtc": prefix.split(",", 1)[0],
                                           "sourceLineNumber": line_number, "literalPayloadText": payload_text})
                final_trace.append(raw)
    assert len(rows) == 50, f"Expected fifty literal route rows, got {len(rows)}"
    assert len({row["id"] for row in rows}) == 50, "Duplicate route IDs"
    ledger = json.loads((ROOT / "assets/curse-expansion-progress.json").read_text(encoding="utf-8"))
    current = {row["id"]: row for row in ledger["curses"]}
    assert set(current) == {row["id"] for row in rows}
    for row in rows:
        assert row["fbxSha256"] == current[row["id"]]["currentFbxSha256"], row["id"]
        assert row["meshId"] == current[row["id"]]["robloxImport"]["meshId"], row["id"]
        assert row["route"]["status"] == "PASS", row["id"]
        assert row["route"]["coveredSegmentCount"] == 15, row["id"]
        assert row["route"]["preExitState"] == "PROCESSION", row["id"]
        assert row["route"]["postExitStateAbsent"] is True, row["id"]
    trace_bytes = b"".join(trace)
    (OUT / "route-observed-all50.log").write_bytes(trace_bytes)

    core = []
    for path in CORE:
        disk = (ROOT / path).read_bytes()
        head = subprocess.check_output(["git", "show", "HEAD:" + path], cwd=ROOT)
        disk_lf = disk.replace(b"\r\n", b"\n")
        head_lf = head.replace(b"\r\n", b"\n")
        diff = subprocess.run(["git", "diff", "--quiet", "HEAD", "--", path], cwd=ROOT).returncode
        assert diff == 0 and disk_lf == head_lf, f"Production core differs from HEAD: {path}"
        core.append({
            "path": path, "diskSha256": sha(disk), "headBlobSha256": sha(head),
            "diskLfSha256": sha(disk_lf), "headLfSha256": sha(head_lf),
            "exactByteEquality": disk == head, "equalityAfterCrLfNormalization": disk_lf == head_lf,
            "gitDiffHeadExitCode": diff,
        })
    proof = {
        "schemaVersion": 1, "capturedAtUtc": captured,
        "gitHead": subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip(),
        "gitBranch": subprocess.check_output(["git", "branch", "--show-current"], cwd=ROOT, text=True).strip(),
        "method": "Read current file bytes and git show HEAD:path bytes; compare raw SHA256 and CRLF-to-LF-normalized SHA256; git diff --quiet HEAD -- each path.",
        "status": "CURRENT_PRODUCTION_CORE_MATCHES_HEAD",
        "files": core,
        "oldFixtureSourceFingerprints": "NOT_EMITTED_IN_EXTRACTED_LOG_MARKERS",
        "proofLimit": "This is an independent current disk/core baseline comparison, not a reconstruction or certification of immutable sources loaded by the old Studio fixture. The route rows bind the actual observed MeshIds and FBX hashes. No VFX approval is granted.",
        "relatedRouteEvidence": "assets/review/curse-rework/route-observed-all50.json",
    }
    write("route-production-core-proof.json", proof)
    routes = [row["route"] for row in rows]
    report = {
        "schemaVersion": 1,
        "scope": "Actual Studio route-only observations for fifty current imported Curses; deterministic fixture selection. Fixture initial delay/cadence accelerated; no VFX/gameplay-completion approval implied.",
        "studioId": "cbe94f43-503c-4adb-af43-9c6a2f8c45d9",
        "capturedAtUtc": captured,
        "source": {
            "originalLogPath": str(source), "originalLogFilename": source.name,
            "logSnapshotByteCount": len(data), "logSnapshotSha256": sha(data),
            "logMayContinueGrowing": True,
            "rawRouteTrace": "assets/review/curse-rework/route-observed-all50.log",
            "rawRouteTraceSha256": sha(trace_bytes),
            "firstRouteTimestampUtc": rows[0]["logEvidence"]["timestampUtc"],
            "lastRouteTimestampUtc": rows[-1]["logEvidence"]["timestampUtc"],
            "firstSourceLineNumber": rows[0]["logEvidence"]["sourceLineNumber"],
            "lastSourceLineNumber": rows[-1]["logEvidence"]["sourceLineNumber"],
        },
        "readyMarkers": ready,
        "finalReportMarkerCountAtExtraction": len(final_reports),
        "finalReportMarkers": final_reports,
        "fixtureConfigurationReportedByOrchestrator": {
            "routePointCount": 16, "speedStudsPerSecond": 6.5,
            "maxProcessionCurses": 6, "initialDelaySeconds": 0.1, "cadenceSeconds": 0.15,
            "configurationEvidenceLimit": "These fixture overrides are declared by the orchestrator; per-Curse trace values below are literal log observations. Immutable loaded-source fingerprints were not emitted by the old fixture.",
        },
        "currentCoreComparison": "assets/review/curse-rework/route-production-core-proof.json",
        "sourceFingerprintLimit": proof["proofLimit"],
        "summary": {
            "status": "ALL_50_ROUTE_OBSERVATIONS_PASS",
            "uniqueCurrentIds": 50, "routePassCount": 50,
            "allCurrentMeshIdsAndFbxHashesMatched": True,
            "allCoveredFifteenSegments": True, "allPostExitStatesAbsent": True,
            "elapsedSecondsRange": [min(r["elapsedSeconds"] for r in routes), max(r["elapsedSeconds"] for r in routes)],
            "distanceStudsRange": [min(r["distanceStuds"] for r in routes), max(r["distanceStuds"] for r in routes)],
            "maximumLateralErrorStuds": max(r["maximumLateralError"] for r in routes),
            "maximumEndDistanceStuds": max(r["endDistance"] for r in routes),
            "samplesPerCurseRange": [min(r["samples"] for r in routes), max(r["samples"] for r in routes)],
        },
        "route": rows,
    }
    write("route-observed-all50.json", report)
    if final_reports:
        final_trace_bytes = b"".join(final_trace)
        (OUT / "legacy-all-observed.log").write_bytes(final_trace_bytes)
        write("legacy-all-observed.json", {
            "schemaVersion": 1, "capturedAtUtc": captured,
            "scope": "Literal final report emitted by the original ALL fixture. Historical VFX version; do not reuse its VFX approvals for later presentation revisions.",
            "source": {"originalLogPath": str(source), "originalLogFilename": source.name,
                       "originalLogSnapshotSha256": sha(data),
                       "rawFinalTrace": "assets/review/curse-rework/legacy-all-observed.log",
                       "rawFinalTraceSha256": sha(final_trace_bytes)},
            "report": final_reports[-1]["payload"],
            "completeFinalReportExtracted": final_reports[-1]["completeJson"],
            "extractionLimit": "Native Studio logger truncates oversized marker lines. A null report is intentional: the preserved fragment is not a reconstructed JSON report.",
            "reportLogEvidence": final_reports[-1]["logEvidence"],
            "allFinalReportMarkers": final_reports,
            "purchaseMarkers": purchase_markers,
            "purchaseMarkerCounts": {
                "seen": len(purchase_markers),
                "completeJson": sum(item["completeJson"] for item in purchase_markers),
                "truncatedJson": sum(not item["completeJson"] for item in purchase_markers),
            },
            "completionMarkers": completion_markers,
            "currentCoreComparison": "assets/review/curse-rework/route-production-core-proof.json",
            "sourceFingerprintLimit": proof["proofLimit"],
        })
    print(json.dumps({"source": source.name, "routeTrace": report["source"],
                      "summary": report["summary"], "readyMarkers": len(ready),
                      "finalReportMarkers": len(final_reports), "coreFiles": len(core),
                      "purchaseMarkers": len(purchase_markers),
                      "completePurchaseJson": sum(item["completeJson"] for item in purchase_markers),
                      "exactCoreByteMatches": sum(row["exactByteEquality"] for row in core)}, indent=2))


if __name__ == "__main__":
    main()
