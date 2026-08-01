#import "@preview/coconut:0.1.0": *

#import "course.typ": this-course
#import "pages/syllabus.typ": syllabus
#import "pages/staff.typ": staff
#import "pages/weekly.typ": weekly
#import "pages/schedule.typ": schedule
#import "pages/problem-set-1.typ": problem-set-1, problem-set-1-key
#import "pages/midterm.typ": midterm, midterm-key
#import "pages/readings.typ": readings

// A complete, if small, course site: syllabus, staff, term schedule, weekly
// meetings, a problem set with its answer key, a midterm with its key, and a
// readings page. Every page is emitted as both HTML and PDF from this one
// bundle.
//
// This file is the site itself and nothing else. Each page is written in its
// own file under `pages/`, where it defines the route it becomes — its title,
// its URL, and its body — and the list below puts those routes in order. That
// order is the order of the navigation and of the course reader, so adding a
// page means writing it in `pages/` and naming it here.
//
// Beside this file are the things no single page owns:
//
//   course.typ     the course itself, and the policy text the syllabus draws on
//   staff.typ      the roster the staff page and its office hours come from
//   meetings.typ   the recurring lecture, section, and office hour times

#bundle(
  course: this-course,
  // Only used by the single-document editions (`--format pdf` / `--format html`).
  title: "INFO 220: Complete Course Reader",
  (
    syllabus,
    staff,
    weekly,
    schedule,
    problem-set-1,
    // The same problem set body with solutions switched on, kept out of the
    // navigation. Both routes come from `pages/problem-set-1.typ`.
    problem-set-1-key,
    midterm,
    midterm-key,
    readings,
  ),
)
