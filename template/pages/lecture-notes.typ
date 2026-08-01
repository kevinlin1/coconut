#import "@preview/coconut:0.1.0": *

#let embed-controls() = context {
  html.div(style: "display: flex; flex-wrap: wrap; gap: 0.5em; align-items: center; margin-bottom: 0.5em;", {
    html.elem("button", attrs: (
      type: "button",
      style: "padding: 0.35em 0.65em; border: 1px solid rgb(157,165,180); background: rgb(246,248,250); color: rgb(36,41,47); cursor: pointer; border-radius: 6px;",
      onclick: "var w=this.closest('.embed-wrapper'); var f=w.querySelector('iframe'); var hidden=f.style.display==='none'; f.style.display=hidden?'block':'none'; this.textContent=hidden?'Collapse':'Expand';",
    ), { text("Collapse") })

    html.elem("button", attrs: (
      type: "button",
      style: "padding: 0.35em 0.65em; border: 1px solid rgb(157,165,180); background: rgb(246,248,250); color: rgb(36,41,47); cursor: pointer; border-radius: 6px;",
      onclick: "var w=this.closest('.embed-wrapper'); var f=w.querySelector('iframe'); var h=parseInt(f.style.height||f.clientHeight,10)||0; f.style.height=Math.max(200,h-100)+'px';",
    ), { text("Smaller") })

    html.elem("button", attrs: (
      type: "button",
      style: "padding: 0.35em 0.65em; border: 1px solid rgb(157,165,180); background: rgb(246,248,250); color: rgb(36,41,47); cursor: pointer; border-radius: 6px;",
      onclick: "var w=this.closest('.embed-wrapper'); var f=w.querySelector('iframe'); var h=parseInt(f.style.height||f.clientHeight,10)||0; f.style.height=(h+100)+'px';",
    ), { text("Larger") })
  })
}

#let embed-google-doc(url, title: none, height: 700) = context {
  if target() == "html" {
    html.div(class: "embed-wrapper", style: "border: 1px solid rgb(208,215,222); border-radius: 8px; padding: 0.8em; background: rgb(248,250,252);", {
      if title != none { strong(title) }
      embed-controls()
      html.elem("iframe", attrs: (
        src: url,
        width: "100%",
        height: str(height),
        style: "border: 1px solid rgb(208,215,222); width: 100%; min-height: " + str(height) + "px; background: white;",
        loading: "lazy",
        allowfullscreen: "true",
        referrerpolicy: "strict-origin-when-cross-origin",
      ))
      parbreak()
      link(url)[Open this note in Google Docs]
    })
  } else {
    block(width: 100%, spacing: 0.8em, {
      if title != none { strong(title) }
      parbreak()
      [Embedded view is available on the HTML site. Open ]
      link(url)[this Google Doc]
      [ directly in the browser.]
    })
  }
}

#let embed-video(url, title: none, height: 420) = context {
  if target() == "html" {
    html.div(class: "embed-wrapper", style: "border: 1px solid #d0d7de; border-radius: 8px; padding: 0.8em; background: #f8fafc;", {
      if title != none { strong(title) }
      embed-controls()
      html.elem("iframe", attrs: (
        src: url,
        width: "100%",
        height: str(height),
        style: "border: 0; width: 100%; min-height: " + str(height) + "px; background: black;",
        loading: "lazy",
        allow: "accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share",
        allowfullscreen: "true",
      ))
      parbreak()
      link(url)[Open video in a new tab]
    })
  } else {
    block(width: 100%, spacing: 0.8em, {
      if title != none { strong(title) }
      parbreak()
      [Embedded video is available on the HTML site. Open ]
      link(url)[this video]
      [ directly in the browser.]
    })
  }
}

#let lecture-notes = (
  title: "Lecture Notes",
  description: "Collaborative lecture notes organized by time and topic for INFO 220.",
  body: [
    Lecture notes are a collaborative course resource: written by students, edited by instructors, and organized in lecture order so the class can build a shared record of what happened each week.

    #callout(
      kind: "note",
      title: [How this works],
      [These notes are meant to be living documents. Students can add observations, questions, and summaries; instructors can refine wording, correct mistakes, and keep the notes aligned with the course.
      ],
    )

    = Week 1 — Course overview

    This opening note collects the shared summary of the first lecture and the main themes students should carry forward.

    #embed-google-doc(
      "https://docs.google.com/spreadsheets/d/1HexwBdCAxboUqFYcTH1o8_g117F9yHXAhuVRC-rbDPw/edit?usp=sharing",
      title: [Lecture notes spreadsheet],
      height: 620,
    )

    = Week 2 — Methods and questions

    The second set of notes focuses on the methods introduced in class and the questions students left with after the session.

    #embed-google-doc(
      "https://docs.google.com/document/d/1-HUSO5r3ls-HMDFb0045q1i87L6EE5GA6bsCX8AOB_A/edit?usp=sharing",
      title: [Lecture notes document],
      height: 760,
    )

    = Embedded media example

    This section demonstrates that a lecture page can also host a linked video resource directly in the site.

    #embed-video(
      "https://www.youtube.com/embed/F4SkHTq8FaM",
      title: [Example lecture video],
      height: 420,
    )
  ],
)
