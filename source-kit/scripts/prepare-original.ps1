<#
.SYNOPSIS
Verifies and decodes the exact supported European Mi Dash Cam APK.

.DESCRIPTION
Checks the stock APK against the pinned SHA-256 in the patch manifest and
checksums/original-apk.sha256, verifies Apktool 3.0.3, decodes into the ignored
source-kit/work directory, and validates every declared patch precondition.
No tool or proprietary input is downloaded.

.PARAMETER OriginalApk
Path to the contributor-supplied European Mi Dash Cam 1.1.0 (26) APK.

.PARAMETER ApktoolPath
Path to apktool.jar or an Apktool launcher. If omitted, APKTOOL_PATH and then
PATH are checked.

.PARAMETER JavaPath
Path or command name for Java when ApktoolPath is a JAR.

.PARAMETER Force
Replace an existing generated workspace, after checking that its resolved path
is an exact child of source-kit/work.

.EXAMPLE
.\scripts\prepare-original.ps1 -OriginalApk "C:\Downloads\mi-dash-cam.apk" -ApktoolPath "C:\Tools\apktool_3.0.3.jar"
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$OriginalApk,

    [string]$ManifestPath = 'patches\2.0.0\manifest.json',
    [string]$ApktoolPath,
    [string]$JavaPath = 'java',
    [switch]$Force
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'Common.ps1')

$sourceKitRoot = Get-SourceKitRoot
$manifestRecord = Read-PatchManifest -ManifestPath $ManifestPath -SourceKitRoot $sourceKitRoot
$manifest = $manifestRecord.Data
$originalPath = Get-FullPath -Path $OriginalApk

if (-not [IO.File]::Exists($originalPath)) {
    throw "Original APK not found: $originalPath"
}
if (-not [IO.Path]::GetExtension($originalPath).Equals('.apk', [StringComparison]::OrdinalIgnoreCase)) {
    throw "The original input must be an APK file: $originalPath"
}

$originalHash = Assert-FileHash -LiteralPath $originalPath -ExpectedSha256 ([string]$manifest.originalApkSha256) -Description 'Original European APK'
Write-Output "Original APK verified: SHA256=$originalHash"

$resolvedApktool = Resolve-ApktoolPath -RequestedPath $ApktoolPath
$resolvedJava = $null
if ([IO.Path]::GetExtension($resolvedApktool).Equals('.jar', [StringComparison]::OrdinalIgnoreCase)) {
    $resolvedJava = Resolve-ToolPath -RequestedPath $JavaPath -CommandName 'java' -ParameterHint '-JavaPath'
}
else {
    $resolvedJava = $JavaPath
}

$reportedVersion = Invoke-Apktool -ApktoolPath $resolvedApktool -JavaPath $resolvedJava -Arguments @('--version') -CaptureOutput
$versionMatch = [Text.RegularExpressions.Regex]::Match($reportedVersion, '(?<!\d)(\d+\.\d+\.\d+)(?!\d)')
if (-not $versionMatch.Success -or $versionMatch.Groups[1].Value -ne [string]$manifest.apktoolVersion) {
    throw "Apktool version mismatch. Manifest requires $($manifest.apktoolVersion); tool reported '$reportedVersion'."
}
Write-Output "Apktool verified: $($versionMatch.Groups[1].Value)"

$workRoot = Join-Path $sourceKitRoot 'work'
$workspace = Get-WorkspacePath -Manifest $manifest -SourceKitRoot $sourceKitRoot
Assert-SafeGeneratedDirectory -Path $workspace -AllowedRoot $workRoot

if ([IO.Directory]::Exists($workspace) -and -not $Force) {
    throw "Generated workspace already exists: $workspace. Use -Force to replace only that workspace."
}

[void][IO.Directory]::CreateDirectory($workRoot)
$stagePath = Join-Path $workRoot ('.prepare-' + [Guid]::NewGuid().ToString('N'))
Assert-SafeGeneratedDirectory -Path $stagePath -AllowedRoot $workRoot

try {
    Write-Output "Decoding the verified APK into a private generated workspace..."
    Invoke-Apktool -ApktoolPath $resolvedApktool -JavaPath $resolvedJava -Arguments @('d', '-f', '-o', $stagePath, $originalPath)

    $decodedManifestPath = Join-Path $stagePath 'AndroidManifest.xml'
    if (-not [IO.File]::Exists($decodedManifestPath)) {
        throw "Apktool did not produce AndroidManifest.xml in the decoded workspace."
    }
    try {
        [xml]$decodedManifest = [IO.File]::ReadAllText($decodedManifestPath)
        $decodedPackage = $decodedManifest.DocumentElement.GetAttribute('package')
    }
    catch {
        throw "Could not parse decoded AndroidManifest.xml. $($_.Exception.Message)"
    }
    if ($decodedPackage -ne [string]$manifest.packageName) {
        throw "Decoded package mismatch. Expected '$($manifest.packageName)'; found '$decodedPackage'."
    }

    foreach ($change in @($manifest.fileChanges)) {
        if ($null -eq $change) { continue }
        $target = Resolve-ContainedPath -Root $stagePath -RelativePath ([string]$change.path)
        if (-not [IO.File]::Exists($target)) {
            throw "Declared patch target is absent from the stock decode: $($change.path)"
        }
        [void](Assert-FileHash -LiteralPath $target -ExpectedSha256 ([string]$change.originalSha256) -Description "Stock patch target '$($change.path)'" -HashMode ([string]$change.hashMode))
    }
    foreach ($deleted in @($manifest.deletedFiles)) {
        if ($null -eq $deleted) { continue }
        $target = Resolve-ContainedPath -Root $stagePath -RelativePath ([string]$deleted.path)
        if (-not [IO.File]::Exists($target)) {
            throw "Declared deletion target is absent from the stock decode: $($deleted.path)"
        }
        $hashModeProperty = $deleted.PSObject.Properties['hashMode']
        $hashMode = if ($null -eq $hashModeProperty) { 'raw' } else { [string]$hashModeProperty.Value }
        [void](Assert-FileHash -LiteralPath $target -ExpectedSha256 ([string]$deleted.originalSha256) -Description "Stock deletion target '$($deleted.path)'" -HashMode $hashMode)
    }
    foreach ($added in @($manifest.addedFiles)) {
        if ($null -eq $added) { continue }
        $target = Resolve-ContainedPath -Root $stagePath -RelativePath ([string]$added.path)
        if ([IO.File]::Exists($target) -or [IO.Directory]::Exists($target)) {
            throw "Declared added path already exists in the stock decode: $($added.path)"
        }
    }
    foreach ($vendor in @($manifest.vendorInputs)) {
        if ($null -eq $vendor) { continue }
        $target = Resolve-ContainedPath -Root $stagePath -RelativePath ([string]$vendor.targetPath)
        if ([IO.File]::Exists($target) -or [IO.Directory]::Exists($target)) {
            throw "Declared vendor target already exists in the stock decode: $($vendor.targetPath)"
        }
    }

    if ([IO.Directory]::Exists($workspace)) {
        Assert-SafeGeneratedDirectory -Path $workspace -AllowedRoot $workRoot
        Remove-Item -LiteralPath $workspace -Recurse -Force
    }
    [IO.Directory]::Move($stagePath, $workspace)

    $state = [ordered]@{
        schemaVersion = 1
        manifestSha256 = $manifestRecord.Sha256
        originalApkSha256 = $originalHash
        originalApkFileName = [IO.Path]::GetFileName($originalPath)
        packageName = [string]$manifest.packageName
        releaseVersion = [string]$manifest.releaseVersion
        workspaceRelativePath = [string]$manifest.workspaceRelativePath
        apktoolVersion = [string]$manifest.apktoolVersion
        preparedAtUtc = [DateTime]::UtcNow.ToString('o')
        patchApplied = $false
        completeBuildInputs = $false
        missingVendorInputs = @()
    }
    Write-JsonFile -LiteralPath (Get-StatePath -SourceKitRoot $sourceKitRoot) -Value $state

    Write-Output "Prepared workspace: $workspace"
    Write-Output "Next: .\scripts\apply-patches.ps1"
}
finally {
    if ([IO.Directory]::Exists($stagePath)) {
        Assert-SafeGeneratedDirectory -Path $stagePath -AllowedRoot $workRoot
        Remove-Item -LiteralPath $stagePath -Recurse -Force
    }
}
