#!/bin/zsh
# Builds the release assets into dist/: a universal mkpdf binary and the signed shortcut.
# Upload both to a GitHub release; install.sh downloads them from the latest one.
set -euo pipefail

root=${0:A:h:h}
dist=$root/dist
architectures=(arm64 x86_64)

slices=()
for architecture in $architectures; do
    swift build --package-path "$root" -c release --arch "$architecture"
    slices+=("$(swift build --package-path "$root" -c release --arch "$architecture" \
        --show-bin-path)/mkpdf")
done

rm -rf "$dist"
mkdir -p "$dist"
lipo -create -output "$dist/mkpdf" $slices
# The linker signs only the arm64 slice; sign the merged binary so both slices carry one.
codesign --sign - --force "$dist/mkpdf"
"$root/Scripts/sign-shortcut.sh" "$dist/to-pdf.shortcut"
echo "upload $dist/mkpdf and $dist/to-pdf.shortcut to a GitHub release"
