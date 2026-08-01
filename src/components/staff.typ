#import "../alt.typ": check-alt
#import "../table.typ": data-table
#import "../theme.typ": colors
#import "syllabus.typ": facts

// The course staff page. For many students this is the page that decides
// whether they ever come to office hours, so it carries the things that
// actually lower that barrier: who each person is, what they are there for,
// when and where to find them, and how to reach them.

#let person(
  name,
  role: none,
  pronouns: none,
  email: none,
  hours: none,
  location: none,
  // The photo itself, as bytes: `read("okonkwo.jpg", encoding: none)`. A path
  // would be resolved against this file, inside the package, rather than
  // against the roster the author wrote it in.
  photo: none,
  photo-alt: none,
  bio: none,
  links: (),
) = (
  name: name,
  role: role,
  pronouns: pronouns,
  email: email,
  hours: hours,
  location: location,
  photo: photo,
  photo-alt: photo-alt,
  bio: bio,
  links: links,
)

#let card-body(p) = {
  let items = (
    if p.email != none { (term: [Email], body: link("mailto:" + p.email, raw(p.email))) },
    if p.hours != none { (term: [Office hours], body: p.hours) },
    if p.location != none { (term: [Where], body: p.location) },
    if p.links.len() > 0 {
      (term: [Links], body: p.links.map(l => link(l.url, l.label)).join([, ]))
    },
  ).filter(i => i != none)

  if p.photo != none {
    // A staff photo is meaningful content, not decoration — it is how a student
    // recognizes who to approach in a crowded office-hour room — so it needs a
    // real description of the person. "Photo of instructor" is rejected for the
    // same reason a missing one is: neither helps anyone find the right desk.
    check-alt(p.photo-alt, "the photo of " + repr(p.name))
    assert(
      type(p.photo) == bytes,
      message: "person " + repr(p.name) + " has a photo that is not image data.\n"
        + "  Read the file where the path is written: photo: read(\"..\", encoding: none)",
    )
    box(width: 4cm, image(p.photo, alt: p.photo-alt, width: 100%))
  }
  if p.bio != none { block(p.bio) }
  if items.len() > 0 { facts(items) }
}

#let name-line(p) = {
  p.name
  if p.pronouns != none {
    [ ]
    text(fill: colors.muted, [(#p.pronouns)])
  }
}

// `level: 1` by default: the cards are the page's main content, so they are
// its `<h2>`s. Dropping them to `<h3>` would skip a heading level between the
// page title and its first content heading, which is exactly the structural
// gap screen-reader users use to navigate.
#let staff-directory(members, level: 1, columns: 2) = context if target() == "html" {
  html.ul(
    class: "staff-list",
    for p in members {
      html.li(class: "staff-card", {
        heading(depth: level, name-line(p))
        if p.role != none { html.p(class: "role", p.role) }
        card-body(p)
      })
    },
  )
} else {
  grid(
    columns: (1fr,) * columns,
    gutter: 1em,
    ..members.map(p => block(
      width: 100%,
      fill: colors.surface,
      stroke: 0.5pt + colors.line,
      radius: 3pt,
      inset: 0.9em,
      breakable: false,
      {
        heading(depth: level, name-line(p))
        if p.role != none { block(text(fill: colors.muted, p.role)) }
        card-body(p)
      },
    ))
  )
}

// A compact "who to ask about what" table. Students consistently guess wrong
// about which staff member handles regrades, extensions, or accommodations,
// and guessing wrong costs them a week.
#let who-to-ask(items) = {
  data-table(
    columns: 2,
    row-headers: true,
    caption: "Who to contact",
    header: ([If you need…], [Contact]),
    rows: items.map(i => (i.need, i.contact)),
  )
}
