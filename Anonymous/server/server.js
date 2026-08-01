// "Anonymous" — anonymous course-materials feedback for the coconut course site.
// Serves the compiled site from ../main/ with a feedback overlay injected,
// plus a JSON API for comments, replies, AI suggestions, and settings.
// Everything lives inside Anonymous/; repo files are read-only.
import express from "express";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { db, settings, scheduleSave, saveSettings, newId, findComment } from "./store.js";
import { suggest, getApiKey, currentModel } from "./ai.js";
import {
  getSiteDir,
  getPreviewDir,
  applyAndCompile,
  applyManyAndCompile,
  compilePreview,
} from "./typst.js";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const PUBLIC_DIR = path.join(__dirname, "public");
const PORT = process.env.PORT || 4820;

const app = express();
app.use(express.json({ limit: "1mb" }));

// --- Overlay assets + instructor dashboard ---------------------------------

app.use("/__anon", express.static(PUBLIC_DIR));
app.get("/instructor", (_req, res) => {
  res.sendFile(path.join(PUBLIC_DIR, "dashboard.html"));
});

// --- API: comments -----------------------------------------------------------

// Never leak the browser-local author token to other clients.
function toPublic(comment) {
  const { authorToken, ...rest } = comment;
  return rest;
}

app.get("/api/comments", (req, res) => {
  let comments = db.comments;
  if (req.query.page) comments = comments.filter((c) => c.page === req.query.page);
  res.json({ comments: comments.map(toPublic) });
});

app.get("/api/comments/mine", (req, res) => {
  const { token, page } = req.query;
  if (!token) return res.status(400).json({ error: "token required" });
  let comments = db.comments.filter((c) => c.authorToken === token);
  if (page) comments = comments.filter((c) => c.page === page);
  res.json({ comments: comments.map(toPublic) });
});

app.post("/api/comments", (req, res) => {
  const { page, anchor, commentText, displayName, authorToken, suggestion } = req.body ?? {};
  if (!page || typeof page !== "string") return res.status(400).json({ error: "page required" });
  if (!anchor?.selectedText && !anchor?.general) {
    return res.status(400).json({ error: "anchor.selectedText or anchor.general required" });
  }
  if (!commentText?.trim()) return res.status(400).json({ error: "commentText required" });
  if (!authorToken) return res.status(400).json({ error: "authorToken required" });

  const comment = {
    id: newId(),
    page,
    createdAt: new Date().toISOString(),
    authorToken,
    displayName: displayName?.trim() ? displayName.trim().slice(0, 60) : null,
    anchor: {
      selectedText: String(anchor.selectedText ?? "").slice(0, 2000),
      prefix: String(anchor.prefix ?? "").slice(0, 200),
      suffix: String(anchor.suffix ?? "").slice(0, 200),
      section: Boolean(anchor.section),
      general: Boolean(anchor.general),
    },
    commentText: commentText.trim().slice(0, 5000),
    suggestion:
      suggestion?.originalSnippet && suggestion?.replacementSnippet
        ? {
            status: "pending",
            originalSnippet: String(suggestion.originalSnippet),
            replacementSnippet: String(suggestion.replacementSnippet),
            rationale: String(suggestion.rationale ?? ""),
            aiGenerated: suggestion.aiGenerated !== false,
            instructorEdited: false,
          }
        : null,
    replies: [],
    status: "open",
  };
  db.comments.push(comment);
  scheduleSave();
  res.status(201).json({ comment: toPublic(comment) });
});

app.post("/api/comments/:id/replies", (req, res) => {
  const comment = findComment(req.params.id);
  if (!comment) return res.status(404).json({ error: "not found" });
  const { author, text, authorToken } = req.body ?? {};
  if (!["instructor", "student"].includes(author)) {
    return res.status(400).json({ error: "author must be instructor or student" });
  }
  if (!text?.trim()) return res.status(400).json({ error: "text required" });
  if (author === "student" && authorToken !== comment.authorToken) {
    return res.status(403).json({ error: "only the comment author may reply as student" });
  }
  const reply = {
    id: newId(),
    author,
    text: text.trim().slice(0, 5000),
    createdAt: new Date().toISOString(),
  };
  comment.replies.push(reply);
  scheduleSave();
  res.status(201).json({ comment: toPublic(comment) });
});

app.patch("/api/comments/:id/suggestion", (req, res) => {
  const comment = findComment(req.params.id);
  if (!comment) return res.status(404).json({ error: "not found" });
  if (!comment.suggestion) return res.status(400).json({ error: "comment has no suggestion" });
  const { status, replacementSnippet } = req.body ?? {};
  if (status !== undefined) {
    if (!["approved", "rejected", "pending"].includes(status)) {
      return res.status(400).json({ error: "invalid status" });
    }
    comment.suggestion.status = status;
  }
  if (replacementSnippet !== undefined) {
    if (!String(replacementSnippet).trim()) {
      return res.status(400).json({ error: "replacementSnippet must be non-empty" });
    }
    comment.suggestion.replacementSnippet = String(replacementSnippet);
    comment.suggestion.instructorEdited = true;
  }
  scheduleSave();
  res.json({ comment: toPublic(comment) });
});

// Students can delete their own comments (authorToken must match).
app.delete("/api/comments/:id", (req, res) => {
  const index = db.comments.findIndex((c) => c.id === req.params.id);
  if (index === -1) return res.status(404).json({ error: "not found" });
  const { authorToken } = req.body ?? {};
  if (!authorToken || authorToken !== db.comments[index].authorToken) {
    return res.status(403).json({ error: "only the comment author may delete it" });
  }
  db.comments.splice(index, 1);
  scheduleSave();
  res.json({ ok: true });
});

app.patch("/api/comments/:id", (req, res) => {
  const comment = findComment(req.params.id);
  if (!comment) return res.status(404).json({ error: "not found" });
  const { status } = req.body ?? {};
  if (!["open", "resolved"].includes(status)) {
    return res.status(400).json({ error: "status must be open or resolved" });
  }
  comment.status = status;
  scheduleSave();
  res.json({ comment: toPublic(comment) });
});

// --- API: AI suggestions -----------------------------------------------------

app.post("/api/ai/suggest", async (req, res) => {
  const { page, anchor, commentText } = req.body ?? {};
  if (!anchor?.selectedText || !commentText?.trim()) {
    return res.status(400).json({ error: "anchor.selectedText and commentText required" });
  }
  try {
    const result = await suggest({ page, anchor, commentText });
    if (result.error === "not_configured") {
      return res.status(409).json({ error: "not_configured" });
    }
    if (result.error) return res.status(502).json({ error: result.error });
    res.json(result);
  } catch (err) {
    console.error("AI suggestion failed:", err.message);
    res.status(502).json({ error: "ai_unavailable", detail: err.message });
  }
});

// --- API: settings -----------------------------------------------------------

app.get("/api/settings", (_req, res) => {
  res.json({ aiConfigured: Boolean(getApiKey()), model: currentModel() });
});

app.put("/api/settings", (req, res) => {
  const { apiKey } = req.body ?? {};
  if (typeof apiKey !== "string") return res.status(400).json({ error: "apiKey required" });
  if (apiKey.trim()) settings.geminiApiKey = apiKey.trim();
  else delete settings.geminiApiKey;
  saveSettings();
  res.json({ aiConfigured: Boolean(getApiKey()), model: currentModel() });
});

// --- API: change preview (throwaway compile, nothing saved) ------------------

app.post("/api/preview", (req, res) => {
  let { commentId, page, originalSnippet, replacementSnippet } = req.body ?? {};
  if (commentId) {
    const comment = findComment(commentId);
    if (!comment?.suggestion) return res.status(404).json({ error: "no suggestion" });
    page = comment.page;
    originalSnippet = comment.suggestion.originalSnippet;
    replacementSnippet = comment.suggestion.replacementSnippet;
  }
  if (!page || !originalSnippet || !replacementSnippet) {
    return res.status(400).json({ error: "commentId, or page + snippets, required" });
  }
  const result = compilePreview(originalSnippet, replacementSnippet);
  if (!result.ok) return res.status(422).json({ ok: false, log: result.log });
  res.json({ ok: true, url: `/__preview/${page}.html` });
});

// --- API: apply approved suggestions ------------------------------------------

app.post("/api/apply/:id", (req, res) => {
  const comment = findComment(req.params.id);
  if (!comment?.suggestion) return res.status(404).json({ error: "no suggestion" });
  if (comment.suggestion.status !== "approved") {
    return res.status(400).json({ error: "suggestion must be approved before applying" });
  }
  const { originalSnippet, replacementSnippet } = comment.suggestion;
  const result = applyAndCompile(originalSnippet, replacementSnippet);
  if (result.ok) {
    comment.suggestion.status = "applied";
    scheduleSave();
  }
  res.status(result.ok ? 200 : 422).json({ ok: result.ok, log: result.log });
});

// Apply every approved suggestion in one pass and rebuild the site + PDFs once.
app.post("/api/apply-all", (_req, res) => {
  const approved = db.comments.filter((c) => c.suggestion?.status === "approved");
  if (!approved.length) {
    return res.status(400).json({ ok: false, log: "No approved suggestions to apply." });
  }
  const result = applyManyAndCompile(
    approved.map((c) => ({
      id: c.id,
      originalSnippet: c.suggestion.originalSnippet,
      replacementSnippet: c.suggestion.replacementSnippet,
    })),
  );
  if (result.ok) {
    for (const r of result.results) {
      if (!r.applied) continue;
      const comment = findComment(r.id);
      if (comment?.suggestion) comment.suggestion.status = "applied";
    }
    scheduleSave();
  }
  const applied = result.results?.filter((r) => r.applied).length ?? 0;
  const skipped = result.results?.filter((r) => !r.applied) ?? [];
  res.status(result.ok ? 200 : 422).json({ ok: result.ok, applied, skipped, log: result.log });
});

// --- Site pages with overlay injection ---------------------------------------

function servePage(pageName, res) {
  if (!/^[a-z0-9-]+$/.test(pageName)) return res.status(404).send("Not found");
  const file = path.join(getSiteDir(), `${pageName}.html`);
  if (!fs.existsSync(file)) return res.status(404).send("Not found");
  const html = fs
    .readFileSync(file, "utf8")
    .replace(
      "</body>",
      `<script src="/__anon/overlay.js" data-anon-api="/api" data-anon-base="/__anon" data-anon-page="${pageName}" defer></script></body>`,
    );
  res.type("html").send(html);
}

app.get("/", (_req, res) => servePage("index", res));
app.get(/^\/([a-z0-9-]+)\.html$/, (req, res) => servePage(req.params[0], res));

// Preview pages: the throwaway build with one suggestion applied. Gets the
// preview banner script (not the feedback overlay).
app.get(/^\/__preview\/([a-z0-9-]+)\.html$/, (req, res) => {
  const pageName = req.params[0];
  if (!/^[a-z0-9-]+$/.test(pageName)) return res.status(404).send("Not found");
  const file = path.join(getPreviewDir(), `${pageName}.html`);
  if (!fs.existsSync(file)) {
    return res.status(404).send("No preview has been built yet.");
  }
  const html = fs
    .readFileSync(file, "utf8")
    .replace(
      "</body>",
      `<script src="/__anon/diff.js" defer></script><script src="/__anon/preview.js" data-anon-page="${pageName}" defer></script></body>`,
    );
  res.type("html").send(html);
});
app.use("/__preview", (req, res, next) => express.static(getPreviewDir())(req, res, next));

// Everything else (PDFs, any future assets) passes through untouched.
app.use((req, res, next) => express.static(getSiteDir())(req, res, next));

app.listen(PORT, () => {
  console.log(`Anonymous feedback server running:`);
  console.log(`  Student/instructor pages:  http://localhost:${PORT}/`);
  console.log(`  Full instructor dashboard: http://localhost:${PORT}/instructor`);
  console.log(`  AI configured: ${Boolean(getApiKey())}`);
});
