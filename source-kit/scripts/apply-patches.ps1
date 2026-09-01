<#
.SYNOPSIS
Applies the reviewed 2.0.0 transformations to a prepared local decode.

.DESCRIPTION
Validates all pre-patch hashes, the exact deletion list, project-authored added
files, and every locally supplied vendor input before changing a staged copy of
the workspace. Required vendor inputs are fail-closed by default. -AllowPartial
permits a code-only development workspace and records its incomplete status.

.PARAMETER AllowPartial
Continue when required local vendor inputs are absent. An input that is present
but has the wrong checksum always fails.

.PARAMETER GitPath
Path or command name for Git, used only to apply the reviewed unified text patch.

.EXAMPLE
.\scripts\apply-patches.ps1

.EXAMPLE
.\scripts\apply-patches.ps1 -AllowPartial -GitPath "C:\Program Files\Git\cmd\git.exe"
#>
[CmdletBinding()]
param(
    [string]$ManifestPath = 'patches\2.0.0\manifest.json',
    [string]$GitPath = 'git',
    [switch]$AllowPartial
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'Common.ps1')

function Invoke-GitApply {
    param(
        [Parameter(Mandatory = $true)][string]$ResolvedGit,
        [Parameter(Mandatory = $true)][string]$Workspace,
        [Parameter(Mandatory = $true)][string]$PatchPath,
        [switch]$CheckOnly
    )

    $arguments = @('apply', '--no-index', '--whitespace=nowarn', '--unidiff-zero')
    if ($CheckOnly) { $arguments += '--check' }

    # Git interprets patch paths from the repository root when Workspace is an
    # ignored directory inside a clone. Running from that nested directory can
    # therefore return success while silently skipping every patch. Detect that
    # case and explicitly prepend the workspace path from the repository root.
    $invokeDirectory = $Workspace
    $repositoryProbe = & $ResolvedGit -C $Workspace rev-parse --show-toplevel 2>$null
    if ($LASTEXITCODE -eq 0 -and -not [string]::IsNullOrWhiteSpace(($repositoryProbe | Select-Object -First 1))) {
        $repositoryRoot = [IO.Path]::GetFullPath(($repositoryProbe | Select-Object -First 1).ToString().Trim())
        $workspaceFull = [IO.Path]::GetFullPath($Workspace)
        $repositoryPrefix = $repositoryRoot.TrimEnd('\', '/') + [IO.Path]::DirectorySeparatorChar
        if ($workspaceFull.StartsWith($repositoryPrefix, [StringComparison]::OrdinalIgnoreCase)) {
            $relativeWorkspace = $workspaceFull.Substring($repositoryPrefix.Length).Replace('\', '/')
            $arguments += "--directory=$relativeWorkspace"
            $invokeDirectory = $repositoryRoot
        }
    }
    $arguments += '--'
    $arguments += $PatchPath

    Push-Location $invokeDirectory
    try {
        $output = & $ResolvedGit @arguments 2>&1
        $exitCode = $LASTEXITCODE
    }
    finally {
        Pop-Location
    }
    if ($exitCode -ne 0) {
        $rendered = ($output | ForEach-Object { $_.ToString() }) -join [Environment]::NewLine
        throw "Git could not apply the reviewed text patch (exit $exitCode).`n$rendered"
    }
}

function Get-EntryHashMode {
    param([Parameter(Mandatory = $true)][object]$Entry)
    $property = $Entry.PSObject.Properties['hashMode']
    if ($null -eq $property) { return 'raw' }
    return [string]$property.Value
}

function Assert-PatchedWorkspace {
    param(
        [Parameter(Mandatory = $true)][string]$Workspace,
        [Parameter(Mandatory = $true)][object]$Manifest,
        [Parameter(Mandatory = $true)][hashtable]$ProvidedVendorTargets
    )

    foreach ($change in @($Manifest.fileChanges)) {
        if ($null -eq $change) { continue }
        $target = Resolve-ContainedPath -Root $Workspace -RelativePath ([string]$change.path)
        [void](Assert-FileHash -LiteralPath $target -ExpectedSha256 ([string]$change.patchedSha256) -Description "Patched target '$($change.path)'" -HashMode (Get-EntryHashMode -Entry $change))
    }
    foreach ($added in @($Manifest.addedFiles)) {
        if ($null -eq $added) { continue }
        $target = Resolve-ContainedPath -Root $Workspace -RelativePath ([string]$added.path)
        [void](Assert-FileHash -LiteralPath $target -ExpectedSha256 ([string]$added.patchedSha256) -Description "Added target '$($added.path)'" -HashMode (Get-EntryHashMode -Entry $added))
    }
    foreach ($deleted in @($Manifest.deletedFiles)) {
        if ($null -eq $deleted) { continue }
        $target = Resolve-ContainedPath -Root $Workspace -RelativePath ([string]$deleted.path)
        if ([IO.File]::Exists($target) -or [IO.Directory]::Exists($target)) {
            throw "Deletion postcondition failed; path still exists: $($deleted.path)"
        }
    }
    foreach ($targetPath in $ProvidedVendorTargets.Keys) {
        $vendor = $ProvidedVendorTargets[$targetPath]
        $target = Resolve-ContainedPath -Root $Workspace -RelativePath $targetPath
        [void](Assert-FileHash -LiteralPath $target -ExpectedSha256 ([string]$vendor.sha256) -Description "Vendor target '$targetPath'")
    }
}

$sourceKitRoot = Get-SourceKitRoot
$manifestRecord = Read-PatchManifest -ManifestPath $ManifestPath -SourceKitRoot $sourceKitRoot
$manifest = $manifestRecord.Data
$workspace = Get-WorkspacePath -Manifest $manifest -SourceKitRoot $sourceKitRoot
$workRoot = Join-Path $sourceKitRoot 'work'
Assert-SafeGeneratedDirectory -Path $workspace -AllowedRoot $workRoot

if (-not [IO.Directory]::Exists($workspace)) {
    throw "Prepared workspace not found. Run scripts\prepare-original.ps1 first: $workspace"
}

$state = Read-SourceKitState -SourceKitRoot $sourceKitRoot
if ([int]$state.schemaVersion -ne 1 -or
    -not ([string]$state.manifestSha256).Equals($manifestRecord.Sha256, [StringComparison]::OrdinalIgnoreCase) -or
    -not ([string]$state.originalApkSha256).Equals([string]$manifest.originalApkSha256, [StringComparison]::OrdinalIgnoreCase) -or
    [string]$state.workspaceRelativePath -ne [string]$manifest.workspaceRelativePath) {
    throw "Preparation state does not match this manifest. Re-run prepare-original.ps1 -Force with the pinned stock APK."
}

$patchAlreadyApplied = [bool]$state.patchApplied
$resolvedGit = Resolve-ToolPath -RequestedPath $GitPath -CommandName 'git' -ParameterHint '-GitPath'
$patchPath = Resolve-ContainedPath -Root $manifestRecord.Directory -RelativePath ([string]$manifest.textPatch)
$deleteListPath = Resolve-ContainedPath -Root $manifestRecord.Directory -RelativePath ([string]$manifest.deleteList)
if (-not [IO.File]::Exists($patchPath)) { throw "Text patch not found: $patchPath" }
if (-not [IO.File]::Exists($deleteListPath)) { throw "Deletion list not found: $deleteListPath" }

$declaredDeletionSet = New-Object 'Collections.Generic.HashSet[string]' ([StringComparer]::OrdinalIgnoreCase)
foreach ($deleted in @($manifest.deletedFiles)) {
    if ($null -eq $deleted) { continue }
    [void]$declaredDeletionSet.Add(([string]$deleted.path).Replace('\', '/'))
}
$listedDeletionSet = New-Object 'Collections.Generic.HashSet[string]' ([StringComparer]::OrdinalIgnoreCase)
foreach ($line in [IO.File]::ReadAllLines($deleteListPath)) {
    $trimmed = $line.Trim()
    if ($trimmed.Length -eq 0 -or $trimmed.StartsWith('#')) { continue }
    [void](Resolve-ContainedPath -Root $workspace -RelativePath $trimmed)
    if (-not $listedDeletionSet.Add($trimmed.Replace('\', '/'))) {
        throw "Duplicate path in deletion list: $trimmed"
    }
}
if ($listedDeletionSet.Count -ne $declaredDeletionSet.Count) {
    throw "delete-paths.txt does not exactly match manifest.deletedFiles."
}
foreach ($path in $declaredDeletionSet) {
    if (-not $listedDeletionSet.Contains($path)) {
        throw "delete-paths.txt is missing manifest deletion: $path"
    }
}

$addedSources = @{}
foreach ($added in @($manifest.addedFiles)) {
    if ($null -eq $added) { continue }
    $sourceProperty = $added.PSObject.Properties['source']
    if ($null -ne $sourceProperty -and -not [string]::IsNullOrWhiteSpace([string]$sourceProperty.Value)) {
        $relativeSource = [string]$sourceProperty.Value
    }
    else {
        $relativeSource = Join-Path 'files' ([string]$added.path)
    }
    $source = Resolve-ContainedPath -Root $manifestRecord.Directory -RelativePath $relativeSource
    if (-not [IO.File]::Exists($source)) { throw "Added-file payload not found: $relativeSource" }
    [void](Assert-FileHash -LiteralPath $source -ExpectedSha256 ([string]$added.patchedSha256) -Description "Added-file payload '$relativeSource'" -HashMode (Get-EntryHashMode -Entry $added))
    $addedSources[[string]$added.path] = $source
}

$providedVendorTargets = @{}
$missingRequired = New-Object Collections.Generic.List[string]
foreach ($vendor in @($manifest.vendorInputs)) {
    if ($null -eq $vendor) { continue }
    $inputPath = Resolve-ContainedPath -Root $sourceKitRoot -RelativePath ([string]$vendor.inputPath)
    $targetPath = ([string]$vendor.targetPath).Replace('\', '/')
    if (-not [IO.File]::Exists($inputPath)) {
        $existingTarget = Resolve-ContainedPath -Root $workspace -RelativePath $targetPath
        if ([IO.File]::Exists($existingTarget)) {
            [void](Assert-FileHash -LiteralPath $existingTarget -ExpectedSha256 ([string]$vendor.sha256) -Description "Existing vendor target '$targetPath'")
            $providedVendorTargets[$targetPath] = $vendor
            continue
        }
        if ([bool]$vendor.requiredForCompleteBuild) {
            [void]$missingRequired.Add([string]$vendor.inputPath)
        }
        continue
    }

    [void](Assert-FileHash -LiteralPath $inputPath -ExpectedSha256 ([string]$vendor.sha256) -Description "Local vendor input '$($vendor.inputPath)'")
    $sizeProperty = $vendor.PSObject.Properties['size']
    if ($null -ne $sizeProperty -and [int64]$sizeProperty.Value -ne (Get-Item -LiteralPath $inputPath).Length) {
        throw "Local vendor input size mismatch: $($vendor.inputPath)"
    }
    $providedVendorTargets[$targetPath] = $vendor
}

if ($missingRequired.Count -gt 0 -and -not $AllowPartial) {
    $missingText = ($missingRequired | Sort-Object) -join [Environment]::NewLine
    throw "Required local vendor inputs are missing. Supply the exact checksum-pinned files, or use -AllowPartial for a code-only development build:`n$missingText"
}

if (-not $patchAlreadyApplied) {
    foreach ($change in @($manifest.fileChanges)) {
        if ($null -eq $change) { continue }
        $target = Resolve-ContainedPath -Root $workspace -RelativePath ([string]$change.path)
        [void](Assert-FileHash -LiteralPath $target -ExpectedSha256 ([string]$change.originalSha256) -Description "Patch precondition '$($change.path)'" -HashMode (Get-EntryHashMode -Entry $change))
    }
    foreach ($deleted in @($manifest.deletedFiles)) {
        if ($null -eq $deleted) { continue }
        $target = Resolve-ContainedPath -Root $workspace -RelativePath ([string]$deleted.path)
        [void](Assert-FileHash -LiteralPath $target -ExpectedSha256 ([string]$deleted.originalSha256) -Description "Deletion precondition '$($deleted.path)'" -HashMode (Get-EntryHashMode -Entry $deleted))
    }
    foreach ($added in @($manifest.addedFiles)) {
        if ($null -eq $added) { continue }
        $target = Resolve-ContainedPath -Root $workspace -RelativePath ([string]$added.path)
        if ([IO.File]::Exists($target) -or [IO.Directory]::Exists($target)) {
            throw "Added-file precondition failed; path already exists: $($added.path)"
        }
    }
}
else {
    Assert-PatchedWorkspace -Workspace $workspace -Manifest $manifest -ProvidedVendorTargets @{}
}

$allVendorAlreadyPresent = $true
foreach ($targetPath in $providedVendorTargets.Keys) {
    $vendorTarget = Resolve-ContainedPath -Root $workspace -RelativePath $targetPath
    if ([IO.File]::Exists($vendorTarget)) {
        [void](Assert-FileHash -LiteralPath $vendorTarget -ExpectedSha256 ([string]$providedVendorTargets[$targetPath].sha256) -Description "Existing vendor target '$targetPath'")
    }
    else {
        $allVendorAlreadyPresent = $false
    }
}
if ($patchAlreadyApplied -and $allVendorAlreadyPresent -and
    ([bool]$state.completeBuildInputs -eq ($missingRequired.Count -eq 0))) {
    Write-Output "Patch workspace is already current and verified: $workspace"
    return
}

$stagePath = Join-Path $workRoot ('.apply-' + [Guid]::NewGuid().ToString('N'))
$backupPath = Join-Path $workRoot ('.previous-' + [Guid]::NewGuid().ToString('N'))
$stateTempPath = $null
Assert-SafeGeneratedDirectory -Path $stagePath -AllowedRoot $workRoot
Assert-SafeGeneratedDirectory -Path $backupPath -AllowedRoot $workRoot

try {
    [void][IO.Directory]::CreateDirectory($stagePath)
    Get-ChildItem -LiteralPath $workspace -Force | Copy-Item -Destination $stagePath -Recurse -Force

    if (-not $patchAlreadyApplied) {
        foreach ($change in @($manifest.fileChanges)) {
            if ($null -eq $change -or (Get-EntryHashMode -Entry $change) -ne 'text-utf8-lf') { continue }
            $target = Resolve-ContainedPath -Root $stagePath -RelativePath ([string]$change.path)
            Set-NormalizedUtf8Text -LiteralPath $target -Text (Get-NormalizedUtf8Text -LiteralPath $target)
        }

        Invoke-GitApply -ResolvedGit $resolvedGit -Workspace $stagePath -PatchPath $patchPath -CheckOnly
        Invoke-GitApply -ResolvedGit $resolvedGit -Workspace $stagePath -PatchPath $patchPath

        foreach ($change in @($manifest.fileChanges)) {
            if ($null -eq $change -or (Get-EntryHashMode -Entry $change) -ne 'text-utf8-lf') { continue }
            $target = Resolve-ContainedPath -Root $stagePath -RelativePath ([string]$change.path)
            Set-NormalizedUtf8Text -LiteralPath $target -Text (Get-NormalizedUtf8Text -LiteralPath $target)
        }

        foreach ($added in @($manifest.addedFiles)) {
            if ($null -eq $added) { continue }
            $target = Resolve-ContainedPath -Root $stagePath -RelativePath ([string]$added.path)
            $parent = Split-Path -Parent $target
            if (-not [IO.Directory]::Exists($parent)) { [void][IO.Directory]::CreateDirectory($parent) }
            if ((Get-EntryHashMode -Entry $added) -eq 'text-utf8-lf') {
                Set-NormalizedUtf8Text -LiteralPath $target -Text (Get-NormalizedUtf8Text -LiteralPath $addedSources[[string]$added.path])
            }
            else {
                [IO.File]::Copy($addedSources[[string]$added.path], $target, $false)
            }
        }

        foreach ($deletedPath in $listedDeletionSet) {
            $target = Resolve-ContainedPath -Root $stagePath -RelativePath $deletedPath
            if (-not [IO.File]::Exists($target)) {
                throw "Refusing deletion because the exact verified file is absent: $deletedPath"
            }
            Remove-Item -LiteralPath $target -Force
        }
    }

    foreach ($targetPath in $providedVendorTargets.Keys) {
        $vendor = $providedVendorTargets[$targetPath]
        $target = Resolve-ContainedPath -Root $stagePath -RelativePath $targetPath
        if ([IO.File]::Exists($target)) {
            [void](Assert-FileHash -LiteralPath $target -ExpectedSha256 ([string]$vendor.sha256) -Description "Existing vendor target '$targetPath'")
            continue
        }
        $parent = Split-Path -Parent $target
        if (-not [IO.Directory]::Exists($parent)) { [void][IO.Directory]::CreateDirectory($parent) }
        $source = Resolve-ContainedPath -Root $sourceKitRoot -RelativePath ([string]$vendor.inputPath)
        [IO.File]::Copy($source, $target, $false)
    }

    Assert-PatchedWorkspace -Workspace $stagePath -Manifest $manifest -ProvidedVendorTargets $providedVendorTargets

    $newState = [ordered]@{
        schemaVersion = 1
        manifestSha256 = $manifestRecord.Sha256
        originalApkSha256 = [string]$manifest.originalApkSha256
        originalApkFileName = [string]$state.originalApkFileName
        packageName = [string]$manifest.packageName
        releaseVersion = [string]$manifest.releaseVersion
        workspaceRelativePath = [string]$manifest.workspaceRelativePath
        apktoolVersion = [string]$manifest.apktoolVersion
        preparedAtUtc = [string]$state.preparedAtUtc
        patchApplied = $true
        patchedAtUtc = [DateTime]::UtcNow.ToString('o')
        completeBuildInputs = ($missingRequired.Count -eq 0)
        missingVendorInputs = @($missingRequired | Sort-Object)
    }
    $stateTempPath = Join-Path $workRoot ('.state-' + [Guid]::NewGuid().ToString('N') + '.json')
    Write-JsonFile -LiteralPath $stateTempPath -Value $newState

    [IO.Directory]::Move($workspace, $backupPath)
    try {
        [IO.Directory]::Move($stagePath, $workspace)
    }
    catch {
        if (-not [IO.Directory]::Exists($workspace) -and [IO.Directory]::Exists($backupPath)) {
            [IO.Directory]::Move($backupPath, $workspace)
        }
        throw
    }

    Move-Item -LiteralPath $stateTempPath -Destination (Get-StatePath -SourceKitRoot $sourceKitRoot) -Force
    Assert-SafeGeneratedDirectory -Path $backupPath -AllowedRoot $workRoot
    Remove-Item -LiteralPath $backupPath -Recurse -Force

    if ($missingRequired.Count -gt 0) {
        Write-Warning "Applied a partial development patch. Required local vendor inputs are still missing; do not describe this workspace as a complete 2.0.0 reproduction."
    }
    Write-Output "Patched workspace verified: $workspace"
}
finally {
    foreach ($temporaryDirectory in @($stagePath, $backupPath)) {
        if ([IO.Directory]::Exists($temporaryDirectory)) {
            Assert-SafeGeneratedDirectory -Path $temporaryDirectory -AllowedRoot $workRoot
            Remove-Item -LiteralPath $temporaryDirectory -Recurse -Force
        }
    }
    if ($null -ne $stateTempPath -and [IO.File]::Exists($stateTempPath)) {
        Remove-Item -LiteralPath $stateTempPath -Force
    }
}
