# Porting a course into this template

This directory is a course site: one Typst source that builds a website, a
printable PDF of every page, a large-print PDF beside it, and a single-document
course reader. `main.typ` lists the routes; each file under `pages/` defines
one; `course.typ`, `staff.typ`, and `meetings.typ` hold the data more than one
page draws on. The components come from `@preview/coconut` — see the package
README for the full list and for why each one is shaped the way it is.

Your job, most of the time, is **porting**: an instructor arrives with a course
that already exists somewhere else — a Word syllabus, last year's PDF, a Canvas
shell, a LaTeX problem set, a shared spreadsheet of due dates, a folder of slide
decks, a page of HTML a department webmaster wrote in 2014 — and wants it here.

That job has three obligations, and the third is the one that gets skipped:

1. **Accuracy.** Everything you carry over must say what the source said. A
   deadline you got wrong is worse than a deadline you left out.
2. **Accessibility.** Material that was inaccessible in the source does not
   become accessible by being retyped into Typst. Most of the work is
   re-expressing structure the source only implied.
3. **The handoff.** Some gaps you cannot close — you cannot see inside a scanned
   PDF, caption someone else's video, or decide the instructor's late policy.
   Those go back to the instructor as specific questions, together with the
   larger ones about the course that porting a syllabus tends to surface. See
   [The report you owe the instructor](#the-report-you-owe-the-instructor).

## Start by reading everything, then map it

Read every source before you write a line. Course material contradicts itself
constantly — the syllabus PDF says four late days, the Canvas page says three,
the first-day slides say "ask me" — and you can only see that from above.

Then map source to destination. Roughly:

| In the source | Goes to | As |
| --- | --- | --- |
| Course title, code, term, room, meeting time | `course.typ` | `course(..)` |
| "Instructor / TA / office hours" block | `staff.typ` | `person(..)` |
| Lecture, section, and office-hour times | `meetings.typ` | `meeting(..)` |
| Course description, objectives, grade weights | `pages/syllabus.typ` | `course-header`, `learning-objectives`, `grade-breakdown`, `grading-scale`, `key-dates` |
| Policy paragraphs | `pages/syllabus.typ` | `policy-sections(drafts, ..)`, or `policy(..)` for the instructor's own text |
| Week-by-week table, deadline list | `pages/schedule.typ` | `course-schedule`, `deadline-list`, `due` |
| A problem set, lab, or essay prompt | one file per assignment under `pages/` | `assignment-header`, `problem`, `parts`, `rubric-matrix`, `submission-checklist` |
| An exam | one file under `pages/` | `exam-cover`, `multiple-choice`, `true-false`, `answer-space` |
| Reading list, links, glossary, campus resources | `pages/readings.typ` | `reading-list`, `materials-index`, `media-link`, `file-link`, `glossary`, `resource-table` |

Then add each new route to the array in `main.typ`. That array is the site: it
sets the navigation order and the reader order, and a page not named there is
not built.

Keep one thing in one place. Office hours belong in `meetings.typ` and are
rendered by `pages/weekly.typ`; retyping them onto the staff page as prose
creates two facts that will disagree by week three. The same goes for a due date
that appears in the schedule, in the deadline list, and at the top of the
assignment — write it once and let `due(url: ..)` link the row to the page.

## Accuracy: what you may not do

**Do not invent.** Not a date, not a point value, not a room number, not an
office hour, not an email address, not a URL, not a policy sentence, not a
learning objective. If the source does not say, you do not know.

**Leave gaps visible, not silent.** The policy drafts render unfilled values as
italic bracketed text so an unanswered question shows up on the page rather than
disappearing. Do the same with anything you could not resolve:

```typst
location: [#emph[[ask: which room? the PDF says Kane 210, Canvas says Kane 220]]],
```

A visible placeholder is a question the instructor answers when they read the
page. A plausible guess is one they never see. Never delete a fact you cannot
verify — a missing office hour reads as "there are none."

**Report contradictions rather than resolving them.** Where two sources
disagree, put the placeholder in, and put the conflict in your report with both
readings and where each came from. Newer is not automatically right.

**Copy legally weighted text verbatim.** Academic integrity, Title IX,
accommodations, and anything the institution mandates: carry the wording across
exactly, and say in your report that you did. Do not paraphrase for tone, do not
"improve" it, and do not swap in a `policy-drafts` version when the instructor
already has required language — the drafts exist for the topics a syllabus is
missing, not to overwrite what a university requires.

**Placeholder data in this template is not the instructor's data.** INFO 220,
Dr. Okonkwo, `example.edu`, and the 1951–1980 baseline are examples. When you
port a real course, every one of them should be gone. Grep for `example.edu`
before you hand back.

**Answer keys are unlisted, not private.** `in-nav: false` keeps a route out of
the navigation; publishing the site still publishes the URL. Keep a key out of
`main.typ` until the deadline passes, or give it `formats: ("pdf",)` so it never
becomes a web page at all.

## Accessibility: where ported content changes shape

The components carry the mechanical half — one `<h1>` per page, a `<main>`
landmark, tagged PDFs, AAA contrast, a large-print edition of every PDF. What
they cannot do is recover structure that the source threw away. That is the
porting work, and it is most of the work.

**Headings, not bold text.** A Word syllabus marks a section by making a line
16-point bold. Convert it to a real heading (`=`, `==`) — body headings start at
`<h2>` under the page title automatically, so a top-level `=` inside a page body
is correct. Do not skip levels to get a size you like, and never use `strong()`
where a heading belongs. Getting this wrong is invisible on the web page and
shows up as a flat PDF outline.

**Real tables, and only for data.** Schedules, grade breakdowns, and rubrics
become `data-table()` (or the component that wraps it) with a caption and header
row, so each cell is announced with its coordinates. Two things to watch for in
sources: a table used purely for layout — two columns to sit a photo beside a
paragraph — which should become ordinary blocks, not a table; and a schedule
that arrived as a *screenshot* of a table, which must be retyped as a table.
Text baked into an image is unreachable no matter how good its alt text is.

**Alt text you can actually write.** `figure-image()` fails the build when `alt`
is missing or is not a description — a filename, "chart", "image of…", or the
caption repeated. The rules are in the package README under *What counts as alt
text*; the failure message names the rule and the fix.

The rule that matters more here is the one no compiler enforces: **if you cannot
see what an image shows, you cannot describe it.** A diagram lifted from a slide
deck, a photo from a department page, a plot from a PDF — if you have not
actually examined it, do not write alt text for it. Writing something plausible
produces a description that passes every check and misinforms a reader, which is
worse than the build error. Put the image in with a placeholder that fails
loudly, or leave it out and list it in your report. Ask the instructor what it
shows; they know, and it takes them one sentence.

Use `alt` for what the image *is* — enough to decide whether to open it — and
`description:` for what it *shows*, which renders as a disclosure widget that
prints. A genuinely decorative image gets `decorative()` and no description at
all. Staff photos take `person(photo: .., photo-alt: ..)` and go through the
same check; a photo has to earn its place, and "Dr. Okonkwo" is not a
description of one.

**Link text that survives being read alone.** Sources are full of "click here",
"this link", and bare URLs. Screen reader users navigate by pulling up the list
of links on a page, where "here" appears six times. Write the destination into
the text. Use `file-link()` for downloads so the format and size are stated
before the click, `media-link()` for recordings, and `page-link("Schedule")` for
another page of this site — it resolves to a sibling `.html` on the web and to
the live site from inside a PDF.

**Never color alone.** Highlighter yellow on a syllabus, red text for "no class
this week", a legend that says green means optional: all of it disappears in
print, in greyscale, and to a screen reader. Carry the meaning as a word.
`course-schedule` rows take `kind: "break" | "exam" | "milestone"` and print the
label; a warning becomes `warning()` or `deadline()`, which say so in text.

**Positional language breaks on reflow.** "The box at right", "see page 3",
"the table below" — the web page has no pages and may not have a right. Refer to
things by name: "the grading scale in the syllabus", `page-link("Readings")`.

**Math needs a spoken form.** Typst emits MathML on the web, but a PDF gets a
flat string and nothing else, so `eq("beta equals 0.0086", $beta = 0.0086$)` is
not belt-and-braces — the alt is the only thing a PDF reader hears. Write it the
way you would say it out loud in class. When porting LaTeX, the source often
already contains a spoken form in the surrounding prose; use it. Anything that
is really a diagram in disguise — a commutative diagram, a labelled derivation —
is better as `figure-image()` with a real description.

**Media has to declare itself.** `media-link()` states duration and whether
captions exist, and takes a `transcript`. Set `captions: false` when there are
none rather than leaving the default `true` — it is the difference between a
student learning that now and learning it at 11 p.m. before the exam. An
uncaptioned recording is a gap for the report, not something to paper over.

**Readings carry their access story.** `reading(format: .., access: ..)` is
where a student finds out that something is a library e-reserve requiring
sign-in, or that a PDF is a scan. If a source reading is a scanned image with no
text layer, say so in `notes:` and flag it — it is unreadable by screen reader,
unsearchable, and unusable at high zoom.

**Do not lose information across formats.** `hint()` is a disclosure on the web
and prints open; `answer-space()` is ruled space in the PDF and a note on the
web; `solution()` is omitted entirely unless `solutions: true`. Use them rather
than inventing a "print version" of a page — two versions of one handout is
exactly the drift this package exists to prevent.

**Do not weaken the checks to make a build pass.** Do not turn off
`large-print`, do not drop `--pdf-standard ua-1`, do not route around the alt
check with a bare `image()`, and do not pad alt text to eight characters to get
past the length rule. A check people learn to work around is worse than no
check. If a rule seems wrong for a real case, say so in the report and let the
instructor decide.

## Verify before you hand anything back

From a course site built on the published package:

```sh
typst compile main.typ --features bundle,html --format bundle --pdf-standard ua-1 site
```

Working inside the `coconut` repository itself, the template builds against the
working tree and the full gate is available:

```sh
npm run check   # build all three shapes, then axe, the alt-text rules, and their tests
```

A green build is a floor, not a pass. It means the PDFs satisfy PDF/UA, no image
lacks a description, and no page trips axe. It cannot tell you that a
description is *accurate*, that a heading level matches the meaning, or that the
schedule row and the assignment page name the same date. Re-read what you ported
against the source before you say it is done.

## The report you owe the instructor

End every porting session with a short written report — in the conversation, not
buried in a file. Four parts:

1. **What was ported, and where it lives.** One line per source.
2. **What you could not verify.** Every `#emph[[ask: ..]]` placeholder you left,
   and every contradiction between sources, with both readings.
3. **Accessibility gaps you could not close.** Be specific and name the file:
   images you could not describe, recordings without captions or transcripts,
   scanned readings with no text layer, content hosted somewhere you cannot fix
   (a Canvas quiz, a publisher's homework platform, a video on a departmental
   site), anything that arrived as text inside an image.
4. **Questions.** Few, concrete, and answerable in a sentence each. Three good
   questions get answered; fifteen get skimmed.

Frame gaps as work, not as a verdict on the instructor. "Two lecture recordings
have no transcript; the syllabus promises transcripts within two business days"
is useful. A lecture on why captions matter is not, and it is usually addressed
to someone who already agrees.

## Beyond the website: what to ask about the course

A syllabus is a description of a course, and porting one puts you in front of
every assumption it makes about how students can attend, sit, read, type,
speak, remember, and afford. Fixing the HTML does not touch any of that. Raise
these where the source gives you a reason to — a policy you just typed, a
deadline structure you just built a table of — and put them in the report as
questions for the instructor, at most a handful at a time.

**Assessment.** Is a timed exam measuring the thing the course teaches, or is it
measuring speed? Where speed is not the point, more time for everyone costs less
than an accommodations process does. Is one midterm carrying 20% of the grade,
and what happens to a student who is ill that morning? Is there more than one
way to demonstrate the same learning — a paper or a presentation, an oral or a
written defense? `exam-cover()` ships an accommodations note; it should say what
this instructor will actually do, not the default.

**Participation and attendance.** If participation means speaking in class, it
grades extroversion and fluent speech alongside understanding. Ask what else
counts — forum posts, section contributions, written responses, office hours.
And whether attendance is graded, which quietly requires students to disclose
illness, disability, caregiving, or work to a professor to protect their grade.

**Flexibility that nobody has to ask for.** Late days a student spends without
explaining themselves, one dropped problem set, a resubmission window: each one
removes a conversation that costs the student a disclosure and the instructor an
email. The `late` policy draft takes a `late-days` count — the number is a
course design decision, not a formatting one. Ask what the extension process
actually is, and whether it requires documentation the student would have to
obtain.

**Predictability.** Every deadline published before week one; assignments that
appear when the schedule says they will; slides posted before class rather than
after. A student who plans their week around energy, transport, medication, or a
carer's schedule needs the calendar to be true in advance. This is also the
cheapest thing on the list — the schedule page is already built.

**The room and the meetings.** Is the room step-free, and is the instructor's
position at the front reachable? Do the seats work for a larger body, a
wheelchair, a service animal, a left-handed writer? Is a microphone used even
when the room "doesn't need one" — it does, for hearing aids and induction
loops. Are sightlines to the board and to the interpreter or captioner clear?
For labs, studios, and fieldwork: what does the course assume about standing,
lifting, dexterity, transport, or being outdoors for three hours, and what is
the alternative route through that requirement?

**How the class is run.** Reading slides aloud, describing what is on the board,
saying the equation as well as writing it, repeating a question before answering
it, captioning any video shown in class, not making a color-coded graph the only
carrier of a result: these are teaching habits, not document properties, and no
build step reaches them.

**Group work.** How teams get formed decides who ends up unpicked. How they meet
decides who can participate — a team that meets at 8 p.m. on campus has excluded
the commuter and the parent before the first meeting. Is there a stated route
for a student who cannot make in-person group work?

**Office hours.** One two-hour block a week is one two-hour block a student's
class, job, or clinic appointment can overlap. Is there a second time, an online
option, an appointment slot? Does the syllabus say students may come without a
prepared question — many will not otherwise.

**Cost and technology.** Are all required readings free or library-available?
Does the course require a laptop, a phone with a specific app, reliable home
internet, a camera on during class, or proctoring software — and what happens to
a student for whom any of those is not true? Proctoring software in particular
flags people for moving, looking away, or having a face it was not trained on.

**Belonging.** Names in use rather than roster names; pronouns offered rather
than assumed; staff bios that say office hours are for anyone; a first day that
tells students what to do when the course is not working for them. The
accessibility policy draft already says a barrier in the materials is a bug to
report, not a favor to request. That sentence is only true if the instructor
means it.

Two rules about all of this. **You are asking, not deciding** — course design
belongs to the instructor, and a suggestion delivered as a correction gets
ignored on the merits. And **you may not write a commitment they have not
made**: never put "recordings are captioned within 48 hours", "extensions are
always granted", or a late policy the instructor has not agreed to into a page,
even as a placeholder that looks like prose. A promise on a syllabus is one a
student will rely on. Use `#emph[[ask: ..]]`, and wait for the answer.

Then write the answers back into the files. A recommendation the instructor
accepted in conversation and nobody typed up is a recommendation that did not
happen.
