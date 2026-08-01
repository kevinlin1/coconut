#import "@preview/coconut:0.1.0": *

// The term, week by week, and every deadline in it. `due()` links a deadline to
// the page that describes it, so the schedule row and the assignment cannot
// name different dates.

#let schedule = (
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
)
