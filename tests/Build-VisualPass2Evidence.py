"""Index actual Studio captures and observed dimensions; never generate test results."""
import csv
import html
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
REVIEW = ROOT / 'assets/review/curse-pass2'

def read(path):
    return json.loads((ROOT / path).read_text(encoding='utf-8-sig'))

before = read('assets/review/curse-pass2/runtime-before-compare56-observed.json')
after = read('assets/review/curse-pass2/runtime-final56-observed.json')
audit = read('assets/review/curse-pass2/audit-56.json')
imports = read('assets/imports/curse-visual-pass2-current.json')
old_imports = read('assets/imports/curse_rework_2026-10-01.json')
previous = {r['id']: r for r in before['rows']}
decisions = {r['id']: r for r in audit['rows']}
native = {r['id']: r for r in imports['rows']}
old_native = {r['id']: r for r in old_imports['imports']}
rows = []
for observed in after['rows']:
    id = observed['id']
    old = previous[id]
    imported = native.get(id, old_native.get(id, {}))
    changed = id in native
    bp = REVIEW / 'before-compare' / f'{id}-play-avatar.jpg'
    ap = REVIEW / 'review03' / f'{id}-play-avatar.jpg'
    if id == 'the_last_funeral':
        ap = REVIEW / 'review03/the_last_funeral-play-avatar-recheck.jpg'
    if not ap.exists():
        ap = REVIEW / 'review02' / f'{id}-play-avatar.jpg'
    if not ap.exists():
        raise FileNotFoundError(ap)
    rows.append({
        'id': id, 'name': imported.get('displayName', id.replace('_',' ').title()),
        'rarity': observed['rarity'], 'initialClassification': decisions[id]['classification'],
        'work': 'Rediseño completo' if decisions[id]['classification']=='FULL_REDESIGN' else ('Geometría/materiales y escala' if changed else 'Escala y presentación; geometría conservada'),
        'beforeSize': old['size'], 'afterSize': observed['size'],
        'beforeMeshId': old['meshId'], 'meshId': observed['meshId'],
        'source': imported.get('blendSource', imported.get('source','')),
        'fbx': imported.get('export',''), 'fbxSha256': imported.get('fbxSha256', imported.get('sha256','')),
        'triangles': imported.get('triangles',''),
        'beforeImage': bp.relative_to(REVIEW).as_posix() if bp.exists() else '',
        'baselineGroupImage': f"baseline/group{old['group']:02d}-geometry-avatar.jpg",
        'afterImage': ap.relative_to(REVIEW).as_posix(),
        'comparisonDistanceStuds':22, 'comparisonFov':65,
        'avatarHeightBefore':old['avatarHeight'], 'avatarHeightAfter':observed['avatarHeight'],
    })
(REVIEW/'measures-56.json').write_text(json.dumps(rows,indent=2,ensure_ascii=False),encoding='utf-8')
with (ROOT/'docs/CURSE_VISUAL_PASS2_MEASURES.csv').open('w',newline='',encoding='utf-8-sig') as file:
    writer=csv.writer(file)
    writer.writerow(['id','name','rarity','work','before_W','before_H','before_D','after_W','after_H','after_D','beforeMeshId','currentMeshId','blend','FBX','FBX_SHA256','triangles','before_capture','after_capture'])
    for row in rows:
        writer.writerow([row['id'],row['name'],row['rarity'],row['work'],*row['beforeSize'],*row['afterSize'],row['beforeMeshId'],row['meshId'],row['source'],row['fbx'],row['fbxSha256'],row['triangles'],row['beforeImage'] or row['baselineGroupImage'],row['afterImage']])
page = '''<!doctype html><html lang="es"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Steal A Curse — segunda pasada</title>
<style>body{margin:0;background:#10131a;color:#eef1f6;font:16px system-ui}header,main{max-width:1450px;margin:auto;padding:24px}h1{margin:0 0 12px}p{line-height:1.5;color:#cbd1dc}input,select,button{background:#202735;color:white;border:1px solid #586378;border-radius:7px;padding:10px}nav{display:flex;gap:12px;flex-wrap:wrap;position:sticky;top:0;padding:16px;background:#10131af5;z-index:1}.pair{display:grid;grid-template-columns:1fr 1fr;gap:12px}.pair img{width:100%;display:block;border-radius:7px;cursor:zoom-in}article{margin:16px 0 40px;border-top:1px solid #414958;padding-top:18px}h2{margin:0 0 8px}small{color:#b6c0d0}figure{margin:0}figcaption{padding:8px 0}dl{display:grid;grid-template-columns:150px 1fr;gap:6px}dd{margin:0;overflow-wrap:anywhere}a{color:#99cfff}details{padding:12px;background:#1a202b;border-radius:7px}.single{grid-template-columns:1fr}.badge{color:#aadbd0;font-size:13px}dialog{max-width:96vw;width:1450px;background:#10131a;color:white;border:1px solid #67738d;padding:12px}dialog img{width:100%}dialog button{float:right}@media(max-width:850px){.pair{grid-template-columns:1fr}dl{grid-template-columns:1fr}}</style>
<header><h1>Steal A Curse · segunda pasada visual</h1><p>56 Curses revisadas en Play. 30 mallas reimportadas desde Blender, incluidos los seis originales; 26 conservan su estructura y reciben escala y presentación propias. Capturas reales de Studio, sin renders sustitutivos.</p><p>Los pares individuales usan 22 studs y 65° junto a una copia del avatar real (≈5,74 studs). Las otras 26 tienen evidencia anterior en grupos de cuatro a 22–25 studs; no se presentan esos grupos como pares individuales idénticos. Haz clic en una imagen para verla completa.</p><p><a href="../../../docs/CURSE_VISUAL_PASS2.md">Informe y alcance de las pruebas</a> · <a href="../../../docs/CURSE_VISUAL_PASS2_MEASURES.csv">Medidas, fuentes e IDs de las 56</a> · <a href="../../imports/curse-visual-pass2-current.json">30 importaciones actuales</a></p></header>
<main><nav><input id="q" placeholder="Buscar Curse" aria-label="Buscar Curse"><select id="rarity" aria-label="Rareza"><option value="">Todas las rarezas</option><option>COMMON</option><option>RARE</option><option>LEGENDARY</option><option>MYTHIC</option><option>SECRET</option></select><select id="work" aria-label="Trabajo"><option value="">Todo el trabajo</option><option value="new">30 mallas reimportadas</option><option value="kept">26 estructuras conservadas</option></select><span id="count"></span></nav><section id="items"></section></main><dialog id="zoom"><button onclick="this.parentElement.close()">Cerrar</button><img id="zoomImage" alt="Captura completa de Roblox Studio"></dialog>
<script>const rows=__ROWS__;const q=document.querySelector('#q'),rarity=document.querySelector('#rarity'),work=document.querySelector('#work');const escape=s=>String(s).replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));const size=s=>s.map(n=>n.toFixed(2)).join(' × ');function render(){const list=rows.filter(r=>(r.name+' '+r.id).toLowerCase().includes(q.value.toLowerCase())&&(!rarity.value||r.rarity===rarity.value)&&(!work.value||(work.value==='new'===!!r.beforeImage)));document.querySelector('#count').textContent=list.length+' Curses';document.querySelector('#items').innerHTML=list.map(r=>`<article><h2>${escape(r.name)} <small>${r.rarity}</small></h2><p class="badge">${escape(r.work)} · W × H × D: ${size(r.beforeSize)} → ${size(r.afterSize)} studs</p><div class="pair"><figure><img loading="lazy" src="${r.beforeImage||r.baselineGroupImage}" alt="${escape(r.name)} antes"><figcaption>${r.beforeImage?'Antes · 22 studs / 65°':'Antes · grupo de auditoría, 22–25 studs / 65°'}</figcaption></figure><figure><img loading="lazy" src="${r.afterImage}" alt="${escape(r.name)} después"><figcaption>Después · 22 studs / 65°</figcaption></figure></div><details><summary>Archivos e importación</summary><dl><dt>ID anterior</dt><dd>${r.beforeMeshId}</dd><dt>ID actual</dt><dd>${r.meshId}</dd><dt>Blender</dt><dd><a href="../../../${r.source}">${escape(r.source)}</a></dd><dt>FBX</dt><dd><a href="../../../${r.fbx}">${escape(r.fbx)}</a></dd><dt>SHA-256 FBX</dt><dd>${r.fbxSha256}</dd><dt>Triángulos</dt><dd>${r.triangles||'Ver manifiesto de la primera pasada'}</dd></dl></details></article>`).join('');document.querySelectorAll('article img').forEach(img=>img.onclick=()=>{document.querySelector('#zoomImage').src=img.src;document.querySelector('#zoom').showModal()})}for(const input of[q,rarity,work])input.addEventListener('input',render);render();</script></html>'''
page=page.replace("work.value==='new'===!!r.beforeImage", "(work.value==='new')===Boolean(r.beforeImage)")
page=page.replace('__ROWS__',json.dumps(rows,ensure_ascii=False).replace('</','<\\/'))
(REVIEW/'index.html').write_text(page,encoding='utf-8')
print(json.dumps({'indexed':len(rows),'individualBeforeAfter':sum(bool(r['beforeImage']) for r in rows),'gallery':str(REVIEW/'index.html')},ensure_ascii=False))
