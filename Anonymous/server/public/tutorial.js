(function () {
  "use strict";

  var running = false;
  var idx = 0;
  var hooks = null;
  var backdrop = null;
  var popup = null;
  var titleEl, textEl, progressEl, backBtn, nextBtn, skipBtn;
  var currentTarget = null;

  function safe(fn) {
    if (typeof fn !== "function") return;
    var args = Array.prototype.slice.call(arguments, 1);
    try { return fn.apply(null, args); } catch (e) { /* hook failed; keep going */ }
  }

  var STEPS = [
    {
      title: "Feedback goes to your instructor",
      text: "This button is always here. Everything you send goes straight to the instructor — anonymously, no name needed.",
      target: function () { return hooks.fab; },
      setup: null
    },
    {
      title: "Comment on anything",
      text: "Select any text on the page (mouse, or Shift+arrow keys, then Alt+C), or send general feedback about the whole page from the panel.",
      target: null,
      setup: function () { safe(hooks.closePanel); }
    },
    {
      title: "AI can draft the edit",
      text: "Optionally, AI writes the actual change to the course materials for you. Accept it, tweak it, or discard it — anything you accept is sent to the instructor with your comment, and only they can apply it. You can preview exactly how the page would look.",
      target: function () { return hooks.panel; },
      setup: function () { safe(hooks.openPanel, "compose"); },
      placement: "left"
    },
    {
      title: "Track replies and status",
      text: "The instructor can reply, approve your suggestion, and publish the change. Watch here — or the red bubble — for updates. You can delete your feedback anytime.",
      target: function () { return hooks.panel; },
      setup: function () { safe(hooks.openPanel, "mine"); },
      placement: "left"
    },
    {
      title: "You stay anonymous",
      text: "The instructor sees only your words: the comment, the selected text, the suggested edit. Your name appears only if you type one.",
      target: null,
      setup: null
    }
  ];

  function makeButton(label, className) {
    var b = document.createElement("button");
    b.type = "button";
    b.className = className;
    b.textContent = label;
    return b;
  }

  function build() {
    var root = document.querySelector(".anon-root") || document.body;

    backdrop = document.createElement("div");
    backdrop.className = "anon-tut-backdrop";
    backdrop.setAttribute("aria-hidden", "true");

    popup = document.createElement("div");
    popup.className = "anon-tut-popup";
    popup.setAttribute("role", "dialog");
    popup.setAttribute("aria-modal", "true");
    popup.setAttribute("aria-labelledby", "anon-tut-title");

    titleEl = document.createElement("h2");
    titleEl.className = "anon-tut-title";
    titleEl.id = "anon-tut-title";

    textEl = document.createElement("p");
    textEl.className = "anon-tut-text";

    var footer = document.createElement("div");
    footer.className = "anon-tut-footer";

    progressEl = document.createElement("span");
    progressEl.className = "anon-tut-progress";

    backBtn = makeButton("Back", "anon-btn");
    nextBtn = makeButton("Next", "anon-btn anon-btn-primary");
    skipBtn = makeButton("Skip tour", "anon-btn");

    backBtn.addEventListener("click", function () { go(idx - 1); });
    nextBtn.addEventListener("click", function () {
      if (idx >= STEPS.length - 1) end(true); else go(idx + 1);
    });
    skipBtn.addEventListener("click", function () { end(false); });

    footer.appendChild(progressEl);
    footer.appendChild(backBtn);
    footer.appendChild(nextBtn);
    footer.appendChild(skipBtn);

    popup.appendChild(titleEl);
    popup.appendChild(textEl);
    popup.appendChild(footer);
    popup.addEventListener("keydown", onKeydown);

    root.appendChild(backdrop);
    root.appendChild(popup);
    window.addEventListener("resize", onResize);
  }

  function visibleButtons() {
    return [backBtn, nextBtn, skipBtn].filter(function (b) {
      return b.style.display !== "none";
    });
  }

  function onKeydown(e) {
    if (e.key === "Escape") { e.preventDefault(); end(false); return; }
    if (e.key === "ArrowRight") {
      e.preventDefault();
      if (idx >= STEPS.length - 1) end(true); else go(idx + 1);
      return;
    }
    if (e.key === "ArrowLeft") {
      e.preventDefault();
      if (idx > 0) go(idx - 1);
      return;
    }
    if (e.key === "Tab") {
      var btns = visibleButtons();
      var i = btns.indexOf(document.activeElement);
      if (i === -1) i = 0;
      e.preventDefault();
      var next = e.shiftKey
        ? (i - 1 + btns.length) % btns.length
        : (i + 1) % btns.length;
      btns[next].focus();
    }
  }

  function onResize() {
    if (running) position();
  }

  function clearRing() {
    if (currentTarget) {
      currentTarget.classList.remove("anon-tut-ring");
      currentTarget = null;
    }
  }

  function position() {
    var margin = 8;
    var w = popup.offsetWidth;
    var h = popup.offsetHeight;
    var vw = window.innerWidth;
    var vh = window.innerHeight;
    var top, left;
    var rect = null;

    if (currentTarget) rect = currentTarget.getBoundingClientRect();
    if (rect && (rect.width > 0 || rect.height > 0)) {
      // Try each side of the target; take the first placement that fits the
      // viewport without covering the target (the panel fills the right
      // column, so "left of target" is what usually wins there).
      var candidates = [
        { top: rect.bottom + margin, left: rect.left },
        { top: rect.top - h - margin, left: rect.left },
        { top: rect.top, left: rect.left - w - margin },
        { top: rect.top, left: rect.right + margin }
      ];
      // Steps can pin a placement so consecutive steps with the same target
      // (whose height varies with content) don't hop around the screen.
      if (STEPS[idx] && STEPS[idx].placement === "left") {
        candidates.unshift({ top: rect.top, left: rect.left - w - margin });
      }
      var chosen = null;
      for (var i = 0; i < candidates.length; i++) {
        var c = candidates[i];
        if (
          c.top >= margin && c.top + h <= vh - margin &&
          c.left >= margin && c.left + w <= vw - margin
        ) { chosen = c; break; }
      }
      if (chosen) {
        top = chosen.top;
        left = chosen.left;
      } else {
        // Nothing fits cleanly (small screens): sit beside the target's left
        // edge, clamped — overlap only as a last resort.
        top = Math.min(Math.max(margin, rect.top), Math.max(margin, vh - h - margin));
        left = Math.max(margin, rect.left - w - margin);
      }
    } else {
      top = (vh - h) / 2;
      left = (vw - w) / 2;
    }

    top = Math.max(margin, Math.min(top, vh - h - margin));
    left = Math.max(margin, Math.min(left, vw - w - margin));
    popup.style.top = top + "px";
    popup.style.left = left + "px";
  }

  function go(i) {
    idx = i;
    var step = STEPS[idx];
    clearRing();
    if (step.setup) step.setup();

    titleEl.textContent = step.title;
    textEl.textContent = step.text;
    progressEl.textContent = "Step " + (idx + 1) + " of " + STEPS.length;

    var last = idx === STEPS.length - 1;
    backBtn.style.display = idx === 0 ? "none" : "";
    skipBtn.style.display = last ? "none" : "";
    nextBtn.textContent = last ? "Done" : "Next";

    var target = typeof step.target === "function" ? step.target() : null;
    if (target && target.classList) {
      currentTarget = target;
      currentTarget.classList.add("anon-tut-ring");
    }

    position();
    nextBtn.focus();
  }

  function teardown() {
    clearRing();
    window.removeEventListener("resize", onResize);
    if (backdrop && backdrop.parentNode) backdrop.parentNode.removeChild(backdrop);
    if (popup && popup.parentNode) popup.parentNode.removeChild(popup);
    backdrop = null;
    popup = null;
  }

  function end(finished) {
    if (!running) return;
    running = false;
    teardown();
    safe(hooks.closePanel);
    safe(hooks.announce, finished
      ? "Tutorial finished. Open the panel anytime with the feedback button."
      : "Tutorial skipped.");
    safe(hooks.onDone);
  }

  window.AnonTutorial = {
    start: function (h) {
      if (running) { running = false; teardown(); }
      hooks = h || {};
      running = true;
      build();
      go(0);
    },
    isRunning: function () { return running; }
  };
})();
