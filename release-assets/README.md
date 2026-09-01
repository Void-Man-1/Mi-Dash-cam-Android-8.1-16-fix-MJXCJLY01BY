# Local release assets

This directory contains the ignored APK that will be attached to GitHub Release `v2.0.0` after final hardware acceptance.

The APK is intentionally ignored by Git. This keeps the 30 MB binary out of repository history while leaving the release payload organized beside the public repository.

Release file:

`Mi-Dash-Cam-EU-2.0.0-android12-16-arm64.apk`

APK SHA-256:

`2F189C0D3A6C9965036EDDBFA927EB7FD720C47D611991EB5EC1D1055E89B887`

Signing certificate SHA-256:

`BE7E580BAE6723900DD30952B1DF215B282B445BCADAFC621C03B8D9CF81A1BD`

Version 2.0.0 starts a new signing lineage. It cannot upgrade over Xiaomi's stock app or a community 1.1.x build; either existing app must be uninstalled first, which clears its app data. Every future 2.0.0+ release must use the same new key.

The existing ignored 1.1.9 APK is a historical hardware-accepted baseline, not the planned 2.0.0 release asset.
