"use strict";

// "- [ ] item" / "- [x] item" → a drawn box instead of the literal brackets.
window.mkpdfTaskLists = function (md) {
  const marker = /^\[([ xX])\] /;
  md.core.ruler.after("inline", "mkpdf_task_lists", (state) => {
    const tokens = state.tokens;
    for (let i = 2; i < tokens.length; i++) {
      const inline = tokens[i];
      if (inline.type !== "inline" || tokens[i - 1].type !== "paragraph_open"
        || tokens[i - 2].type !== "list_item_open") {
        continue;
      }
      const first = inline.children[0];
      const match = first && first.type === "text" && marker.exec(first.content);
      if (!match) {
        continue;
      }
      first.content = first.content.slice(match[0].length);
      const box = new state.Token("html_inline", "", 0);
      const checked = match[1] !== " ";
      box.content = `<span class="task-box${checked ? " checked" : ""}"></span>`;
      inline.children.unshift(box);
      tokens[i - 2].attrJoin("class", "task-list-item");
    }
  });
};
