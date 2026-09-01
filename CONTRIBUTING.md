# Contributing

This project patches a legacy binary, so a useful report needs more context than “it crashes.” Before opening an issue, confirm that the camera label says `MJXCJLY01BY` and that the European app/package is appropriate for the camera.

## Bug reports

Please include:

- phone manufacturer and exact model;
- Android version, security-patch level, and vendor skin/build number;
- app version shown above Firmware update;
- camera model and, when available, camera firmware version;
- whether this was a clean 2.0.0 install or an upgrade between later same-key 2.x releases;
- the exact steps from a cold app start;
- what you expected and what actually happened;
- a screenshot or short screen recording with personal data removed;
- whether camera Wi-Fi, recording list, download, replay, live preview, rotation/full-screen, and reconnect work independently.

Do not post Mi-account credentials, access tokens, Wi-Fi passwords, signing keys, precise location data, or unredacted packet captures.

## Acceptance priorities

The Poco F6 / Android 16 / HyperOS 3 real-camera acceptance pass is complete for the historical 1.1.9 baseline. Version 2.0.0 still needs its own repeated connect, leave/disconnect, and reconnect acceptance with the real camera. The highest-value new evidence is now:

1. repeated real-camera reconnect cycles with the exact 2.0.0 release candidate;
2. a physical Android 13 result and a local-camera/Wi-Fi Android 14 result;
3. results from additional MJXCJLY01BY firmware revisions;
4. long-duration preview and repeated disconnect/reconnect stress testing;
5. physical Android 10 and 11 results, plus reports from additional Android 8.1, 9, 12, 15, and 16 manufacturers.

## Changes

Use the [patch source kit](source-kit/README.md) to prepare the verified original EU APK locally, apply the reviewed compatibility transformations, and build an unsigned test APK. Keep the original APK, complete decompiled tree, vendor assets and libraries, manuals, signing material, generated workspaces, and other local inputs out of Git; the source kit documents the exact input and licensing boundaries.

Keep patches narrowly scoped. Preserve the EU package name, the original firmware-update row, local camera protocols, recording behavior, and the offline-account privacy guarantees unless a change explicitly documents and tests a migration.

Never commit the private patch signing key, Xiaomi's original APK, user/device data, or raw captures containing identifiers.
