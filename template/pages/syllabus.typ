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

    // The one figure in the example site. `alt` says what the diagram is —
    // enough to know whether to open it — and `description` says what it shows,
    // because four labelled boxes are not a sentence. Both are checked at
    // compile time; try replacing the alt with "diagram.svg" and rebuilding.
    //
    // `read()` rather than a path: Typst resolves a relative path against the
    // file the `image()` call is written in, and that call is inside the
    // package, not here.
    #figure-image(
      read("../figures/data-to-argument.svg", encoding: none),
      width: 100%,
      alt: "Four labelled boxes joined left to right by arrows: instrument, dataset, analysis, argument.",
      caption: [The route a measurement takes, and the four places this course stops
        along it.],
      description: [A measurement starts at an *instrument*, which can see some
        things and not others: a thermometer at an airport records the air over a
        runway, not the air over the neighborhood beside it. What the instrument
        records becomes a *dataset*, which keeps some of the reading and drops the
        rest — a monthly average keeps the trend and loses the afternoon it was
        hottest. The dataset supports an *analysis*, which can establish some
        claims and not others: a trend is not a cause, and a correlation across
        cities is not a prediction for one. The analysis is then made into an
        *argument* in public, where the uncertainty that survived every earlier
        step is usually the first thing dropped. The course spends roughly two
        weeks at each arrow.],
    )

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
