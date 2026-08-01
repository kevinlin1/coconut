#import "components/assignment.typ": problem-counter
#import "components/nav.typ": format-switcher, paged-footer, paged-header, site-footer, site-header
#import "config.typ"
#import "scope.typ": mark-end, mark-start
#import "slug.typ": slugify
#import "theme.typ": colors, margins-for, paged-styles, stylesheet

// A course site has two shapes, and this file emits both from one description.
//
//   typst compile main.typ --features bundle,html --format bundle site/
//       One HTML page and one PDF per route: the website, plus a printable
//       handout for each page of it.
//
//   typst compile main.typ --features bundle,html --format pdf reader.pdf
//       Every route in sequence as one continuous document: the course reader
//       students print once at the start of term. Add
//       `--input large-print=true` for the 18-point edition of it.
//
// The switch is `target()`, which reports "bundle" at the top level of a bundle
// export and "paged" or "html" when a single document is being built (and
// inside each `document()` body). So `page()` either constructs documents or
// contributes a section to the one being built — the same trick Typst's own
// documentation uses to publish typst.app/docs and a standalone reference PDF
// from one source.

// Counters are shared across every document in a bundle: without this, page 2
// would start numbering its problems where page 1 left off. Resetting at the
// top of each page makes each one start from a clean slate. The page counter is
// the exception in reader mode, where numbering runs straight through.
#let reset-counters(pages: true) = {
  if pages { counter(page).update(1) }
  counter(heading).update(0)
  counter(footnote).update(0)
  counter(math.equation).update(0)
  counter(figure.where(kind: image)).update(0)
  counter(figure.where(kind: table)).update(0)
  counter(figure.where(kind: raw)).update(0)
  problem-counter.update(0)
}

// Supplying the whole `<html>` tree — rather than letting Typst generate the
// scaffold around a bare body — is what lets the stylesheet live in `<head>`
// where it belongs. Typst still injects its MathML stylesheet into this head,
// so exported equations keep their styling. Everything else we now owe the
// document ourselves: character set, viewport, title, description, language.
#let html-shell(title: none, description: none, lang: "en", body) = html.html(
  lang: lang,
  {
    html.head({
      html.meta(charset: "utf-8")
      html.meta(name: "viewport", content: "width=device-width, initial-scale=1")
      if description != none { html.meta(name: "description", content: description) }
      if title != none { html.title(title) }
      html.style(stylesheet)
    })
    html.body(body)
  },
)

// The page frame, per target. This is where the accessible skeleton lives:
// exactly one `<h1>` (the document title, which Typst reserves for `title()`),
// a `<main>` landmark that the skip link jumps to, and headings inside the body
// starting at `<h2>` — matched in the PDF by `heading(offset: 1)`, so every
// format has the same outline.
//
// In reader mode (`single: true`) a page is one section of a longer document,
// so it drops the per-page furniture — site navigation, the "download as PDF"
// link, its own landmark — and keeps only its heading.
//
// `large-print: true` is the same page in the large-print edition. It changes
// nothing above this line: the outline, the tagging, the content, and the order
// are what the standard edition has, at a size that can be read.
#let chrome(
  kind: "page",
  masthead: true,
  page-title: none,
  single: false,
  large-print: false,
  body,
) = context {
  let cfg = config.config()

  // Syntax highlighting is off, on both targets, because it cannot be made to
  // pass contrast on the web. Typst bakes highlight colors into each span as an
  // inline `style` attribute, so they cannot answer `prefers-color-scheme` the
  // way the rest of the palette does — one fixed color has to clear 4.5:1
  // against both the light and the dark code background. No color does: the
  // light background admits only colors below 0.165 relative luminance, the
  // dark one only colors above 0.235. Code stays in body ink, which clears AAA
  // in both schemes, and loses nothing a reader was relying on — color was
  // never carrying meaning here that the code itself does not carry.
  set raw(theme: none)

  if target() == "html" {
    // Sets `<html lang>`, which is how a screen reader picks the right voice
    // and pronunciation rules for the page.
    set text(lang: cfg.lang)
    if single {
      html.section({
        if masthead { heading(depth: 1, page-title) }
        body
      })
    } else {
      site-header()
      html.main(id: "main", {
        if masthead { title() }
        format-switcher()
        body
      })
      site-footer()
    }
  } else {
    paged-styles(kind: kind, large-print: large-print, fonts: cfg.fonts, lang: cfg.lang, {
      // `std.page`, not `page`: this file defines its own `page()` below, and
      // a set rule has to name the element, not the wrapper.
      set std.page(
        paper: "us-letter",
        margin: margins-for(kind, large-print: large-print),
        header: paged-header(),
        footer: paged-footer(),
      )
      if single { pagebreak(weak: true) }
      if masthead {
        // `offset: 0` keeps the title at level 1 while the body's `= Section`
        // headings sit at level 2 under it. Components pass `depth:` rather
        // than `level:` for the same reason: `level` is absolute and ignores
        // the offset, so a component heading would otherwise come out as a
        // peer of the page title instead of a child of it.
        //
        // The title is passed in as a value rather than read back with
        // `title()`: PDF/UA needs the heading's text at tagging time, and a
        // `title()` element resolves too late to end up in the tag, which
        // fails conformance with "heading title is empty". In reader mode
        // there is no per-section document title to read back anyway.
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
  // Also emit the large-print PDF (18-point type) beside the standard one.
  // There is no large-print HTML: a web page already reflows at whatever size
  // the reader's browser is set to, and shipping a second page at a fixed
  // larger size would take that control away rather than add to it.
  large-print: true,
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
  // `single` is whether this is one section of a longer document; `large` is
  // whether this rendering is the large-print edition. The route's own
  // `large-print` flag says whether that edition is *offered*, and goes into
  // the configuration for the switcher to read; `large` says which of the two
  // is being typeset right now, which is why they are separate.
  let contents = (single, large) => {
    config.init(
      title: title,
      course: course,
      nav: nav,
      path: base,
      solutions: solutions,
      formats: formats,
      large-print: large-print,
      kind: kind,
      fonts: fonts,
      lang: lang,
      single: single,
    )
    reset-counters(pages: not single)
    mark-start
    chrome(
      kind: kind,
      masthead: masthead,
      page-title: title,
      single: single,
      large-print: large,
      body,
    )
    mark-end
  }

  context if target() == "bundle" {
    for format in formats {
      document(
        base + "." + format,
        title: title,
        description: description,
        if format == "html" {
          html-shell(title: title, description: description, lang: lang, contents(false, false))
        } else {
          contents(false, false)
        },
      )
      if format == "pdf" and large-print {
        document(
          base + config.large-print-suffix + ".pdf",
          // The suffix distinguishes the two editions on disk; the title
          // distinguishes them everywhere a title is what gets read out — a
          // list of open tabs, a screen reader's document list, the print
          // dialog, a file manager showing document properties.
          title: [#title (#config.large-print-name)],
          description: description,
          contents(false, true),
        )
      }
    }
  } else if target() == "paged" and "pdf" in formats {
    // A page the site publishes only as HTML stays out of the printed reader.
    //
    // Which edition the reader is comes from the command line, not from the
    // route: this build emits one document, and a section of it cannot be set
    // in a different size than the document it belongs to.
    contents(true, config.large-print-input())
  } else if target() == "html" and "html" in formats {
    contents(true, false)
  }
}

// The reader's table of contents.
//
// Not `outline()`, which indents by a heading's *depth* — the level it was
// written at, before `offset` is applied. Every page's title is written as
// `heading(level: 1)` and so is every section inside a page body, so the
// built-in outline draws them at the same indent and the reader can't tell a
// page from a section within it. Indenting by the resolved `level` instead
// restores the nesting the document actually has.
#let reader-contents(depth: 2) = context {
  // Entries stay clickable, but they are not painted like body links: a page
  // of blue underline reads as noise, and the indent and page number already
  // say what each row is. `paged-styles()` leaves internal destinations
  // unstyled for exactly this reason.
  set text(fill: colors.ink)
  let entries = query(heading).filter(h => h.outlined and h.level <= depth)
  for h in entries {
    let loc = h.location()
    let body = if h.level == 1 { strong(h.body) } else { h.body }
    block(
      above: if h.level == 1 { 0.9em } else { 0.45em },
      below: 0pt,
      pad(left: (h.level - 1) * 1.4em, link(
        loc,
        grid(
          columns: (auto, 1fr, auto),
          column-gutter: 0.4em,
          body,
          align(bottom, box(width: 100%, repeat(justify: false)[.])),
          [#counter(std.page).at(loc).first()],
        ),
      )),
    )
  }
}

// Front matter for the single-document editions: a cover and a table of
// contents, which the website doesn't need because it has navigation instead.
#let reader-front-matter(
  title: none,
  course: (:),
  fonts: (:),
  lang: "en",
  large-print: false,
  outline: true,
) = context {
  let subtitle = (
    course.at("name", default: none),
    course.at("term", default: none),
  ).filter(p => p != none)

  if target() == "html" {
    // `html.h1` rather than `heading()`: Typst reserves `<h1>` for a document
    // title element, which a single-page build has no way to emit, so the
    // reader would otherwise open with an `<h2>` and no top-level heading.
    if title != none { html.h1(title) }
    if subtitle.len() > 0 { html.p(class: "page-meta", subtitle.join[ · ]) }
  } else if target() == "paged" {
    paged-styles(large-print: large-print, fonts: fonts, lang: lang, {
      set std.page(paper: "us-letter", margin: margins-for("page", large-print: large-print))
      align(center + horizon, {
        if title != none { text(size: 2.2em, weight: 700, title) }
        if subtitle.len() > 0 {
          v(0.8em)
          text(size: 1.2em, fill: colors.muted, subtitle.join[ · ])
        }
      })
      if outline {
        pagebreak(weak: true)
        // `offset: 0` puts "Contents" at the level of the sections it lists,
        // rather than making it a child of the one above it.
        heading(level: 1, offset: 0, outlined: false, [Contents])
        reader-contents()
      }
    })
  }
}

// Declarative form of `page()`: describe a whole course site as data instead of
// a sequence of calls. `course` and `nav` are given once and inherited by every
// route, which is what keeps the running header on a printed problem set in
// sync with the banner on the website.
//
// A route is a dictionary with `title` and `body`, plus any of `path`,
// `formats`, `description`, `solutions`, `kind`, `masthead`, `large-print`,
// `in-nav` (list it in the site navigation) and `in-reader` (include it in the
// single-document editions — set it to false on the answer keys you don't want
// bound into the copy students print).
#let bundle(
  routes,
  course: (:),
  nav: auto,
  fonts: (:),
  lang: "en",
  // Emit the large-print PDF beside the standard one, for every route that
  // doesn't say otherwise. Turning it off site-wide is a decision worth
  // hesitating over: a student who needs 18-point type and doesn't find it
  // published has to ask for it by name, one handout at a time.
  large-print: true,
  // Title of the single-document editions. Bundle export ignores it, since
  // every page there carries its own title.
  title: none,
  outline: true,
) = {
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

  // Which edition a single-document build is. Bundle export writes both and
  // ignores this; see `large-print-input()` in `config.typ`.
  //
  // Deliberately not `and large-print`: the argument above decides what the
  // site publishes by default, and asking for `--input large-print=true` on the
  // command line is not a default but someone typing out what they want.
  let large = config.large-print-input()

  // Bundle export has no single document to describe, and ignores this.
  let doc-title = if title != none { title } else { course.at("name", default: none) }
  set document(title: if doc-title != none and large {
    [#doc-title (#config.large-print-name)]
  } else {
    doc-title
  })

  let front = reader-front-matter(
    title: title,
    course: course,
    fonts: fonts,
    lang: lang,
    large-print: large,
    outline: outline,
  )

  let sections = {
    for route in routes {
      let in-reader = route.at("in-reader", default: true)
      context if target() == "bundle" or in-reader {
        page(
          route.title,
          path: route.at("path", default: none),
          formats: route.at("formats", default: ("html", "pdf")),
          large-print: route.at("large-print", default: large-print),
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
  }

  context if target() == "html" {
    // The one-page HTML edition. Bundle export gets its stylesheet and its
    // `<main>` from `html-shell()` and `chrome()`; here there is a single
    // document, so the frame is put on once, around everything.
    html.style(stylesheet)
    html.main(id: "main", {
      front
      sections
    })
  } else {
    front
    sections
  }
}
