# Anonymous — course-materials feedback (hackathon MVP)

Students leave anonymous feedback directly on the compiled course site; Gemini
drafts a suggested edit to the underlying Typst source (Google-Docs-suggestion
style); the instructor reviews, replies, and can apply approved edits with a
live recompile. Everything lives in `Anonymous/` — the rest of the repo is
read-only.

## Run

```powershell
cd Anonymous/server
npm install
node server.js
```

Prerequisite: the site has been compiled at least once into `main/`
(`typst watch main.typ --features bundle,html --format bundle` from the repo root).

- **Student / instructor pages:** http://localhost:4820/ (also `/schedule.html`, etc.)
  — open the **Feedback** button, and switch views with the "View as" toggle in the panel.
- **Full instructor dashboard:** http://localhost:4820/instructor
- **Gemini API key:** paste it in the panel's **Settings** tab (or the dashboard's
  "AI settings"), or set `$env:GEMINI_API_KEY` before starting. Without a key the
  app still works — comments only, no AI suggestions.

## How it works

- `server.js` serves the compiled site from `../main/`, injecting
  `/__anon/overlay.js` before `</body>` on the fly, and exposes a JSON API
  (comments, replies, AI suggestions, settings).
- `overlay.js` is a self-contained vanilla-JS overlay (config from its own
  script tag's `data-*` attributes), designed to convert to an MV3 browser
  extension content script later.
- `ai.js` sends the full `main.typ` plus the selected rendered text and the
  student's comment to Gemini (`gemini-3.5-flash-lite`, with automatic fallback
  to the newest available flash-lite model) and validates that the returned
  `original_snippet` appears exactly once in the source before showing it.
- **Preview change** (any suggestion, both roles): compiles a throwaway build
  with just that edit applied and opens it at `/__preview/<page>.html` — a
  banner shows old → new and the changed text is highlighted in place. Nothing
  is saved.
- **Apply to site** (dashboard, per approved suggestion) and **Apply approved &
  rebuild site + PDFs** (dashboard, one click for all approved suggestions)
  edit a shadow copy of `main.typ` under `Anonymous/server/workdir/` and
  recompile with the local `typst` CLI in bundle format — web pages and PDFs
  rebuild together from the one source. The served site switches to the
  recompiled copy. Repo files are never modified.

## Accessibility

Fully keyboard-operable: `Alt+C` comments on the current text selection, and a
"Comment on a section" picker skips text selection entirely. The panel is a
labelled dialog with an ARIA tab interface, focus management, Esc-to-close,
`aria-live` announcements for async events, `<del>`/`<ins>` diff semantics, and
WCAG AA contrast.

## Storage

`data/db.json` (comments) and `data/settings.json` (API key) — plain JSON,
gitignored, safe to delete for a fresh start.
