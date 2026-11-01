#!/bin/zsh
# Installs mkpdf and its Finder Quick Action from the latest GitHub release, or removes them.
# Files fetched with curl are not quarantined, so Gatekeeper lets the ad-hoc signed binary run.
set -euo pipefail

release=https://github.com/GV-Echo/mkpdf/releases/latest/download
minimum_macos=15
binary=$HOME/.local/bin/mkpdf
support=$HOME/Library/Application\ Support/mkpdf

name="В PDF"
case ${1-} in
    "") ;;
    --english) name="To PDF" ;;
    --uninstall)
        rm -f "$binary"
        rm -rf "$support"
        echo "removed $binary and $support"
        echo "now delete the \"В PDF\" (or \"To PDF\") shortcut in the Shortcuts app"
        exit 0
        ;;
    *)
        echo "usage: install.sh [--english | --uninstall]" >&2
        exit 64
        ;;
esac

if (( ${$(sw_vers -productVersion)%%.*} < minimum_macos )); then
    echo "mkpdf needs macOS $minimum_macos or later" >&2
    exit 1
fi

work=$(mktemp -d)
curl --fail --silent --show-error --location --output "$work/mkpdf" "$release/mkpdf"
curl --fail --silent --show-error --location --output "$work/$name.shortcut" \
    "$release/to-pdf.shortcut"
mkdir -p "${binary:h}"
install -m 755 "$work/mkpdf" "$binary"
echo "installed $binary"
open "$work/$name.shortcut"
