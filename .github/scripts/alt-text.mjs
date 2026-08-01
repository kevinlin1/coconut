// The alt-text quality rules, applied to what the build actually emitted.
//
// This is the second half of `src/alt.typ`: the same list of rules, in the same
// order, with the same ids, so a failure reads the same whichever half reports
// it. The two exist because they catch different things.
//
//   - The Typst half runs at compile time and covers both output formats,
//     including the PDF, which nothing else ever re-checks. But it only sees
//     alt text that goes through `figure-image()` or `person(photo-alt: ..)`.
//   - This half sees every `<img>` on the page however it got there — a bare
//     `image()` in course content, raw `html.img(..)`, anything a future
//     component emits — and it can resolve what the compiler cannot: whether an
//     image is hidden from the accessibility tree, what its `<figcaption>`
//     actually says, and whether two images on a page share one description.
//
// axe covers the presence of alt text (`image-alt`) and stops there, by design:
// no automated check can judge whether a description is accurate. These rules
// do not try to. They catch the alt text that was never a description at all —
// a filename, the word "image", a URL, the caption repeated — which is most of
// what goes wrong in practice.

// Keep in step with `_filler` in src/alt.typ.
const FILLER = new Set([
  "a", "an", "and", "the", "of", "or", "for", "in", "on", "with", "this",
  "that", "here", "it", "is", "my", "our", "some",
  "image", "images", "img", "picture", "pic", "photo", "photos", "photograph",
  "graphic", "graphics", "icon", "logo", "figure", "fig", "chart", "graph",
  "diagram", "screenshot", "screengrab", "thumbnail", "banner", "illustration",
  "media", "file", "attachment", "spacer", "placeholder", "example", "sample",
  "alt", "text", "description", "caption", "untitled", "unknown", "blank",
  "empty", "none", "na", "todo", "tbd", "tk", "xxx", "test", "temp",
]);

const REDUNDANT_OPENER =
  /^\s*(an?|the)?\s*(image|picture|photo|photograph|graphic|graphics)\s+(of|showing|that shows|depicting)\b/i;
const FILENAME = /\.(png|jpe?g|gif|svg|webp|avif|bmp|tiff?|pdf|eps)\s*$/i;
const CAMERA_NAME = /^\s*(img|dsc|dscn|pxl|mvimg|screen ?shot|screenshot|image)[-_ ]?\d+\s*$/i;
const URL = /(https?:\/\/|www\.)/i;
// Typst numbers captions when it renders them, so what a reader hears is
// "Figure 1: …" and what the caption said is the rest.
const CAPTION_NUMBER = /^(figure|fig|table|listing|chart|image|photo)\s+\d+\s+/;

export const MIN_CHARACTERS = 8;
export const MIN_WORDS = 2;
export const MAX_CHARACTERS = 250;

const DECORATIVE_FIX =
  "Describe what the image shows. If it is purely decorative, use decorative() instead.";

const normalize = (text) => text.toLowerCase().replace(/[^\p{L}\p{N}]+/gu, " ").trim();

const words = (text) => normalize(text).split(" ").filter((word) => word !== "");

// Codepoints rather than UTF-16 units, to match Typst's `.clusters().len()`
// closely enough that a length limit means the same thing on both sides.
const length = (text) => [...text].length;

// Alt text the caption already contains is announced twice in a row, and the
// second reading carries nothing. Only this direction — an alt text that says
// *more* than the caption is the point of having both.
function coveredByCaption(alt, caption) {
  if (caption === null || caption === undefined) return false;
  const described = normalize(alt);
  const said = normalize(caption).replace(CAPTION_NUMBER, "");
  return described !== "" && ` ${said} `.includes(` ${described} `);
}

// `null` when the alt text is usable, otherwise { id, problem, fix }.
export function altProblem(alt, { caption = null } = {}) {
  if (alt === null || alt === undefined) {
    return { id: "missing", problem: "is missing", fix: DECORATIVE_FIX };
  }

  const trimmed = alt.trim();
  const parts = words(trimmed);

  if (trimmed === "") return { id: "empty", problem: "is empty", fix: DECORATIVE_FIX };

  if (parts.length === 0) {
    return {
      id: "no-words",
      problem: `has no letters or digits in it: ${JSON.stringify(trimmed)}`,
      fix: "Punctuation is read aloud as punctuation. Write words.",
    };
  }
  if (parts.every((word) => FILLER.has(word))) {
    return {
      id: "placeholder",
      problem: `only names the medium: ${JSON.stringify(trimmed)}`,
      fix: "A screen reader already announces that this is an image. Say what is in it — "
        + "what a sighted reader would take from it at a glance.",
    };
  }
  if (FILENAME.test(trimmed) || CAMERA_NAME.test(trimmed)) {
    return {
      id: "filename",
      problem: `is a filename: ${JSON.stringify(trimmed)}`,
      fix: "What the file is called is not what it shows. Describe the content.",
    };
  }
  if (URL.test(trimmed)) {
    return {
      id: "url",
      problem: `contains a URL: ${JSON.stringify(trimmed)}`,
      fix: "A URL read character by character is not a description. Describe the image, "
        + "and put the address in a link if the reader needs it.",
    };
  }
  if (REDUNDANT_OPENER.test(trimmed)) {
    return {
      id: "redundant-opener",
      problem: `starts by saying it is an image: ${JSON.stringify(trimmed)}`,
      fix: 'The element is announced as an image already, so "image of" is heard twice. '
        + "Start with the subject instead.",
    };
  }
  if (length(trimmed) > MAX_CHARACTERS) {
    return {
      id: "too-long",
      problem: `is ${length(trimmed)} characters, over the ${MAX_CHARACTERS}-character limit`,
      fix: "Alt text cannot be paused, re-read, or navigated within. Keep it to the one-sentence "
        + "summary and move the detail into figure-image(description: ..), which renders a long "
        + "description a reader can navigate.",
    };
  }
  if (parts.length < MIN_WORDS || length(trimmed) < MIN_CHARACTERS) {
    return {
      id: "too-short",
      problem: `is too short to describe anything: ${JSON.stringify(trimmed)}`,
      fix: `Write at least ${MIN_WORDS} words (${MIN_CHARACTERS} characters). `
        + "A label is not a description.",
    };
  }
  if (coveredByCaption(trimmed, caption)) {
    return {
      id: "same-as-caption",
      problem: `says nothing the caption does not: ${JSON.stringify(trimmed)}`,
      fix: "The caption is read out already, so this is heard twice. Use the alt text for what "
        + "the caption leaves out — what the image actually shows.",
    };
  }
  return null;
}

// Whether an image has been deliberately taken out of the accessibility tree.
// `decorative()` emits `aria-hidden="true"`; `role="presentation"` and
// `role="none"` are the hand-written equivalents.
const isDecorative = (image) =>
  image.hidden === true || image.role === "presentation" || image.role === "none";

// Every problem on one page, in document order. Takes the extracted image
// records rather than a DOM, so the rules are testable without a browser:
//
//   { target, alt, caption, hidden, role, label }
//
// `alt` is null when the attribute is absent, `caption` the text of the
// enclosing `<figcaption>` if there is one, `hidden` whether the image or an
// ancestor is `aria-hidden`, and `label` any `aria-label` on the image itself.
export function pageProblems(images) {
  const problems = [];
  const seen = new Map();

  for (const image of images) {
    const decorative = isDecorative(image);
    const alt = image.alt ?? null;

    // A decorative image is meant to be silent, which `alt=""` on its own is
    // enough to achieve. Alt text on one is a contradiction the author will
    // never hear: whatever it says is discarded.
    if (decorative) {
      if (alt !== null && alt.trim() !== "") {
        problems.push({
          ...image,
          id: "hidden-with-alt",
          problem: `is on an image hidden from assistive technology: ${JSON.stringify(alt.trim())}`,
          fix: "Nothing will ever read it. Either drop the alt text, or stop hiding the image "
            + "because it turns out to be content.",
        });
      }
      continue;
    }

    // An empty alt is the correct way to say "skip this", but only when
    // something says the image is decorative. Unmarked, it is indistinguishable
    // from alt text nobody got round to writing.
    if (alt !== null && alt.trim() === "") {
      problems.push({
        ...image,
        id: "empty",
        problem: "is empty, and the image is not marked as decorative",
        fix: "Use decorative() so the image is hidden from assistive technology deliberately, "
          + "or describe what it shows.",
      });
      continue;
    }

    // An image labelled by ARIA is described, whatever its alt attribute says;
    // the label is what a screen reader announces, so that is what gets checked.
    const described = image.label ?? alt;
    const problem = altProblem(described, { caption: image.caption ?? null });
    if (problem) {
      problems.push({ ...image, ...problem });
      continue;
    }

    // Two images described identically are either the same image twice — in
    // which case at least one of them is decoration — or two different images
    // sharing one copied description, which leaves a reader unable to tell them
    // apart. Reported once, against the second occurrence.
    const key = normalize(described);
    if (seen.has(key)) {
      problems.push({
        ...image,
        id: "duplicate",
        problem: `repeats the description already given for ${seen.get(key)}: ${JSON.stringify(described.trim())}`,
        fix: "Describe what makes each image different, or mark the repeated one as decorative "
          + "with decorative().",
      });
    } else {
      seen.set(key, image.target);
    }
  }

  return problems;
}
