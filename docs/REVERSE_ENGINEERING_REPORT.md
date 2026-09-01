# Reverse-engineering and compatibility report

Report date: 2026-09-01 (Europe/Warsaw)

Current generation: 2.0.0 release candidate. Version 1.1.9 is the historical exact signed artifact with complete physical-camera acceptance. Version 2.0.0 completes executable Mi-account removal and adds recurrent-connection hardening; its exact signed artifact has passed static, cryptographic, and clean-install checks, while repeated physical reconnect acceptance remains pending.

## Scope and limits

The supplied EU APK was decoded completely at the Android-package level:

- all DEX bytecode to buildable smali with Apktool;
- resources, manifest, assets, signing metadata, and packaged files;
- best-effort Java reconstruction with JADX;
- all native ELF files inventoried for architecture, dependencies, and load-segment alignment.

Compiled native libraries cannot be converted back into the developers' exact C/C++ source. They were analyzed and, where necessary, replaced with source-generation-compatible upstream binaries whose Java/JNI interface was then tested at runtime.

## Original application identity

- Package: `com.banyac.mijia.app.eu`
- Version: `1.1.0` (`versionCode 26`)
- SDK levels: minimum 15, target 23
- Native ABI: ARMv7 only
- EU channel: `mj_eu`, channel number `11`, device identifier `13`
- EU remote configuration: `https://download.70mai.asia/config/app-mijia-eu.xml`
- Xiaomi OAuth application: `L2882303761517680798`
- Xiaomi redirect: `http://xiaomi.com`

The production patch preserves the EU region/channel, package identity, remote-configuration address, camera model, and local camera protocol. Version 1.1.9 removed the Xiaomi OAuth permission, manifest activity, app-ID metadata, and redirect metadata because accountless operation was required. Version 2.0.0 also removes the old login activity, Xiaomi account SDK bytecode, auth-service interfaces, and remote-profile client/callback.

## How the app works

### Startup and identity

In the original APK, `SplashActivity` initialized application managers and opened `LoginActivity`. That activity used Xiaomi's bundled OAuth SDK, requested a Xiaomi profile from `https://open.account.xiaomi.com/user/profile`, stored the resulting record, and then opened `MainActivity`.

Version 1.1.9 changed the initialization sequence so the profile manager always returns a local, tokenless profile. A fresh installation uses the internal identifier `local-device-user`. When an existing signed-in installation is upgraded, its token and all avatar URLs are erased immediately and its display name becomes `Offline account`. The previous identifier is retained only as the GreenDAO/SQLite namespace for existing device and download records; it is hidden in the UI. The account page shows `Offline account` and `No Mi account connected` and returns before the old remote-profile request. Version 2.0.0 removes that unreachable remote-profile client and the old login implementation rather than merely leaving them dormant.

### Dash-cam discovery and pairing

The pairing guide requires location/Wi-Fi access and expects the user to join an SSID containing `midr-cardvr-v1`. It obtains the Wi-Fi DHCP gateway, falling back to `192.72.1.1` when no gateway is reported. It also uses SSID/BSSID data to bind the device record.

The app does not discover or control the camera through Xiaomi cloud transport. Camera control is direct over the phone-to-camera Wi-Fi network.

For Android 23+, the app calls `ConnectivityManager.bindProcessToNetwork()` with the selected Wi-Fi `Network`. This is important because the camera network intentionally has no internet and Android may otherwise route requests over mobile data. The manual Wi-Fi-settings flow remains available. The optional automatic-connect path uses legacy `WifiConfiguration` and hidden/reflected Wi-Fi APIs, so it is less reliable on modern Android and was not treated as the only supported path.

### Camera control and media

- Configuration commands: `http://<gateway>/cgi-bin/Config.cgi`
- Firmware upload: `http://<gateway>/cgi-bin/FWupload.cgi`
- MJPEG live view: `http://<gateway>/cgi-bin/liveMJPEG`
- RTSP variants: `rtsp://<gateway>/liveRTSP/av1`, `/v1`, `/av2`, `/av4`
- UDP listener: `0.0.0.0:49142`

The main camera screen chooses the MJPEG or RTSP URL based on the camera's reported stream type. The bundled VLC layer provides the live-stream fragment. IJK Player is used by the recorded-file/video-player paths. Camera files and short recordings are downloaded into the legacy public `DCIM`-based directory and then indexed by Android's media scanner.

Recorded-file enumeration is also local. The app sends `Config.cgi` GET requests with the directory action (`dir`/`reardir`), recording property (`Normal` or `Event`), format, a batch size of 30, starting position, and direction (`backward`). Its XML parser converts the response into file nodes. Thumbnail URLs are `http://<gateway>/thumb...`; recorded media URLs are `http://<gateway>` plus the returned file name. Playback switches the camera into Playback mode, sends periodic heartbeats, and exits that mode when finished. Export uses the app's production `DownloadServer`, writes into `DCIM/Mi Dash Cam`, and invokes Android's media scanner.

### Cloud-dependent features

The bundled EU configuration points feedback, timestamp, OTA-check, device-reporting, and agreement APIs to `https://de-api.70mai.com`. On 2026-08-28 that host did not resolve from the test environment, and the app logged `UnknownHostException`. The legacy `eu-help.70mai.com` agreement/help pages returned HTTP 502 during probes. The app's four home help routes were pages `36`, `54`, `38`, and `32`; Wi-Fi help used page `66`. Internet Archive's availability API reported no snapshots for those five exact URLs. Version 1.1.6 replaces only those help routes with bundled pages derived from Xiaomi's surviving official product/specification pages for the exact MJXCJLY01BY model and behavior recovered from this APK. Legal/privacy routes were not replaced.

The separate Xiaomi account endpoints were reachable during the original investigation, and interactive login succeeded on Android 12 and Android 15 before accountless mode was introduced. They have not been required since version 1.1.9, and version 2.0.0 removes the executable account client path. The EU remote-configuration and other 70mai endpoints remain separate from Mi account authentication. An unavailable 70mai API may still impair feedback, cloud OTA checks, reporting, or agreement pages; it does not affect the direct local camera protocol.

## Compatibility findings and fixes

### Installation target

The original targets API 23. Stock Android 15 blocks fresh installation of apps targeting below API 24. The available MuMu Android 15 image additionally sets its minimum supported target to API 28. The patch therefore targets API 28: high enough to install on that test system while minimizing behavior changes compared with a jump to API 35/36.

### Local cleartext HTTP

At target API 28, cleartext traffic is disabled by default. The dash cam requires unencrypted local HTTP, so the manifest now explicitly sets `android:usesCleartextTraffic="true"`. Removing this would break the camera's CGI and MJPEG URLs.

### Exposed file URI

Targeting API 24 or later makes an outbound `file://` URI trigger `FileUriExposedException`. The completed-download path used such a URI in `ACTION_MEDIA_SCANNER_SCAN_FILE`. Both branches of that call site were replaced with `MediaScannerConnection.scanFile()`, which performs the same media-indexing job without exposing a file URI.

### Apache HTTP runtime declaration

Version 1.1.3 exposed a target-API-28 behavior change missed by the initial startup smoke test. Opening any destination stopped `MainActivity`; `BaseProjectActivity.onStop()` then initialized `NetService`, which referenced `android.net.http.AndroidHttpClient`. Android 9 removed the Apache HTTP implementation from the default boot class path for apps targeting API 28+, producing:

`java.lang.NoClassDefFoundError: android.net.http.AndroidHttpClient`

The exception was captured on Android 15 at `NetService.java:92`, reached through `ServiceManager` and `BaseProjectActivity.onStop()`. This explains why unrelated buttons all appeared broken.

The manifest now declares `<uses-library android:name="org.apache.http.legacy" android:required="false"/>`, exactly as Android's API-28 compatibility guidance specifies. `required="false"` is necessary because the app's minimum SDK is 15. Both Android 15 MuMu and Android 16 HyperOS report that the platform library is present. No button-specific exception suppression was added.

### 64-bit and 16 KiB page support

The original APK contains only `armeabi-v7a`, and every original ELF uses 4 KiB load-segment alignment. The production APK adds:

- IJK Player ARM64 from the upstream `k0.7.5` generation, matching the bundled Java layer and reported IJK/FFmpeg generation;
- VLC Android SDK ARM64 from tag `1.9.8`, the first release in that repository to add ARM64 while retaining the same `LibVLC(ArrayList<String>)` and `nativeNew(String[])` JNI contract used by Xiaomi's APK.

The app's original `libcompat.7.so` is byte-for-byte identical to the VLC 1.9.8 ARMv7 copy, further tying the bundled code to that upstream generation. The replacement ARM64 libraries all use `0x10000` load alignment and passed actual construction/native-call/release probes.

The original ARMv7 libraries remain for the Note10+ and other older devices. Their 4 KiB alignment is expected and is not used when Android selects the ARM64 ABI.

### Android 16 local-network behavior

Android 16's local-network permission model is opt-in for apps below the future target threshold. Keeping target 28 and the existing `INTERNET`, Wi-Fi-state, Wi-Fi-change, multicast, and location permissions preserves the legacy local-network access model. Raising the target to the newest level without a larger permission and storage migration would create avoidable breakage.

### Unavailable help service

Tips, Installation, User manual, FAQ, and the setup flow's Wi-Fi helper originally loaded five `eu-help.70mai.com` pages that returned 502 during testing. The default configuration now uses local `file:///android_asset/help/` pages. The four home-button call sites and the setup Wi-Fi-help call site also use those local URLs directly.

Version 1.1.6 additionally maps legacy page IDs `36`, `54`, `38`, `32`, and `66` inside both packaged WebView activity namespaces. The mapping uses URL substring checks, so cached or remotely supplied `http`/`https` variants and URLs with query strings are redirected to the matching bundled page before a network request can reproduce the 502 response. Agreement and privacy URLs remain original because substituting unrecovered legal text would be unsafe.

The offline pages identify the exact model and separate Xiaomi-published specifications/installation guidance from app-derived Android troubleshooting. Version 1.1.9 bundles four reviewed MJXCJLY01BY PDFs directly in the APK: English phone-friendly, English complete landscape, Russian phone-friendly, and Russian original landscape. Each is named explicitly at the top of the User manual page.

Local PDF links are intercepted before the legacy WebView can render them. The opener accepts only the four safe asset names, copies the selected asset to `cache/manuals`, obtains a content URI from a non-exported `FileProvider`, and sends `ACTION_VIEW` with MIME type `application/pdf` plus a temporary read grant. The provider exposes only the private manual-cache directory. All four packaged PDF hashes match their reviewed sources exactly.

### Live-preview freeze and retry loop

The main camera screen uses Xiaomi's packaged VLC fragment for RTSP live preview. The original fragment scheduled a five-second timeout. If the first frame had not arrived, its handler synchronously stopped the native player on the main thread and opened a new one, up to three cycles. The error callback followed the same stop/recreate path. This could block input dispatch during native teardown and continually reset a stream that needed longer than five seconds to negotiate.

A controlled Android 16 test made the failure mechanism observable. VLC initially attempted RTSP over UDP; the MediaMTX server then recorded VLC tearing down that transport and establishing a working TCP reader after approximately 11 seconds. The original five-second restart therefore occurred before VLC's successful fallback and could repeat while Android reported the app as unresponsive.

Version 1.1.6 changes the startup timeout to 20 seconds, removes synchronous VLC `stop()` calls from timeout and error callbacks, and removes automatic player recreation from those callbacks. Failure is reported once, pending handler work is canceled on load/reload/stop, and ordinary one-time lifecycle cleanup remains. The loading indicator is cleared as soon as playback begins; its buffer threshold was also reduced from 95 percent to 1 percent so a live stream does not leave a permanent spinner while frames are rendering. Camera stream URLs, commands, and codec libraries were not changed.

### Black live-preview transport

The remaining black preview was traced to transport selection rather than an H.264 decoder problem. The app first requests `Camera.Preview.RTSP.av` from the camera's `Config.cgi` endpoint. Its response selects one of four fixed paths; value `1`, used for the audio/video preview, maps to `rtsp://<gateway>/liveRTSP/av1`. Protocol captures published for this MStar/Mi camera family identify that session as RTP `video/JPEG`, and the local reproduction independently confirmed the same VLC/live555 media description and MJPEG decoder path.

`VlcVideoViewer.setVideoURI()` read the `_rtsp_tcp` preference but discarded its result and never supplied a per-media or LibVLC transport option. Consequently the old live555 stack could establish RTSP control while attempting RTP media on separate UDP sockets. That is fragile on modern Android/OEM networking and is consistent with a permanently black SurfaceView even though the RTSP control session exists.

Version 1.1.7 adds the official VLC live555 option `--rtsp-tcp` to the existing LibVLC instance options. This forces RTP to be interleaved inside the RTSP TCP connection and avoids the unused preference path without changing the camera URL, CGI command, codec, or region. An Android 15 diagnostic using the production player code and a 1920x1080/30 RTP `video/JPEG` source logged `Transport: RTP/AVP/TCP;unicast;interleaved=0-1`, `codec (mjpeg) started`, successful input opening, `Received first picture`, and continuing video-output activity.

### Recurrent-connection hang

A later real-use report identified a hang when trying to connect to the camera again after an earlier session. The report does not describe simultaneous connections from multiple phones.

The camera screen begins with a staged chain of fast control requests: exit playback mode, read timestamp, retrieve menu/settings, retrieve preview type, read recording status, and set video mode when required. Those requests inherited a Volley policy of a 10-second timeout, three hidden retries, and a 1.0 backoff multiplier. A single unavailable command could therefore remain active for roughly 40 seconds before the activity's own retry path, and an old tagged request could still overlap a newly started connection sequence.

Version 2.0.0 cancels earlier requests tagged to the camera screen before starting a new sequence. It also gives those six fast control interactors a 4-second timeout and zero hidden retries. Recording enumeration and media-download timing are deliberately unchanged. Round-trip inspection confirms that the cancellation and request policies survive DEX rebuild. This bounds the failure path in code, but the final signed artifact still needs repeated connect, leave/disconnect, and reconnect cycles with the physical `MJXCJLY01BY` before the issue can be marked hardware accepted.

### Obsolete application-update prompt

The app contains two application-update dialogs: a blocking update and a recommended update. Both depend on the now-unavailable legacy 70mai application-update service. They are separate from `DeviceUpdateActivity`, the dash-cam firmware-upload endpoint, and the camera settings entry for firmware update.

Version 1.1.7 and later short-circuit only those two APK-update dialog entry points. Camera pairing, camera commands, and the device firmware-update path remain intact. Android 12, 15, and 16 launch checks confirm that the current version reaches `MainActivity` without either obsolete prompt.

### Offline account mode

The original account requirement was an application gate, not a camera-protocol dependency. Discovery, pairing, configuration, live view, file enumeration, thumbnails, downloads, replay, and firmware upload all use the phone-to-camera Wi-Fi connection. The stored `userId` was also used as a local database partition key, which is why simply deleting the profile would hide existing paired cameras.

Version 1.1.9 replaced the authentication state without discarding the local namespace:

- the profile getter synthesizes and persists a local profile on a fresh install;
- every profile write clears the access token and all avatar fields and forces the visible name `Offline account`;
- an upgraded profile retains only its former identifier for local database lookup;
- the Account page hides that identifier, shows `No Mi account connected`, and skips the Xiaomi profile request when the token is empty;
- the cloud error handler no longer clears the profile or opens login for error `500001`;
- the status-reporting, OTA, agreement, and privacy call sites overwrite their legacy `xiaomiId` parameter with `offline-local`; only local database/device-manager calls retain a migrated historical identifier;
- the manifest no longer requests `com.xiaomi.permission.AUTH_SERVICE`, declares Xiaomi `AuthorizeActivity`, or contains `XIAOMI_APPID` / `XIAOMI_REDIRECT_URL` metadata.

Version 2.0.0 then removes the login activity, Xiaomi account SDK bytecode, Xiaomi auth-service interface bytecode, remote-profile client, and callback. Executable-code scans find no Xiaomi account endpoint, account SDK class, auth-service interface, login activity, access-token starter, OAuth authorizer, or OAuth app-ID reference. Inert inherited resource identifiers can remain without providing an executable login path.

A clean-install 1.1.9 packet capture covering launch, Account, My dash cam, and Settings contained no Mi/Xiaomi account DNS lookup and no cleartext authorization, cookie, token, or user-ID value. One lookup for the separate non-account host `de-api.70mai.com` remained, so the application is accountless but not network-air-gapped. The exact signed 2.0.0 tree then passed executable auth-path and redacted sensitive-data scans: known private account identifiers and verification values were absent, and no embedded token or executable Mi-account implementation was found. A repeat dynamic trace remains appropriate during final camera acceptance.

## Exact current-generation changes

1. `targetSdkVersion`: 23 to 28.
2. `versionCode`: 26 to 20000.
3. `versionName`: `1.1.0` to `2.0.0`.
4. Manifest application attribute: `android:usesCleartextTraffic="true"`.
5. Manifest optional platform library: `org.apache.http.legacy`.
6. Media scan: exposed broadcast URI replaced by `MediaScannerConnection.scanFile()`.
7. Added seven `arm64-v8a` libraries: IJK FFmpeg/player/SDL and VLC anw/compat/core/JNI.
8. Added bundled offline Tips, Installation, User manual, FAQ, Wi-Fi help, and shared responsive styling; routed the corresponding buttons locally and added stale legacy-URL fallbacks in both WebView namespaces.
9. Bundled four clearly named MJXCJLY01BY manuals and added a private-cache/FileProvider PDF-opening path restricted to those assets.
10. Changed VLC preview startup handling from a five-second, main-thread stop/recreate loop to a 20-second, single-failure path without synchronous teardown; canceled pending callbacks and corrected spinner clearing.
11. Added VLC's `--rtsp-tcp` instance option so the camera's RTP/JPEG preview is interleaved over the RTSP TCP connection.
12. Disabled only the obsolete blocking/recommended application-update dialogs; the separate camera firmware-update path is unchanged.
13. Added accountless local-profile creation, credential/avatar sanitization, offline account labels, remote-profile suppression, and cloud-expiry hardening.
14. Removed the Xiaomi auth permission, authorization activity, OAuth app-ID metadata, and redirect metadata from the manifest.
15. Added the non-clickable `Patched by Void__Man` and version labels above the unchanged clickable firmware row.
16. Removed the unreachable login activity, Xiaomi account SDK/auth-service bytecode, and remote-profile client/callback.
17. Added request-chain cancellation before a new camera connection sequence and applied a 4-second/no-hidden-retry policy to the six fast camera-control interactors.
18. Backported VideoLAN's upstream asynchronous `nativeStop()` implementation so a stalled RTSP input teardown cannot block Android's main thread during recurrent connection cycles.
19. Version 2.0.0 starts a fresh signing lineage. It uses a new release certificate rather than Xiaomi's certificate or the historical community 1.1.x certificate; existing installations must be removed before 2.0.0 is installed.

No EU region switch, analytics change, certificate-pinning bypass, camera-command change, stream-URL change, or camera-cloud substitute was made. Authentication removal is explicit and limited to replacing the obsolete Mi account gate with a tokenless local profile. Local device records can be retained between later same-key 2.x upgrades; uninstalling stock or community 1.1.x before 2.0.0 clears those older app records.

## Verification evidence

### Static

- The exact signed 1.1.9 baseline round-trip decoded successfully with Apktool 3.0.3.
- Its manifest reports target 28, version code 36, expected package, optional `org.apache.http.legacy`, and both native ABIs.
- Its `apksigner` v1/v2/v3 verification and `zipalign -P 16 -c 4` checks pass.
- All seven ARM64 ELF files are AArch64 and report maximum `PT_LOAD p_align` of `0x10000`.
- The 1.1.9 signed-artifact round trip contains the account sanitizer, offline labels, removed OAuth manifest entries, four manual assets and safe PDF opener, separated attribution/firmware layout, local help routes, VLC timeout/spinner/TCP changes, and application-update gate changes, with no playback-smoke/test-harness markers.
- Each packaged 1.1.9 manual matches its reviewed source SHA-256 exactly.
- Historical 1.1.9 SHA-256: `2EEA8D5655AB610B3C476064BB7EDAEC0CA73BF98818DC9D8EB5F27B39A8D7BC`.
- Historical 1.1.9 signing certificate SHA-256: `08F22E51D761F5B0A1878E9E0D4ABA8060D08EDB3BD21551AD040EC40CDFAFD9`.
- The exact signed 2.0.0 release candidate freshly decodes and rebuilds unsigned with package `com.banyac.mijia.app.eu`, version code 20000, version name `2.0.0`, minimum SDK 15, and target SDK 28.
- Its round-trip contains the six 4-second/no-hidden-retry control policies and the camera-screen request cancellation.
- Its executable tree has zero references to the old account endpoint, Xiaomi account SDK, auth-service interface, login activity, access-token starter, OAuth authorizer, and OAuth app ID.
- Its v1/v2/v3 signatures, 16 KiB ZIP alignment, and all seven AArch64 libraries' `0x10000` load alignment verify successfully.
- All four packaged manuals match their reviewed source hashes, and the redacted scan over 5,100 decoded text files found no private-key marker, recognized cloud/developer token, JWT, bearer literal, basic-auth URL, embedded OTP assignment, or token-sensitive URL value.
- Fresh-key 2.0.0 APK SHA-256: `2F189C0D3A6C9965036EDDBFA927EB7FD720C47D611991EB5EC1D1055E89B887`.
- Fresh 2.0.0 signing-certificate SHA-256: `BE7E580BAE6723900DD30952B1DF215B282B445BCADAFC621C03B8D9CF81A1BD`.

The 1.1.9 v1 verifier warns that `META-INF/LICENSE` is not covered by the old JAR-entry signature. This is inherited packaging behavior; v2/v3 cover the APK as a whole, and verification passes.

### Runtime

Android 15/API 35 MuMu:

- installation passed with target 28;
- package manager selected `primaryCpuAbi=arm64-v8a`;
- IJK 0.7.5 native construct/release probe passed;
- VLC native construct/version/release probe passed and returned `3.0.0-git Vetinari`;
- the diagnostic probe was removed from production;
- the clean production APK upgraded successfully and displayed Splash, Login, and then MainActivity with the retained login state and no fatal logs;
- interactive Xiaomi login was also reported successful by the user;
- the captured version-1.1.3 Add-camera crash was reproduced as `NoClassDefFoundError: android.net.http.AndroidHttpClient`;
- version 1.1.4 then opened Add camera, Profile, Tips, Installation, User manual, and FAQ without any `FATAL EXCEPTION`;
- a test-only wrapper invoked the unmodified production IJK implementation with a controlled H.264/AAC file through prepare, first audio/video frame, rendering start, and completion;
- version 1.1.5 installed over the diagnostic build and displayed the retained-login `MainActivity`.
- the version-1.1.7 production VLC code was exercised with a camera-representative 1920x1080/30 MJPEG stream published as RTP `video/JPEG` through MediaMTX;
- VLC negotiated `RTP/AVP/TCP;unicast;interleaved=0-1`, started its MJPEG decoder, opened the RTSP input, received its first picture, and continued feeding video output without a fatal exception or ANR. MuMu's screenshot path captured the SurfaceView as black because it is a hardware overlay; the decoder/video-output log is retained as the objective playback evidence.
- the signed production 1.1.7 APK then upgraded MuMu's installed 1.1.5 build in place, retained the logged-in state, and resumed `MainActivity` without a fatal exception, ANR, or obsolete update dialog during the launch smoke window.
- version 1.1.9 was then installed after clearing only MuMu's app data. It reached `MainActivity` without interactive login. The decrypted persisted profile had an empty token, empty avatar fields, the local identifier `local-device-user`, and visible name `Offline account`;
- the Account page displayed `Offline account` and `No Mi account connected`, with zero account-auth log hits and no fatal exception or ANR;
- all four manual cards copied the expected PDF into private cache with matching hashes, and the attribution/version block remained non-clickable above the separate firmware row;
- a packet capture of launch, Account, My dash cam, and Settings recorded no Mi/Xiaomi account DNS lookup or cleartext credential value. A separate `de-api.70mai.com` DNS query confirms that accountless operation is not the same as total network isolation.
- the debug-signed 2.0.0 candidate installed as an in-place emulator upgrade and then clean-launched after clearing only MuMu's app data;
- the main screen displayed `Patched by Void__Man` and `Version: 2.0.0`, Account displayed `Offline account` / `No Mi account connected`, and Add camera reached the hotspot guide;
- captured 2.0.0 launch windows contained zero fatal exceptions, ANR records, or Xiaomi-auth references. This is a runtime smoke check, not a physical camera or final-signature acceptance.

Android 16/API 36, HyperOS `OS3.0.4.0.WNTEUXM`, Redmi 13C (`24040RN64Y`):

- version 1.1.6 installed in place as a same-signature update; the existing application user/first-install state and Xiaomi login were retained;
- package manager selected `primaryCpuAbi=arm64-v8a`;
- Add camera proceeded through `Turn on Wi-Fi hotspot` and `Connect to Wi-Fi hotspot` on the clean production build without the original crash;
- Profile opened `UserCenterActivity` without a fatal exception;
- the actual Tips, Installation, User manual, and FAQ buttons each opened the packaged WebView activity and visually rendered bundled content; no fatal exception, ANR, 502 page, or other WebView network error occurred;
- the User manual page visibly rendered the new complete-manual link at its top; tapping it handed the URL to Brave, which rendered all four PDF pages. Mi Dash Cam produced no fatal exception or ANR during the handoff;
- a test-only wrapper invoked the unmodified production IJK implementation and decoded/rendered H.264/AAC to the display; playback was visually verified;
- the wrapper supplied a localhost HTTP URL served by the PC through ADB reverse, then exercised the real `VideoPlayerActivity`, camera-gateway URL construction, IJK HTTP input, export UI, production downloader, storage-permission flow, and media scanner;
- export created `/sdcard/DCIM/Mi Dash Cam/playback-smoke-long.mp4`; Android indexed it, and the device file exactly matched the served source at 2,271,966 bytes and SHA-256 `E80E5FBCCCA8150578C24BB300BA7306D3EE8CF12CE114EDA85F2BEA9BD7939C`;
- a separate diagnostic package exercised the version-1.1.6 VLC fragment against an H.264/AAC RTSP stream published by FFmpeg to MediaMTX through ADB reverse. VLC fell back from UDP to a working TCP reader after approximately 11 seconds, the activity stayed focused and responsive, and Android's SurfaceView compositor logged approximately 29.95–30.45 frames per second without a fatal exception or ANR;
- an initial capture showed the color-bar stream rendering; after the spinner correction, compositor logs again confirmed continuous rendering and the capture confirmed that the spinner was absent (the hardware-overlay SurfaceView itself appeared black in that ADB screenshot);
- diagnostic wrappers were replaced by clean production version 1.1.6, and the signed artifact round-trip contains no harness markers;
- before the version-1.1.6 preview patch, the physical camera connected successfully on this phone, its recording list and thumbnails loaded, a recording downloaded, and the downloaded recording replayed successfully. These are real-camera file-operation passes, but they do not prove the patched live-preview behavior;
- Firmware update produced no usable update result and stayed on MainActivity, consistent with the unavailable legacy backend, but did not crash.
- version 1.1.7 installed over 1.1.6 with the same release certificate, retained package data, and launched `MainActivity` without a fatal exception or ANR during the launch smoke window;
- the obsolete application-update dialog did not appear in the version-1.1.7 launch screenshot or log.
- version 1.1.9 installed in place over the legacy signed-in state, sanitized it, and displayed `Offline account` / `No Mi account connected` without an auth log hit, fatal exception, or ANR;
- the User manual page displayed all four bundled manuals. Adobe Reader opened the app-private content URI and rendered the English phone-friendly manual;
- the main screen displayed the attribution and version above the unchanged separate Firmware update row.
- after removing 1.1.9, the exact fresh-key 2.0.0 APK clean-installed with package metadata `20000` / `2.0.0`;
- the 2.0.0 clean install reached Main, displayed its attribution/version and fixed Offline account, opened Add camera, visually rendered every bundled help/manual page, and handed the English phone-friendly PDF to Android;
- that exact 2.0.0 UI sequence produced zero captured fatal exceptions or ANRs.

Android 12 / One UI 4.1 Note10+:

- interactive Xiaomi login had completed successfully on an earlier same-signature build;
- version 1.1.6 then installed in place through ADB, retaining the existing application user/first-install state and login;
- `MainActivity` launched without a startup fatal exception or ANR;
- the actual Tips, Installation, User manual, and FAQ buttons each opened bundled content without a fatal exception, ANR, or 502 response;
- the User manual page visibly rendered the new complete-manual link at its top; tapping it handed the URL to Brave, which downloaded `MJXCJLY01BY.pdf`. Mi Dash Cam produced no fatal exception or ANR during the handoff.
- version 1.1.7 installed in place with the same release certificate, retained package data, and launched `MainActivity` without a fatal exception, ANR, or obsolete application-update dialog during the launch smoke window.
- version 1.1.9 installed in place over the legacy signed-in state, sanitized it, and displayed `Offline account` / `No Mi account connected` without an auth log hit, fatal exception, or ANR;
- Samsung Notes rendered the bundled English phone-friendly PDF from the scoped app content URI, and the main-screen attribution/version placement matched the Redmi and MuMu layout.
- after removing 1.1.9, the exact fresh-key 2.0.0 APK clean-installed with package metadata `20000` / `2.0.0`;
- the 2.0.0 clean install reached Main, displayed its attribution/version and fixed Offline account, opened Add camera, rendered every bundled help/manual page, and opened the English phone-friendly PDF in Samsung's reader;
- that exact 2.0.0 UI sequence produced zero captured fatal exceptions or ANRs.

Selected version-1.1.9 Android 14 and 16 account, manual, setup, and layout screenshots are published under [`assets/screenshots`](../assets/screenshots). The complete Android 12/14/15/16 device evidence, raw packet capture, and media diagnostics remain in the private engineering workspace so device identifiers and unreviewed captures are not published accidentally.

## Hardware acceptance boundary

A complete end-to-end physical test was conducted with the exact version-1.1.9 APK, a Poco F6 running Android 16 / HyperOS 3.0.303.0.WNPEUXM.C07, and the EU MJXCJLY01BY. Camera connection, visible live preview, sustained responsiveness, recording enumeration and thumbnails, recording download, and replay all passed.

Version 1.1.9 is therefore end-to-end hardware accepted for the supported Poco F6/MJXCJLY01BY combination. A BlueStacks 5 Android 13 Beta/API-33 instance additionally passed clean launch, Offline account, local Tips/manuals, and Add-camera navigation with no fatal exception or ANR; its virtual network was not treated as a physical camera-Wi-Fi test. Two physical Android Device Streaming phones—a Galaxy S24 and S24 Ultra on Android 14/API 34—then passed clean ARM64 install, cold launch, accountless UI, all local help/manual routes, PDF handoff, and Add-camera navigation with no crash or ANR record. Their remote data-centre networking cannot reach the local camera Wi-Fi, so camera transport on Android 14 remains unclaimed. Camera firmware update remains a separate high-risk path because the old cloud OTA service is externally controlled and may be unavailable.

Version 1.1.9 is ARM64/16-KiB-ready, starts accountlessly, sanitizes legacy accounts, opens all four bundled manuals, suppresses the obsolete app-update prompt, and restores the MJPEG/RTP/TCP live preview together with recording list, download, and replay on the physical camera.

Version 2.0.0 inherits that accepted implementation and adds complete executable auth-code removal plus recurrent-connection hardening. Those deltas have passed exact signed-artifact inspection and physical Android 12/16 clean-install UI checks, but 2.0.0 is still a release candidate. It must not be called hardware accepted until the exact signed APK completes repeated physical connect, leave/disconnect, and reconnect cycles, followed by live preview, recording list, download, and replay checks after reconnecting.

## Research sources

- Android 15 installation restriction: https://developer.android.com/about/versions/15/behavior-changes-all
- Android 9/API-28 Apache HTTP compatibility declaration: https://developer.android.com/about/versions/pie/android-9.0-changes-28
- Android 16 migration guidance: https://developer.android.com/about/versions/16/migration
- Android 16 local-network protections: https://developer.android.com/privacy-and-security/local-network-permission
- Android 16 behavior changes and page compatibility: https://developer.android.com/about/versions/16/behavior-changes-all
- Android 16 KiB page-size guidance: https://developer.android.com/guide/practices/page-sizes
- Android ANR diagnosis and input-dispatch guidance: https://developer.android.com/topic/performance/anrs/diagnose-and-fix-anrs
- Android WebView external-link handling: https://developer.android.com/develop/ui/views/layout/webapps/webview
- Poco F6 EU ROM listing used by the request: https://miuirom.org/phones/poco-f6
- Xiaomi Poco F6 hardware FAQ: https://www.mi.com/global/support/faq/details/KA-165333/
- Xiaomi global product declaration identifying Mi Dash Cam as model MJXCJLY01BY: https://www.mi.com/global/support/terms/declaration/
- Xiaomi official MJXCJLY01BY product/installation page: https://www.mi.com/mj-carcorder
- Xiaomi official MJXCJLY01BY specifications: https://www.mi.com/mj-carcorder/specs
- Four-page Russian MJXCJLY01BY manual used as the reviewed bundled source: https://mi-house.ru/asserts/instructions/3516/1/MJXCJLY01BY.pdf
- IJK Player upstream tag `k0.7.5`: https://github.com/bilibili/ijkplayer/tree/k0.7.5
- VLC Android SDK tag `1.9.8`: https://github.com/mrmaffen/vlc-android-sdk/tree/1.9.8
- VideoLAN asynchronous native-stop ANR fix: https://github.com/videolan/vlc-android/commit/1dbdcb3f3041d57ea0be07b929c3339719ade1b1
- VideoLAN repeated-stop ANR report: https://code.videolan.org/videolan/vlc-android/-/issues/172
- VideoLAN RTSP/Wi-Fi stop hang report: https://code.videolan.org/videolan/vlc-android/-/issues/2641
- VLC live555 source defining the `--rtsp-tcp` option: https://github.com/videolan/vlc/blob/3.0.0/modules/access/live555.cpp
- Community capture of the exact Mi Dash Cam app/device RTSP session identifying `video/JPEG`: https://gist.github.com/azrael8576/4848a145e45bfe1a436703cf25e259b8
- MStar dash-cam protocol mapping for `Camera.Preview.RTSP.av`: https://www.viidure.com/opendoc/pages/base/mstar.html
- MediaMTX FFmpeg publishing guide: https://github.com/bluenviron/mediamtx/blob/main/docs/3-publish/17-ffmpeg.md
- MediaMTX RTSP-client guide: https://github.com/bluenviron/mediamtx/blob/main/docs/3-publish/07-rtsp-clients.md
