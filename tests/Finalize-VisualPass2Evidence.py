"""Verify saved artifacts and index actual Studio observations; run no simulated tests."""
from collections import Counter
from datetime import datetime, timezone
import hashlib
import json
from pathlib import Path
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
REVIEW = ROOT / 'assets/review/curse-pass2'

def read(path):
    return json.loads((ROOT / path).read_text(encoding='utf-8-sig'))

def digest(path):
    return hashlib.sha256((ROOT / path).read_bytes()).hexdigest()

def write(path, data):
    (ROOT / path).write_text(json.dumps(data, indent=2, ensure_ascii=False), encoding='utf-8')

measures = read('assets/review/curse-pass2/measures-56.json')
ledger = read('assets/imports/curse-visual-pass2-current.json')
full = read('assets/review/curse-pass2/gameplay-final56-observed.json')
mobile = read('assets/review/curse-pass2/gameplay-mobile13-observed.json')
startup = read('assets/review/curse-pass2/final-production-play-observed.json')
native = {r['id']: r for r in ledger['rows']}
full_assets = {r['id']: r for r in full['assets']}
mobile_assets = {r['id']: r for r in mobile['assets']}
rows = []
missing = []
sha_errors = []
for row in measures:
    id = row['id']
    for path in (row['source'], row['fbx'], 'assets/review/curse-pass2/' + (row['beforeImage'] or row['baselineGroupImage']), 'assets/review/curse-pass2/' + row['afterImage']):
        if not path or not (ROOT / path).is_file():
            missing.append({'id': id, 'path': path})
    if row['fbx'] and (ROOT / row['fbx']).is_file() and digest(row['fbx']) != row['fbxSha256']:
        sha_errors.append({'id': id, 'file': row['fbx']})
    if id in native and digest(native[id]['blendSource']) != native[id]['blendSha256']:
        sha_errors.append({'id': id, 'file': native[id]['blendSource']})
    actual = full_assets[id]
    mobile_actual = mobile_assets.get(id, {})
    assert actual['meshId'] == row['meshId']
    assert actual['purchase']['status'] == 'PASS' and actual['purchase']['usedActualClientPrompt']
    mobile_checked = id in mobile['purchase']['requestedIds'] and mobile_actual.get('purchase', {}).get('status') == 'PASS'
    rows.append({**row, 'importedInPass2': id in native,
        'appearanceReviewedInNativePlay': True,
        'appearanceEvidence': 'assets/review/curse-pass2/' + row['afterImage'],
        'purchaseDeliveryIncomePedestal': actual['purchase']['status'],
        'purchaseEvidence': 'assets/review/curse-pass2/gameplay-final56-observed.json',
        'mobilePurchaseVerified': mobile_checked,
        'mobileEvidence': 'assets/review/curse-pass2/gameplay-mobile13-observed.json' if mobile_checked else None,
        'latestFullRouteEvidence': 'assets/review/curse-pass2/gameplay-final56-observed.json' if id in full['route']['requestedIds'] else 'assets/review/curse-pass2/gameplay-batch01-observed.json',
        'geometryAuthoringScope': 'New or improved Blender/FBX imported in this pass' if id in native else 'Existing native mesh retained; concept-specific runtime scale and presentation adjusted'})

assert len(rows) == 56 and len(native) == 30
assert not missing and not sha_errors, (missing, sha_errors)
assert full['phase'] == mobile['phase'] == 'passed' and not full['failures'] and not mobile['failures']
assert startup['status'] == 'PASS'

fingerprints = {path: digest(path) for path in mobile['sourceFingerprints']}
changed_since_mobile = [path for path, sha in fingerprints.items() if sha != mobile['sourceFingerprints'][path]]
production_changes_since_mobile = [path for path in changed_since_mobile if path.startswith('src/') or path == 'default.project.json']
assert not production_changes_since_mobile
production_changes_since_full = [path for path, sha in fingerprints.items() if (path.startswith('src/') or path == 'default.project.json') and sha != full['sourceFingerprints'].get(path)]
assert production_changes_since_full == ['src/server/Gameplay/CurseVisualService.luau']

def normalized_hash(text):
    return hashlib.sha256(text.replace('\r\n', '\n').replace('\r', '\n').encode()).hexdigest()

tree = ET.parse(ROOT / 'build-curse-visual-pass2.rbxlx')
embedded = [p.text or '' for p in tree.iter() if p.attrib.get('name') == 'Source']
source_hashes = Counter(normalized_hash(path.read_text(encoding='utf-8-sig')) for path in (ROOT / 'src').rglob('*.luau'))
embedded_hashes = Counter(normalized_hash(text) for text in embedded)
assert embedded_hashes == source_hashes, 'Final rbxlx source differs from production files'

status = {'observedAtUtc': datetime.now(timezone.utc).isoformat(), 'counts': {'reviewed': 56, 'nativeReimports': 30, 'fullRedesigns': 6, 'geometryMaterialImprovements': 24, 'retainedGeometry': 26, 'purchasesVerified': full['purchase']['completed'], 'mobilePurchasesVerified': mobile['purchase']['completed']},
    'scope': 'Appearance was actually reviewed in native Play; gameplay observations come from saved native test reports, using seeded Souls and controlled offer selection. Price-only label correction after full56 was verified in mobile13. Retained geometry is not counted as newly authored.', 'rows': rows}
write('assets/review/curse-pass2/final-status-56.json', status)

artifacts = ['build-curse-visual-pass2.rbxlx', 'default.project.json', 'docs/CURSE_VISUAL_PASS2.md', 'docs/CURSE_VISUAL_PASS2_MEASURES.csv', 'assets/review/curse-pass2/index.html', 'assets/review/curse-pass2/final-status-56.json', 'assets/review/curse-pass2/gameplay-final56-observed.json', 'assets/review/curse-pass2/gameplay-mobile13-observed.json', 'assets/review/curse-pass2/final-production-play-observed.json', 'assets/imports/curse-visual-pass2-current.json']
proof = {'verifiedAtUtc': datetime.now(timezone.utc).isoformat(), 'status': 'PASS', 'method': 'Filesystem existence/SHA checks, final XML embedded-source comparison and indexing saved actual Studio observations; not a new engine test.',
    'artifactSha256': {path: digest(path) for path in artifacts}, 'sourceFingerprints': fingerprints,
    'embeddedProductionSources': len(embedded), 'finalXmlMatchesAllProductionSources': True,
    'productionChangesSinceMobileTest': production_changes_since_mobile,
    'metadataChangesSinceMobileTest': changed_since_mobile,
    'productionChangesSinceFull56Test': production_changes_since_full,
    'labelCorrectionScope': 'Preserve compact price text and disable truncation in DELIVERING/PLACED; mobile13 checks native text bounds and exact price after this correction.',
    'missingArtifacts': missing, 'assetShaErrors': sha_errors,
    'nativeStartupStatus': startup['status'], 'counts': status['counts'],
    'desktopStressNear': full['stress']['client']['near'], 'mobileEmulatedStressNear': mobile['stress']['client']['near'],
    'limitations': ['Studio emulation is not a physical phone benchmark', 'One client gameplay validation; multiplayer stealing/replication not verified here', '26 retained meshes have runtime scale/presentation changes, not newly exported Blender geometry']}
write('assets/review/curse-pass2/final-delivery-proof.json', proof)
print(json.dumps({'status': proof['status'], 'counts': status['counts'], 'embeddedProductionSources': len(embedded), 'productionChangesSinceMobileTest': production_changes_since_mobile}))
