# iOS dependency update

The app now requires Flutter 3.44 or newer (Dart 3.12+) and iOS 14+.
Select a compatible Flutter version in Codemagic before rebuilding.

Updated packages:

- `file_picker`: 13.3.0. Uses the new federated native implementations.
- `app_links`: 7.2.2.
- `sign_in_with_apple`: 8.2.0.
- `printing`: 5.14.3, the newest version compatible with the existing Excel exporter.
  Version 5.15.1 requires `pdf` 3.13 / `xml` 7, while `excel` 4.0.6 requires
  `xml` below 7. Do not override `xml` without migrating and testing Excel export.

`supabase_flutter` was updated to 2.18.3 because version 1 uses
`getInitialAppLink`, removed from newer `app_links`. Query filters have been
migrated to `inFilter` and `isFilter`. The app explicitly preserves its previous
implicit authentication flow.

The unused `drift_dev` generator was removed: `AppDatabase` is a stub and fresh
code generation failed when Drift tried to resolve database types.

The shared image selector reads bytes using `PlatformFile.readAsBytes()` for
previews and uploads. File exports pass bytes directly to `FilePicker.saveFile`;
the plugin handles writing and returns a URI.

Use `scripts/codemagic_pre_build.sh` to resolve every package and regenerate
Riverpod files before the iOS archive. A successful local Dart/web check does not
verify Xcode compilation or signing; confirm the archive in Codemagic. If it
fails, inspect the first native compiler error preceding `ARCHIVE FAILED`.
