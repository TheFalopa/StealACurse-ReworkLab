param([string]$Baseline = '6b9891d')
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
Push-Location $projectRoot
try {
    $branch = & git branch --show-current
    if ($LASTEXITCODE -ne 0 -or $branch -ne 'feature/final-map-polish-v2') {
        throw "Expected feature/final-map-polish-v2, got '$branch'."
    }
    $head = & git rev-parse --short HEAD
    if ($LASTEXITCODE -ne 0) { throw 'Could not inspect HEAD.' }

    $corePaths = @('src/server/Gameplay/BaseService.luau', 'src/server/Gameplay/CurseService.luau', 'src/server/Gameplay/SoulsService.luau')
    $coreChanges = & git diff --name-only $Baseline -- $corePaths
    if ($LASTEXITCODE -ne 0) { throw 'Could not compare core services to the starting state.' }
    if ($coreChanges) { throw "Working core services changed; review before accepting: $($coreChanges -join ', ')" }
    $deletedSources = & git diff --name-only --diff-filter=D $Baseline -- assets/source/blender assets/export/meshes
    if ($LASTEXITCODE -ne 0) { throw 'Could not inspect original source/export retention.' }
    if ($deletedSources) { throw "Previous Blender/FBX files must not be deleted: $($deletedSources -join ', ')" }

    $originalProjectText = & git show ($Baseline + ':default.project.json')
    if ($LASTEXITCODE -ne 0) { throw 'Could not read baseline project.' }
    $original = ($originalProjectText -join "`n") | ConvertFrom-Json
    $projectText = Get-Content -LiteralPath 'default.project.json' -Raw
    $project = $projectText | ConvertFrom-Json
    if ($projectText -match '(?i)tests[/\\]|Quality(Map|UI)Validator|ExpansionValidator|SliceTestControl') {
        throw 'Read-only/test fixtures must not be mapped into the production project.'
    }
    $retainedMeshes = 0
    foreach ($kitName in @('MapMeshKit', 'CurseMeshKit')) {
        foreach ($property in $original.tree.ServerStorage.$kitName.PSObject.Properties) {
            if ($property.Name.StartsWith('$')) { continue }
            $current = $project.tree.ServerStorage.$kitName.($property.Name)
            $expectedId = $property.Value.'$properties'.MeshId
            if ($null -eq $current -or $current.'$properties'.MeshId -ne $expectedId) {
                throw "Original verified MeshId was removed/replaced: $kitName/$($property.Name)."
            }
            $retainedMeshes++
        }
        foreach ($property in $project.tree.ServerStorage.$kitName.PSObject.Properties) {
            if ($property.Name.StartsWith('$')) { continue }
            if ($property.Value.'$properties'.MeshId -notmatch '^rbxassetid://[1-9][0-9]+$') {
                throw "Invalid mapped MeshId: $kitName/$($property.Name)."
            }
        }
    }
    if ($retainedMeshes -ne 30) { throw "Expected thirty verified starting templates, got $retainedMeshes." }

    $originalCatalogText = & git show ($Baseline + ':src/shared/CurseCatalog.luau')
    if ($LASTEXITCODE -ne 0) { throw 'Could not read original catalog.' }
    $originalCatalog = $originalCatalogText -join "`n"
    $catalog = Get-Content -LiteralPath 'src/shared/CurseCatalog.luau' -Raw
    $originalIds = @('cursed_doll', 'haunted_mirror', 'crying_mask', 'watching_eye', 'soul_chains', 'the_void')
    foreach ($id in $originalIds) {
        $entryPattern = '(?ms)^\s*' + [regex]::Escape($id) + '\s*=\s*\{(?<body>.*?)^\s*\},'
        $previous = [regex]::Match($originalCatalog, $entryPattern)
        $current = [regex]::Match($catalog, $entryPattern)
        if (-not $previous.Success -or -not $current.Success) { throw "Original Curse definition missing: $id." }
        foreach ($field in @('price', 'baseSoulsPerSecond', 'spawnWeight')) {
            $fieldPattern = '\b' + $field + '\s*=\s*(?<value>[0-9.]+)'
            $before = [regex]::Match($previous.Groups['body'].Value, $fieldPattern)
            $after = [regex]::Match($current.Groups['body'].Value, $fieldPattern)
            if (-not $after.Success -or $before.Groups['value'].Value -ne $after.Groups['value'].Value) {
                throw "Original development economy changed: $id/$field."
            }
        }
    }
    $orderPattern = '(?s)Catalog\.Order\s*=\s*\{(?<body>.*?)\}'
    $oldOrder = [regex]::Matches([regex]::Match($originalCatalog, $orderPattern).Groups['body'].Value, '"(?<id>[a-z0-9_]+)"') | ForEach-Object { $_.Groups['id'].Value }
    $newOrder = [regex]::Matches([regex]::Match($catalog, $orderPattern).Groups['body'].Value, '"(?<id>[a-z0-9_]+)"') | ForEach-Object { $_.Groups['id'].Value }
    if (($oldOrder -join ',') -ne ($newOrder -join ',') -or $newOrder.Count -ne 6) {
        throw 'The original six live spawn-order entries must remain intact.'
    }

    $expectedNames = @{
        COMMON = @('Candle Wisp', 'Grave Hopper', 'Grave Key', 'Mourning Ribbon', 'Wilted Sprout', 'Ink Imp', 'Lost Locket', 'Ashen Book', 'Lantern Lurker', 'Hourglass Hound', 'Nail Beetle', 'Pale Guest', 'Cold Teacup', 'Coin Crawler', 'Umbrella Wraith')
        RARE = @('Marrow Dice', 'Veil Mourner', 'Grave Compass', 'Hollow Violin', 'Chime Triplets', 'Thimble Spider', 'Music Box Dancer', 'Raven Quill', 'Sorrow Chalice', 'Pale Gramophone', 'Thorn Reliquary', 'Anchor Crab', 'Sundial Sentinel', 'Sleepwalker Shoes')
        LEGENDARY = @('Night Harp', 'Thorn Cathedral', 'Phantom Marionette', 'Blood Moon Rose', 'Judgement Scales', 'Clockwork Raven', 'Eclipse Stag', 'Endless Library', 'Sunken Crown', 'Silent Choir')
        MYTHIC = @('Cathedral Heart', 'Plague Monarch', 'Hollow Throne', 'Worldroot', 'The Undertow', 'The Last Funeral')
        SECRET = @('Nameless Door', 'Crown of Silence', 'The First Grave', 'The Unwritten', 'The Last Star')
    }
    # Inspect the actual data tuples, not names occurring only in comments.
    $conceptPattern = '(?m)^\s*\{\s*"(?<id>[a-z0-9_]+)",\s*"(?<name>[^"]+)",\s*"(?<rarity>COMMON|RARE|LEGENDARY|MYTHIC|SECRET)",\s*(?<sheet>[0-9]+)\s*\},?\s*$'
    $concepts = @([regex]::Matches($catalog, $conceptPattern))
    if ($concepts.Count -ne 50) { throw "All fifty unique attached concepts are required, got $($concepts.Count). Sheet 10 adds three Mythics omitted in prose." }
    $conceptIds = @($concepts | ForEach-Object { $_.Groups['id'].Value })
    if (@($conceptIds | Select-Object -Unique).Count -ne 50) { throw 'Duplicate expansion IDs found.' }
    foreach ($rarity in $expectedNames.Keys) {
        $actualNames = @($concepts | Where-Object { $_.Groups['rarity'].Value -eq $rarity } | ForEach-Object { $_.Groups['name'].Value })
        if ($actualNames.Count -ne $expectedNames[$rarity].Count -or (Compare-Object $expectedNames[$rarity] $actualNames)) {
            throw "Expansion reference names/rarities are incomplete or altered: $rarity."
        }
    }
    if ($catalog -notmatch 'Catalog\.AllOrder\s*=\s*table\.clone\(Catalog\.Order\)' -or
        $catalog -notmatch 'table\.insert\(Catalog\.AllOrder,\s*id\)' -or
        $catalog -notmatch 'spawnWeight\s*=\s*0,\s*enabled\s*=\s*false' -or
        $catalog -notmatch 'sourceReference\s*=' -or $catalog -notmatch 'implementationStatus\s*=') {
        throw 'Catalog must expose the complete manifest, source/status fields and disabled controlled rollout.'
    }

    $manifestPath = 'assets/source/blender/curses_expansion/curse_expansion_manifest.json'
    $manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
    if ($manifest.schemaVersion -ne 1 -or $manifest.concepts.Count -ne 50) { throw 'The durable expansion manifest must contain all fifty concepts.' }
    foreach ($concept in $manifest.concepts) {
        $tuple = $concepts | Where-Object { $_.Groups['id'].Value -eq $concept.id }
        if ($null -eq $tuple -or $tuple.Groups['name'].Value -ne $concept.displayName -or
            $tuple.Groups['rarity'].Value -ne $concept.rarity -or $concept.visualKey -ne $concept.id -or
            [string]::IsNullOrWhiteSpace($concept.sourceReference) -or [string]::IsNullOrWhiteSpace($concept.implementationStatus)) {
            throw "Durable manifest and catalog disagree: $($concept.id)."
        }
        if ($concept.enabled -ne $false) { throw "Unvalidated expansion must remain disabled: $($concept.id)." }
        if ($concept.meshId) {
            $mapped = $project.tree.ServerStorage.CurseMeshKit.($concept.visualKey)
            if ($concept.meshId -notmatch '^rbxassetid://[1-9][0-9]+$' -or $null -eq $mapped -or $mapped.'$properties'.MeshId -ne $concept.meshId) {
                throw "Recorded Roblox import must match the production template: $($concept.id)."
            }
        } elseif ($concept.robloxImportVerified -eq $true) {
            throw "Cannot claim a verified import without its real MeshId: $($concept.id)."
        }
    }

    $geometryPath = 'assets/source/blender/curses_expansion/first_wave_geometry.json'
    $validationPath = 'assets/source/blender/curses_expansion/first_wave_validation.json'
    $geometry = Get-Content -LiteralPath $geometryPath -Raw | ConvertFrom-Json
    $validation = Get-Content -LiteralPath $validationPath -Raw | ConvertFrom-Json
    if ($geometry.waveCount -ne 15 -or $geometry.assets.Count -ne 15 -or $validation.assetCount -ne 15 -or $validation.status -ne 'FBX_ROUND_TRIP_PASS') {
        throw 'The first-wave geometry and actual FBX round-trip records must describe fifteen models.'
    }
    if (-not (Test-Path -LiteralPath 'assets/source/blender/curses_expansion/steal_a_curse_expansion_wave1.blend' -PathType Leaf)) {
        throw 'The editable first-wave Blender source is missing.'
    }
    $triangles = 0
    foreach ($asset in $geometry.assets) {
        if ($asset.id -notin $conceptIds -or -not (Test-Path -LiteralPath $asset.export -PathType Leaf)) { throw "First-wave export/catalog mismatch: $($asset.id)." }
        $concept = $manifest.concepts | Where-Object id -EQ $asset.id
        if ($concept.productionWave -ne 1 -or $concept.fbxExport -ne $asset.export -or
            (Get-FileHash -LiteralPath $asset.export -Algorithm SHA256).Hash -ne $concept.fbxSha256) {
            throw "First-wave export SHA/source manifest mismatch: $($asset.id)."
        }
        $record = $validation.assets | Where-Object id -EQ $asset.id
        if ($null -eq $record -or $record.meshObjects -ne 1 -or $record.triangles -ne $asset.triangles -or
            $asset.triangles -le 0 -or $asset.triangles -gt 2500 -or $record.nonManifoldEdges -ne 0 -or
            $record.looseVertices -ne 0 -or $record.degenerateFaces -ne 0 -or $record.uvLayers -lt 1) {
            throw "First-wave mesh topology/UV validation failed: $($asset.id)."
        }
        $triangles += $asset.triangles
    }
    if ($triangles -ne $geometry.totalSourceTriangles -or $triangles -ne $validation.sourceTriangles) { throw 'Triangle totals disagree with per-asset records.' }

    $sourceFiles = & rg --files src -g '*.luau'
    if ($LASTEXITCODE -ne 0) { throw 'Could not inventory production Luau.' }
    foreach ($sourcePath in $sourceFiles) {
        $source = Get-Content -LiteralPath $sourcePath -Raw
        if ($source -match 'GetService\s*\(\s*["'']MarketplaceService["'']|[:.]\s*(PromptGamePassPurchase|PromptProductPurchase|PromptPurchase)\s*\(|\.\s*ProcessReceipt\s*=|\b(GamePassId|ProductId|DeveloperProductId)\b') {
            throw "Real purchase APIs/IDs must not appear: $sourcePath."
        }
        if ($source -match '\b(SliceTestControl|QualityMapValidator|QualityUIValidator|ExpansionValidator)\b') {
            throw "Test-only entrypoint/control found in production Luau: $sourcePath."
        }
    }
    & git diff --check
    if ($LASTEXITCODE -ne 0) { throw 'git diff --check failed.' }
    Write-Output "EXPANSION_STATIC_PASS branch=$branch head=$head baseline=$Baseline retainedVerifiedMeshes=$retainedMeshes coreServicesUnchanged=true originalSixEconomyOrderPreserved=true expansionConcepts=50 expectedTotalCatalog=56 firstWaveExports=15 sourceTriangles=$triangles noPurchaseIntegration=true fixturesExcluded=true"
    Write-Output 'Scope: static source/export checks do not verify Roblox upload ownership, importer appearance, natural route behavior, physical travel, responsive gestures or hardware FPS.'
} finally {
    Pop-Location
}
