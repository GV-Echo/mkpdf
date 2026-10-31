"use strict";

// "[[note]]", "[[note#heading|alias]]" → plain text; "![[image.png|300]]" → an image the
// app resolves (next to the note or in the Obsidian vault); other embeds → their name.
window.mkpdfWikiLinks = function (md, embedURL) {
  const imageExtensions = /\.(png|jpe?g|gif|webp|svg|bmp|tiff?|heic|avif)$/i;
  const pixelWidth = /^\d+$/;

  function displayText(target, alias) {
    if (alias) {
      return alias;
    }
    return target.replace(/\.md$/i, "").replace(/#\^?/g, " › ");
  }

  md.inline.ruler.before("link", "mkpdf_wikilinks", (state, silent) => {
    const start = state.pos;
    const isEmbed = state.src.startsWith("![[", start);
    if (!isEmbed && !state.src.startsWith("[[", start)) {
      return false;
    }
    const open = start + (isEmbed ? 3 : 2);
    const close = state.src.indexOf("]]", open);
    if (close === -1 || state.src.slice(open, close).includes("\n")) {
      return false;
    }
    if (!silent) {
      const [target, alias] = state.src.slice(open, close).split("|", 2).map((s) => s.trim());
      if (isEmbed && imageExtensions.test(target)) {
        const image = state.push("html_inline", "", 0);
        const width = alias && pixelWidth.test(alias) ? ` width="${alias}"` : "";
        image.content = `<img src="${md.utils.escapeHtml(embedURL(target))}"${width} alt="">`;
      } else {
        const text = state.push("html_inline", "", 0);
        const name = md.utils.escapeHtml(displayText(target, alias));
        text.content = `<span class="wikilink${isEmbed ? " embed" : ""}">${name}</span>`;
      }
    }
    state.pos = close + 2;
    return true;
  });
};
