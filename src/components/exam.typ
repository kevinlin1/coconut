#import "../config.typ": showing-solutions
#import "../theme.typ": colors
#import "assignment.typ": points-summary, total-points
#import "callout.typ": callout
#import "syllabus.typ": facts

// Exams and quizzes. Built on the same `problem()` machinery as assignments,
// with the extra apparatus a proctored assessment needs: a cover page, the
// rules stated where students will actually read them, and a grading grid.
//
// Building the exam and its key from one source is worth more here than
// anywhere else in the package — an answer key that was edited separately from
// the exam is how a question ends up graded against a solution to its previous
// draft.

// Lines for a student to write their name and ID on. Paged only: nobody writes
// on the HTML, and an empty ruled box would just be noise in a screen reader.
#let identity-lines(fields: ([Name], [Student ID], [Section])) = context {
  if target() == "html" { return }
  grid(
    columns: (1fr,) * fields.len(),
    gutter: 1.2em,
    ..fields.map(f => {
      f
      v(1.4em)
      line(length: 100%, stroke: 0.5pt + colors.ink)
    })
  )
}

// The instructions students are held to. Stated as a list rather than a
// paragraph so that a student rereading under time pressure can find one rule
// without rereading all of them.
#let exam-instructions(items, title: [Instructions]) = callout(
  kind: "important",
  name: title,
  list(..items),
)

#let exam-cover(
  duration: none,
  materials: none,
  aid-sheet: none,
  instructions: (),
  points: auto,
  identity: true,
  grading-grid: true,
  accommodations: [If you have an accommodation for extra time or a separate
    room and have not yet arranged it, tell the proctor before you begin.],
) = context {
  let total = if points == auto { total-points() } else { points }
  let items = (
    if duration != none { (term: [Time limit], body: duration) },
    if total != none and total != 0 { (term: [Total points], body: [#total]) },
    if materials != none { (term: [Allowed materials], body: materials) },
    if aid-sheet != none { (term: [Reference sheet], body: aid-sheet) },
  ).filter(i => i != none)

  if identity { identity-lines() }
  if items.len() > 0 { facts(items) }
  if instructions.len() > 0 { exam-instructions(instructions) }
  if accommodations != none { callout(kind: "note", name: [Accommodations], accommodations) }
  if grading-grid {
    // Filled in by the grader; also tells the student, before they start, how
    // the points are spread so they can budget their time.
    points-summary(caption: "Points by problem", score-column: true)
  }
  if target() != "html" { pagebreak(weak: true) }
}

// Multiple choice. Rendered as an ordered list so the choice letters come from
// the document structure instead of hand-typed "(A)" prefixes that drift when a
// choice is inserted. `answer` is the 1-based index of the correct choice (or
// an array of them); it is only rendered in the solutions build, and it is
// marked with a word, never with color alone.
#let multiple-choice(choices, answer: none, multiple: false) = context {
  let correct = if answer == none { () } else if type(answer) == array { answer } else { (answer,) }
  let reveal = showing-solutions()
  block({
    if multiple {
      text(fill: colors.muted, [Select all that apply.])
    }
    enum(
      numbering: "(A)",
      ..choices.enumerate().map(((i, choice)) => {
        choice
        if reveal and (i + 1) in correct {
          text(fill: colors.tip, weight: 700, [ — correct])
        }
      })
    )
  })
}

#let true-false(statement, answer: none) = context {
  block({
    statement
    if showing-solutions() and answer != none {
      text(fill: colors.tip, weight: 700, [ — #if answer [True] else [False]])
    } else {
      [ ]
      text(fill: colors.muted, [(True / False)])
    }
  })
}

// Matching questions: prompts on the left, options on the right. Kept as two
// lists rather than a drawn line-matching layout, since a layout that only
// works when you can draw on it excludes anyone taking the exam digitally.
#let matching(prompts, options, answer: (:)) = context {
  let reveal = showing-solutions()
  grid(
    columns: (1fr, 1fr),
    gutter: 1.5em,
    {
      strong[Prompts]
      enum(
        ..prompts.enumerate().map(((i, p)) => {
          p
          [ ]
          if reveal and str(i + 1) in answer {
            text(fill: colors.tip, weight: 700, [#answer.at(str(i + 1))])
          } else {
            text(fill: colors.muted, [\_\_\_\_])
          }
        })
      )
    },
    {
      strong[Options]
      enum(numbering: "(A)", ..options)
    },
  )
}

// Marks the end of the exam, so a student who has lost track of the page order
// knows there is nothing after this.
#let end-of-exam(body: [End of exam. Check that you have answered every problem.]) = context {
  set align(center)
  set text(fill: colors.muted)
  block(above: 2em, body)
}
