<p align="center">
  <img src="assets/app-icon.png" width="132" height="132" alt="Mi Dash Cam application icon">
</p>

<h1 align="center">Mi Dash cam Android 8.1-16 fix<br><code>MJXCJLY01BY</code></h1>

<p align="center">
  Restores the European Mi Dash Cam app on modern Android, including Poco F6 with Android 16 / HyperOS 3.
</p>

<p align="center">
  <img alt="Generation 2.0.0" src="https://img.shields.io/badge/generation-2.0.0-e5484d">
  <img alt="2.0.0 release candidate" src="https://img.shields.io/badge/status-release%20candidate-f59e0b">
  <img alt="Model MJXCJLY01BY" src="https://img.shields.io/badge/model-MJXCJLY01BY-555555">
  <img alt="EU region" src="https://img.shields.io/badge/region-EU-2563eb">
  <img alt="Android 8.1, 9, and 12 through 16 tested" src="https://img.shields.io/badge/tested-Android%208.1%20%7C%209%20%7C%2012--16-3ddc84">
  <img alt="1.1.9 Poco F6 hardware accepted" src="https://img.shields.io/badge/1.1.9%20baseline-hardware%20accepted-ff6900">
</p>

> [!IMPORTANT]
> This patch is for the Xiaomi Mi Dash Cam, model `MJXCJLY01BY`, European region. Xiaomi lists the similarly named Mi Dash Cam 1S as model `MJXCJLY02BY`; that is a different camera and is not supported by this project.

- [Simple overview](#simple-overview) — what this is, why it exists, what was fixed, supported Android versions, and installation.
- [Technical details](#technical-details) — exact changes, account behavior, native compatibility, verification, and release identity.

# Simple overview

## What is this?

This repository provides an unofficial compatibility version of the European Mi Dash Cam app for the Xiaomi Mi Dash Cam `MJXCJLY01BY`. It is intended specifically for this camera model and the European app variant.

Version 2.0.0 works locally without a Mi account and restores the phone features needed to set up and use the dashcam.

The app has been checked on real phones running Android 8.1, 9, 12, and 16, with additional Android 13–15 testing described below. A complete camera test on a Poco F6 confirmed live view, recordings, download, and playback with the earlier 1.1.9 build. Before 2.0.0 is published, it still needs one final real-camera test focused on leaving the camera and connecting to it again several times.

This repository contains the explanation, screenshots, checksums, and test results. Developers can review, reproduce, and improve the compatibility work through the [patch source kit](source-kit/README.md) without redistributing the complete decompiled Xiaomi/70mai application. The patched app will be added to GitHub Releases after that final test passes.

The patched app provides:

- connect to the dashcam over Wi-Fi;
- see the live camera view;
- browse recordings and thumbnails;
- download recordings to the phone;
- replay downloaded videos;
- change camera settings;
- read help and user manuals without relying on dead websites.

## Why I made it

This project exists because I wanted to use my dashcam, only to discover that its original app no longer worked on my phone. The newer Mi Home app did not want to connect to this dashcam either. The camera was still functional, but the software needed to use it had effectively been left behind.

The original Mi Dash Cam app would crash when opening its buttons, hang while connected, show a black live preview, display obsolete update messages, and send its help buttons to `502 Bad Gateway` pages. On Android 15 and newer, the untouched APK was also too old to install normally.

Rather than discard working hardware because its companion app was abandoned, the app was taken apart, studied, repaired, rebuilt, signed, and tested on current devices.

## Abandonment timeline

Xiaomi/70mai did not publish a formal “this app is abandoned” notice that we could find, so this timeline separates verifiable records from the point where the app became practically unusable.

| Date | What happened |
|---|---|
| January 2018 | Third-party app history records show the European Mi Dash Cam app appearing on Google Play. |
| 23 May 2018 | Original version 1.1.0 was published. It targeted Android 6 / API 23 and contained only 32-bit ARM libraries. This is the last original release we could verify. ([APKMirror record](https://www.apkmirror.com/apk/70mai-co-ltd/mi-dash-cam-2/mi-dash-cam-2-1-1-0-release/mi-dash-cam-1-1-0-android-apk-download/)) |
| 2018–2024 | No newer original European APK was found. Android, phone CPUs, media libraries, storage rules, and security requirements continued moving forward while the app remained at 1.1.0. |
| 18 September 2024 | AppBrain records the app as removed from Google Play and still lists 1.1.0 as its final version. ([AppBrain history](https://www.appbrain.com/app/mi-dash-cam/com.banyac.mijia.app.eu)) |
| Android 15 era | Android began rejecting normal installation of apps targeting below API 24. The original targets API 23, so fresh installation fails on Android 15/16. ([Android documentation](https://developer.android.com/about/versions/15/behavior-changes-all)) |
| 28 August 2026 | This investigation reproduced the crashes, freezing, black preview, dead update flow, and HTTP 502 help pages. The current Mi Home app also failed to provide a working replacement connection for this EU camera. |
| 31 August 2026 | Patch `1.1.9-android16-eu9` reached stable status after a complete physical Poco F6 / Android 16 / HyperOS 3 camera test passed. |
| 1 September 2026 | The new generation became `2.0.0`. It removes the remaining executable Mi-account/login code and adds targeted hardening for a reported hang when connecting to the camera again. Final repeated-connection hardware acceptance is pending. |

The important point is simple: the hardware outlived its software support by years.

## Original app archive references

These links preserve the abandoned European app's public history around the time it stopped being distributed through Google Play. They refer to Xiaomi/70mai's old stock package `com.banyac.mijia.app.eu`, not to this patched release:

- [APKMirror — Mi Dash Cam 1.1.0 (26), uploaded 23 May 2018](https://www.apkmirror.com/apk/70mai-co-ltd/mi-dash-cam-2/mi-dash-cam-2-1-1-0-release/mi-dash-cam-1-1-0-android-apk-download/)
- [APKCombo — Mi Dash Cam package archive, versions 1.0.1 through 1.1.0](https://apkcombo.com/mi-dash-cam/com.banyac.mijia.app.eu/)
- [APKFab — Mi Dash Cam package archive with 1.0.1, 1.0.2, and 1.1.0](https://apkfab.com/mi-dash-cam/com.banyac.mijia.app.eu)
- [AppBrain — Google Play history and removal record](https://www.appbrain.com/app/mi-dash-cam/com.banyac.mijia.app.eu)

The mirror metadata agrees on final stock version 1.1.0, 32-bit `armeabi-v7a`, and package name `com.banyac.mijia.app.eu`. APKMirror records the original file SHA-256 as `3AC4C02EF5D43A0F9636637B1359073818C6799F3BFE3A7E2A38633F653D95A8`. These old files are kept here as historical references only; they do not contain the Android 12–16 compatibility fixes. Use this repository's Releases page for the patched APK.

## What was fixed?

In plain language:

- It installs again: The app is accepted by Android 15 and 16 without special installation commands.
- The menus work: Add camera, Profile, Tips, Installation, User manual, FAQ, and settings no longer crash the app.
- The camera connects: Direct Wi-Fi communication with `MJXCJLY01BY` is preserved.
- Live preview works: The app now uses the network transport expected by the camera instead of leaving a black video area.
- The app stays responsive: The repeated media-player restart loop was removed, and VideoLAN's upstream asynchronous native-stop fix was backported so a dead RTSP session cannot hold Android's main thread during teardown.
- Connecting again is bounded: Version 2.0.0 cancels stale camera-screen requests and removes long hidden retries from the fast control commands used during connection. Repeated physical reconnect acceptance is still pending.
- Recordings work: File lists, thumbnails, download, and replay are operational.
- No Mi account is required: The app starts as `Offline account` and uses the camera locally.
- The help section works offline: Dead 502 web pages were replaced with built-in help and four clearly named PDF manuals.
- The obsolete app-update prompt is gone: It cannot keep asking for an update that will never arrive.
- The camera firmware button was left alone: It remains a separate original function.
- Modern phone CPUs are supported: ARM64 and 16 KiB-page compatibility were added while retaining older ARMv7 support.

## Supported Android versions

| Android | Status | Verified on |
|---|---|---|
| Android 8.1 | Exact 2.0.0 clean install and physical app/UI regression verified; camera hardware not tested | FUJITSU F-01L, API 27 |
| Android 9 | Exact 2.0.0 clean install and physical app/UI regression verified; camera hardware not tested | SHARP AQUOS sense2 (`SH-01L`), API 28 |
| Android 10–11 | Not tested | No support claim yet |
| Android 12 | Exact 2.0.0 clean install and app/UI verified; camera/media baseline verified on 1.1.9 | Samsung Galaxy Note10+ (`SM-N975F`), One UI 4.1 |
| Android 13 | App/UI supported and verified on the 1.1.9 baseline | BlueStacks 5 Android 13 Beta, API 33 (`Tiramisu64`) |
| Android 14 | App/UI supported and physically verified on the 1.1.9 baseline | Samsung Galaxy S24 (`SM-S921U`) and S24 Ultra (`SM-S928U1`), API 34 |
| Android 15 | 2.0.0 debug-candidate replacement and clean-data smoke verified; 1.1.9 baseline verified | MuMu Player, API 35 |
| Android 16 | Exact 2.0.0 clean install and app/UI verified; camera/media baseline verified on 1.1.9 | Redmi 13C (`24040RN64Y`), HyperOS `3.0.4.0.WNTEUXM` |
| Android 16 | 1.1.9 baseline fully hardware accepted | Poco F6, HyperOS `3.0.303.0.WNPEUXM.C07` |

A complete physical test was conducted with the exact 1.1.9 APK and the EU `MJXCJLY01BY` connected to the Poco F6. Startup, camera connection, live preview, sustained responsiveness, recording list and thumbnails, download, and replay all passed. This proves the inherited camera/media baseline; the 2.0.0 reconnect delta still needs its own repeated-session camera test.

On BlueStacks Android 13, the exact APK installed with its ARM64 libraries, cold-launched, showed the tokenless profile, rendered offline Tips/manuals, and opened Add camera with no fatal exception or ANR. BlueStacks' virtual networking was not used as a substitute for a physical camera-Wi-Fi test.

On two physical Android Device Streaming phones running Samsung Android 14/API 34, the exact APK clean-installed as ARM64, cold-launched, showed `Offline account` / `No Mi account connected`, rendered all four local help/manual sections, handed a bundled PDF to Android's resolver, and opened the Add-camera hotspot guide. Android exit history and event logs contained no crash or ANR. Because these phones are hosted remotely in Google's device lab, they cannot join the dashcam's local Wi-Fi and do not replace the Poco F6 camera/live-preview acceptance test.

The exact release-signed 2.0.0 APK was clean-installed on a physical FUJITSU F-01L running Android 8.1/API 27 and a physical SHARP AQUOS sense2 SH-01L running Android 9/API 28 through Android Device Streaming. Both selected the bundled `arm64-v8a` libraries and passed the main screen, `Offline account`, Add camera, Tips, Installation, User manual, FAQ, all four bundled manual entries, and two additional cold relaunches. Android 8.1 rendered the selected PDF; Android 9 handed it to Android and displayed the PDF application chooser. Captured diagnostics contained no app crash, ANR, or Xiaomi-account authentication signal.

Those remotely hosted phones cannot join the `MJXCJLY01BY` local Wi-Fi. They did not test camera connection, live preview, recording access, download, or replay and are not camera-hardware acceptance tests.

## Download and install

Version 2.0.0 is not ready for public download yet. The exact release-signed file is complete and verified, but publication remains blocked on recurrent-reconnect hardware acceptance. Do not install an unsigned or debug candidate. `Mi-Dash-Cam-EU-2.0.0-android12-16-arm64.apk` will appear on the repository's [GitHub Releases page](https://github.com/Void-Man-1/Mi-Dash-cam-Android-8.1-16-fix-MJXCJLY01BY/releases/latest) only after that final physical test passes.

When the release is published:

1. Download the exact 2.0.0 APK from GitHub Releases.
2. Verify its SHA-256 against [`checksums/SHA256SUMS.txt`](checksums/SHA256SUMS.txt).
3. Save anything you need, then uninstall any existing Mi Dash Cam app, whether it is Xiaomi's stock app or a community 1.1.x build. Version 2.0.0 uses a new release signing key, so Android cannot install it over either signing lineage. Uninstalling clears the existing app's local data.
4. Open the downloaded APK and allow installation from that browser or file-manager source when Android asks.
5. Launch Mi Dash Cam. It should open directly as `Offline account`, without Mi-account login.
6. Power on the `MJXCJLY01BY`, join its Wi-Fi network, and add/connect it in the app. The camera network intentionally has no internet; tell Android to stay connected if it warns or tries to switch back to mobile data/another Wi-Fi network.

Version 2.0.0 begins a new signing lineage. It cannot upgrade Xiaomi's stock app or community builds 1.1.3–1.1.9 in place. Every future 2.0.0+ release must use the same new release key so upgrades within the new lineage remain possible.

## What it looks like

<p align="center">
  <img src="assets/screenshots/main-redmi-android16.png" width="230" alt="Mi Dash Cam main screen on Android 16">
  &nbsp;
  <img src="assets/screenshots/offline-account-redmi-android16.png" width="230" alt="Offline account screen on Android 16">
  &nbsp;
  <img src="assets/screenshots/manual-library-redmi-android16.png" width="230" alt="Offline user manual library on Android 16">
</p>

<p align="center"><em>Historical 1.1.9 baseline: main screen, tokenless Offline account, and bundled manual library on Android 16.</em></p>

<p align="center">
  <img src="assets/screenshots/poco-f6-hyperos3-android16.jpg" width="300" alt="Poco F6 running HyperOS 3 and Android 16">
</p>

<p align="center"><em>Poco F6 used for the complete physical-camera acceptance of the historical 1.1.9 baseline: HyperOS 3.0.303.0.WNPEUXM.C07, Android 16.</em></p>

<p align="center">
  <img src="assets/screenshots/bluestacks-android13-main.png" width="300" alt="Mi Dash Cam running on BlueStacks Android 13">
</p>

<p align="center"><em>Historical 1.1.9 baseline: clean launch on BlueStacks 5 Android 13 Beta / API 33.</em></p>

<p align="center">
  <img src="assets/screenshots/galaxy-s24-android14-main.png" width="230" alt="Mi Dash Cam main screen on a physical Galaxy S24 running Android 14">
  &nbsp;
  <img src="assets/screenshots/galaxy-s24-android14-offline-account.png" width="230" alt="Offline account on a physical Galaxy S24 running Android 14">
  &nbsp;
  <img src="assets/screenshots/galaxy-s24-ultra-android14-add-camera.png" width="230" alt="Add-camera wizard on a physical Galaxy S24 Ultra running Android 14">
  &nbsp;
  <img src="assets/screenshots/galaxy-s24-ultra-android14-manuals.png" width="230" alt="Bundled MJXCJLY01BY manual library on a physical Galaxy S24 Ultra running Android 14">
</p>

<p align="center"><em>Historical 1.1.9 baseline: physical Galaxy S24/S24 Ultra Android 14/API-34 regression pass via Android Device Streaming.</em></p>

<p align="center">
  <img src="assets/screenshots/fujitsu-f-01l-android8-main.png" width="230" alt="Mi Dash Cam 2.0.0 main screen on a physical FUJITSU F-01L running Android 8.1">
  &nbsp;
  <img src="assets/screenshots/fujitsu-f-01l-android8-manual-pdf.png" width="230" alt="Bundled MJXCJLY01BY English manual rendered on a physical FUJITSU F-01L running Android 8.1">
  &nbsp;
  <img src="assets/screenshots/sharp-sh-01l-android9-offline-account.png" width="230" alt="Offline account screen on a physical SHARP AQUOS sense2 SH-01L running Android 9">
  &nbsp;
  <img src="assets/screenshots/sharp-sh-01l-android9-pdf-handoff.png" width="230" alt="Bundled manual handed to the Android PDF chooser on a physical SHARP AQUOS sense2 SH-01L running Android 9">
</p>

<p align="center"><em>Exact 2.0.0 candidate: physical Android 8.1/API-27 and Android 9/API-28 app/UI regression pass via Android Device Streaming.</em></p>

# Technical details

## Exact camera identification

| Property | Supported value |
|---|---|
| Product name | Xiaomi Mi Dash Cam |
| Model number | `MJXCJLY01BY` |
| Region | European / EU app and camera variant |
| Android package | `com.banyac.mijia.app.eu` |
| Video | 1920 × 1080 |
| Wi-Fi | 802.11 b/g/n, direct phone-to-camera connection |

The model number and hardware specifications are corroborated by Xiaomi's [official Mi Dash Cam specification page](https://www.mi.com/mj-carcorder/specs) and [global compliance index](https://www.mi.com/global/support/terms/declaration/). The compliance index separately identifies `MJXCJLY02BY` as Mi Dash Cam 1S.

## Detailed changes

### Added or repaired

| Area | Technical change |
|---|---|
| Android installation | Raised `targetSdkVersion` from 23 to 28, clearing Android 15's minimum installable target floor. |
| CPU compatibility | Added `arm64-v8a` IJK and VLC libraries while retaining `armeabi-v7a`. |
| 16 KiB systems | Aligned every ARM64 ELF `PT_LOAD` segment to `0x10000` and verified APK packaging with `zipalign -P 16`. |
| Legacy HTTP | Declared optional `org.apache.http.legacy`, fixing the `AndroidHttpClient` navigation crash introduced by the API-28 target. |
| Camera network | Preserved cleartext local HTTP for camera CGI, thumbnail, download, and media endpoints. |
| Live preview | Added VLC `--rtsp-tcp` so the camera's RTP/JPEG stream is interleaved over RTSP TCP. |
| Responsiveness | Removed the five-second UI-thread VLC stop/recreate cycle, limited failure handling, added lifecycle cleanup, and backported VideoLAN's asynchronous `nativeStop()` fix for modules that can hang during teardown. |
| Recurrent connection | Before a new camera-screen initialization, cancels stale tagged requests; fast control requests use a 4-second timeout and no hidden retry. Recording-list and media-download timing is unchanged. |
| Download handling | Replaced an exposed `file://` media-scan broadcast with `MediaScannerConnection.scanFile()`. |
| Help content | Replaced dead 70mai web routes with responsive offline Tips, Installation, FAQ, Wi-Fi help, and a manual library. |
| Manuals | Bundled English phone-friendly, English landscape, Russian phone-friendly, and Russian original landscape PDFs. |
| Accountless use | Uses a tokenless local profile named `Offline account`; fresh installs skip Mi-account sign-in. Version 2.0.0 also removes the old login activity, Xiaomi account SDK bytecode, auth-service interfaces, and remote-profile client/callback. |
| Defensive account cleanup | Retains code that erases Mi access tokens and avatar URLs if encountered during a later same-key 2.x migration. Moving from stock or community 1.1.x to 2.0.0 still requires an uninstall, so older app data is not carried into this signing lineage. |
| UI identity | Displays `Patched by Void__Man` and `Version: 2.0.0` above the unchanged firmware row. |

Android's relevant platform documentation is available for the [Android 15 install restriction](https://developer.android.com/about/versions/15/behavior-changes-all), [Apache HTTP compatibility](https://developer.android.com/about/versions/pie/android-9.0-changes-28), [Android 16 compatibility testing](https://developer.android.com/about/versions/16/migration), and [16 KiB page sizes](https://developer.android.com/guide/practices/page-sizes).

### Removed or disabled

- Xiaomi OAuth permission, authorization/login activities, OAuth app ID, and redirect metadata from the production manifest.
- The executable Xiaomi account SDK, auth-service interfaces, and remote-profile client/callback used by the old login flow.
- Both obsolete application self-update prompts.
- Broken `eu-help.70mai.com` navigation that returned HTTP 502.
- The blocking five-second live-preview retry loop.
- Unsafe `file://` media notification behavior.
- Display or remote reuse of a historical Mi-account identifier during normal operation.

Some inert inherited resource identifiers can still contain old login-related names, but current executable-code scans find no Xiaomi account endpoint, account SDK class, auth-service interface, login activity, access-token starter, OAuth authorizer, or OAuth app-ID reference.

### Deliberately preserved

- Original local CGI, recording-list, thumbnail, download, replay, settings, and streaming protocols.
- The separate clickable Firmware update row and its camera-firmware command path.
- European package identity and local device/database compatibility.
- ARMv7 support for older compatible phones.

The firmware button was not repurposed. The legacy OTA result is not guaranteed because Xiaomi/70mai controls that external backend.

## Offline-account behavior

- A clean installation creates only a local profile.
- The visible account name is `Offline account` with `No Mi account connected`.
- Legacy migration code clears stored Mi tokens and avatar URLs when it encounters them, but installing 2.0.0 requires removing any stock or community 1.1.x installation first, so that older app data is not carried into 2.0.0.
- The old internal identifier can remain only as a local database key for data created within the new 2.0.0+ signing lineage.
- Five reachable legacy request builders overwrite any field named `xiaomiId` with the anonymous string `offline-local`.
- A captured fresh 1.1.9 launch/account/device/settings session produced no Mi/Xiaomi account DNS request and no cleartext authorization, cookie, token, or user-ID value. The exact 2.0.0 executable additionally has no reachable Mi-account implementation.

The app is accountless, not network-air-gapped. Camera control requires direct local network traffic, and inherited non-account configuration code can still resolve a 70mai service such as `de-api.70mai.com`.

## Verification

The exact signed 1.1.9 baseline passed:

- APK Signature Scheme v1, v2, and v3 verification;
- `zipalign -P 16 -c 4`;
- AArch64/16 KiB ELF checks for all seven ARM64 native libraries;
- post-sign manifest, DEX, asset, and bundled-manual hash audits;
- clean or upgrade launch/account/navigation tests on Android 12, 13, 14, 15, and 16;
- full real-camera operation on Poco F6 / HyperOS 3 / Android 16;
- physical recording list, thumbnail, download, and replay checks;
- visible RTSP/RTP-JPEG live preview without the old repeated UI freeze;
- a fresh-install packet capture with no Mi/Xiaomi account authentication traffic.

The exact release-signed 2.0.0 candidate additionally passes v1/v2/v3 signature verification, 16 KiB ZIP/ELF alignment, a clean signed-APK decode and unsigned rebuild, exact `20000` / `2.0.0` identity checks, executable account-path and sensitive-data scans, structural reconnect-policy checks, and structural confirmation of the asynchronous VLC stop backport. Clean installs on physical Android 8.1, 9, 12, and 16 phones reached the 2.0.0 main screen, Offline account, Add camera, every local help/manual route, and bundled PDF handoff with zero captured fatal exceptions or ANRs. The Android 8.1 and Android 9 phones also passed two additional cold relaunches and produced zero captured Xiaomi-authentication signals. Android 15 MuMu debug-candidate replacement and clean-data smoke tests also passed; that same-debug-key replacement does not establish upgrade compatibility with Xiaomi's stock app or community 1.1.x builds.

Repeated real-camera reconnect cycles, followed by live preview, recording list, download, and replay checks after reconnecting, are the remaining release gate. See the [2.0.0 verification report](docs/TEST_REPORT_2.0.0.md) for the exact boundary between completed and pending checks.

## Release identity

| Field | Value |
|---|---|
| Version name | `2.0.0` |
| Version code | `20000` |
| Package | `com.banyac.mijia.app.eu` |
| Minimum SDK declared | API 15 |
| Target SDK | API 28 |
| ABIs | `arm64-v8a`, `armeabi-v7a` |
| APK SHA-256 | `2F189C0D3A6C9965036EDDBFA927EB7FD720C47D611991EB5EC1D1055E89B887` |
| Signing certificate SHA-256 | `BE7E580BAE6723900DD30952B1DF215B282B445BCADAFC621C03B8D9CF81A1BD` |

The new key must be retained securely and used for every future 2.0.0+ release. Changing it again would require another uninstall and would clear app data again.

## Known limitations

- Only the Xiaomi Mi Dash Cam `MJXCJLY01BY` EU variant is supported. Mi Dash Cam 1S `MJXCJLY02BY` and other 70mai/Xiaomi cameras are not claimed compatible.
- Android 10 and 11 are untested. Android 13 is emulator-verified but has not received a physical-device/camera-network pass.
- Android 8.1, 9, and 14 have physical-device app/UI passes, but their remotely hosted phones could not access the local dashcam Wi-Fi. Camera behavior on those Android versions remains unverified.
- The preserved firmware-update backend may no longer be available.
- This is a compatibility patch around a legacy application, not a modern rewrite or a Google Play submission.

## Documentation

- [Release 2.0.0 candidate test report](docs/TEST_REPORT_2.0.0.md)
- [Historical release 1.1.9 test report](docs/TEST_REPORT_1.1.9.md)
- [Reverse-engineering and patch report](docs/REVERSE_ENGINEERING_REPORT.md)
- [Release 2.0.0 notes](docs/RELEASE_NOTES_2.0.0.md)
- [Historical release 1.1.9 notes](docs/RELEASE_NOTES_1.1.9.md)
- [Repository listing metadata](docs/GITHUB_LISTING.md)
- [Publishing checklist](docs/PUBLISHING_CHECKLIST.md)
- [Reproducible patch source kit](source-kit/README.md)
- [Contributing and useful bug reports](CONTRIBUTING.md)
- [Legal and attribution notice](NOTICE.md)
- [Release checksum](checksums/SHA256SUMS.txt)

## Disclaimer

This is an unofficial community preservation and interoperability project. It is not affiliated with, endorsed by, or supported by Xiaomi, 70mai, or the original application developer. Xiaomi, Mi, 70mai, product names, icons, and trademarks belong to their respective owners. Use the modified application at your own risk and never interact with the dashcam while driving.
