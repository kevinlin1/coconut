// The rules in alt-text.mjs, tested against the alt text they exist to reject
// and — the half that matters more — the alt text they must not.
//
// A quality check that fires on good descriptions is worse than no check: it
// gets switched off, or worked around with whatever wording satisfies it. Every
// rule here is paired with the nearest thing to it that has to keep passing.
//
// Run with: node --test .github/scripts

import test from "node:test";
import assert from "node:assert/strict";
import { altProblem, pageProblems, MAX_CHARACTERS } from "./alt-text.mjs";

const id = (alt, options) => altProblem(alt, options)?.id ?? null;

test("alt text that is not there", () => {
  assert.equal(id(null), "missing");
  assert.equal(id(undefined), "missing");
  assert.equal(id(""), "empty");
  assert.equal(id("   "), "empty");
  assert.equal(id("—"), "no-words");
});

test("alt text that names the medium instead of the content", () => {
  assert.equal(id("image"), "placeholder");
  assert.equal(id("Image"), "placeholder");
  assert.equal(id("the chart"), "placeholder");
  assert.equal(id("figure 1"), null, "a numbered figure is at least identifying");
  assert.equal(id("photo"), "placeholder");
  assert.equal(id("TODO"), "placeholder");
});

test("alt text copied from the file system", () => {
  assert.equal(id("co2-trend.png"), "filename");
  assert.equal(id("figures/co2 trend.svg"), "filename");
  assert.equal(id("IMG_1024"), "filename");
  assert.equal(id("DSC00312.JPG"), "filename");
  assert.equal(id("Before/after view of the calibration"), null, "a slash is not a path");
  assert.equal(id("Figure 2 of the fitted trend line"), null, "a word and a number is not a filename");
});

test("alt text a screen reader would announce twice", () => {
  assert.equal(id("Image of the Mauna Loa record"), "redundant-opener");
  assert.equal(id("A photo of Dr. Okonkwo at the sensor"), "redundant-opener");
  assert.equal(id("Screenshot of the grading page in Canvas"), null, "a screenshot is a thing it is");
  assert.equal(id("Map of the sensor sites along the river"), null);
  assert.equal(id("Photosynthesis rates by month"), null, "matching has to be on words");
});

test("alt text that is a URL", () => {
  assert.equal(id("https://example.edu/figures/trend"), "url");
  assert.equal(id("See www.example.edu for the data"), "url");
});

test("alt text too short to be a description", () => {
  assert.equal(id("Trend"), "too-short");
  assert.equal(id("CO2"), "too-short");
  assert.equal(id("MIT logo"), null, "two words is the floor, and a logo clears it");
});

test("alt text long enough to need a long description instead", () => {
  const long = "The monthly mean carbon dioxide concentration at Mauna Loa, "
    + "rising and falling within each year while trending upward across all of them, "
    + "from about 315 parts per million in 1958 to about 420 parts per million in 2024, "
    + "with the annual cycle widening slightly over the record.";
  assert.ok(long.length > MAX_CHARACTERS);
  assert.equal(id(long), "too-long");
});

test("alt text the caption already covers", () => {
  const alt = "Carbon dioxide at Mauna Loa, 1958 to 2024";
  assert.equal(id(alt, { caption: alt }), "same-as-caption");
  assert.equal(
    id(alt, { caption: "Figure 1: Carbon dioxide at Mauna Loa, 1958 to 2024." }),
    "same-as-caption",
    "the number Typst prints in front of a caption does not make it a different sentence",
  );
  assert.equal(
    id("Carbon dioxide at Mauna Loa", { caption: alt }),
    "same-as-caption",
    "a subset of the caption adds nothing to it",
  );
  assert.equal(
    id("A sawtooth curve climbing from 315 to 420 ppm", { caption: alt }),
    null,
    "saying what the caption does not is the point",
  );
  assert.equal(
    id(`${alt}, a sawtooth curve rising year on year`, { caption: alt }),
    null,
    "an alt text that says more than the caption is not the caption",
  );
});

const image = (overrides) => ({
  target: "img",
  alt: null,
  label: null,
  role: null,
  hidden: false,
  caption: null,
  ...overrides,
});

test("decorative images are exempt, but only when they are silent", () => {
  const described = "Monthly carbon dioxide at Mauna Loa";
  assert.deepEqual(pageProblems([image({ alt: "", hidden: true })]), []);
  assert.deepEqual(pageProblems([image({ alt: "", role: "presentation" })]), []);
  assert.equal(pageProblems([image({ alt: "" })])[0].id, "empty");
  assert.equal(pageProblems([image({ alt: described, hidden: true })])[0].id, "hidden-with-alt");
});

test("an ARIA label is what gets announced, so it is what gets checked", () => {
  assert.deepEqual(pageProblems([image({ role: "img", label: "Rising sawtooth curve" })]), []);
  assert.equal(pageProblems([image({ role: "img" })])[0].id, "missing");
  assert.equal(
    pageProblems([image({ alt: "A good description of the figure", label: "image" })])[0].id,
    "placeholder",
    "the label wins over the alt attribute",
  );
});

test("two images on a page cannot share one description", () => {
  const alt = "Sensor housing mounted on a rooftop mast";
  const problems = pageProblems([
    image({ target: "img:nth-of-type(1)", alt }),
    image({ target: "img:nth-of-type(2)", alt: alt.toUpperCase() }),
  ]);
  assert.equal(problems.length, 1);
  assert.equal(problems[0].id, "duplicate");
  assert.equal(problems[0].target, "img:nth-of-type(2)", "reported against the second one");
});

test("a page of well-described images has nothing to report", () => {
  assert.deepEqual(
    pageProblems([
      image({ alt: "Carbon dioxide rising from 315 to 420 ppm", caption: "Figure 1: the record" }),
      image({ alt: "Dr. Okonkwo, wearing a red jacket, beside a river gauge" }),
      image({ alt: "", hidden: true }),
    ]),
    [],
  );
});
