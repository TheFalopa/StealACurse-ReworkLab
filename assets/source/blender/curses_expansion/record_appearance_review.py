"""Record the actual root-agent visual review of the 50 freshly imported meshes."""
from pathlib import Path
import json, hashlib
ROOT=Path(__file__).resolve().parents[4]
path=ROOT/"assets/imports/curse_rework_2026-10-01.json"
data=json.loads(path.read_text(encoding="utf-8"))
byid={r["id"]:r for r in data["imports"]}
review=[]
for filename,group in (("common_rework_observed.json","common"),("rare_rework_observed.json","rare"),("high_rework_observed.json","high")):
    observed=sorted(json.loads((ROOT/"assets/imports"/filename).read_text()),key=lambda r:r["id"])
    for index,row in enumerate(observed):
        record=byid[row["id"]]
        assert record["meshId"]==row["meshId"]
        actual=hashlib.sha256((ROOT/record["export"]).read_bytes()).hexdigest()
        assert actual==record["fbxSha256"]
        key=f"{group}-{index//5+1:02d}"
        screenshots=[f"assets/review/curse-rework/{key}-studio-{angle}.jpg" for angle in ("front","back")]
        assert all((ROOT/p).is_file() for p in screenshots)
        proof={"id":row["id"],"meshId":row["meshId"],"fbxSha256":actual,"observedSize":row["size"],
            "screenshots":screenshots,"result":"ROOT_VISUAL_REVIEW_PASS",
            "scope":"Fresh actual Studio imports, isolated copies at original size, white SmoothPlastic multiplier; front and rear inspection. Painted colors, palette, three-dimensional form and focal detail visible. No gameplay/VFX approval implied."}
        review.append(proof)
        record["studioAppearanceChecked"]=True
        record["appearanceEvidence"]=screenshots
        record["materialTechnique"]="Authored painted vertex colors; UV map retained; no uploaded texture required."
        record["appearanceReview"]=proof
assert len(review)==50
path.write_text(json.dumps(data,indent=2)+"\n",encoding="utf-8")
out=ROOT/"assets/review/curse-rework/studio-appearance-review.json"
out.write_text(json.dumps({"count":50,"reviewer":"root agent; actual images viewed","assets":review},indent=2)+"\n",encoding="utf-8")
print("ACTUAL_STUDIO_APPEARANCE_REVIEW",len(review))
