# Mi Dash Cam EU 1.1.9 release notes

Historical status: this is the exact signed hardware-accepted baseline. The current generation is the 2.0.0 release candidate documented in [`RELEASE_NOTES_2.0.0.md`](RELEASE_NOTES_2.0.0.md). The 1.1.9 results remain here because they establish the last complete physical-camera acceptance without implying that the new 2.0.0 reconnect delta has already passed.

## Release

- File: `Mi-Dash-Cam-EU-1.1.9-android16-arm64.apk`
- Camera: Xiaomi Mi Dash Cam `MJXCJLY01BY`, European region
- App version: `1.1.9-android16-eu9` (`versionCode 36`)
- Package: `com.banyac.mijia.app.eu`
- SHA-256: `2EEA8D5655AB610B3C476064BB7EDAEC0CA73BF98818DC9D8EB5F27B39A8D7BC`

## Highlights

- Runs without a Mi account using a local `Offline account` profile.
- Removes Mi OAuth manifest entry points and clears migrated credentials/avatar URLs.
- Adds ARM64 media libraries and 16 KiB native/page alignment.
- Fixes the removed Apache `AndroidHttpClient` dependency crash.
- Replaces broken 502 help pages with offline help and four bundled manuals.
- Uses RTSP/TCP for the camera's RTP/JPEG live-preview stream.
- Removes the UI-thread preview retry loop responsible for repeated freezes.
- Disables obsolete application-update prompts.
- Preserves the original camera firmware-update row and command path.
- Adds patch attribution and an exact version label above the firmware row.

## Tested environments

- Samsung Galaxy Note10+ / Android 12 / One UI 4.1
- BlueStacks 5 Android 13 Beta / API 33 (`Tiramisu64`): clean launch, Offline account, Tips, manual library, and Add-camera wizard; zero fatal/ANR hits
- Physical Samsung Galaxy S24 (`SM-S921U`) and S24 Ultra (`SM-S928U1`) / Android 14 / API 34 via Android Device Streaming: clean ARM64 install, cold launch, Offline account, all offline help/manual sections, PDF resolver, and Add-camera wizard; zero crash/ANR records
- MuMu Player / Android 15 / API 35
- Redmi 13C `24040RN64Y` / Android 16 / HyperOS `3.0.4.0.WNTEUXM`
- Poco F6 / Android 16 / HyperOS `3.0.303.0.WNPEUXM.C07`: complete physical EU MJXCJLY01BY test passed, including connection, live preview, responsiveness, recording list/thumbnails, download, and replay

Android 13 still lacks a physical-device report. The Android 14 phones were remotely hosted and therefore could not join the dashcam's local Wi-Fi; real-camera Android 14 coverage remains pending even though the physical-device app/UI regression pass is complete.

## Installation note

Xiaomi's original APK and this build have different signing certificates. Uninstall the original app before installing this release. Earlier community patch builds 1.1.3–1.1.8 can upgrade in place because they share the patch certificate.
