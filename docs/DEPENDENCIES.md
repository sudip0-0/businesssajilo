# Dependency audit

**Date:** 2026-07-09  
**Command:** `dart pub outdated`  
**Policy:** Prefer patch/minor upgrades that resolve cleanly. Hold major bumps that need a dedicated migration PR.

## Direct dependencies (summary)

| Package | Current (pre-upgrade) | Upgradable (same constraint) | Latest | Hold reason |
|---------|----------------------|------------------------------|--------|-------------|
| connectivity_plus | 6.1.5 | 6.1.5 | 7.2.0 | Major API change — defer |
| drift | 2.34.0 | 2.34.1 | 2.34.1 | Safe minor — upgrade |
| firebase_core | 4.10.0 | 4.11.0 | 4.11.0 | Safe minor — upgrade |
| firebase_messaging | 16.3.0 | 16.4.1 | 16.4.1 | Safe minor — upgrade |
| google_fonts | 6.3.3 | 6.3.3 | 8.1.0 | Major — defer (N1 may drop runtime fetch) |
| image_picker | 1.2.2 | 1.2.3 | 1.2.3 | Safe patch — upgrade |
| intl | 0.20.2 | 0.20.2 | 0.20.3 | Flutter SDK pin often holds |
| package_info_plus | 8.3.1 | 8.3.1 | 10.2.0 | Major — defer |
| path_provider | 2.1.5 | 2.1.6 | 2.1.6 | Safe patch — upgrade |
| pdf | 3.12.0 | 3.12.0 | 3.13.0 | Constraint / transitive hold |
| printing | 5.14.3 | 5.14.3 | 5.15.0 | Constraint / transitive hold |
| share_plus | 10.1.4 | 10.1.4 | 13.2.0 | Major — defer |
| supabase_flutter | 2.14.2 | 2.16.0 | 2.16.0 | Safe minor — upgrade |

## Dev dependencies

| Package | Notes |
|---------|-------|
| build_runner | Patch available (2.15.1) — upgrade |
| drift_dev | Latest may need constraint bump — upgrade when lock allows |

## Intentional major holds

- **connectivity_plus 7.x**, **share_plus 13.x**, **package_info_plus 10.x**, **google_fonts 8.x** — require dedicated regression passes (platform channels / share UX / font loading).
- No Dependabot/advisory scan was run in this pass; re-check after major bumps.

## Actions taken this pass

1. Documented `dart pub outdated` snapshot above.
2. Ran `dart pub upgrade` (no `--major-versions`) to pick up locked patch/minor updates within existing constraints.
3. Did **not** edit `pubspec.yaml` to force major version ranges.

## Follow-ups

- After N1 bundles Inter, evaluate removing or pinning `google_fonts`.
- Schedule a major-bump PR for `connectivity_plus` / `share_plus` / `package_info_plus` with device smoke tests.
- Optional CI: warn-only `dart pub outdated --json` vs this baseline.
