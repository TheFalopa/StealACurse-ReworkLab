"""Enable only the fifty current imports with complete actual Studio evidence."""
import json
from datetime import datetime, timezone
import update_rework_progress as progress
import apply_rework_assets
import write_rework_manifest


def main():
    progress.main()
    eligibility_path = progress.ROOT / 'assets/review/curse-rework/verification-eligibility.json'
    eligibility = json.loads(eligibility_path.read_text(encoding='utf-8'))
    assert eligibility['eligible'] and eligibility['applied'], 'Actual evidence must be audited and applied first'
    assert eligibility['testedCount'] == 50 and not eligibility.get('failures'), 'All fifty must pass'
    current_sources = progress.production_source_fingerprints()
    assert eligibility['productionSourceFingerprints'] == current_sources, 'Production changed after the actual tests'
    ledger = json.loads(progress.LEDGER.read_text(encoding='utf-8'))
    assert len(ledger['curses']) == 50
    for row in ledger['curses']:
        assert all(row['stages'][stage] for stage in progress.STAGES[:-1]), row['id']
        assert row['verification']['rowChecksPassed'], row['id']
        assert row['verification']['productionSourceFingerprints'] == current_sources, row['id']
    captured = datetime.now(timezone.utc).isoformat()
    ids = []
    for row in ledger['curses']:
        row['stages']['enabled'] = True
        row['evidence']['enabled'] = 'assets/review/curse-rework/local-activation.json'
        ids.append(row['id'])
    ledger['counts']['enabled'] = len(ids)
    progress.LEDGER.write_text(json.dumps(ledger, indent=2) + '\n', encoding='utf-8')
    apply_rework_assets.main()
    write_rework_manifest.main()
    updated = json.loads(progress.LEDGER.read_text(encoding='utf-8'))
    assert all(updated['counts'][stage] == 50 for stage in progress.STAGES), updated['counts']
    assert progress.production_source_fingerprints() == current_sources
    proof = {'capturedAtUtc': captured, 'scope': 'Local project activation after actual Studio gates; no experience publishing or Git commit',
             'enabledIds': ids, 'enabledNewCount': 50, 'preservedOriginalCount': 6,
             'eligibility': eligibility_path.relative_to(progress.ROOT).as_posix(),
             'eligibilitySha256': progress.digest(eligibility_path), 'productionSourceFingerprints': current_sources,
             'stageCounts': updated['counts']}
    output = progress.ROOT / 'assets/review/curse-rework/local-activation.json'
    output.write_text(json.dumps(proof, indent=2) + '\n', encoding='utf-8')
    print('LOCAL_ACTIVATION', json.dumps(updated['counts']))


if __name__ == '__main__':
    main()
