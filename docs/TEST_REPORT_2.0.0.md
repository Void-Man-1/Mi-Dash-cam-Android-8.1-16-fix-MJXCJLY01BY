# Mi Dash Cam EU 2.0.0 final verification report

- Report date: 2026-09-02
- Package: `com.banyac.mijia.app.eu`
- Version: `20000` / `2.0.0`
- Intended camera: Xiaomi Mi Dash Cam `MJXCJLY01BY`, European region
- Release status: final hardware-accepted release

## Final result

The exact release-signed 2.0.0 APK passed its build, package-identity, signature, 16 KiB alignment, account-removal, sensitive-data, clean-install, and runtime checks. A complete physical test was then conducted with the European `MJXCJLY01BY` and a Poco F6 running Android 16 / HyperOS 3.

The tester confirmed that repeated camera sessions and the intended local-camera feature set passed on that device. The app connected and connected again after earlier sessions, displayed live preview, remained responsive, enumerated recordings and thumbnails, replayed camera recordings, and completed downloads. No application crash, Android application-not-responding event, obsolete application-update prompt, or Mi Account login request was observed during the accepted workflow.

A privacy-redacted recording preserves visual evidence for one representative connection and media session. It visibly demonstrates the patched help routes, camera authorization, live updating preview, recording grid and thumbnails, playback, and two completed export/download operations. The recording does not itself show the repeated-connection sequence; that result is an accompanying tester confirmation and is not presented as a frame-visible claim.

Camera firmware OTA was not part of acceptance and is not claimed as working or validated.

## Exact release artifact

- File: `Mi-Dash-Cam-EU-2.0.0-android12-16-arm64.apk`
- Size: 30,437,934 bytes
- APK SHA-256: `2F189C0D3A6C9965036EDDBFA927EB7FD720C47D611991EB5EC1D1055E89B887`
- Signing-certificate SHA-256: `BE7E580BAE6723900DD30952B1DF215B282B445BCADAFC621C03B8D9CF81A1BD`
- Signer: 4096-bit RSA
- APK Signature Schemes v1/v2/v3: verified
- APK Signature Schemes v3.1/v4: not present
- Package: `com.banyac.mijia.app.eu`
- `versionCode`: `20000`
- `versionName`: `2.0.0`
- `minSdkVersion`: `15`
- `targetSdkVersion`: `28`
- `zipalign -P 16 -c 4`: passed
- Bundled native ABI: `arm64-v8a`
- ARM64 ELF load-segment alignment: `0x10000`

The exact APK was decoded afresh and completed an unsigned round-trip rebuild. All seven ARM64 native libraries were verified as AArch64 ELF files. The signed artifact and signing-certificate hashes above define the accepted release.

Version 2.0.0 starts a new signing lineage. It cannot install as an update over Xiaomi's stock APK or an older community-signed APK. The existing installation must be removed first, which clears that installation's local app data. Future releases in this lineage must retain the 2.0.0 signing key for in-place updates.

## Evidence record

The public evidence copy is documented in [the evidence record](../assets/evidence/README.md) and is stored at:

`assets/evidence/poco-f6-android16-v2.0.0-full-camera-test.mp4`

Its verified public identity is:

- SHA-256: `8A7DDA7D8C1ED6B80EB7E446911378E3BB547D95F3380DB4F3A726182FF25959`
- Size: 7,323,323 bytes
- Duration: 266.000 seconds
- Video: H.264, 576 × 1280, fixed 25 fps, 6,650 frames
- Audio: none
- Strict decode: passed with zero warnings or errors

The private source recording has the following immutable identity:

- SHA-256: `91F71D11C7EED6F8ABEA23E1326359D25497185288DF43E6513B78534B05F797`
- Size: 20,298,217 bytes
- Duration: 266.219 seconds
- Frame size: 576 × 1280

The public derivative is video-only, has container metadata and audio removed, and redacts nearby-network identifiers, camera identifiers, and identifying camera imagery. Those privacy transformations do not broaden the claims supported by the source recording.

## What the recording visibly demonstrates

Timecodes use the source recording sequence. The fixed-frame-rate public derivative retains those positions and ends at 266.000 seconds.

| Time | Visible result |
|---|---|
| `00:00–00:05` | The app launches and reaches the patched 2.0.0 main screen. |
| `00:05–00:16` | Tips, Installation, User manual, and FAQ each render local content without a server-error page or crash. The manual page shows four clearly named English and Russian entries; the individual PDFs are not opened in this recording. |
| `00:16–00:43` | Add-camera onboarding and Android permission handling complete, followed by connection to the camera's local Wi-Fi. |
| `00:43–00:55` | Camera authorization completes and the app reports a successful connection. |
| `00:55–01:07` | The camera screen initializes its preview. |
| `01:07–01:23` | Live windshield preview is displayed and visibly updates rather than remaining a frozen still. |
| `01:23–01:37` | The recording browser loads a populated grid with thumbnails and durations. |
| `01:37–01:50` | A selected recording opens and plays; its timeline advances and its image changes. |
| `01:53–03:03` | The first export/download progresses to completion and reports success. |
| `03:24–04:19` | A second export/download progresses to completion and reports success. |
| `04:19–04:26` | The app remains responsive on the playback screen. |

No crash dialog or Android application-not-responding dialog is visible. Preview initialization takes approximately 12 seconds and the recording grid approximately nine seconds; active loading indicators remain visible during those intervals. Both transfer sequences show continuing percentage progress.

## Visual-evidence boundary

The recording alone does not visually demonstrate:

- a disconnect followed by a second camera connection;
- the phone model or Android version;
- the Device settings screen;
- the short-clip recording control;
- recording deletion;
- opening each individual bundled PDF;
- the Offline account screen or an inspection of stored app data;
- independent filesystem inspection of the two exported files;
- camera firmware OTA.

The Poco F6, Android 16 / HyperOS 3 identity and repeated-connection result come from the accompanying physical-test record. The video does show that no Mi Account login is requested anywhere in the representative camera workflow, but it is not an account-storage forensic capture.

Device settings, short-clip capture, and deletion were not visually demonstrated in this particular recording. Their absence from the footage is an evidence limitation, not a claim that those controls failed. Firmware OTA remains outside the accepted scope and must not be inferred from the presence of its unchanged button.

## Repeated-connection fix and acceptance

The reported defect concerned a later connection attempt after an earlier camera session, not simultaneous connections from two phones. The original request policy could leave a fast camera-control request active for roughly 40 seconds because a 10-second timeout was combined with three hidden retries. Native RTSP teardown could also execute synchronously on Android's main thread.

Version 2.0.0:

- cancels earlier requests tagged to the camera screen before a new connection sequence;
- applies a four-second timeout and zero hidden retries to the fast connection-control requests;
- preserves the separate recording-enumeration and media-download policies;
- retains bounded preview-start error handling and RTSP/TCP playback;
- backports VideoLAN's asynchronous `nativeStop()` behavior so native RTSP teardown cannot directly block Android's main thread.

Static round-trip inspection confirmed that the cancellation, retry policies, new runnable, and worker-thread start survived the APK rebuild. The final Poco F6 hardware test then supplied the missing runtime acceptance: the tester confirmed repeated camera sessions completed successfully and the app remained operational.

## Account-removal verification

The freshly decoded signed APK was scanned for the removed Xiaomi-account flow. No executable reference was found to the former profile endpoint, Xiaomi account service classes, OAuth activity, token request entry point, OAuth builder, app ID, or redirect metadata. The manifest no longer declares the former login activity or Xiaomi authentication permission.

Startup and account fallbacks use local application screens. The account page displays fixed local Offline account text and does not request a remote profile. Clean-install runtime tests showed no Xiaomi-account authentication signal. A redacted scan over 5,100 decoded text files found no private-key marker, recognized cloud/developer token, JWT, bearer literal, embedded one-time code, or known private account identifier.

## Android coverage

The release target is Android 8.1 through Android 16, but the depth of testing differs by version. Full camera-hardware acceptance was conducted on Android 16. Android 10 and Android 11 remain untested.

| Android | Environment | Coverage |
|---:|---|---|
| 8.1 / API 27 | Physical FUJITSU F-01L | Exact signed APK clean install, ARM64 selection, launch, Offline account, Add camera, local help/manual library, PDF rendering, and repeated cold relaunches passed. The remotely hosted phone could not reach the local camera Wi-Fi. |
| 9 / API 28 | Physical SHARP AQUOS sense2 SH-01L | Exact signed APK clean install, ARM64 selection, launch, Offline account, Add camera, local help/manual library, Android PDF chooser handoff, and repeated cold relaunches passed. The remotely hosted phone could not reach the local camera Wi-Fi. |
| 10 | Not tested | No direct result is claimed. |
| 11 | Not tested | No direct result is claimed. |
| 12 | Physical Samsung Galaxy Note10+ | Exact signed APK clean install and app/UI regression passed. Final camera acceptance was conducted on Android 16. |
| 13 / API 33 | BlueStacks 5 emulator | Development-build app/UI smoke passed. Physical-device and camera-network behavior were not tested. |
| 14 / API 34 | Physical Samsung Galaxy S24 and S24 Ultra through Android Device Streaming | Development-build app/UI regression passed. The remotely hosted phones could not reach the local camera Wi-Fi. |
| 15 / API 35 | MuMu Player | Development-build replacement and clean-data smoke passed. Camera-network behavior was not tested. |
| 16 | Physical Redmi 13C | Exact signed APK clean install and app/UI regression passed. |
| 16 | Physical Poco F6, HyperOS `3.0.303.0.WNPEUXM.C07` | Exact release-signed APK completed final camera-hardware acceptance with the European `MJXCJLY01BY`. |

No captured app crash or ANR appeared in the physical app/UI sequences. Results from emulators and remotely hosted phones are compatibility evidence only and are not substitutes for the Poco F6 camera test.

## Final assessment

The exact signed artifact identified in this report is accepted as the final 2.0.0 release for the European Xiaomi Mi Dash Cam `MJXCJLY01BY`.

Accepted scope:

- accountless app startup and operation;
- camera connection and tester-confirmed repeated connection;
- live preview;
- recording enumeration and thumbnails;
- recording playback;
- completed export/download;
- local Tips, Installation, User manual, and FAQ content;
- bundled manual library and Android PDF handoff;
- stable operation across the documented test matrix.

Excluded scope:

- Xiaomi or camera-vendor cloud services;
- camera firmware OTA;
- unsupported camera models or regional variants;
- untested Android 10 and Android 11 behavior.
