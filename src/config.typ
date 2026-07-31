// Per-document configuration: the course description, site navigation, and
// flags like `solutions` that components deep in the tree need to read.
//
// `page()` writes this state at the top of every document body, so each
// document in the bundle starts from a known value even though state is
// otherwise shared across the whole bundle. Reading it requires `context`.
#let store = state("coconut:config", (:))

#let defaults = (
  // Title of the page currently being rendered. Read by the running header, so
  // it names the section rather than the whole document in reader mode.
  title: none,
  // Course identity, shown in headers/footers and by `course-header()`.
  // See `course()` in `lib.typ` for the full set of recognized keys.
  course: (:),
  // Site navigation: array of `(label: .., path: ..)`, see `components/nav.typ`.
  nav: (),
  // Path of the current document, without extension. Used to mark the current
  // item in the navigation and to link to the PDF twin.
  path: none,
  // Whether solutions, answer keys, and grading notes are included. The
  // instructor build sets this; the student build leaves it false.
  solutions: false,
  // Formats this page is being emitted in, so the HTML rendering can offer a
  // download link only when the PDF twin actually exists.
  formats: ("html", "pdf"),
  // Paged layout preset: "page", "assignment", "exam", or "handout".
  kind: "page",
  // Paged font overrides, merged over `theme.default-fonts`.
  fonts: (:),
  // BCP 47 language tag for the document.
  lang: "en",
  // True when this page is one section of a single-document build rather than
  // a document of its own. Page numbering runs through, and per-page furniture
  // (navigation, format switcher) is dropped.
  single: false,
)

#let init(..fields) = store.update(defaults + fields.named())

// The whole configuration dictionary. Call inside `context`.
#let config() = defaults + store.get()

// The course dictionary, with a field's default filled in.
#let course-field(key, default: none) = config().course.at(key, default: default)

// Whether this build includes solutions. Call inside `context`.
#let showing-solutions() = config().solutions
