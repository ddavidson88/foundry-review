#requires -Version 7.0
& {
[CmdletBinding()]
param(
    [string]$EraPath = 'C:\Program Files (x86)\World of Warcraft\_classic_era_',
    [string]$RuntimeZip
)
Clear-Host
[void](Read-Host 'Close WoW, then press Enter to start the Era installer')
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$expectedZip = '6ad75fd72a20597b156730ae2c24b08af58da78acfc0a32bfeb2ffc31a8b2217'
$source = 'https://raw.githubusercontent.com/ddavidson88/foundry-review/69afcd8e8e0ffcdc2ab63c69b0f863ad0233dc31/grindprobe/era11/ForeverGrindProbe-0.1.0-era.11-RUNTIME.zip'
$runId = (Get-Date -Format 'yyyyMMdd-HHmmss') + '-' + [guid]::NewGuid().ToString('N').Substring(0,8)
$documents = [Environment]::GetFolderPath('MyDocuments')
if (-not $documents) { throw 'Windows Documents folder could not be resolved.' }
$work = Join-Path $documents "ForeverGrindProbe\Install-era11-$runId"
New-Item -ItemType Directory -Path $work | Out-Null
$log = Join-Path $work 'install.log'
$transcript = $false
$backup = $null
$backupVerified = $false
$targetTouched = $false
$stage = $null
$failure = $null
$rollbackFailure = $null
$success = $false
function Assert-NoGame {
    if (@(Get-Process -Name 'Wow*' -ErrorAction SilentlyContinue).Count) {
        throw 'Close all World of Warcraft clients before running this installer.'
    }
}
function Assert-NoLinks([string]$Path) {
    $cursor = Get-Item -LiteralPath $Path -Force
    while ($null -ne $cursor) {
        if ($cursor.Attributes -band [IO.FileAttributes]::ReparsePoint) { throw "Linked path refused: $($cursor.FullName)" }
        $cursor = $cursor.Parent
    }
    foreach ($item in Get-ChildItem -LiteralPath $Path -Force -Recurse) {
        if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) { throw "Linked item refused: $($item.FullName)" }
    }
}
function Get-Inventory([string]$Path) {
    @(Get-ChildItem -LiteralPath $Path -File -Force -Recurse | ForEach-Object {
        [IO.Path]::GetRelativePath($Path, $_.FullName) + ':' + (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash
    } | Sort-Object)
}
try {
    Start-Transcript -Path $log | Out-Null
    $transcript = $true
    if (-not $IsWindows) { throw 'This installer requires Windows and PowerShell 7.' }
    Assert-NoGame
    $EraPath = (Resolve-Path -LiteralPath $EraPath).Path
    if ((Split-Path $EraPath -Leaf) -ne '_classic_era_') { throw 'Expected the _classic_era_ client folder.' }
    if (-not (Test-Path -LiteralPath (Join-Path $EraPath 'WowClassic.exe') -PathType Leaf)) { throw 'WowClassic.exe not found.' }
    $addons = Join-Path $EraPath 'Interface\AddOns'
    if (-not (Test-Path -LiteralPath $addons -PathType Container)) { throw 'Era Interface\AddOns not found.' }
    # Inspect ancestors without recursively scanning unrelated addons.
    $cursor = Get-Item -LiteralPath $addons
    while ($null -ne $cursor) {
        if ($cursor.Attributes -band [IO.FileAttributes]::ReparsePoint) { throw 'Linked client/addon paths are not supported.' }
        $cursor = $cursor.Parent
    }
    $target = Join-Path $addons 'ForeverGrindProbe'
    $stage = Join-Path $EraPath "Interface\GrindProbe-stage-$runId"
    # Probe write/delete access before downloading or changing the installed addon.
    $probe = Join-Path $addons ".GrindProbe-writecheck-$runId"
    try {
        New-Item -ItemType Directory -Path $probe | Out-Null
        Set-Content -LiteralPath (Join-Path $probe 'test.txt') -Value 'write check'
        Remove-Item -LiteralPath $probe -Recurse -Force
        if (Test-Path -LiteralPath $target) {
            Assert-NoLinks $target
            $probe = Join-Path $target ".GrindProbe-writecheck-$runId"
            Set-Content -LiteralPath $probe -Value 'write check'
            Remove-Item -LiteralPath $probe -Force
        }
    } catch {
        throw "Write-access check failed. Run PowerShell 7 as Administrator and retry. No addon swap attempted. Detail: $($_.Exception.Message)"
    }
    $zip = Join-Path $work 'ForeverGrindProbe-0.1.0-era.11-RUNTIME.zip'
    if ($RuntimeZip) { Copy-Item -LiteralPath $RuntimeZip -Destination $zip }
    else { Invoke-WebRequest -Uri $source -OutFile $zip }
    if ((Get-FileHash -LiteralPath $zip -Algorithm SHA256).Hash -ne $expectedZip) { throw 'Runtime ZIP SHA-256 mismatch.' }
    Write-Host '[OK] Cleared runtime ZIP hash verified.' -ForegroundColor Green
    New-Item -ItemType Directory -Path $stage | Out-Null
    Expand-Archive -LiteralPath $zip -DestinationPath $stage
    $candidate = Join-Path $stage 'ForeverGrindProbe'
    Assert-NoLinks $candidate
    $expectedFiles = @{
        'Capture.lua' = '0ccb47916c9ad23ffd5f4401dfb77b3edf7f0c4d43dc4efa5d2fc4aecd02d845'
        'Core.lua' = '032d1bd201b33ac775ac5c55642cafd7853c3df1184a7b6307c2fb492e307aa9'
        'ForeverGrindProbe.toc' = '648e27c59a62f66819461c90bd55d48cb3ce74902f55c0c959802c0909d645ae'
        'Refinements.lua' = 'f63e47a1155c680c908a93f681d88c22d80e7a02276cd4dd03d418cf39e34685'
        'Telemetry.lua' = '147632d882457168e8c6042e009732b2e002164d4e3df706d76b79dba67af514'
        'UI.lua' = '9630e68f30ff540c59e700ef3fd435aea097f671e50329fbb1bf81cff042e211'
    }
    function Assert-Candidate([string]$Path) {
        $files = @(Get-ChildItem -LiteralPath $Path -File -Force -Recurse)
        if ($files.Count -ne $expectedFiles.Count) { throw 'Unexpected runtime file count.' }
        foreach ($name in $expectedFiles.Keys) {
            if ((Get-FileHash -LiteralPath (Join-Path $Path $name) -Algorithm SHA256).Hash -ne $expectedFiles[$name]) { throw "Runtime file hash mismatch: $name" }
        }
    }
    Assert-Candidate $candidate
    if (Test-Path -LiteralPath $target) {
        Assert-NoLinks $target
        $backup = Join-Path $work 'previous-install'
        Copy-Item -LiteralPath $target -Destination $backup -Recurse -Force
        if (((Get-Inventory $target) -join "`n") -cne ((Get-Inventory $backup) -join "`n")) { throw 'Backup verification failed.' }
        $backupVerified = $true
        Write-Host "[OK] Previous install backed up and verified: $backup" -ForegroundColor Green
    }
    Assert-NoGame
    # The verified backup stays in Documents. No backup is placed in the client.
    $targetTouched = $true
    if (Test-Path -LiteralPath $target) { Remove-Item -LiteralPath $target -Recurse -Force }
    Move-Item -LiteralPath $candidate -Destination $target
    Assert-Candidate $target
    $success = $true
    Write-Host '[OK] Installed ForeverGrindProbe 0.1.0-era.11. SavedVariables untouched.' -ForegroundColor Green
} catch {
    $failure = $_.Exception.Message
    Write-Host "[FAIL] $failure" -ForegroundColor Red
    if ($targetTouched -and -not $success) {
        try {
            if (Test-Path -LiteralPath $target) { Remove-Item -LiteralPath $target -Recurse -Force }
            if ($backupVerified) {
                Copy-Item -LiteralPath $backup -Destination $target -Recurse -Force
                if (((Get-Inventory $target) -join "`n") -cne ((Get-Inventory $backup) -join "`n")) { throw 'Restored inventory mismatch.' }
                Write-Host '[OK] Restored and verified previous addon install from Documents.' -ForegroundColor Green
            }
        } catch {
            $rollbackFailure = $_.Exception.Message
            Write-Host "[FAIL] Restore needs manual assistance: $rollbackFailure. Verified backup retained at $backup" -ForegroundColor Red
        }
    }
} finally {
    if ($stage -and (Test-Path -LiteralPath $stage)) {
        try { Remove-Item -LiteralPath $stage -Recurse -Force }
        catch { Write-Host "[WARN] Could not remove staging directory: $stage" -ForegroundColor Yellow }
    }
    if ($transcript) { Stop-Transcript | Out-Null }
}
$reportPath = Join-Path $work 'report.txt'
$report = "ForeverGrindProbe era.11 installer r2`nSuccess: $success`nFailure: $failure`nRestore failure: $rollbackFailure`nLog: $log`nBackup verified: $backupVerified`n"
if (Test-Path -LiteralPath $log) { $report += Get-Content -LiteralPath $log -Raw }
try { Set-Content -LiteralPath $reportPath -Value $report -Encoding utf8 }
catch { Write-Host "[WARN] Report file could not be saved: $($_.Exception.Message)" -ForegroundColor Yellow }
try {
    Set-Clipboard -Value $report
    Write-Host '[OK] Report copied to clipboard for Launch Prep.' -ForegroundColor Green
} catch { Write-Host '[WARN] Clipboard copy failed. Use the amber report below.' -ForegroundColor Yellow }
Write-Host "AMBER BACKUP — report file: $reportPath" -ForegroundColor Yellow
Write-Host $report -ForegroundColor Yellow
Write-Host 'NEXT STEPS' -ForegroundColor Magenta
if ($success) {
    Write-Host 'Paste the report to Launch Prep. Then launch Era, check the panel/version, perform the native test, and collect the log.' -ForegroundColor Magenta
} else {
    Write-Host 'Keep WoW closed. Paste the report to Launch Prep for help before retrying.' -ForegroundColor Magenta
}
} @args
