#import "../table.typ": cell, data-table
#import "../theme.typ": colors

// The term-length course schedule: the page students consult most often after
// the first week, usually to answer one narrow question ("what do I have to
// read for Thursday?").
//
// It is a real data table with a header row *and* a header column, so a screen
// reader announces "Week 4, Read before class: Chapter 6" instead of stranding
// a cell with no idea which week it belongs to. Special rows (breaks, exams,
// project milestones) are marked with a word as well as a tint, because a row
// that is only distinguished by being slightly yellow is not distinguished at
// all in print, in greyscale, or to a screen reader.

// The default columns. Pass your own dictionary to rename, reorder, or drop
// them — a seminar might use `(dates: [Dates], text: [Reading], lead: [Discussion lead])`,
// a studio course `(dates: [Dates], topic: [Focus], critique: [Critique])`.
#let default-columns = (
  dates: [Dates],
  topic: [Topic],
  prepare: [Prepare before class],
  due: [Due],
)

#let row-kinds = (
  normal: (label: none, fill: none),
  // Quoted because `break` is a keyword; `kind: "break"` still reads naturally
  // at the call site.
  "break": (label: [No class], fill: colors.surface),
  exam: (label: [Assessment], fill: colors.warn-bg),
  milestone: (label: [Milestone], fill: colors.tip-bg),
)

// `rows` is an array of dictionaries. Each has a `label` (the row header — a
// week number, a date, a unit name), any subset of the `columns` keys, and
// optionally `kind` and `note`. A row with a `note` spans the full width, for
// "Spring break — no class, no assignments due".
#let course-schedule(
  rows,
  columns: default-columns,
  header: [Week],
  caption: "Course schedule",
) = {
  let keys = columns.keys()
  let width = keys.len() + 1

  let body-rows = rows.map(row => {
    let kind = row-kinds.at(row.at("kind", default: "normal"))
    let head = cell(
      {
        row.at("label", default: [])
        if kind.label != none {
          linebreak()
          text(size: 0.9em, fill: colors.muted, kind.label)
        }
      },
      header: true,
      fill: kind.fill,
    )
    if row.at("note", default: none) != none {
      (head, cell(row.note, colspan: width - 1, fill: kind.fill))
    } else {
      (head,) + keys.map(k => cell(row.at(k, default: []), fill: kind.fill))
    }
  })

  data-table(
    columns: width,
    caption: caption,
    row-headers: true,
    header: (header,) + keys.map(k => columns.at(k)),
    rows: body-rows,
  )
}

// An assignment or milestone mentioned inside a schedule cell. Links to the
// assignment page and states the due time — a date without a time is the single
// most common ambiguity in a course schedule.
#let due(what, at: none, url: none) = {
  let label = if at != none { [#what, due #at] } else { what }
  if url != none { link(url, label) } else { label }
}

// A chronological list of everything with a deadline, generated from the same
// data as the schedule so the two cannot disagree. Some students navigate by
// week, others by deadline; this serves the second group without a second
// source of truth.
#let deadline-list(items, caption: "All deadlines") = data-table(
  columns: 3,
  caption: caption,
  row-headers: true,
  header: ([Due], [What], [Where to submit]),
  rows: items.map(i => (i.at("at"), i.what, i.at("submit", default: []))),
)
