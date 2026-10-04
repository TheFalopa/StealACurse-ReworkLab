"""Generate the current-design manifest; keep earlier imports as history."""
import json
import update_rework_progress


def main():
    update_rework_progress.main()
    ledger = json.loads(update_rework_progress.LEDGER.read_text(encoding="utf-8"))
    records, rarities = [], {}
    for row in ledger["curses"]:
        shape, stages = row.get("geometry", {}), row["stages"]
        imported = row.get("robloxImport", {}) if stages["realRobloxImportRecorded"] else {}
        status = "VALIDATED" if stages["gameplayChecked"] else "IMPORTED" if imported else "EXPORTED" if stages["fbxExported"] else "PLANNED"
        record = {"id": row["id"], "displayName": row["displayName"], "rarity": row["rarity"],
            "visualKey": row["id"], "sourceReference": row["sourceReference"],
            "referenceSheet": int(row["sourceReference"].split("-")[1]),
            "implementationStatus": status, "enabled": stages["enabled"],
            "productionWave": 2 if imported else 0,
            "blendSource": shape.get("blendSource"), "fbxExport": shape.get("export"),
            "fbxSha256": row["currentFbxSha256"], "meshId": imported.get("meshId"),
            "textureId": imported.get("textureId"), "importedSize": imported.get("size"),
            "importedInitialSize": imported.get("meshSize"),
            "robloxImportVerified": stages["realRobloxImportRecorded"],
            "robloxAppearanceVerified": stages["studioAppearanceChecked"],
            "vfxVerified": stages["vfxChecked"], "gameplayValidated": stages["gameplayChecked"],
            "importEvidence": row["evidence"].get("robloxImport"),
            "historicalFirstWave": row["historicalFirstWave"], "stages": stages,
            "designNotes": shape.get("designNotes", [])}
        for key in ("triangles", "vertices", "robloxIntendedSize", "vfxProfile", "vfxHookRoblox", "vfxHooksRoblox", "paintedColorCount", "colorLayer", "uvLayers"):
            if key in shape: record[key] = shape[key]
        records.append(record)
        rarities[row["rarity"]] = rarities.get(row["rarity"], 0)+1
    assert len(records) == 50 and len({r["id"] for r in records}) == 50
    report = {"schemaVersion": 2, "conceptCount": 50, "preservedExistingCount": 6,
        "totalPlannedCatalogCount": 56, "historicalFirstWaveCount": 15,
        "remainingUnmodeledCount": 50-ledger["counts"]["blenderModelComplete"],
        "rarityCounts": rarities, "stageCounts": ledger["counts"],
        "statusRules": "Exports, imports, material appearance, VFX, gameplay and enablement are independent; current-source SHA256 required.",
        "concepts": records}
    update_rework_progress.MANIFEST.write_text(json.dumps(report, indent=2)+"\n", encoding="utf-8")
    print("CURRENT_DESIGN_MANIFEST", ledger["counts"])


if __name__ == "__main__":
    main()
