#import "@preview/coconut:0.1.0": *

// Course staff. The staff page renders this roster in full; keeping it here
// means office hours are written down once, in the same place as the person
// who holds them.

#let roster = (
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
