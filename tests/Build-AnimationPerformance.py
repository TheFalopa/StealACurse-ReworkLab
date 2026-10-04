import json,subprocess
from pathlib import Path
root=Path(__file__).resolve().parents[1]
p=json.loads((root/'default.project.json').read_text(encoding='utf8'))
p['tree']['ServerScriptService']['AnimationPerformance']={'$path':str(root/'tests/AnimationPerformance.server.luau')}
p['tree']['StarterPlayer']['StarterPlayerScripts']['AnimationPerformance']={'$path':str(root/'tests/AnimationPerformance.client.luau')}
p['tree']['ServerStorage']['LocalProfileBridge']={'$className':'Folder','$attributes':{'Namespace':'qa-animation-performance'}}
out=root/'build-curse-animation-performance.project.json';out.write_text(json.dumps(p,indent=2),encoding='utf8')
subprocess.run([str(Path.home()/'.rokit/bin/rojo.exe'),'build',str(out),'--output',str(root/'build-curse-animation-performance.rbxlx')],check=True)
