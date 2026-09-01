Set-StrictMode -Version 2.0

function Get-SourceKitRoot {
    return [IO.Path]::GetFullPath((Split-Path -Parent $PSScriptRoot))
}

function Get-FullPath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [string]$BasePath = (Get-Location).Path
    )

    if ([IO.Path]::IsPathRooted($Path)) {
        return [IO.Path]::GetFullPath($Path)
    }

    return [IO.Path]::GetFullPath((Join-Path $BasePath $Path))
}

function Resolve-ContainedPath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Root,

        [Parameter(Mandatory = $true)]
        [string]$RelativePath,

        [switch]$AllowRoot
    )

    if ([string]::IsNullOrWhiteSpace($RelativePath)) {
        throw "A relative path cannot be empty."
    }
    if ([IO.Path]::IsPathRooted($RelativePath)) {
        throw "An absolute path is not permitted in patch metadata: $RelativePath"
    }

    $segments = $RelativePath -split '[\\/]'
    foreach ($segment in $segments) {
        if ([string]::IsNullOrWhiteSpace($segment) -or $segment -eq '.' -or $segment -eq '..' -or $segment.Contains(':')) {
            throw "Unsafe relative path in patch metadata: $RelativePath"
        }
    }

    $rootFull = [IO.Path]::GetFullPath($Root).TrimEnd([IO.Path]::DirectorySeparatorChar, [IO.Path]::AltDirectorySeparatorChar)
    $normalizedRelative = $RelativePath.Replace([IO.Path]::AltDirectorySeparatorChar, [IO.Path]::DirectorySeparatorChar)
    $candidate = [IO.Path]::GetFullPath((Join-Path $rootFull $normalizedRelative))
    $comparison = [StringComparison]::OrdinalIgnoreCase

    if ($candidate.Equals($rootFull, $comparison)) {
        if ($AllowRoot) {
            return $candidate
        }
        throw "The path must identify a child of '$rootFull', not the directory itself."
    }

    $rootPrefix = $rootFull + [IO.Path]::DirectorySeparatorChar
    if (-not $candidate.StartsWith($rootPrefix, $comparison)) {
        throw "Path escapes its permitted root: $RelativePath"
    }

    return $candidate
}

function Assert-SafeGeneratedDirectory {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [string]$AllowedRoot
    )

    $allowedFull = [IO.Path]::GetFullPath($AllowedRoot).TrimEnd([IO.Path]::DirectorySeparatorChar, [IO.Path]::AltDirectorySeparatorChar)
    $pathFull = [IO.Path]::GetFullPath($Path).TrimEnd([IO.Path]::DirectorySeparatorChar, [IO.Path]::AltDirectorySeparatorChar)
    $prefix = $allowedFull + [IO.Path]::DirectorySeparatorChar

    if ($pathFull.Equals($allowedFull, [StringComparison]::OrdinalIgnoreCase) -or
        -not $pathFull.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Refusing a recursive operation outside the generated-data root '$allowedFull': $pathFull"
    }
}

function Get-Sha256Hex {
    param(
        [Parameter(Mandatory = $true)]
        [string]$LiteralPath
    )

    $resolved = Get-FullPath -Path $LiteralPath
    if (-not [IO.File]::Exists($resolved)) {
        throw "File not found: $resolved"
    }

    $stream = [IO.File]::Open($resolved, [IO.FileMode]::Open, [IO.FileAccess]::Read, [IO.FileShare]::Read)
    $sha256 = [Security.Cryptography.SHA256]::Create()
    try {
        return ([BitConverter]::ToString($sha256.ComputeHash($stream))).Replace('-', '').ToUpperInvariant()
    }
    finally {
        $sha256.Dispose()
        $stream.Dispose()
    }
}

function Get-NormalizedUtf8Text {
    param(
        [Parameter(Mandatory = $true)]
        [string]$LiteralPath
    )

    $resolved = Get-FullPath -Path $LiteralPath
    if (-not [IO.File]::Exists($resolved)) {
        throw "File not found: $resolved"
    }

    $utf8Strict = New-Object Text.UTF8Encoding($false, $true)
    try {
        $text = $utf8Strict.GetString([IO.File]::ReadAllBytes($resolved))
    }
    catch {
        throw "Expected UTF-8 text but decoding failed: $resolved. $($_.Exception.Message)"
    }
    if ($text.Length -gt 0 -and $text[0] -eq [char]0xFEFF) {
        $text = $text.Substring(1)
    }
    return ($text -replace "`r`n", "`n" -replace "`r", "`n")
}

function Set-NormalizedUtf8Text {
    param(
        [Parameter(Mandatory = $true)]
        [string]$LiteralPath,

        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]$Text
    )

    $normalized = $Text -replace "`r`n", "`n" -replace "`r", "`n"
    [IO.File]::WriteAllText($LiteralPath, $normalized, (New-Object Text.UTF8Encoding($false)))
}

function Get-ContentSha256Hex {
    param(
        [Parameter(Mandatory = $true)]
        [string]$LiteralPath,

        [string]$HashMode = 'raw'
    )

    switch ($HashMode.ToLowerInvariant()) {
        'raw' {
            return Get-Sha256Hex -LiteralPath $LiteralPath
        }
        'text-utf8-lf' {
            $text = Get-NormalizedUtf8Text -LiteralPath $LiteralPath
            $bytes = (New-Object Text.UTF8Encoding($false)).GetBytes($text)
            $sha256 = [Security.Cryptography.SHA256]::Create()
            try {
                return ([BitConverter]::ToString($sha256.ComputeHash($bytes))).Replace('-', '').ToUpperInvariant()
            }
            finally {
                $sha256.Dispose()
            }
        }
        default {
            throw "Unsupported hashMode '$HashMode'. Supported values are 'raw' and 'text-utf8-lf'."
        }
    }
}

function Assert-Sha256Value {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Value,

        [Parameter(Mandatory = $true)]
        [string]$Description
    )

    if ($Value -notmatch '^[0-9A-Fa-f]{64}$') {
        throw "$Description is not a SHA-256 value: '$Value'"
    }
}

function Assert-FileHash {
    param(
        [Parameter(Mandatory = $true)]
        [string]$LiteralPath,

        [Parameter(Mandatory = $true)]
        [string]$ExpectedSha256,

        [Parameter(Mandatory = $true)]
        [string]$Description,

        [string]$HashMode = 'raw'
    )

    Assert-Sha256Value -Value $ExpectedSha256 -Description "$Description expected hash"
    $actual = Get-ContentSha256Hex -LiteralPath $LiteralPath -HashMode $HashMode
    if (-not $actual.Equals($ExpectedSha256, [StringComparison]::OrdinalIgnoreCase)) {
        throw "$Description checksum mismatch. Expected $($ExpectedSha256.ToUpperInvariant()); found $actual."
    }
    return $actual
}

function Get-RequiredProperty {
    param(
        [Parameter(Mandatory = $true)]
        [object]$Object,

        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [string]$Context
    )

    $property = $Object.PSObject.Properties[$Name]
    if ($null -eq $property -or $null -eq $property.Value) {
        throw "$Context is missing required property '$Name'."
    }
    return $property.Value
}

function Read-PatchManifest {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ManifestPath,

        [Parameter(Mandatory = $true)]
        [string]$SourceKitRoot
    )

    $resolvedManifest = Get-FullPath -Path $ManifestPath -BasePath $SourceKitRoot
    if (-not [IO.File]::Exists($resolvedManifest)) {
        throw "Patch manifest not found: $resolvedManifest"
    }

    try {
        $manifest = [IO.File]::ReadAllText($resolvedManifest) | ConvertFrom-Json
    }
    catch {
        throw "Patch manifest is not valid JSON: $resolvedManifest. $($_.Exception.Message)"
    }

    $schemaVersion = Get-RequiredProperty -Object $manifest -Name 'schemaVersion' -Context 'Patch manifest'
    if ([int]$schemaVersion -ne 1) {
        throw "Unsupported patch-manifest schemaVersion '$schemaVersion'; expected 1."
    }

    foreach ($propertyName in @(
        'releaseVersion', 'packageName', 'originalApkSha256', 'apktoolVersion',
        'workspaceRelativePath', 'textPatch', 'deleteList', 'fileChanges',
        'addedFiles', 'deletedFiles', 'vendorInputs', 'expected'
    )) {
        [void](Get-RequiredProperty -Object $manifest -Name $propertyName -Context 'Patch manifest')
    }

    Assert-Sha256Value -Value ([string]$manifest.originalApkSha256) -Description 'originalApkSha256'
    if ([string]::IsNullOrWhiteSpace([string]$manifest.packageName)) {
        throw "Patch manifest packageName cannot be empty."
    }
    if ([string]::IsNullOrWhiteSpace([string]$manifest.releaseVersion)) {
        throw "Patch manifest releaseVersion cannot be empty."
    }

    $expected = $manifest.expected
    foreach ($propertyName in @('versionCode', 'versionName', 'minSdkVersion', 'targetSdkVersion', 'abis')) {
        [void](Get-RequiredProperty -Object $expected -Name $propertyName -Context 'Patch manifest expected block')
    }

    $workRoot = Join-Path $SourceKitRoot 'work'
    [void](Resolve-ContainedPath -Root $workRoot -RelativePath (([string]$manifest.workspaceRelativePath) -replace '^work[\\/]', ''))

    $seenTargets = New-Object 'Collections.Generic.HashSet[string]' ([StringComparer]::OrdinalIgnoreCase)
    foreach ($item in @($manifest.fileChanges)) {
        if ($null -eq $item) { continue }
        $path = [string](Get-RequiredProperty -Object $item -Name 'path' -Context 'fileChanges entry')
        [void](Resolve-ContainedPath -Root $workRoot -RelativePath $path)
        $hashMode = [string](Get-RequiredProperty -Object $item -Name 'hashMode' -Context "fileChanges '$path'")
        if ($hashMode -notin @('raw', 'text-utf8-lf')) { throw "Unsupported hashMode '$hashMode' for fileChanges '$path'." }
        Assert-Sha256Value -Value ([string](Get-RequiredProperty -Object $item -Name 'originalSha256' -Context "fileChanges '$path'")) -Description "fileChanges '$path' originalSha256"
        Assert-Sha256Value -Value ([string](Get-RequiredProperty -Object $item -Name 'patchedSha256' -Context "fileChanges '$path'")) -Description "fileChanges '$path' patchedSha256"
        if (-not $seenTargets.Add($path)) { throw "Duplicate patch target path: $path" }
    }
    foreach ($item in @($manifest.addedFiles)) {
        if ($null -eq $item) { continue }
        $path = [string](Get-RequiredProperty -Object $item -Name 'path' -Context 'addedFiles entry')
        [void](Resolve-ContainedPath -Root $workRoot -RelativePath $path)
        $hashMode = [string](Get-RequiredProperty -Object $item -Name 'hashMode' -Context "addedFiles '$path'")
        if ($hashMode -notin @('raw', 'text-utf8-lf')) { throw "Unsupported hashMode '$hashMode' for addedFiles '$path'." }
        Assert-Sha256Value -Value ([string](Get-RequiredProperty -Object $item -Name 'patchedSha256' -Context "addedFiles '$path'")) -Description "addedFiles '$path' patchedSha256"
        if (-not $seenTargets.Add($path)) { throw "Duplicate patch target path: $path" }
    }
    foreach ($item in @($manifest.deletedFiles)) {
        if ($null -eq $item) { continue }
        $path = [string](Get-RequiredProperty -Object $item -Name 'path' -Context 'deletedFiles entry')
        [void](Resolve-ContainedPath -Root $workRoot -RelativePath $path)
        $hashModeProperty = $item.PSObject.Properties['hashMode']
        $hashMode = if ($null -eq $hashModeProperty) { 'raw' } else { [string]$hashModeProperty.Value }
        if ($hashMode -notin @('raw', 'text-utf8-lf')) { throw "Unsupported hashMode '$hashMode' for deletedFiles '$path'." }
        Assert-Sha256Value -Value ([string](Get-RequiredProperty -Object $item -Name 'originalSha256' -Context "deletedFiles '$path'")) -Description "deletedFiles '$path' originalSha256"
        if (-not $seenTargets.Add($path)) { throw "Duplicate patch target path: $path" }
    }
    foreach ($item in @($manifest.vendorInputs)) {
        if ($null -eq $item) { continue }
        $inputPath = [string](Get-RequiredProperty -Object $item -Name 'inputPath' -Context 'vendorInputs entry')
        $targetPath = [string](Get-RequiredProperty -Object $item -Name 'targetPath' -Context "vendorInputs '$inputPath'")
        [void](Resolve-ContainedPath -Root $SourceKitRoot -RelativePath $inputPath)
        [void](Resolve-ContainedPath -Root $workRoot -RelativePath $targetPath)
        Assert-Sha256Value -Value ([string](Get-RequiredProperty -Object $item -Name 'sha256' -Context "vendorInputs '$inputPath'")) -Description "vendorInputs '$inputPath' sha256"
        [void](Get-RequiredProperty -Object $item -Name 'category' -Context "vendorInputs '$inputPath'")
        [void](Get-RequiredProperty -Object $item -Name 'requiredForCompleteBuild' -Context "vendorInputs '$inputPath'")
        if (-not $seenTargets.Add($targetPath)) { throw "Duplicate patch target path: $targetPath" }
    }

    $checksumFile = Join-Path $SourceKitRoot 'checksums\original-apk.sha256'
    if (-not [IO.File]::Exists($checksumFile)) {
        throw "Required checksum file not found: $checksumFile"
    }
    $checksumText = [IO.File]::ReadAllText($checksumFile)
    $checksumMatch = [Text.RegularExpressions.Regex]::Match($checksumText, '(?im)^\s*([0-9a-f]{64})(?:\s+|$)')
    if (-not $checksumMatch.Success) {
        throw "Could not read a SHA-256 value from $checksumFile"
    }
    if (-not $checksumMatch.Groups[1].Value.Equals([string]$manifest.originalApkSha256, [StringComparison]::OrdinalIgnoreCase)) {
        throw "The manifest originalApkSha256 does not match checksums/original-apk.sha256."
    }

    return [PSCustomObject]@{
        Data = $manifest
        Path = $resolvedManifest
        Directory = Split-Path -Parent $resolvedManifest
        Sha256 = Get-Sha256Hex -LiteralPath $resolvedManifest
    }
}

function Get-WorkspacePath {
    param(
        [Parameter(Mandatory = $true)]
        [object]$Manifest,

        [Parameter(Mandatory = $true)]
        [string]$SourceKitRoot
    )

    $relative = [string]$Manifest.workspaceRelativePath
    if ($relative -notmatch '^(?i)work[\\/](.+)$') {
        throw "workspaceRelativePath must be a child of source-kit/work: $relative"
    }
    return Resolve-ContainedPath -Root (Join-Path $SourceKitRoot 'work') -RelativePath $Matches[1]
}

function Get-StatePath {
    param([Parameter(Mandatory = $true)][string]$SourceKitRoot)
    return Join-Path $SourceKitRoot 'work\source-kit-state.json'
}

function Read-SourceKitState {
    param([Parameter(Mandatory = $true)][string]$SourceKitRoot)
    $statePath = Get-StatePath -SourceKitRoot $SourceKitRoot
    if (-not [IO.File]::Exists($statePath)) {
        throw "Preparation state not found. Run scripts\prepare-original.ps1 first: $statePath"
    }
    try {
        return [IO.File]::ReadAllText($statePath) | ConvertFrom-Json
    }
    catch {
        throw "Preparation state is invalid JSON: $statePath. $($_.Exception.Message)"
    }
}

function Write-JsonFile {
    param(
        [Parameter(Mandatory = $true)]
        [string]$LiteralPath,

        [Parameter(Mandatory = $true)]
        [object]$Value
    )

    $parent = Split-Path -Parent $LiteralPath
    if (-not [IO.Directory]::Exists($parent)) {
        [void][IO.Directory]::CreateDirectory($parent)
    }
    $json = $Value | ConvertTo-Json -Depth 12
    [IO.File]::WriteAllText($LiteralPath, $json + [Environment]::NewLine, (New-Object Text.UTF8Encoding($false)))
}

function Resolve-ToolPath {
    param(
        [string]$RequestedPath,
        [Parameter(Mandatory = $true)]
        [string]$CommandName,
        [Parameter(Mandatory = $true)]
        [string]$ParameterHint
    )

    if (-not [string]::IsNullOrWhiteSpace($RequestedPath)) {
        $candidate = Get-FullPath -Path $RequestedPath
        if ([IO.File]::Exists($candidate)) {
            return $candidate
        }

        $explicitCommand = Get-Command $RequestedPath -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($null -ne $explicitCommand) {
            return $explicitCommand.Source
        }
        throw "Tool not found: $RequestedPath"
    }

    $command = Get-Command $CommandName -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($null -eq $command) {
        throw "Could not find '$CommandName'. Supply it with $ParameterHint; this source kit never downloads tools."
    }
    return $command.Source
}

function Invoke-Apktool {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ApktoolPath,

        [Parameter(Mandatory = $true)]
        [string]$JavaPath,

        [Parameter(Mandatory = $true)]
        [string[]]$Arguments,

        [switch]$CaptureOutput
    )

    if ([IO.Path]::GetExtension($ApktoolPath).Equals('.jar', [StringComparison]::OrdinalIgnoreCase)) {
        if ($CaptureOutput) {
            $output = & $JavaPath -jar $ApktoolPath @Arguments 2>&1
        }
        else {
            & $JavaPath -jar $ApktoolPath @Arguments
        }
    }
    else {
        if ($CaptureOutput) {
            $output = & $ApktoolPath @Arguments 2>&1
        }
        else {
            & $ApktoolPath @Arguments
        }
    }

    $exitCode = $LASTEXITCODE
    if ($exitCode -ne 0) {
        if ($CaptureOutput) {
            $rendered = ($output | ForEach-Object { $_.ToString() }) -join [Environment]::NewLine
            throw "Apktool failed with exit code $exitCode.`n$rendered"
        }
        throw "Apktool failed with exit code $exitCode."
    }

    if ($CaptureOutput) {
        return (($output | ForEach-Object { $_.ToString() }) -join [Environment]::NewLine).Trim()
    }
}

function Resolve-ApktoolPath {
    param([string]$RequestedPath)
    if ([string]::IsNullOrWhiteSpace($RequestedPath) -and -not [string]::IsNullOrWhiteSpace($env:APKTOOL_PATH)) {
        $RequestedPath = $env:APKTOOL_PATH
    }
    return Resolve-ToolPath -RequestedPath $RequestedPath -CommandName 'apktool' -ParameterHint '-ApktoolPath'
}

function Resolve-AndroidBuildTool {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ToolName,

        [string]$RequestedPath,
        [string]$AndroidSdkRoot,
        [string]$BuildToolsVersion
    )

    if (-not [string]::IsNullOrWhiteSpace($RequestedPath)) {
        return Resolve-ToolPath -RequestedPath $RequestedPath -CommandName $ToolName -ParameterHint "-$($ToolName.Substring(0,1).ToUpperInvariant())$($ToolName.Substring(1))Path"
    }

    $sdkRoot = $AndroidSdkRoot
    if ([string]::IsNullOrWhiteSpace($sdkRoot)) { $sdkRoot = $env:ANDROID_SDK_ROOT }
    if ([string]::IsNullOrWhiteSpace($sdkRoot)) { $sdkRoot = $env:ANDROID_HOME }
    if ([string]::IsNullOrWhiteSpace($sdkRoot) -and -not [string]::IsNullOrWhiteSpace($env:LOCALAPPDATA)) {
        $sdkRoot = Join-Path $env:LOCALAPPDATA 'Android\Sdk'
    }

    if (-not [string]::IsNullOrWhiteSpace($sdkRoot)) {
        $buildToolsRoot = Join-Path (Get-FullPath -Path $sdkRoot) 'build-tools'
        $candidateDirectories = @()
        if (-not [string]::IsNullOrWhiteSpace($BuildToolsVersion)) {
            $candidateDirectories = @(Join-Path $buildToolsRoot $BuildToolsVersion)
        }
        elseif ([IO.Directory]::Exists($buildToolsRoot)) {
            $candidateDirectories = @(Get-ChildItem -LiteralPath $buildToolsRoot -Directory | Sort-Object {
                try { [version]$_.Name } catch { [version]'0.0' }
            } -Descending | ForEach-Object { $_.FullName })
        }

        foreach ($directory in $candidateDirectories) {
            foreach ($fileName in @("$ToolName.exe", "$ToolName.bat", $ToolName)) {
                $candidate = Join-Path $directory $fileName
                if ([IO.File]::Exists($candidate)) {
                    return $candidate
                }
            }
        }
    }

    $pathCommand = Get-Command $ToolName -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($null -ne $pathCommand) {
        return $pathCommand.Source
    }

    throw "Could not find Android build tool '$ToolName'. Supply its explicit path or set ANDROID_SDK_ROOT; this source kit never downloads tools."
}

function ConvertTo-PlainText {
    param([Parameter(Mandatory = $true)][Security.SecureString]$Value)
    $pointer = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($Value)
    try {
        return [Runtime.InteropServices.Marshal]::PtrToStringBSTR($pointer)
    }
    finally {
        [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($pointer)
    }
}
