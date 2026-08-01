#import "../config.typ": config, large-print-suffix
#import "../scope.typ": page-count
#import "../slug.typ": slugify
#import "../theme.typ": colors

// Where a link to another page in the bundle should point.
//
// In HTML the answer is the sibling `.html` file. In a PDF it depends on
// whether the course has a public site: if it does, the PDF should send the
// reader to the live page (relative links between downloaded PDFs break as
// soon as one of the files is moved or emailed); if it doesn't, the sibling
// `.pdf` is the best available guess.
//
// Returns a plain string, so it must be called from inside a `context` block
// (it reads the course configuration and the current target).
#let page-href(path) = {
  let base = config().course.at("url", default: none)
  if target() == "html" { path + ".html" } else if base != none {
    base.trim("/") + "/" + path + ".html"
  } else { path + ".pdf" }
}

// Link to another page by its title, mirroring how `page()` derives permalinks.
#let page-link(title, label: none) = context {
  link(page-href(slugify(title)), if label != none { label } else { title })
}

// Site navigation. `items` is an array of `(label: .., path: ..)`; the entry
// matching the current page is marked with `aria-current="page"` rather than
// only by styling, so it is announced and not merely seen.
#let site-nav(items, current: none, label: "Course") = context {
  if items.len() == 0 { return }
  let current = if current != none { current } else { config().path }
  if target() == "html" {
    html.nav(
      class: "site-nav",
      aria-label: label,
      html.ul(for item in items {
        let attrs = (href: item.path + ".html")
        if item.path == current { attrs.insert("aria-current", "page") }
        html.li(html.elem("a", attrs: attrs, item.label))
      }),
    )
  } else {
    // In print, navigation is reference material rather than a control strip.
    set text(size: 0.92em, fill: colors.muted)
    items
      .map(item => if item.path == current { strong(item.label) } else {
        link(page-href(item.path), item.label)
      })
      .join([ · ])
  }
}

// "Also available as" line under the page title. Only rendered in HTML, and
// only when the PDF twin is actually part of this page's `formats`, so it can
// never point at a file the bundle didn't emit. The link text names the format
// so it is meaningful when read out of context in a list of links — which is
// also why the second link says "large print" rather than "this version": the
// two entries have to be told apart by their text alone.
//
// The large-print edition is listed here, next to the standard one, rather than
// filed on an accessibility page somewhere: a student who needs 18-point type
// should find it where everyone finds the PDF, without asking anyone for it.
#let format-switcher() = context {
  let cfg = config()
  if target() != "html" or cfg.single or cfg.path == none or "pdf" not in cfg.formats {
    return
  }
  let links = (
    link(cfg.path + ".pdf", [Download this page as a PDF (opens a PDF file)]),
  )
  if cfg.large-print {
    links.push(link(
      cfg.path + large-print-suffix + ".pdf",
      [Download this page in large print, 18-point type (opens a PDF file)],
    ))
  }
  html.p(class: "page-meta no-print", links.join[ · ])
}

#let site-header() = context {
  let cfg = config()
  let c = cfg.course
  let name = c.at("code", default: c.at("name", default: none))
  if target() == "html" {
    {
      // First focusable thing on the page, so a keyboard or screen-reader user
      // can jump past the navigation that repeats on every page. Wrapped in a
      // `div` because a bare inline element at block level would be wrapped in
      // a `<p>`, whose margin would show as a gap once the link itself is
      // positioned off-screen.
      html.div(html.a(class: "skip-link", href: "#main", [Skip to main content]))
      html.header(
        class: "site-header",
        html.div({
          if name != none {
            html.span(class: "course-name", link("index.html", name))
          }
          if c.at("term", default: none) != none {
            [ ]
            html.span(class: "course-term", c.term)
          }
          site-nav(cfg.nav)
        }),
      )
    }
  }
}

#let site-footer() = context {
  let cfg = config()
  let c = cfg.course
  let parts = (
    c.at("name", default: none),
    c.at("term", default: none),
    if c.at("updated", default: none) != none { [Last updated #c.updated] },
    if c.at("url", default: none) != none and target() == "html" { none } else {
      c.at("url", default: none)
    },
  ).filter(p => p != none)
  if parts.len() == 0 { return }
  if target() == "html" {
    html.footer(class: "site-footer", html.div(parts.join[ · ]))
  } else {
    set text(size: 0.9em, fill: colors.muted)
    parts.join[ · ]
  }
}

// Running header / footer for paged output. The header repeats the course and
// page title so a printed handout that gets separated from its stack can still
// be identified; the footer carries "Page n of m" in words, not just digits,
// because a bare number is ambiguous when read aloud.
#let paged-header() = context {
  let cfg = config()
  let name = cfg.course.at("code", default: cfg.course.at("name", default: none))
  set text(size: 0.85em, fill: colors.muted)
  if name == none { return }
  // The page title comes from the configuration rather than from `title()`,
  // which in a single-document build would name the whole reader on every
  // page instead of the section the reader is actually looking at.
  let page-title = if cfg.title != none { cfg.title } else { title() }
  grid(
    columns: (1fr, auto),
    align(left, name), align(right, page-title),
  )
  line(length: 100%, stroke: 0.5pt + colors.line)
}

#let paged-footer() = context {
  set text(size: 0.85em, fill: colors.muted)
  grid(
    columns: (1fr, auto),
    align(left, site-footer()),
    align(right, [Page #counter(page).display() of #page-count(single: config().single)]),
  )
}
