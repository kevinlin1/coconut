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
# The website: one HTML page and one PDF per route, into site/
typst watch main.typ --features bundle,html --format bundle site

# The course reader: every page in sequence as one continuous PDF
typst compile main.typ --features bundle,html --format pdf course-reader.pdf

# The same reader as a single long web page
typst compile main.typ --features bundle,html --format html course-reader.html
```

Add `--pdf-standard ua-1` to any PDF build to have Typst enforce the
accessibility standard; the example site passes in every shape.

`template/` is a complete example course site — it is what `typst init
@preview/coconut` gives you, with `main.typ` as the entrypoint and one file per
page beside it. `lib.typ` is the public API. To build it from a clone of this
repository rather than from the published package, see
[Development](#development).

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

## A course site in several files

A page is a dictionary, so a page can live in its own file and a term's worth of
material never has to sit in one buffer. That is how the example template is
written: `main.typ` holds the pinned import and the ordered list of routes,
each file under `pages/` defines the route it becomes, and the data more than
one page draws on — the course itself, the staff roster, the recurring meetings
— sits beside them.

```
template/
├── main.typ              the import, and the list below
├── course.typ            course() and policy-drafts()
├── staff.typ             the person() roster
├── meetings.typ          the meeting() times
└── pages/
    ├── syllabus.typ      #let syllabus = (title: .., path: "index", body: [..])
    ├── problem-set-1.typ one body, exported twice: handout and answer key
    └── ..
```

```typst
// pages/syllabus.typ
#import "@preview/coconut:0.1.0": *
#import "../course.typ": drafts

#let syllabus = (
  title: "Syllabus",
  path: "index",
  body: [#course-header(description: [..]) #policy-sections(drafts, ("late", "ai"))],
)
```

```typst
// main.typ — the list is the site: it sets the navigation and the reader order.
#import "pages/syllabus.typ": syllabus
#bundle(course: this-course, (syllabus, staff, problem-set-1, problem-set-1-key))
```

Every file imports `@preview/coconut:<version>` for itself, the way any
multi-file Typst project does, so bumping the package version means bumping the
pin in each of them.

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
  read structurally. In the PDF it is alt text instead — see below.

These are claims, so CI checks them — see [Development](#development).

## Where math is not equal in both formats

This is the one place the package does not deliver on "the same information in
both formats," and the cause is upstream rather than fixable here.

A screen reader can only navigate an equation — step into a fraction, re-read a
single subscript, hand the expression to a braille display — if the file carries
the equation's *structure*. On the web it does: Typst emits real MathML. In a
PDF, structure requires PDF 2.0's associated-files mechanism, which attaches a
MathML representation to each `Formula` structure element; PDF/UA-1, built on
PDF 1.7, has no such mechanism and allows only a flat `/Alt` string.

**Typst 0.15.1 never emits that MathML.** Inspecting the PDFs this repository
builds, every equation is a `/Formula` element carrying `/Alt` and nothing else
— no MathML, no `/AF` associated-file entries — and that is true whether the
document targets PDF 1.7 or PDF 2.0. Nor can PDF/UA-2 be requested: `ua-1` is
the only accessibility standard `--pdf-standard` accepts, and asking for
`2.0,ua-1` fails outright with *"PDF 2.0 is not compatible with PDF/UA-1."* So
today the choice is PDF/UA-1 with alt-text math, or PDF 2.0 with alt-text math
and no enforced accessibility standard at all.

What this means in practice:

- `eq(alt, body)` is not belt-and-braces, it is the *only* thing a PDF reader
  gets. Write the alt the way you would say the formula out loud in class —
  `eq("beta equals 0.0086", $beta = 0.0086$)` — because a reader cannot fall
  back to the structure to work out what you meant.
- A flat string cannot be navigated or re-read in pieces. For a long or nested
  expression, point students at the web version, which can be.
- Anything that is genuinely a diagram in disguise — a commutative diagram, a
  labelled derivation — is better served by `figure-image()` with real alt text
  than by an equation.

When Typst gains MathML in tagged PDF, `eq()` is the seam that changes: it
already has both the structural body and the spoken form, so the alt text stays
useful and no course content needs rewriting.

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

## Development

The template imports `@preview/coconut:0.1.0`, the same pinned import a consumer
writes, because it is the source they receive from `typst init`. Building it
from a clone therefore needs one extra step: the working tree is staged into
`dist/` as if it were the published package, and `--package-path` points Typst
at it. The pin resolves to your branch instead of to Typst Universe, so there is
no second copy of the example site to drift out of sync, and nothing to rewrite
before publishing.

```sh
npm install && npx playwright install chromium

npm run check          # stage, build all three shapes, then run axe
npm run build          # stage and build only, into build/
npm run axe -- build/site build/reader
npm run pages          # build, then lay out the published site in build/pages
```

`npm run build` wraps `.github/scripts/build.sh`, which is also what CI runs. To
drive the compiler yourself — for `typst watch`, say — stage once and pass the
path:

```sh
node .github/scripts/stage-package.mjs
typst watch template/main.typ --package-path dist --features bundle,html --format bundle site
```

Staging also verifies that every `@preview/coconut` pin under `template/` — the
entrypoint, the data files, and each page — matches `version` in `typst.toml`,
and names the files that disagree if any do. Without that check a version bump
that misses one file leaves Typst reporting only `package not found`.

`.github/workflows/accessibility.yml` runs the same build on every push and pull
request, with `--pdf-standard ua-1` on the PDFs so Typst enforces PDF/UA, then
runs [axe-core](https://github.com/dequelabs/axe-core) over every emitted HTML
page against WCAG 2.2 AA plus axe's best-practice rules. The reader is checked
alongside the website, because concatenating every route into one document can
produce problems no single page has.

## Publishing

The same workflow publishes the example site to GitHub Pages on every push to
`main`. The deployment downloads the artifact the accessibility job already
checked instead of building a second time, so what goes live is byte for byte
what axe passed, and a failing check blocks the deployment rather than
publishing alongside it.

`.github/scripts/pages.sh` lays out what gets served. The website goes at the
root, so the relative links the bundle emits — navigation, the per-page PDF
links, cross-page links in the schedule — work unchanged; the course reader is
copied in beside it as `course-reader.html` and `course-reader.pdf`. Run
`npm run pages` to produce that same directory locally in `build/pages`, and
serve it with any static file server to check it before pushing.

One caution the example inherits: `bundle()` emits every page you declare,
including those marked `in-nav: false`. An answer key kept out of the navigation
is unlisted, not private — publishing the site publishes it to anyone who reads
the URL out of a classmate's browser history. Release keys by adding them to the
bundle after the deadline, or build them separately and hand them out directly.

Publishing needs Pages switched on once, under **Settings → Pages → Build and
deployment → Source: GitHub Actions**. Until it is, the deployment step fails
with `Resource not accessible by integration` while the accessibility job keeps
passing.

Publishing your own course needs none of this machinery — the staging and
assembly scripts exist because this repository builds the example against its
own working tree. From the published package it is one command, and `site/` is
the directory to hand to `actions/upload-pages-artifact`:

```sh
typst compile main.typ --features bundle,html --format bundle site
```

## License

MIT.
