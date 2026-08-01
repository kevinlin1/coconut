// JSON-file storage with an in-memory cache and debounced atomic writes.
// Single-process only — the in-memory objects are the source of truth.
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const DATA_DIR = path.join(__dirname, "data");
const DB_PATH = path.join(DATA_DIR, "db.json");
const SETTINGS_PATH = path.join(DATA_DIR, "settings.json");

fs.mkdirSync(DATA_DIR, { recursive: true });

function loadJson(file, fallback) {
  try {
    return JSON.parse(fs.readFileSync(file, "utf8"));
  } catch {
    return fallback;
  }
}

function atomicWrite(file, obj) {
  const tmp = `${file}.tmp`;
  fs.writeFileSync(tmp, JSON.stringify(obj, null, 2));
  fs.renameSync(tmp, file);
}

export const db = loadJson(DB_PATH, { comments: [] });
export const settings = loadJson(SETTINGS_PATH, {});

let saveTimer = null;
export function scheduleSave() {
  clearTimeout(saveTimer);
  saveTimer = setTimeout(() => {
    try {
      atomicWrite(DB_PATH, db);
    } catch (err) {
      console.error("Failed to persist db.json:", err.message);
    }
  }, 250);
}

export function saveSettings() {
  atomicWrite(SETTINGS_PATH, settings);
}

export function newId() {
  return crypto.randomUUID();
}

export function findComment(id) {
  return db.comments.find((c) => c.id === id);
}

// Flush pending writes on shutdown so a Ctrl+C doesn't lose the last mutation.
for (const sig of ["SIGINT", "SIGTERM"]) {
  process.on(sig, () => {
    clearTimeout(saveTimer);
    try {
      atomicWrite(DB_PATH, db);
    } catch {}
    process.exit(0);
  });
}
