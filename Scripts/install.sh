#!/bin/zsh
# Builds a release binary and installs it where the "В PDF" shortcut runs it.
set -euo pipefail

root=${0:A:h:h}
destination=$HOME/.local/bin

swift build --package-path "$root" -c release
mkdir -p "$destination"
install -m 755 "$root/.build/release/mkpdf" "$destination/mkpdf"
echo "installed $destination/mkpdf"
