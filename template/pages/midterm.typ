#import "@preview/coconut:0.1.0": *

// The exam and its key, from one body, the same way the problem set does it.
// The key is PDF-only — see `formats` below.

#let paper = [
  #exam-cover(
    duration: [50 minutes],
    materials: [One double-sided page of handwritten notes. No calculators,
      phones, or laptops.],
    instructions: (
      [Write your name on every page — pages are separated for grading.],
      [Show your work. An unexplained correct answer earns partial credit at best.],
      [If a question seems ambiguous, write down the interpretation you chose and answer it.],
      [Budget roughly one minute per point.],
    ),
  )

  #problem(title: [Definitions], points: 8)[
    Which of the following defines a temperature #emph[anomaly]?

    #multiple-choice(
      (
        [The difference between a year's temperature and a fixed baseline average],
        [The highest temperature recorded in a year],
        [The difference between two adjacent years],
        [A model's predicted temperature for a year],
      ),
      answer: 1,
    )
  ]

  #problem(title: [True or false], points: 6)[
    #true-false([A statistically significant trend in a temperature record
      implies the trend was caused by greenhouse gases.], answer: false)
    #true-false([Averaging over more years reduces the influence of interannual
      variability on the estimated trend.], answer: true)
  ]

  #problem(title: [Short answer], points: 16, new-page: true)[
    A city publishes a dashboard showing air quality at four sensors. Residents
    of one neighborhood say the dashboard reports clean air on days when they
    can see and smell smoke.

    Give two specific, technically plausible explanations for the discrepancy,
    and for each, describe one change to the monitoring program that would test
    it. The blank is worth #blank(answer: [4], width: 4em) points per
    explanation and #blank(answer: [4], width: 4em) points per test.

    #answer-space(lines: 8)

    #solution[
      Any two of: sensor siting (all four sensors are upwind or elevated, so
      test by deploying a sensor at street level in the affected neighborhood);
      temporal averaging (a 24-hour mean hides a three-hour spike, so test by
      publishing hourly values); pollutant coverage (the dashboard reports
      PM2.5 but not the pollutant responsible for the smell, so test by adding
      speciated monitoring); calibration drift (test by co-locating a reference
      instrument).
    ]
  ]

  #end-of-exam()
]

#let midterm = (
  title: "Midterm",
  kind: "exam",
  description: "INFO 220 midterm exam, Autumn 2026.",
  body: paper,
)

// `formats: ("pdf",)` gives the key a printable copy and no web page at all —
// one fewer URL to leak before the exam is graded.
#let midterm-key = (
  title: "Midterm: Answer Key",
  path: "midterm-key",
  kind: "exam",
  solutions: true,
  in-nav: false,
  formats: ("pdf",),
  body: paper,
)
