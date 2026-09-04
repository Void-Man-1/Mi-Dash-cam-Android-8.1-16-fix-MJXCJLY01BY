# Publishing checklist

## Legal and repository administration

Unchecked items in this section remain unresolved or undocumented and are not represented as complete. They are separate from the recorded technical acceptance below.

- [ ] Review `NOTICE.md` and decide what license, if any, applies to material you own.
- [ ] Confirm redistribution rights for the modified APK and any bundled vendor/manual content in the target jurisdiction.
- [x] Confirm `release-assets/*.apk` is ignored by Git.
- [x] Confirm no signing key, original APK, decoded source tree, token, device identifier, raw packet capture, or private log is staged.
- [x] Run a secret scan over every staged file.
- [x] Scan the exact final APK and its decoded tree for known private account identifiers, verification codes, access tokens, cookies, and authorization URLs with sensitive query values.
- [x] Review screenshots for account names, notifications, precise location, Wi-Fi details, and other personal information.
- [x] Verify all README links and images from the local repository root.

## Create the GitHub repository

- [x] Use the values in `docs/GITHUB_LISTING.md`.
- [x] Set the default branch to `main`.
- [x] Add the suggested topics so model-number and Android searches can find the project.
- [x] Enable Issues for structured device reports.
- [x] Leave GitHub Pages disabled; the README is the repository landing page.

## Technical acceptance for release 2.0.0

Version 2.0.0 starts a new signing lineage. It cannot upgrade over Xiaomi's stock app or community 1.1.x builds. Testers and users must uninstall the existing app first, which clears its app data. Every future 2.0.0+ release must use the same new key.

- [x] Build and sign the exact `Mi-Dash-Cam-EU-2.0.0-android12-16-arm64.apk`; do not use the debug smoke APK.
- [x] Confirm package `com.banyac.mijia.app.eu`, `versionName 2.0.0`, and `versionCode 20000`.
- [x] Confirm the APK uses the new 2.0.0 release key and record certificate SHA-256 `BE7E580BAE6723900DD30952B1DF215B282B445BCADAFC621C03B8D9CF81A1BD`.
- [x] Verify APK signatures v1/v2/v3 and 16 KiB ZIP/ELF alignment.
- [x] Decode the signed APK again and confirm the account-code removal, recurrent-connection policies, asynchronous VLC native-stop worker, offline manuals, and intended manifest.
- [x] Save any needed data, uninstall the stock or community 1.1.x app from the available physical Android 12 and Android 16 test phones, then clean-install the final signed APK and smoke-test startup, Offline account, local help/manuals, and Add camera.
- [x] Clean-install the exact signed APK on physical Android 8.1/API 27 and Android 9/API 28 phones; verify startup, Offline account, Add camera, all local help/manual routes, PDF handoff, two cold relaunches, and zero captured crash/ANR/auth signals.
- [x] Review the physical Poco F6 / Android 16 recording: it directly shows one connection to the EU `MJXCJLY01BY` and a visible live preview; the accompanying tester confirmation reports that reconnection also succeeded without the reported hang.
- [x] Confirm the recording directly shows the recording grid and thumbnails, recording playback, and two export/download operations; the tester separately confirmed that the downloads completed.
- [x] Confirm the recorded session shows no visible app crash, Android-not-responding dialog, prolonged UI freeze, or obsolete application-update prompt. Treat executable account-path scans and earlier runtime checks—not the video—as the accountless-operation evidence.
- [x] Record that camera firmware OTA was not tested and is excluded from the hardware-acceptance claim.
- [x] Calculate the final APK SHA-256 and add it to `checksums/SHA256SUMS.txt`; never publish a placeholder hash.

Technical acceptance is complete for the exact release-signed APK. See the [physical-test video](../assets/evidence/poco-f6-android16-v2.0.0-full-camera-test.mp4), [evidence notes](../assets/evidence/README.md), and [verification report](TEST_REPORT_2.0.0.md).

## Signing-key continuity

- [ ] Create and verify a secure offline backup of the new key and its recovery information for all future 2.0.0+ releases.

This open continuity task does not alter the completed test result, but losing the key would prevent future in-place updates within the 2.0.0 signing lineage.

## Publish release 2.0.0

- [ ] Create tag `v2.0.0` at the accepted source revision.
- [ ] Paste the final `docs/RELEASE_NOTES_2.0.0.md` into the GitHub Release description.
- [ ] Upload `release-assets/Mi-Dash-Cam-EU-2.0.0-android12-16-arm64.apk` as a Release asset.
- [ ] Publish the release, then test the README's GitHub Releases link in a logged-out browser.

## Never publish

- the private patch signing key or its password;
- Xiaomi's untouched original APK;
- the full private decoded/reverse-engineering workspace;
- device serial numbers, Mi tokens, cookies, account IDs, or Wi-Fi passwords;
- raw captures/logs that have not been reviewed and redacted.
