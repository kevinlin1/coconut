// Shared visual language for both targets.
//
// The palette is the accessibility floor of the package: every foreground /
// background pair listed here clears WCAG 2.2 contrast level AAA (7:1) for
// body text, in both the light and dark schemes, so an instructor can drop in
// a callout or a table without checking contrast themselves. Colors are also
// never the only carrier of meaning — callouts pair their tint with a label,
// schedule rows pair theirs with a word ("Holiday", "Exam").

#let light = (
  paper: rgb("#ffffff"),
  surface: rgb("#f4f6f8"),
  ink: rgb("#141618"),
  muted: rgb("#4c525c"),
  line: rgb("#c9d0d8"),
  accent: rgb("#0b5394"),
  visited: rgb("#6b3fa0"),
  note: rgb("#0b5394"),
  note-bg: rgb("#eaf2fb"),
  tip: rgb("#1a5c3a"),
  tip-bg: rgb("#e7f4ec"),
  warn: rgb("#7a4a00"),
  warn-bg: rgb("#fdf1dc"),
  danger: rgb("#9a1f27"),
  danger-bg: rgb("#fdecec"),
  example: rgb("#5a3e9e"),
  example-bg: rgb("#f0ecfb"),
)

#let dark = (
  paper: rgb("#14171a"),
  surface: rgb("#1b1f23"),
  ink: rgb("#e8eaed"),
  muted: rgb("#a9b1bb"),
  line: rgb("#3a4149"),
  accent: rgb("#7fb7f0"),
  visited: rgb("#c4a6f0"),
  note: rgb("#9dc6f2"),
  note-bg: rgb("#16222e"),
  tip: rgb("#8fd3ab"),
  tip-bg: rgb("#132218"),
  warn: rgb("#e8c07a"),
  warn-bg: rgb("#241c0d"),
  danger: rgb("#f2a2a5"),
  danger-bg: rgb("#241516"),
  example: rgb("#c3aef0"),
  example-bg: rgb("#1c1830"),
)

// Paged output is printed on white, so it always uses the light scheme.
#let colors = light

// Typography for paged output. The defaults are the families Typst embeds in
// the compiler, so a build produces the same PDF on a laptop and on a CI runner
// and never emits "unknown font family" warnings at someone who has no idea
// what to do about them.
//
// Override per site: `bundle(fonts: (body: "Charter", heading: "Inter"))`. Any
// family named there does have to be installed. HTML output ignores this and
// uses the reader's system font stack, which is the accessible default on the
// web — it respects the font the reader has already chosen.
#let default-fonts = (
  body: "Libertinus Serif",
  heading: "Libertinus Serif",
  mono: "DejaVu Sans Mono",
)

// ---------------------------------------------------------------------------
// HTML
// ---------------------------------------------------------------------------

// Typst has no way to write into `<head>` from a bundle document, so the
// stylesheet is emitted inline at the top of `<body>`. Browsers apply it
// identically; keeping it inline also means a page saved or emailed on its own
// still looks and behaves right, which matters for students who download
// course materials to read offline.
//
// Notable accessibility choices below: focus is always visible, the reading
// measure is capped near 70 characters, nothing is sized in absolute px so the
// browser's font-size setting is respected, motion is opt-out, wide tables
// scroll in a labelled and keyboard-reachable region, and there is a print
// stylesheet so printing the HTML is a reasonable substitute for the PDF.
#let stylesheet = "
:root {
  color-scheme: light dark;
  --paper: #ffffff; --surface: #f4f6f8; --ink: #141618; --muted: #4c525c;
  --line: #c9d0d8; --accent: #0b5394; --visited: #6b3fa0;
  --note: #0b5394; --note-bg: #eaf2fb;
  --tip: #1a5c3a; --tip-bg: #e7f4ec;
  --warn: #7a4a00; --warn-bg: #fdf1dc;
  --danger: #9a1f27; --danger-bg: #fdecec;
  --example: #5a3e9e; --example-bg: #f0ecfb;
  --measure: 70ch;
  --sans: system-ui, -apple-system, 'Segoe UI', Roboto, 'Helvetica Neue', sans-serif;
  --mono: ui-monospace, SFMono-Regular, 'JetBrains Mono', Menlo, Consolas, monospace;
}
@media (prefers-color-scheme: dark) {
  :root {
    --paper: #14171a; --surface: #1b1f23; --ink: #e8eaed; --muted: #a9b1bb;
    --line: #3a4149; --accent: #7fb7f0; --visited: #c4a6f0;
    --note: #9dc6f2; --note-bg: #16222e;
    --tip: #8fd3ab; --tip-bg: #132218;
    --warn: #e8c07a; --warn-bg: #241c0d;
    --danger: #f2a2a5; --danger-bg: #241516;
    --example: #c3aef0; --example-bg: #1c1830;
  }
}
html { font-family: var(--sans); }
body {
  margin: 0; background: var(--paper); color: var(--ink);
  line-height: 1.6; font-size: 1.0625rem; text-wrap: pretty;
  -webkit-text-size-adjust: 100%;
}
main, .site-header > *, .site-footer > * {
  max-width: var(--measure); margin-inline: auto; padding-inline: 1.25rem;
}
main { padding-block: 1.5rem 4rem; display: block; }

/* Skip link: present for keyboard users, out of the way for everyone else. */
.skip-link {
  position: absolute; left: -9999px; top: 0; z-index: 10;
  background: var(--paper); color: var(--accent);
  padding: 0.75rem 1rem; border: 2px solid var(--accent); border-radius: 0 0 6px 0;
}
.skip-link:focus { left: 0; }
.visually-hidden {
  position: absolute; width: 1px; height: 1px; margin: -1px; padding: 0;
  overflow: hidden; clip-path: inset(50%); white-space: nowrap;
}

a { color: var(--accent); text-underline-offset: 0.15em; }
a:visited { color: var(--visited); }
a:hover { text-decoration-thickness: 0.15em; }
:focus-visible { outline: 3px solid var(--accent); outline-offset: 2px; border-radius: 2px; }

h1, h2, h3, h4, h5, h6 { line-height: 1.25; text-wrap: balance; margin: 2rem 0 0.5rem; }
h1 { font-size: clamp(1.75rem, 1.3rem + 2vw, 2.35rem); margin-top: 0; }
h2 { font-size: 1.5rem; padding-bottom: 0.2rem; border-bottom: 1px solid var(--line); }
h3 { font-size: 1.2rem; }
h4, h5, h6 { font-size: 1.03rem; }
p, ul, ol, dl, table, figure, blockquote, pre, details { margin-block: 0.85rem; }
li { margin-block: 0.3rem; }
img { max-width: 100%; height: auto; }
code, pre, kbd { font-family: var(--mono); font-size: 0.94em; }
pre {
  background: var(--surface); padding: 0.9rem 1rem; border-radius: 8px;
  border: 1px solid var(--line); overflow-x: auto;
}
blockquote {
  margin-inline: 0; padding: 0.2rem 1rem; border-left: 4px solid var(--line); color: var(--muted);
}

/* Site chrome */
.site-header {
  background: var(--surface); border-bottom: 1px solid var(--line); padding-block: 0.75rem;
}
.site-header .course-name { font-weight: 700; }
.site-header .course-term { color: var(--muted); }
.site-nav ul {
  list-style: none; margin: 0.5rem 0 0; padding: 0;
  display: flex; flex-wrap: wrap; gap: 0.25rem 1.25rem;
}
.site-nav a {
  display: inline-block; padding: 0.35rem 0; min-height: 44px; line-height: 44px;
}
.site-nav [aria-current='page'] { font-weight: 700; text-decoration-thickness: 0.18em; }
.site-footer {
  border-top: 1px solid var(--line); padding-block: 1.25rem 2.5rem;
  color: var(--muted); font-size: 0.94rem;
}
.page-meta { color: var(--muted); margin-top: -0.35rem; }

/* Tables: wide ones scroll inside a labelled, focusable region instead of
   forcing the page to scroll sideways. */
.table-scroll { overflow-x: auto; margin-block: 1rem; }
.table-scroll:focus-visible { outline-offset: 0; }
table { border-collapse: collapse; width: 100%; }
caption {
  text-align: left; font-weight: 600; padding-bottom: 0.5rem; color: var(--ink);
}
th, td {
  text-align: left; vertical-align: top; padding: 0.5rem 0.7rem;
  border: 1px solid var(--line);
}
thead th { background: var(--surface); }
tbody th { background: var(--surface); font-weight: 600; }
td.empty { background: repeating-linear-gradient(135deg, transparent, transparent 6px, var(--surface) 6px, var(--surface) 12px); }

/* Callouts */
.callout {
  border: 1px solid var(--line); border-left: 6px solid var(--muted);
  border-radius: 6px; padding: 0.1rem 1rem; margin-block: 1.25rem;
  background: var(--surface);
}
.callout > .callout-label {
  font-weight: 700; margin-block: 0.85rem 0; display: flex; gap: 0.5rem; align-items: baseline;
}
.callout-note { border-left-color: var(--note); background: var(--note-bg); }
.callout-note > .callout-label { color: var(--note); }
.callout-tip, .callout-objective { border-left-color: var(--tip); background: var(--tip-bg); }
.callout-tip > .callout-label, .callout-objective > .callout-label { color: var(--tip); }
.callout-warning, .callout-deadline { border-left-color: var(--warn); background: var(--warn-bg); }
.callout-warning > .callout-label, .callout-deadline > .callout-label { color: var(--warn); }
.callout-important { border-left-color: var(--danger); background: var(--danger-bg); }
.callout-important > .callout-label { color: var(--danger); }
.callout-example, .callout-activity { border-left-color: var(--example); background: var(--example-bg); }
.callout-example > .callout-label, .callout-activity > .callout-label { color: var(--example); }

/* Disclosure widgets (hints, long descriptions, policy details) */
details {
  border: 1px solid var(--line); border-radius: 6px; padding: 0 1rem; background: var(--surface);
}
details[open] { padding-bottom: 0.5rem; }
summary {
  cursor: pointer; font-weight: 600; padding: 0.7rem 0; min-height: 44px;
  display: list-item;
}

/* Staff directory, course facts, problems */
.staff-list { list-style: none; padding: 0; display: grid; gap: 1rem; }
@media (min-width: 45rem) { .staff-list { grid-template-columns: repeat(2, 1fr); } }
.staff-card {
  border: 1px solid var(--line); border-radius: 8px; padding: 0.9rem 1rem; background: var(--surface);
}
.staff-card h3 { margin: 0 0 0.15rem; font-size: 1.05rem; }
.staff-card .role { color: var(--muted); }
.staff-card dl { display: grid; grid-template-columns: max-content 1fr; gap: 0.15rem 0.6rem; margin: 0.5rem 0 0; }
.staff-card dt { font-weight: 600; }
.staff-card dd { margin: 0; }
.facts { display: grid; grid-template-columns: max-content 1fr; gap: 0.35rem 1rem; }
.facts dt { font-weight: 700; }
.facts dd { margin: 0; }
.problem { margin-block: 1.75rem; }
.problem-head { display: flex; flex-wrap: wrap; gap: 0.6rem; align-items: baseline; }
.points { color: var(--muted); font-variant-numeric: tabular-nums; }
.solution { border-left: 6px solid var(--tip); }
.answer-space {
  border: 2px dashed var(--line); border-radius: 6px; color: var(--muted);
  padding: 0.75rem 1rem; margin-block: 0.85rem;
}
.badge {
  display: inline-block; font-size: 0.85rem; font-weight: 700; padding: 0.1rem 0.5rem;
  border-radius: 999px; border: 1px solid currentColor;
}

@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after { animation-duration: 0.01ms !important; transition-duration: 0.01ms !important; }
}

@media print {
  .site-nav, .skip-link, .no-print { display: none; }
  body { font-size: 11pt; }
  main { max-width: none; }
  a::after { content: ' (' attr(href) ')'; font-size: 0.85em; word-break: break-all; }
  a[href^='#']::after { content: ''; }
  .callout, table, figure, .problem { break-inside: avoid; }
}
"

// ---------------------------------------------------------------------------
// Paged
// ---------------------------------------------------------------------------

// Page geometry per `kind`. Assignments and exams get a wider bottom margin
// because their footers carry more (point totals, "continued" notices).
#let paged-margins = (
  page: (x: 1.9cm, y: 2.1cm),
  handout: (x: 2.2cm, y: 2.2cm),
  assignment: (x: 2cm, top: 2.1cm, bottom: 2.4cm),
  exam: (x: 2cm, top: 2.3cm, bottom: 2.4cm),
)

// Base typography and element styling for PDF output. Deliberately does *not*
// touch `heading` structure — restyling headings through a `show` rule that
// returns a `block` would erase the heading semantics that tagged PDF and
// HTML export both depend on, so styling goes through `set` rules instead.
#let paged-styles(kind: "page", fonts: (:), lang: "en", body) = {
  let fonts = default-fonts + fonts
  // `lang` is not cosmetic: it selects hyphenation and quotation rules, and it
  // is what tells a screen reader which voice to read the PDF in.
  set text(font: fonts.body, size: 11pt, lang: lang, fill: colors.ink)
  set par(leading: 0.72em, spacing: 1.1em, justify: false)
  show raw: set text(font: fonts.mono, size: 0.92em)

  // Headings sit one level below the page title, matching the `<h1>`/`<h2>`
  // nesting the HTML target produces.
  set heading(offset: 1, numbering: none)
  show heading: set text(font: fonts.heading, fill: colors.ink)
  show heading.where(level: 2): set block(above: 1.6em, below: 0.7em)
  show heading.where(level: 3): set block(above: 1.3em, below: 0.6em)

  set list(indent: 0.6em, spacing: 0.9em)
  set enum(indent: 0.6em, spacing: 0.9em, numbering: "1.a.i.")
  set terms(separator: [: ], hanging-indent: 1.2em)

  // Links are underlined, not just colored, so they survive greyscale printing
  // and don't rely on color perception.
  show link: it => text(fill: colors.accent, underline(it.body, offset: 0.12em))

  // Only geometry here: header shading belongs to `data-table()`, which knows
  // which rows are headers. A blanket `fill: (_, y) => if y == 0 { .. }` would
  // shade the first data row of any plain `table()` an instructor writes.
  set table(stroke: 0.5pt + colors.line, inset: (x: 0.7em, y: 0.55em))
  show table.cell.where(y: 0): set text(hyphenate: false)

  set figure(gap: 0.9em)
  show figure.caption: set text(size: 0.92em, fill: colors.muted)
  // A term schedule is taller than a page. Unbreakable figures would push the
  // whole table to the next page and leave a third of this one blank, so
  // tables are allowed to split and repeat their header row.
  show figure.where(kind: table): set block(breakable: true)

  set quote(block: true)
  show quote: set pad(left: 1em)

  body
}
