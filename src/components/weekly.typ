#import "../table.typ": data-table
#import "../time.typ": format-range, parse-time

// The weekly view: only the things that happen every week — lecture, sections,
// labs, office hours. One-time events belong on the term schedule, not here.
//
// There is deliberately no time grid here. A week laid out as a two-dimensional
// table of times against days is the shape courses reach for first, and it is
// the worst of the options: even built honestly as a `<table>` with `rowspan`,
// it is read cell by cell, it needs sideways scrolling on a phone, and it falls
// apart at large text sizes. `weekly-list()` says the same thing as prose —
// which is also the version that survives being pasted into an email.

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

// What a meeting is. `office-hours` is the one kind that changes a rendering —
// `office-hours()` selects on it — but the rest are worth naming so a course's
// meetings describe themselves, and so a typo is caught at compile time.
#let kinds = (
  "lecture", "section", "lab", "studio", "office-hours", "review", "other",
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

// The meetings as a linear list, grouped by day: one heading per day, so a
// screen reader's heading list is a way to jump to Thursday.
#let weekly-list(meetings, clock: "12h", level: 2) = {
  let used = meetings.map(m => m.days).flatten().dedup().sorted()
  for d in used {
    let todays = meetings.filter(m => d in m.days).sorted(key: m => m.start)
    heading(depth: level, day-names.at(d))
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
