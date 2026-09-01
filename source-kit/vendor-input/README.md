# Local vendor inputs

This directory intentionally contains no binaries or manuals.

For a complete local 2.0.0 build, place the files listed in `../patches/2.0.0/manifest.json` at their exact `inputPath` locations. The patcher verifies every SHA-256 value before copying anything into the ignored decoded workspace.

The required groups are:

- seven ARM64 media libraries under `arm64-v8a/`;
- four PDF manuals under `manuals/`.

The VLC files are associated with `mrmaffen/vlc-android-sdk` tag `1.9.8`, commit `caaa6cfd9a2e2ca0d951103a06a89417336606a1`. The IJK files are compatible with the `0.7.5` generation, but this repository does not claim a cryptographically recorded upstream build chain for the local AARs.

Do not substitute files merely because their names match. A checksum mismatch must stop the build. Confirm origin, licensing, notices, and redistribution obligations yourself.

The manuals remain local inputs. A public URL or a translated/phone-formatted derivative does not by itself grant redistribution rights.
