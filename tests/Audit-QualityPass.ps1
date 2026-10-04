param([string]$Baseline = '1a3ad5f')
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
Push-Location $projectRoot
try {
    $branch = & git branch --show-current
    if ($LASTEXITCODE -ne 0 -or $branch -ne 'feature/final-map-polish-v2') {
        throw "Expected feature/final-map-polish-v2, got '$branch'."
    }
    $gameplayChanges = & git diff --name-only $Baseline -- src/server/Gameplay src/shared src/server/init.server.luau
    if ($LASTEXITCODE -ne 0) { throw 'Could not compare gameplay against baseline.' }
    if ($gameplayChanges) { throw "Gameplay/source contract changed; review intentionally before accepting: $gameplayChanges" }

    $originalText = & git show ($Baseline + ':default.project.json')
    if ($LASTEXITCODE -ne 0) { throw 'Could not read baseline project.' }
    $original = ($originalText -join "`n") | ConvertFrom-Json
    $currentText = Get-Content -LiteralPath 'default.project.json' -Raw
    $current = $currentText | ConvertFrom-Json
    if ($currentText -match '(?i)tests[/\\]|QualityMapValidator|QualityUIValidator|SliceTestControl') {
        throw 'A test fixture must not be mapped by the production project.'
    }
    $retainedMeshes = 0
    foreach ($kitName in @('MapMeshKit', 'CurseMeshKit')) {
        foreach ($property in $original.tree.ServerStorage.$kitName.PSObject.Properties) {
            if ($property.Name.StartsWith('$')) { continue }
            $newItem = $current.tree.ServerStorage.$kitName.($property.Name)
            $expectedId = $property.Value.'$properties'.MeshId
            if ($null -eq $newItem -or $newItem.'$properties'.MeshId -ne $expectedId) {
                throw "Verified original mesh was removed or replaced: $kitName/$($property.Name)."
            }
            if ($expectedId -notmatch '^rbxassetid://[1-9][0-9]+$') { throw "Invalid retained MeshId: $expectedId" }
            $retainedMeshes++
        }
    }

    $forbidden = @()
    $sourceFiles = & rg --files src -g '*.luau'
    if ($LASTEXITCODE -ne 0) { throw 'Could not inventory production Luau.' }
    foreach ($sourcePath in $sourceFiles) {
        $source = Get-Content -LiteralPath $sourcePath -Raw
        # Match actual API/service/ID references, not the phrase "no purchases"
        # in documentation. UI-only ComingSoon/TBD text is intentionally allowed.
        if ($source -match 'GetService\s*\(\s*["'']MarketplaceService["'']|[:.]\s*(PromptGamePassPurchase|PromptProductPurchase|PromptPurchase)\s*\(|\.\s*ProcessReceipt\s*=|\b(GamePassId|ProductId|DeveloperProductId)\b') {
            $forbidden += $sourcePath
        }
        if ($source -match '\bSliceTestControl\b|\bQualityMapValidator\b|\bQualityUIValidator\b') {
            throw "Test-only control/validator found in production Luau: $sourcePath"
        }
    }
    if ($forbidden.Count -gt 0) { throw "Purchase integration or product IDs require removal/review: $($forbidden -join ', ')" }
    & git diff --check
    if ($LASTEXITCODE -ne 0) { throw 'git diff --check failed.' }
    Write-Output "QUALITY_STATIC_PASS branch=$branch retainedVerifiedMeshes=$retainedMeshes gameplayUnchangedFrom=$Baseline noPurchaseIntegration=true fixturesExcluded=true"
} finally {
    Pop-Location
}
