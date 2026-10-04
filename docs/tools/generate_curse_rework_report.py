"""Generate read-only evidence annexes for the current 50-Curse rework.

Run with Python 3 from any directory. Reads the current ledger, import evidence,
recorded Blender validation, static audit and Git status. Writes only the two
Markdown annexes in docs; never changes approvals, asset mappings or gameplay.
The ten-point narrative report is edited separately so Play evidence survives
regeneration of these tables.
"""

from __future__ import annotations

from collections import Counter
from datetime import datetime, timezone
import hashlib
import json
import math
from pathlib import Path
import subprocess


ROOT = Path(__file__).resolve().parents[2]
DOCS = ROOT / "docs"
STAGES = [
    ("referenceReviewed", "Referencia"),
    ("blenderModelComplete", "Modelo"),
    ("locallyValidated", "QA local"),
    ("fbxExported", "FBX"),
    ("realRobloxImportRecorded", "Importación"),
    ("studioAppearanceChecked", "Apariencia"),
    ("vfxChecked", "VFX"),
    ("gameplayChecked", "Juego"),
    ("enabled", "Habilitada"),
]


def read(relative: str) -> dict:
    return json.loads((ROOT / relative).read_text(encoding="utf-8"))


def link(label: str, relative: str) -> str:
    path = Path(relative).as_posix()
    assert (ROOT / path).is_file(), f"Evidence file is missing: {path}"
    return f"[{label}](../{path})"


def dims(value: list[float] | None) -> str:
    return " × ".join(f"{n:.4f}" for n in value) if value else "Sin evidencia"


def checked(value: bool) -> str:
    return "Sí" if value else "Pendiente"


def git(*args: str) -> str:
    return subprocess.check_output(
        ["git", *args], cwd=ROOT, text=True, encoding="utf-8"
    ).strip("\r\n")


def main() -> None:
    generated = datetime.now(timezone.utc).isoformat(timespec="seconds")
    ledger = read("assets/curse-expansion-progress.json")
    imports = read("assets/imports/curse_rework_2026-10-01.json")
    audit = read("assets/review/curse-rework/static-audit.json")
    rows = ledger["curses"]
    observed = {row["id"]: row for row in imports["imports"]}
    assert len(rows) == 50 and len({row["id"] for row in rows}) == 50
    assert set(observed) == {row["id"] for row in rows}
    counts = {key: sum(bool(row["stages"][key]) for row in rows) for key, _ in STAGES}
    assert counts == ledger["counts"], "Ledger counters do not match its per-Curse stages"

    # Bind the reported import to its exact frozen, current individual source.
    for row in rows:
        geometry = row["geometry"]
        export = ROOT / geometry["export"]
        actual_hash = hashlib.sha256(export.read_bytes()).hexdigest()
        assert actual_hash == row["currentFbxSha256"], row["id"]
        assert actual_hash == observed[row["id"]]["fbxSha256"], row["id"]
        assert (ROOT / geometry["blendSource"]).is_file(), row["id"]

    first_wave = [row for row in rows if row.get("historicalFirstWave", {}).get("robloxImportVerified")]
    rebuilt = [row for row in first_wave if row["historicalFirstWave"]["fbxSha256"] != row["currentFbxSha256"]]
    rarity_counts = Counter(row["rarity"] for row in rows)
    triangles = sum(row["geometry"]["triangles"] for row in rows)
    diagonals = [math.sqrt(sum(n * n for n in observed[row["id"]]["size"])) for row in rows]
    lines = [
        "# Anexo: las 50 Curses del rework actual",
        "",
        f"Instantánea generada: **{generated}**. El archivo no concede aprobaciones: refleja las etapas del registro actual.",
        "",
        f"Registro: {link('progreso por Curse', 'assets/curse-expansion-progress.json')}; "
        f"importaciones: {link('observaciones reales de Studio', 'assets/imports/curse_rework_2026-10-01.json')}; "
        f"QA: {link('auditoría estática', 'assets/review/curse-rework/static-audit.json')}. "
        "El registro conserva la evidencia histórica de los primeros quince por separado.",
        "",
        f"**{len(rebuilt)} de los quince iniciales reconstruidos y reimportados; {50 - len(first_wave)} modelos nuevos.** "
        f"Geometría total: {triangles:,} triángulos entre los cincuenta, no por fotograma. "
        f"Diagonales observadas en Studio: {min(diagonals):.4f}–{max(diagonals):.4f} studs.",
        "",
        "## Recuentos por etapa",
        "",
        "Planificadas en el catálogo: **50**; sin modelo terminado: "
        f"**{50 - counts['blenderModelComplete']}**. Las etapas son independientes.",
        "",
        "| Etapa | Cantidad |",
        "| --- | ---: |",
    ]
    lines += [f"| {label} | {counts[key]} / 50 |" for key, label in STAGES]
    lines += ["", "| Rareza | Cantidad |", "| --- | ---: |"]
    lines += [f"| {rarity} | {rarity_counts[rarity]} |" for rarity in ("COMMON", "RARE", "LEGENDARY", "MYTHIC", "SECRET")]
    lines += [
        "",
        "## Estado y nombres exactos",
        "",
        "«Juego» exige comprobación de las interacciones y la economía. Una importación o una imagen de Studio no sustituye esta etapa. "
        "«Pendiente» significa que el registro aún no contiene aprobación para el FBX actual.",
        "",
        "| Curse / ID | Rareza | Ref. | Modelo | QA | FBX | Import. | Apariencia | VFX | Juego | Habilitada |",
        "| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |",
    ]
    for row in rows:
        state = " | ".join(checked(row["stages"][key]) for key, _ in STAGES)
        lines.append(f"| {row['displayName']} · `{row['id']}` | {row['rarity']} | {state} |")

    lines += [
        "",
        "## MeshIds y medidas realmente observadas",
        "",
        "Medidas XYZ en studs, redondeadas aquí a cuatro decimales; los valores completos y los hashes de lote/componente están en el JSON de importación. "
        "TextureID vacío es deliberado: la superficie usa colores de vértice pintados; no se ha inventado una textura subida.",
        "",
        "| ID | MeshId observado | Size | MeshSize | TextureID |",
        "| --- | --- | --- | --- | --- |",
    ]
    for row in rows:
        imp = observed[row["id"]]
        texture = f"`{imp['textureId']}`" if imp.get("textureId") else "Vacío · vertex paint"
        lines.append(f"| `{row['id']}` | `{imp['meshId']}` | {dims(imp.get('size'))} | {dims(imp.get('meshSize'))} | {texture} |")

    lines += [
        "",
        "## Fuentes editables, FBX y perfiles de efectos",
        "",
        "Cada enlace corresponde al modelo actual. Las validaciones por familia prueban el FBX reimportado en Blender, incluidos límites, "
        "topología, colores y UV; la evidencia de Studio prueba una etapa distinta.",
        "",
        "| ID | Fuente / exportación / referencia | Triángulos | Colores pintados | Perfil VFX |",
        "| --- | --- | ---: | ---: | --- |",
    ]
    for row in rows:
        geometry = row["geometry"]
        source = " · ".join([
            link("Blend", geometry["blendSource"]),
            link("FBX", geometry["export"]),
            link("Hoja", "assets/reference/" + row["sourceReference"]),
        ])
        lines.append(f"| `{row['id']}` | {source} | {geometry['triangles']} | {geometry.get('paintedColorCount', '—')} | `{geometry['vfxProfile']}` |")

    lines += [
        "",
        "## Evidencia por Curse",
        "",
        "| ID | Revisión real de apariencia | SHA256 del FBX actual |",
        "| --- | --- | --- |",
    ]
    for row in rows:
        screenshots = observed[row["id"]].get("appearanceEvidence", [])
        links = " · ".join(link(f"Vista {i + 1}", path) for i, path in enumerate(screenshots)) or "Pendiente"
        lines.append(f"| `{row['id']}` | {links} | `{row['currentFbxSha256']}` |")

    lines += ["", "## Pendientes exactos de las etapas finales", ""]
    for key, label in STAGES[-4:]:
        pending = [row["displayName"] for row in rows if not row["stages"][key]]
        lines += [f"**{label}: {len(pending)} pendientes.** " + (", ".join(pending) + "." if pending else "Ninguna."), ""]
    summary = audit["summary"]
    lines += [
        "## Alcance de la auditoría estática",
        "",
        f"Última auditoría guardada: `{audit['auditedAtUtc']}`, estado `{audit['status']}`; "
        f"{summary['passed']} comprobaciones aprobadas y {summary['failed']} fallidas. "
        "Su fecha puede preceder cambios posteriores del registro. No ejecuta Studio ni certifica FPS, VFX, juego o un dispositivo móvil físico.",
        "",
        "Generador: [generate_curse_rework_report.py](tools/generate_curse_rework_report.py). "
        "Lee fuentes y evidencia; escribe únicamente este anexo y el inventario Markdown. El informe narrativo y las evidencias de Play no se sobrescriben.",
        "",
    ]
    (DOCS / "CURSE_EXPANSION_50_REWORK_STATUS.md").write_text("\n".join(lines), encoding="utf-8")

    status = git("status", "--porcelain=v1", "--untracked-files=all")
    entries = [(line[:2], line[3:]) for line in status.splitlines()]
    tracked = [item for item in entries if item[0] != "??"]
    new = [item for item in entries if item[0] == "??"]
    refs = [item for item in new if item[1].strip('"').startswith("assets/reference/")]
    inventory = [
        "# Inventario local de la expansión",
        "",
        f"Instantánea: **{generated}**; rama actual `{git('branch', '--show-current')}`; HEAD `{git('rev-parse', '--short', 'HEAD')}`.",
        "",
        f"Git presenta {len(tracked)} archivos seguidos modificados y {len(new)} archivos sin seguimiento. "
        f"Entre los últimos hay {len(refs)} referencias aportadas por el usuario antes del trabajo: no se cuentan como modelos creados. "
        "El inventario incluye archivos de prueba, capturas, artefactos y cachés tal como Git los devuelve; es una instantánea, no un commit.",
        "",
        "La rama y el estado iniciales están en el [registro](../assets/curse-expansion-progress.json). "
        "Una prueba de Play o captura posterior puede añadir archivos; regenerar este inventario después del cierre.",
        "",
        "| Estado Git | Archivo |",
        "| --- | --- |",
    ]
    inventory += [f"| `{state}` | `{path}` |" for state, path in entries]
    inventory += ["", "Generador: [generate_curse_rework_report.py](tools/generate_curse_rework_report.py).", ""]
    (DOCS / "CURSE_EXPANSION_50_REWORK_FILES.md").write_text("\n".join(inventory), encoding="utf-8")
    print(json.dumps({"generatedAtUtc": generated, "counts": counts, "rarities": dict(rarity_counts),
                      "initialModelsRebuilt": len(rebuilt), "newModels": 50 - len(first_wave),
                      "triangles": triangles, "observedDiagonalRange": [min(diagonals), max(diagonals)],
                      "gitTrackedChanges": len(tracked), "gitUntrackedFiles": len(new)}, indent=2))


if __name__ == "__main__":
    main()
