// Typst compilation against a shadow copy of main.typ kept entirely inside
// Anonymous/server/workdir/ — the repo's own files are never written.
//
// Three operations:
//   applyAndCompile(...)      — apply ONE suggestion permanently + rebuild
//   applyManyAndCompile(...)  — apply ALL approved suggestions + rebuild once
//   compilePreview(...)       — throwaway build with one suggestion applied,
//                               served at /__preview/ (nothing is saved)
//
// Every build uses `--format bundle`, which emits BOTH the HTML page and the
// PDF for every route — the "one source, both formats" property of main.typ.
import fs from "node:fs";
import path from "node:path";
import { spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const REPO_ROOT = path.resolve(__dirname, "..", "..");
const REAL_MAIN = path.join(REPO_ROOT, "main.typ");
const WORKDIR = path.join(__dirname, "workdir");
const SHADOW_MAIN = path.join(WORKDIR, "main.typ");
const SHADOW_SITE = path.join(WORKDIR, "site");
const PREVIEW_MAIN = path.join(WORKDIR, "preview.typ");
const PREVIEW_SITE = path.join(WORKDIR, "preview-site");
const DEFAULT_SITE = path.join(REPO_ROOT, "main");

// Serve the recompiled shadow site once it exists; the original build otherwise.
export function getSiteDir() {
  if (fs.existsSync(path.join(SHADOW_SITE, "index.html"))) return SHADOW_SITE;
  return DEFAULT_SITE;
}

export function getPreviewDir() {
  return PREVIEW_SITE;
}

function ensureShadow() {
  fs.mkdirSync(WORKDIR, { recursive: true });
  if (!fs.existsSync(SHADOW_MAIN)) {
    // Typst resolves absolute import paths from --root, so "/lib.typ" works
    // from anywhere under the repo root.
    const source = fs
      .readFileSync(REAL_MAIN, "utf8")
      .replace(`#import "lib.typ": *`, `#import "/lib.typ": *`);
    fs.writeFileSync(SHADOW_MAIN, source);
  }
}

export function readShadowSource() {
  ensureShadow();
  return fs.readFileSync(SHADOW_MAIN, "utf8");
}

function runTypst(inputFile, outputDir) {
  const result = spawnSync(
    "typst",
    [
      "compile",
      "--root", REPO_ROOT,
      "--features", "bundle,html",
      "--format", "bundle",
      inputFile,
      outputDir,
    ],
    { encoding: "utf8", shell: process.platform === "win32" },
  );
  if (result.error || result.status !== 0) {
    const log = result.error
      ? result.error.message
      : `${result.stderr || result.stdout || ""}`.trim();
    return { ok: false, log: log || `typst exited with status ${result.status}` };
  }
  return { ok: true, log: (result.stderr || "").trim() };
}

// Locate `snippet` in `content`: must appear exactly once.
function findUnique(content, snippet) {
  if (!snippet) return { ok: false, reason: "empty snippet" };
  const first = content.indexOf(snippet);
  if (first === -1) {
    return {
      ok: false,
      reason:
        "The original snippet no longer appears in the source (it may have been changed by an earlier applied suggestion).",
    };
  }
  if (content.indexOf(snippet, first + 1) !== -1) {
    return { ok: false, reason: "The original snippet appears more than once; refusing an ambiguous edit." };
  }
  return { ok: true };
}

// Apply one suggestion permanently and rebuild. Reverts on compile failure.
export function applyAndCompile(originalSnippet, replacementSnippet) {
  ensureShadow();
  const before = fs.readFileSync(SHADOW_MAIN, "utf8");
  const located = findUnique(before, originalSnippet);
  if (!located.ok) return { ok: false, log: located.reason };

  fs.writeFileSync(SHADOW_MAIN, before.replace(originalSnippet, replacementSnippet));
  const result = runTypst(SHADOW_MAIN, SHADOW_SITE);
  if (!result.ok) fs.writeFileSync(SHADOW_MAIN, before);
  return result;
}

// Apply a batch of suggestions (id + snippets), compile once. Edits that no
// longer match are skipped and reported; a compile failure reverts everything.
export function applyManyAndCompile(edits) {
  ensureShadow();
  const before = fs.readFileSync(SHADOW_MAIN, "utf8");
  let content = before;
  const results = [];
  for (const edit of edits) {
    const located = findUnique(content, edit.originalSnippet);
    if (located.ok) {
      content = content.replace(edit.originalSnippet, edit.replacementSnippet);
      results.push({ id: edit.id, applied: true });
    } else {
      results.push({ id: edit.id, applied: false, reason: located.reason });
    }
  }
  const appliedCount = results.filter((r) => r.applied).length;
  if (appliedCount === 0) {
    return { ok: false, log: "No approved suggestion could be applied to the current source.", results };
  }
  fs.writeFileSync(SHADOW_MAIN, content);
  const compile = runTypst(SHADOW_MAIN, SHADOW_SITE);
  if (!compile.ok) {
    fs.writeFileSync(SHADOW_MAIN, before);
    return {
      ok: false,
      log: compile.log,
      results: results.map((r) => ({ ...r, applied: false, reason: r.reason || "compile failed — nothing was applied" })),
    };
  }
  return { ok: true, log: compile.log, results };
}

// Throwaway preview build with one suggestion applied; nothing is saved.
export function compilePreview(originalSnippet, replacementSnippet) {
  const base = readShadowSource();
  const located = findUnique(base, originalSnippet);
  if (!located.ok) return { ok: false, log: located.reason };
  fs.writeFileSync(PREVIEW_MAIN, base.replace(originalSnippet, replacementSnippet));
  return runTypst(PREVIEW_MAIN, PREVIEW_SITE);
}
