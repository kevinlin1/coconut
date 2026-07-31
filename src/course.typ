// The course description: one dictionary, given once to `bundle()`, read by
// every page's header and footer and by `course-header()` on the syllabus.
//
// Everything is optional, but `code` and `term` are what identify a printed
// handout that has been separated from its stack, and `url` is what lets a PDF
// point back at the live page instead of at a sibling file that may not have
// travelled with it.
#let course(
  // "CSE 190A" — the short identifier used in running headers.
  code: none,
  // "Foundations of Computing" — the human-readable name.
  name: none,
  // "Autumn 2026".
  term: none,
  // "4 credits", "3 units".
  credits: none,
  // When and where the class meets, as content: [Mon/Wed/Fri, 10:30–11:20 a.m.]
  meets: none,
  location: none,
  // "In person", "Hybrid", "Online, synchronous" — students need this before
  // they need anything else on the page.
  modality: none,
  prerequisites: none,
  // Public URL of the course site, without a trailing file name.
  url: none,
  // Content: how to reach the course as a whole (forum, email alias).
  contact: none,
  // Displayed in the footer of every page. Course materials get edited all
  // term; a student looking at a printout deserves to know how old it is.
  updated: none,
  ..extra,
) = {
  let fields = (
    code: code,
    name: name,
    term: term,
    credits: credits,
    meets: meets,
    location: location,
    modality: modality,
    prerequisites: prerequisites,
    url: url,
    contact: contact,
    updated: updated,
  )
  // Unset fields are dropped rather than stored as `none`, so components can
  // test for presence with a plain `at(key, default: none)`.
  let present = (:)
  for (key, value) in fields {
    if value != none { present.insert(key, value) }
  }
  // `website` is derived so the syllabus can show the URL as a real link
  // without every caller writing the same `link()` call.
  let derived = if url != none { (website: link(url, url)) } else { (:) }
  present + derived + extra.named()
}
