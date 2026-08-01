// Stages the working tree as a resolvable Typst package.
//
// `template/main.typ` imports `@preview/coconut:<version>` — the same pinned
// import a consumer writes after `typst init @preview/coconut`. Passing
// `--package-path <staging dir>` to `typst compile` makes that import resolve
// to this working tree instead of the published package, so CI checks the
// source in the branch through the exact path users take.
//
// Usage: node stage-package.mjs [--out <dir>]   (default: dist)

import { cp, mkdir, readFile, rm } from "node:fs/promises";
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

// The pin in the template must track the version in the manifest. When it does
// not, Typst fails with a bare "package not found" that says nothing about the
// cause, so the mismatch is reported here instead.
const entrypoint = path.join(repo, "template", "main.typ");
const template = await readFile(entrypoint, "utf8");
const pin = template.match(/@preview\/([\w-]+):([\d.]+)/);

if (!pin) {
  console.error(`error: ${path.relative(repo, entrypoint)} has no @preview/${name} import.`);
  console.error(`  The template is published to users, so it must import the package by`);
  console.error(`  its published name, not by a relative path.`);
  process.exit(1);
}
if (pin[1] !== name || pin[2] !== version) {
  console.error(`error: the template pins a package that does not match typst.toml.`);
  console.error(`  ${path.relative(repo, entrypoint)} imports @preview/${pin[1]}:${pin[2]}`);
  console.error(`  typst.toml declares   ${name} ${version}`);
  console.error(`\n  Bump the import in the template to match, then re-run.`);
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
