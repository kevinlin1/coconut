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

One source file builds three things, chosen by `--format`:

```sh
# The website: one HTML page and one PDF per route, into main/
typst watch main.typ --features bundle,html --format bundle

# The course reader: every page in sequence as one continuous PDF
typst compile main.typ --features bundle,html --format pdf main/course-reader.pdf

# The same reader as a single long web page
typst compile main.typ --features bundle,html --format html main/course-reader.html
```

Add `--pdf-standard ua-1` to any PDF build to have Typst enforce the
accessibility standard; the example site passes in every shape.

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

Each route becomes `<path>.html` and `<path>.pdf`, or one section of the reader.
`bundle()` gives every page the same course identity and navigation, so the
running header on a printed problem set can't disagree with the banner on the
website. `in-nav: false` keeps a route out of the site navigation; `in-reader:
false` keeps it out of the reader, which is how you avoid binding an answer key
into the copy students print.

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
  word as well as a tint. Code listings go further and carry no syntax
  highlighting at all: Typst writes highlight colors into each span as an inline
  style, so they cannot follow the reader's color scheme, and no single color
  clears 4.5:1 against both the light and the dark code background. Code is set
  in body ink, which clears AAA in both.
- **Totals are not headers.** A total row is shaded and bold like a header, but
  only its label is a `<th>`; the figures beside it are data, and a blank cell
  is never a header with nothing to announce.
- **Web defaults that respect the reader:** system font stack, no absolute font
  sizes, visible focus, reduced-motion support, wide tables scrolling inside a
  labelled focusable region, and a print stylesheet.
- **MathML.** Typst exports math as MathML on the web, which screen readers
  read structurally.

## One site, three shapes

The website and the reader are the same routes rendered two ways, not two
pipelines. The switch is `target()`, which reports **`"bundle"`** at the top
level of a bundle export and `"paged"` or `"html"` when a single document is
being built — so `page()` either constructs `document()` elements or contributes
a section to the document already in progress:

```typst
context if target() == "bundle" {
  for format in formats { document(base + "." + format, ..) }  // the website
} else if target() == "paged" and "pdf" in formats {
  contents(single: true)                                       // one section of the reader
}
```

This is the shape Typst's own documentation uses to publish typst.app/docs and
its standalone reference PDF from one source (see `docs/components/section.typ`
in the Typst repository, which branches between `html-section` and
`paged-section` the same way). Reader mode drops the per-page furniture —
navigation, the "download as PDF" link — lets page numbering run straight
through, and adds a cover and a table of contents.

## Working with bundles

Four things about bundle export are worth knowing, because they are the source
of most surprises:

1. **Introspection is global.** `counter.final()`, `state.final()`, and a bare
   `query()` see every document in the bundle at once. `page()` resets counters
   at the top of each document, and `page-query()` / `page-total()` bound a
   query to the document being rendered — that is how an assignment header can
   total points from problems below it without picking up every other problem
   set on the site.
2. **`set page(..)` and layout functions only exist on the paged target.**
   Anything paged-only belongs behind `context if target() != "html"`.
3. **A `document()` body can be a whole `html.html(..)` tree.** That is the only
   way to write into `<head>`, which is where the stylesheet, viewport, and
   description belong; Typst still injects its MathML styles alongside them.
4. **`heading(level: ..)` is absolute and ignores `offset`.** Components take a
   relative level and pass it as `depth:`, so a component heading nests under
   the page title instead of becoming its sibling. Getting this wrong is
   invisible in HTML and shows up as a flat PDF outline.

## License

MIT.
