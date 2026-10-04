param([switch]$Multiplayer, [switch]$AllBases, [switch]$QualityPass, [switch]$Expansion, [switch]$CurseReviewGallery)
$ErrorActionPreference = 'Stop'
if ($CurseReviewGallery -and -not $QualityPass) { throw '-CurseReviewGallery requires -QualityPass.' }
if (([int]$Multiplayer.IsPresent + [int]$AllBases.IsPresent + [int]$QualityPass.IsPresent + [int]$Expansion.IsPresent) -gt 1) {
    throw 'Choose only one of -Multiplayer, -AllBases, -QualityPass or -Expansion.'
}
$projectRoot = Split-Path $PSScriptRoot -Parent
$project = Get-Content -LiteralPath (Join-Path $projectRoot 'default.project.json') -Raw | ConvertFrom-Json
$artifactName = if ($CurseReviewGallery) { 'build-curse-rework-enabled-gallery-captures' } elseif ($Expansion) { 'build-expansion-tests' } elseif ($QualityPass) { 'build-quality-pass-tests' } elseif ($AllBases) { 'build-slice-all-bases' } elseif ($Multiplayer) { 'build-slice-multiplayer' } else { 'build-slice-tests' }
$galleryFingerprints = @{}
if ($QualityPass -or $Expansion) {
    # Keep the production initialization and natural procession. These validators
    # are read-only: no credits, setup teleports, forced state or test remotes.
    $project.tree.ServerScriptService | Add-Member QualityMapValidator @{ '$path' = (Join-Path $PSScriptRoot 'QualityPass.server.luau') }
    $project.tree.StarterPlayer.StarterPlayerScripts | Add-Member QualityUIValidator @{ '$path' = (Join-Path $PSScriptRoot 'QualityUI.client.luau') }
    # Helpers stay in the review fixture. FinalWalk moves only when explicitly
    # requested on the real client; ReportSummary only reads existing evidence.
    $project.tree.ReplicatedStorage | Add-Member TestReviewSummary @{ '$path' = (Join-Path $PSScriptRoot 'ReviewSummary.luau') }
    $project.tree.ReplicatedStorage | Add-Member TestFinalWalk @{ '$path' = (Join-Path $PSScriptRoot 'FinalWalk.luau') }
    $project.tree.ReplicatedStorage | Add-Member TestReviewCamera @{ '$path' = (Join-Path $PSScriptRoot 'ReviewCamera.luau') }
    $project.tree.ServerScriptService | Add-Member ReviewSummaryServer @{ '$path' = (Join-Path $PSScriptRoot 'ReviewSummary.server.luau') }
    $project.tree.StarterPlayer.StarterPlayerScripts | Add-Member ReviewSummaryClient @{ '$path' = (Join-Path $PSScriptRoot 'ReviewSummary.client.luau') }
    $project.tree.StarterPlayer.StarterPlayerScripts | Add-Member FinalWalkHelper @{ '$path' = (Join-Path $PSScriptRoot 'FinalWalk.fixture.client.luau') }
    if ($CurseReviewGallery) {
        $gallerySources = @('src/client/init.client.luau', 'src/client/CurseVFX.luau', 'src/client/UI/CurseLabels.luau', 'default.project.json', 'tests/CurseReviewGallery.server.luau', 'tests/CurseReviewGalleryCamera.luau', 'tests/GalleryCamera.fixture.client.luau', 'tests/Build-StudioFixture.ps1')
        foreach ($folder in @('src/shared', 'src/server/Gameplay', 'src/server/Map')) {
            foreach ($file in Get-ChildItem -LiteralPath (Join-Path $projectRoot $folder) -Filter '*.luau' -File) { $gallerySources += $folder + '/' + $file.Name }
        }
        foreach ($sourcePath in ($gallerySources | Sort-Object -Unique)) { $galleryFingerprints[$sourcePath] = (Get-FileHash -LiteralPath (Join-Path $projectRoot $sourcePath) -Algorithm SHA256).Hash.ToLowerInvariant() }
        $galleryConfiguration = @{ builtAtUtc = [DateTime]::UtcNow.ToString('o'); sourceFingerprints = $galleryFingerprints }
        $project.tree.ServerScriptService | Add-Member CurseReviewGallery @{ '$path' = (Join-Path $PSScriptRoot 'CurseReviewGallery.server.luau') }
        $project.tree.ReplicatedStorage | Add-Member TestCurseReviewGalleryCamera @{ '$path' = (Join-Path $PSScriptRoot 'CurseReviewGalleryCamera.luau') }
        $project.tree.StarterPlayer.StarterPlayerScripts | Add-Member GalleryCaptureCamera @{ '$path' = (Join-Path $PSScriptRoot 'GalleryCamera.fixture.client.luau') }
        $project.tree.ReplicatedStorage | Add-Member CurseReviewGalleryConfig @{ '$className' = 'StringValue'; '$properties' = @{ Value = ($galleryConfiguration | ConvertTo-Json -Depth 6 -Compress) } }
    }
    if ($Expansion) {
        $project.tree.ServerScriptService | Add-Member ExpansionValidator @{ '$path' = (Join-Path $PSScriptRoot 'Expansion.server.luau') }
        $project.tree.ServerScriptService | Add-Member TestCurseGallery @{ '$path' = (Join-Path $PSScriptRoot 'CurseGallery.luau') }
    }
} else {
$server = $project.tree.ServerScriptService.Server
$entrypoint = if ($AllBases) { 'AllBases.server.luau' } elseif ($Multiplayer) { 'Multiplayer.server.luau' } else { 'Slice.server.luau' }
$server.'$path' = Join-Path $PSScriptRoot $entrypoint
$server | Add-Member Map @{ '$path' = (Join-Path $projectRoot 'src/server/Map') }
$server | Add-Member Gameplay @{ '$path' = (Join-Path $projectRoot 'src/server/Gameplay') }
$project.tree.StarterPlayer.StarterPlayerScripts | Add-Member TestClient @{ '$path' = (Join-Path $PSScriptRoot 'Slice.client.luau') }
}
# Only a generated test project is written; default.project.json is untouched.
$fixtureProject = Join-Path $projectRoot ($artifactName + '.project.json')
$project | ConvertTo-Json -Depth 100 | Set-Content -LiteralPath $fixtureProject -Encoding UTF8
& rojo build $fixtureProject --output (Join-Path $projectRoot ($artifactName + '.rbxlx'))
if ($LASTEXITCODE -ne 0) { throw 'Fixture build failed' }
if ($CurseReviewGallery) {
    foreach ($sourcePath in $galleryFingerprints.Keys) {
        if ((Get-FileHash -LiteralPath (Join-Path $projectRoot $sourcePath) -Algorithm SHA256).Hash.ToLowerInvariant() -ne $galleryFingerprints[$sourcePath]) { throw "Gallery source changed while building: $sourcePath" }
    }
    $proof = @{ artifact = $artifactName + '.rbxlx'; artifactSha256 = (Get-FileHash -LiteralPath (Join-Path $projectRoot ($artifactName + '.rbxlx')) -Algorithm SHA256).Hash.ToLowerInvariant(); configuration = $galleryConfiguration; productionInitializationUnchanged = $true; galleryPresentationOnly = $true }
    $proof | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath (Join-Path $projectRoot 'assets/review/curse-rework/enabled-gallery-captures-build-proof.json') -Encoding UTF8
    Write-Output ("Gallery quality fixture SHA256: " + $proof.artifactSha256)
}
