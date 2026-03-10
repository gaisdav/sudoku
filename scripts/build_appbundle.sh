#!/usr/bin/env bash
# Build release AAB for Google Play (obfuscated, symbols for crash decoding).
# Output: build/app/outputs/bundle/release/app-release.aab
# Keep build/app/outputs/symbols/ for stack trace decoding (do not commit).

set -e
cd "$(dirname "$0")/.."
flutter build appbundle --obfuscate --split-debug-info=build/app/outputs/symbols
