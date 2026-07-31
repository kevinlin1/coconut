// coconut — accessible course materials in HTML and PDF from one source.
//
// This file is the package's public API; it has no content of its own. Every
// component below renders on both targets, and the two renderings carry the
// same information: what is a disclosure widget on the web prints open, what is
// blank writing space in the PDF becomes a note on the web, and nothing that
// matters exists only in one format.

// --- Documents and site structure -----------------------------------------
#import "src/document.typ": (
  bundle, chrome, html-shell, page, reader-contents, reader-front-matter,
  reset-counters,
)
#import "src/course.typ": course
#import "src/config.typ": config, showing-solutions
#import "src/slug.typ": slugify
#import "src/scope.typ": page-count, page-query, page-total

// --- Theme, tables, and time ----------------------------------------------
#import "src/theme.typ": colors, dark, default-fonts, light, paged-margins, stylesheet
#import "src/table.typ": cell, data-table
#import "src/time.typ": format-range, format-time, parse-time

// --- Page furniture --------------------------------------------------------
#import "src/components/nav.typ": (
  format-switcher, page-href, page-link, site-footer, site-header, site-nav,
)

// --- Callouts and media ----------------------------------------------------
#import "src/components/callout.typ": (
  activity, callout, deadline, disclosure, example, important, note, tip, warning,
)
#import "src/components/media.typ": (
  code-listing, decorative, eq, figure-image, file-link, media-link,
)

// --- Syllabus and policies -------------------------------------------------
#import "src/components/syllabus.typ": (
  course-header, facts, grade-breakdown, grading-scale, key-dates,
  learning-objectives, policy,
)
#import "src/policies.typ": policy-drafts, policy-sections

// --- People ----------------------------------------------------------------
#import "src/components/staff.typ": person, staff-directory, who-to-ask

// --- Schedules -------------------------------------------------------------
#import "src/components/schedule.typ": course-schedule, deadline-list, due
#import "src/components/weekly.typ": (
  meeting, office-hours, weekly-list, weekly-schedule,
)

// --- Assignments and exams -------------------------------------------------
#import "src/components/assignment.typ": (
  answer-space, assignment-header, blank, grading-note, hint, part, parts,
  points-summary, problem, problem-index, rubric, rubric-matrix, solution,
  submission-checklist, total-points,
)
#import "src/components/exam.typ": (
  end-of-exam, exam-cover, exam-instructions, identity-lines, matching,
  multiple-choice, true-false,
)

// --- Readings and reference ------------------------------------------------
#import "src/components/resources.typ": (
  announcements, badge, glossary, materials-index, reading, reading-list,
  resource-table,
)
