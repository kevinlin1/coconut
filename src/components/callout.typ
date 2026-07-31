#import "../theme.typ": colors

// Boxed asides: the workhorse of a course page. Prerequisites, deadline
// reminders, worked examples, "common mistake" warnings, in-class activities.
//
// Every kind carries a *word*, not just a color and a border — a student
// reading a greyscale printout, a student with a color vision deficiency, and
// a screen reader all get the same signal. That is also why there are no icon
// glyphs: emoji and dingbats are announced inconsistently by screen readers
// ("information source"), and they render as tofu when the PDF font lacks them.
#let kinds = (
  note: (label: "Note", class: "note", fg: colors.note, bg: colors.note-bg),
  tip: (label: "Tip", class: "tip", fg: colors.tip, bg: colors.tip-bg),
  important: (label: "Important", class: "important", fg: colors.danger, bg: colors.danger-bg),
  warning: (label: "Warning", class: "warning", fg: colors.warn, bg: colors.warn-bg),
  deadline: (label: "Deadline", class: "deadline", fg: colors.warn, bg: colors.warn-bg),
  example: (label: "Example", class: "example", fg: colors.example, bg: colors.example-bg),
  activity: (label: "Activity", class: "activity", fg: colors.example, bg: colors.example-bg),
  objective: (label: "Learning objective", class: "objective", fg: colors.tip, bg: colors.tip-bg),
  accessibility: (label: "Accessibility", class: "note", fg: colors.note, bg: colors.note-bg),
)

// `name` overrides the leading word ("Solution", "Common mistake", "Fieldwork
// safety") while keeping a kind's color and shape.
#let callout(kind: "note", title: none, name: none, body) = {
  assert(
    kind in kinds,
    message: "unknown callout kind \"" + kind + "\"; expected one of " + kinds.keys().join(", "),
  )
  let k = kinds.at(kind)
  let word = if name != none { name } else { k.label }
  let label-text = if title != none { [#word: #title] } else { [#word] }
  context if target() == "html" {
    html.div(
      class: "callout callout-" + k.class,
      {
        html.p(class: "callout-label", label-text)
        body
      },
    )
  } else {
    block(
      width: 100%,
      fill: k.bg,
      stroke: (left: 4pt + k.fg, rest: 0.5pt + colors.line),
      radius: 3pt,
      inset: (x: 1em, y: 0.85em),
      breakable: true,
      {
        set text(fill: colors.ink)
        text(fill: k.fg, weight: 700, label-text)
        parbreak()
        body
      },
    )
  }
}

#let note(title: none, body) = callout(kind: "note", title: title, body)
#let tip(title: none, body) = callout(kind: "tip", title: title, body)
#let important(title: none, body) = callout(kind: "important", title: title, body)
#let warning(title: none, body) = callout(kind: "warning", title: title, body)
#let deadline(title: none, body) = callout(kind: "deadline", title: title, body)
#let example(title: none, body) = callout(kind: "example", title: title, body)
#let activity(title: none, body) = callout(kind: "activity", title: title, body)

// A disclosure: collapsed by default on the web, always visible in print.
// Hiding content behind a control the reader can't operate is the classic way
// a "clean" web page becomes an incomplete printout, so the paged rendering
// keeps the summary as a run-in label and shows the body.
#let disclosure(summary, body, open: false) = context if target() == "html" {
  let attrs = (:)
  if open { attrs.insert("open", "") }
  html.elem("details", attrs: attrs, {
    html.summary(summary)
    body
  })
} else {
  block(
    width: 100%,
    fill: colors.surface,
    stroke: 0.5pt + colors.line,
    radius: 3pt,
    inset: (x: 1em, y: 0.85em),
    {
      text(weight: 600, summary)
      parbreak()
      body
    },
  )
}
