// Anonymous feedback overlay for the coconut course site.
// Self-contained: config comes from this script tag's data-* attributes, all
// DOM lives under one .anon-root container, all user content is inserted via
// textContent. Structured so it can become an MV3 content script by swapping
// the config source.
(function () {
  "use strict";

  // --- Config (from the injected script tag; extension can set window.__ANON_CONFIG)
  const script = document.currentScript;
  const cfg = Object.assign(
    {
      api: script?.dataset.anonApi || "/api",
      base: script?.dataset.anonBase || "/__anon",
      page:
        script?.dataset.anonPage ||
        location.pathname.replace(/^\//, "").replace(/\.html$/, "") ||
        "index",
    },
    window.__ANON_CONFIG || {},
  );

  // --- Load stylesheet + shared diff renderer
  const link = document.createElement("link");
  link.rel = "stylesheet";
  link.href = `${cfg.base}/overlay.css`;
  document.head.appendChild(link);
  const diffScript = document.createElement("script");
  diffScript.src = `${cfg.base}/diff.js`;
  document.head.appendChild(diffScript);
  const tutorialScript = document.createElement("script");
  tutorialScript.src = `${cfg.base}/tutorial.js`;
  document.head.appendChild(tutorialScript);

  // crypto.randomUUID needs a secure context; fall back for plain-HTTP LAN demos.
  function uuid() {
    if (crypto.randomUUID) return crypto.randomUUID();
    return "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx".replace(/[xy]/g, (c) => {
      const r = (Math.random() * 16) | 0;
      return (c === "x" ? r : (r & 0x3) | 0x8).toString(16);
    });
  }

  function safeParse(json, fallback) {
    try {
      return JSON.parse(json) ?? fallback;
    } catch {
      return fallback;
    }
  }

  // --- Local state (browser-local identity, preferences)
  const store = {
    get token() {
      let t = localStorage.getItem("anon-token");
      if (!t) {
        t = uuid();
        localStorage.setItem("anon-token", t);
      }
      return t;
    },
    get role() {
      return localStorage.getItem("anon-role") || "student";
    },
    set role(v) {
      localStorage.setItem("anon-role", v);
    },
    get aiEnabled() {
      return localStorage.getItem("anon-ai") !== "off";
    },
    set aiEnabled(v) {
      localStorage.setItem("anon-ai", v ? "on" : "off");
    },
    get name() {
      return localStorage.getItem("anon-name") || "";
    },
    set name(v) {
      localStorage.setItem("anon-name", v);
    },
    seen: safeParse(localStorage.getItem("anon-seen") || "{}", {}),
    saveSeen() {
      localStorage.setItem("anon-seen", JSON.stringify(this.seen));
    },
  };

  // --- API helper
  async function api(method, path, body) {
    const res = await fetch(cfg.api + path, {
      method,
      headers: body ? { "Content-Type": "application/json" } : undefined,
      body: body ? JSON.stringify(body) : undefined,
    });
    const data = await res.json().catch(() => ({}));
    if (!res.ok) {
      throw Object.assign(new Error(data.error || res.statusText), {
        status: res.status,
        data,
      });
    }
    return data;
  }

  // --- Tiny DOM helper: el("button", {class: "x", onclick: fn}, "label", node)
  function el(tag, attrs, ...children) {
    const node = document.createElement(tag);
    for (const [key, value] of Object.entries(attrs || {})) {
      if (key.startsWith("on") && typeof value === "function") {
        node.addEventListener(key.slice(2), value);
      } else if (key === "class") {
        node.className = value;
      } else if (value !== undefined && value !== null && value !== false) {
        node.setAttribute(key, value === true ? "" : value);
      }
    }
    for (const child of children.flat()) {
      if (child === null || child === undefined) continue;
      node.appendChild(
        typeof child === "string" ? document.createTextNode(child) : child,
      );
    }
    return node;
  }

  // --- Root, live region, FAB, panel shells
  const root = el("div", { class: "anon-root" });
  const live = el("div", {
    class: "anon-visually-hidden",
    role: "status",
    "aria-live": "polite",
  });
  function announce(message) {
    live.textContent = "";
    // Re-set on the next frame so repeated identical messages are re-announced.
    requestAnimationFrame(() => {
      live.textContent = message;
    });
  }

  const fabBadge = el("span", { class: "anon-fab-badge", hidden: true });
  const fabLabel = el("span", {}, "Give feedback to instructor");
  const fab = el(
    "button",
    {
      class: "anon-fab",
      type: "button",
      "aria-expanded": "false",
      "aria-controls": "anon-panel",
      onclick: () => togglePanel(),
    },
    fabLabel,
    fabBadge,
  );

  const panel = el("section", {
    class: "anon-panel",
    id: "anon-panel",
    role: "dialog",
    "aria-label": "Course feedback",
    hidden: true,
  });

  const popover = el(
    "button",
    {
      class: "anon-popover",
      type: "button",
      hidden: true,
      // Without this, mousedown on the button collapses the page selection
      // before click fires and the handler sees an empty selection.
      onmousedown: (event) => event.preventDefault(),
      onclick: () => {
        commentOnCurrentSelection();
      },
    },
    "\u{1F4AC} Comment on selection",
  );

  // Margin layer for Google-Docs-style comment cards anchored to highlights.
  const marginLayer = el("div", { class: "anon-margin-layer" });

  root.append(live, fab, panel, popover, marginLayer);

  // --- Panel open/close with focus management
  let lastInvoker = null;
  function openPanel() {
    panel.hidden = false;
    fab.setAttribute("aria-expanded", "true");
    lastInvoker = document.activeElement instanceof HTMLElement ? document.activeElement : fab;
    render();
    const target = panel.querySelector(
      "input:not([type=hidden]), button.anon-close, button, textarea, select",
    );
    (target || panel).focus?.();
  }
  function closePanel() {
    panel.hidden = true;
    fab.setAttribute("aria-expanded", "false");
    (lastInvoker && document.contains(lastInvoker) ? lastInvoker : fab).focus();
  }
  function togglePanel() {
    panel.hidden ? openPanel() : closePanel();
  }

  document.addEventListener("keydown", (event) => {
    if (event.key === "Escape") {
      if (!popover.hidden) {
        hidePopover();
        return;
      }
      if (activeCommentId) {
        deactivateComment();
        return;
      }
      if (!panel.hidden) closePanel();
    }
    // Keyboard path to comment on the current text selection (documented in the panel).
    if (event.altKey && (event.key === "c" || event.key === "C")) {
      const sel = document.getSelection();
      if (sel && !sel.isCollapsed && selectionInMain(sel)) {
        event.preventDefault();
        commentOnCurrentSelection();
      }
    }
  });

  // --- Selection handling (works for mouse and keyboard selections alike)
  function selectionInMain(sel) {
    const main = document.getElementById("main");
    if (!main || sel.rangeCount === 0) return false;
    const node = sel.getRangeAt(0).commonAncestorContainer;
    return main.contains(node) && !root.contains(node);
  }

  let selectionTimer = null;
  document.addEventListener("selectionchange", () => {
    clearTimeout(selectionTimer);
    selectionTimer = setTimeout(() => {
      const sel = document.getSelection();
      if (!sel || sel.isCollapsed || !selectionInMain(sel) || sel.toString().trim().length < 3) {
        hidePopover();
        return;
      }
      const rect = sel.getRangeAt(0).getBoundingClientRect();
      popover.style.top = `${window.scrollY + rect.bottom + 6}px`;
      popover.style.left = `${Math.max(8, window.scrollX + rect.left)}px`;
      popover.hidden = false;
    }, 250);
  });

  function hidePopover() {
    popover.hidden = true;
  }

  // Capture the anchor immediately: selected text + surrounding rendered
  // context (fuzzy anchor — the minified HTML has no stable ids/classes).
  function captureAnchor(selectedText) {
    // Belt-and-suspenders: strip any stray marker glyphs from the anchor.
    const clean = (value) => value.replace(/\u{1F4AC}/gu, "");
    const main = document.getElementById("main");
    const text = clean(main ? main.innerText : document.body.innerText);
    const needle = clean(selectedText);
    const idx = text.indexOf(needle);
    return {
      selectedText: needle,
      prefix: idx >= 0 ? text.slice(Math.max(0, idx - 40), idx) : "",
      suffix: idx >= 0 ? text.slice(idx + needle.length, idx + needle.length + 40) : "",
      section: false,
    };
  }

  function commentOnCurrentSelection() {
    const sel = document.getSelection();
    const selectedText = sel ? sel.toString().trim() : "";
    if (!selectedText) return;
    composeState.anchor = captureAnchor(selectedText);
    resetSuggestion();
    hidePopover();
    store.role = "student";
    activeTab = "compose";
    if (panel.hidden) openPanel();
    else render();
    panel.querySelector("#anon-comment-text")?.focus();
    announce("Selection captured. Write your comment in the feedback panel.");
  }

  // --- Compose state
  const composeState = {
    anchor: null,
    comment: "",
    suggestion: null, // {originalSnippet, replacementSnippet, rationale, aiGenerated, accepted, editing}
    generating: false,
    error: "",
  };
  function resetSuggestion() {
    composeState.suggestion = null;
    composeState.generating = false;
    composeState.error = "";
  }
  function resetCompose() {
    composeState.anchor = null;
    composeState.comment = "";
    resetSuggestion();
  }

  let activeTab = "compose"; // compose | mine | settings
  let aiSettings = { aiConfigured: false, model: "" };

  // Restore focus to a card after an action re-renders an async list.
  let pendingFocusId = null;
  function applyPendingFocus() {
    if (!pendingFocusId) return;
    const target = panel.querySelector(`#${pendingFocusId}`);
    pendingFocusId = null;
    target?.focus();
  }

  // --- Rendering ---------------------------------------------------------------

  function render() {
    panel.textContent = "";
    panel.append(
      el(
        "div",
        { class: "anon-panel-header" },
        el("h2", { class: "anon-panel-title" }, "Course feedback"),
        el(
          "button",
          {
            class: "anon-close",
            type: "button",
            "aria-label": "Close feedback panel",
            onclick: closePanel,
          },
          "✕",
        ),
      ),
      renderRoleToggle(),
    );
    if (store.role === "instructor") {
      panel.append(renderInstructorView());
    } else {
      panel.append(renderTabs(), renderActiveTab());
    }
  }

  function renderRoleToggle() {
    const make = (value, label) =>
      el(
        "label",
        {},
        el("input", {
          type: "radio",
          name: "anon-role",
          value,
          checked: store.role === value ? true : undefined,
          onchange: () => {
            store.role = value;
            render();
            // render() destroyed the focused radio — restore focus so
            // keyboard users can keep arrowing through the group.
            panel.querySelector(`input[name="anon-role"][value="${value}"]`)?.focus();
            refreshAnnotations({ force: true }); // margin cards are role-aware
            updateBadge(); // button label + bubble are role-aware
            announce(`Switched to ${label} view.`);
          },
        }),
        label,
      );
    return el(
      "fieldset",
      { class: "anon-role" },
      el("legend", {}, "View as"),
      make("student", "Student"),
      make("instructor", "Instructor"),
    );
  }

  // ARIA tabs pattern with arrow-key navigation.
  function renderTabs() {
    const tabs = [
      { id: "compose", label: "Compose" },
      { id: "mine", label: "My feedback" },
      { id: "settings", label: "Settings" },
    ];
    const tablist = el("div", {
      class: "anon-tabs",
      role: "tablist",
      "aria-label": "Feedback sections",
    });
    for (const tab of tabs) {
      tablist.appendChild(
        el(
          "button",
          {
            class: "anon-tab",
            type: "button",
            role: "tab",
            id: `anon-tab-${tab.id}`,
            "aria-selected": String(activeTab === tab.id),
            // Only the active tabpanel exists in the DOM; a dangling
            // aria-controls reference is an ARIA-validity error.
            "aria-controls": activeTab === tab.id ? `anon-tabpanel-${tab.id}` : undefined,
            tabindex: activeTab === tab.id ? "0" : "-1",
            onclick: () => {
              activeTab = tab.id;
              render();
              panel.querySelector(`#anon-tab-${tab.id}`)?.focus();
            },
            onkeydown: (event) => {
              if (event.key !== "ArrowRight" && event.key !== "ArrowLeft") return;
              event.preventDefault();
              const index = tabs.findIndex((t) => t.id === activeTab);
              const delta = event.key === "ArrowRight" ? 1 : -1;
              activeTab = tabs[(index + delta + tabs.length) % tabs.length].id;
              render();
              panel.querySelector(`#anon-tab-${activeTab}`)?.focus();
            },
          },
          tab.label,
        ),
      );
    }
    return tablist;
  }

  function renderActiveTab() {
    const container = el("div", {
      role: "tabpanel",
      id: `anon-tabpanel-${activeTab}`,
      "aria-labelledby": `anon-tab-${activeTab}`,
    });
    if (activeTab === "compose") container.append(...renderCompose());
    else if (activeTab === "mine") container.append(renderMine());
    else container.append(renderSettings());
    return container;
  }

  // --- Compose tab
  function renderCompose() {
    const parts = [];

    if (composeState.anchor) {
      parts.push(
        el(
          "blockquote",
          { class: "anon-quote" },
          el(
            "span",
            { class: "anon-quote-label" },
            composeState.anchor.general
              ? "General feedback on this page"
              : composeState.anchor.section
                ? "Commenting on section"
                : "Commenting on",
          ),
          composeState.anchor.general
            ? ""
            : composeState.anchor.selectedText.length > 220
              ? composeState.anchor.selectedText.slice(0, 220) + "…"
              : composeState.anchor.selectedText,
        ),
        el(
          "div",
          { class: "anon-btn-row" },
          el(
            "button",
            {
              class: "anon-btn",
              type: "button",
              onclick: () => {
                resetCompose();
                render();
                announce("Selection cleared.");
              },
            },
            "Clear selection",
          ),
        ),
      );
    } else {
      parts.push(
        el(
          "p",
          { class: "anon-note" },
          "Select text on the page to comment on it (mouse, or Shift+arrow keys then Alt+C) — or:",
        ),
        el(
          "div",
          { class: "anon-btn-row" },
          el(
            "button",
            {
              class: "anon-btn",
              type: "button",
              onclick: () => {
                composeState.anchor = { selectedText: "", prefix: "", suffix: "", general: true };
                resetSuggestion();
                render();
                panel.querySelector("#anon-comment-text")?.focus();
                announce("Writing general feedback about the whole page.");
              },
            },
            "Comment on the whole page",
          ),
        ),
      );
    }

    const commentField = el(
      "div",
      { class: "anon-field" },
      el("label", { for: "anon-comment-text" }, "Your comment"),
      el("textarea", {
        id: "anon-comment-text",
        oninput: (event) => {
          composeState.comment = event.target.value;
        },
      }),
    );
    commentField.querySelector("textarea").value = composeState.comment;

    const nameField = el(
      "div",
      { class: "anon-field" },
      el("label", { for: "anon-display-name" }, "Display name (optional)"),
      el("p", { class: "anon-hint" }, "Leave blank to stay anonymous."),
      el("input", {
        type: "text",
        id: "anon-display-name",
        autocomplete: "off",
        oninput: (event) => {
          store.name = event.target.value;
        },
      }),
    );
    nameField.querySelector("input").value = store.name;

    const aiToggle = el(
      "div",
      { class: "anon-checkbox" },
      el("input", {
        type: "checkbox",
        id: "anon-ai-toggle",
        checked: store.aiEnabled && aiSettings.aiConfigured ? true : undefined,
        disabled: aiSettings.aiConfigured ? undefined : true,
        onchange: (event) => {
          store.aiEnabled = event.target.checked;
          render();
          panel.querySelector("#anon-ai-toggle")?.focus();
        },
      }),
      el(
        "label",
        { for: "anon-ai-toggle" },
        "AI-suggested edit",
        aiSettings.aiConfigured
          ? ""
          : el(
              "span",
              { class: "anon-hint" },
              " (add a Gemini API key under Settings to enable)",
            ),
      ),
    );

    parts.push(commentField, nameField, aiToggle);

    // Suggestion area (AI needs a text selection to map to the source —
    // general whole-page comments go without one)
    if (composeState.anchor && !composeState.anchor.general && aiSettings.aiConfigured && store.aiEnabled) {
      if (composeState.suggestion) {
        parts.push(renderSuggestionCard());
      } else {
        parts.push(
          el(
            "div",
            { class: "anon-btn-row" },
            el(
              "button",
              {
                class: "anon-btn",
                type: "button",
                "aria-busy": composeState.generating ? "true" : undefined,
                disabled: composeState.generating ? true : undefined,
                onclick: generateSuggestion,
              },
              composeState.generating ? "Generating…" : "Generate suggested edit",
            ),
          ),
        );
      }
    }

    if (composeState.error) {
      parts.push(el("p", { class: "anon-error", role: "alert" }, composeState.error));
    }

    parts.push(
      el(
        "div",
        { class: "anon-btn-row" },
        el(
          "button",
          {
            class: "anon-btn anon-btn-primary",
            type: "button",
            onclick: submitComment,
          },
          "Send to instructor",
        ),
      ),
      el(
        "p",
        { class: "anon-note" },
        "Anonymous by default — the instructor sees your feedback, never who you are.",
      ),
    );

    return parts;
  }

  async function generateSuggestion() {
    if (!composeState.anchor) return;
    if (!composeState.comment.trim()) {
      composeState.error = "Write your comment first — the AI uses it to draft the edit.";
      render();
      return;
    }
    composeState.generating = true;
    composeState.error = "";
    render();
    announce("Generating suggested edit…");
    // Snapshot the anchor: if the user changes/clears the selection while the
    // request is in flight, the late response must not attach to the new anchor.
    const anchorAtRequest = composeState.anchor;
    try {
      const result = await api("POST", "/ai/suggest", {
        page: cfg.page,
        anchor: composeState.anchor,
        commentText: composeState.comment,
      });
      if (composeState.anchor !== anchorAtRequest) return;
      if (!result.found) {
        composeState.error =
          "The AI couldn't map this selection to the source. " +
          (result.rationale || "") +
          " You can still submit the comment on its own.";
        composeState.suggestion = null;
        announce("No suggestion available. You can still submit your comment.");
      } else {
        composeState.suggestion = {
          originalSnippet: result.originalSnippet,
          replacementSnippet: result.replacementSnippet,
          rationale: result.rationale,
          aiGenerated: true,
          accepted: false,
          editing: false,
        };
        announce("Suggested edit ready. Review it below.");
      }
    } catch (err) {
      if (composeState.anchor !== anchorAtRequest) return;
      composeState.error =
        err.status === 409
          ? "AI is not configured. Add a Gemini API key under Settings."
          : "AI is unavailable right now. You can still submit your comment.";
      announce(composeState.error);
    }
    composeState.generating = false;
    render();
  }

  // Build a throwaway compile of the site with the edit applied and open it
  // in a new tab (Google-Docs-style "see the result in context").
  async function openPreview(button, body) {
    const originalLabel = button.textContent;
    button.disabled = true;
    button.setAttribute("aria-busy", "true");
    button.textContent = "Building preview…";
    announce("Building preview — this recompiles the page and takes a few seconds.");
    try {
      const result = await api("POST", "/preview", body);
      window.open(result.url, "_blank", "noopener");
      announce("Preview opened in a new tab.");
    } catch (err) {
      announce(
        err.data?.log
          ? `Couldn't build the preview: ${String(err.data.log).slice(0, 140)}`
          : "Couldn't build the preview.",
      );
    }
    button.disabled = false;
    button.removeAttribute("aria-busy");
    button.textContent = originalLabel;
  }

  function previewButton(body) {
    return el(
      "button",
      {
        class: "anon-btn",
        type: "button",
        onclick: (event) => openPreview(event.currentTarget, body),
      },
      "Preview on page",
    );
  }

  function renderSuggestionCard() {
    const suggestion = composeState.suggestion;
    const card = el("div", { class: "anon-suggestion" });

    card.append(el("div", { class: "anon-diff-label" }, "Current source"));
    const originalBlock = el("pre", { class: "anon-diff" });
    originalBlock.appendChild(
      el("del", {}, suggestion.originalSnippet),
    );
    card.append(originalBlock);

    card.append(el("div", { class: "anon-diff-label" }, "Suggested"));
    if (suggestion.editing) {
      const editArea = el("textarea", {
        "aria-label": "Edit the suggested replacement",
        class: "anon-diff",
      });
      editArea.value = suggestion.replacementSnippet;
      card.append(
        editArea,
        el(
          "div",
          { class: "anon-btn-row" },
          el(
            "button",
            {
              class: "anon-btn anon-btn-primary",
              type: "button",
              onclick: () => {
                suggestion.replacementSnippet = editArea.value;
                suggestion.aiGenerated = false;
                suggestion.editing = false;
                suggestion.accepted = true;
                render();
                announce("Edited suggestion saved and accepted.");
              },
            },
            "Save edit",
          ),
          el(
            "button",
            {
              class: "anon-btn",
              type: "button",
              onclick: () => {
                suggestion.editing = false;
                render();
              },
            },
            "Cancel",
          ),
        ),
      );
    } else {
      const replacementBlock = el("pre", { class: "anon-diff" });
      if (window.AnonDiff) {
        replacementBlock.appendChild(
          window.AnonDiff.render(suggestion.originalSnippet, suggestion.replacementSnippet),
        );
      } else {
        replacementBlock.appendChild(el("ins", {}, suggestion.replacementSnippet));
      }
      card.append(replacementBlock);
      if (suggestion.rationale) {
        card.append(el("p", { class: "anon-rationale" }, suggestion.rationale));
      }
      card.append(
        el(
          "p",
          { class: "anon-note" },
          "If you accept, this edit goes to the instructor for review — only they can apply it.",
        ),
      );
      card.append(
        el(
          "div",
          { class: "anon-btn-row" },
          suggestion.accepted
            ? el("span", { class: "anon-status-ok" }, "✓ Will be sent to the instructor with your comment")
            : el(
                "button",
                {
                  class: "anon-btn anon-btn-primary",
                  type: "button",
                  onclick: () => {
                    suggestion.accepted = true;
                    render();
                    announce("Suggestion accepted.");
                  },
                },
                "Accept",
              ),
          el(
            "button",
            {
              class: "anon-btn",
              type: "button",
              onclick: () => {
                suggestion.editing = true;
                render();
              },
            },
            "Edit",
          ),
          el(
            "button",
            {
              class: "anon-btn anon-btn-danger",
              type: "button",
              onclick: () => {
                resetSuggestion();
                render();
                announce("Suggestion discarded. Your comment will be submitted on its own.");
              },
            },
            "Discard",
          ),
          el(
            "button",
            {
              class: "anon-btn",
              type: "button",
              onclick: () => {
                resetSuggestion();
                render();
                generateSuggestion();
              },
            },
            "Regenerate",
          ),
          previewButton({
            page: cfg.page,
            originalSnippet: suggestion.originalSnippet,
            replacementSnippet: suggestion.replacementSnippet,
          }),
        ),
      );
    }
    return card;
  }

  async function submitComment() {
    if (!composeState.anchor) {
      composeState.error = "Select text or pick a section to comment on first.";
      render();
      return;
    }
    if (!composeState.comment.trim()) {
      composeState.error = "Write a comment before submitting.";
      render();
      return;
    }
    const suggestion =
      composeState.suggestion && composeState.suggestion.accepted
        ? {
            originalSnippet: composeState.suggestion.originalSnippet,
            replacementSnippet: composeState.suggestion.replacementSnippet,
            rationale: composeState.suggestion.rationale,
            aiGenerated: composeState.suggestion.aiGenerated,
          }
        : null;
    try {
      await api("POST", "/comments", {
        page: cfg.page,
        anchor: composeState.anchor,
        commentText: composeState.comment,
        displayName: store.name || null,
        authorToken: store.token,
        suggestion,
      });
      resetCompose();
      activeTab = "mine";
      render();
      refreshAnnotations({ force: true }); // highlight + margin card appear immediately
      announce("Feedback submitted. Thank you!");
    } catch {
      composeState.error = "Couldn't submit — is the server running?";
      render();
      announce(composeState.error);
    }
  }

  // --- My feedback tab
  function renderMine() {
    const container = el("div", {});
    container.append(el("p", { class: "anon-note" }, "Loading your feedback…"));
    api("GET", `/comments/mine?token=${encodeURIComponent(store.token)}`)
      .then(({ comments }) => {
        // The user may have left the tab before the response landed — don't
        // mark replies as seen for a list they never saw.
        if (!container.isConnected) return;
        container.textContent = "";
        if (!comments.length) {
          container.append(
            el("p", { class: "anon-empty" }, "You haven't submitted any feedback yet."),
          );
          return;
        }
        // Viewing the tab marks replies as seen.
        for (const comment of comments) {
          store.seen[comment.id] = new Date().toISOString();
        }
        store.saveSeen();
        updateBadge();
        for (const comment of comments.slice().reverse()) {
          container.append(renderMineCard(comment));
        }
        applyPendingFocus();
      })
      .catch(() => {
        if (!container.isConnected) return;
        container.textContent = "";
        container.append(el("p", { class: "anon-error" }, "Couldn't load your feedback."));
      });
    return container;
  }

  function statusChip(comment) {
    const label = comment.suggestion
      ? comment.suggestion.status
      : comment.status === "resolved"
        ? "resolved"
        : "open";
    return el(
      "span",
      { class: `anon-chip anon-chip-${label}` },
      label,
    );
  }

  // Clickable quote: navigates to (and flashes) the highlight on the page.
  function quoteButton(comment) {
    return el(
      "button",
      {
        class: "anon-quote anon-quote-click",
        type: "button",
        onclick: () => {
          if (comment.page !== cfg.page) {
            location.href = `/${comment.page === "index" ? "" : `${comment.page}.html`}#anon-comment=${comment.id}`;
            return;
          }
          activateComment(comment.id, "panel");
        },
      },
      comment.anchor.general
        ? el("span", { class: "anon-quote-label" }, "General feedback on this page")
        : comment.anchor.section
          ? el("span", { class: "anon-quote-label" }, "Section")
          : null,
      comment.anchor.general ? "" : comment.anchor.selectedText.slice(0, 160),
      el("span", { class: "anon-quote-hint" }, comment.page === cfg.page ? "Show on page" : `Show on ${comment.page}`),
    );
  }

  function renderMineCard(comment) {
    const card = el("div", { class: "anon-card", id: `anon-card-${comment.id}`, tabindex: "-1" });
    card.append(
      el(
        "p",
        { class: "anon-card-meta" },
        `${comment.page} · ${new Date(comment.createdAt).toLocaleString()}`,
        statusChip(comment),
      ),
      quoteButton(comment),
      el("p", {}, comment.commentText),
    );
    if (comment.suggestion) {
      card.append(renderStoredSuggestion(comment.suggestion, comment));
    }
    for (const reply of comment.replies) {
      card.append(
        el(
          "div",
          { class: "anon-reply" },
          el("span", { class: "anon-reply-author" }, reply.author === "instructor" ? "Instructor: " : "You: "),
          reply.text,
        ),
      );
    }
    card.append(
      renderReplyForm(comment, "student"),
      el(
        "div",
        { class: "anon-btn-row" },
        el(
          "button",
          {
            class: "anon-btn anon-btn-danger",
            type: "button",
            onclick: async () => {
              if (!window.confirm("Delete this feedback? This also removes it for the instructor.")) return;
              try {
                await api("DELETE", `/comments/${comment.id}`, { authorToken: store.token });
                announce("Feedback deleted.");
                refreshAnnotations({ force: true });
                updateBadge();
                render();
              } catch {
                announce("Couldn't delete this feedback.");
              }
            },
          },
          "Delete",
        ),
      ),
    );
    return card;
  }

  function renderStoredSuggestion(suggestion, comment) {
    const wrap = el("div", { class: "anon-suggestion" });
    wrap.append(el("div", { class: "anon-diff-label" }, "Suggested edit"));
    const pre = el("pre", { class: "anon-diff" });
    if (window.AnonDiff) {
      pre.appendChild(window.AnonDiff.render(suggestion.originalSnippet, suggestion.replacementSnippet));
    } else {
      pre.textContent = suggestion.replacementSnippet;
    }
    wrap.append(pre);
    if (comment && suggestion.status !== "applied") {
      wrap.append(el("div", { class: "anon-btn-row" }, previewButton({ commentId: comment.id })));
    }
    return wrap;
  }

  function renderReplyForm(comment, author) {
    const input = el("input", {
      type: "text",
      "aria-label": "Reply",
      placeholder: "Reply…",
    });
    return el(
      "form",
      {
        class: "anon-reply-form",
        onsubmit: async (event) => {
          event.preventDefault();
          if (!input.value.trim()) return;
          try {
            await api("POST", `/comments/${comment.id}/replies`, {
              author,
              text: input.value,
              authorToken: author === "student" ? store.token : undefined,
            });
            announce("Reply sent.");
            refreshAnnotations({ force: true });
            if (panel.contains(input)) {
              pendingFocusId = `anon-card-${comment.id}`;
              render();
            }
          } catch {
            announce("Couldn't send reply.");
          }
        },
      },
      input,
      el("button", { class: "anon-btn", type: "submit" }, "Reply"),
    );
  }

  // --- Settings tab
  function renderSettings() {
    const container = el("div", {});
    const status = el(
      "p",
      {},
      aiSettings.aiConfigured
        ? el("span", { class: "anon-status-ok" }, `✓ AI configured (${aiSettings.model})`)
        : "AI is not configured yet.",
    );
    const input = el("input", {
      type: "password",
      id: "anon-api-key",
      autocomplete: "off",
    });
    container.append(
      status,
      el(
        "div",
        { class: "anon-field" },
        el("label", { for: "anon-api-key" }, "Gemini API key"),
        el(
          "p",
          { class: "anon-hint" },
          "Stored on the local server only — never shown to other users.",
        ),
        input,
      ),
      el(
        "div",
        { class: "anon-btn-row" },
        el(
          "button",
          {
            class: "anon-btn anon-btn-primary",
            type: "button",
            onclick: async () => {
              try {
                aiSettings = await api("PUT", "/settings", { apiKey: input.value });
                announce(aiSettings.aiConfigured ? "API key saved. AI is ready." : "API key cleared.");
                render();
              } catch {
                announce("Couldn't save the API key.");
              }
            },
          },
          "Save key",
        ),
      ),
      el(
        "div",
        { class: "anon-btn-row" },
        el(
          "button",
          {
            class: "anon-btn",
            type: "button",
            onclick: () => startTutorial(),
          },
          "Replay tutorial",
        ),
      ),
      el(
        "p",
        { class: "anon-note" },
        "Tip: press Alt+C to comment on the current text selection.",
      ),
    );
    return container;
  }

  // --- Tutorial wiring (module lives in tutorial.js) ---------------------------
  function startTutorial() {
    if (!window.AnonTutorial) {
      announce("The tutorial is still loading — try again in a moment.");
      return;
    }
    store.role = "student"; // the tour explains the student experience
    updateBadge();
    window.AnonTutorial.start({
      fab,
      panel,
      openPanel: (tab) => {
        activeTab = tab;
        if (panel.hidden) openPanel();
        else render();
      },
      closePanel: () => {
        if (!panel.hidden) closePanel();
      },
      announce,
      onDone: () => {
        localStorage.setItem("anon-tutorial-done", "1");
        activeTab = "compose";
        updateBadge();
        fab.focus();
      },
    });
  }

  // --- Instructor view (in-panel moderation for the current page)
  function renderInstructorView() {
    const container = el("div", {});
    container.append(
      el("a", { class: "anon-dash-link", href: "/instructor" }, "Full dashboard →"),
      el("p", { class: "anon-note" }, `Feedback on this page (${cfg.page}):`),
    );
    const list = el("div", {});
    container.append(list);
    list.append(el("p", { class: "anon-note" }, "Loading…"));
    api("GET", `/comments?page=${encodeURIComponent(cfg.page)}`)
      .then(({ comments }) => {
        if (!list.isConnected) return;
        list.textContent = "";
        if (!comments.length) {
          list.append(el("p", { class: "anon-empty" }, "No feedback on this page yet."));
          return;
        }
        for (const comment of comments.slice().reverse()) {
          list.append(renderInstructorCard(comment));
        }
        applyPendingFocus();
      })
      .catch(() => {
        if (!list.isConnected) return;
        list.textContent = "";
        list.append(el("p", { class: "anon-error" }, "Couldn't load feedback."));
      });
    return container;
  }

  function renderInstructorCard(comment) {
    const card = el("div", { class: "anon-card", id: `anon-card-${comment.id}`, tabindex: "-1" });
    card.append(
      el(
        "p",
        { class: "anon-card-meta" },
        `${comment.displayName || "Anonymous"} · ${new Date(comment.createdAt).toLocaleString()}`,
        statusChip(comment),
      ),
      quoteButton(comment),
      el("p", {}, comment.commentText),
    );

    if (comment.suggestion) {
      const wrap = renderStoredSuggestion(comment.suggestion, comment);
      const actions = el("div", { class: "anon-btn-row" });
      const patch = async (body, message) => {
        try {
          await api("PATCH", `/comments/${comment.id}/suggestion`, body);
          announce(message);
          refreshAnnotations({ force: true });
          pendingFocusId = `anon-card-${comment.id}`;
          render();
        } catch {
          announce("Action failed.");
        }
      };
      if (comment.suggestion.status === "pending") {
        actions.append(
          el(
            "button",
            {
              class: "anon-btn anon-btn-primary",
              type: "button",
              onclick: () => patch({ status: "approved" }, "Suggestion approved."),
            },
            "Approve",
          ),
          el(
            "button",
            {
              class: "anon-btn anon-btn-danger",
              type: "button",
              onclick: () => patch({ status: "rejected" }, "Suggestion rejected."),
            },
            "Reject",
          ),
        );
      }
      actions.append(
        el(
          "button",
          {
            class: "anon-btn",
            type: "button",
            onclick: () => {
              const editArea = el("textarea", {
                "aria-label": "Edit the suggested replacement",
                class: "anon-diff",
              });
              editArea.value = comment.suggestion.replacementSnippet;
              wrap.append(
                editArea,
                el(
                  "div",
                  { class: "anon-btn-row" },
                  el(
                    "button",
                    {
                      class: "anon-btn anon-btn-primary",
                      type: "button",
                      onclick: () =>
                        patch({ replacementSnippet: editArea.value }, "Suggestion updated."),
                    },
                    "Save",
                  ),
                ),
              );
              editArea.focus();
            },
          },
          "Edit",
        ),
      );
      wrap.append(actions);
      card.append(wrap);
    }

    for (const reply of comment.replies) {
      card.append(
        el(
          "div",
          { class: "anon-reply" },
          el(
            "span",
            { class: "anon-reply-author" },
            reply.author === "instructor" ? "You (instructor): " : "Student: ",
          ),
          reply.text,
        ),
      );
    }
    card.append(
      renderReplyForm(comment, "instructor"),
      el("div", { class: "anon-btn-row" }, resolveButton(comment)),
    );
    return card;
  }

  // Works for every comment, suggestion or not.
  function resolveButton(comment) {
    return el(
      "button",
      {
        class: "anon-btn",
        type: "button",
        onclick: async () => {
          try {
            await api("PATCH", `/comments/${comment.id}`, {
              status: comment.status === "resolved" ? "open" : "resolved",
            });
            announce(comment.status === "resolved" ? "Reopened." : "Marked resolved.");
            refreshAnnotations({ force: true });
            updateBadge();
            pendingFocusId = `anon-card-${comment.id}`;
            render();
          } catch {
            announce("Action failed.");
          }
        },
      },
      comment.status === "resolved" ? "Reopen" : "Mark resolved",
    );
  }

  // --- Unread-reply badge + in-page highlights ----------------------------------

  // Role-aware button label + red notification bubble:
  // student — unread instructor replies; instructor — open feedback items.
  let badgeSeq = 0;
  async function updateBadge() {
    const seq = ++badgeSeq; // discard out-of-order responses (e.g. role toggled mid-fetch)
    const instructor = store.role === "instructor";
    const label = instructor ? "View feedback" : "Give feedback to instructor";
    fabLabel.textContent = label;
    try {
      let count = 0;
      let what = "";
      if (instructor) {
        const { comments } = await api("GET", "/comments");
        count = comments.filter((c) => c.status === "open").length;
        what = count === 1 ? "open feedback item" : "open feedback items";
      } else {
        const { comments } = await api(
          "GET",
          `/comments/mine?token=${encodeURIComponent(store.token)}`,
        );
        for (const comment of comments) {
          const lastSeen = store.seen[comment.id] || comment.createdAt;
          if (
            comment.replies.some(
              (reply) => reply.author === "instructor" && reply.createdAt > lastSeen,
            )
          ) {
            count++;
          }
        }
        what = count === 1 ? "unread reply" : "unread replies";
      }
      if (seq !== badgeSeq) return;
      if (count > 0) {
        fabBadge.hidden = false;
        fabBadge.textContent = String(count);
        fab.setAttribute("aria-label", `${label}, ${count} ${what}`);
      } else {
        fabBadge.hidden = true;
        fab.setAttribute("aria-label", label);
      }
    } catch {
      if (seq === badgeSeq) fab.setAttribute("aria-label", label);
    }
  }

  // --- Annotation layer: highlights + markers + margin comment cards ----------
  // Google-Docs-style: every located comment gets a high-contrast <mark>, a 💬
  // marker, and a margin card aligned with its anchor. Clicking a highlight
  // focuses its card; clicking a card (or a quote in the panel) scrolls to the
  // highlight. On narrow screens cards hide and float up when activated.

  let pageComments = [];
  let mineIds = new Set();
  let annotations = []; // [{comment, mark, card}]
  let activeCommentId = null;
  let annotationsPayload = "";

  async function refreshAnnotations({ force = false } = {}) {
    // Don't rebuild while the user is typing in a margin card.
    if (!force && marginLayer.contains(document.activeElement)) return;
    try {
      const [all, mine] = await Promise.all([
        api("GET", `/comments?page=${encodeURIComponent(cfg.page)}`),
        api("GET", `/comments/mine?token=${encodeURIComponent(store.token)}`).catch(() => ({ comments: [] })),
      ]);
      mineIds = new Set(mine.comments.map((c) => c.id));
      // Re-check after the await: the user may have started typing in a
      // margin card while the fetch was in flight.
      if (!force && marginLayer.contains(document.activeElement)) return;
      const payload = JSON.stringify(all.comments) + store.role;
      if (!force && payload === annotationsPayload) return;
      annotationsPayload = payload;
      pageComments = all.comments;
      renderAnnotations();
    } catch {
      /* server unreachable — keep whatever is on screen */
    }
  }

  function clearAnnotations() {
    for (const marker of document.querySelectorAll("button.anon-marker")) marker.remove();
    for (const mark of document.querySelectorAll("mark.anon-highlight")) {
      const parent = mark.parentNode;
      while (mark.firstChild) parent.insertBefore(mark.firstChild, mark);
      mark.remove();
      parent.normalize();
    }
    marginLayer.textContent = "";
    annotations = [];
  }

  function locateRange(needle) {
    const main = document.getElementById("main");
    if (!main || !needle) return null;
    const walker = document.createTreeWalker(main, NodeFilter.SHOW_TEXT);
    let node;
    while ((node = walker.nextNode())) {
      if (node.parentElement?.closest(".anon-root, mark.anon-highlight")) continue;
      const index = node.textContent.indexOf(needle);
      if (index === -1) continue;
      const range = document.createRange();
      range.setStart(node, index);
      range.setEnd(node, index + needle.length);
      return range;
    }
    return null;
  }

  function wrapComment(comment) {
    const full = comment.anchor?.selectedText ?? "";
    // Full match first; long/multi-line selections span text nodes, so fall
    // back to marking a leading fragment (Google Docs anchors survive this too).
    let range = locateRange(full);
    if (!range && full.includes("\n")) range = locateRange(full.split("\n")[0].trim());
    if (!range && full.length > 60) {
      const short = full.slice(0, 60).replace(/\s+\S*$/, "");
      if (short.length >= 12) range = locateRange(short);
    }
    if (!range) return null;
    const mark = document.createElement("mark");
    mark.className = "anon-highlight";
    mark.dataset.commentId = comment.id;
    mark.title = "Commented — click to view";
    try {
      range.surroundContents(mark);
    } catch {
      return null;
    }
    mark.addEventListener("click", () => activateComment(comment.id, "mark"));
    // The glyph is a CSS pseudo-element so it never appears in text selections
    // or innerText (which feed the AI's anchors).
    const marker = el("button", {
      class: "anon-marker",
      type: "button",
      "aria-label": `View comment by ${comment.displayName || "Anonymous"}`,
      onclick: () => activateComment(comment.id, "mark"),
    });
    mark.after(marker);
    return mark;
  }

  function buildMarginCard(comment) {
    const isMine = mineIds.has(comment.id);
    const statusLabel = comment.suggestion
      ? comment.suggestion.status
      : comment.status === "resolved"
        ? "resolved"
        : "open";
    const preview =
      comment.commentText.length > 90 ? `${comment.commentText.slice(0, 90)}…` : comment.commentText;

    const body = el("div", { class: "anon-margin-body", hidden: true });
    const head = el(
      "button",
      {
        class: "anon-margin-head",
        type: "button",
        "aria-expanded": "false",
        onclick: () => {
          const expanded = !body.hidden;
          if (expanded && activeCommentId === comment.id) {
            deactivateComment();
          } else {
            activateComment(comment.id, "card");
          }
        },
      },
      el(
        "span",
        { class: "anon-margin-meta" },
        `${comment.displayName || "Anonymous"}${isMine ? " (you)" : ""}`,
        el("span", { class: `anon-chip anon-chip-${statusLabel}` }, statusLabel),
      ),
      el("span", { class: "anon-margin-preview" }, preview),
    );

    body.append(el("p", { style: "margin:6px 0" }, comment.commentText));
    if (comment.suggestion) {
      body.append(
        el(
          "p",
          { class: "anon-margin-note" },
          `Includes a suggested edit (${comment.suggestion.status}) — open the feedback panel for the full diff.`,
        ),
      );
      if (comment.suggestion.status !== "applied" && (store.role === "instructor" || isMine)) {
        body.append(
          el("div", { class: "anon-btn-row" }, previewButton({ commentId: comment.id })),
        );
      }
    }
    for (const reply of comment.replies) {
      body.append(
        el(
          "div",
          { class: "anon-reply" },
          el(
            "span",
            { class: "anon-reply-author" },
            reply.author === "instructor" ? "Instructor: " : isMine ? "You: " : "Student: ",
          ),
          reply.text,
        ),
      );
    }
    if (store.role === "instructor") {
      body.append(
        renderReplyForm(comment, "instructor"),
        el(
          "div",
          { class: "anon-btn-row" },
          resolveButton(comment),
          el(
            "button",
            {
              class: "anon-btn",
              type: "button",
              onclick: () => {
                pendingFocusId = `anon-card-${comment.id}`;
                if (panel.hidden) openPanel();
                else render();
              },
            },
            "Review in panel",
          ),
        ),
      );
    } else if (isMine) {
      body.append(renderReplyForm(comment, "student"));
    }

    return el(
      "div",
      { class: "anon-margin-card", id: `anon-margin-${comment.id}` },
      head,
      body,
    );
  }

  function renderAnnotations() {
    const hadActive = activeCommentId;
    const hadFocus = marginLayer.contains(document.activeElement);
    clearAnnotations();
    activeCommentId = null;
    for (const comment of pageComments) {
      // General whole-page comments have no text anchor: no mark, card pinned
      // at the top of the document.
      const mark = comment.anchor?.general ? null : wrapComment(comment);
      if (!mark && !comment.anchor?.general) continue;
      const card = buildMarginCard(comment);
      marginLayer.append(card);
      annotations.push({ comment, mark, card });
    }
    positionCards();
    // Keep the active card open across a data refresh (e.g. after replying),
    // and restore focus if the destroyed DOM had it.
    if (hadActive && annotations.some((a) => a.comment.id === hadActive)) {
      activateComment(hadActive, "refresh");
      if (hadFocus) {
        annotations
          .find((a) => a.comment.id === hadActive)
          ?.card.querySelector(".anon-margin-head")
          ?.focus();
      }
    }
  }

  function marginSpace() {
    const main = document.getElementById("main");
    if (!main) return 0;
    return window.innerWidth - main.getBoundingClientRect().right;
  }

  function positionCards() {
    if (!annotations.length) return;
    const main = document.getElementById("main");
    const rect = main.getBoundingClientRect();
    const space = marginSpace();
    const marginMode = space >= 260;
    if (!marginMode) {
      for (const a of annotations) {
        a.card.classList.add("anon-card-overlay");
        // Keep the active card visible as a floating sheet across a
        // wide→narrow resize.
        a.card.classList.toggle("anon-floating", a.comment.id === activeCommentId);
      }
      return;
    }
    const left = window.scrollX + rect.right + 16;
    const width = Math.min(space - 32, 320);
    // General comments (no mark) pin above everything at the top of <main>.
    const anchorTop = (a) => (a.mark ? a.mark.getBoundingClientRect().top : rect.top - 4);
    const sorted = annotations.slice().sort((a, b) => anchorTop(a) - anchorTop(b));
    let prevBottom = 0;
    for (const a of sorted) {
      a.card.classList.remove("anon-card-overlay", "anon-floating");
      a.card.style.left = `${left}px`;
      a.card.style.width = `${width}px`;
      const anchorY = window.scrollY + anchorTop(a);
      const top = Math.max(anchorY, prevBottom + 8);
      a.card.style.top = `${top}px`;
      prevBottom = top + a.card.offsetHeight;
    }
  }

  function setExpanded(entry, expanded) {
    entry.card.querySelector(".anon-margin-head").setAttribute("aria-expanded", String(expanded));
    entry.card.querySelector(".anon-margin-body").hidden = !expanded;
  }

  function deactivateComment() {
    activeCommentId = null;
    for (const a of annotations) {
      a.mark?.classList.remove("anon-active");
      a.card.classList.remove("anon-active", "anon-floating");
      setExpanded(a, false);
    }
    positionCards();
  }

  function activateComment(id, origin) {
    const entry = annotations.find((a) => a.comment.id === id);
    if (!entry) {
      announce("This comment's text couldn't be located on the page.");
      return;
    }
    activeCommentId = id;
    const floating = marginSpace() < 260;
    for (const a of annotations) {
      const on = a === entry;
      a.mark?.classList.toggle("anon-active", on);
      a.card.classList.toggle("anon-active", on);
      a.card.classList.toggle("anon-floating", on && floating);
      setExpanded(a, on);
    }
    positionCards();
    const smooth = window.matchMedia("(prefers-reduced-motion: reduce)").matches ? "auto" : "smooth";
    if (origin !== "refresh") {
      // General comments have no mark — scroll to the top of the document.
      const target = entry.mark || document.getElementById("main");
      target?.scrollIntoView({ block: entry.mark ? "center" : "start", behavior: smooth });
    }
    if (origin === "mark" && !floating) {
      entry.card.querySelector(".anon-margin-head").focus();
    }
    // A background data refresh must not re-announce the comment.
    if (origin !== "refresh") {
      announce(
        `Comment by ${entry.comment.displayName || "Anonymous"}: ${entry.comment.commentText.slice(0, 120)}`,
      );
    }
  }

  let resizeTimer = null;
  window.addEventListener("resize", () => {
    clearTimeout(resizeTimer);
    resizeTimer = setTimeout(positionCards, 150);
  });

  // --- Boot ----------------------------------------------------------------------

  function boot() {
    document.body.appendChild(root);
    api("GET", "/settings")
      .then((s) => {
        aiSettings = s;
      })
      .catch(() => {});
    updateBadge();
    refreshAnnotations({ force: true }).then(() => {
      // Deep link from the dashboard: /page.html#anon-comment=<id>
      const match = location.hash.match(/anon-comment=([\w-]+)/);
      if (match) activateComment(match[1], "hash");
    });
    // Keep annotations and the badge fresh (new comments, instructor replies).
    setInterval(() => {
      refreshAnnotations();
      updateBadge();
    }, 10000);
    // First-run tour for students (replayable from Settings).
    if (!localStorage.getItem("anon-tutorial-done") && store.role !== "instructor") {
      setTimeout(() => {
        if (window.AnonTutorial && !window.AnonTutorial.isRunning()) startTutorial();
      }, 800);
    }
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", boot);
  } else {
    boot();
  }
})();
