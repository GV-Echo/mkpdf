#!/bin/zsh
# Signs Shortcut/to-pdf.plist and opens it, so Shortcuts offers to add the "В PDF" Quick Action.
set -euo pipefail

root=${0:A:h:h}
work=$(mktemp -d)

plutil -convert binary1 -o "$work/unsigned.shortcut" "$root/Shortcut/to-pdf.plist"
# The tool logs unrelated runtime warnings to stderr; failures still stop the script.
shortcuts sign --mode anyone --input "$work/unsigned.shortcut" --output "$work/В PDF.shortcut" \
    2>/dev/null
open "$work/В PDF.shortcut"
