import json,subprocess
from pathlib import Path
root=Path(__file__).resolve().parents[1]
p=json.loads((root/'default.project.json').read_text(encoding='utf8'))
s=p['tree']['ServerScriptService']['Server']
s['$path']=str(root/'tests/RecoveryQueue.server.luau')
s['Map']={'$path':str(root/'src/server/Map')}
s['Gameplay']={'$path':str(root/'src/server/Gameplay')}
p['tree']['ServerStorage']['LocalProfileBridge']={'$className':'Folder','$attributes':{'Namespace':'qa-recovery-queue'}}
p['tree']['StarterPlayer']['StarterPlayerScripts']['ManagementTestClient']={'$path':str(root/'tests/Management.client.luau')}
out=root/'build-curse-recovery-queue.project.json'
out.write_text(json.dumps(p,indent=2),encoding='utf8')
subprocess.run([str(Path.home()/'.rokit/bin/rojo.exe'),'build',str(out),'--output',str(root/'build-curse-recovery-queue.rbxlx')],check=True)
