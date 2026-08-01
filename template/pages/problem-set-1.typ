#import "@preview/coconut:0.1.0": *

// One body, two routes: the student handout and the answer key. `solution()`
// and `grading-note()` only render in the build that sets `solutions: true`, so
// the key cannot describe a problem that no longer exists.

#let handout = [
  #assignment-header(
    due: [Friday, October 9, 11:59 p.m.],
    submit: [As a single PDF on the course site],
    collaboration: [Discuss freely; write up alone, and name everyone you
      worked with at the top of your submission.],
    estimate: [4--6 hours],
    weight: [5% of the course grade],
  )

  This problem set covers the first two weeks: reading a temperature record,
  quantifying a trend, and saying honestly what the number does and does not
  show.

  #problem(title: [Reading the record], points: 10, tags: ("data literacy",))[
    The table below gives the annual mean surface temperature anomaly, in
    degrees Celsius relative to the 1951--1980 baseline, for six years.

    #data-table(
      columns: 2,
      caption: "Annual mean temperature anomaly",
      row-headers: true,
      header: ([Year], [Anomaly (°C)]),
      rows: (
        ([1980], [0.26]), ([1990], [0.45]), ([2000], [0.42]),
        ([2010], [0.72]), ([2020], [1.02]), ([2024], [1.28]),
      ),
    )

    #parts(
      part(points: 4)[Compute the mean anomaly for the six years shown. Show
        your arithmetic.],
      part(points: 6)[The 2000 value is lower than the 1990 value. Explain in
        two or three sentences why this does not, on its own, contradict a
        warming trend.],
    )

    #hint[Think about what a single year's value includes besides the long-term
      trend: El Niño and La Niña cycles, volcanic aerosols, and measurement
      noise all move an individual year up or down.]

    #solution[
      #parts(
        part[The mean is #eq(
          "the sum of 0.26, 0.45, 0.42, 0.72, 1.02 and 1.28, divided by 6, equals 4.15 over 6, approximately 0.69",
          $(0.26 + 0.45 + 0.42 + 0.72 + 1.02 + 1.28) / 6 = 4.15 / 6 approx 0.69$,
        )°C.],
        part[A trend is a statement about the central tendency of a series, not
          about every consecutive pair in it. Interannual variability — El Niño
          and La Niña in particular — is large enough to swamp a decade of trend
          in any single year, so year-to-year decreases are expected even while
          the trend is upward.],
      )
    ]

    #grading-note[Full credit on (b) requires naming a specific source of
      interannual variability *and* distinguishing a trend from a pairwise
      comparison. Award 3 of 6 for one without the other.]
  ]

  #problem(title: [Estimating a rate], points: 15, tags: ("modeling", "units"))[
    A linear fit to the full 1880--2024 record gives a slope of
    #eq("beta equals 0.0086", $beta = 0.0086$)°C per year, with a standard error
    of #eq("0.0004", $0.0004$)°C per year.

    #parts(
      part(points: 5)[Express the trend in degrees Celsius per decade, with
        units.],
      part(points: 5)[Give an approximate 95% confidence interval for the
        per-decade trend.],
      part(points: 5)[A classmate writes: "the model predicts 3.4°C of warming
        by 2424." State the strongest objection you can to that sentence.],
    )

    #answer-space(lines: 6)

    #solution[
      #parts(
        part[#eq("0.0086 times 10 equals 0.086", $0.0086 times 10 = 0.086$)°C per decade.],
        part[The standard error per decade is #eq("0.004", $0.004$)°C, so the
          interval is roughly #eq(
            "0.086 plus or minus 2 times 0.004, giving the interval 0.078 to 0.094",
            $0.086 plus.minus 2 times 0.004 = [0.078, 0.094]$,
          )°C per decade.],
        part[Extrapolating a linear fit four centuries past the data assumes the
          physical system stays linear over a range where it demonstrably does
          not; the confidence interval describes uncertainty in the fit, not the
          validity of extending the model.],
      )
    ]
  ]

  #problem(title: [Whose data?], points: 15, tags: ("ethics", "writing"))[
    Choose one of the monitoring programs discussed in week 2. In roughly 400
    words, describe who collects the data, who pays for it, who can access it,
    and one group that is affected by it but has no say in how it is collected.

    #rubric-matrix(
      (
        (
          criterion: [Accuracy of description],
          levels: (
            "Exemplary": [Specific and correct about funding, access, and governance],
            "Proficient": [Broadly correct with minor gaps],
            "Developing": [Significant factual errors, or too vague to check],
          ),
        ),
        (
          criterion: [Analysis of power],
          levels: (
            "Exemplary": [Identifies a concrete affected group and explains the mechanism of exclusion],
            "Proficient": [Identifies a group; mechanism is asserted rather than shown],
            "Developing": [Restates that data collection has consequences],
          ),
        ),
        (
          criterion: [Use of evidence],
          levels: (
            "Exemplary": [Cites course readings and at least one outside source],
            "Proficient": [Cites course readings],
            "Developing": [No citations],
          ),
        ),
      ),
      ("Exemplary", "Proficient", "Developing"),
    )
  ]

  #submission-checklist((
    [One PDF, with your name on the first page],
    [Collaborators named at the top],
    [Units on every numeric answer],
    [Word count for problem 3],
  ))
]

#let problem-set-1 = (
  title: "Problem Set 1",
  path: "problem-set-1",
  kind: "assignment",
  description: "INFO 220 problem set 1: reading a temperature record and estimating a trend.",
  body: handout,
)

// The same body, built with solutions on. Keep it out of the site navigation
// and hand out the URL when you release the key.
#let problem-set-1-key = (
  title: "Problem Set 1: Answer Key",
  path: "problem-set-1-key",
  kind: "assignment",
  solutions: true,
  in-nav: false,
  body: handout,
)
