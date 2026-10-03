#!/bin/bash
set -euo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "$0")" && pwd)"
if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "iOS requires macOS and Xcode. Use run-android.cmd on Windows." >&2
  exit 1
fi
if [[ -n "${FLUTTER_ROOT:-}" ]]; then
  export PATH="$FLUTTER_ROOT/bin:$PATH"
fi
if ! command -v flutter >/dev/null 2>&1 || ! command -v dart >/dev/null 2>&1; then
  echo "Install Flutter 3.47.6 and add its bin directory to PATH." >&2
  exit 1
fi
exec dart "$SCRIPT_DIR/scripts/run-mobile.dart" ios "$@"
