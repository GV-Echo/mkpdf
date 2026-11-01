#!/bin/zsh
# Signs the shortcut and opens it, so Shortcuts offers to add the Quick Action:
# "В PDF", or "To PDF" with --english.
set -euo pipefail

name="В PDF"
case ${1-} in
    "") ;;
    --english) name="To PDF" ;;
    *)
        echo "usage: ${0:t} [--english]" >&2
        exit 64
        ;;
esac

work=$(mktemp -d)
"${0:A:h}/sign-shortcut.sh" "$work/$name.shortcut"
open "$work/$name.shortcut"
