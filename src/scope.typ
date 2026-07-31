// Introspection in a bundle is *global*: `state.final()`, `counter.final()`,
// and a bare `query()` see every document in the bundle at once, not just the
// one being rendered. That makes the usual "count the things on this page"
// idiom silently wrong — a problem-set page would report the point total of
// every problem set in the site.
//
// The fix is to bracket each document's body with marker labels (`page()` in
// `document.typ` does this) and bound queries to the pair of markers
// surrounding the current location.

#let start-marker = label("coconut:page-start")
#let end-marker = label("coconut:page-end")

// Content to emit at the very beginning / end of a document body.
#let mark-start = [#metadata(none)#start-marker]
#let mark-end = [#metadata(none)#end-marker]

// `query()`, restricted to the document currently being rendered. Must be
// called from inside a `context` block (it needs `here()`).
#let page-query(target) = {
  let before = query(selector(start-marker).before(here(), inclusive: true))
  let after = query(selector(end-marker).after(here(), inclusive: true))
  if before.len() == 0 or after.len() == 0 {
    // Called outside a `page()` — fall back to the whole bundle rather than
    // failing, so components still work in a bare `document()`.
    return query(target)
  }
  query(target.after(before.last().location()).before(after.first().location()))
}

// Sum of the values of all `metadata` carrying `key` on this page. Used for
// point totals, which have to be known in the header before the problems that
// contribute to them have been rendered.
#let page-total(key) = page-query(selector(key)).map(m => m.value).sum(default: 0)

// Number of pages in the current PDF document. `counter(page).final()` would
// report the length of the *last* document in the bundle, so read the counter
// at this document's end marker instead.
#let page-count() = {
  let after = query(selector(end-marker).after(here(), inclusive: true))
  if after.len() == 0 { counter(page).final().first() } else {
    counter(page).at(after.first().location()).first()
  }
}
