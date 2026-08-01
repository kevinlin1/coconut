// Shared word-level diff renderer used by the overlay and the dashboard.
// Exposes window.AnonDiff.render(original, replacement) -> DocumentFragment
// containing <del>/<ins> spans (semantic elements, announced by screen readers).
(function () {
  "use strict";

  function tokenize(text) {
    // Keep whitespace tokens so the diff reconstructs the exact strings.
    return text.split(/(\s+)/).filter((t) => t.length > 0);
  }

  // Longest-common-subsequence table; snippets are small (a few hundred tokens).
  function lcs(a, b) {
    const m = a.length;
    const n = b.length;
    const table = Array.from({ length: m + 1 }, () => new Array(n + 1).fill(0));
    for (let i = m - 1; i >= 0; i--) {
      for (let j = n - 1; j >= 0; j--) {
        table[i][j] = a[i] === b[j] ? table[i + 1][j + 1] + 1 : Math.max(table[i + 1][j], table[i][j + 1]);
      }
    }
    return table;
  }

  function diffTokens(a, b) {
    const table = lcs(a, b);
    const ops = [];
    let i = 0;
    let j = 0;
    while (i < a.length && j < b.length) {
      if (a[i] === b[j]) {
        ops.push({ type: "same", text: a[i] });
        i++;
        j++;
      } else if (table[i + 1][j] >= table[i][j + 1]) {
        ops.push({ type: "del", text: a[i] });
        i++;
      } else {
        ops.push({ type: "ins", text: b[j] });
        j++;
      }
    }
    while (i < a.length) ops.push({ type: "del", text: a[i++] });
    while (j < b.length) ops.push({ type: "ins", text: b[j++] });
    return ops;
  }

  // Merge consecutive ops of the same type so we emit few elements.
  function mergeOps(ops) {
    const merged = [];
    for (const op of ops) {
      const last = merged[merged.length - 1];
      if (last && last.type === op.type) last.text += op.text;
      else merged.push({ ...op });
    }
    return merged;
  }

  function render(original, replacement) {
    const frag = document.createDocumentFragment();
    const ops = mergeOps(diffTokens(tokenize(original), tokenize(replacement)));
    for (const op of ops) {
      if (op.type === "same") {
        frag.appendChild(document.createTextNode(op.text));
      } else {
        const el = document.createElement(op.type);
        el.textContent = op.text;
        frag.appendChild(el);
      }
    }
    return frag;
  }

  window.AnonDiff = { render };
})();
