// What makes an alt text descriptive, as rules a compiler can check.
//
// Requiring `alt` to be present is easy and nearly free of value on its own:
// `alt="image"` satisfies every automated check ever written and tells a
// student using a screen reader exactly as much as `alt=""` would, while also
// costing them the one signal — silence — that would have told them something
// was missing. The rules below are the cheap half of the difference: they
// cannot tell whether a description is *accurate*, but they can tell when it is
// a filename, the word "image", a URL, or the caption said twice.
//
// They run at compile time because that is the only point at which both output
// formats are still in hand. axe can re-check the HTML afterwards — and CI does
// — but nothing re-checks the PDF, where the alt text is all a reader gets.
// `.github/scripts/alt-text.mjs` implements this same list for the built HTML;
// the two are kept in step by hand, and the rule ids are shared so a failure
// reads the same whichever half reports it.

// Words that name the medium rather than describe the content. An alt text
// built only from these says "there is an image here", which the screen reader
// has already announced.
#let _filler = (
  "a", "an", "and", "the", "of", "or", "for", "in", "on", "with", "this",
  "that", "here", "it", "is", "my", "our", "some",
  "image", "images", "img", "picture", "pic", "photo", "photos", "photograph",
  "graphic", "graphics", "icon", "logo", "figure", "fig", "chart", "graph",
  "diagram", "screenshot", "screengrab", "thumbnail", "banner", "illustration",
  "media", "file", "attachment", "spacer", "placeholder", "example", "sample",
  "alt", "text", "description", "caption", "untitled", "unknown", "blank",
  "empty", "none", "na", "todo", "tbd", "tk", "xxx", "test", "temp",
)

// Openers a screen reader makes redundant: it announces the element as an image
// before reading a word of the alt text, so "Image of the CO₂ record" is heard
// as "image, image of the CO₂ record". Deliberately short — "screenshot of the
// grading page" and "map of the sensor sites" name what the thing *is*, which
// is the job of alt text, so neither is listed.
#let _redundant-openers = regex(
  "^(?i)\\s*(an?|the)?\\s*(image|picture|photo|photograph|graphic|graphics)\\s+(of|showing|that shows|depicting)\\b",
)

// A filename, a path, or a camera's idea of a name. Whatever the image is
// called on disk is not what it shows.
#let _filename = regex("(?i)\\.(png|jpe?g|gif|svg|webp|avif|bmp|tiff?|pdf|eps)\\s*$")
// Anchored at both ends: "IMG_1024" is a filename, but "figure 2 of the trend"
// is a description that happens to start with a word and a number.
#let _camera-name = regex("(?i)^\\s*(img|dsc|dscn|pxl|mvimg|screen ?shot|screenshot|image)[-_ ]?\\d+\\s*$")
#let _url = regex("(?i)(https?://|www\\.)")

// Long enough to be a description rather than a label. Two words is a low bar
// on purpose: "MIT logo" clears it, "chart" does not.
#let min-characters = 8
#let min-words = 2

// Past this, a screen reader is reading a paragraph with no way to pause,
// re-read, or skip within it. That content belongs in a long description, which
// is navigable — `figure-image(description: ..)` renders one.
#let max-characters = 250

// Captions are content, and the caption is one of the things alt text is
// checked against, so it has to be flattened to the words a reader would hear.
// Anything this does not know how to read contributes nothing, which can only
// make the comparison below miss — never fire on text that was not there.
#let plain-text(item) = {
  if item == none { "" } else if type(item) == str { item } else if type(item) != content {
    str(item)
  } else if item == [ ] {
    // Markup spacing is its own element with no fields to read.
    " "
  } else if item.has("text") {
    item.text
  } else if item.has("children") {
    item.children.map(plain-text).join("")
  } else if item.has("body") {
    plain-text(item.body)
  } else if item.func() == linebreak or item.func() == parbreak {
    " "
  } else {
    ""
  }
}

#let _normalize(text) = lower(plain-text(text)).replace(regex("[^\\p{L}\\p{N}]+"), " ").trim()

#let _words(text) = _normalize(text).split(" ").filter(word => word != "")

// Typst numbers captions when it renders them, so what a reader hears is
// "Figure 1: …" and what the caption said is the rest.
#let _caption-number = regex("^(figure|fig|table|listing|chart|image|photo)\\s+\\d+\\s+")

// The one rule that needs a second value: alt text the caption already contains
// is announced twice in a row, and the second reading carries nothing. Only
// this direction — an alt text that says *more* than the caption is the point of
// having both.
#let _covered-by-caption(alt, caption) = {
  if caption == none { return false }
  let described = _normalize(alt)
  let said = _normalize(caption).replace(_caption-number, "")
  described != "" and (" " + said + " ").contains(" " + described + " ")
}

// Returns `none` when the alt text is usable, or `(id, problem, fix)` naming
// what is wrong with it. `caption` is the figure's caption, when it has one, so
// the two can be compared.
#let alt-problem(alt, caption: none) = {
  if alt == none {
    return (
      id: "missing",
      problem: "is missing",
      fix: "Describe what the image shows. If it is purely decorative, use decorative() instead.",
    )
  }
  if type(alt) != str {
    return (
      id: "not-a-string",
      problem: "is " + str(type(alt)) + ", not a string",
      fix: "Alt text has to survive into a PDF /Alt entry and an HTML alt attribute, "
        + "neither of which can hold markup. Write it as a plain string.",
    )
  }

  let trimmed = alt.trim()
  let words = _words(trimmed)

  if trimmed == "" {
    return (
      id: "empty",
      problem: "is empty",
      fix: "Describe what the image shows. If it is purely decorative, use decorative() instead.",
    )
  }
  if words.len() == 0 {
    return (
      id: "no-words",
      problem: "has no letters or digits in it: " + repr(trimmed),
      fix: "Punctuation is read aloud as punctuation. Write words.",
    )
  }
  if words.all(word => word in _filler) {
    return (
      id: "placeholder",
      problem: "only names the medium: " + repr(trimmed),
      fix: "A screen reader already announces that this is an image. "
        + "Say what is in it — what a sighted reader would take from it at a glance.",
    )
  }
  if trimmed.match(_filename) != none or trimmed.match(_camera-name) != none {
    return (
      id: "filename",
      problem: "is a filename: " + repr(trimmed),
      fix: "What the file is called is not what it shows. Describe the content.",
    )
  }
  if trimmed.match(_url) != none {
    return (
      id: "url",
      problem: "contains a URL: " + repr(trimmed),
      fix: "A URL read character by character is not a description. "
        + "Describe the image, and put the address in a link if the reader needs it.",
    )
  }
  if trimmed.match(_redundant-openers) != none {
    return (
      id: "redundant-opener",
      problem: "starts by saying it is an image: " + repr(trimmed),
      fix: "The element is announced as an image already, so \"image of\" is heard twice. "
        + "Start with the subject instead.",
    )
  }
  // Length before brevity: a 300-character run-on is many things, but it is not
  // too short, whatever its word count.
  if trimmed.clusters().len() > max-characters {
    return (
      id: "too-long",
      problem: "is " + str(trimmed.clusters().len()) + " characters, over the "
        + str(max-characters) + "-character limit",
      fix: "Alt text cannot be paused, re-read, or navigated within. Keep it to the one-sentence "
        + "summary and move the detail into figure-image(description: ..), which renders a long "
        + "description a reader can navigate.",
    )
  }
  if words.len() < min-words or trimmed.clusters().len() < min-characters {
    return (
      id: "too-short",
      problem: "is too short to describe anything: " + repr(trimmed),
      fix: "Write at least " + str(min-words) + " words (" + str(min-characters) + " characters). "
        + "A label is not a description.",
    )
  }
  if _covered-by-caption(trimmed, caption) {
    return (
      id: "same-as-caption",
      problem: "says nothing the caption does not: " + repr(trimmed),
      fix: "The caption is read out already, so this is heard twice. Use the alt text for what "
        + "the caption leaves out — what the image actually shows.",
    )
  }
  none
}

// Fails the build when `alt` is not a usable description. `subject` names the
// call site — the image source, or the person whose photo it is — because the
// error is otherwise a string with no way back to the line that wrote it.
#let check-alt(alt, subject, caption: none) = {
  let problem = alt-problem(alt, caption: caption)
  assert(
    problem == none,
    message: "alt text for " + subject + " " + if problem == none { "" } else {
      problem.problem + " [" + problem.id + "]\n  " + problem.fix
    },
  )
}
