param(
    [ValidateSet('All','Route','Purchase','PurchaseAndStress','Stress')][string]$Phase='All',
    [string]$Name='build-curse-pass2-final-tests',
    [switch]$ExpectMobile,
    [string[]]$RouteIds=@('grave_key','mourning_ribbon','wilted_sprout','hourglass_hound','nail_beetle','cold_teacup','umbrella_wraith','veil_mourner','raven_quill','thorn_reliquary','night_harp','blood_moon_rose','judgement_scales','eclipse_stag','hollow_throne','worldroot','the_last_funeral','the_unwritten','the_void','nameless_door'),
    [string[]]$PurchaseIds=@(),
    [ValidateRange(0,60)][double]$ReviewHoldSeconds=10,
    [string[]]$ReviewIds=@('cursed_doll','haunted_mirror','crying_mask','watching_eye','soul_chains','the_void','pale_guest','cold_teacup','coin_crawler','pale_gramophone','thorn_cathedral','cathedral_heart','the_last_star')
)
$ErrorActionPreference='Stop'
$projectRoot=Split-Path $PSScriptRoot -Parent
if ($Name -notmatch '^build-curse-pass2-[a-z0-9-]+$') {throw 'Use a local pass2 build name.'}
$project=Get-Content -Raw -LiteralPath (Join-Path $projectRoot 'default.project.json') | ConvertFrom-Json
$first=Get-Content -Raw -LiteralPath (Join-Path $projectRoot 'assets/imports/curse_rework_2026-10-01.json') | ConvertFrom-Json
$current=Get-Content -Raw -LiteralPath (Join-Path $projectRoot 'assets/imports/curse-visual-pass2-current.json') | ConvertFrom-Json
$progress=Get-Content -Raw -LiteralPath (Join-Path $projectRoot 'assets/curse-expansion-progress.json') | ConvertFrom-Json
$proofById=@{}
foreach($item in $first.imports){$proofById[$item.id]=$item}
foreach($item in $current.rows){$proofById[$item.id]=$item}
$geometryById=@{}
foreach($item in $progress.curses){$geometryById[$item.id]=$item.geometry}
$imports=@()
foreach($id in @($proofById.Keys | Sort-Object)){
    $proof=$proofById[$id]
    $hash=(Get-FileHash -Algorithm SHA256 -LiteralPath (Join-Path $projectRoot $proof.export)).Hash.ToLowerInvariant()
    if($hash -ne $proof.fbxSha256){throw "FBX differs from actual import proof: $id"}
    $template=$project.tree.ServerStorage.CurseMeshKit.$id
    if($template.'$properties'.MeshId -ne $proof.meshId){throw "Template differs from actual imported ID: $id"}
    $triangles=if($proof.triangles){$proof.triangles}else{$geometryById[$id].triangles}
    $imports+=@{id=$id;fbxSha256=$hash;meshId=$proof.meshId;export=$proof.export;sourceReference=$proof.sourceReference;triangles=$triangles}
}
if($imports.Count -ne 56){throw "Expected 56 real imports; found $($imports.Count)"}
foreach($subset in @(@{name='Route';ids=$RouteIds},@{name='Purchase';ids=$PurchaseIds})){
    $seen=[Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
    foreach($id in $subset.ids){if(-not $proofById.ContainsKey($id) -or -not $seen.Add($id)){throw "Invalid or duplicated $($subset.name) ID: $id"}}
}
$sourceFingerprints=@{}
$proofSources=@('default.project.json','assets/imports/curse-visual-pass2-current.json','tests/VisualPass2Gameplay.server.luau','tests/VisualPass2Gameplay.client.luau','tests/Build-VisualPass2Gameplay.ps1')
foreach($file in Get-ChildItem -LiteralPath (Join-Path $projectRoot 'src') -Recurse -File){
    $proofSources+=$file.FullName.Substring($projectRoot.Length+1).Replace('\','/')
}
foreach($path in @($proofSources | Sort-Object -Unique)){
    $sourceFingerprints[$path]=(Get-FileHash -Algorithm SHA256 -LiteralPath (Join-Path $projectRoot $path)).Hash.ToLowerInvariant()
}
$config=@{phase=$Phase;builtAtUtc=[DateTime]::UtcNow.ToString('o');expectedImportedCount=56;expectMobile=[bool]$ExpectMobile;routeIds=$RouteIds;purchaseIds=$PurchaseIds;reviewIds=$ReviewIds;reviewHoldSeconds=$ReviewHoldSeconds;imports=$imports;sourceFingerprints=$sourceFingerprints}
$configuration=$config | ConvertTo-Json -Depth 15 -Compress
$server=$project.tree.ServerScriptService.Server
$server.'$path'=Join-Path $PSScriptRoot 'VisualPass2Gameplay.server.luau'
$server | Add-Member Map @{'$path'=(Join-Path $projectRoot 'src/server/Map')}
$server | Add-Member Gameplay @{'$path'=(Join-Path $projectRoot 'src/server/Gameplay')}
$project.tree.ReplicatedStorage | Add-Member CurseReworkFixtureConfig @{'$className'='StringValue';'$properties'=@{Value=$configuration}}
$project.tree.StarterPlayer.StarterPlayerScripts | Add-Member CurseReworkTestClient @{'$path'=(Join-Path $PSScriptRoot 'VisualPass2Gameplay.client.luau')}
$fixtureProject=Join-Path $projectRoot ($Name+'.project.json')
$fixturePlace=Join-Path $projectRoot ($Name+'.rbxlx')
$project | ConvertTo-Json -Depth 100 | Set-Content -Encoding UTF8 -LiteralPath $fixtureProject
& rojo build $fixtureProject --output $fixturePlace
if($LASTEXITCODE -ne 0){throw 'Pass2 gameplay build failed.'}
foreach($path in $sourceFingerprints.Keys){
    if((Get-FileHash -Algorithm SHA256 -LiteralPath (Join-Path $projectRoot $path)).Hash.ToLowerInvariant() -ne $sourceFingerprints[$path]){throw "Source changed during build: $path"}
}
@{artifact=(Split-Path $fixturePlace -Leaf);artifactSha256=(Get-FileHash -Algorithm SHA256 -LiteralPath $fixturePlace).Hash.ToLowerInvariant();configuration=$config} | ConvertTo-Json -Depth 25 | Set-Content -Encoding UTF8 -LiteralPath (Join-Path $projectRoot ($Name+'.proof.json'))
Write-Output "Verified fixture: $($imports.Count) imports; phase=$Phase; selected routes=$($RouteIds.Count); full purchases when PurchaseIds is empty."
