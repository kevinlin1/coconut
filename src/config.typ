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
  // Whether a large-print PDF is emitted beside the standard one. Read by the
  // format switcher, which offers it for download, so — like `formats` — it can
  // never advertise a file the build didn't write.
  large-print: true,
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

// The large-print edition of a page is a second file beside the standard PDF,
// under the same name with this suffix: `problem-set-1-large-print.pdf`. One
// definition, because the file the bundle writes and the link the website
// offers have to agree, and because a student given one file name should be
// able to guess the other.
#let large-print-suffix = "-large-print"
#let large-print-name = "large print"

// Whether this compile was asked for the large-print edition, with
// `--input large-print=true` on the command line.
//
// Bundle export writes both editions side by side and never consults this: it
// emits as many documents as it likes, so nothing has to choose. A
// single-document build (`--format pdf`, the course reader) writes exactly one
// PDF and therefore has to be told which one it is — hence a command-line
// input rather than a document-level setting.
#let large-print-input() = {
  let value = sys.inputs.at("large-print", default: "false")
  lower(value) in ("true", "1", "yes", "on")
}
