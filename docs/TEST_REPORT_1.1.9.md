# Mi Dash Cam EU 1.1.9 verification report

Historical status: this report covers the exact signed hardware-accepted baseline. The current 2.0.0 candidate and its still-pending repeated-connection hardware gate are documented in [`TEST_REPORT_2.0.0.md`](TEST_REPORT_2.0.0.md).

- Date: 2026-08-31
- Release: `Mi-Dash-Cam-EU-1.1.9-android16-arm64.apk`
- Package: `com.banyac.mijia.app.eu`
- Version: `36` / `1.1.9-android16-eu9`

## Result

The exact signed release passes post-sign decode, package identity, signature, ZIP alignment, ARM64 ELF alignment, accountless startup, legacy-account sanitization, offline account UI, bundled-manual, footer-layout, Android 12/13/14/15/16 smoke checks, and final Poco F6 real-camera acceptance.

No Mi/Xiaomi account authentication was observed during fresh startup and ordinary account/device/settings navigation. The profile stored by the app has an empty token and avatar fields and is visibly identified as `Offline account` / `No Mi account connected`.

A complete end-to-end physical test was conducted with the exact release, a Poco F6 running Android 16 / HyperOS 3.0.303.0.WNPEUXM.C07, and the EU MJXCJLY01BY. Camera connection, visible live preview, sustained responsiveness, recording list/thumbnails, download, and replay all passed.

## Release identity

- APK SHA-256: `2EEA8D5655AB610B3C476064BB7EDAEC0CA73BF98818DC9D8EB5F27B39A8D7BC`
- Signing certificate SHA-256: `08F22E51D761F5B0A1878E9E0D4ABA8060D08EDB3BD21551AD040EC40CDFAFD9`
- APK signature schemes v1/v2/v3: verified
- v3.1/v4: not present, as expected for this local sideload release
- `zipalign -P 16 -c 4`: passed
- `minSdkVersion`: 15
- `targetSdkVersion`: 28
- Native ABIs: `arm64-v8a`, `armeabi-v7a`
- All seven ARM64 ELFs: AArch64, maximum `PT_LOAD p_align=0x10000`
- Post-sign audit tree: `audit/roundtrip/final-eu9-audit-20260831`

`apksigner` emits the inherited JAR-signature warning that `META-INF/LICENSE` is not individually covered by v1. The APK-wide v2 and v3 signatures cover the file, and all requested signature verifications pass.

## Post-sign package audit

The signed APK was decoded with Apktool 3.0.3. The decoded artifact confirms:

- package `com.banyac.mijia.app.eu`, version code 36, version name `1.1.9-android16-eu9`;
- no `com.xiaomi.permission.AUTH_SERVICE` permission;
- no Xiaomi `AuthorizeActivity` manifest component;
- no `XIAOMI_APPID` or `XIAOMI_REDIRECT_URL` manifest metadata;
- a non-exported `FileProvider` scoped to `cache/manuals`;
- the profile getter always returns a local profile;
- the profile writer clears the access token and every avatar field and writes `Offline account`;
- the account page displays `Offline account` and `No Mi account connected` for a tokenless profile and returns before remote profile refresh;
- all five reachable legacy network call sites that label a value `xiaomiId` overwrite it with `offline-local`, while local database/device lookups retain the migrated namespace;
- cloud error `500001` no longer clears the local profile or opens login;
- four local manual cards, all four PDF assets, the safe PDF opener, and the WebView interception hook;
- a 48 dp non-clickable attribution/version block above the original separate, clickable 56 dp firmware row;
- the retained `liveRTSP/av1` route and VLC `--rtsp-tcp` option;
- both obsolete application-update dialog entry points remain short-circuited;
- no diagnostic, MediaMTX, mock-camera, or test-only marker in manifest, smali, or non-PDF assets.

Unused Xiaomi SDK and login classes remain in the original DEX namespace, but the production manifest has no authorization entry point or OAuth client metadata and normal startup always receives the tokenless local profile.

## Offline-account runtime checks

### Fresh Android 15 install

MuMu Player was used as a clean-install test subject. App data was cleared, the exact 1.1.9 APK was installed, and the launcher activity was started.

- The app reached `MainActivity` without interactive login.
- Decryption of the app's stored `user_profile_v2` value showed:
  - token empty: yes;
  - visible name: `Offline account`;
  - fresh local identifier: `local-device-user`;
  - every avatar field empty: yes.
- The Account page showed `Offline account` and `No Mi account connected`.
- Account-auth log hits: 0.
- Fatal exception or ANR: 0.

Evidence: `evidence/releases/1.1.9/mumu-fresh-android15/`

### Fresh BlueStacks Android 13 install

A newly created BlueStacks 5 `Tiramisu64` instance reported Android 13/API 33 and ABI support for `x86_64`, `x86`, `arm64-v8a`, `armeabi-v7a`, and `armeabi`. The exact release installed successfully with `primaryCpuAbi=arm64-v8a`.

- Cold launch reached `MainActivity` and kept the process alive.
- Main-screen attribution/version and the separate Firmware update row rendered correctly.
- Profile showed `Offline account` and `No Mi account connected`.
- Bundled Tips and User manual pages rendered locally.
- Add camera opened `StepOneActivity`.
- Fatal exception or ANR hits for each tested step: 0.

BlueStacks uses virtual networking, so this pass verifies Android-13 installation, startup, accountless UI, offline content, and navigation—not physical dashcam Wi-Fi/live video.

Evidence: `evidence/releases/1.1.9/bluestacks-android13/`

### Physical Android 14 Device Streaming installs

Google Android Device Streaming supplied two physical Samsung phones. Both were factory-clean remote sessions, reported Android 14/API 34 and `arm64-v8a`, and received the exact SHA-256-verified release:

| Device | Build identity | Result |
|---|---|---|
| Galaxy S24 Ultra (`SM-S928U1`, `e3q`) | Android 14/API 34, build `S928U1UES4AXKF` | Install and cold launch passed |
| Galaxy S24 (`SM-S921U`, `e1q`) | Android 14/API 34, build `S921USQS3AXFC` | Install and cold launch passed |

On each phone:

- Package Manager selected `primaryCpuAbi=arm64-v8a` and reported version `1.1.9-android16-eu9` / code 36.
- Cold launch reached `MainActivity` with the patch/version footer and no obsolete app-update prompt.
- Profile showed `Offline account` and `No Mi account connected`.
- Tips, Installation, User manual, and FAQ opened bundled local content instead of the dead 502 endpoints.
- Add camera reached `StepOneActivity` and displayed the `Turn on Wi-Fi hotspot` guide.
- The manual library displayed all four named PDFs; selecting the English phone-friendly manual produced Android's valid PDF-app resolver.
- AndroidRuntime logs, event logs, and application-exit history contained no crash or ANR. Exit records were limited to deliberate force-stops between isolated scenarios.

The hosted phones are physical devices but cannot join the MJXCJLY01BY's local Wi-Fi in the user's vehicle. This pass therefore verifies Android-14 installation, ABI selection, startup, accountless operation, local content, PDF handoff, and camera-wizard navigation—not camera transport, live preview, or recording transfer.

Evidence: `evidence/releases/1.1.9/android-device-streaming-api34/`

### Existing signed-in profile upgrade

The same-signature 1.1.9 APK was installed over previous builds on both physical phones, which still had legacy account state.

| Device | OS | Install path | Account result | Auth/fatal result |
|---|---|---|---|---|
| Samsung Galaxy Note10+ (SM-N975F) | Android 12 / One UI 4.1 | In-place upgrade | `Offline account` / `No Mi account connected` | 0 auth hits; 0 fatal/ANR |
| Redmi 13C (24040RN64Y) | Android 16 / HyperOS 3.0.4.0.WNTEUXM | In-place upgrade | `Offline account` / `No Mi account connected` | 0 auth hits; 0 fatal/ANR |

This verifies the migration path: legacy tokens and avatars are removed while the prior internal user identifier remains available only as a local device/database namespace.

Evidence:

- `evidence/releases/1.1.9/samsung-android12/`
- `evidence/releases/1.1.9/redmi-android16/`

### Network observation

A root packet capture on the clean Android 15 instance covered launch, Account, My dash cam, and Settings.

- Mi/Xiaomi account-related DNS hits: 0.
- Cleartext authorization/cookie/token/user-ID hits: 0.
- One DNS query for `de-api.70mai.com` was observed. This is a non-account 70mai legacy service host, so the app must not be described as fully network-air-gapped.

Evidence: `evidence/releases/1.1.9/mumu-fresh-android15/logs/eu9-offline-operation.pcap`

## Manual and layout checks

The four PDF assets decoded from the signed APK match their reviewed source files:

| Manual | SHA-256 match |
|---|---:|
| English translation - phone-friendly | Pass |
| English translation - complete landscape | Pass |
| Russian manual - phone-friendly | Pass |
| Russian original - complete landscape | Pass |

On MuMu, all four cards were tapped and all four expected files appeared in the app-private manual cache with matching hashes. On Samsung Android 12, Android's resolver received the scoped content URI and Samsung Notes rendered the first page. On Redmi, Adobe Reader rendered the same bundled manual. The physical Galaxy S24 Ultra Android-14 session independently displayed all four manual cards and handed the selected bundled PDF to Android's resolver. No fatal exception or ANR occurred.

The main screen on all three systems displayed `Patched by Void__Man` and `Version: 1.1.9-android16-eu9` above `Firmware update`. UI hierarchy inspection confirms that the attribution labels are not clickable and that the original firmware container remains a separate clickable 56 dp row.

## Camera-path status

Previously completed physical-camera checks on the Redmi established successful connection, recording-list and thumbnail retrieval, recording download, and downloaded replay. A production-player diagnostic also reproduced the camera's 1920x1080/30 RTP `video/JPEG` stream and verified RTSP interleaving over TCP, MJPEG decoder startup, first-picture receipt, continuing video output, and no fatal exception or ANR.

Final physical-camera acceptance was completed on the Poco F6 with the exact 1.1.9 release and the EU MJXCJLY01BY. The app connected to the camera, displayed live video, remained responsive, enumerated recordings and thumbnails, downloaded a recording, and replayed it successfully. Every tested end-to-end camera function passed.

Public device-version evidence: [`assets/screenshots/poco-f6-hyperos3-android16.jpg`](../assets/screenshots/poco-f6-hyperos3-android16.jpg)

## Remaining coverage

1. Android 13 still needs a physical-device/camera-network report. Android 14 has a physical app/UI pass but still lacks a local dashcam-Wi-Fi test.
2. Additional MJXCJLY01BY firmware versions would broaden coverage.
3. Treat camera firmware update as a separate high-risk test because the old cloud OTA service is unavailable.
