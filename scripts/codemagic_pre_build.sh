#!/usr/bin/env bash
# Run from the Default Workflow's Pre-build step.
set -euo pipefail

: "${CM_BUILD_DIR:?CM_BUILD_DIR must point to the cloned repository}"
cd "$CM_BUILD_DIR"
test -f apps/main_app/ios/Runner.xcodeproj/project.pbxproj

printf '%s\n' 'Resolving workspace dependencies'
dart pub get
for package in packages/core packages/data packages/ui_components apps/main_app; do
  (cd "$package" && flutter pub get)
done

for package in packages/core packages/data apps/main_app; do
  printf 'Generating Dart files in %s\n' "$package"
  (cd "$package" && dart run build_runner build --delete-conflicting-outputs)
done

python3 - <<'PY'
import json
import re
from pathlib import Path

root = Path.cwd()
missing = []
for package in ('packages/core', 'packages/data', 'apps/main_app'):
    for source in (root / package / 'lib').rglob('*.dart'):
        for part in re.findall(r"^\s*part\s+['\"]([^'\"]+)['\"]\s*;", source.read_text(encoding='utf-8'), re.MULTILINE):
            if not (source.parent / part).is_file():
                missing.append(str((source.parent / part).relative_to(root)))
if missing:
    raise SystemExit('Generated Dart files missing:\n' + '\n'.join(missing))

# Only the public application configuration is passed to Flutter.
required = ('ENVIRONMENT', 'SUPABASE_URL', 'SUPABASE_ANON_KEY')
config = {}
for line in (root / '.env.production').read_text(encoding='utf-8-sig').splitlines():
    line = line.strip()
    if not line or line.startswith('#'):
        continue
    key, separator, value = line.partition('=')
    key = key.strip()
    if separator and key in required:
        value = value.strip()
        if len(value) >= 2 and value[0] == value[-1] and value[0] in "\"'":
            value = value[1:-1]
        config[key] = value
for key in required:
    if not config.get(key):
        raise SystemExit(f'Missing {key} in .env.production')
if config['ENVIRONMENT'] != 'production':
    raise SystemExit('Expected ENVIRONMENT=production in .env.production')
if not config['SUPABASE_URL'].startswith('https://'):
    raise SystemExit('Production SUPABASE_URL must use HTTPS')
output = root / 'apps/main_app/.dart_tool/codemagic/production.json'
output.parent.mkdir(parents=True, exist_ok=True)
output.write_text(json.dumps(config), encoding='utf-8')
print('Generated Dart files verified; production configuration prepared.')
PY

printf '%s\n' 'Pre-build complete. Build arguments must include:' \
  '--dart-define-from-file=.dart_tool/codemagic/production.json'
