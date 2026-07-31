#import "../table.typ": cell, data-table
#import "../theme.typ": colors
#import "../time.typ": format-range, format-time, parse-time

// The weekly view: only the things that happen every week — lecture, sections,
// labs, office hours. One-time events belong on the term schedule, not here.
//
// A time grid is where accessible course sites usually break down, because the
// obvious implementation is absolute positioning over a background image, which
// is unreadable to a screen reader and unusable at large text sizes. This one
// is a genuine `<table>`: times are row headers, days are column headers, and a
// meeting spans rows with `rowspan`, so "Tuesday, 10:30 a.m." reads out with
// both of its coordinates. `weekly-list()` renders the same data as prose for
// readers who would rather not navigate a grid at all.

#let day-names = (
  "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday",
)

#let day-aliases = {
  let aliases = (:)
  for (i, name) in day-names.enumerate() {
    aliases.insert(lower(name), i)
    aliases.insert(lower(name.slice(0, 3)), i)
  }
  aliases.insert("tues", 1)
  aliases.insert("thur", 3)
  aliases.insert("thurs", 3)
  aliases
}

#let parse-day(day) = {
  if type(day) == int { return day }
  let key = lower(day).trim().trim(".")
  assert(key in day-aliases, message: "unrecognized day \"" + day + "\"")
  day-aliases.at(key)
}

// Labels are content so they can be compared against a meeting's own title:
// a cell that already says "Office hours" should not then say "Office hours".
#let kinds = (
  lecture: (label: [Lecture], fill: colors.note-bg),
  section: (label: [Section], fill: colors.tip-bg),
  lab: (label: [Lab], fill: colors.tip-bg),
  studio: (label: [Studio], fill: colors.tip-bg),
  office-hours: (label: [Office hours], fill: colors.example-bg),
  review: (label: [Review], fill: colors.warn-bg),
  other: (label: none, fill: none),
)

#let meeting(
  title,
  days: (),
  start: none,
  end: none,
  location: none,
  staff: none,
  kind: "other",
  url: none,
  note: none,
) = {
  assert(start != none and end != none, message: "meeting " + repr(title) + " needs start: and end:")
  assert(kind in kinds, message: "unknown meeting kind \"" + kind + "\"")
  (
    title: title,
    days: (if type(days) == str { (days,) } else { days }).map(parse-day),
    start: parse-time(start),
    end: parse-time(end),
    location: location,
    staff: staff,
    kind: kind,
    url: url,
    note: note,
  )
}

#let meeting-body(m, clock: "12h", show-time: true) = {
  let k = kinds.at(m.kind)
  block({
    set text(size: 0.94em)
    strong(if m.url != none { link(m.url, m.title) } else { m.title })
    if k.label != none and k.label != m.title {
      linebreak()
      text(fill: colors.muted, k.label)
    }
    if show-time {
      linebreak()
      format-range(m.start, m.end, clock: clock)
    }
    if m.location != none {
      linebreak()
      m.location
    }
    if m.staff != none {
      linebreak()
      text(fill: colors.muted, m.staff)
    }
    if m.note != none {
      linebreak()
      text(fill: colors.muted, m.note)
    }
  })
}

// Group a day's meetings into blocks of mutually overlapping meetings. Two
// meetings that overlap share one cell rather than fighting over the same grid
// slot — the honest rendering of "office hours run during the other section".
#let blocks-for-day(meetings) = {
  let sorted = meetings.sorted(key: m => m.start)
  let blocks = ()
  for m in sorted {
    if blocks.len() > 0 and m.start < blocks.last().end {
      let last = blocks.pop()
      blocks.push((
        start: last.start,
        end: calc.max(last.end, m.end),
        meetings: last.meetings + (m,),
      ))
    } else {
      blocks.push((start: m.start, end: m.end, meetings: (m,)))
    }
  }
  blocks
}

#let weekly-schedule(
  meetings,
  days: auto,
  slot: 30,
  start: auto,
  end: auto,
  clock: "12h",
  caption: "Weekly schedule",
) = {
  if meetings.len() == 0 { return }
  let day-indices = if days != auto { days.map(parse-day) } else {
    meetings.map(m => m.days).flatten().dedup().sorted()
  }
  let first = if start != auto { parse-time(start) } else {
    let earliest = meetings.map(m => m.start).reduce(calc.min)
    earliest - calc.rem(earliest, slot)
  }
  let last = if end != auto { parse-time(end) } else {
    let latest = meetings.map(m => m.end).reduce(calc.max)
    latest + calc.rem(slot - calc.rem(latest, slot), slot)
  }
  let slots = range(first, last, step: slot)

  // For each day: where a block starts, and which slots it covers.
  let day-blocks = day-indices.map(d => blocks-for-day(meetings.filter(m => d in m.days)))

  let rows = ()
  for (r, t) in slots.enumerate() {
    let row = (cell(format-time(t, clock: clock), header: true, scope: "row"),)
    for (c, blocks) in day-blocks.enumerate() {
      let starting = blocks.filter(b => b.start >= t and b.start < t + slot)
      let covering = blocks.filter(b => b.start < t and b.end > t)
      if starting.len() > 0 {
        // Two short meetings can begin inside the same slot without
        // overlapping; they share the cell rather than one of them vanishing.
        let span = starting
          .map(b => calc.max(1, calc.ceil((b.end - b.start) / slot)))
          .reduce(calc.max)
        // Don't let the last block run past the bottom of the grid.
        let span = calc.min(span, slots.len() - r)
        row.push(cell(
          for b in starting { for m in b.meetings { meeting-body(m, clock: clock) } },
          rowspan: span,
          fill: kinds.at(starting.first().meetings.first().kind).fill,
        ))
      } else if covering.len() == 0 {
        row.push(cell([], class: "empty"))
      }
    }
    rows.push(row)
  }

  data-table(
    columns: day-indices.len() + 1,
    caption: caption,
    row-headers: true,
    header: ([Time],) + day-indices.map(d => day-names.at(d)),
    rows: rows,
  )
}

// The same meetings as a linear list, grouped by day. Faster to read on a
// phone, faster to read aloud, and the version that survives being pasted into
// an email.
#let weekly-list(meetings, clock: "12h", level: 2) = {
  let used = meetings.map(m => m.days).flatten().dedup().sorted()
  for d in used {
    let todays = meetings.filter(m => d in m.days).sorted(key: m => m.start)
    heading(level: level, day-names.at(d))
    list(
      ..todays.map(m => {
        strong(if m.url != none { link(m.url, m.title) } else { m.title })
        [, #format-range(m.start, m.end, clock: clock)]
        if m.location != none { [, #m.location] }
        if m.staff != none { [ — #m.staff] }
        if m.note != none { [ (#m.note)] }
      })
    )
  }
}

// Office hours pulled out of the weekly data, in the form students actually
// ask for: who, when, where, and how to get in the queue.
#let office-hours(meetings, caption: "Office hours", clock: "12h") = {
  let hours = meetings
    .filter(m => m.kind == "office-hours")
    .map(m => m.days.map(d => (day: d, m: m)))
    .flatten()
    .sorted(key: e => (e.day, e.m.start))
  data-table(
    columns: 4,
    caption: caption,
    row-headers: true,
    header: ([Who], [Day], [Time], [Where]),
    rows: hours.map(e => (
      if e.m.staff != none { e.m.staff } else { e.m.title },
      day-names.at(e.day),
      format-range(e.m.start, e.m.end, clock: clock),
      if e.m.location != none { e.m.location } else { [] },
    )),
  )
}
