#import "@preview/coconut:0.1.0": *

// A complete, if small, course site: syllabus, staff, term schedule, weekly
// meetings, a problem set with its answer key, a midterm with its key, and a
// readings page. Every page below is emitted as both HTML and PDF from this one
// file — the problem set and its solutions share a body variable, so the key
// cannot describe a problem that no longer exists.

#let this-course = course(
  code: "INFO 220",
  name: "Climate Data and Society",
  term: "Autumn 2026",
  credits: "5 credits",
  meets: [Monday, Wednesday, Friday, 10:30--11:20 a.m.],
  location: [Kane Hall 210],
  modality: [In person, with all materials online],
  prerequisites: [One course in statistics, or permission of the instructor],
  url: "https://example.edu/info220",
  contact: [Course forum (preferred) or #link("mailto:info220@example.edu")[info220\@example.edu]],
  updated: [July 31, 2026],
)

#let drafts = policy-drafts(
  institution: "Example University",
  accessibility-office: "Disability Resources for Students",
  accessibility-contact: link("mailto:drs@example.edu")[drs\@example.edu],
  integrity-policy: link("https://example.edu/integrity")[the university integrity policy],
  counseling: link("https://example.edu/counseling")[Counseling Center],
  basic-needs: link("https://example.edu/basic-needs")[the Husky Pantry and Basic Needs Center],
  title-ix: "the Title IX office",
  instructor-email: link("mailto:okonkwo@example.edu")[okonkwo\@example.edu],
  late-days: 4,
  ai: "limited",
)

// --- Course staff -----------------------------------------------------------

#let staff = (
  person(
    [Dr. Amara Okonkwo],
    role: [Instructor],
    pronouns: [she/her],
    email: "okonkwo@example.edu",
    hours: [Tuesdays 2:00--4:00 p.m., and by appointment],
    location: [Mary Gates 312],
    bio: [I study how communities use environmental monitoring data to argue for
      policy change. Come talk to me about the course, about research, or about
      whether this field is for you.],
  ),
  person(
    [Priya Raman],
    role: [Teaching assistant, sections AA and AB],
    pronouns: [she/her],
    email: "praman@example.edu",
    hours: [Thursdays 1:00--3:00 p.m.],
    location: [Odegaard Library, ground floor],
    bio: [Second-year masters student. I grade problem sets and run section, and
      I am the person to ask about regrade requests.],
  ),
  person(
    [Diego Salazar],
    role: [Teaching assistant, section AC],
    pronouns: [he/him],
    email: "dsalazar@example.edu",
    hours: [Wednesdays 3:00--5:00 p.m.],
    location: [Online, link on the course forum],
    bio: [I focus on the data-analysis side of the course. My office hours are
      online, so bring your laptop and your error messages.],
  ),
)

// --- Recurring meetings -----------------------------------------------------

#let meetings = (
  meeting(
    [Lecture],
    days: ("Mon", "Wed", "Fri"),
    start: "10:30am",
    end: "11:20am",
    location: [Kane 210],
    kind: "lecture",
  ),
  meeting(
    [Section AA],
    days: "Thu",
    start: "12:30pm",
    end: "1:20pm",
    location: [Savery 131],
    staff: [Priya Raman],
    kind: "section",
  ),
  meeting(
    [Section AB],
    days: "Thu",
    start: "1:30pm",
    end: "2:20pm",
    location: [Savery 131],
    staff: [Priya Raman],
    kind: "section",
  ),
  meeting(
    [Section AC],
    days: "Fri",
    start: "1:30pm",
    end: "2:20pm",
    location: [Savery 137],
    staff: [Diego Salazar],
    kind: "section",
  ),
  meeting(
    [Office hours],
    days: "Tue",
    start: "2:00pm",
    end: "4:00pm",
    location: [Mary Gates 312],
    staff: [Dr. Okonkwo],
    kind: "office-hours",
  ),
  meeting(
    [Office hours],
    days: "Wed",
    start: "3:00pm",
    end: "5:00pm",
    location: [Online],
    staff: [Diego Salazar],
    kind: "office-hours",
    note: [Link on the course forum],
  ),
  meeting(
    [Office hours],
    days: "Thu",
    start: "1:00pm",
    end: "3:00pm",
    location: [Odegaard, ground floor],
    staff: [Priya Raman],
    kind: "office-hours",
  ),
)

// --- Problem set 1 ----------------------------------------------------------
//
// One body, two pages: the student handout and the answer key. `solution()` and
// `grading-note()` only render in the build that sets `solutions: true`.

#let pset1 = [
  #assignment-header(
    due: [Friday, October 9, 11:59 p.m.],
    submit: [As a single PDF on the course site],
    collaboration: [Discuss freely; write up alone, and name everyone you
      worked with at the top of your submission.],
    estimate: [4--6 hours],
    weight: [5% of the course grade],
  )

  This problem set covers the first two weeks: reading a temperature record,
  quantifying a trend, and saying honestly what the number does and does not
  show.

  #problem(title: [Reading the record], points: 10, tags: ("data literacy",))[
    The table below gives the annual mean surface temperature anomaly, in
    degrees Celsius relative to the 1951--1980 baseline, for six years.

    #data-table(
      columns: 2,
      caption: "Annual mean temperature anomaly",
      row-headers: true,
      header: ([Year], [Anomaly (°C)]),
      rows: (
        ([1980], [0.26]), ([1990], [0.45]), ([2000], [0.42]),
        ([2010], [0.72]), ([2020], [1.02]), ([2024], [1.28]),
      ),
    )

    #parts(
      part(points: 4)[Compute the mean anomaly for the six years shown. Show
        your arithmetic.],
      part(points: 6)[The 2000 value is lower than the 1990 value. Explain in
        two or three sentences why this does not, on its own, contradict a
        warming trend.],
    )

    #hint[Think about what a single year's value includes besides the long-term
      trend: El Niño and La Niña cycles, volcanic aerosols, and measurement
      noise all move an individual year up or down.]

    #solution[
      #parts(
        part[The mean is #eq(
          "the sum of 0.26, 0.45, 0.42, 0.72, 1.02 and 1.28, divided by 6, equals 4.15 over 6, approximately 0.69",
          $(0.26 + 0.45 + 0.42 + 0.72 + 1.02 + 1.28) / 6 = 4.15 / 6 approx 0.69$,
        )°C.],
        part[A trend is a statement about the central tendency of a series, not
          about every consecutive pair in it. Interannual variability — El Niño
          and La Niña in particular — is large enough to swamp a decade of trend
          in any single year, so year-to-year decreases are expected even while
          the trend is upward.],
      )
    ]

    #grading-note[Full credit on (b) requires naming a specific source of
      interannual variability *and* distinguishing a trend from a pairwise
      comparison. Award 3 of 6 for one without the other.]
  ]

  #problem(title: [Estimating a rate], points: 15, tags: ("modeling", "units"))[
    A linear fit to the full 1880--2024 record gives a slope of
    #eq("beta equals 0.0086", $beta = 0.0086$)°C per year, with a standard error
    of #eq("0.0004", $0.0004$)°C per year.

    #parts(
      part(points: 5)[Express the trend in degrees Celsius per decade, with
        units.],
      part(points: 5)[Give an approximate 95% confidence interval for the
        per-decade trend.],
      part(points: 5)[A classmate writes: "the model predicts 3.4°C of warming
        by 2424." State the strongest objection you can to that sentence.],
    )

    #answer-space(lines: 6)

    #solution[
      #parts(
        part[#eq("0.0086 times 10 equals 0.086", $0.0086 times 10 = 0.086$)°C per decade.],
        part[The standard error per decade is #eq("0.004", $0.004$)°C, so the
          interval is roughly #eq(
            "0.086 plus or minus 2 times 0.004, giving the interval 0.078 to 0.094",
            $0.086 plus.minus 2 times 0.004 = [0.078, 0.094]$,
          )°C per decade.],
        part[Extrapolating a linear fit four centuries past the data assumes the
          physical system stays linear over a range where it demonstrably does
          not; the confidence interval describes uncertainty in the fit, not the
          validity of extending the model.],
      )
    ]
  ]

  #problem(title: [Whose data?], points: 15, tags: ("ethics", "writing"))[
    Choose one of the monitoring programs discussed in week 2. In roughly 400
    words, describe who collects the data, who pays for it, who can access it,
    and one group that is affected by it but has no say in how it is collected.

    #rubric-matrix(
      (
        (
          criterion: [Accuracy of description],
          levels: (
            "Exemplary": [Specific and correct about funding, access, and governance],
            "Proficient": [Broadly correct with minor gaps],
            "Developing": [Significant factual errors, or too vague to check],
          ),
        ),
        (
          criterion: [Analysis of power],
          levels: (
            "Exemplary": [Identifies a concrete affected group and explains the mechanism of exclusion],
            "Proficient": [Identifies a group; mechanism is asserted rather than shown],
            "Developing": [Restates that data collection has consequences],
          ),
        ),
        (
          criterion: [Use of evidence],
          levels: (
            "Exemplary": [Cites course readings and at least one outside source],
            "Proficient": [Cites course readings],
            "Developing": [No citations],
          ),
        ),
      ),
      ("Exemplary", "Proficient", "Developing"),
    )
  ]

  #submission-checklist((
    [One PDF, with your name on the first page],
    [Collaborators named at the top],
    [Units on every numeric answer],
    [Word count for problem 3],
  ))
]

// --- Midterm ----------------------------------------------------------------

#let midterm = [
  #exam-cover(
    duration: [50 minutes],
    materials: [One double-sided page of handwritten notes. No calculators,
      phones, or laptops.],
    instructions: (
      [Write your name on every page — pages are separated for grading.],
      [Show your work. An unexplained correct answer earns partial credit at best.],
      [If a question seems ambiguous, write down the interpretation you chose and answer it.],
      [Budget roughly one minute per point.],
    ),
  )

  #problem(title: [Definitions], points: 8)[
    Which of the following defines a temperature #emph[anomaly]?

    #multiple-choice(
      (
        [The difference between a year's temperature and a fixed baseline average],
        [The highest temperature recorded in a year],
        [The difference between two adjacent years],
        [A model's predicted temperature for a year],
      ),
      answer: 1,
    )
  ]

  #problem(title: [True or false], points: 6)[
    #true-false([A statistically significant trend in a temperature record
      implies the trend was caused by greenhouse gases.], answer: false)
    #true-false([Averaging over more years reduces the influence of interannual
      variability on the estimated trend.], answer: true)
  ]

  #problem(title: [Short answer], points: 16, new-page: true)[
    A city publishes a dashboard showing air quality at four sensors. Residents
    of one neighborhood say the dashboard reports clean air on days when they
    can see and smell smoke.

    Give two specific, technically plausible explanations for the discrepancy,
    and for each, describe one change to the monitoring program that would test
    it. The blank is worth #blank(answer: [4], width: 1.5cm) points per
    explanation and #blank(answer: [4], width: 1.5cm) points per test.

    #answer-space(lines: 8)

    #solution[
      Any two of: sensor siting (all four sensors are upwind or elevated, so
      test by deploying a sensor at street level in the affected neighborhood);
      temporal averaging (a 24-hour mean hides a three-hour spike, so test by
      publishing hourly values); pollutant coverage (the dashboard reports
      PM2.5 but not the pollutant responsible for the smell, so test by adding
      speciated monitoring); calibration drift (test by co-locating a reference
      instrument).
    ]
  ]

  #end-of-exam()
]

// --- The site ---------------------------------------------------------------

#bundle(
  course: this-course,
  // Only used by the single-document editions (`--format pdf` / `--format html`).
  title: "INFO 220: Complete Course Reader",
  (
  (
    title: "Syllabus",
    path: "index",
    nav-label: "Home",
    description: "INFO 220: Climate Data and Society — syllabus for Autumn 2026.",
    body: [
      #course-header(description: [How do measurements of the atmosphere become
        arguments about policy? This course follows environmental data from the
        instrument that records it to the graph in a city council meeting, and
        asks what is gained and lost at every step.])

      #learning-objectives((
        [Read a published environmental dataset and describe how it was collected],
        [Estimate a trend from a time series and state its uncertainty honestly],
        [Explain what a statistical claim about climate does and does not establish],
        [Evaluate who benefits from, and who is excluded by, a monitoring program],
        [Communicate a quantitative finding to a non-technical audience],
      ))

      #note(title: [Everything here works in both formats])[
        Every page of this site is available as a web page and as a PDF, built
        from the same source. Use whichever suits you: the PDF for printing and
        annotating, the web page for screen readers, phones, and text resizing.
        If something on either version is unusable, email me — that is a bug.
      ]

      = How the course works

      Three lectures a week, one section, and a problem set every other week.
      Lecture introduces a method; section is where you practice it with a TA in
      the room; problem sets are where you find out whether you can do it alone.

      #grade-breakdown((
        (name: [Problem sets (5)], weight: 40, notes: [Lowest score dropped]),
        (name: [Midterm], weight: 20, notes: [In class, week 6]),
        (name: [Final project], weight: 30, notes: [Proposal, draft, and final report]),
        (name: [Section participation], weight: 10, notes: [Attendance and weekly exercise]),
      ))

      #grading-scale()

      = Key dates

      #key-dates(caption: "Dates and deadlines at a glance", (
        (date: [Friday, October 9], what: [Problem set 1 due], notes: [11:59 p.m.]),
        (date: [Wednesday, November 4], what: [Midterm], notes: [In class, 50 minutes]),
        (date: [Friday, November 13], what: [Final project proposal due], notes: []),
        (date: [Friday, December 11], what: [Final report due], notes: [No late days]),
      ))

      = Policies

      #policy-sections(drafts, (
        "accessibility",
        "late",
        "ai",
        "integrity",
        "community",
        "religious",
        "basic-needs",
        "communication",
      ))
    ],
  ),
  (
    title: "Staff",
    description: "Who teaches INFO 220, when their office hours are, and who to ask about what.",
    body: [
      Office hours are the single most under-used resource in this course. You do
      not need a specific question to come to them.

      #staff-directory(staff)

      = Who to ask about what

      #who-to-ask((
        (need: [An extension, or something going on in your life], contact: [Dr. Okonkwo]),
        (need: [A regrade on a problem set], contact: [Priya Raman, within one week of the grade]),
        (need: [Help with the data analysis tools], contact: [Diego Salazar's office hours]),
        (need: [A disability accommodation], contact: [Disability Resources for Students, then Dr. Okonkwo]),
        (need: [Anything the whole class would benefit from], contact: [The course forum]),
      ))
    ],
  ),
  (
    title: "Weekly Schedule",
    path: "weekly",
    description: "Lecture, section, and office hour times for INFO 220.",
    body: [
      These meetings happen every week of the term. One-time events — exams,
      deadlines, the field trip — are on the #page-link("Schedule") page.

      #weekly-schedule(meetings)

      = The same schedule as a list

      #weekly-list(meetings)

      = Office hours

      #office-hours(meetings)
    ],
  ),
  (
    title: "Schedule",
    description: "Week-by-week topics, readings, and deadlines for INFO 220.",
    body: [
      #course-schedule((
        (
          label: [Week 1],
          dates: [Sep 28 -- Oct 2],
          topic: [What is a temperature record?],
          prepare: [Syllabus; Hulme, ch. 1],
          due: [Section exercise 1],
        ),
        (
          label: [Week 2],
          dates: [Oct 5 -- 9],
          topic: [Instruments, baselines, and anomalies],
          prepare: [Hansen et al. (2010), sections 1--3],
          due: [#due([Problem set 1], at: [Fri 11:59 p.m.], url: "problem-set-1.html")],
        ),
        (
          label: [Week 3],
          dates: [Oct 12 -- 16],
          topic: [Trends and uncertainty],
          prepare: [Course notes on linear fits],
          due: [Section exercise 2],
        ),
        (
          label: [Week 4],
          dates: [Oct 19 -- 23],
          topic: [Who collects the data?],
          prepare: [Two readings on the #link("readings.html")[readings page]],
          due: [#due([Problem set 2], at: [Fri 11:59 p.m.])],
        ),
        (
          label: [Week 5],
          dates: [Oct 26 -- 30],
          topic: [Monitoring and environmental justice],
          prepare: [Community monitoring case study],
          due: [Project team formed],
        ),
        (
          label: [Week 6],
          dates: [Nov 2 -- 6],
          kind: "exam",
          topic: [Midterm on Wednesday; project workshop Friday],
          prepare: [Review weeks 1--5],
          due: [#due([Midterm], at: [Wed, in class], url: "midterm.html")],
        ),
        (
          label: [Week 7],
          dates: [Nov 9 -- 13],
          topic: [From dataset to argument],
          prepare: [Two readings on the readings page],
          due: [#due([Project proposal], at: [Fri 11:59 p.m.])],
        ),
        (
          label: [Nov 26 -- 27],
          kind: "break",
          note: [Thanksgiving holiday. No class, no section, and nothing due the
            Monday after — take the whole week.],
        ),
        (
          label: [Week 10],
          dates: [Dec 7 -- 11],
          kind: "milestone",
          topic: [Project presentations],
          prepare: [Your slides, uploaded by Sunday],
          due: [#due([Final report], at: [Fri 11:59 p.m.])],
        ),
      ))

      = Every deadline in one place

      #deadline-list((
        (at: [Fri Oct 9, 11:59 p.m.], what: [Problem set 1], submit: [Course site]),
        (at: [Fri Oct 23, 11:59 p.m.], what: [Problem set 2], submit: [Course site]),
        (at: [Wed Nov 4, in class], what: [Midterm], submit: [On paper]),
        (at: [Fri Nov 13, 11:59 p.m.], what: [Project proposal], submit: [Course site]),
        (at: [Fri Dec 11, 11:59 p.m.], what: [Final report], submit: [Course site, no late days]),
      ))
    ],
  ),
  (
    title: "Problem Set 1",
    path: "problem-set-1",
    kind: "assignment",
    description: "INFO 220 problem set 1: reading a temperature record and estimating a trend.",
    body: pset1,
  ),
  (
    // Same body, built with solutions on. Keep it out of the site navigation
    // and hand out the URL when you release the key.
    title: "Problem Set 1: Answer Key",
    path: "problem-set-1-key",
    kind: "assignment",
    solutions: true,
    in-nav: false,
    body: pset1,
  ),
  (
    title: "Midterm",
    kind: "exam",
    description: "INFO 220 midterm exam, Autumn 2026.",
    body: midterm,
  ),
  (
    title: "Midterm: Answer Key",
    path: "midterm-key",
    kind: "exam",
    solutions: true,
    in-nav: false,
    formats: ("pdf",),
    body: midterm,
  ),
  (
    title: "Readings",
    description: "Readings, class materials, and campus resources for INFO 220.",
    body: [
      Every required reading is available at no cost through the library or as
      an open-access copy. If a link fails, post on the forum rather than paying
      for anything.

      #reading-list(
        (
          reading(
            [Why We Disagree About Climate Change, ch. 1],
            author: [Mike Hulme],
            source: [Cambridge University Press, 2009],
            url: "https://example.edu/library/hulme-ch1",
            pages: "28 pages",
            format: "PDF",
            access: [Library e-reserve, sign in required],
          ),
          reading(
            [Global surface temperature change],
            author: [Hansen, Ruedy, Sato, and Lo],
            source: [Reviews of Geophysics, 2010],
            url: "https://example.edu/library/hansen-2010",
            pages: "29 pages",
            format: "PDF",
            access: [Open access],
            notes: [Read sections 1--3 closely; skim the rest.],
          ),
          reading(
            [Sensing Injustice: community air monitoring],
            author: [Gwen Ottinger],
            source: [Science, Technology & Human Values, 2017],
            url: "https://example.edu/library/ottinger-2017",
            required: false,
            format: "PDF",
            access: [Library e-reserve],
            notes: [Optional, but the best single entry point to the week 5 material.],
          ),
        ),
        title: [Required and optional readings],
      )

      = Class materials

      #materials-index((
        (
          date: [Mon Sep 28],
          topic: [Course overview],
          slides: link("https://example.edu/info220/01-slides.pdf")[Slides (PDF)],
          notes: link("https://example.edu/info220/01-notes.html")[Notes],
          recording: [—],
        ),
        (
          date: [Wed Sep 30],
          topic: [Instruments and baselines],
          slides: link("https://example.edu/info220/02-slides.pdf")[Slides (PDF)],
          notes: link("https://example.edu/info220/02-notes.html")[Notes],
          recording: link("https://example.edu/info220/02-recording")[Recording],
        ),
      ))

      #media-link(
        "https://example.edu/info220/02-recording",
        title: [Lecture 2: Instruments and baselines],
        kind: "lecture recording",
        duration: "48 minutes",
        captions: true,
        transcript: [Full transcripts are posted with each recording within two
          business days. If one is missing or wrong, tell me and I will fix it —
          the transcript is course material, not a bonus.],
      )

      = Working with the data

      #code-listing(
        caption: [Loading the temperature record],
        ```python
        import pandas as pd

        record = pd.read_csv("gistemp.csv", comment="#")
        annual = record.groupby("year")["anomaly"].mean()
        print(annual.loc[1980:2024].describe())
        ```,
      )

      = Glossary

      #glossary((
        ([anomaly], [The difference between a measurement and a fixed baseline
          average, rather than an absolute value.]),
        ([baseline], [The reference period an anomaly is measured against; in
          this course, 1951--1980 unless stated otherwise.]),
        ([interannual variability], [Year-to-year fluctuation caused by processes
          like El Niño, independent of any long-term trend.]),
      ))

      = Campus resources

      #resource-table((
        (
          name: [Disability Resources for Students],
          purpose: [Accommodations of any kind, temporary or permanent],
          access: link("mailto:drs@example.edu")[drs\@example.edu],
        ),
        (
          name: [Writing Center],
          purpose: [Feedback on project drafts at any stage],
          access: [Drop in, Odegaard 121],
        ),
        (
          name: [Statistics Tutoring],
          purpose: [Help with the quantitative parts of problem sets],
          access: [Mon--Thu evenings, Communications B027],
        ),
      ))
    ],
  ),
))
