# Poco F6 Android 16 physical-test evidence

This directory contains the privacy-redacted public evidence copy for the final Mi Dash Cam EU 2.0.0 hardware test.

## Public evidence file

- File: [poco-f6-android16-v2.0.0-full-camera-test.mp4](poco-f6-android16-v2.0.0-full-camera-test.mp4)
- Purpose: visual evidence for the representative physical-camera workflow
- Public SHA-256: `8A7DDA7D8C1ED6B80EB7E446911378E3BB547D95F3380DB4F3A726182FF25959`
- Public size: 7,323,323 bytes
- Duration: 266.000 seconds
- Video: H.264, 576 × 1280, fixed 25 fps, 6,650 frames
- Audio: none
- Strict decode: passed with zero warnings or errors

## Source recording identity

The private source recording is not committed to the repository.

- SHA-256: `91F71D11C7EED6F8ABEA23E1326359D25497185288DF43E6513B78534B05F797`
- Size: 20,298,217 bytes
- Duration: 266.219 seconds
- Frame size: 576 × 1280
- Video: H.264
- Source audio: mono AAC, effectively silent; local speech recognition returned zero speech segments

The source decoded to completion. Its original screen-recorder timing produces duplicate/non-monotonic DTS warnings when decoded into FFmpeg's null muxer, but strict H.264 frame decoding completed successfully.

## Public-copy privacy transformations

The public file is a video-only derivative. Preparation removes or redacts:

- the source audio stream;
- container metadata that is unnecessary for visual verification;
- nearby-network names and other network identifiers;
- the camera's unique connection identifier;
- identifying camera imagery, including location clues, recognizable routes, buildings, vehicles, and registration details;
- incidental personal home-screen details where visible.

These transformations protect privacy without changing the evidence boundary. The private source hash remains recorded above so the originating file can be identified independently if needed.

## Test provenance

The tester identified the test device as a Poco F6 running Android 16 / HyperOS 3 and the connected camera as the European Xiaomi Mi Dash Cam `MJXCJLY01BY`. The recording itself does not display the phone's About screen and contains no device-model metadata, so device identity comes from the accompanying test record rather than from the MP4 alone.

The tester separately confirmed that repeated camera sessions and the intended local-camera feature set passed. The public recording documents one representative connection and media session. Tester confirmation and visual proof are intentionally reported as separate evidence sources.

Camera firmware OTA was not part of acceptance and is not claimed as validated.

## Timecoded visual evidence

The fixed-frame-rate public derivative retains the source sequence and timecode positions, ending at 266.000 seconds rather than the source container's 266.219 seconds.

| Time | Visible evidence |
|---|---|
| `00:00–00:05` | App launch and patched 2.0.0 main screen. |
| `00:05–00:16` | Local Tips, Installation, User manual, and FAQ pages open without a server-error page or crash. The manual library shows four named entries. |
| `00:16–00:43` | Add-camera onboarding, Android permission handling, and camera-Wi-Fi connection. Network and device identifiers are redacted in the public copy. |
| `00:43–00:55` | Camera authorization and successful connection. |
| `00:55–01:07` | Preview initialization with an active loading indicator. |
| `01:07–01:23` | Live preview appears and updates. Privacy-sensitive camera imagery is redacted in the public copy while motion evidence is retained where practical. |
| `01:23–01:37` | Recording browser loads a populated thumbnail grid. Thumbnail imagery is privacy-redacted. |
| `01:37–01:50` | A selected camera recording plays and its timeline advances. Camera imagery is privacy-redacted. |
| `01:53–03:03` | First export/download progresses to completion and reports success. |
| `03:24–04:19` | Second export/download progresses to completion and reports success. |
| `04:19–04:26` | Playback screen remains responsive through the end of the recording. |

No application crash dialog or Android application-not-responding dialog is visible. Loading indicators remain active during preview and recording-grid initialization, and both transfer sequences show continuing percentage progress.

## Proven by the recording

- Patched version 2.0.0 launches.
- Each of the four help-menu destinations renders local content without the obsolete server-error page.
- Add-camera onboarding and Android permission handling proceed.
- One physical camera connection reaches successful authorization.
- Live preview renders and updates.
- The recording list and thumbnails load.
- A camera recording replays with an advancing timeline.
- Two export/download operations reach their success state.
- No Mi Account login is requested during the recorded camera workflow.
- No crash or Android application-not-responding dialog is visible.

## Not proven by this recording alone

- A disconnect followed by a second connection.
- Poco F6 or Android 16 identity.
- Device settings behavior.
- The short-clip recording control.
- Recording deletion.
- Opening each individual bundled PDF.
- Offline-account screen contents or stored-account-data inspection.
- Independent filesystem inspection of the exported files.
- Camera firmware OTA.

The absence of Device settings, short-clip, and delete interactions from the recording is an evidence limitation, not a recorded failure. Repeated connection and the broader intended local-camera acceptance result come from the accompanying tester confirmation. Firmware OTA remains outside the accepted scope.

## Integrity check

After the public derivative is finalized, verify its recorded identity from the repository root:

```powershell
Get-FileHash -Algorithm SHA256 -LiteralPath '.\assets\evidence\poco-f6-android16-v2.0.0-full-camera-test.mp4'
Get-Item -LiteralPath '.\assets\evidence\poco-f6-android16-v2.0.0-full-camera-test.mp4' | Select-Object Length
```
