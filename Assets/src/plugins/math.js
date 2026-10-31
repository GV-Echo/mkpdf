"use strict";

// "$inline$" and "$$display$$" math rendered by KaTeX. Dollar rules follow Pandoc: the
// opening "$" is not followed by a space, the closing one is not preceded by a space and
// not followed by a digit, so "$5 and $10" stays text.
window.mkpdfMath = function (md) {
  function render(tex, displayMode) {
    return window.katex.renderToString(tex, { displayMode, throwOnError: false });
  }

  md.inline.ruler.after("escape", "mkpdf_math_inline", (state, silent) => {
    const src = state.src;
    const start = state.pos;
    if (src[start] !== "$" || src[start + 1] === "$" || /\s/.test(src[start + 1] || " ")) {
      return false;
    }
    let end = start + 1;
    while ((end = src.indexOf("$", end)) !== -1) {
      if (src[end - 1] !== "\\" && !/\s/.test(src[end - 1]) && !/\d/.test(src[end + 1] || "")) {
        break;
      }
      end++;
    }
    if (end === -1) {
      return false;
    }
    if (!silent) {
      state.push("html_inline", "", 0).content = render(src.slice(start + 1, end), false);
    }
    state.pos = end + 1;
    return true;
  });

  md.block.ruler.before("fence", "mkpdf_math_block", (state, startLine, endLine, silent) => {
    const lineStart = state.bMarks[startLine] + state.tShift[startLine];
    const firstLine = state.src.slice(lineStart, state.eMarks[startLine]);
    if (!firstLine.startsWith("$$")) {
      return false;
    }
    if (silent) {
      return true;
    }
    let body = firstLine.slice(2);
    let line = startLine;
    let closed = body.trimEnd().endsWith("$$");
    if (closed) {
      body = body.trimEnd().slice(0, -2);
    }
    const lines = [body];
    while (!closed && ++line < endLine) {
      const text = state.src.slice(state.bMarks[line] + state.tShift[line], state.eMarks[line]);
      if (text.trimEnd().endsWith("$$")) {
        lines.push(text.trimEnd().slice(0, -2));
        closed = true;
      } else {
        lines.push(text);
      }
    }
    if (!closed) {
      return false;
    }
    state.line = line + 1;
    const token = state.push("html_block", "", 0);
    token.content = `<div class="math-display">${render(lines.join("\n"), true)}</div>\n`;
    token.map = [startLine, state.line];
    return true;
  });

  return render;
};
