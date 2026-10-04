"""Bind existing, unedited native Studio captures to observed gallery metadata.

Reads evidence and image headers; never generates, crops or modifies an image.
The native camera selection and visible review were performed in Studio.
"""
from datetime import datetime, timezone
import hashlib
import json
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[2]
REVIEW = ROOT / "assets/review/curse-rework"
CAPTURES = {
    "candle_wisp": "candle-wisp-gameplay-distance-vfx-desktop.jpg",
    "pale_gramophone": "pale-gramophone-gameplay-distance-vfx-desktop.jpg",
    "thorn_cathedral": "thorn-cathedral-gameplay-distance-vfx-desktop.jpg",
    "cathedral_heart": "cathedral-heart-gameplay-distance-vfx-desktop.jpg",
    "the_last_star": "the-last-star-gameplay-distance-vfx-desktop.jpg",
}


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def image_record(name):
    path = REVIEW / name
    with Image.open(path) as im:
        assert im.format == "JPEG" and im.size == (1920, 1032), name
        size = list(im.size)
    return {
        "path": path.relative_to(ROOT).as_posix(),
        "sha256": sha(path),
        "format": "JPEG",
        "nativeWindowDimensions": size,
        "fileModifiedUtc": datetime.fromtimestamp(path.stat().st_mtime, timezone.utc).isoformat(),
        "uneditedNativeCapture": True,
    }


def main():
    metadata_path = REVIEW / "normal-gallery-metadata-current-source-observed.json"
    observed = json.loads(metadata_path.read_text(encoding="utf-8"))
    gallery = observed["report"]
    assert gallery["phase"] == "ready" and gallery["enabledSpawnCount"] == 56
    assert gallery["presentationOnly"] and gallery["displayCount"] == 5
    assert gallery["ownedDisplaysAdded"] == 0 and gallery["incomeCreatedByGallery"] == 0
    production_sources = {}
    fixture_sources = []
    for relative, expected in gallery["sourceFingerprints"].items():
        current = sha(ROOT / relative)
        if relative.startswith("src/") or relative == "default.project.json":
            assert current == expected, relative
            production_sources[relative] = current
        else:
            fixture_sources.append({"path": relative, "loadedSha256": expected,
                                    "currentSha256": current, "matches": current == expected})
    displays = {d["id"]: d for d in gallery["displays"]}
    assert set(displays) == set(CAPTURES)
    captures = []
    for curse_id, filename in CAPTURES.items():
        display = displays[curse_id]
        assert display["presentationOnly"] and not display["promptEnabled"]
        assert not display["ownershipRecordCreated"]
        captures.append({**image_record(filename), "id": curse_id, "observedDisplay": display,
                         "nativeCameraSelection": f'require(game.ReplicatedStorage.TestCurseReviewGalleryCamera).frame("{curse_id}")',
                         "visuallyReviewed": True})
    evidence = {
        "schemaVersion": 1,
        "recordedAtUtc": datetime.now(timezone.utc).isoformat(),
        "studioId": observed["studioId"],
        "metadataPath": metadata_path.relative_to(ROOT).as_posix(),
        "metadataSha256": sha(metadata_path),
        "productionFingerprintsVerifiedCurrent": production_sources,
        "fixtureFingerprints": fixture_sources,
        "fixtureSourceScope": "The loaded manual gallery fixture is preserved with its build proof. Its builder subsequently gained an optional automatic camera mode which was not used for these native captures. Any builder hash difference is recorded; all loaded runtime sources and the default project remain current.",
        "captures": captures,
        "scope": "Five unedited native desktop Studio Play window captures. Each actual imported presentation-only model uses production Visual/VFX and existing world lighting, framed at about 11 studs, 15 degrees and FOV65 using the optional review camera. Native game viewport is 1580x633 inside the 1920x1032 application window. These static views show geometry, painted materials, labels and visible effects at gameplay distance; the full purchase/motion/VFX proof is the separate actual 50-Curse test. They are not owned pedestal displays, natural spawn coverage or income proof. Camera and identity provenance derive from actual loaded GalleryMetadata and the native camera commands; each image was visually reviewed, never generated or edited.",
        "uiCaptures": [image_record(n) for n in ["normal-56-live-catalog-desktop.jpg", "normal-56-live-catalog-secret-desktop.jpg", "normal-56-shop-desktop.jpg"]],
        "nativeUiObserved": {
            "catalogFooter": "56 live · 0 expansion concepts. Catalog only; not an inventory.",
            "catalogOpenedAndClosed": True,
            "desktopWheelMovedList": True,
            "desktopWheelScrollYInputs": [5600, 3600],
            "lastVisibleRows": ["The First Grave", "The Unwritten", "The Last Star"],
            "shopOpenedAndClosed": True,
            "shopScope": "Existing concept shop, Gamepasses tab, no purchases or active perks.",
            "physicalPhoneTested": False,
            "nativeMobileScrollConfirmed": False,
        },
    }
    output = REVIEW / "gameplay-distance-captures-provenance.json"
    output.write_text(json.dumps(evidence, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(f"Recorded 5 native model captures and 3 UI captures: {output}")


if __name__ == "__main__":
    main()
