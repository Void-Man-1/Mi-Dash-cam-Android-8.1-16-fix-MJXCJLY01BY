# Mi Dash Cam EU 2.0.0 release notes

Release status: final, exact release-signed APK verified and physically hardware accepted.

## Release identity

- Release file: `Mi-Dash-Cam-EU-2.0.0-android12-16-arm64.apk`
- Camera: Xiaomi Mi Dash Cam `MJXCJLY01BY`, European region
- App version: `2.0.0` (`versionCode 20000`)
- Package: `com.banyac.mijia.app.eu`
- SHA-256: `2F189C0D3A6C9965036EDDBFA927EB7FD720C47D611991EB5EC1D1055E89B887`
- Signing certificate SHA-256: `BE7E580BAE6723900DD30952B1DF215B282B445BCADAFC621C03B8D9CF81A1BD`

The exact file above is the final release artifact. Do not redistribute a debug, unsigned, modified, or differently signed build under the same version.

## Why the version is now 2.0.0

The original European app ended at version 1.1.0. Compatibility work restored operation on modern Android, but version 2.0.0 is a larger generational change: the old cloud-account-gated application now starts as a local accountless tool, its executable Mi-account implementation is removed, and the camera reconnection path is hardened.

## Signing-key transition

Version 2.0.0 uses a new release signing key and begins a new signing lineage. Android cannot install it as an upgrade over Xiaomi's stock app or an earlier community 1.1.x build. Save anything needed from the existing installation, uninstall it, and then install 2.0.0. Uninstalling clears the existing app's local data.

Every future 2.0.0+ release must use this same key so Android can upgrade releases within the new lineage. Its verified certificate fingerprint is recorded above.

## Changes in 2.0.0

### Mi-account code removed

- Removed the legacy login activity from the manifest and executable code.
- Removed the bundled Xiaomi account SDK bytecode and Xiaomi auth-service interface bytecode used by the old sign-in flow.
- Removed the remote-profile client and callback.
- Kept startup on a tokenless local profile displayed as `Offline account` / `No Mi account connected`.
- Kept defensive sanitization that clears access tokens and avatar URLs if they appear during a later same-key 2.x migration.
- Confirmed by executable-code scans that the final APK has no Xiaomi account endpoint, auth-service interface, login activity, access-token starter, OAuth authorizer, or OAuth app-ID reference.

### Camera reconnection hardened

The reported failure was a hang when connecting to the camera again, not simultaneous use by two phones. Version 2.0.0 addresses that recurrent-connection path by:

- cancelling an earlier request chain tagged to the camera screen before a new connection sequence begins;
- changing the fast camera-control requests used during connection from a 10-second timeout with three hidden retries to a 4-second timeout with no hidden Volley retry;
- backporting VideoLAN's upstream asynchronous `nativeStop()` change so a stalled RTSP module cannot block Android's main thread while the preview is torn down;
- keeping recording-list and media-download timing unchanged;
- retaining live-preview lifecycle cleanup and the RTSP/TCP transport repair.

These changes bound failed control requests and prevent stale work from overlapping a new connection attempt. Physical use on the Poco F6 confirmed successful camera connection and reconnection without the reported hang.

### Release identity

- Changed the visible version label to `Version: 2.0.0`.
- Changed Android package metadata to `versionName 2.0.0` and `versionCode 20000`.
- Left the separate camera Firmware update row and its original command path unchanged.

## Current feature set

Version 2.0.0 includes:

- installation on Android 15 and 16 without special installation commands;
- tested phone-side compatibility across Android 8.1, 9, and 12 through 16, with the exact evidence boundaries documented in the verification report;
- ARM64 and 16 KiB native/page alignment while retaining ARMv7;
- optional Apache HTTP compatibility for the legacy application code;
- direct local camera CGI, thumbnail, recording, download, replay, settings, and streaming paths;
- RTSP/TCP live preview for the camera's RTP/JPEG stream;
- removal of the blocking UI-thread preview restart loop;
- offline Tips, Installation, FAQ, Wi-Fi help, and four bundled `MJXCJLY01BY` manuals;
- disabled obsolete application self-update prompts;
- safe media scanning and private-cache PDF handoff;
- `Patched by Void__Man` attribution above the unchanged firmware row.

## Verification and hardware acceptance

The final 2.0.0 APK passed:

- exact release signing with verified v1/v2/v3 signatures and a 4096-bit RSA key;
- exact APK and signing-certificate SHA-256 fingerprints recorded above;
- `zipalign -P 16 -c 4` and AArch64 ELF load alignment at `0x10000` for all seven ARM64 libraries;
- clean signed-APK decode and unsigned round-trip rebuild;
- exact package identity, `versionCode 20000`, and `versionName 2.0.0` checks;
- four bundled manual hashes matched against their reviewed source PDFs;
- structural confirmation of reconnect cancellation and the 4-second/no-retry camera-control policies;
- structural and round-trip confirmation that VLC native stop runs outside Android's main thread;
- executable-code scans for the removed Mi-account paths and a redacted sensitive-data scan over the decoded APK;
- exact clean-install app/UI checks on physical Android 8.1, 9, 12, and 16 phones;
- additional Android 13, 14, and 15 development-build coverage described in the verification report;
- full physical-camera acceptance with a Poco F6 running Android 16 / HyperOS 3.0.303.0.WNPEUXM.C07 and the European `MJXCJLY01BY`.

The [recorded physical test](https://github.com/Void-Man-1/Mi-Dash-cam-Android-8.1-16-fix-MJXCJLY01BY/blob/v2.0.0/assets/evidence/poco-f6-android16-v2.0.0-full-camera-test.mp4) directly shows one camera connection, visible live preview, the recording grid and thumbnails, recording playback, two export/download operations, local help routes, and no visible crash, Android-not-responding dialog, or prolonged UI freeze. The accompanying tester confirmation reports that camera reconnection and all exercised features also worked. See the [evidence notes](https://github.com/Void-Man-1/Mi-Dash-cam-Android-8.1-16-fix-MJXCJLY01BY/blob/v2.0.0/assets/evidence/README.md) for the distinction between what is visible in the recording and what the tester separately confirmed.

The video is user-interface evidence, not a packet capture or Android system log. It does not independently prove the absence of background network traffic. Accountless behavior is supported separately by the executable-code scans and earlier runtime checks documented in the [2.0.0 verification report](https://github.com/Void-Man-1/Mi-Dash-cam-Android-8.1-16-fix-MJXCJLY01BY/blob/v2.0.0/docs/TEST_REPORT_2.0.0.md).

The camera firmware OTA function was not tested and is not part of the hardware-acceptance claim. Its row and original command path remain unchanged, but the legacy external backend may no longer be available.

The remotely hosted Android 8.1 and Android 9 phones could not join the dashcam's local Wi-Fi. Their results verify phone-side app/UI compatibility only; the Poco F6 test supplies the final real-camera evidence.

The VLC teardown change follows VideoLAN's [2017 ANR-prevention commit](https://github.com/videolan/vlc-android/commit/1dbdcb3f3041d57ea0be07b929c3339719ade1b1). VideoLAN's tracker also documents the same main-thread stop hang after repeated players and after an RTSP source disappears from Wi-Fi.

## Installation

1. Save anything needed from an existing Mi Dash Cam installation.
2. Uninstall Xiaomi's stock app or any earlier community 1.1.x build. The fresh 2.0.0 signing key prevents an in-place upgrade, and uninstalling clears the old app's local data.
3. Download `Mi-Dash-Cam-EU-2.0.0-android12-16-arm64.apk` from the GitHub release.
4. Verify that its SHA-256 is exactly `2F189C0D3A6C9965036EDDBFA927EB7FD720C47D611991EB5EC1D1055E89B887`.
5. Install the APK and launch it as `Offline account`.
6. Join the `MJXCJLY01BY` Wi-Fi network and tell Android to remain connected if it warns that the camera network has no internet.
