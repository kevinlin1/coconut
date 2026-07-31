#import "../theme.typ": colors
#import "callout.typ": disclosure

// Images, figures, media links, and code listings.
//
// The one rule this module enforces rather than suggests: a figure has to
// describe itself. `figure-image()` fails the build when `alt` is missing,
// because a missing alt text is invisible to the person who wrote the page and
// total to the person who needs it. Failing at compile time is the only point
// at which it is cheap to fix.

#let figure-image(
  source,
  alt: none,
  caption: none,
  // Long description for content that cannot be summarized in a sentence —
  // charts, circuit diagrams, flowcharts, annotated screenshots. `alt` says
  // what the image *is*; `description` conveys what it *shows*.
  description: none,
  width: auto,
) = {
  assert(
    alt != none and alt.trim() != "",
    message: "figure-image(\"" + source + "\") needs alt: a short description of the image. "
      + "If the image is purely decorative, use decorative() instead of a figure.",
  )
  let picture = image(source, alt: alt, width: width)
  if caption == none { picture } else { figure(picture, caption: caption) }
  // Outside the figure, so the disclosure is reachable in its own right rather
  // than buried in a caption that assistive technology may announce as one run.
  if description != none {
    disclosure([Long description of this figure], description)
  }
}

// An equation with a spoken form.
//
// HTML export turns Typst math into MathML, which a screen reader can already
// read structurally, but a tagged PDF has no equivalent: the equation is drawn
// glyphs, and without `alt` it is announced as nothing at all. (Build with
// `--pdf-standard ua-1` and Typst will refuse to emit an equation that has
// none.) Write the alt the way you would say the formula out loud in class.
#let eq(alt, body) = {
  if type(body) == content and body.func() == math.equation {
    // Rebuilt rather than wrapped, so `eq("...", $x$)` doesn't nest an
    // equation inside an equation.
    math.equation(alt: alt, block: body.block, body.body)
  } else {
    math.equation(alt: alt, body)
  }
}

// Purely presentational rules, spacers, and background flourishes. Marked as an
// artifact in tagged PDF and hidden from the accessibility tree in HTML, so it
// is skipped rather than read as a mystery.
#let decorative(body) = context if target() == "html" {
  html.div(aria-hidden: "true", body)
} else {
  pdf.artifact(body)
}

// A link to media hosted elsewhere (a lecture recording, a podcast, a dataset).
// `transcript` is not decoration: a transcript serves deaf and hard-of-hearing
// students, students in noisy environments, students on slow connections, and
// anyone who wants to search the lecture — and it is the only version of the
// content that survives into the PDF at all.
#let media-link(
  url,
  title: none,
  kind: "recording",
  duration: none,
  captions: true,
  transcript: none,
) = {
  assert(title != none, message: "media-link() needs a title: link text of \"here\" or a bare URL is not usable.")
  let annotations = (
    kind,
    if duration != none { duration },
    if captions { "captioned" } else { "no captions available" },
  ).filter(a => a != none)
  block({
    link(url, title)
    text(fill: colors.muted, [ (#annotations.join(", "))])
    if transcript != none {
      disclosure([Transcript: #title], transcript)
    }
  })
}

// A file that students download rather than read in place. The label states the
// format and size up front so nobody discovers it by clicking.
#let file-link(url, title, format: none, size: none, pages: none) = {
  let annotations = (format, pages, size).filter(a => a != none)
  if annotations.len() == 0 { link(url, title) } else {
    link(url, [#title (#annotations.join(", "))])
  }
}

#let code-listing(body, caption: none) = {
  let listing = if type(body) == str { raw(body, block: true) } else { body }
  if caption == none { listing } else { figure(listing, caption: caption, kind: raw) }
}
