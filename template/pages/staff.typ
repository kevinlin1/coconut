#import "@preview/coconut:0.1.0": *

#import "../staff.typ": roster

// Who teaches the course. The directory is generated from the roster in
// `staff.typ`; only the prose and the "who to ask" table are written here.

#let staff = (
  title: "Staff",
  description: "Who teaches INFO 220, when their office hours are, and who to ask about what.",
  body: [
    Office hours are the single most under-used resource in this course. You do
    not need a specific question to come to them.

    #staff-directory(roster)

    = Who to ask about what

    #who-to-ask((
      (need: [An extension, or something going on in your life], contact: [Dr. Okonkwo]),
      (need: [A regrade on a problem set], contact: [Priya Raman, within one week of the grade]),
      (need: [Help with the data analysis tools], contact: [Diego Salazar's office hours]),
      (need: [A disability accommodation], contact: [Disability Resources for Students, then Dr. Okonkwo]),
      (need: [Anything the whole class would benefit from], contact: [The course forum]),
    ))
  ],
)
