<#
.SYNOPSIS
Builds an unsigned or contributor-signed APK from the verified patch workspace.

.DESCRIPTION
Rechecks the patch manifest and workspace state, builds with the contributor's
Apktool, and applies 16 KiB-aware ZIP alignment. Signing is optional. Passwords
are read as SecureString values, passed to apksigner through uniquely named
process-scoped environment variables, and removed in a finally block.

.PARAMETER KeystorePath
Optional path to a contributor-owned keystore outside this Git repository.

.PARAMETER KeyAlias
Alias in the contributor-owned keystore. Required with KeystorePath.

.PARAMETER AllowPartial
Build a workspace intentionally prepared with missing required vendor inputs.
The output is labelled as a partial development build.

.EXAMPLE
.\scripts\build.ps1 -ApktoolPath "C:\Tools\apktool_3.0.3.jar"

.EXAMPLE
.\scripts\build.ps1 -ApktoolPath "C:\Tools\apktool_3.0.3.jar" -KeystorePath "C:\Secure\my-key.p12" -KeyAlias "my-key"
#>
[CmdletBinding()]
param(
    [string]$ManifestPath = 'patches\2.0.0\manifest.json',
    [string]$ApktoolPath,
    [string]$JavaPath = 'java',
    [string]$AndroidSdkRoot,
    [string]$BuildToolsVersion,
    [string]$ZipalignPath,
    [string]$ApksignerPath,
    [string]$KeystorePath,
    [string]$KeyAlias,
    [ValidateSet('PKCS12', 'JKS')]
    [string]$KeystoreType,
    [Security.SecureString]$KeystorePassword,
    [Security.SecureString]$KeyPassword,
    [switch]$AllowPartial
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'Common.ps1')

function Get-EntryHashMode {
    param([Parameter(Mandatory = $true)][object]$Entry)
    $property = $Entry.PSObject.Properties['hashMode']
    if ($null -eq $property) { return 'raw' }
    return [string]$property.Value
}

$sourceKitRoot = Get-SourceKitRoot
$repositoryRoot = Split-Path -Parent $sourceKitRoot
$manifestRecord = Read-PatchManifest -ManifestPath $ManifestPath -SourceKitRoot $sourceKitRoot
$manifest = $manifestRecord.Data
$workspace = Get-WorkspacePath -Manifest $manifest -SourceKitRoot $sourceKitRoot
$workRoot = Join-Path $sourceKitRoot 'work'
Assert-SafeGeneratedDirectory -Path $workspace -AllowedRoot $workRoot
if (-not [IO.Directory]::Exists($workspace)) {
    throw "Prepared workspace not found. Run prepare-original.ps1 and apply-patches.ps1 first."
}

$state = Read-SourceKitState -SourceKitRoot $sourceKitRoot
if (-not [bool]$state.patchApplied) {
    throw "The prepared workspace has not been patched. Run scripts\apply-patches.ps1 first."
}
if (-not ([string]$state.manifestSha256).Equals($manifestRecord.Sha256, [StringComparison]::OrdinalIgnoreCase)) {
    throw "Workspace state belongs to a different manifest. Re-run prepare-original.ps1 -Force."
}
if (-not [bool]$state.completeBuildInputs -and -not $AllowPartial) {
    $missing = @($state.missingVendorInputs) -join [Environment]::NewLine
    throw "This is a partial workspace with required vendor inputs missing. Supply them and re-run apply-patches.ps1, or explicitly use -AllowPartial for a development build:`n$missing"
}

foreach ($change in @($manifest.fileChanges)) {
    if ($null -eq $change) { continue }
    $target = Resolve-ContainedPath -Root $workspace -RelativePath ([string]$change.path)
    [void](Assert-FileHash -LiteralPath $target -ExpectedSha256 ([string]$change.patchedSha256) -Description "Patched target '$($change.path)'" -HashMode (Get-EntryHashMode -Entry $change))
}
foreach ($added in @($manifest.addedFiles)) {
    if ($null -eq $added) { continue }
    $target = Resolve-ContainedPath -Root $workspace -RelativePath ([string]$added.path)
    [void](Assert-FileHash -LiteralPath $target -ExpectedSha256 ([string]$added.patchedSha256) -Description "Added target '$($added.path)'" -HashMode (Get-EntryHashMode -Entry $added))
}
foreach ($deleted in @($manifest.deletedFiles)) {
    if ($null -eq $deleted) { continue }
    $target = Resolve-ContainedPath -Root $workspace -RelativePath ([string]$deleted.path)
    if ([IO.File]::Exists($target) -or [IO.Directory]::Exists($target)) {
        throw "Deletion postcondition failed: $($deleted.path)"
    }
}

$missingTargets = New-Object Collections.Generic.List[string]
foreach ($vendor in @($manifest.vendorInputs)) {
    if ($null -eq $vendor) { continue }
    $target = Resolve-ContainedPath -Root $workspace -RelativePath ([string]$vendor.targetPath)
    if (-not [IO.File]::Exists($target)) {
        if ([bool]$vendor.requiredForCompleteBuild) { [void]$missingTargets.Add([string]$vendor.targetPath) }
        continue
    }
    [void](Assert-FileHash -LiteralPath $target -ExpectedSha256 ([string]$vendor.sha256) -Description "Vendor target '$($vendor.targetPath)'")
}
if ($missingTargets.Count -gt 0 -and -not $AllowPartial) {
    throw "Required vendor targets are missing from the workspace:`n$(($missingTargets | Sort-Object) -join [Environment]::NewLine)"
}

$resolvedApktool = Resolve-ApktoolPath -RequestedPath $ApktoolPath
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

$resolvedZipalign = Resolve-AndroidBuildTool -ToolName 'zipalign' -RequestedPath $ZipalignPath -AndroidSdkRoot $AndroidSdkRoot -BuildToolsVersion $BuildToolsVersion
$willSign = -not [string]::IsNullOrWhiteSpace($KeystorePath)
if ($willSign) {
    if ([string]::IsNullOrWhiteSpace($KeyAlias)) {
        throw "KeyAlias is required when KeystorePath is supplied."
    }
    $resolvedKeystore = Get-FullPath -Path $KeystorePath
    if (-not [IO.File]::Exists($resolvedKeystore)) { throw "Keystore not found: $resolvedKeystore" }
    $repositoryPrefix = [IO.Path]::GetFullPath($repositoryRoot).TrimEnd('\', '/') + [IO.Path]::DirectorySeparatorChar
    if ($resolvedKeystore.StartsWith($repositoryPrefix, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Refusing to use a private signing key stored inside the Git repository. Move it to a secure external directory."
    }
    if ([string]::IsNullOrWhiteSpace($KeystoreType)) {
        if ([IO.Path]::GetExtension($resolvedKeystore) -in @('.p12', '.pfx')) { $KeystoreType = 'PKCS12' } else { $KeystoreType = 'JKS' }
    }
    $resolvedApksigner = Resolve-AndroidBuildTool -ToolName 'apksigner' -RequestedPath $ApksignerPath -AndroidSdkRoot $AndroidSdkRoot -BuildToolsVersion $BuildToolsVersion
}

$buildRoot = Join-Path $sourceKitRoot 'build'
[void][IO.Directory]::CreateDirectory($buildRoot)
$stagePath = Join-Path $buildRoot ('.build-' + [Guid]::NewGuid().ToString('N'))
Assert-SafeGeneratedDirectory -Path $stagePath -AllowedRoot $buildRoot
[void][IO.Directory]::CreateDirectory($stagePath)

$releaseName = "Mi-Dash-Cam-EU-$($manifest.releaseVersion)"
if (-not [bool]$state.completeBuildInputs -or $missingTargets.Count -gt 0) {
    $releaseName += '-partial-development'
}
$finalName = if ($willSign) { "$releaseName-local-signed.apk" } else { "$releaseName-unsigned.apk" }
$finalPath = Join-Path $buildRoot $finalName
$rawApk = Join-Path $stagePath 'apktool-raw.apk'
$alignedApk = Join-Path $stagePath 'aligned-unsigned.apk'
$signedApk = Join-Path $stagePath 'signed.apk'

try {
    Invoke-Apktool -ApktoolPath $resolvedApktool -JavaPath $resolvedJava -Arguments @('b', '-f', $workspace, '-o', $rawApk)
    & $resolvedZipalign -P 16 -f 4 $rawApk $alignedApk
    if ($LASTEXITCODE -ne 0) { throw "zipalign failed with exit code $LASTEXITCODE." }
    & $resolvedZipalign -P 16 -c 4 $alignedApk
    if ($LASTEXITCODE -ne 0) { throw "16 KiB-aware ZIP alignment verification failed with exit code $LASTEXITCODE." }

    if ($willSign) {
        if ($null -eq $KeystorePassword) {
            $KeystorePassword = Read-Host 'Keystore password' -AsSecureString
        }
        if ($null -eq $KeyPassword) {
            $KeyPassword = $KeystorePassword
        }

        $storePlain = ConvertTo-PlainText -Value $KeystorePassword
        $keyPlain = ConvertTo-PlainText -Value $KeyPassword
        $passwordScope = [Guid]::NewGuid().ToString('N')
        $storeVariable = "MIDASHCAM_STORE_PASSWORD_$passwordScope"
        $keyVariable = "MIDASHCAM_KEY_PASSWORD_$passwordScope"
        try {
            if ($storePlain.Length -ne $storePlain.TrimEnd().Length -or $keyPlain.Length -ne $keyPlain.TrimEnd().Length) {
                Write-Warning 'A signing password ends with whitespace. Continue only if that whitespace is intentional.'
            }
            [Environment]::SetEnvironmentVariable($storeVariable, $storePlain, 'Process')
            [Environment]::SetEnvironmentVariable($keyVariable, $keyPlain, 'Process')
            & $resolvedApksigner sign `
                --ks $resolvedKeystore `
                --ks-type $KeystoreType `
                --ks-key-alias $KeyAlias `
                --ks-pass "env:$storeVariable" `
                --key-pass "env:$keyVariable" `
                --out $signedApk `
                $alignedApk
            if ($LASTEXITCODE -ne 0) { throw "APK signing failed with exit code $LASTEXITCODE." }
        }
        finally {
            if ($null -ne $storeVariable) { [Environment]::SetEnvironmentVariable($storeVariable, $null, 'Process') }
            if ($null -ne $keyVariable) { [Environment]::SetEnvironmentVariable($keyVariable, $null, 'Process') }
            $storePlain = $null
            $keyPlain = $null
        }

        & $resolvedApksigner verify --verbose --print-certs $signedApk
        if ($LASTEXITCODE -ne 0) { throw "Signed APK verification failed with exit code $LASTEXITCODE." }
        Move-Item -LiteralPath $signedApk -Destination $finalPath -Force
    }
    else {
        Move-Item -LiteralPath $alignedApk -Destination $finalPath -Force
    }

    $finalHash = Get-Sha256Hex -LiteralPath $finalPath
    Write-Output "APK=$finalPath"
    Write-Output "SHA256=$finalHash"
    if (-not $willSign) {
        Write-Warning 'The APK is unsigned and cannot normally be installed. Sign it only with a key you own.'
    }
}
finally {
    if ([IO.Directory]::Exists($stagePath)) {
        Assert-SafeGeneratedDirectory -Path $stagePath -AllowedRoot $buildRoot
        Remove-Item -LiteralPath $stagePath -Recurse -Force
    }
}
