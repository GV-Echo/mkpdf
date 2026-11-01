#!/bin/zsh
# Signs Shortcut/to-pdf.plist into the given .shortcut file. Shortcuts names an imported
# shortcut after its file, so the output name is the name users see.
set -euo pipefail

if (( $# != 1 )); then
    echo "usage: ${0:t} <output.shortcut>" >&2
    exit 64
fi

root=${0:A:h:h}
work=$(mktemp -d)

plutil -convert binary1 -o "$work/unsigned.shortcut" "$root/Shortcut/to-pdf.plist"
# The tool logs unrelated runtime warnings to stderr; failures still stop the script.
shortcuts sign --mode anyone --input "$work/unsigned.shortcut" --output "$1" 2>/dev/null
