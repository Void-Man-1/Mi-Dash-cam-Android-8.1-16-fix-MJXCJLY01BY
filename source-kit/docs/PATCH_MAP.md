# Patch map

This document explains the behavior changed by the source kit. It is a review map, not a copy of Xiaomi/70mai's program and not a substitute for the machine-readable patch manifest.

## Patch groups

| Group | Purpose | Main verification |
|---|---|---|
| Base identity | Set generation `2.0.0` / `20000` while preserving the EU package `com.banyac.mijia.app.eu` | Inspect built package metadata |
| Android compatibility | Raise the target to API 28 and declare optional legacy Apache HTTP support required by inherited navigation code | Decode the built manifest; launch affected screens |
| Accountless local mode | Start with `Offline account`, bypass the retired Mi-account flow, remove reachable account/authentication components, and clear legacy token/profile values when encountered | Static account-path scan, clean-data launch, network observation |
| Help and manuals | Replace dead HTTP 502 help routes with local Tips, Installation, FAQ, Wi-Fi guidance, and a manual-library handoff | Open every route offline; verify external PDF handoff |
| Live preview | Force the RTSP transport expected by the camera and repair media lifecycle behavior that produced a black preview or blocked teardown | Physical camera preview and lifecycle test |
| Reconnect hardening | Cancel stale camera-screen requests, bound fast control requests, and remove hidden retries that could accumulate across a later connection | Repeated connect, leave, and reconnect cycles |
| Download safety | Replace exposed `file://` media notification with Android's media scanner API | Download and replay; inspect emitted intents |
| UI identity | Show `Patched by Void__Man` and `Version: 2.0.0` above the unchanged Firmware update row | Visual inspection |
| Native compatibility | Add the separately sourced ARM64/16 KiB-compatible media components while retaining inherited ARMv7 support | ABI inventory, ELF segment alignment, `zipalign -P 16`, device launch |

## Deliberately preserved behavior

The source kit should not redesign unrelated camera behavior. These areas remain inherited unless a future change is separately justified and tested:

- European camera discovery and direct Wi-Fi connection;
- local CGI control commands;
- recording list and thumbnail retrieval;
- media download and replay;
- camera settings;
- the separate Firmware update row and its original command path;
- package identity and local database compatibility;
- ARMv7 support for compatible older phones.

## Material represented as transformations

The public patch set should describe only the smallest change needed at each known target. It should not contain a second decompiled copy of an upstream class or resource simply because a few instructions changed.

Each transformation should record:

- a stable patch identifier;
- the expected stock input version and SHA-256;
- the local decoded path it targets;
- narrow anchors or a pre-patch digest;
- the intended change;
- a post-patch assertion or digest;
- the verification that demonstrates the behavior.

A transform must fail if its expected input is absent or ambiguous. Broad search-and-replace rules that can silently modify an unknown application version are not acceptable.

## Locally supplied material

Some release behavior depends on material that is not a project-authored transformation:

- the original European APK;
- upstream application resources and artwork;
- vendor manuals;
- third-party native media libraries;
- a contributor's signing key.

These inputs are not stored in the source kit. Where a local input is supported, its exact expected checksum belongs in the manifest and the build must refuse an unrecognized replacement.

The native compatibility layer is a special boundary. The source kit may describe required filenames, hashes, provenance, and integration points, but it does not redistribute or automatically fetch the binaries until their upstream origin and applicable obligations are fully documented. A build without the verified release inputs is a functional development build, not proof of exact release reproduction.

## Adding a patch

Before proposing a new transformation:

1. reproduce the problem on a supported stock input;
2. identify the smallest behavior and decoded target that must change;
3. avoid copying unrelated upstream code or assets;
4. add strict preconditions and postconditions;
5. document the privacy, networking, signing, and compatibility effects;
6. add static verification where possible;
7. test on a real `MJXCJLY01BY` when the behavior touches the camera;
8. submit only redacted logs and evidence.

The repository's [contribution guide](../../CONTRIBUTING.md) lists the device and reproduction details expected in an issue or pull request.
