"""Record coordinator review of already captured actual native Roblox frames."""
import json,hashlib
from pathlib import Path
root=Path(__file__).resolve().parents[1]
folder=root/'assets/review/sanctuary-restoration'
ledger_path=root/'assets/imports/curse-animation-current.json'
ledger=json.loads(ledger_path.read_text(encoding='utf-8'))
ids={'grave_hopper':'grave-hopper','nail_beetle':'nail-beetle','coin_crawler':'coin-crawler'}
notes={
 'grave_hopper':'Readable cut stone rim, RIP inscription, grouped moss and integrated expressive face. Four weighted leg chains preserved; native frames show changing stance/body and shell acting. Carry and ordinary pedestal instance inspected.',
 'nail_beetle':'Six plated leg chains, contrasting head/eyes/mandibles and forged nail remain distinguishable at native play distance. Native sampled poses retain leg articulation and separate moving nail. Normal carry and placed instance inspected.',
 'coin_crawler':'Bronze lip/body, pale minted coins, dark face and blue-gray legs are visually separated. Native stance/gaze/lid acting retained; all four knee chains have corrected source pivots and weights. Carry and placed instance inspected.',
}
rows=[]
for id,stem in ids.items():
 video=folder/'videos'/(stem+'-native.mp4');assert video.exists()
 ledger[id]['playReviewed']=True
 ledger[id]['sanctuaryReview']={'states':['PROCESSION','CARRYING','PLACED'],'video':str(video.relative_to(root)).replace('\\','/'),'review':notes[id]}
 rows.append({'id':id,'meshId':ledger[id]['meshId'],'review':notes[id],
  'video':str(video.relative_to(root)).replace('\\','/'),'videoSHA256':hashlib.sha256(video.read_bytes()).hexdigest(),
  'before':f'assets/review/sanctuary-restoration/visuals/{stem}-before-user.png',
  'after':f'assets/review/sanctuary-restoration/visuals/{stem}-native-pedestal.png'})
ledger_path.write_text(json.dumps(ledger,indent=2,ensure_ascii=False)+'\n',encoding='utf-8')
(folder/'visuals/native-visual-review.json').write_text(json.dumps({'reviewer':'root coordinator','scope':'3 changed models; 53 unchanged preserve prior native reviews. No claim of 56 new reviews. Sampled animation inspection is not a guarantee of perfect contact at every pose.','rows':rows,'sourceDeformationEvidence':'visuals/rig-deformation-checks.json','denseFrames':'videos/native-gait-detail.png'},indent=2,ensure_ascii=False)+'\n',encoding='utf-8')
