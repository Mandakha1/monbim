#!/usr/bin/env bash
# Build the MonBIM Windows x64 installer and portable zip from macOS or Linux.
#
#   brew install mingw-w64 makensis         # or apt install mingw-w64 nsis
#   rustup target add x86_64-pc-windows-gnu
#   packaging/monbim/build-windows.sh       # → dist/monbim-<year>-<ver>-windows-x64-setup.exe, -portable.zip
#
# On Windows itself the GitHub workflow (.github/workflows/monbim.yml) builds the same installer
# with the MSVC toolchain. The MinGW build gets its icon through windres (apps/bimcraft/build.rs).
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"
TARGET="${TARGET:-x86_64-pc-windows-gnu}"
VERSION="$(sed -n 's/^version = "\(.*\)"/\1/p' Cargo.toml | head -1)"
YEAR="$(sed -n 's/^pub const YEAR: &str = "\(.*\)";/\1/p' crates/ui-egui/src/brand.rs)"
DIST="$ROOT/dist"
# makensis crashes (std::bad_alloc) under the C locale on macOS, hence LC_ALL below.
command -v makensis >/dev/null || { echo "error: makensis (NSIS) not found" >&2; exit 1; }
command -v "${WINDRES:-x86_64-w64-mingw32-windres}" >/dev/null || { echo "error: windres (mingw-w64) not found: monbim.exe would have no icon" >&2; exit 1; }

cargo build --release --locked -p bimcraft -p bimcraft-cli --target "$TARGET"
BIN="$ROOT/target/$TARGET/release"
mkdir -p "$DIST"

SETUP="$DIST/monbim-$YEAR-$VERSION-windows-x64-setup.exe"
LC_ALL=en_US.UTF-8 makensis -V2 -DROOT="$ROOT" -DVERSION="$VERSION" -DYEAR="$YEAR" -DBINDIR="$BIN" -DOUTFILE="$SETUP" packaging/monbim/windows/monbim.nsi

# The portable zip: the two programs, the licences, NOTICE, the readme, and the fonts' licence where NOTICE says it is.
STAGE="$ROOT/target/monbim-portable/monbim-$YEAR-$VERSION-windows-x64-portable"
rm -rf "$STAGE" && mkdir -p "$STAGE/fonts/ibm-plex-sans" "$STAGE/fonts/ibm-plex-mono"
cp "$BIN/monbim.exe" "$BIN/monbim-cli.exe" LICENSE-APACHE LICENSE-MIT NOTICE README.md "$STAGE/"
for font in ibm-plex-sans ibm-plex-mono; do
  cp "assets/fonts/$font/OFL.txt" "$STAGE/fonts/$font/OFL.txt"
done
ZIP="$DIST/monbim-$YEAR-$VERSION-windows-x64-portable.zip"
rm -f "$ZIP"
(cd "$(dirname "$STAGE")" && zip -qr "$ZIP" "$(basename "$STAGE")")

(cd "$DIST" && shasum -a 256 "$(basename "$SETUP")" "$(basename "$ZIP")" > "SHA256SUMS-windows.txt")
ls -la "$SETUP" "$ZIP"
cat "$DIST/SHA256SUMS-windows.txt"
