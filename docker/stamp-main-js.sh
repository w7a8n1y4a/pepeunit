#!/bin/sh
# Flutter keeps the app bundle at main.dart.js. A long-lived cache on that
# path survives the next deploy. The bootstrap is revalidated every visit,
# so a content hash in mainJsPath makes the browser request a new URL.
set -eu
web=${1:-$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)/build/web}
boot=$web/flutter_bootstrap.js
js=$web/main.dart.js
hash=$(sha256sum "$js" | awk 'NR==1 { print substr($1, 1, 16) }')
needle='"mainJsPath":"main.dart.js"'
stamp='"mainJsPath":"main.dart.js?v='"$hash"'"'
if ! grep -F -q "$needle" "$boot"; then
  echo "stamp-main-js: $needle not found in $boot" >&2
  exit 1
fi
sed -i "s|$needle|$stamp|g" "$boot"
grep -F -q "$stamp" "$boot"
