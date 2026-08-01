// Stages the working tree as a resolvable Typst package.
//
// The template imports `@preview/coconut:<version>` — the same pinned import a
// consumer writes after `typst init @preview/coconut`. Passing
// `--package-path <staging dir>` to `typst compile` makes that import resolve
// to this working tree instead of the published package, so CI checks the
// source in the branch through the exact path users take.
//
// Usage: node stage-package.mjs [--out <dir>]   (default: dist)

import { cp, mkdir, readdir, readFile, rm } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const repo = path.resolve(fileURLToPath(import.meta.url), "../../..");

// The files that make up the package itself. Everything else in the repo —
// the workflow, the Node tooling, the build output — is development-only and
// is also listed in `exclude` in typst.toml so it stays out of the published
// package.
const PACKAGE_FILES = ["typst.toml", "lib.typ", "src", "template", "README.md", "LICENSE"];

function arg(name, fallback) {
  const i = process.argv.indexOf(name);
  return i === -1 ? fallback : process.argv[i + 1];
}

// Minimal readers for the two manifest fields this script needs. A TOML
// dependency is not worth it for a package whose manifest is this small.
function manifestField(toml, field) {
  const match = toml.match(new RegExp(`^${field}\\s*=\\s*"([^"]+)"`, "m"));
  if (!match) throw new Error(`typst.toml has no \`${field}\` field`);
  return match[1];
}

const manifest = await readFile(path.join(repo, "typst.toml"), "utf8");
const name = manifestField(manifest, "name");
const version = manifestField(manifest, "version");

// The pins in the template must track the version in the manifest. When one
// does not, Typst fails with a bare "package not found" that says nothing about
// the cause, so the mismatch is reported here instead. The template is several
// files — the entrypoint, the course data, and one file per page — and each
// imports the package for itself, so every one of them is checked and not just
// the entrypoint a version bump is likely to be edited in.
const templateDir = path.join(repo, "template");
const sources = (await readdir(templateDir, { recursive: true }))
  .filter((file) => file.endsWith(".typ"))
  .sort();

const mismatched = [];
let entrypointPinned = false;

for (const file of sources) {
  const source = await readFile(path.join(templateDir, file), "utf8");
  for (const pin of source.matchAll(/@preview\/([\w-]+):([\d.]+)/g)) {
    if (file === "main.typ" && pin[1] === name) entrypointPinned = true;
    if (pin[1] === name && pin[2] !== version) {
      mismatched.push({ file: path.join("template", file), pinned: pin[2] });
    }
  }
}

if (!entrypointPinned) {
  console.error(`error: template/main.typ has no @preview/${name} import.`);
  console.error(`  The template is published to users, so it must import the package by`);
  console.error(`  its published name, not by a relative path.`);
  process.exit(1);
}
if (mismatched.length > 0) {
  console.error(`error: the template pins a version that does not match typst.toml.`);
  for (const { file, pinned } of mismatched) {
    console.error(`  ${file} imports @preview/${name}:${pinned}`);
  }
  console.error(`  typst.toml declares @preview/${name}:${version}`);
  console.error(`\n  Bump the imports in the template to match, then re-run.`);
  process.exit(1);
}

const out = path.resolve(repo, arg("--out", "dist"));
const staged = path.join(out, "preview", name, version);

await rm(out, { recursive: true, force: true });
await mkdir(staged, { recursive: true });
for (const file of PACKAGE_FILES) {
  await cp(path.join(repo, file), path.join(staged, file), { recursive: true });
}

console.log(`Staged ${name} ${version} at ${path.relative(repo, staged)}`);
console.log(`Compile against it with: typst compile --package-path ${path.relative(repo, out)} ...`);
