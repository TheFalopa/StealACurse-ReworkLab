import json,subprocess,hashlib
from pathlib import Path
root=Path(__file__).resolve().parents[1]
frozen=root/'assets/review/management-animations/checkpoints/00-second-visual-pass-start'
proof={}
for mode,base in [('before',frozen),('after',root)]:
 p=json.loads((base/'default.project.json').read_text(encoding='utf8'))
 def paths(node):
  if isinstance(node,dict):
   for key,value in node.items():
    if key=='$path':node[key]=str(base/value)
    else:paths(value)
 paths(p)
 p['tree']['StarterPlayer']['StarterPlayerScripts']['PavementCompare']={'$path':str(root/'tests/PavementCompare.client.luau')}
 if mode=='after':p['tree']['ServerStorage']['LocalProfileBridge']={'$className':'Folder','$attributes':{'Namespace':'qa-pavement'}}
 project=root/f'build-curse-pavement-{mode}.project.json'
 project.write_text(json.dumps(p,indent=2),encoding='utf8')
 target=root/f'build-curse-pavement-{mode}.rbxlx'
 subprocess.run([str(Path.home()/'.rokit/bin/rojo.exe'),'build',str(project),'--output',str(target)],check=True)
 proof[mode]={'sourceRoot':str(base),'artifactSha256':hashlib.sha256(target.read_bytes()).hexdigest()}
(root/'assets/review/management-animations/phase2-compare-build-proof.json').write_text(json.dumps(proof,indent=2))
