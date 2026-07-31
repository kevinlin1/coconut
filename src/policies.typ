#import "components/syllabus.typ": policy

// Starter policy text.
//
// These are *drafts*, not boilerplate to paste unread: every institution has
// its own required language, its own office names, and its own procedures, and
// several of these topics (accommodations, Title IX, academic integrity) carry
// legal weight. They exist because the alternative faculty most often fall back
// on is copying last year's syllabus from a colleague, which is how a broken
// URL and a renamed office survive a decade.
//
// Placeholders render as bracketed text so anything left unfilled is obvious on
// the page rather than silently wrong.
#let fill(value, hint) = if value != none { value } else { text(style: "italic", "[" + hint + "]") }

#let policy-drafts(
  institution: none,
  accessibility-office: none,
  accessibility-contact: none,
  integrity-policy: none,
  counseling: none,
  basic-needs: none,
  title-ix: none,
  // How much slack the course gives on deadlines, and how students use it.
  late-days: 3,
  // "prohibited", "limited", or "encouraged" — the three stances most course
  // policies take on generative AI. Each produces different text.
  ai: "limited",
  instructor-email: none,
  response-time: [one business day],
) = {
  let school = fill(institution, "your institution")
  let drafts = (:)

  drafts.accessibility = (
    title: [Accessibility and accommodations],
    body: [
      I want this course to be usable by every student in it. Course materials are
      published in both HTML and PDF, and I will provide alternative formats on
      request.

      If you have a documented disability, contact
      #fill(accessibility-office, "your disability services office")
      (#fill(accessibility-contact, "contact information")) to arrange
      accommodations, and share your accommodation letter with me as early as you
      can so we have time to put it in place. You do not need a letter to talk to
      me: if some aspect of the course is getting in your way, tell me and we will
      work on it. If you find a barrier in the course materials themselves — an
      unreadable PDF, a video without captions, a diagram without a description —
      report it to me and I will treat it as a bug to fix, not a favor.
    ],
  )

  drafts.religious = (
    title: [Religious accommodations],
    body: [
      Absences and assessment conflicts caused by religious observance are
      accommodated. Follow #school's process for requesting religious
      accommodations, and let me know within the first two weeks of the term
      where possible, so alternate arrangements can be made without a rush.
    ],
  )

  drafts.integrity = (
    title: [Academic integrity],
    body: [
      Work you submit must represent your own understanding. Cite sources,
      including classmates, tutors, forums, and software, whenever they shaped
      what you turned in — attribution is almost never the thing that gets a
      student in trouble; concealment is.

      Suspected violations are handled through
      #fill(integrity-policy, "your institution's academic integrity policy").
      If you are stuck, out of time, or panicking, contact me before the
      deadline. Any consequence I can offer for a late or incomplete assignment
      is smaller than the one for a violation.
    ],
  )

  drafts.ai = (
    title: [Use of generative AI],
    body: if ai == "prohibited" [
      Assignments in this course must be completed without generative AI
      assistants. The skills being assessed are exactly the ones these tools
      perform for you, so using them removes the practice that the assignment
      exists to provide. If you are unsure whether a tool counts, ask me first.
    ] else if ai == "encouraged" [
      You may use generative AI tools on assignments in this course. When you do,
      include a brief note describing which tool you used and what you used it
      for, and be prepared to explain and defend everything you submit — you are
      responsible for its correctness, its sources, and its claims.
    ] else [
      You may use generative AI tools to explain concepts, brainstorm, and get
      unstuck, but not to produce the work you submit. Note where you used a tool
      and what you used it for. You remain responsible for everything you turn
      in, including anything a tool got wrong; "the model said so" is not a
      defense, and neither is a citation the model invented.
    ],
  )

  drafts.late = (
    title: [Deadlines, late work, and extensions],
    body: [
      Deadlines exist so feedback arrives while it is still useful, not to test
      your endurance. You have #late-days late #if late-days == 1 [day] else [days]
      to use across the term, no questions asked and no explanation required:
      apply them to any assignment where you need more time.

      If you run out, or something larger is going on — illness, caregiving, a
      family emergency — email me. I would rather rearrange a deadline than
      collect work you did at 4 a.m. while sick.
    ],
  )

  drafts.community = (
    title: [Our learning environment],
    body: [
      This class includes people with different backgrounds, preparation,
      languages, and reasons for being here. Confusion is ordinary and asking
      about it helps everyone, including the people too unsure to ask. Come to
      class ready to be wrong in public occasionally; that is what learning looks
      like from the outside.

      Let me know — in person, by email, or anonymously — if something in this
      course, including something I said, made it harder for you to participate.
      I will also use the name and pronouns you tell me to use.
    ],
  )

  drafts.basic-needs = (
    title: [Support and basic needs],
    body: [
      College is hard, and it is harder when the rest of life is. If you are
      struggling with mental health, #fill(counseling, "your counseling center")
      is available to you. If you have trouble affording food or lack a safe
      place to stay, #fill(basic-needs, "your campus basic-needs resources") can
      help, and you are welcome to talk to me so I can point you toward
      resources — this happens more often than most students think.

      As an instructor I am a responsible employee for reporting purposes: if you
      disclose sexual harassment or violence, I am required to notify
      #fill(title-ix, "the Title IX office"). Confidential resources on campus can
      speak with you without triggering a report.
    ],
  )

  drafts.communication = (
    title: [How to reach me],
    body: [
      Course questions belong on the course forum where possible, so the answer
      reaches everyone with the same question. For anything personal, email me at
      #fill(instructor-email, "instructor email"); I reply within #response-time
      on weekdays. Office hours are for anything at all, including "I have no
      specific question, I am just lost" — that is a normal reason to come.
    ],
  )

  drafts.recording = (
    title: [Recordings and privacy],
    body: [
      Class recordings, when they exist, are course materials for students
      enrolled this term: do not repost or share them. Students may record class
      sessions for their own study or as an approved accommodation. Please tell me
      before recording so that everyone in the room knows.
    ],
  )

  drafts
}

// Render several drafts in order: `policy-sections(drafts, ("accessibility", "integrity"))`.
#let policy-sections(drafts, keys, level: 1, collapse: false) = {
  for key in keys {
    assert(key in drafts, message: "no policy draft named \"" + key + "\"")
    policy(drafts.at(key).title, drafts.at(key).body, level: level, collapse: collapse)
  }
}
