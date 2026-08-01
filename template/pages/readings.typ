#import "@preview/coconut:0.1.0": *

// Readings, recordings, code, glossary, and the campus resources that belong
// somewhere other than the syllabus.

#let readings = (
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
)
