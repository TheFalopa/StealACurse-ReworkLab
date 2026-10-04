param(
    [ValidateSet('All', 'Route', 'Purchase', 'PurchaseAndStress', 'Stress')][string]$Phase = 'All',
    [int]$ExpectedImportedCount = 0,
    [switch]$ExpectMobile,
    [string[]]$PurchaseIds = @(),
    [ValidateRange(0, 60)][double]$ReviewHoldSeconds = 0,
    [string[]]$ReviewIds = @('candle_wisp', 'pale_gramophone', 'thorn_cathedral', 'cathedral_heart', 'the_last_star')
)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
$project = Get-Content -LiteralPath (Join-Path $projectRoot 'default.project.json') -Raw | ConvertFrom-Json
$ledger = Get-Content -LiteralPath (Join-Path $projectRoot 'assets/curse-expansion-progress.json') -Raw | ConvertFrom-Json
$imports = @()
foreach ($curse in $ledger.curses) {
    if (-not $curse.stages.realRobloxImportRecorded) { continue }
    $exportPath = Join-Path $projectRoot $curse.geometry.export
    $actualHash = (Get-FileHash -LiteralPath $exportPath -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($actualHash -ne $curse.currentFbxSha256) { throw "Current FBX and import ledger differ: $($curse.id)" }
    $template = $project.tree.ServerStorage.CurseMeshKit.($curse.id)
    if (-not $template -or -not $template.'$properties'.MeshId) { throw "Missing actual imported template: $($curse.id)" }
    $imports += @{
        id = $curse.id
        fbxSha256 = $actualHash
        meshId = $template.'$properties'.MeshId
        export = $curse.geometry.export
        sourceReference = $curse.sourceReference
        triangles = $curse.geometry.triangles
    }
}
if ($imports.Count -eq 0) { throw 'The fixture needs at least one verified current-source import.' }
if ($ExpectedImportedCount -gt 0 -and $imports.Count -ne $ExpectedImportedCount) {
    throw "Expected $ExpectedImportedCount verified imports, found $($imports.Count)."
}
$knownImportedIds = @($imports | ForEach-Object { $_.id })
$seenPurchaseIds = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
foreach ($purchaseId in $PurchaseIds) {
    if ($knownImportedIds -cnotcontains $purchaseId) { throw "Purchase ID is not an exact current imported ID: $purchaseId" }
    if (-not $seenPurchaseIds.Add($purchaseId)) { throw "Duplicate purchase ID: $purchaseId" }
}
$sourceFingerprints = @{}
$proofSources = @(
    'src/shared/CurseVFXProfiles.luau',
    'src/client/CurseVFX.luau',
    'src/client/init.client.luau',
    'src/client/UI/CurseLabels.luau',
    'src/server/Gameplay/CurseVisualService.luau',
    'src/shared/CurseCatalog.luau',
    'src/shared/CurseExpansionAssets.luau',
    'src/server/Gameplay/CurseService.luau',
    'src/server/Gameplay/CurseProcessionService.luau',
    'src/server/Gameplay/SoulsService.luau',
    'src/server/Gameplay/BaseService.luau',
    'src/server/Gameplay/Config.luau',
    'src/server/Map/Build.luau',
    'src/server/Map/WorldPolish.luau',
    'src/server/Map/Grounding.luau',
    'src/server/Map/AssetKit.luau',
    'assets/source/blender/curses_expansion/rework/common_geometry.json',
    'assets/source/blender/curses_expansion/rework/rare_geometry.json',
    'assets/source/blender/curses_expansion/rework/high_geometry.json',
    'tests/CurseRework.server.luau',
    'tests/CurseRework.client.luau',
    'tests/Build-CurseReworkFixture.ps1',
    'default.project.json'
)
foreach ($mapSource in Get-ChildItem -LiteralPath (Join-Path $projectRoot 'src/server/Map') -Filter '*.luau' -File) {
    $proofSources += 'src/server/Map/' + $mapSource.Name
}
foreach ($sharedSource in Get-ChildItem -LiteralPath (Join-Path $projectRoot 'src/shared') -Filter '*.luau' -File) {
    $proofSources += 'src/shared/' + $sharedSource.Name
}
$proofSources = @($proofSources | Sort-Object -Unique)
foreach ($sourcePath in $proofSources) {
    $sourceFingerprints[$sourcePath] = (Get-FileHash -LiteralPath (Join-Path $projectRoot $sourcePath) -Algorithm SHA256).Hash.ToLowerInvariant()
}
$configuration = @{
    phase = $Phase
    expectedImportedCount = $imports.Count
    expectMobile = [bool]$ExpectMobile.IsPresent
    purchaseIds = $PurchaseIds
    reviewHoldSeconds = $ReviewHoldSeconds
    reviewIds = $ReviewIds
    builtAtUtc = [DateTime]::UtcNow.ToString('o')
    imports = $imports
    sourceFingerprints = $sourceFingerprints
} | ConvertTo-Json -Depth 12 -Compress
$server = $project.tree.ServerScriptService.Server
$server.'$path' = Join-Path $PSScriptRoot 'CurseRework.server.luau'
$server | Add-Member Map @{ '$path' = (Join-Path $projectRoot 'src/server/Map') }
$server | Add-Member Gameplay @{ '$path' = (Join-Path $projectRoot 'src/server/Gameplay') }
$project.tree.ReplicatedStorage | Add-Member CurseReworkFixtureConfig @{
    '$className' = 'StringValue'
    '$properties' = @{ Value = $configuration }
}
# Keep the production client entrypoint, HUD, label policy and VFX module intact.
$project.tree.StarterPlayer.StarterPlayerScripts | Add-Member CurseReworkTestClient @{
    '$path' = (Join-Path $PSScriptRoot 'CurseRework.client.luau')
}
$fixtureProject = Join-Path $projectRoot 'build-curse-rework-tests.project.json'
$fixturePlace = Join-Path $projectRoot 'build-curse-rework-tests.rbxlx'
$project | ConvertTo-Json -Depth 100 | Set-Content -LiteralPath $fixtureProject -Encoding UTF8
& rojo build $fixtureProject --output $fixturePlace
if ($LASTEXITCODE -ne 0) { throw 'Curse rework fixture build failed.' }
foreach ($sourcePath in $proofSources) {
    $afterBuild = (Get-FileHash -LiteralPath (Join-Path $projectRoot $sourcePath) -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($afterBuild -ne $sourceFingerprints[$sourcePath]) {
        throw "Source changed while the fixture was built; rebuild to preserve accurate fingerprints: $sourcePath"
    }
}
Write-Output "Curse rework fixture ready: phase=$Phase currentImports=$($imports.Count)"
$fixtureHash = (Get-FileHash -LiteralPath $fixturePlace -Algorithm SHA256).Hash.ToLowerInvariant()
$configHasher = [Security.Cryptography.SHA256]::Create()
try {
    $configHash = [BitConverter]::ToString($configHasher.ComputeHash([Text.Encoding]::UTF8.GetBytes($configuration))).Replace('-', '').ToLowerInvariant()
} finally { $configHasher.Dispose() }
$buildProof = @{
    artifact = (Split-Path $fixturePlace -Leaf)
    artifactSha256 = $fixtureHash
    configSha256 = $configHash
    configuration = ($configuration | ConvertFrom-Json)
}
$buildProof | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath (Join-Path $projectRoot 'build-curse-rework-tests.proof.json') -Encoding UTF8
Write-Output "Curse rework fixture SHA256: $fixtureHash"
