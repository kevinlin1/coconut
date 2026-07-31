// Lowercase, collapse runs of non-alphanumeric characters to a single
// hyphen, and trim leading/trailing hyphens. Used to turn a page title into
// a filesystem- and URL-safe permalink when no explicit path is given.
#let slugify(title) = lower(title).replace(regex("[^a-z0-9]+"), "-").trim("-")
