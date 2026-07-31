#import "../table.typ": cell, data-table
#import "../theme.typ": colors
#import "media.typ": file-link

// Readings, materials, announcements, and glossaries — the parts of a course
// site that are mostly lists of links, and therefore the parts where link text
// most often decays into "here", "this", and "click for more".

// A word-based badge. Never the only signal: it sits next to text that says
// the same thing.
#let badge(body) = context if target() == "html" {
  html.span(class: "badge", body)
} else {
  box(
    stroke: 0.5pt + colors.muted,
    radius: 1em,
    inset: (x: 0.5em, y: 0.2em),
    text(size: 0.85em, weight: 600, body),
  )
}

// One entry in a reading list. `access` records how a student is expected to
// get it — the difference between a link that works from the library proxy and
// one that asks for $40 is the difference between a reading that gets done and
// one that doesn't.
#let reading(
  title,
  author: none,
  source: none,
  url: none,
  pages: none,
  required: true,
  access: none,
  format: none,
  notes: none,
) = (
  title: title,
  author: author,
  source: source,
  url: url,
  pages: pages,
  required: required,
  access: access,
  format: format,
  notes: notes,
)

#let reading-list(items, title: none, level: 1) = {
  if title != none { heading(depth: level, title) }
  list(
    ..items.map(r => {
      badge(if r.required { [Required] } else { [Optional] })
      [ ]
      if r.url != none {
        file-link(r.url, strong(r.title), format: r.format, pages: r.pages)
      } else {
        strong(r.title)
        if r.pages != none { [ (#r.pages)] }
      }
      if r.author != none { [. #r.author] }
      if r.source != none { [. #emph(r.source)] }
      if r.access != none { [. #text(fill: colors.muted, r.access)] }
      if r.notes != none {
        linebreak()
        text(fill: colors.muted, r.notes)
      }
    })
  )
}

// Per-session materials: slides, recording, notes, code, transcript. A table
// because students arrive at it looking for one cell ("the slides from
// Tuesday"), not to read it through.
#let materials-index(
  sessions,
  columns: (topic: [Topic], slides: [Slides], notes: [Notes], recording: [Recording]),
  caption: "Class materials",
) = {
  let keys = columns.keys()
  data-table(
    columns: keys.len() + 1,
    caption: caption,
    row-headers: true,
    header: ([Date],) + keys.map(k => columns.at(k)),
    rows: sessions.map(s => (s.date,) + keys.map(k => s.at(k, default: [—]))),
  )
}

// Announcements, newest first. Each one carries its own date, because
// "yesterday's announcement" means nothing to the student reading it in week 9
// while catching up.
#let announcements(items, level: 1) = {
  for a in items {
    heading(depth: level, {
      a.at("title", default: [Announcement])
      text(fill: colors.muted, size: 0.85em, [ — #a.date])
    })
    a.body
  }
}

// Course vocabulary. A description list, so a screen reader pairs each term
// with its definition, and so a student can search the page for a word.
#let glossary(entries) = context if target() == "html" {
  html.dl(for (term, definition) in entries {
    html.dt(html.dfn(term))
    html.dd(definition)
  })
} else {
  terms(
    tight: false,
    ..entries.map(((term, definition)) => terms.item(term, definition)),
  )
}

// Support services, tutoring centers, software, and hardware students may need.
// Grouped and named, so nobody has to guess whether "the center" means writing
// or math.
#let resource-table(items, caption: "Course and campus resources") = data-table(
  columns: 3,
  caption: caption,
  row-headers: true,
  header: ([Resource], [What it's for], [How to get it]),
  rows: items.map(i => (i.name, i.purpose, i.access)),
)
