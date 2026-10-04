"""Isolated Studio fixture. Reuse --namespace for the durable reload check."""
import argparse,datetime,json,subprocess
from pathlib import Path
root=Path(__file__).resolve().parents[1]
p=argparse.ArgumentParser();p.add_argument('--namespace');p.add_argument('--output',default='build-sanctuary-review.rbxlx');p.add_argument('--full',action='store_true');a=p.parse_args()
namespace=a.namespace or 'qa-restoration-'+datetime.datetime.now().strftime('%Y%m%d-%H%M%S')
project=json.loads((root/'default.project.json').read_text(encoding='utf-8-sig'))
server=project['tree']['ServerScriptService']['Server']
server['$path']=str(root/'tests/SanctuaryReview.server.luau')
server['Map']={'$path':str(root/'src/server/Map')};server['Gameplay']={'$path':str(root/'src/server/Gameplay')}
storage=project['tree']['ServerStorage']
if a.full:
 storage['FullReview']={'$path':str(root/'tests/SanctuaryFullReview.luau')}
 storage['NativeReview']={'$path':str(root/'tests/SanctuaryNativeReview.luau')}
 if (root/'tests/SanctuarySpatialReview.luau').exists():storage['SpatialReview']={'$path':str(root/'tests/SanctuarySpatialReview.luau')}
 project['tree']['StarterPlayer']['StarterPlayerScripts']['SanctuaryReviewClient']={'$path':str(root/'tests/SanctuaryReview.client.luau')}
 project['tree']['ReplicatedStorage']['$attributes']={'FullRestorationReview':True}
storage['LocalProfileBridge']={'$className':'Folder','$attributes':{'Namespace':namespace}}
storage['UnitTest']={'$className':'Folder','RunUnitTest':{'$path':str(root/'tests/Unit/RunUnitTest.luau')},'Cases':{'$className':'Folder'}}
for name,path in [('Progression','tests/SanctuaryProgression.spec.luau'),('Architecture','tests/SanctuaryArchitecture.spec.luau'),('OwnedRules','tests/Unit/Cases/OwnedCurseRules_Test.luau')]:
 if (root/path).exists():storage['UnitTest']['Cases'][name]={'$path':str(root/path)}
file=root/'build-sanctuary-review.project.json';file.write_text(json.dumps(project,indent=2),encoding='utf-8')
subprocess.run([str(Path.home()/'.rokit/bin/rojo.exe'),'build',str(file),'--output',str(root/a.output)],check=True)
print('Isolated namespace:',namespace)
(root/'assets/review/sanctuary-restoration/qa-namespace.txt').write_text(namespace,encoding='utf-8')
