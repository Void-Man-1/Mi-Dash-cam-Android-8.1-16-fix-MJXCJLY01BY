# Local release assets

This directory contains the ignored APK attached to GitHub Release `v2.0.0`.

The APK is intentionally ignored by Git. This keeps the 30 MB binary out of repository history while leaving the release payload organized beside the public repository.

Release file:

`Mi-Dash-Cam-EU-2.0.0-android12-16-arm64.apk`

APK SHA-256:

`2F189C0D3A6C9965036EDDBFA927EB7FD720C47D611991EB5EC1D1055E89B887`

Signing certificate SHA-256:

`BE7E580BAE6723900DD30952B1DF215B282B445BCADAFC621C03B8D9CF81A1BD`

Version 2.0.0 starts a new signing lineage. It cannot upgrade over Xiaomi's stock app or a community 1.1.x build; either existing app must be uninstalled first, which clears its app data. Every future 2.0.0+ release must use the same new key.

The exact release asset completed full physical-camera acceptance with the EU `MJXCJLY01BY` on a Poco F6 running Android 16 / HyperOS 3. Camera connection and reconnection, live preview, recordings and thumbnails, completed downloads, and recording replay passed. Camera firmware OTA was not part of the acceptance test.
