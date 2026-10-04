"""Align both real clients to the separately sampled authority timeline."""
import json,bisect,math,statistics
from pathlib import Path
root=Path(__file__).resolve().parents[1]
folder=root/'assets/review/management-animations'
p=json.loads((folder/'phase1-multiplayer-synchronized.json').read_text())
server=sorted(p['serverSamples'],key=lambda r:r['time']);times=[r['time']for r in server]
def percentile(a,q):return sorted(a)[min(len(a)-1,math.ceil(len(a)*q)-1)]
def summary(a):return {'count':len(a),'mean':statistics.mean(a),'p95':percentile(a,.95),'maximum':max(a)}
out={'network':p['profile'],'serverSamples':len(server),'method':'Linear interpolation between separately recorded server anchor samples at the same GetServerTimeNow timestamp; excludes samples outside recorded range. This is visual-to-authority separation, not network round-trip latency.','clients':[]}
for client in p['clients']:
 errors=[]
 for r in client['samples']:
  i=bisect.bisect_right(times,r['time'])
  if i==0 or i>=len(server):continue
  a,b=server[i-1],server[i];alpha=(r['time']-a['time'])/(b['time']-a['time'])
  target=[x+(y-x)*alpha for x,y in zip(a['a'],b['a'])]
  errors.append(math.dist(target,r['v']))
 out['clients'].append({'observer':client['summary']['observer'],'authoritySeparationStuds':summary(errors),'originalMotionSummary':client['summary']})
(folder/'phase1-authority-aligned.json').write_text(json.dumps(out,indent=2))
print(json.dumps(out,indent=2))
