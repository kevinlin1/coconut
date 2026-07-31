#import "components/assignment.typ": problem-counter
#import "components/nav.typ": format-switcher, paged-footer, paged-header, site-footer, site-header
#import "config.typ"
#import "scope.typ": mark-end, mark-start
#import "slug.typ": slugify
#import "theme.typ": paged-margins, paged-styles, stylesheet

// Wrapper around the built-in `document()` bundle element. `title` is the only
// required argument — the permalink defaults to a slugified version of it
// (override with `path:` when the inferred slug isn't right, e.g. the home
// page) — and by default this emits *both* an HTML and a PDF document from the
// same `body`.
//
// That is the whole premise of the package. A student who needs a screen
// reader, a student on a phone with a data cap, and a student who prints the
// problem set and works it in pencil are all reading the same source, so they
// cannot drift apart the way a hand-maintained PDF and a course website always
// do. Content that genuinely differs per format (a "download as PDF" link, the
// blank space to write an answer in) branches on `target()` inside the
// components rather than the caller writing the body twice.

// Counters are shared across every document in a bundle: without this, page 2
// would start numbering its problems where page 1 left off. Resetting at the
// top of each document body makes each page start from a clean slate.
#let reset-counters() = {
  counter(page).update(1)
  counter(heading).update(0)
  counter(footnote).update(0)
  counter(math.equation).update(0)
  counter(figure.where(kind: image)).update(0)
  counter(figure.where(kind: table)).update(0)
  counter(figure.where(kind: raw)).update(0)
  problem-counter.update(0)
}

// The page frame, per target. This is where the accessible skeleton lives:
// exactly one `<h1>` (the document title, which Typst reserves for `title()`),
// a `<main>` landmark that the skip link jumps to, and headings inside the body
// starting at `<h2>` — matched in the PDF by `heading(offset: 1)`, so both
// formats have the same outline.
#let chrome(kind: "page", masthead: true, page-title: none, body) = context {
  let cfg = config.config()
  if target() == "html" {
    // Sets `<html lang>`, which is how a screen reader picks the right voice
    // and pronunciation rules for the page.
    set text(lang: cfg.lang)
    site-header()
    html.main(id: "main", {
      if masthead { title() }
      format-switcher()
      body
    })
    site-footer()
  } else {
    paged-styles(kind: kind, fonts: cfg.fonts, lang: cfg.lang, {
      set page(
        paper: "us-letter",
        margin: paged-margins.at(kind, default: paged-margins.page),
        header: paged-header(),
        footer: paged-footer(),
      )
      if masthead {
        // `offset: 0` keeps the title at level 1 while the body's `= Section`
        // headings sit at level 2 under it.
        //
        // The title is passed in as a value rather than read back with
        // `title()`: PDF/UA needs the heading's text at tagging time, and a
        // `title()` element resolves too late to end up in the tag, which
        // fails conformance with "heading title is empty".
        show heading.where(level: 1): set text(size: 1.6em)
        block(below: 1.2em, heading(level: 1, offset: 0, page-title))
      }
      body
    })
  }
}

#let page(
  title,
  path: none,
  formats: ("html", "pdf"),
  description: none,
  // Course metadata (see `course()` in `lib.typ`) and site navigation. Usually
  // passed once through `bundle()` rather than per page.
  course: (:),
  nav: (),
  // Build the instructor version: solutions, answer keys, and grading notes are
  // included in the output instead of being dropped.
  solutions: false,
  // Paged layout preset: "page", "assignment", "exam", or "handout".
  kind: "page",
  masthead: true,
  // Paged font overrides (see `default-fonts`) and the document language.
  fonts: (:),
  lang: "en",
  body,
) = {
  let base = if path != none { path } else { slugify(title) }
  for format in formats {
    document(base + "." + format, title: title, description: description, {
      config.init(
        course: course,
        nav: nav,
        path: base,
        solutions: solutions,
        formats: formats,
        kind: kind,
        fonts: fonts,
        lang: lang,
      )
      reset-counters()
      mark-start
      // The stylesheet has to live in the body: a bundle document has no way to
      // write into `<head>`. Browsers apply it just the same, and keeping it
      // inline means a page saved to disk still carries its own styling.
      context if target() == "html" { html.style(stylesheet) }
      chrome(kind: kind, masthead: masthead, page-title: title, body)
      mark-end
    })
  }
}

// Declarative form of `page()`: describe a whole course site as data instead of
// a sequence of calls. `course` and `nav` are given once and inherited by every
// route, which is what keeps the running header on a printed problem set in
// sync with the banner on the website.
//
// A route is a dictionary with `title` and `body`, plus any of `path`,
// `formats`, `description`, `solutions`, `kind`, and `masthead`.
#let bundle(routes, course: (:), nav: auto, fonts: (:), lang: "en") = {
  // By default the navigation is the site itself, in the order the routes were
  // declared — one fewer list to keep in sync by hand.
  let nav = if nav != auto { nav } else {
    routes
      .filter(r => r.at("in-nav", default: true))
      .map(r => (
        label: r.at("nav-label", default: r.title),
        path: r.at("path", default: slugify(r.title)),
      ))
  }
  for route in routes {
    page(
      route.title,
      path: route.at("path", default: none),
      formats: route.at("formats", default: ("html", "pdf")),
      description: route.at("description", default: none),
      course: course,
      nav: nav,
      solutions: route.at("solutions", default: false),
      kind: route.at("kind", default: "page"),
      masthead: route.at("masthead", default: true),
      fonts: route.at("fonts", default: fonts),
      lang: route.at("lang", default: lang),
      route.body,
    )
  }
}
