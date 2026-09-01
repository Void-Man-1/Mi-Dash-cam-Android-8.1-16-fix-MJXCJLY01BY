# Mi Dash Cam EU 2.0.0 verification report

- Report date: 2026-09-01
- Package: `com.banyac.mijia.app.eu`
- Release-candidate version: `20000` / `2.0.0`
- Intended camera: Xiaomi Mi Dash Cam `MJXCJLY01BY`, European region
- Release status: not yet published; exact signed candidate verified; repeated-connection hardware acceptance pending

## Result at this checkpoint

The exact release-signed 2.0.0 candidate passes cryptographic verification, 16 KiB ZIP/ELF alignment, a fresh decode and unsigned rebuild, package/version checks, account-path and sensitive-data scans, and structural checks for the recurrent-connection hardening. Clean installs on physical Android 8.1, 9, 12, and 16 phones also pass startup, Offline account, Add camera, every local help/manual page, and bundled PDF handoff with no captured crash or ANR. The Android 8.1 and Android 9 phones additionally passed two cold relaunch cycles and produced no captured Xiaomi-account authentication signal.

This is not yet final hardware acceptance. The exact APK and signing-certificate hashes are recorded below, but the recurrent connection fix still requires a real-camera test consisting of repeated connect, leave, and reconnect cycles followed by media checks after reconnecting.

## Historical hardware-accepted baseline

Version 1.1.9 is the last exact signed artifact with complete physical-camera acceptance. A full test used a Poco F6 running Android 16 / HyperOS 3.0.303.0.WNPEUXM.C07 and the EU `MJXCJLY01BY`. The app connected to the camera, showed visible live preview, remained responsive, listed recordings and thumbnails, downloaded a recording, and replayed it successfully.

The 2.0.0 candidate inherits that accepted camera/media implementation and changes the account-removal and recurrent-connection areas described below. Historical results are not presented as proof that the new reconnect delta has passed hardware acceptance.

## New signing lineage

Version 2.0.0 uses a new release signing key. It cannot upgrade over Xiaomi's stock app or a community 1.1.x build; either existing app must be uninstalled first, which clears its local app data. This clean-install requirement applies to final device acceptance as well as end users.

Every future 2.0.0+ release must use the same new key to preserve in-place upgrades within the new lineage. Its verified signing-certificate SHA-256 is `BE7E580BAE6723900DD30952B1DF215B282B445BCADAFC621C03B8D9CF81A1BD`.

## 2.0.0 build and identity checks

The exact signed release candidate passed:

- Apktool build;
- fresh signed-APK decode and unsigned round-trip rebuild;
- package `com.banyac.mijia.app.eu`;
- `versionCode 20000`;
- `versionName 2.0.0`;
- `minSdkVersion 15`;
- `targetSdkVersion 28`.

Exact artifact identity:

- file: `Mi-Dash-Cam-EU-2.0.0-android12-16-arm64.apk`;
- size: 30,437,934 bytes;
- APK SHA-256: `2F189C0D3A6C9965036EDDBFA927EB7FD720C47D611991EB5EC1D1055E89B887`;
- signing-certificate SHA-256: `BE7E580BAE6723900DD30952B1DF215B282B445BCADAFC621C03B8D9CF81A1BD`;
- signer: 4096-bit RSA;
- APK Signature Schemes v1/v2/v3: verified;
- v3.1/v4: not present, as expected for this sideload release;
- `zipalign -P 16 -c 4`: passed;
- all seven ARM64 libraries are AArch64 ELF files whose load segments use `0x10000` alignment.

A debug-signed candidate was used only for local runtime smoke testing. It is not a distributable release artifact, and its checksum is intentionally omitted to prevent it from being mistaken for the final APK. Its same-key replacement behavior is not evidence that the final fresh-key release can upgrade a stock or community 1.1.x installation.

## Mi-account removal checks

The exact signed APK's fresh decoded executable tree was scanned for the old account flow. The checks found no executable reference to:

- the Xiaomi account profile endpoint;
- `com.xiaomi.account` classes;
- `IXiaomiAuthService`;
- the removed login activity;
- `startGetAccessToken`;
- `XiaomiOAuthorize`;
- `XIAOMI_APPID`.

The manifest no longer declares the login activity, Xiaomi auth-service permission, OAuth app ID, or redirect metadata. Startup and account fallbacks route to local application screens. The account page displays fixed local labels and does not request a remote profile.

Inert inherited resource names can remain, but they do not form an executable login path. The redacted scan over 5,100 decoded text files found no private-key marker, recognized cloud/developer token, JWT, bearer literal, basic-auth URL, embedded OTP assignment, or token-sensitive URL value. Known private account identifiers and verification values were absent.

## Recurrent-connection diagnosis and code checks

The reported hang occurs when trying to connect again after an earlier camera session. It is not a simultaneous two-phone connection report.

The camera screen initializes a sequence of fast control requests before live preview. The original request policy allowed a 10-second timeout and three hidden retries for each of these commands. That could keep one control request active for roughly 40 seconds before the activity's own retry handling, making a failed reconnect appear frozen.

The 2.0.0 candidate now:

- cancels earlier requests tagged to the camera screen before beginning a new connection sequence;
- applies a 4-second timeout and zero hidden retries to playback-exit, timestamp, menu/settings, preview-type, record-status, and video-mode control interactors;
- leaves recording enumeration and media-download policies unchanged;
- retains the live-preview handler cleanup, limited error restart behavior, 20-second preview startup allowance, and RTSP/TCP option;
- backports VideoLAN's upstream asynchronous `nativeStop()` implementation so the old VLC binding no longer performs a potentially unbounded RTSP stop on Android's main thread.

The VLC finding is supported by VideoLAN's own [ANR-prevention commit](https://github.com/videolan/vlc-android/commit/1dbdcb3f3041d57ea0be07b929c3339719ade1b1), which moved `nativeStop()` to a worker thread because VLC modules can hang during stop. VideoLAN issue reports independently reproduce main-thread ANRs after repeated player stops and when an RTSP source disappears from Wi-Fi.

Round-trip inspection of the exact signed artifact confirmed these policies, request cancellation, the new `Runnable`, and `Thread.start()` survived DEX rebuild. The first unavailable control stage should now reach the activity retry/error path in seconds rather than accumulating the old hidden retry delay, while a stalled native RTSP teardown can no longer directly block the UI thread. Physical timing and repeated-camera-session behavior remain to be measured with the real camera.

## Android 15 runtime smoke

MuMu Player reported Android 15. One debug candidate replaced an earlier candidate signed with the same debug key, and it was then tested after clearing only the emulator app's data.

Observed results:

- launcher activity reached the main screen;
- the screen showed `Patched by Void__Man` and `Version: 2.0.0` above the separate Firmware update row;
- Account showed `Offline account` and `No Mi account connected`;
- Add camera reached the `Turn on Wi-Fi hotspot` screen;
- fatal exceptions: 0;
- ANR records: 0;
- Xiaomi-auth references in the captured launch windows: 0.

The post-backport debug candidate was installed in place on the same Android 15 MuMu instance. Package Manager reported `primaryCpuAbi=arm64-v8a`, `versionCode=20000`, and `versionName=2.0.0`; the app launched with zero captured app fatal/ANR lines and zero Xiaomi-auth log references. MuMu cannot reproduce a physical camera disappearing during VLC teardown, so this is a verifier/launch regression check rather than proof of the hardware reconnect result.

The emulator cannot replace a real `MJXCJLY01BY` Wi-Fi and media test.

## Physical Android 12 and Android 16 clean-install smoke

The exact signed candidate was clean-installed after removing the historical 1.1.9 app from the available Samsung Android 12 and Redmi Android 16 phones. On both devices:

- Package Manager reported `versionCode 20000` and `versionName 2.0.0`;
- cold launch reached the main screen and kept the app process alive;
- `Patched by Void__Man` and `Version: 2.0.0` appeared above the unchanged Firmware update row;
- Account displayed `Offline account` and `No Mi account connected`;
- Add camera opened the Wi-Fi-hotspot guide;
- Tips, Installation, User manual, and FAQ rendered bundled local content rather than the obsolete server error page;
- the manual page exposed all four clearly named PDF links;
- the English phone-friendly link handed the bundled PDF to Android and opened it successfully;
- captured fatal exceptions: 0;
- captured ANRs: 0.

## Physical Android 8.1 and Android 9 clean-install smoke

The exact release-signed APK also passed its offline phone-side checks on two older physical phones supplied through Android Device Streaming:

| Device | Android | API | Selected ABI | Result |
|---|---:|---:|---|---|
| FUJITSU F-01L | 8.1.0 | 27 | `arm64-v8a` | Passed |
| SHARP AQUOS sense2 (`SH-01L`) | 9 | 28 | `arm64-v8a` | Passed |

On both phones:

- the exact APK SHA-256 matched `2F189C0D3A6C9965036EDDBFA927EB7FD720C47D611991EB5EC1D1055E89B887`;
- Package Manager reported `versionCode 20000`, `versionName 2.0.0`, `minSdk 15`, and `targetSdk 28`;
- clean installation and the initial cold launch passed;
- the main screen displayed `Patched by Void__Man`, `Version: 2.0.0`, and the separate unchanged Firmware update row without an obsolete application-update prompt;
- Account displayed `Offline account` and `No Mi account connected`;
- Add camera opened the `Turn on Wi-Fi hotspot` guide;
- Tips, Installation, User manual, and FAQ rendered bundled offline content;
- the manual library displayed all four bundled PDF choices;
- two additional force-stop/cold-launch cycles returned to the main screen;
- captured app crashes: 0;
- captured ANR events: 0;
- captured Xiaomi-account authentication signals: 0.

PDF behavior differed only after the app handed the bundled file to Android:

- Android 8.1/API 27 opened and rendered the selected English phone-friendly PDF;
- Android 9/API 28 displayed Android's application chooser for the selected PDF.

Android Device Streaming phones cannot join the `MJXCJLY01BY` local Wi-Fi. Camera connection, live preview, recording enumeration, download, replay, and recurrent camera-session behavior were not tested on these two phones. These results are physical app/UI regression evidence, not camera-hardware acceptance.

## Remaining final-release gates

1. With the EU `MJXCJLY01BY`, perform multiple complete camera cycles: connect, confirm live preview, leave/disconnect, reconnect, and confirm preview again.
2. After a repeated connection, enumerate recordings and thumbnails, download a recording, and replay it.
3. Confirm no fatal exception, ANR, long main-thread stall, account-auth attempt, or obsolete app-update prompt during those cycles.

Until these gates pass, 2.0.0 must be described as a release candidate. The 1.1.9 report remains the evidence for full hardware operation of the inherited camera/media baseline.
