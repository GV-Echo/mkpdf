"use strict";

// Upper bound for one image to load; a missing or remote image must not stall the PDF.
const IMAGE_LOAD_TIMEOUT_MS = 10000;
const MERMAID_SELECTOR = "pre.mermaid";
// Must match LocalSchemeHandler on the Swift side.
const IMAGE_URL_PREFIX = "mkpdf://image/?ref=";
const EMBED_URL_PREFIX = "mkpdf://embed/?name=";
const URL_SCHEME = /^[a-z][a-z0-9+.-]*:/i;

function highlight(code, language) {
  if (language && window.hljs.getLanguage(language)) {
    return window.hljs.highlight(code, { language, ignoreIllegals: true }).value;
  }
  return "";
}

function createRenderer() {
  const md = window.markdownit({ html: true, linkify: true, highlight });
  md.use(window.markdownitFootnote);
  md.use(window.mkpdfTaskLists);
  md.use(window.mkpdfCallouts);
  md.use(window.mkpdfWikiLinks, (name) => EMBED_URL_PREFIX + encodeURIComponent(name));
  const renderMath = window.mkpdfMath(md);

  const defaultFence = md.renderer.rules.fence;
  md.renderer.rules.fence = (tokens, index, options, env, self) => {
    const token = tokens[index];
    const language = token.info.trim().split(/\s+/)[0].toLowerCase();
    if (language === "mermaid") {
      return `<pre class="mermaid">${md.utils.escapeHtml(token.content)}</pre>\n`;
    }
    if (language === "math") {
      return `<div class="math-display">${renderMath(token.content, true)}</div>\n`;
    }
    return defaultFence(tokens, index, options, env, self);
  };

  // Local paths are served by the app, which resolves them relative to the note.
  const defaultImage = md.renderer.rules.image;
  md.renderer.rules.image = (tokens, index, options, env, self) => {
    const token = tokens[index];
    const src = token.attrGet("src");
    if (src && !URL_SCHEME.test(src)) {
      token.attrSet("src", IMAGE_URL_PREFIX + encodeURIComponent(src));
    }
    return defaultImage(tokens, index, options, env, self);
  };
  return md;
}

function waitForImage(image) {
  if (image.complete) {
    return Promise.resolve();
  }
  return new Promise((resolve) => {
    image.addEventListener("load", resolve, { once: true });
    image.addEventListener("error", resolve, { once: true });
    setTimeout(resolve, IMAGE_LOAD_TIMEOUT_MS);
  });
}

async function renderDiagrams(content) {
  if (!content.querySelector(MERMAID_SELECTOR)) {
    return;
  }
  window.mermaid.initialize({ startOnLoad: false, theme: "default" });
  // A broken diagram is drawn as Mermaid's error box; the rest of the document still prints.
  await window.mermaid.run({ querySelector: MERMAID_SELECTOR, suppressErrors: true });
}

// Called from Swift; resolves once the page is ready to print.
window.mkpdfRender = async function (source) {
  const content = document.getElementById("content");
  content.innerHTML = createRenderer().render(source);
  await renderDiagrams(content);
  await Promise.all(Array.from(content.querySelectorAll("img"), waitForImage));
  await document.fonts.ready;
};
