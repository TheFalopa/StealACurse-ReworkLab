"""Build and inspect fourteen original Rare Curse models from current sheets.

Blender invocation: blender -b --python rare_generate.py -- pale_gramophone
No initial-wave mesh, source or import record is overwritten.
"""
from pathlib import Path
import json
import sys

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
from rework_geometry import Sculpt, PALETTE, reset, render, validate_asset
from rare_models import MODELS

# Copper patina is distinct from the olive plant palette used by other ranks.
PALETTE['verdigris'] = (.22, .40, .34)

DISPLAY = {
    'marrow_dice': 'Marrow Dice', 'veil_mourner': 'Veil Mourner',
    'grave_compass': 'Grave Compass', 'hollow_violin': 'Hollow Violin',
    'chime_triplets': 'Chime Triplets', 'thimble_spider': 'Thimble Spider',
    'music_box_dancer': 'Music Box Dancer', 'raven_quill': 'Raven Quill',
    'sorrow_chalice': 'Sorrow Chalice', 'pale_gramophone': 'Pale Gramophone',
    'thorn_reliquary': 'Thorn Reliquary', 'anchor_crab': 'Anchor Crab',
    'sundial_sentinel': 'Sundial Sentinel', 'sleepwalker_shoes': 'Sleepwalker Shoes',
}


def main():
    args = sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else []
    wanted = args or list(MODELS)
    geometry_path, validation_path = HERE / 'rare_geometry.json', HERE / 'rare_validation.json'
    rows = json.loads(geometry_path.read_text(encoding='utf-8'))['assets'] if geometry_path.exists() else []
    checks = json.loads(validation_path.read_text(encoding='utf-8'))['assets'] if validation_path.exists() else []
    for identity in wanted:
        reset()
        model = Sculpt()
        details = MODELS[identity](model)
        obj, row = model.finish(identity, DISPLAY[identity], 'Rare', details['reference'],
            details['hook'], details['profile'], notes=[details['design'], details['motion']])
        row['vfxHooksRoblox'] = {name: [at[0]-model.offset[0], at[2]-model.offset[2],
            -(at[1]-model.offset[1])] for name, at in details.get('hooks', {}).items()}
        row['vfxGlowMaterial'] = details.get('glow', 'cyan')
        render(obj, HERE / (identity + '_preview.png'), azimuth=.95)
        rows = [old for old in rows if old['id'] != identity] + [row]
        checks = [old for old in checks if old['id'] != identity] + [validate_asset(row)]
        print('RARE_BUILT ' + identity + ' triangles=' + str(row['triangles']) +
              ' colors=' + str(row['paintedColorCount']) + ' diagonal=' + str(round(row['diagonal'], 3)), flush=True)
        geometry_path.write_text(json.dumps({'assets': rows}, indent=2)+'\n', encoding='utf-8')
        validation_path.write_text(json.dumps({'assets': checks}, indent=2)+'\n', encoding='utf-8')


if __name__ == '__main__':
    main()
