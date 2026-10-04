"""Build an isolated native Studio two-client fixture from the current sources.

Run in Studio through Test > Local Server > 2 Players > Start. Nothing from
tests/ is added to the release project; the native CurseMeshKit stays intact.
"""
import argparse
import datetime
import json
import subprocess
from pathlib import Path

root = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--output', type=Path, default=root / 'build-curse-polished-multiplayer.rbxlx')
args = parser.parse_args()
project = json.loads((root / 'default.project.json').read_text(encoding='utf-8-sig'))
server = project['tree']['ServerScriptService']['Server']
server['$path'] = str(root / 'tests/PolishedMultiplayer.server.luau')
server['Map'] = {'$path': str(root / 'src/server/Map')}
server['Gameplay'] = {'$path': str(root / 'src/server/Gameplay')}
project['tree']['StarterPlayer']['StarterPlayerScripts']['PolishedMultiplayerClient'] = {
    '$path': str(root / 'tests/PolishedMultiplayer.client.luau')
}
# Avoid recovery records from an interrupted older QA run. The existing local
# profile plugin provides actual profile load/save under this separate key.
namespace = 'qa-polished-multiplayer-' + datetime.datetime.now().strftime('%Y%m%d-%H%M%S')
project['tree']['ServerStorage']['LocalProfileBridge'] = {
    '$className': 'Folder', '$attributes': {'Namespace': namespace}
}
project_file = root / 'build-curse-polished-multiplayer.project.json'
project_file.write_text(json.dumps(project, indent=2), encoding='utf-8')
rojo = Path.home() / '.rokit/bin/rojo.exe'
subprocess.run([str(rojo), 'build', str(project_file), '--output', str(args.output)], check=True)
print('Native two-client fixture:', args.output.resolve())
print('Isolated profile namespace:', namespace)
print('Use native Studio Test with 2 clients; Player1 claims with E, then Start.')
print('Each client has Capture 30s / Each Curse buttons. Review rendered geometry in the videos.')
