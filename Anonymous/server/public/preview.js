// Change-preview banner: injected into pages served from /__preview/ (a
// throwaway compile with one suggestion applied). Shows what changed versus
// the live page and highlights the new text in place. Self-contained.
(function () {
  "use strict";

  const script = document.currentScript;
  const page = script?.dataset.anonPage || "index";
  const liveHref = page === "index" ? "/" : `/${page}.html`;

  const style = document.createElement("style");
  style.textContent = `
    .anon-preview-banner {
      font-family: system-ui, -apple-system, "Segoe UI", sans-serif;
      font-size: 15px;
      line-height: 1.45;
      background: #fef9c3;
      color: #1f1300;
      border-bottom: 2px solid #ca8a04;
      padding: 10px 16px;
    }
    .anon-preview-banner strong { margin-right: 8px; }
    .anon-preview-banner a { color: #1d4ed8; font-weight: 600; margin-left: 12px; white-space: nowrap; }
    .anon-preview-diff {
      margin-top: 6px;
      font-size: 14px;
      overflow-wrap: anywhere;
    }
    .anon-preview-diff del { background: #fde8e8; color: #7f1d1d; text-decoration: line-through; }
    .anon-preview-diff ins { background: #def7ec; color: #14532d; text-decoration: underline; }
    button.anon-preview-jump {
      font: inherit;
      background: transparent;
      border: none;
      padding: 2px 4px;
      margin: -2px 0;
      border-radius: 4px;
      cursor: pointer;
      text-align: left;
      overflow-wrap: anywhere;
    }
    button.anon-preview-jump:hover { background: rgb(0 0 0 / 0.08); }
    button.anon-preview-jump:focus-visible { outline: 2px solid #1d4ed8; outline-offset: 2px; }
    @media (prefers-color-scheme: dark) {
      button.anon-preview-jump:hover { background: rgb(255 255 255 / 0.12); }
      button.anon-preview-jump:focus-visible { outline-color: #8ab4f8; }
    }
    mark.anon-preview-mark {
      background: #bbf7d0;
      color: #052e16;
      border-bottom: 2px solid #16a34a;
      border-radius: 2px;
      padding: 0 1px;
    }
    @media (prefers-color-scheme: dark) {
      .anon-preview-banner { background: #3a3110; color: #fde68a; border-bottom-color: #fbbf24; }
      .anon-preview-banner a { color: #8ab4f8; }
      .anon-preview-diff del { background: #4a1d1d; color: #f6c6c2; }
      .anon-preview-diff ins { background: #1d3b28; color: #bde8c8; }
      mark.anon-preview-mark { background: #14532d; color: #bbf7d0; border-bottom-color: #4ade80; }
    }
  `;
  document.head.appendChild(style);

  const banner = document.createElement("div");
  banner.className = "anon-preview-banner";
  banner.setAttribute("role", "region");
  banner.setAttribute("aria-label", "Change preview");

  const headline = document.createElement("div");
  const title = document.createElement("strong");
  title.textContent = "Change preview";
  const note = document.createElement("span");
  note.textContent = "This is how the page would look with the suggested edit — nothing is saved yet.";
  const back = document.createElement("a");
  back.href = liveHref;
  back.textContent = "← Back to the current site";
  headline.append(title, note, back);

  const diffEl = document.createElement("p");
  diffEl.className = "anon-preview-diff";
  diffEl.textContent = "Comparing with the current page…";

  banner.append(headline, diffEl);
  document.body.prepend(banner);

  function escapeRegex(text) {
    return text.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
  }

  // Find the changed words even when they span element boundaries (table
  // cells, links): search the concatenated text of all text nodes, then wrap
  // each covered node segment in its own mark. Returns the first mark or null.
  function findAndMark(root, words) {
    const nodes = [];
    let text = "";
    const walker = document.createTreeWalker(root, NodeFilter.SHOW_TEXT);
    let node;
    while ((node = walker.nextNode())) {
      if (node.parentElement?.closest(".anon-preview-banner")) continue;
      nodes.push({ node, start: text.length });
      text += node.textContent;
    }

    // Adjacent cells concatenate with NO whitespace between words, so the
    // joiner must accept zero-or-more whitespace.
    let match = null;
    for (const take of [words.length, 6, 3]) {
      if (take < 2 || take > words.length) continue;
      match = new RegExp(words.slice(0, take).map(escapeRegex).join("\\s*")).exec(text);
      if (match) break;
    }
    if (!match) return null;

    const start = match.index;
    const end = match.index + match[0].length;
    const marks = [];
    for (const entry of nodes) {
      const nodeLength = entry.node.textContent.length;
      if (entry.start + nodeLength <= start || entry.start >= end) continue;
      const from = Math.max(0, start - entry.start);
      const to = Math.min(nodeLength, end - entry.start);
      if (to <= from || !entry.node.textContent.slice(from, to).trim()) continue;
      const range = document.createRange();
      range.setStart(entry.node, from);
      range.setEnd(entry.node, to);
      const mark = document.createElement("mark");
      mark.className = "anon-preview-mark";
      try {
        range.surroundContents(mark);
        marks.push(mark);
      } catch {
        /* skip this segment */
      }
    }
    return marks[0] || null;
  }

  async function compare() {
    const main = document.getElementById("main") || document.body;
    let liveWords;
    try {
      const response = await fetch(liveHref);
      const html = await response.text();
      const doc = new DOMParser().parseFromString(html, "text/html");
      const liveMain = doc.getElementById("main") || doc.body;
      liveWords = (liveMain.textContent || "").split(/\s+/).filter(Boolean);
    } catch {
      diffEl.textContent = "Couldn't compare with the current page.";
      return;
    }
    const previewWords = (main.textContent || "").split(/\s+/).filter(Boolean);

    // Single-edit diff: trim the common prefix and suffix; the middle is the change.
    let prefix = 0;
    while (
      prefix < liveWords.length &&
      prefix < previewWords.length &&
      liveWords[prefix] === previewWords[prefix]
    ) {
      prefix++;
    }
    let suffix = 0;
    while (
      suffix < liveWords.length - prefix &&
      suffix < previewWords.length - prefix &&
      liveWords[liveWords.length - 1 - suffix] === previewWords[previewWords.length - 1 - suffix]
    ) {
      suffix++;
    }
    const removed = liveWords.slice(prefix, liveWords.length - suffix).join(" ");
    const inserted = previewWords.slice(prefix, previewWords.length - suffix).join(" ");

    diffEl.textContent = "";
    if (!removed && !inserted) {
      diffEl.textContent =
        "No visible change on this page — the edit may affect a different page, or only the PDF output.";
      return;
    }

    // Locate + highlight the changed region first, so the summary can link to it.
    const anchorWords = inserted
      ? previewWords.slice(prefix, Math.min(previewWords.length - suffix, prefix + 12))
      : previewWords.slice(Math.max(0, prefix - 5), prefix + 2);
    const mark = anchorWords.length >= 2 ? findAndMark(main, anchorWords) : null;
    const smooth = window.matchMedia("(prefers-reduced-motion: reduce)").matches
      ? "auto"
      : "smooth";

    const label = document.createElement("strong");
    label.textContent = "Changed: ";
    diffEl.appendChild(label);

    const clip = (text) => (text.length > 180 ? `${text.slice(0, 180)}…` : text);
    // The old → new summary is a button that jumps to the change in the page.
    const summary = document.createElement(mark ? "button" : "span");
    if (mark) {
      summary.type = "button";
      summary.className = "anon-preview-jump";
      summary.setAttribute("aria-label", "Jump to this change on the page");
      summary.addEventListener("click", () => {
        mark.scrollIntoView({ block: "center", behavior: smooth });
      });
    }
    if (removed) {
      const del = document.createElement("del");
      del.textContent = clip(removed);
      summary.appendChild(del);
    }
    if (removed && inserted) summary.appendChild(document.createTextNode(" → "));
    if (inserted) {
      const ins = document.createElement("ins");
      ins.textContent = clip(inserted);
      summary.appendChild(ins);
    }
    diffEl.appendChild(summary);

    if (mark) mark.scrollIntoView({ block: "center", behavior: smooth });
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", compare);
  } else {
    compare();
  }
})();
