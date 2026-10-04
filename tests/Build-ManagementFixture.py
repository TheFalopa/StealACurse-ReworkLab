import json,subprocess
from pathlib import Path
root=Path(__file__).resolve().parents[1]
p=json.loads((root/'default.project.json').read_text(encoding='utf8'))
server=p['tree']['ServerScriptService']['Server']
server['$path']=str(root/'tests/Management.server.luau')
server['Map']={'$path':str(root/'src/server/Map')}
server['Gameplay']={'$path':str(root/'src/server/Gameplay')}
p['tree']['ServerStorage']['LocalProfileBridge']={'$className':'Folder','$attributes':{'Namespace':'qa-management'}}
p['tree']['ServerStorage']['UnitTest']={'$path':str(root/'tests/Unit')}
p['tree']['ServerScriptService']['UnitTestRunner']={'$path':str(root/'tests/UnitTestRunner.server.luau'),'$properties':{'Disabled':True}}
p['tree']['StarterPlayer']['StarterPlayerScripts']['ManagementTestClient']={'$path':str(root/'tests/Management.client.luau')}
out=root/'build-curse-management-tests.project.json'
out.write_text(json.dumps(p,indent=2),encoding='utf8')
subprocess.run([str(Path.home()/'.rokit/bin/rojo.exe'),'build',str(out),'--output',str(root/'build-curse-management-tests.rbxlx')],check=True)
