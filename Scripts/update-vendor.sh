#!/bin/zsh
# Refreshes Assets/vendor from the versions pinned in Scripts/vendor/package-lock.json.
# Needs npm; the build itself does not.
set -euo pipefail

root=${0:A:h:h}
vendor=$root/Assets/vendor
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

cp "$root/Scripts/vendor/package.json" "$root/Scripts/vendor/package-lock.json" "$work/"
(cd "$work" && npm ci --ignore-scripts --no-audit --no-fund)
packages=$work/node_modules

rm -rf "$vendor"
mkdir -p "$vendor/fonts" "$vendor/licenses"

cp "$packages/markdown-it/dist/browser/markdown-it.umd.min.js" "$vendor/markdown-it.min.js"
cp "$packages/markdown-it-footnote/dist/markdown-it-footnote.min.js" "$vendor/"
cp "$packages/@highlightjs/cdn-assets/highlight.min.js" "$vendor/"
cp "$packages/@highlightjs/cdn-assets/styles/github.min.css" "$vendor/highlight-github.min.css"
cp "$packages/katex/dist/katex.min.js" "$packages/katex/dist/katex.min.css" "$vendor/"
cp "$packages"/katex/dist/fonts/*.woff2 "$vendor/fonts/"
cp "$packages/mermaid/dist/mermaid.min.js" "$vendor/"

cp "$packages/markdown-it/LICENSE" "$vendor/licenses/markdown-it.txt"
cp "$packages/markdown-it-footnote/LICENSE" "$vendor/licenses/markdown-it-footnote.txt"
cp "$packages/@highlightjs/cdn-assets/LICENSE" "$vendor/licenses/highlight.js.txt"
cp "$packages/katex/LICENSE" "$vendor/licenses/katex.txt"
cp "$packages/mermaid/LICENSE" "$vendor/licenses/mermaid.txt"

# Source maps are not shipped; drop the references so nothing asks for them.
sed -i '' -e '/^\/\/# sourceMappingURL=/d' "$vendor"/*.js
