// Checks the quality of the alt text on every image the build emitted.
//
// axe answers "does this image have alt text?" and cannot answer "is that alt
// text a description?" — no automated check can judge accuracy. This one covers
// the part that is decidable: alt text that is a filename, a placeholder word,
// a URL, the caption repeated, or the same sentence as the image above it was
// never a description to begin with. `alt-text.mjs` holds the rules, and
// `src/alt.typ` enforces the same list at compile time, where the PDF can still
// be caught too.
//
// Run separately from axe rather than folded into it, so the axe report stays
// what axe found and nothing else.
//
// Usage: node alt-text-check.mjs <directory>... [--report <path>]

import { writeFile, mkdir } from "node:fs/promises";
import { pathToFileURL } from "node:url";
import path from "node:path";
import { chromium } from "playwright";
import { htmlFiles } from "./html-files.mjs";
import { pageProblems } from "./alt-text.mjs";

function parseArgs(argv) {
  const args = { dirs: [], report: null };
  for (let i = 0; i < argv.length; i++) {
    if (argv[i] === "--report") args.report = argv[++i];
    else args.dirs.push(argv[i]);
  }
  if (args.dirs.length === 0) {
    console.error("usage: node alt-text-check.mjs <directory>... [--report <path>]");
    process.exit(2);
  }
  return args;
}

// Runs in the page. Collects what the rules need for each image: the alt text,
// whether anything has taken the image out of the accessibility tree, the
// caption it sits under, and enough of a selector to find it again.
function collectImages() {
  const path = (element) => {
    const steps = [];
    for (let node = element; node && node.nodeType === 1; node = node.parentElement) {
      if (node.id) {
        steps.unshift(`#${node.id}`);
        break;
      }
      const tag = node.tagName.toLowerCase();
      if (tag === "html" || tag === "body") break;
      const siblings = [...(node.parentElement?.children ?? [])].filter(
        (sibling) => sibling.tagName === node.tagName,
      );
      steps.unshift(siblings.length > 1 ? `${tag}:nth-of-type(${siblings.indexOf(node) + 1})` : tag);
    }
    return steps.join(" > ");
  };

  const labelledBy = (element) => {
    const ids = (element.getAttribute("aria-labelledby") ?? "").split(/\s+/).filter(Boolean);
    if (ids.length === 0) return null;
    return ids
      .map((id) => document.getElementById(id)?.textContent?.trim() ?? "")
      .join(" ")
      .trim();
  };

  // `src` is only ever quoted back in an error message, and Typst inlines
  // images as base64 data URIs, so keep the useful head of it and no more.
  const source = (element) => {
    const src = element.getAttribute("src");
    if (!src) return null;
    if (src.startsWith("data:")) return `${src.slice(0, src.indexOf(";") + 1)}…inline`;
    return src;
  };

  return [...document.querySelectorAll('img, [role="img"]')].map((element) => ({
    target: path(element),
    src: source(element),
    alt: element.hasAttribute("alt") ? element.getAttribute("alt") : null,
    label: element.getAttribute("aria-label") ?? labelledBy(element),
    role: element.getAttribute("role"),
    hidden: element.closest('[aria-hidden="true"]') !== null,
    caption: element.closest("figure")?.querySelector("figcaption")?.textContent?.trim() ?? null,
  }));
}

function printProblems(file, problems) {
  console.log(`\n✗ ${file}`);
  for (const problem of problems) {
    console.log(`  [${problem.id}] alt text ${problem.problem}`);
    console.log(`    at ${problem.target}${problem.src ? ` (${problem.src})` : ""}`);
    console.log(`    ${problem.fix}`);
  }
}

const { dirs, report } = parseArgs(process.argv.slice(2));

const files = (await Promise.all(dirs.map(htmlFiles))).flat();

if (files.length === 0) {
  console.error(`No HTML files found in ${dirs.join(", ")} — did the Typst build run?`);
  process.exit(2);
}

console.log(`Checking alt text on ${files.length} page(s)`);

const browser = await chromium.launch();
const context = await browser.newContext();
const results = [];
let failed = 0;
let images = 0;

try {
  for (const { label, path: file } of files) {
    const page = await context.newPage();
    try {
      await page.goto(pathToFileURL(path.resolve(file)).href, { waitUntil: "load" });
      const found = await page.evaluate(collectImages);
      const problems = pageProblems(found);
      images += found.length;
      results.push({ file: label, images: found.length, problems });

      if (problems.length > 0) {
        failed++;
        printProblems(label, problems);
      } else if (found.length > 0) {
        console.log(`✓ ${label} (${found.length} image(s) described)`);
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
  await writeFile(report, JSON.stringify({ results }, null, 2));
  console.log(`\nFull alt-text report written to ${report}`);
}

const total = results.reduce((n, r) => n + r.problems.length, 0);
if (failed > 0) {
  console.log(`\n${total} image(s) without a usable description, across ${failed} page(s).`);
  process.exit(1);
}
console.log(`\n${images} image(s) across ${files.length} page(s), all described.`);
