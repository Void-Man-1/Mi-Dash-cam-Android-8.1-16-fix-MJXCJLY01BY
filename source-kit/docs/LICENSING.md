# Licensing and redistribution boundaries

This document explains why the source kit publishes transformations instead of a complete decompiled application. It is a project policy and practical risk boundary, not legal advice.

## Ownership does not change through decompilation

Decoding an APK into Smali, XML, images, and native libraries changes its representation; it does not transfer copyright or trademark ownership. Xiaomi/70mai's original program, visual assets, manuals, names, and other vendor material remain subject to their respective owners' rights. Third-party components retain their own licenses and notices.

For that reason, this repository does not publish:

- the original APK;
- a full or substantially complete decompiled tree;
- upstream classes or resources merely reformatted as Smali or XML;
- original artwork, application signatures, or manuals as source-kit build inputs; the repository-level app icon is retained only for product identification under the separate [notice](../../NOTICE.md);
- native libraries whose provenance and redistribution obligations have not been established;
- signing keys, credentials, account records, or device data.

## What the source kit publishes

The intended public material is limited to project-authored documentation, verification logic, build orchestration, patch metadata, and narrowly scoped transformations needed to describe the compatibility work.

Keeping a patch small does not automatically make every use lawful. Contributors should include only material they created or are entitled to submit, and only as much upstream context as is necessary to identify and review a change.

No repository-wide open-source license has been selected. The VideoLAN-derived patch material has only the scoped license stated in [PATCH_SOURCE_NOTICES.md](../PATCH_SOURCE_NOTICES.md). Unless another file or directory has an explicit license from its rights holder, default copyright rules apply. GitHub explains this default in [Licensing a repository](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/licensing-a-repository).

The repository's [notice](../../NOTICE.md) controls attribution and the current high-level licensing position. A future license for project-authored scripts or documentation must expressly state its scope and must not purport to relicense Xiaomi/70mai or third-party material.

## European interoperability context

The project concerns a European application and camera variant. Article 6 of [Directive 2009/24/EC on the legal protection of computer programs](https://eur-lex.europa.eu/legal-content/EN/TXT/PDF/?uri=CELEX%3A32009L0024) provides a limited framework in which certain reproduction or translation acts may be permitted when indispensable to obtain information necessary for interoperability, subject to stated conditions and restrictions.

That provision is not blanket permission to publish a complete decompiled application. Whether a particular act falls within an exception depends on the facts, purpose, amount used, jurisdiction, and other conditions. Anyone planning broader redistribution should obtain permission from the relevant rights holders or advice appropriate to their jurisdiction.

GitHub also maintains a [DMCA takedown policy](https://docs.github.com/en/site-policy/content-removal-policies/dmca-takedown-policy). Keeping proprietary inputs local reduces exposure but does not by itself decide the legality of a patch.

## Third-party native components

The application uses media components associated with projects such as VLC/LibVLC and IJKPlayer/FFmpeg. Open-source availability does not mean an arbitrary binary can be copied without conditions. The exact source, version, modifications, notices, corresponding-source obligations, and binary redistribution terms must be established for each component.

Until that record is complete, the source kit treats compatibility libraries as local `vendor-input/` files and does not download or redistribute them. A checksum proves identity, not permission.

The separately published asynchronous media-stop source transformation contains a small VideoLAN-derived change. Its exact scope, modification date, upstream commit, copyright notice, and LGPL-2.1-or-later terms are recorded in [PATCH_SOURCE_NOTICES.md](../PATCH_SOURCE_NOTICES.md); the applicable full license text is included under `LICENSES/`.

## Manuals and links

A public link to a vendor or archive page is not the same as republishing the linked file. The source kit may document where a user can find an original APK or manual, but it does not bundle those files unless permission or a suitable license is confirmed.

Third-party archive links are historical references. The project does not control their availability, contents, security, or terms.

## Contributions

By contributing, do not assume that this repository can accept every useful artifact. Submitters should:

- contribute only work they created or have the right to provide;
- keep upstream excerpts minimal and necessary;
- identify all third-party sources and licenses;
- avoid APKs, decoded trees, proprietary assets, manuals, and unknown native binaries;
- remove credentials, account identifiers, device serials, precise locations, Wi-Fi details, and other personal information;
- never submit a private signing key or password.

If a change cannot be explained or reproduced without uploading a large amount of upstream material, open an issue describing the problem and the proposed boundary before submitting the files.
