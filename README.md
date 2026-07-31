# coconut

Accessible course materials in HTML and PDF, from one Typst source.

Higher education faculty end up maintaining the same course content twice: a
website students read on a phone and a screen reader, and a stack of PDFs
students print and write on. The two drift apart, and the accessible one is
usually the one that falls behind. `coconut` uses Typst's experimental
[bundle export](https://typst.app/docs/) to emit both from the same file, and
ships the components a course actually needs — syllabus, staff directory, term
schedule, weekly meeting grid, problem sets, exams, readings — with the
accessibility work already done.

```sh
typst watch main.typ --features bundle,html --format bundle
```

That writes `main/index.html`, `main/index.pdf`, `main/schedule.html`, and so
on. To check the PDFs against the accessibility standard:

```sh
typst compile main.typ --features bundle,html --format bundle --pdf-standard ua-1
```

`main.typ` is a complete example course site; `lib.typ` is the public API.

## A course site in one file

```typst
#import "@preview/coconut:0.1.0": *

#let info220 = course(
  code: "INFO 220",
  name: "Climate Data and Society",
  term: "Autumn 2026",
  meets: [Monday, Wednesday, Friday, 10:30--11:20 a.m.],
  url: "https://example.edu/info220",
)

#bundle(course: info220, (
  (title: "Syllabus", path: "index", nav-label: "Home", body: [
    #course-header(description: [How do measurements become policy?])
    #learning-objectives(([Read a published dataset], [Estimate a trend]))
    #grade-breakdown((
      (name: [Problem sets], weight: 40),
      (name: [Final project], weight: 60),
    ))
  ]),
  (title: "Problem Set 1", kind: "assignment", body: pset1),
  // Same body, solutions switched on, kept out of the navigation.
  (title: "Problem Set 1: Answer Key", solutions: true, in-nav: false, body: pset1),
))
```

Each route becomes `<path>.html` and `<path>.pdf`. `bundle()` gives every page
the same course identity and navigation, so the running header on a printed
problem set can't disagree with the banner on the website.

## What's in the box

| Module | Components |
| --- | --- |
| Documents | `page`, `bundle`, `course`, `slugify` |
| Syllabus | `course-header`, `facts`, `learning-objectives`, `grade-breakdown`, `grading-scale`, `key-dates`, `policy` |
| Policies | `policy-drafts`, `policy-sections` — starter text for accommodations, integrity, generative AI, late work, basic needs |
| People | `person`, `staff-directory`, `who-to-ask` |
| Schedules | `course-schedule`, `deadline-list`, `due`, `weekly-schedule`, `weekly-list`, `office-hours`, `meeting` |
| Assignments | `problem`, `parts`, `part`, `solution`, `grading-note`, `hint`, `answer-space`, `blank`, `rubric`, `rubric-matrix`, `points-summary`, `submission-checklist` |
| Exams | `exam-cover`, `exam-instructions`, `multiple-choice`, `true-false`, `matching`, `identity-lines`, `end-of-exam` |
| Callouts | `callout`, `note`, `tip`, `important`, `warning`, `deadline`, `example`, `activity`, `disclosure` |
| Media | `figure-image`, `eq`, `media-link`, `file-link`, `code-listing`, `decorative` |
| Reference | `reading`, `reading-list`, `materials-index`, `announcements`, `glossary`, `resource-table`, `badge` |
| Building blocks | `data-table`, `cell`, `page-query`, `page-total`, `colors`, `parse-time` |

## One source, two students

Components differ between targets only where the format genuinely differs, and
never by dropping information:

- `hint()` is a disclosure widget on the web and prints open, so the handout is
  never missing something the web page has.
- `answer-space()` is ruled writing space in the PDF and a note on the web.
- `solution()` and `grading-note()` are **omitted from the output** in the
  student build rather than hidden with styling — there is nothing to recover
  from view-source.
- Links between pages resolve to sibling `.html` files on the web, and to the
  live site (when `course(url: ..)` is set) from inside a PDF, because relative
  links between downloaded PDFs break the moment one is emailed.

## The accessibility floor

The point of the package is that a component you drop in is already accessible:

- **One `<h1>` per page**, a `<main>` landmark, a skip link, and body headings
  starting at `<h2>` — matched in the PDF by `heading(offset: 1)`, so both
  formats have the same outline.
- **Real data tables.** `data-table()` emits `<caption>` and `scope="col"` /
  `scope="row"` headers, so a schedule cell is announced with both of its
  coordinates. The weekly grid is a table with `rowspan`, not positioned boxes.
- **Every PDF passes `--pdf-standard ua-1`,** including the example site.
  Tagged PDF is on by default in Typst; `figure-image()` refuses to build
  without `alt`, and `eq()` attaches the spoken form of an equation.
- **Contrast.** Every foreground/background pair in the palette clears WCAG 2.2
  AAA (7:1) in both light and dark schemes.
- **Never color alone.** Callouts, schedule rows, and marked answers all carry a
  word as well as a tint.
- **Web defaults that respect the reader:** system font stack, no absolute font
  sizes, visible focus, reduced-motion support, wide tables scrolling inside a
  labelled focusable region, and a print stylesheet.
- **MathML.** Typst exports math as MathML on the web, which screen readers
  read structurally.

## Working with bundles

Two things about bundle export are worth knowing, because they are the source
of most surprises:

1. **Introspection is global.** `counter.final()`, `state.final()`, and a bare
   `query()` see every document in the bundle at once. `page()` resets counters
   at the top of each document, and `page-query()` / `page-total()` bound a
   query to the document being rendered — that is how an assignment header can
   total points from problems below it without picking up every other problem
   set on the site.
2. **`set page(..)` and layout functions only exist on the paged target.**
   Anything paged-only belongs behind `context if target() != "html"`.

## License

MIT.
