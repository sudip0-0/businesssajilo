# Dependency audit

**Date:** 2026-07-09  
**Source:** `pubspec.lock` (locked versions after `dart pub upgrade` within existing constraints)  
**Policy:** Prefer patch/minor upgrades that resolve cleanly. Hold major bumps that need a dedicated migration PR.

## Direct dependencies (locked)

| Package | Locked | Constraint (`pubspec.yaml`) | Notes |
|---------|--------|-----------------------------|-------|
| cached_network_image | 3.4.1 | ^3.4.1 | |
| connectivity_plus | 6.1.5 | ^6.1.4 | Hold 7.x (major) |
| drift | 2.34.1 | ^2.34.0 | |
| drift_flutter | 0.3.0 | ^0.3.0 | |
| firebase_core | 4.11.0 | ^4.1.1 | |
| firebase_messaging | 16.4.1 | ^16.0.2 | |
| flutter_animate | 4.5.2 | ^4.5.2 | |
| flutter_riverpod | 3.3.2 | ^3.3.2 | No riverpod codegen |
| freezed_annotation | 3.1.0 | ^3.1.0 | |
| go_router | 17.3.0 | ^17.3.0 | |
| image | 4.8.0 | ^4.5.4 | Used by PDF raster isolate |
| image_picker | 1.2.3 | ^1.2.2 | |
| intl | 0.20.2 | ^0.20.2 | Often pinned by Flutter SDK |
| json_annotation | 4.12.0 | ^4.12.0 | |
| nepali_utils | 3.0.8 | ^3.0.8 | BS dates |
| package_info_plus | 8.3.1 | ^8.3.0 | Hold 10.x (major) |
| path_provider | 2.1.6 | ^2.1.5 | |
| pdf | 3.12.0 | ^3.11.3 | |
| phosphor_flutter | 2.1.0 | ^2.1.0 | |
| printing | 5.14.3 | ^5.14.2 | |
| share_plus | 10.1.4 | ^10.1.4 | Hold 13.x (major) |
| shared_preferences | 2.5.5 | ^2.5.3 | |
| supabase_flutter | 2.16.0 | ^2.14.2 | |
| uuid | 4.5.3 | ^4.5.3 | |

**Typography:** Inter is **bundled** under `assets/fonts/` (not `google_fonts`).

## Dev dependencies (locked)

| Package | Locked | Notes |
|---------|--------|-------|
| build_runner | 2.15.1 | CI runs `build_runner build` |
| drift_dev | 2.34.0 | Analyzer conflict with riverpod_generator — keep hand-written Riverpod |
| flutter_lints | 6.0.0 | |
| freezed | 3.2.5 | |
| json_serializable | 6.14.0 | `field_rename: snake` in `build.yaml` |

## Intentional major holds

- **connectivity_plus 7.x**, **share_plus 13.x**, **package_info_plus 10.x** — require dedicated regression passes (platform channels / share UX).
- No Dependabot/advisory scan in this pass; re-check after major bumps.

## Follow-ups

- Schedule a major-bump PR for `connectivity_plus` / `share_plus` / `package_info_plus` with device smoke tests.
- Optional CI: warn-only `dart pub outdated --json` vs this baseline.
