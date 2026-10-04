"""Preserve actual Quality UI reports and native world report fragments.

Only reads a named Studio log; writes observation files in assets/review.
Oversized native logger lines are preserved as fragments, never guessed JSON.
"""

from datetime import datetime, timezone
import hashlib
import json
from pathlib import Path
import sys


ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "assets/review/curse-rework"


def main() -> None:
    source = Path(sys.argv[1]).resolve()
    mode = sys.argv[2] if len(sys.argv) > 2 else "desktop"
    minimum_timestamp = sys.argv[3] if len(sys.argv) > 3 else ""
    maximum_timestamp = sys.argv[4] if len(sys.argv) > 4 else ""
    minimum_time = datetime.fromisoformat(minimum_timestamp.replace("Z", "+00:00")) if minimum_timestamp else None
    maximum_time = datetime.fromisoformat(maximum_timestamp.replace("Z", "+00:00")) if maximum_timestamp else None
    data = source.read_bytes()
    ui, world, markers, trace = [], [], [], []
    for number, raw in enumerate(data.splitlines(keepends=True), 1):
        line = raw.decode("utf-8", errors="replace").rstrip("\r\n")
        timestamp = line.split(",", 1)[0]
        if minimum_time or maximum_time:
            try:
                observed_time = datetime.fromisoformat(timestamp.replace("Z", "+00:00"))
            except ValueError:
                continue
            if minimum_time and observed_time < minimum_time:
                continue
            if maximum_time and observed_time >= maximum_time:
                continue
        for marker in ("QUALITY_UI_REPORT", "QUALITY_UI_PASS", "QUALITY_UI_FAIL",
                       "QUALITY_WORLD_REPORT", "QUALITY_WORLD_PASS", "QUALITY_WORLD_FAIL"):
            if marker + " " not in line:
                continue
            prefix, text = line.split(marker + " ", 1)
            evidence = {"marker": marker, "sourceLineNumber": number,
                        "timestampUtc": prefix.split(",", 1)[0], "literalPayloadText": text}
            if marker.endswith("_REPORT"):
                try:
                    evidence["payload"] = json.loads(text)
                    evidence["completeJson"] = True
                except json.JSONDecodeError as error:
                    evidence["payload"] = None
                    evidence["completeJson"] = False
                    evidence["parseError"] = str(error)
                (ui if marker.startswith("QUALITY_UI") else world).append(evidence)
            else:
                markers.append(evidence)
            trace.append(raw)
    trace_bytes = b"".join(trace)
    trace_name = f"quality-observed-{mode}.log"
    (OUT / trace_name).write_bytes(trace_bytes)
    observation_source = {
        "originalLogPath": str(source), "originalLogFilename": source.name,
        "originalSnapshotSha256": hashlib.sha256(data).hexdigest(),
        "rawTrace": "assets/review/curse-rework/" + trace_name,
        "rawTraceSha256": hashlib.sha256(trace_bytes).hexdigest(),
        "logMayContinueGrowing": True,
        "selectedTimestampRangeUtc": {"fromInclusive": minimum_timestamp or None,
                                      "toExclusive": maximum_timestamp or None},
    }
    captured = datetime.now(timezone.utc).isoformat(timespec="seconds")
    ui_report = {
        "schemaVersion": 1, "capturedAtUtc": captured, "source": observation_source,
        "scope": "Literal client UI bounds/text observations; native user input described separately by the orchestrator. Not a physical-device performance test.",
        "reports": ui,
        "markers": [item for item in markers if item["marker"].startswith("QUALITY_UI")],
        "summary": {
            "completeReportCount": sum(item["completeJson"] for item in ui),
            "incompleteReportCount": sum(not item["completeJson"] for item in ui),
            "observedFailMarkers": sum(item["marker"] == "QUALITY_UI_FAIL" for item in markers),
            "observedReportFailures": [failure for item in ui if item["completeJson"] for failure in item["payload"].get("failures", [])],
        },
    }
    world_report = {
        "schemaVersion": 1, "capturedAtUtc": captured, "source": observation_source,
        "reports": world,
        "markers": [item for item in markers if item["marker"].startswith("QUALITY_WORLD")],
        "completeWorldReportExtracted": bool(world) and all(item["completeJson"] for item in world),
        "extractionLimit": "The native Studio logger cuts oversized marker lines. A null payload is a literal incomplete fragment, not a reconstructed world report. The WORLD_PASS marker is preserved independently.",
    }
    for name, content in ((f"quality-ui-observed-{mode}.json", ui_report),
                          (f"quality-world-log-{mode}.json", world_report)):
        (OUT / name).write_text(json.dumps(content, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({"source": source.name, "mode": mode, "ui": ui_report["summary"],
                      "completeWorldReportExtracted": world_report["completeWorldReportExtracted"],
                      "worldPassMarkers": sum(item["marker"] == "QUALITY_WORLD_PASS" for item in markers)}, indent=2))


if __name__ == "__main__":
    main()
