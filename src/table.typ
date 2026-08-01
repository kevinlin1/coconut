#import "theme.typ": colors
#import "config.typ"

// A table that stays a *data* table on both targets.
//
// Typst's built-in `table()` already exports a real `<table>` with `<thead>`
// and `<th>`, but two things that assistive technology depends on have no
// Typst equivalent: `scope` attributes (which tell a screen reader whether a
// header labels a row or a column) and `<caption>` (which names the table when
// it is reached out of context). Row headers matter a lot here — a course
// schedule is read row by row ("Week 3: ..."), and an office hours table is
// read cell by cell ("Priya Raman, Thursday, ..."), which only works if the
// leading column is marked as headers too.
//
// So the HTML rendering is emitted by hand, and the paged rendering uses
// `table()` (whose header row Typst tags for PDF/UA).

// One cell. Callers may pass bare content instead and get the defaults.
//
// `header` and `emphasis` are deliberately separate. A total row looks like a
// header — bold, shaded — but only its label is one: "Total" names the row,
// while the figure beside it is data, and a blank cell at the end of the row
// names nothing at all. Marking those as `<th>` gives a screen reader a header
// with no text to announce, so they take `emphasis` and stay `<td>`.
#let cell(
  body,
  header: false,
  emphasis: false,
  scope: none,
  colspan: 1,
  rowspan: 1,
  fill: none,
  align: auto,
  class: none,
) = (
  coconut-cell: true,
  body: body,
  header: header,
  emphasis: emphasis,
  scope: scope,
  colspan: colspan,
  rowspan: rowspan,
  fill: fill,
  align: align,
  class: class,
)

#let normalize(c) = if type(c) == dictionary and c.at("coconut-cell", default: false) { c } else { cell(c) }

#let paged-cell(c, header: false) = {
  let c = normalize(c)
  // On the paged target the distinction is purely visual, so `emphasis` and
  // `header` render identically.
  let prominent = c.header or c.emphasis or header
  table.cell(
    colspan: c.colspan,
    rowspan: c.rowspan,
    align: c.align,
    fill: if c.fill != none { c.fill } else if prominent { colors.surface },
    if prominent { strong(c.body) } else { c.body },
  )
}

#let html-cell(c, default-scope: none) = {
  let c = normalize(c)
  let is-header = c.header or c.scope != none or default-scope != none
  let attrs = (:)
  if is-header and (c.scope != none or default-scope != none) {
    attrs.insert("scope", if c.scope != none { c.scope } else { default-scope })
  }
  if c.colspan > 1 { attrs.insert("colspan", str(c.colspan)) }
  if c.rowspan > 1 { attrs.insert("rowspan", str(c.rowspan)) }
  // An emphasized data cell carries the header's appearance as a class; a real
  // header already gets it from the `th` rules in the stylesheet.
  let classes = ()
  if c.class != none { classes.push(c.class) }
  if c.emphasis and not is-header { classes.push("emphasis") }
  if classes.len() > 0 { attrs.insert("class", classes.join(" ")) }
  if c.fill != none { attrs.insert("style", "background-color: " + c.fill.to-hex() + ";") }
  html.elem(if is-header { "th" } else { "td" }, attrs: attrs, c.body)
}

// `header` is one row of column headers (or an array of rows for a stacked
// header). `rows` is an array of rows. When `row-headers` is true the first
// cell of every body row becomes a `<th scope="row">`.
#let data-table(
  columns: auto,
  header: none,
  rows: (),
  caption: none,
  row-headers: false,
  // Column alignment, passed through to `table()` on the paged target. Named
  // `column-align` so it doesn't shadow the built-in `align` function.
  column-align: left,
  region-label: none,
) = {
  let header-rows = if header == none { () } else if type(header.first()) == array { header } else { (header,) }
  let width = if columns != auto { columns } else if header-rows.len() > 0 {
    header-rows.first().len()
  } else if rows.len() > 0 { rows.first().len() } else { 1 }

  context if target() == "html" {
    // The scroll wrapper is focusable so a keyboard user can pan a wide
    // schedule without a pointing device. It only claims `role="region"` when
    // there is a real name to give it — an unnamed region is worse than none.
    let attrs = (class: "table-scroll", tabindex: "0")
    let name = if region-label != none { region-label } else if type(caption) == str { caption }
    // In reader mode every route is a section of one document, so captions that
    // are unique per page collide: two assignments each carrying a "Rubric"
    // produce two landmarks with the same name, and the landmark list stops
    // being a way to navigate. Qualify the name with the section it belongs to.
    // A caption that already names its section ("Course schedule" on the
    // Schedule page) is left alone rather than doubled.
    let cfg = config.config()
    if name != none and cfg.single and type(cfg.title) == str and lower(cfg.title) not in lower(name) {
      name = name + " — " + cfg.title
    }
    if name != none {
      attrs.insert("role", "region")
      attrs.insert("aria-label", name)
    }
    html.elem(
      "div",
      attrs: attrs,
      html.table({
        if caption != none { html.caption(caption) }
        if header-rows.len() > 0 {
          html.thead(for row in header-rows {
            html.tr(for c in row { html-cell(c, default-scope: "col") })
          })
        }
        html.tbody(for row in rows {
          html.tr(for (i, c) in row.enumerate() {
            html-cell(c, default-scope: if row-headers and i == 0 { "row" })
          })
        })
      }),
    )
  } else {
    let body = table(
      columns: width,
      align: column-align,
      ..for row in header-rows { (table.header(..row.map(c => paged-cell(c, header: true))),) },
      ..rows
        .map(row => row.enumerate().map(((i, c)) => paged-cell(c, header: row-headers and i == 0)))
        .flatten(),
    )
    if caption == none { body } else {
      // Above the table and flush left, matching where `<caption>` renders in
      // the HTML.
      show figure: set align(left)
      set figure.caption(position: top)
      show figure.caption: set text(fill: colors.ink, weight: 600, size: 1em)
      figure(body, caption: caption, kind: table, supplement: none, numbering: none)
    }
  }
}
