param([switch]$Audit)
$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
$project=Get-Content -LiteralPath (Join-Path $root 'default.project.json') -Raw | ConvertFrom-Json
if ($Audit) {
    $project.tree.ServerScriptService | Add-Member Pass2Audit @{ '$path'=(Join-Path $PSScriptRoot 'VisualPass2Audit.server.luau') }
    $project.tree.StarterPlayer.StarterPlayerScripts | Add-Member Pass2AuditCamera @{ '$path'=(Join-Path $PSScriptRoot 'VisualPass2Audit.client.luau') }
}
$name=if($Audit){'build-curse-pass2-audit'}else{'build-curse-visual-pass2'}
$project | ConvertTo-Json -Depth 100 | Set-Content -LiteralPath (Join-Path $root ($name+'.project.json')) -Encoding UTF8
& rojo build (Join-Path $root ($name+'.project.json')) --output (Join-Path $root ($name+'.rbxlx'))
if ($LASTEXITCODE-ne 0){throw 'Build failed'}
