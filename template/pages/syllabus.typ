#import "@preview/coconut:0.1.0": *

#import "../course.typ": drafts

// The landing page. `path: "index"` is what makes it the page a bare URL opens,
// and what `pages.sh` looks for when it lays out the published site.

#let syllabus = (
  title: "Syllabus",
  path: "index",
  nav-label: "Home",
  description: "INFO 220: Climate Data and Society — syllabus for Autumn 2026.",
  body: [
    #course-header(description: [How do measurements of the atmosphere become
      arguments about policy? This course follows environmental data from the
      instrument that records it to the graph in a city council meeting, and
      asks what is gained and lost at every step.])

    #learning-objectives((
      [Read a published environmental dataset and describe how it was collected],
      [Estimate a trend from a time series and state its uncertainty honestly],
      [Explain what a statistical claim about climate does and does not establish],
      [Evaluate who benefits from, and who is excluded by, a monitoring program],
      [Communicate a quantitative finding to a non-technical audience],
    ))

    #note(title: [Everything here works in both formats])[
      Every page of this site is available as a web page and as a PDF, built
      from the same source. Use whichever suits you: the PDF for printing and
      annotating, the web page for screen readers, phones, and text resizing.
      If something on either version is unusable, email me — that is a bug.
    ]

    = How the course works

    Three lectures a week, one section, and a problem set every other week.
    Lecture introduces a method; section is where you practice it with a TA in
    the room; problem sets are where you find out whether you can do it alone.

    #grade-breakdown((
      (name: [Problem sets (5)], weight: 40, notes: [Lowest score dropped]),
      (name: [Midterm], weight: 20, notes: [In class, week 6]),
      (name: [Final project], weight: 30, notes: [Proposal, draft, and final report]),
      (name: [Section participation], weight: 10, notes: [Attendance and weekly exercise]),
    ))

    #grading-scale()

    = Key dates

    #key-dates(caption: "Dates and deadlines at a glance", (
      (date: [Friday, October 9], what: [Problem set 1 due], notes: [11:59 p.m.]),
      (date: [Wednesday, November 4], what: [Midterm], notes: [In class, 50 minutes]),
      (date: [Friday, November 13], what: [Final project proposal due], notes: []),
      (date: [Friday, December 11], what: [Final report due], notes: [No late days]),
    ))

    = Policies

    #policy-sections(drafts, (
      "accessibility",
      "late",
      "ai",
      "integrity",
      "community",
      "religious",
      "basic-needs",
      "communication",
    ))
  ],
)
