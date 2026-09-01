# Build from the original European APK

This guide produces a local patched build while keeping Xiaomi/70mai's APK, decoded files, native binaries, and signing material outside Git.

## Before you begin

You need:

- the European Mi Dash Cam 1.1.0 APK for `com.banyac.mijia.app.eu`;
- PowerShell and the Java/Android tooling reported by each script's `Get-Help` output;
- enough free space for an APK decoding workspace;
- checksum-pinned compatibility libraries and manuals in `vendor-input/` for a complete build, or an explicit code-only partial workflow;
- an optional signing key that you own if the result will be installed on a device.

This kit supports one exact stock input. A package with a similar name, a different regional build, or the Mi Dash Cam 1S application is not interchangeable.

## 1. Obtain the stock APK yourself

The project does not supply or redistribute Xiaomi/70mai's application. A historical reference is:

- [APKMirror — Mi Dash Cam 1.1.0 (26), uploaded 23 May 2018](https://www.apkmirror.com/apk/70mai-co-ltd/mi-dash-cam-2/mi-dash-cam-2-1-1-0-release/mi-dash-cam-1-1-0-android-apk-download/)

The required SHA-256 is:

```text
3AC4C02EF5D43A0F9636637B1359073818C6799F3BFE3A7E2A38633F653D95A8
```

The preparation script calculates the checksum itself and must stop if it differs. Do not bypass that check: patch locations and safety assertions are defined for this exact input.

If you want an independent Windows check before running the script:

```powershell
certutil -hashfile "C:\path\to\the-original.apk" SHA256
```

## 2. Prepare a local workspace

Open PowerShell in `source-kit` and run:

```powershell
.\scripts\prepare-original.ps1 -OriginalApk "C:\path\to\the-original.apk"
```

The script verifies the APK and decodes it into the ignored local workspace under `work/`. The stock APK and decoded tree must not be added to Git.

Preparation is intentionally fail-closed. If the input checksum, package identity, or expected patch anchors do not match, stop and investigate rather than forcing the patch onto a different application.

## 3. Supply local compatibility inputs for a complete build

The original APK contains only its inherited 32-bit ARM libraries. The full compatibility release also uses separately sourced native components for ARM64 and 16 KiB-page support.

This repository does not currently redistribute or automatically download those binaries. Place only the locally obtained files requested by the scripts under `vendor-input/`. The script must verify every expected checksum before using a file.

You are responsible for confirming each component's origin, license, notices, and redistribution terms. Do not replace a missing file with a similarly named binary from an unknown APK.

Without the complete verified vendor input set, the kit remains useful for reviewing and developing the application-level transformations. Use `-AllowPartial` in the patch, build, and verification commands; the resulting filename is marked `partial-development` and must not be described as a complete or byte-for-byte reproduction of the project's signed 2.0.0 release.

## 4. Apply the project patches

```powershell
.\scripts\apply-patches.ps1
```

For an intentionally incomplete code-only workspace:

```powershell
.\scripts\apply-patches.ps1 -AllowPartial
```

The patcher works only in the ignored decoded workspace. It checks known preconditions before making a change and should stop on an unexpected file rather than silently applying a partial transformation.

The behavioral purpose of each group is documented in [PATCH_MAP.md](PATCH_MAP.md). Patch metadata is the machine-readable source of truth for exact target paths, preconditions, and expected results.

## 5. Build

Build an unsigned APK first:

```powershell
.\scripts\build.ps1
```

Use `-AllowPartial` here too if the workspace was prepared without the complete vendor inputs:

```powershell
.\scripts\build.ps1 -AllowPartial
```

An unsigned APK is suitable for inspection but cannot normally be installed. To create an installable local build, use a keystore and alias that you own:

```powershell
.\scripts\build.ps1 -KeystorePath "C:\secure\my-release-key.p12" -KeyAlias "my-alias"
```

Follow the script's secure password prompt. Do not type a password directly into a command, script, environment file, issue, or commit. Keep the private key backed up outside the repository. Android accepts an update only when it is signed with the same key as the installed build.

A contributor-signed APK belongs to a different signing lineage from the project's release APK. It cannot update the stock app or an official project release in place.

## 6. Verify the built APK

```powershell
.\scripts\verify.ps1 -ApkPath ".\build\path-to-output.apk"
```

For an explicitly partial development APK:

```powershell
.\scripts\verify.ps1 -AllowPartial -ApkPath ".\build\Mi-Dash-Cam-EU-2.0.0-partial-development-unsigned.apk"
```

Verification should cover at least:

- output package identity; the preparation script verifies the stock input identity;
- version name and version code;
- manifest and SDK expectations;
- expected CPU architectures;
- APK signature schemes when the build is signed;
- ZIP and native-library alignment where applicable;
- unsafe or duplicate ZIP entry names;
- absence of packaged files with private-key-like extensions.

Keep the resulting report with your test notes. A successful static verification is necessary, but it is not a physical-camera acceptance test.

## 7. Smoke-test safely

Use a clean app install unless you are deliberately testing an upgrade within your own signing lineage. At minimum, check:

1. cold launch;
2. `Offline account` and the absence of a Mi-account login request;
3. Add camera, Tips, Installation, User manual, and FAQ;
4. repeated leave-and-reconnect cycles;
5. live preview;
6. recording list and thumbnails;
7. download and replay;
8. Android crash and ANR history.

Camera-network functions require a physical European `MJXCJLY01BY` or an equivalent controlled test setup. An emulator or remote device that cannot join the dashcam's Wi-Fi cannot verify those functions.

## Troubleshooting

### The original checksum does not match

Do not continue. Confirm that you downloaded European version 1.1.0, package `com.banyac.mijia.app.eu`, rather than a different region or camera model. A matching filename is not proof of matching content.

### Signing fails

Confirm the keystore path, alias, keystore type, and password. Trailing spaces copied with a password are significant. Do not solve the problem by committing or printing the secret.

### Android refuses to install the APK

An installed stock or community build may use a different signing certificate. Save anything needed, uninstall that app, and then install your build. Uninstalling clears its local app data.

### Verification passes but the camera does not work

Static checks do not validate the local network, camera firmware, RTSP behavior, or Android vendor networking. Capture a redacted bug report following the repository's [contribution guide](../../CONTRIBUTING.md).
