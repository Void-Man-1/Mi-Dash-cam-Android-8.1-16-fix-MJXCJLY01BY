# Mi Dash Cam EU 2.0.0 release notes

Release status: exact release-signed candidate verified; repeated-connection hardware acceptance pending.

## Release identity

- Release file: `Mi-Dash-Cam-EU-2.0.0-android12-16-arm64.apk`
- Camera: Xiaomi Mi Dash Cam `MJXCJLY01BY`, European region
- App version: `2.0.0` (`versionCode 20000`)
- Package: `com.banyac.mijia.app.eu`
- SHA-256: `2F189C0D3A6C9965036EDDBFA927EB7FD720C47D611991EB5EC1D1055E89B887`
- Signing certificate SHA-256: `BE7E580BAE6723900DD30952B1DF215B282B445BCADAFC621C03B8D9CF81A1BD`

The exact file above is the only release candidate. Do not publish or redistribute a debug, unsigned, or differently signed build under the same version.

## Why the version is now 2.0.0

The original European app ended at version 1.1.0. Community builds through 1.1.9 established compatibility and restored complete physical operation with the dashcam. Version 2.0.0 marks the larger generational change from an old cloud-account-gated app to a local, accountless compatibility build, and adds a new repeated-connection hardening pass.

Version 1.1.9 remains the historical hardware-accepted baseline. The complete physical test with a Poco F6, Android 16 / HyperOS 3, and the EU `MJXCJLY01BY` passed camera connection, visible live preview, sustained responsiveness, recording list and thumbnails, download, and replay.

## Signing-key transition

Version 2.0.0 uses a new release signing key and begins a new signing lineage. Android therefore cannot install it as an upgrade over Xiaomi's stock app or any community 1.1.x build. Users must save anything they need and uninstall the existing app before installing 2.0.0; uninstalling clears the existing app's local data.

Every future 2.0.0+ release must use this same new key so Android can upgrade releases within the new lineage. Its verified certificate fingerprint is recorded above.

## Changes since 1.1.9

### Mi-account removal completed

- Removed the legacy login activity from the manifest and DEX.
- Removed the bundled Xiaomi account SDK bytecode and Xiaomi auth-service interface bytecode used by the old sign-in flow.
- Removed the remote-profile client and callback.
- Kept startup on a tokenless local profile displayed as `Offline account` / `No Mi account connected`.
- Kept defensive sanitization that clears access tokens and avatar URLs if they appear during a later same-key 2.x migration. Moving from stock or community 1.1.x to 2.0.0 still requires an uninstall, so older app data is not carried into this signing lineage.
- Confirmed by executable-code scans that the current candidate has no Xiaomi account endpoint, auth-service interface, login-activity, access-token starter, OAuth-authorizer, or OAuth app-ID reference.

### Repeated camera connection hardened

The reported problem was a hang when connecting to the camera again, not simultaneous use by two phones. Version 2.0.0 addresses that recurrent-connection path by:

- cancelling an earlier request chain tagged to the camera screen before a new connection sequence begins;
- changing the fast camera-control requests used during connection from a 10-second timeout with three hidden retries to a 4-second timeout with no hidden Volley retry;
- backporting VideoLAN's upstream asynchronous `nativeStop()` change so a stalled RTSP module cannot block Android's main thread while the preview is torn down;
- keeping recording-list and media-download timing unchanged;
- retaining the existing live-preview lifecycle cleanup and RTSP/TCP transport fix.

These changes bound failed control requests and prevent stale work from overlapping a new connection attempt. Final physical acceptance still requires repeated connect, leave, and reconnect cycles with the real `MJXCJLY01BY`.

### Version identity

- Changed the visible version label to `Version: 2.0.0`.
- Changed Android package metadata to `versionName 2.0.0` and `versionCode 20000`.
- Left the separate camera Firmware update row and its original command path unchanged.

## Inherited compatibility work

Version 2.0.0 retains the fixes already accepted in 1.1.9:

- installation on Android 15 and 16 without special install commands;
- Android 12–16 app/UI compatibility;
- ARM64 and 16 KiB native/page alignment while retaining ARMv7;
- optional Apache HTTP compatibility declaration;
- direct local camera CGI, thumbnail, recording, download, replay, and settings paths;
- RTSP/TCP live preview for the camera's RTP/JPEG stream;
- removal of the blocking UI-thread preview restart loop;
- offline Tips, Installation, FAQ, Wi-Fi help, and four bundled `MJXCJLY01BY` manuals;
- disabled obsolete application self-update prompts;
- safe media scanning and private-cache PDF handoff;
- `Patched by Void__Man` attribution above the unchanged firmware row.

## Verification status

Completed for the 2.0.0 candidate:

- exact release signing with verified v1/v2/v3 signatures and a 4096-bit RSA key;
- exact APK and signing-certificate SHA-256 fingerprints recorded above;
- `zipalign -P 16 -c 4` and AArch64 ELF load alignment at `0x10000` for all seven ARM64 libraries;
- clean signed-APK decode and unsigned round-trip rebuild;
- exact package identity, `versionCode 20000`, and `versionName 2.0.0` checks;
- four bundled manual hashes matched their reviewed source PDFs;
- structural confirmation of the reconnect cancellation and 4-second/no-retry camera-control policies;
- structural and round-trip confirmation that VLC native stop now runs outside Android's main thread;
- executable-code scan for removed Mi-account paths and a redacted sensitive-data scan over the decoded signed APK;
- clean installs on the physical Android 12 and Android 16 phones;
- visible main screen, `Version: 2.0.0`, `Offline account`, `No Mi account connected`, Add camera, every local help/manual page, and bundled PDF handoff on both physical phones;
- zero fatal exceptions or ANRs in those physical clean-install UI sequences;
- Android 15 MuMu same-debug-key candidate replacement and clean-app-data launch;
- zero fatal exceptions, ANR records, or Xiaomi-auth references in the tested MuMu launch windows.

Required before release:

- complete repeated physical connection cycles with the camera, including live preview, recording list, download, and replay after reconnecting.

See [the 2.0.0 verification report](TEST_REPORT_2.0.0.md) for the current evidence boundary and [the 1.1.9 verification report](TEST_REPORT_1.1.9.md) for the historical full hardware acceptance.

The VLC teardown change follows VideoLAN's own [2017 ANR-prevention commit](https://github.com/videolan/vlc-android/commit/1dbdcb3f3041d57ea0be07b929c3339719ade1b1). VideoLAN's tracker also documents the same main-thread stop hang after repeated players and after an RTSP source disappears from Wi-Fi.

## Installation note

Uninstall Xiaomi's stock app or any community 1.1.x build before installing 2.0.0. The fresh 2.0.0 key is intentionally different from both earlier signing lineages, so an in-place upgrade is not possible and uninstalling clears app data. Future 2.0.0+ releases must continue using the new key.
