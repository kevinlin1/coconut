#import "@preview/coconut:0.1.0": *

// Everything that happens every week: lecture, sections, and office hours. The
// weekly page renders these two ways — day by day, and as office hours alone —
// from this one array, so the two cannot disagree.

#let meetings = (
  meeting(
    [Lecture],
    days: ("Mon", "Wed", "Fri"),
    start: "10:30am",
    end: "11:20am",
    location: [Kane 210],
    kind: "lecture",
  ),
  meeting(
    [Section AA],
    days: "Thu",
    start: "12:30pm",
    end: "1:20pm",
    location: [Savery 131],
    staff: [Priya Raman],
    kind: "section",
  ),
  meeting(
    [Section AB],
    days: "Thu",
    start: "1:30pm",
    end: "2:20pm",
    location: [Savery 131],
    staff: [Priya Raman],
    kind: "section",
  ),
  meeting(
    [Section AC],
    days: "Fri",
    start: "1:30pm",
    end: "2:20pm",
    location: [Savery 137],
    staff: [Diego Salazar],
    kind: "section",
  ),
  meeting(
    [Office hours],
    days: "Tue",
    start: "2:00pm",
    end: "4:00pm",
    location: [Mary Gates 312],
    staff: [Dr. Okonkwo],
    kind: "office-hours",
  ),
  meeting(
    [Office hours],
    days: "Wed",
    start: "3:00pm",
    end: "5:00pm",
    location: [Online],
    staff: [Diego Salazar],
    kind: "office-hours",
    note: [Link on the course forum],
  ),
  meeting(
    [Office hours],
    days: "Thu",
    start: "1:00pm",
    end: "3:00pm",
    location: [Odegaard, ground floor],
    staff: [Priya Raman],
    kind: "office-hours",
  ),
)
