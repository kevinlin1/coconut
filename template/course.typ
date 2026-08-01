#import "@preview/coconut:0.1.0": *

// The course itself, and the starting text for the policies the syllabus
// renders. Both live outside any one page: `bundle()` gives every route the
// same course identity, and the drafts are written once and cited wherever a
// page needs them.

#let this-course = course(
  code: "INFO 220",
  name: "Climate Data and Society",
  term: "Autumn 2026",
  credits: "5 credits",
  meets: [Monday, Wednesday, Friday, 10:30--11:20 a.m.],
  location: [Kane Hall 210],
  modality: [In person, with all materials online],
  prerequisites: [One course in statistics, or permission of the instructor],
  url: "https://example.edu/info220",
  contact: [Course forum (preferred) or #link("mailto:info220@example.edu")[info220\@example.edu]],
  updated: [July 31, 2026],
)

#let drafts = policy-drafts(
  institution: "Example University",
  accessibility-office: "Disability Resources for Students",
  accessibility-contact: link("mailto:drs@example.edu")[drs\@example.edu],
  integrity-policy: link("https://example.edu/integrity")[the university integrity policy],
  counseling: link("https://example.edu/counseling")[Counseling Center],
  basic-needs: link("https://example.edu/basic-needs")[the Husky Pantry and Basic Needs Center],
  title-ix: "the Title IX office",
  instructor-email: link("mailto:okonkwo@example.edu")[okonkwo\@example.edu],
  late-days: 4,
  ai: "limited",
)
