# Patch-source notices

The patch set includes narrowly scoped changes to inherited application code solely to describe and reproduce the compatibility work.

## VideoLAN-derived media-stop patch

SPDX-License-Identifier: LGPL-2.1-or-later

The following scoped material is derived from VideoLAN's VLC Android `MediaPlayer.java`:

- the `smali/org/videolan/libvlc/MediaPlayer.smali` hunks in `patches/2.0.0/changes.patch`;
- `patches/2.0.0/files/smali/org/videolan/libvlc/MediaPlayer$2.smali`.

Copyright © 2015 VLC authors and VideoLAN. Original author: Jean-Baptiste Kempf. This compatibility project adapted the material on 2026-08-31 from [VideoLAN commit 1dbdcb3f3041d57ea0be07b929c3339719ade1b1](https://github.com/videolan/vlc-android/commit/1dbdcb3f3041d57ea0be07b929c3339719ade1b1) so `nativeStop()` runs on a worker thread.

Those named hunks and the added worker class are licensed under LGPL-2.1-or-later. See the bundled [GNU Lesser General Public License 2.1](LICENSES/LGPL-2.1-or-later.txt). This scoped license statement does not relicense unrelated Xiaomi/70mai application code or other third-party material.

## Project-authored additions

The injected `ManualPdfOpener` helper and local help pages were authored for this compatibility project. Their inclusion does not relicense Xiaomi/70mai application code, assets, manuals, trademarks, or third-party native binaries.

See [Licensing and redistribution boundaries](docs/LICENSING.md) and the repository [NOTICE](../NOTICE.md).
