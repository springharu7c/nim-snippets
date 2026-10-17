param(
    [string]$Installation = (Join-Path $HOME '.nimcp_ver5')
)
$ErrorActionPreference = 'Stop'
$templates = Join-Path $Installation 'templates'
$runner = Join-Path $Installation 'tools/workflow_ver5.rb'
$mainSource = Join-Path $PSScriptRoot 'Main_ver6.nim'
$snippetsSource = Join-Path $PSScriptRoot 'nim_competitive_ver6.code-snippets'
$mainTarget = Join-Path $templates 'template_ver5.nim'
$snippetsTarget = Join-Path $templates 'nim_competitive_ver5.code-snippets'
foreach ($path in @($mainSource, $snippetsSource, $mainTarget, $snippetsTarget, $runner)) {
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "Missing file: $path"
    }
}
$runnerText = [System.IO.File]::ReadAllText($runner)
$needle = "base.split('# === EDIT SOLVE BELOW ===', 2).first"
$replacement = 'base.split(/^proc solve\(\) =$/, 2).first'
if ($runnerText.Contains($needle)) {
    $runnerText = $runnerText.Replace($needle, $replacement)
} elseif (-not $runnerText.Contains($replacement)) {
    throw 'Workflow contains an unexpected self-test implementation; no files were changed.'
}
foreach ($path in @($mainTarget, $snippetsTarget, $runner)) {
    $backup = $path + '.backup_before_clean'
    if (-not (Test-Path -LiteralPath $backup)) {
        Copy-Item -LiteralPath $path -Destination $backup -ErrorAction Stop
    }
}
Copy-Item -LiteralPath $mainSource -Destination $mainTarget -Force
Copy-Item -LiteralPath $snippetsSource -Destination $snippetsTarget -Force
[System.IO.File]::WriteAllText($runner, $runnerText, (New-Object System.Text.UTF8Encoding($false)))
Write-Host 'Updated the installed starter/snippets and adjusted the self-test parser.'
Write-Host 'The next nnew will create a comment-free Main.nim. Existing Main.nim files were not touched.'
