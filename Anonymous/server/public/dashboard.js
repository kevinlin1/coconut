// Instructor dashboard: cross-page feedback view with approve/reject/edit,
// replies, resolve, apply-to-site (stretch), and AI settings.
(function () {
  "use strict";

  const listEl = document.getElementById("feedback-list");
  const liveEl = document.getElementById("live");
  const pageFilter = document.getElementById("filter-page");
  const statusFilter = document.getElementById("filter-status");

  let comments = [];
  let lastPayload = "";

  function announce(message) {
    liveEl.textContent = "";
    requestAnimationFrame(() => {
      liveEl.textContent = message;
    });
  }

  async function api(method, path, body) {
    const res = await fetch(`/api${path}`, {
      method,
      headers: body ? { "Content-Type": "application/json" } : undefined,
      body: body ? JSON.stringify(body) : undefined,
    });
    const data = await res.json().catch(() => ({}));
    if (!res.ok) throw Object.assign(new Error(data.error || res.statusText), { status: res.status, data });
    return data;
  }

  function el(tag, attrs, ...children) {
    const node = document.createElement(tag);
    for (const [key, value] of Object.entries(attrs || {})) {
      if (key.startsWith("on") && typeof value === "function") node.addEventListener(key.slice(2), value);
      else if (key === "class") node.className = value;
      else if (value !== undefined && value !== null && value !== false) {
        node.setAttribute(key, value === true ? "" : value);
      }
    }
    for (const child of children.flat()) {
      if (child === null || child === undefined) continue;
      node.appendChild(typeof child === "string" ? document.createTextNode(child) : child);
    }
    return node;
  }

  // --- Settings -----------------------------------------------------------------

  async function loadSettings() {
    const statusEl = document.getElementById("ai-status");
    try {
      const settings = await api("GET", "/settings");
      statusEl.textContent = "";
      statusEl.appendChild(
        settings.aiConfigured
          ? el("span", { class: "status-ok" }, `✓ AI configured (${settings.model})`)
          : el("span", {}, "AI is not configured — student suggestion generation is disabled."),
      );
    } catch {
      statusEl.textContent = "Couldn't reach the server.";
    }
  }

  // --- Publish: apply every approved suggestion, rebuild site + PDFs once ------

  document.getElementById("publish").addEventListener("click", async (event) => {
    const button = event.currentTarget;
    const statusEl = document.getElementById("publish-status");
    button.disabled = true;
    button.setAttribute("aria-busy", "true");
    statusEl.textContent = "Applying approved suggestions and recompiling the site and PDFs…";
    announce("Rebuilding the site — this takes a few seconds.");
    try {
      const result = await api("POST", "/apply-all");
      const skippedNote = result.skipped?.length
        ? ` ${result.skipped.length} could not be applied (source changed) — see their cards.`
        : "";
      statusEl.textContent = `✓ Applied ${result.applied} change${result.applied === 1 ? "" : "s"} and rebuilt the site + PDFs.${skippedNote}`;
      announce(statusEl.textContent);
      refresh({ force: true });
    } catch (err) {
      statusEl.textContent = `Rebuild failed: ${err.data?.log || err.message}`;
      announce("Rebuild failed.");
    }
    button.disabled = false;
    button.removeAttribute("aria-busy");
  });

  document.getElementById("save-key").addEventListener("click", async () => {
    const input = document.getElementById("api-key");
    try {
      const settings = await api("PUT", "/settings", { apiKey: input.value });
      announce(settings.aiConfigured ? "API key saved. AI is ready." : "API key cleared.");
      input.value = "";
      loadSettings();
    } catch {
      announce("Couldn't save the API key.");
    }
  });

  // --- Data + polling -------------------------------------------------------------

  async function refresh({ force = false } = {}) {
    // Don't clobber in-progress interaction: skip re-render while focus is in
    // the list or on a filter (rebuilding an open <select> closes its dropdown).
    const active = document.activeElement;
    if (!force && (listEl.contains(active) || active === pageFilter || active === statusFilter)) {
      return;
    }
    let data;
    try {
      data = await api("GET", "/comments");
    } catch {
      if (!comments.length) {
        listEl.textContent = "";
        listEl.appendChild(el("p", { class: "dash-empty status-err" }, "Couldn't reach the server."));
      }
      return;
    }
    const payload = JSON.stringify(data.comments);
    if (!force && payload === lastPayload) return;
    const isNew = lastPayload && data.comments.length > comments.length;
    lastPayload = payload;
    comments = data.comments;
    renderPageFilter();
    renderList();
    if (isNew) announce("New feedback received.");
  }

  function renderPageFilter() {
    const current = pageFilter.value;
    const pages = [...new Set(comments.map((c) => c.page))].sort();
    pageFilter.textContent = "";
    pageFilter.appendChild(el("option", { value: "" }, "All pages"));
    for (const page of pages) {
      pageFilter.appendChild(el("option", { value: page, selected: page === current ? true : undefined }, page));
    }
  }

  pageFilter.addEventListener("change", renderList);
  statusFilter.addEventListener("change", renderList);

  // --- Rendering -------------------------------------------------------------------

  function renderList() {
    listEl.textContent = "";
    let visible = comments;
    if (pageFilter.value) visible = visible.filter((c) => c.page === pageFilter.value);
    if (statusFilter.value) visible = visible.filter((c) => c.status === statusFilter.value);
    if (!visible.length) {
      listEl.appendChild(el("p", { class: "dash-empty" }, "No feedback matches these filters."));
      return;
    }
    for (const comment of visible.slice().reverse()) {
      listEl.appendChild(renderCard(comment));
    }
  }

  function chip(label) {
    return el("span", { class: `chip chip-${label}` }, label);
  }

  // After an action rebuilds the list, refocus the acted-on card so keyboard
  // and screen-reader users keep their place.
  async function refreshAndRefocus(commentId) {
    await refresh({ force: true });
    document.getElementById(`card-${commentId}`)?.focus();
  }

  function renderCard(comment) {
    const card = el("article", {
      class: "dash-card",
      id: `card-${comment.id}`,
      tabindex: "-1",
      "aria-label": `Feedback from ${comment.displayName || "Anonymous"}`,
    });

    const meta = el(
      "p",
      { class: "dash-card-meta" },
      el("strong", {}, comment.displayName || "Anonymous"),
      ` · ${new Date(comment.createdAt).toLocaleString()} · `,
      el("a", { href: comment.page === "index" ? "/" : `/${comment.page}.html` }, comment.page),
      comment.suggestion ? chip(comment.suggestion.status) : null,
      chip(comment.status === "resolved" ? "resolved" : "open"),
    );

    const pageHref = comment.page === "index" ? "/" : `/${comment.page}.html`;
    card.append(
      meta,
      el(
        "a",
        {
          class: "quote-link",
          href: `${pageHref}#anon-comment=${comment.id}`,
          "aria-label": `Open this comment's location on the ${comment.page} page`,
        },
        el(
          "blockquote",
          { class: "quote" },
          el("span", { class: "quote-label" }, comment.anchor.section ? "Section" : "Selected text"),
          comment.anchor.selectedText.slice(0, 300),
          el("span", { class: "quote-hint" }, "Open on page →"),
        ),
      ),
      el("p", {}, comment.commentText),
    );

    if (comment.suggestion) card.append(renderSuggestion(comment));

    for (const reply of comment.replies) {
      card.append(
        el(
          "div",
          { class: "reply" },
          el("span", { class: "reply-author" }, reply.author === "instructor" ? "You: " : "Student: "),
          reply.text,
        ),
      );
    }

    const replyInput = el("input", { type: "text", "aria-label": "Reply to this feedback", placeholder: "Reply to the student…" });
    card.append(
      el(
        "form",
        {
          class: "reply-form",
          onsubmit: async (event) => {
            event.preventDefault();
            if (!replyInput.value.trim()) return;
            try {
              await api("POST", `/comments/${comment.id}/replies`, { author: "instructor", text: replyInput.value });
              announce("Reply sent.");
              refreshAndRefocus(comment.id);
            } catch {
              announce("Couldn't send reply.");
            }
          },
        },
        replyInput,
        el("button", { class: "dash-btn", type: "submit" }, "Reply"),
      ),
      el(
        "div",
        { class: "dash-btn-row" },
        el(
          "button",
          {
            class: "dash-btn",
            type: "button",
            onclick: async () => {
              try {
                await api("PATCH", `/comments/${comment.id}`, {
                  status: comment.status === "resolved" ? "open" : "resolved",
                });
                announce(comment.status === "resolved" ? "Reopened." : "Marked resolved.");
                refreshAndRefocus(comment.id);
              } catch {
                announce("Action failed.");
              }
            },
          },
          comment.status === "resolved" ? "Reopen" : "Mark resolved",
        ),
      ),
    );
    return card;
  }

  function renderSuggestion(comment) {
    const suggestion = comment.suggestion;
    const wrap = el("div", { class: "suggestion" });

    wrap.append(el("div", { class: "diff-label" }, "Current source"));
    const originalPre = el("pre", { class: "diff" });
    originalPre.appendChild(el("del", {}, suggestion.originalSnippet));
    wrap.append(originalPre);

    wrap.append(
      el(
        "div",
        { class: "diff-label" },
        `Suggested${suggestion.aiGenerated ? " (AI)" : " (student-edited)"}${suggestion.instructorEdited ? " (instructor-edited)" : ""}`,
      ),
    );
    const suggestedPre = el("pre", { class: "diff" });
    suggestedPre.appendChild(
      window.AnonDiff
        ? window.AnonDiff.render(suggestion.originalSnippet, suggestion.replacementSnippet)
        : document.createTextNode(suggestion.replacementSnippet),
    );
    wrap.append(suggestedPre);

    if (suggestion.rationale) wrap.append(el("p", { class: "rationale" }, suggestion.rationale));

    const patch = async (body, message) => {
      try {
        await api("PATCH", `/comments/${comment.id}/suggestion`, body);
        announce(message);
        refreshAndRefocus(comment.id);
      } catch {
        announce("Action failed.");
      }
    };

    const actions = el("div", { class: "dash-btn-row" });
    if (suggestion.status === "pending") {
      actions.append(
        el("button", { class: "dash-btn dash-btn-primary", type: "button", onclick: () => patch({ status: "approved" }, "Suggestion approved.") }, "Approve"),
        el("button", { class: "dash-btn dash-btn-danger", type: "button", onclick: () => patch({ status: "rejected" }, "Suggestion rejected.") }, "Reject"),
      );
    }
    if (suggestion.status === "approved") {
      actions.append(
        el(
          "button",
          {
            class: "dash-btn dash-btn-primary",
            type: "button",
            onclick: async (event) => {
              const button = event.currentTarget;
              button.disabled = true;
              button.textContent = "Applying…";
              announce("Applying the change and recompiling the site…");
              try {
                await api("POST", `/apply/${comment.id}`);
                announce("Change applied — the site has been recompiled.");
                refreshAndRefocus(comment.id);
              } catch (err) {
                announce("Apply failed.");
                button.disabled = false;
                button.textContent = "Apply to site";
                wrap.append(
                  el("p", { class: "status-err" }, "Apply failed:"),
                  el("pre", { class: "apply-log" }, err.data?.log || err.message),
                );
              }
            },
          },
          "Apply to site",
        ),
        el("button", { class: "dash-btn", type: "button", onclick: () => patch({ status: "pending" }, "Moved back to pending.") }, "Undo approval"),
      );
    }
    if (suggestion.status !== "applied") {
      actions.append(
        el(
          "button",
          {
            class: "dash-btn",
            type: "button",
            onclick: async (event) => {
              const button = event.currentTarget;
              const label = button.textContent;
              button.disabled = true;
              button.textContent = "Building preview…";
              announce("Building preview — this takes a few seconds.");
              try {
                const result = await api("POST", "/preview", { commentId: comment.id });
                window.open(result.url, "_blank", "noopener");
                announce("Preview opened in a new tab.");
              } catch (err) {
                announce(`Couldn't build the preview. ${err.data?.log || ""}`.trim());
              }
              button.disabled = false;
              button.textContent = label;
            },
          },
          "Preview change",
        ),
        el(
          "button",
          {
            class: "dash-btn",
            type: "button",
            onclick: (event) => {
              const editArea = el("textarea", { class: "diff", "aria-label": "Edit the suggested replacement" });
              editArea.value = suggestion.replacementSnippet;
              const save = el(
                "button",
                {
                  class: "dash-btn dash-btn-primary",
                  type: "button",
                  onclick: () => patch({ replacementSnippet: editArea.value }, "Suggestion updated."),
                },
                "Save edit",
              );
              event.currentTarget.replaceWith(save);
              suggestedPre.replaceWith(editArea);
              editArea.focus();
            },
          },
          "Edit",
        ),
      );
    }
    wrap.append(actions);
    return wrap;
  }

  // --- Boot ---------------------------------------------------------------------

  loadSettings();
  refresh({ force: true });
  setInterval(refresh, 5000);
})();
