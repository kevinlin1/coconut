// Every HTML file under a directory, as { label, path }.
//
// Shared by the two checks that walk the build output, so they always look at
// the same set of pages. The label is what shows up in the log and in the JSON
// report, so it stays relative to the working directory rather than absolute.

import { readdir } from "node:fs/promises";
import path from "node:path";

export async function htmlFiles(dir) {
  const entries = await readdir(dir, { recursive: true, withFileTypes: true });
  return entries
    .filter((e) => e.isFile() && e.name.endsWith(".html"))
    .map((e) => path.join(e.parentPath ?? e.path, e.name))
    .sort()
    .map((p) => ({ label: path.relative(".", p), path: p }));
}
