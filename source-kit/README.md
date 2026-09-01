# Mi Dash Cam patch source kit

This directory makes the Android compatibility work reviewable and repeatable without republishing Xiaomi/70mai's application source or a complete decompiled APK.

The kit starts from a copy of the original European Mi Dash Cam 1.1.0 APK supplied by the contributor. It verifies that input, decodes it locally, applies narrowly scoped reviewed compatibility transformations, and rebuilds an unsigned APK. A contributor may then sign their local build with a key they own.

## Supported base

| Property | Required value |
|---|---|
| Camera | Xiaomi Mi Dash Cam `MJXCJLY01BY` |
| Region | European / EU |
| Package | `com.banyac.mijia.app.eu` |
| Stock version | `1.1.0` (`versionCode 26`) |
| Stock APK SHA-256 | `3AC4C02EF5D43A0F9636637B1359073818C6799F3BFE3A7E2A38633F653D95A8` |

One historical source for that APK is the [APKMirror Mi Dash Cam 1.1.0 archive](https://www.apkmirror.com/apk/70mai-co-ltd/mi-dash-cam-2/mi-dash-cam-2-1-1-0-release/mi-dash-cam-1-1-0-android-apk-download/). APKMirror is a third-party archive, not part of this project. Verify the downloaded file by content, not by its filename.

## What is included

- scripts for preparing, patching, building, and verifying a local workspace;
- minimal transformations describing this project's compatibility changes;
- a human-readable, non-build Java reference for the project-authored PDF helper, while the manifest and Smali payload remain the executable source of truth;
- expected hashes and patch metadata;
- documentation explaining each change and its verification boundary.

## What is not included

- Xiaomi/70mai's original APK or a renamed copy of it;
- the complete decompiled Smali and resource tree;
- original artwork, application assets, signatures, or bundled manuals;
- vendor or third-party native libraries;
- signing keys, certificates containing private keys, or passwords;
- device logs, packet captures, account data, or other personal information;
- a claim that a locally rebuilt APK is byte-for-byte identical to an official project release.

Local inputs and generated workspaces belong under `input/`, `vendor-input/`, `work/`, and `build/`. Those paths are excluded from Git and must remain local.

## Workflow

From this directory:

```powershell
.\scripts\prepare-original.ps1 -OriginalApk C:\path\to\the-original.apk
.\scripts\apply-patches.ps1
.\scripts\build.ps1
.\scripts\verify.ps1 -ApkPath .\build\path-to-output.apk
```

For a code-only development workspace without the local native libraries and manuals, use `-AllowPartial` when applying, building, and verifying:

```powershell
.\scripts\apply-patches.ps1 -AllowPartial
.\scripts\build.ps1 -AllowPartial
.\scripts\verify.ps1 -AllowPartial -ApkPath .\build\Mi-Dash-Cam-EU-2.0.0-partial-development-unsigned.apk
```

The default build is unsigned. Signing is optional and uses a contributor-owned key:

```powershell
.\scripts\build.ps1 -KeystorePath C:\secure\my-release-key.p12 -KeyAlias my-alias
```

Run `Get-Help` on a script for its current parameters and output locations. Never place a keystore or password inside this repository.

A complete build requires locally supplied, checksum-verified native libraries and manuals under `vendor-input/`. They are deliberately not downloaded or redistributed by this kit while their provenance and license obligations remain unpinned. Without those inputs, the workflow can still demonstrate and develop the project-authored application patches, but it does not reproduce the complete release APK.

Read the full instructions before building:

- [Build from the original APK](docs/BUILD_FROM_ORIGINAL.md)
- [Patch map](docs/PATCH_MAP.md)
- [Patch-source and third-party notices](PATCH_SOURCE_NOTICES.md)
- [Licensing and redistribution boundaries](docs/LICENSING.md)
- [Repository notice](../NOTICE.md)

## Source-kit validation

The published workflow was tested from a fresh Apktool 3.0.3 decode of the checksum-pinned stock APK under Windows PowerShell 5.1. The preparation gate rejected a different APK, the patch output matched the reviewed 2.0.0 decoded tree across every non-generated file after line-ending normalization, a complete unsigned APK rebuilt successfully, and the verifier passed its package, version, SDK, ABI, vendor-input, ZIP-alignment, and ARM64 ELF-alignment checks.

Signing was not exercised with a private key as part of this public-source validation. The signing path remains optional and never includes the project's private release key.

## Important verification boundary

The verification script checks properties of an APK file. It does not prove that the app works with a physical camera. Changes involving connection, live preview, recordings, download, replay, or reconnect behavior still require a real European `MJXCJLY01BY` camera test.
