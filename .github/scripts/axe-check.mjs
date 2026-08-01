// Runs axe-core over every HTML file the bundle export produced.
//
// The pages are self-contained — inline stylesheet, no scripts, no external
// assets — so they are loaded straight off disk over file:// rather than
// through a server. Exits non-zero if any page has a violation, and writes the
// full axe result for every page to a JSON report for the CI artifact.
//
// Usage: node axe-check.mjs <directory>... [--report <path>] [--tags a,b,c]

import { readdir, writeFile, mkdir } from "node:fs/promises";
import { pathToFileURL } from "node:url";
import path from "node:path";
import { chromium } from "playwright";
import AxeBuilder from "@axe-core/playwright";

// WCAG 2.2 AA is the conformance target; `best-practice` adds the structural
// rules the package promises (one main landmark, no skipped heading levels).
const DEFAULT_TAGS = [
  "wcag2a",
  "wcag2aa",
  "wcag21a",
  "wcag21aa",
  "wcag22aa",
  "best-practice",
];

function parseArgs(argv) {
  const args = { dirs: [], report: null, tags: DEFAULT_TAGS };
  for (let i = 0; i < argv.length; i++) {
    if (argv[i] === "--report") args.report = argv[++i];
    else if (argv[i] === "--tags") args.tags = argv[++i].split(",").map((t) => t.trim());
    else args.dirs.push(argv[i]);
  }
  if (args.dirs.length === 0) {
    console.error("usage: node axe-check.mjs <directory>... [--report <path>] [--tags <a,b>]");
    process.exit(2);
  }
  return args;
}

// Every HTML file under `dir`, as { label, path } — the label is what shows up
// in the log and the report, so it stays relative to the directory given.
async function htmlFiles(dir) {
  const entries = await readdir(dir, { recursive: true, withFileTypes: true });
  return entries
    .filter((e) => e.isFile() && e.name.endsWith(".html"))
    .map((e) => path.join(e.parentPath ?? e.path, e.name))
    .sort()
    .map((p) => ({ label: path.relative(".", p), path: p }));
}

// axe reports one violation per rule with an array of offending nodes; print
// every node so a failure names the element rather than only the rule.
function printViolations(file, violations) {
  console.log(`\n✗ ${file}`);
  for (const v of violations) {
    console.log(`  [${v.impact ?? "unknown"}] ${v.id}: ${v.help}`);
    console.log(`    ${v.helpUrl}`);
    for (const node of v.nodes) {
      console.log(`    at ${node.target.join(" ")}`);
      const detail = node.failureSummary?.split("\n").filter(Boolean) ?? [];
      for (const line of detail) console.log(`      ${line}`);
    }
  }
}

const { dirs, report, tags } = parseArgs(process.argv.slice(2));

const files = (await Promise.all(dirs.map(htmlFiles))).flat();

if (files.length === 0) {
  console.error(`No HTML files found in ${dirs.join(", ")} — did the Typst build run?`);
  process.exit(2);
}

console.log(`Checking ${files.length} page(s) with axe-core against: ${tags.join(", ")}`);

const browser = await chromium.launch();
// @axe-core/playwright injects into every frame, which it can only do from a
// page belonging to an explicit context.
const context = await browser.newContext();
const results = [];
let failed = 0;

try {
  for (const { label, path: file } of files) {
    const page = await context.newPage();
    try {
      await page.goto(pathToFileURL(path.resolve(file)).href, { waitUntil: "load" });
      const result = await new AxeBuilder({ page }).withTags(tags).analyze();
      results.push({ file: label, violations: result.violations, passes: result.passes.length });

      if (result.violations.length > 0) {
        failed++;
        printViolations(label, result.violations);
      } else {
        console.log(`✓ ${label} (${result.passes.length} checks passed)`);
      }
    } finally {
      await page.close();
    }
  }
} finally {
  await browser.close();
}

if (report) {
  await mkdir(path.dirname(report), { recursive: true });
  await writeFile(report, JSON.stringify({ tags, results }, null, 2));
  console.log(`\nFull axe report written to ${report}`);
}

const total = results.reduce((n, r) => n + r.violations.length, 0);
if (failed > 0) {
  console.log(`\n${total} violation(s) across ${failed} of ${files.length} page(s).`);
  process.exit(1);
}
console.log(`\nNo accessibility violations across ${files.length} page(s).`);
