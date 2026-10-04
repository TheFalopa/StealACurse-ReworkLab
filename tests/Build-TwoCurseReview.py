"""Focused native regression for the two user-reported acts; never a release script."""
import json,subprocess
from pathlib import Path
root=Path(__file__).resolve().parents[1]
source=(root/'tests/AnimationReview.client.luau').read_text()
start=source.index("local order=")
end=source.index('local cursor,',start)
source=source[:start]+"local order={'music_box_dancer','thorn_reliquary'}\n"+source[end:]
source=source.replace('math.max(12,mesh.Size.Y*1.55)','math.max(16,mesh.Size.Y*1.55)')
source=source.replace("button('Gallery clip',738,function()",'local function startClip()')
source=source.replace('end)\n-- Finite fixture camera','end\nbutton(\'Gallery clip\',12,startClip)\ntask.delay(4,startClip)\n-- Finite fixture camera')
client=root/'tests/TwoCurseReview.client.luau';client.write_text(source)
project=json.loads((root/'default.project.json').read_text())
project['tree']['ServerScriptService']['AnimationReview']={'$path':str(root/'tests/AnimationReview.server.luau')}
project['tree']['StarterPlayer']['StarterPlayerScripts']['AnimationReview']={'$path':str(client)}
project['tree']['ServerStorage']['LocalProfileBridge']={'$className':'Folder','$attributes':{'Namespace':'qa-user-two-curses'}}
path=root/'build-two-curse-review.project.json';path.write_text(json.dumps(project,indent=2))
subprocess.run([str(Path.home()/'.rokit/bin/rojo.exe'),'build',str(path),'--output',str(root/'build-two-curse-review.rbxlx')],check=True)
