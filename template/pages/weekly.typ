#import "@preview/coconut:0.1.0": *

#import "../meetings.typ": meetings

// The recurring week, rendered two ways from one array: day by day, and office
// hours on their own.

#let weekly = (
  title: "Weekly Schedule",
  path: "weekly",
  description: "Lecture, section, and office hour times for INFO 220.",
  body: [
    These meetings happen every week of the term. One-time events — exams,
    deadlines, the field trip — are on the #page-link("Schedule") page.

    #weekly-list(meetings, level: 1)

    = Office hours

    #office-hours(meetings)
  ],
)
