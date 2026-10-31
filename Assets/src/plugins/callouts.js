"use strict";

// Obsidian "> [!note] Title" (optionally folded with +/-) and GitHub "> [!NOTE]" callouts.
window.mkpdfCallouts = function (md) {
  const marker = /^\[!([\w-]+)\][+-]?[ \t]*(.*)$/;
  md.core.ruler.before("inline", "mkpdf_callouts", (state) => {
    const tokens = state.tokens;
    for (let i = 0; i + 2 < tokens.length; i++) {
      const open = tokens[i];
      const inline = tokens[i + 2];
      if (open.type !== "blockquote_open" || tokens[i + 1].type !== "paragraph_open"
        || inline.type !== "inline") {
        continue;
      }
      const lineEnd = inline.content.indexOf("\n");
      const firstLine = lineEnd === -1 ? inline.content : inline.content.slice(0, lineEnd);
      const match = marker.exec(firstLine);
      if (!match) {
        continue;
      }
      const type = match[1].toLowerCase();
      const title = match[2] || type.charAt(0).toUpperCase() + type.slice(1);
      open.attrJoin("class", `callout callout-${type}`);
      inline.content = lineEnd === -1 ? "" : inline.content.slice(lineEnd + 1);
      const heading = new state.Token("html_block", "", 0);
      heading.content = `<p class="callout-title">${md.renderInline(title)}</p>\n`;
      tokens.splice(i + 1, 0, heading);
    }
  });
};
