#import "../config.typ": config
#import "../table.typ": cell, data-table
#import "../theme.typ": colors
#import "callout.typ": disclosure

// The syllabus / course home page: the document students return to all term,
// and the one most likely to be read on a phone, printed, fed to a screen
// reader, or skimmed for one fact at a time.

// A labelled list of facts. Rendered as a description list (`<dl>`) rather
// than a two-column table, because these are name/value pairs, not tabular
// data — the distinction is what lets a screen reader announce "Meets: Monday,
// Wednesday, Friday" as a pair instead of reading two disconnected cells.
#let facts(items) = context if target() == "html" {
  html.dl(
    class: "facts",
    for (term, body) in items {
      html.dt(term)
      html.dd(body)
    },
  )
} else {
  terms(
    tight: false,
    ..items.map(((term, body)) => terms.item(text(term), body)),
  )
}

// Header block for the course home page: the identifying facts, pulled from
// the `course` dictionary given to `bundle()` so they cannot drift out of sync
// with the running headers and footers on every other page.
//
// `extra` adds course-specific rows (a lab section, a required field trip, a
// software requirement) without having to rebuild the whole block.
#let course-header(description: none, extra: ()) = context {
  let c = config().course
  let row(key, term) = if c.at(key, default: none) != none { (term: term, body: c.at(key)) }
  let items = (
    row("term", [Term]),
    row("credits", [Credits]),
    row("meets", [Meets]),
    row("location", [Location]),
    row("modality", [Format]),
    row("prerequisites", [Prerequisites]),
    row("website", [Course website]),
    row("contact", [Contact]),
  ).filter(r => r != none) + extra

  if c.at("name", default: none) != none and c.at("code", default: none) != none {
    // The `<h1>` is the page title; this is the human-readable course name
    // under it, not a competing heading.
    block(text(size: 1.15em, fill: colors.muted, c.name))
  }
  if description != none { block(description) }
  facts(items)
}

// "By the end of this course you will be able to ..." — phrased as observable
// student actions. Kept as a real list so it can be skimmed and so screen
// readers announce how many objectives there are.
#let learning-objectives(
  items,
  title: [Learning objectives],
  intro: [By the end of this course, you will be able to:],
  level: 1,
) = {
  if title != none { heading(depth: level, title) }
  if intro != none { block(intro) }
  list(..items)
}

// Where the grade comes from. The total row is always shown: if the weights
// don't add to 100%, that is a mistake worth seeing on the page rather than
// discovering in week 10.
#let grade-breakdown(items, caption: "How the course grade is computed") = {
  let total = items.map(i => i.weight).sum(default: 0)
  data-table(
    columns: 3,
    caption: caption,
    row-headers: true,
    header: ([Component], [Weight], [Notes]),
    rows: items.map(i => (
      i.name,
      [#i.weight%],
      i.at("notes", default: []),
    ))
      + (
        (
          cell([Total], header: true),
          cell([#total%], header: true),
          cell(if total != 100 { [Weights do not sum to 100%.] } else { [] }, header: true),
        ),
      ),
  )
}

// Letter-grade scale. The default is a conventional US scale; pass your own
// `items` for standards-based, contract, or specification grading.
#let default-scale = (
  (grade: [A], range: [93–100%], meaning: [Consistently exceeds expectations]),
  (grade: [A−], range: [90–92%], meaning: []),
  (grade: [B+], range: [87–89%], meaning: []),
  (grade: [B], range: [83–86%], meaning: [Meets expectations]),
  (grade: [B−], range: [80–82%], meaning: []),
  (grade: [C+], range: [77–79%], meaning: []),
  (grade: [C], range: [73–76%], meaning: [Meets minimum expectations]),
  (grade: [C−], range: [70–72%], meaning: []),
  (grade: [D], range: [60–69%], meaning: [Below expectations]),
  (grade: [F], range: [Below 60%], meaning: [Does not meet expectations]),
)

#let grading-scale(items: default-scale, caption: "Grade scale") = data-table(
  columns: 3,
  caption: caption,
  row-headers: true,
  header: ([Grade], [Percentage], [Meaning]),
  rows: items.map(i => (i.grade, i.range, i.at("meaning", default: []))),
)

// A policy section. Long boilerplate (institutional statements, integrity
// policy, accommodation procedures) can be collapsed on the web with
// `collapse: true` — it still prints in full, since `disclosure()` shows its
// body on the paged target.
#let policy(title, body, level: 1, collapse: false) = {
  if collapse {
    disclosure(title, body)
  } else {
    heading(depth: level, title)
    body
  }
}

// The set of dates students most need: rendered once, near the top, instead of
// being spread across a term schedule they have to reconstruct.
#let key-dates(items, caption: "Key dates") = data-table(
  columns: 3,
  caption: caption,
  row-headers: true,
  header: ([Date], [What], [Notes]),
  rows: items.map(i => (i.date, i.what, i.at("notes", default: []))),
)
