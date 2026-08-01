#import "@preview/coconut:0.1.0": *

#import "../meetings.typ": meetings

// The recurring week, rendered three ways from one array: a grid, a list, and
// office hours on their own.

#let weekly = (
  title: "Weekly Schedule",
  path: "weekly",
  description: "Lecture, section, and office hour times for INFO 220.",
  body: [
    These meetings happen every week of the term. One-time events — exams,
    deadlines, the field trip — are on the #page-link("Schedule") page.

    #weekly-schedule(meetings)

    = The same schedule as a list

    #weekly-list(meetings)

    = Office hours

    #office-hours(meetings)
  ],
)
