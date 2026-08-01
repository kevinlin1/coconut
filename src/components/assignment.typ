#import "../config.typ": showing-solutions
#import "../scope.typ": page-query
#import "../table.typ": cell, data-table
#import "../theme.typ": colors
#import "callout.typ": callout, disclosure
#import "syllabus.typ": facts

// Problem sets, labs, essays, studio briefs, lab reports — anything with
// numbered problems, points, and a due date.
//
// The organizing idea is that the student handout and the answer key are the
// *same source file*, emitted twice. `solution()` and `grading-note()` render
// only when the page is built with `solutions: true`, and — importantly — they
// are omitted from the output entirely rather than hidden with styling, so
// nothing recoverable is shipped to students in the HTML they can view-source.

#let problem-counter = counter("coconut:problem")
#let problem-label = label("coconut:problem")

// Points are recorded as metadata so a header at the top of the page can total
// problems that have not been rendered yet. Points on a `part()` are shown but
// not summed: a problem's `points:` is its own total, including its parts.
#let total-points() = {
  page-query(selector(problem-label))
    .map(m => m.value.points)
    .filter(p => p != none)
    .sum(default: 0)
}

#let problem-index() = page-query(selector(problem-label)).map(m => m.value)

#let points-label(points, of: none) = if points == none { none } else {
  let unit = if points == 1 { [point] } else { [points] }
  if of != none { [(#points of #of #unit)] } else { [(#points #unit)] }
}

// One problem. `title` is optional but worth writing: "Problem 3" tells a
// student nothing when they are scanning for the one about eigenvalues.
#let problem(title: none, points: none, tags: (), new-page: false, body) = {
  problem-counter.step()
  context {
    let n = problem-counter.get().first()
    let head = {
      [Problem #n]
      if title != none { [. #title] }
      if points != none {
        text(fill: colors.muted, [ #points-label(points)])
      }
    }
    let content = {
      [#metadata((number: n, title: title, points: points, tags: tags))#problem-label]
      heading(depth: 1, head)
      if tags.len() > 0 {
        block(text(size: 0.9em, fill: colors.muted, [Topics: #tags.join(", ")]))
      }
      body
    }
    if target() == "html" {
      html.section(class: "problem", content)
    } else {
      if new-page { pagebreak(weak: true) }
      block(width: 100%, breakable: true, content)
    }
  }
}

// Lettered parts of a problem, rendered as an ordered list so screen readers
// announce "3 of 5" and so the lettering can never drift out of sync with the
// prose that refers to it.
#let part(points: none, body) = (coconut-part: true, points: points, body: body)

#let parts(..items) = {
  let normalized = items.pos().map(i => if type(i) == dictionary and i.at("coconut-part", default: false) {
    i
  } else { (coconut-part: true, points: none, body: i) })
  enum(
    numbering: "(a)",
    ..normalized.map(p => {
      if p.points != none {
        text(fill: colors.muted, [#points-label(p.points) ])
      }
      p.body
    })
  )
}

// Shown only in the solutions build.
#let solution(body, title: none) = context if showing-solutions() {
  callout(kind: "tip", name: [Solution], title: title, body)
}

// Notes for whoever grades this — point splits, common wrong answers, what to
// give partial credit for. Also solutions-only.
#let grading-note(body) = context if showing-solutions() {
  callout(kind: "note", name: [Grading note], body)
}

// Always available to students, but out of the way: a hint you have to choose
// to open is a hint that doesn't spoil the problem for the student who wants to
// keep working. Prints in full.
#let hint(body, title: [Hint]) = disclosure(title, body)

// Blank space to write in. The ruled lines are marked as decorative so a
// screen reader announces the "Answer:" label and then moves on instead of
// reading a stack of empty rules; on the web, where nobody writes in the page,
// the space collapses to a note.
#let answer-space(lines: 5, height: none) = context if target() == "html" {
  html.p(class: "answer-space", [Space to write your answer is provided in the PDF version of this page.])
} else {
  block(above: 0.9em, below: 0.9em, {
    text(fill: colors.muted, size: 0.9em, [Answer:])
    v(0.3em)
    let rule = {
      line(length: 100%, stroke: 0.5pt + colors.line)
      v(0.85cm)
    }
    if height != none {
      block(width: 100%, height: height, stroke: 0.5pt + colors.line, radius: 2pt, [])
    } else {
      for _ in range(lines) { rule }
    }
  })
}

// Inline blank for fill-in-the-blank questions. In the solutions build the
// answer is printed in the blank instead of leaving it empty.
#let blank(answer: none, width: 3cm) = context {
  if showing-solutions() and answer != none {
    underline(text(fill: colors.tip, answer))
  } else if target() == "html" {
    [\_\_\_\_\_\_]
  } else {
    box(width: width, baseline: 0.1em, line(length: 100%, stroke: 0.5pt + colors.ink))
  }
}

// Header block for an assignment page. `points: auto` totals the problems on
// the page, so the header cannot disagree with the problems below it.
#let assignment-header(
  due: none,
  points: auto,
  submit: none,
  collaboration: none,
  estimate: none,
  weight: none,
  extra: (),
) = context {
  let total = if points == auto { total-points() } else { points }
  let items = (
    if due != none { (term: [Due], body: due) },
    if total != none and total != 0 { (term: [Points], body: [#total]) },
    if weight != none { (term: [Course weight], body: weight) },
    if estimate != none { (term: [Expected time], body: estimate) },
    if submit != none { (term: [Submit], body: submit) },
    if collaboration != none { (term: [Collaboration], body: collaboration) },
  ).filter(i => i != none) + extra
  if items.len() > 0 { facts(items) }
}

// Point distribution across the problems on this page.
#let points-summary(caption: "Point distribution", score-column: false) = context {
  let problems = problem-index()
  if problems.len() == 0 { return }
  let total = problems.map(p => p.points).filter(p => p != none).sum(default: 0)
  let score = if score-column { 1 } else { 0 }
  let header = ([Problem], [Points]) + ([Score],) * score
  let rows = problems.map(p => (
    if p.title != none { [#p.number. #p.title] } else { [#p.number] },
    if p.points != none { [#p.points] } else { [—] },
  ) + ([],) * score)
  let total-row = (
    cell([Total], header: true),
    cell([#total], emphasis: true),
  ) + (cell([], emphasis: true),) * score
  data-table(
    columns: header.len(),
    caption: caption,
    row-headers: true,
    header: header,
    rows: rows + (total-row,),
  )
}

// A one-dimensional rubric: what each criterion is worth.
#let rubric(items, caption: "Rubric") = {
  let total = items.map(i => i.points).sum(default: 0)
  data-table(
    columns: 3,
    caption: caption,
    row-headers: true,
    header: ([Criterion], [Points], [What earns full credit]),
    rows: items.map(i => (i.criterion, [#i.points], i.at("expectations", default: [])))
      + ((cell([Total], header: true), cell([#total], emphasis: true), cell([], emphasis: true)),),
  )
}

// A rubric matrix: criteria down the side, performance levels across the top.
// Common in writing-intensive and studio courses, and the hardest kind of table
// to make accessible by hand — every cell needs both of its headers.
#let rubric-matrix(criteria, levels, caption: "Rubric") = data-table(
  columns: levels.len() + 1,
  caption: caption,
  row-headers: true,
  header: ([Criterion],) + levels.map(l => l),
  rows: criteria.map(c => (c.criterion,) + levels.map(l => c.levels.at(l, default: []))),
)

// The last thing a student should read before submitting.
#let submission-checklist(items, title: [Before you submit]) = callout(
  kind: "warning",
  name: title,
  list(..items),
)
