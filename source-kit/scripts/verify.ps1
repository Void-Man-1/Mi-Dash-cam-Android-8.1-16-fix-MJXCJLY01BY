<#
.SYNOPSIS
Performs static verification of a locally built Mi Dash Cam APK.

.DESCRIPTION
Checks package/version/SDK metadata, expected ABIs and checksum-pinned direct
vendor payloads, APK signing state, 16 KiB ZIP alignment, ARM64 ELF LOAD-segment
alignment, unsafe ZIP names, and private-key-like payload names. This does not
replace a physical MJXCJLY01BY camera test.

.PARAMETER ApkPath
Path to the APK to verify.

.PARAMETER AllowPartial
Allow expected vendor payloads and ABIs to be absent from a deliberately partial
development build. Any payload that is present must still match its checksum.

.PARAMETER RequireSignature
Fail when the APK is unsigned. By default a verified unsigned build is accepted
for inspection and clearly reported as unsigned.

.EXAMPLE
.\scripts\verify.ps1 -ApkPath .\build\Mi-Dash-Cam-EU-2.0.0-unsigned.apk
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$ApkPath,

    [string]$ManifestPath = 'patches\2.0.0\manifest.json',
    [string]$AndroidSdkRoot,
    [string]$BuildToolsVersion,
    [string]$AaptPath,
    [string]$ZipalignPath,
    [string]$ApksignerPath,
    [string]$ReportPath,
    [switch]$AllowPartial,
    [switch]$RequireSignature
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'Common.ps1')
Add-Type -AssemblyName System.IO.Compression.FileSystem

function Get-StreamSha256 {
    param([Parameter(Mandatory = $true)][IO.Stream]$Stream)
    $sha = [Security.Cryptography.SHA256]::Create()
    try { return ([BitConverter]::ToString($sha.ComputeHash($Stream))).Replace('-', '').ToUpperInvariant() }
    finally { $sha.Dispose() }
}

function Read-AllEntryBytes {
    param([Parameter(Mandatory = $true)][IO.Compression.ZipArchiveEntry]$Entry)
    $stream = $Entry.Open()
    $memory = New-Object IO.MemoryStream
    try {
        $stream.CopyTo($memory)
        return $memory.ToArray()
    }
    finally {
        $memory.Dispose()
        $stream.Dispose()
    }
}

function Get-UInt16LE([byte[]]$Bytes, [int]$Offset) {
    if (-not [BitConverter]::IsLittleEndian) {
        $copy = New-Object byte[] 2
        [Array]::Copy($Bytes, $Offset, $copy, 0, 2)
        [Array]::Reverse($copy)
        return [BitConverter]::ToUInt16($copy, 0)
    }
    return [BitConverter]::ToUInt16($Bytes, $Offset)
}

function Get-UInt32LE([byte[]]$Bytes, [int]$Offset) {
    if (-not [BitConverter]::IsLittleEndian) {
        $copy = New-Object byte[] 4
        [Array]::Copy($Bytes, $Offset, $copy, 0, 4)
        [Array]::Reverse($copy)
        return [BitConverter]::ToUInt32($copy, 0)
    }
    return [BitConverter]::ToUInt32($Bytes, $Offset)
}

function Get-UInt64LE([byte[]]$Bytes, [int]$Offset) {
    if (-not [BitConverter]::IsLittleEndian) {
        $copy = New-Object byte[] 8
        [Array]::Copy($Bytes, $Offset, $copy, 0, 8)
        [Array]::Reverse($copy)
        return [BitConverter]::ToUInt64($copy, 0)
    }
    return [BitConverter]::ToUInt64($Bytes, $Offset)
}

function Assert-Arm64ElfAlignment {
    param([Parameter(Mandatory = $true)][IO.Compression.ZipArchiveEntry]$Entry)
    $bytes = Read-AllEntryBytes -Entry $Entry
    if ($bytes.Length -lt 64 -or $bytes[0] -ne 0x7F -or $bytes[1] -ne 0x45 -or $bytes[2] -ne 0x4C -or $bytes[3] -ne 0x46) {
        throw "ARM64 library is not a valid ELF file: $($Entry.FullName)"
    }
    if ($bytes[4] -ne 2 -or $bytes[5] -ne 1) {
        throw "ARM64 library is not a little-endian ELF64 file: $($Entry.FullName)"
    }

    $programOffset = Get-UInt64LE $bytes 32
    $entrySize = Get-UInt16LE $bytes 54
    $entryCount = Get-UInt16LE $bytes 56
    if ($entrySize -lt 56 -or $entryCount -eq 0) { throw "Invalid ELF program-header table: $($Entry.FullName)" }
    for ($index = 0; $index -lt $entryCount; $index++) {
        $offset64 = $programOffset + ([uint64]$index * $entrySize)
        if ($offset64 -gt [int]::MaxValue -or ([int]$offset64 + 56) -gt $bytes.Length) {
            throw "ELF program-header table extends past the file: $($Entry.FullName)"
        }
        $offset = [int]$offset64
        if ((Get-UInt32LE $bytes $offset) -eq 1) {
            $alignment = Get-UInt64LE $bytes ($offset + 48)
            if ($alignment -lt 16384) {
                throw "ARM64 ELF LOAD segment is aligned to $alignment bytes, below 16384: $($Entry.FullName)"
            }
        }
    }
}

function Invoke-CapturedTool {
    param([string]$Tool, [string[]]$Arguments, [switch]$AllowFailure)
    # Windows PowerShell 5.1 promotes a native program's stderr to a
    # terminating NativeCommandError while the script-wide preference is Stop.
    # Some probes intentionally expect a nonzero result (for example, checking
    # whether an APK is unsigned), so capture that output under Continue and
    # decide from the native exit code ourselves.
    $previousPreference = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        $output = & $Tool @Arguments 2>&1
        $exitCode = $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $previousPreference
    }
    $text = ($output | ForEach-Object { $_.ToString() }) -join [Environment]::NewLine
    if ($exitCode -ne 0 -and -not $AllowFailure) { throw "Tool '$Tool' failed with exit code $exitCode.`n$text" }
    return [PSCustomObject]@{ ExitCode = $exitCode; Text = $text }
}

$sourceKitRoot = Get-SourceKitRoot
$manifestRecord = Read-PatchManifest -ManifestPath $ManifestPath -SourceKitRoot $sourceKitRoot
$manifest = $manifestRecord.Data
$resolvedApk = Get-FullPath -Path $ApkPath
if (-not [IO.File]::Exists($resolvedApk)) { throw "APK not found: $resolvedApk" }

$resolvedAapt = Resolve-AndroidBuildTool -ToolName 'aapt' -RequestedPath $AaptPath -AndroidSdkRoot $AndroidSdkRoot -BuildToolsVersion $BuildToolsVersion
$resolvedZipalign = Resolve-AndroidBuildTool -ToolName 'zipalign' -RequestedPath $ZipalignPath -AndroidSdkRoot $AndroidSdkRoot -BuildToolsVersion $BuildToolsVersion
$resolvedApksigner = Resolve-AndroidBuildTool -ToolName 'apksigner' -RequestedPath $ApksignerPath -AndroidSdkRoot $AndroidSdkRoot -BuildToolsVersion $BuildToolsVersion

$badging = Invoke-CapturedTool -Tool $resolvedAapt -Arguments @('dump', 'badging', $resolvedApk)
$packageMatch = [Text.RegularExpressions.Regex]::Match($badging.Text, "(?m)^package: name='([^']+)' versionCode='([^']+)' versionName='([^']+)'(?=\s|$)")
if (-not $packageMatch.Success) { throw 'aapt did not report parseable package metadata.' }
if ($packageMatch.Groups[1].Value -ne [string]$manifest.packageName) { throw "Package mismatch: $($packageMatch.Groups[1].Value)" }
if ($packageMatch.Groups[2].Value -ne [string]$manifest.expected.versionCode) { throw "versionCode mismatch: $($packageMatch.Groups[2].Value)" }
if ($packageMatch.Groups[3].Value -ne [string]$manifest.expected.versionName) { throw "versionName mismatch: $($packageMatch.Groups[3].Value)" }

$minMatch = [Text.RegularExpressions.Regex]::Match($badging.Text, "(?m)^sdkVersion:'([^']+)'\r?$")
$targetMatch = [Text.RegularExpressions.Regex]::Match($badging.Text, "(?m)^targetSdkVersion:'([^']+)'\r?$")
if (-not $minMatch.Success -or $minMatch.Groups[1].Value -ne [string]$manifest.expected.minSdkVersion) { throw 'Minimum SDK does not match the manifest.' }
if (-not $targetMatch.Success -or $targetMatch.Groups[1].Value -ne [string]$manifest.expected.targetSdkVersion) { throw 'Target SDK does not match the manifest.' }

$alignment = Invoke-CapturedTool -Tool $resolvedZipalign -Arguments @('-P', '16', '-c', '4', $resolvedApk)
$signature = Invoke-CapturedTool -Tool $resolvedApksigner -Arguments @('verify', '--verbose', '--print-certs', $resolvedApk) -AllowFailure
$signed = $signature.ExitCode -eq 0
if (-not $signed -and $RequireSignature) { throw "APK signature verification failed.`n$($signature.Text)" }

$archive = [IO.Compression.ZipFile]::OpenRead($resolvedApk)
$abiSet = New-Object 'Collections.Generic.HashSet[string]' ([StringComparer]::Ordinal)
$entryMap = @{}
try {
    $nameSet = New-Object 'Collections.Generic.HashSet[string]' ([StringComparer]::Ordinal)
    foreach ($entry in $archive.Entries) {
        $name = $entry.FullName.Replace('\', '/')
        if ($name.StartsWith('/') -or $name -match '(^|/)\.\.(/|$)' -or [IO.Path]::IsPathRooted($name)) { throw "Unsafe ZIP entry name: $name" }
        if (-not $nameSet.Add($name)) { throw "Duplicate ZIP entry name: $name" }
        $entryMap[$name] = $entry
        if ($name -match '^lib/([^/]+)/[^/]+\.so$') { [void]$abiSet.Add($Matches[1]) }
        if ($name -match '(?i)\.(p12|pfx|p8|pk8|pkcs8|jks|keystore|pem|key)$') { throw "Private-key-like file must not be packaged: $name" }
    }

    foreach ($expectedAbi in @($manifest.expected.abis)) {
        if (-not $abiSet.Contains([string]$expectedAbi) -and -not $AllowPartial) { throw "Expected ABI is absent: $expectedAbi" }
    }

    $missingVendor = New-Object Collections.Generic.List[string]
    foreach ($vendor in @($manifest.vendorInputs)) {
        if ($null -eq $vendor) { continue }
        $target = ([string]$vendor.targetPath).Replace('\', '/')
        if (-not $entryMap.ContainsKey($target)) {
            if ([bool]$vendor.requiredForCompleteBuild) { [void]$missingVendor.Add($target) }
            continue
        }
        $stream = $entryMap[$target].Open()
        try { $actual = Get-StreamSha256 -Stream $stream } finally { $stream.Dispose() }
        if (-not $actual.Equals([string]$vendor.sha256, [StringComparison]::OrdinalIgnoreCase)) { throw "Packaged vendor input checksum mismatch: $target" }
    }
    if ($missingVendor.Count -gt 0 -and -not $AllowPartial) { throw "Required packaged vendor inputs are absent:`n$(($missingVendor | Sort-Object) -join [Environment]::NewLine)" }

    foreach ($entry in $archive.Entries) {
        if ($entry.FullName.Replace('\', '/') -match '^lib/arm64-v8a/[^/]+\.so$') {
            Assert-Arm64ElfAlignment -Entry $entry
        }
    }

    if (-not $signed) {
        $hasSignatureArtifacts = @($archive.Entries | Where-Object { $_.FullName -match '(?i)^META-INF/[^/]+\.(RSA|DSA|EC|SF)$' }).Count -gt 0
        if ($hasSignatureArtifacts) { throw "APK signature verification failed even though signature artifacts are present.`n$($signature.Text)" }
    }
}
finally {
    $archive.Dispose()
}

$report = [ordered]@{
    schemaVersion = 1
    verifiedAtUtc = [DateTime]::UtcNow.ToString('o')
    apkFileName = [IO.Path]::GetFileName($resolvedApk)
    apkSha256 = Get-Sha256Hex -LiteralPath $resolvedApk
    packageName = $packageMatch.Groups[1].Value
    versionCode = $packageMatch.Groups[2].Value
    versionName = $packageMatch.Groups[3].Value
    minSdkVersion = $minMatch.Groups[1].Value
    targetSdkVersion = $targetMatch.Groups[1].Value
    abis = @($abiSet | Sort-Object)
    signed = $signed
    zipAlignedFor16KiB = $true
    allowPartial = [bool]$AllowPartial
    physicalCameraTest = 'not-performed-by-this-script'
}

if ([string]::IsNullOrWhiteSpace($ReportPath)) {
    $reportDirectory = Join-Path $sourceKitRoot 'build'
    [void][IO.Directory]::CreateDirectory($reportDirectory)
    $ReportPath = Join-Path $reportDirectory (([IO.Path]::GetFileNameWithoutExtension($resolvedApk)) + '-verification.json')
}
else {
    $ReportPath = Get-FullPath -Path $ReportPath
}
Write-JsonFile -LiteralPath $ReportPath -Value $report

Write-Output "VERIFIED=$resolvedApk"
Write-Output "SHA256=$($report.apkSha256)"
Write-Output "SIGNED=$signed"
Write-Output "REPORT=$ReportPath"
if (-not $signed) { Write-Warning 'The APK is unsigned. Static structure passed, but it cannot normally be installed.' }
Write-Warning 'Static verification does not prove camera connection, preview, download, replay, or reconnect behavior.'
