# Implementation plan for AI-generated exercise feedback

Prepared as the follow-up to `Admin/AI-EXERCISE-FEEDBACK-OPTIONS-REPORT.md`, which laid out and got
approval for the overall architecture: a Cloudflare Worker (free tier) in front of Gemini's free
tier, gated by Turnstile, per-IP rate limiting, a length cap, and an Origin check, so the feature
costs students nothing and the site operator nothing beyond free-tier limits. The three open
questions that report left unresolved have since been settled -- the feedback prompt will never
see the book's own model solution, the first version returns feedback in one shot rather than
streaming it, and the per-exercise manifest sent to Gemini is derived from `tex2md.py`'s own
exercise-numbering logic rather than hand-authored, so it can never drift from the book's text.
This report records the concrete, file-by-file plan for building that, based on reading the
current website build (`Website/convert/tex2md.py`, `Website/book.toml`,
`Website/theme/custom.css`) and the CI workflows in detail. No files have been changed to produce
this report, and nothing described here has been built yet.

## Why this shape

The website today has no JavaScript at all, no per-exercise anchor or wrapper in the rendered
page, and no Cloudflare infrastructure anywhere in the repository. But it already has two
precedents worth reusing rather than inventing something new:

- **The `\webvideo`/`webvideos` mechanism** (`Book/webdefs.tex`, and the matching
  preprocessing/postprocessing in `tex2md.py`) is the established pattern for a web-only widget: a
  LaTeX macro is swapped for a plain-text sentinel token before Pandoc ever sees it (so Pandoc's
  LaTeX reader can't misinterpret it), and the sentinel is resolved into real HTML afterwards, once
  Pandoc has produced Markdown. This plan reuses that idiom for exercises, with one difference:
  the video mechanism *discards* whatever Pandoc rendered for its inner content and rebuilds HTML
  from scratch, whereas an exercise's rendered text (paragraphs, inline code, code blocks) has to
  be *preserved*, just wrapped in a container -- so the sentinel scheme here carries the exercise's
  rendered content through untouched, rather than throwing it away.
- **`Website/chapters/Pictures/`** is a non-Markdown directory that already lives inside mdBook's
  `src` tree and gets copied straight into the built site by `mdbook build`, with no `book.toml`
  changes. A generated `exercises.json` manifest can sit alongside it the same way.

## A. Changes confined to `Website/convert/tex2md.py`

Every change below lives in this one file. Nothing in `Book/` changes, so `Book/root.pdf` is
unaffected by construction, not just by testing.

**A stable ID and anchor for each exercise.** `number_exercises()` already computes a
cumulative `chapter.exercise` number (e.g. "5.3") for every real numbered exercise, skipping the
`\item[label]` entries used for unnumbered intro prose. Right now that number only ever becomes
bold run-in text with no wrapper at all -- `**5.3** Define a function...` -- so there is nothing in
the page for a widget to attach to. The fix is to wrap each numbered exercise's content in a new
sentinel pair, `EXERCISEOPEN<id>EXERCISEMID...EXERCISECLOSE`, following the exact two-part-sentinel
idiom already shipping as `CODELINKOPEN/MID/CLOSE` and `WEBVIDEOOPEN/MID/CLOSE` -- plain uppercase
text glued directly onto the surrounding LaTeX, confirmed safe by that existing precedent. A new
postprocessing step, added right after the existing `_resolve_webvideos` call, then wraps the
(already Pandoc-rendered) content in `<div class="exercise" id="exercise-5.3"
data-exercise-id="5.3">...<div class="exercise-feedback" data-exercise-id="5.3"></div></div>`. The
feedback div is left empty -- the button, textarea, Turnstile mount point, and result area are all
built client-side, so the widget's markup isn't duplicated into each of the roughly 130 exercises
in the book.

**A manifest of exercise text, with no second parser to keep in sync.** The same
`number_exercises()` closure that assigns each ID already has that exercise's content in scope, so
the manifest is built by capturing it right there, into a small module-level dictionary, rather
than re-extracting it from the final rendered Markdown in a second pass that would risk drifting
out of step with the numbering. By the point this code runs, `tex2md.py`'s own pipeline has
already turned `\ref` into a resolvable sentinel, citations into their own sentinels, and
`\begin{alltt}` code blocks into `\begin{minted}{haskell}` blocks -- so a small cleanup helper
only needs to resolve those, fence the code blocks, drop a handful of remaining formatting macros,
and collapse whitespace, before the text is fit to paste into an LLM prompt. (It doesn't need to
be pixel-perfect -- this text is prompt context, not rendered HTML.) The result is written as
`Website/chapters/exercises.json`, shaped as `{"5.3": {"chapter": 5, "text": "..."}, ...}`, by a
new function added alongside the script's existing `build_license_page`/`build_summary_page`
helpers and called from the same place they are.

## B. A new Cloudflare Worker, in a new `Worker/` directory

The Worker is new infrastructure -- a repo-wide search found no existing Cloudflare, Wrangler, or
Worker references anywhere -- so it gets its own top-level directory, alongside `Book/`, `Website/`,
and `Admin/`. It imports `Website/chapters/exercises.json` directly by relative path, so the
manifest has exactly one source of truth with no copy step to forget.

The request handler runs its checks cheapest-first, so a request that's going to be rejected
anyway never burns a KV read or a network round-trip to Turnstile: reject anything that isn't a
POST from the book's own origin; reject malformed bodies; reject code submissions over 4000
characters; reject unknown exercise IDs; check a per-IP rate limit held in Workers KV; verify the
Turnstile token; and only then build a prompt from the exercise's manifest text and the student's
code -- never the book's model solution, which the manifest doesn't contain in the first place --
and call Gemini once, without streaming. The rate limiter is a documented approximation rather
than a fully atomic counter: Workers KV has no atomic increment, so a tight concurrent burst from
one IP could land slightly over its hourly cap. That's accepted rather than engineered around,
since Turnstile, the Origin check, and the length cap already bound the realistic worst case well
inside what this feature's abuse-control bar needs.

## C. Frontend wiring

`Website/book.toml` gains its first `additional-js` entry, pointing at a new
`Website/theme/exercise-feedback.js`. That script finds each exercise's feedback container, wires
up a toggle button and a hidden panel, and lazy-loads Cloudflare's Turnstile script only the first
time a panel is actually opened, rather than on every page load. Submitting posts the exercise ID,
the student's code, and the Turnstile token to the Worker, and renders the response as escaped
text -- never as raw HTML, since the model's own output is not something to trust as markup.
`Website/theme/custom.css` gains a small set of rules for the new elements, following the same
convention the existing `.webvideos` rules already use: colours and backgrounds taken from
mdBook's own theme variables, so light and dark mode are handled for free rather than hardcoded.

## D. Deployment

A new `.github/workflows/deploy-worker.yml`, path-filtered to the `Worker/` directory and the
exercise manifest file the same way the two existing workflows are each filtered to `Book/**` and
`Website/**`, deploys the Worker via Cloudflare's own `wrangler-action`, using a repository secret
for the API token.

## What the user needs to do before any of this can go live

Two accounts don't exist yet, and creating them isn't something that can be done on the user's
behalf:

1. A Cloudflare account, including picking a `*.workers.dev` subdomain, registering a Turnstile
   site (which yields a public site key and a private secret key), and creating a Workers KV
   namespace for rate limiting.
2. A Gemini API key from `ai.google.dev`, deliberately created in a project with **no billing
   account attached** -- the thing that turns "free tier" from an assumption into a guarantee,
   since an over-quota request is then rejected outright rather than quietly billed.

Beyond account creation, a handful of steps are inherently things the user runs themselves rather
than Claude: an interactive `wrangler login`; pasting the Gemini and Turnstile secret keys into
`wrangler secret put` prompts, which shouldn't pass through a shared transcript; and adding the
Cloudflare API token as a GitHub Actions secret via the repository's own settings page. Once the
Worker has been deployed once, its URL and the Turnstile site key are the last two pieces needed
to finish wiring up the frontend script.

## What can and can't be checked before any of that happens

Everything on the build side can be verified without any live credentials: regenerating every
chapter's Markdown and the manifest and diffing them against what's currently committed, to
confirm the only change is the new wrapping around numbered exercises and nothing else shifts;
checking the manifest's contents directly; and building the site locally to confirm the widget
renders and toggles correctly in both light and dark theme. A `git diff --stat` showing no changes
under `Book/` confirms the PDF build is untouched.

What can't be checked yet is, unavoidably, everything that depends on the two accounts above
existing: the real Gemini call and the quality of its feedback, the Turnstile verification
round-trip, the rate limiter's behaviour under real concurrent traffic, cross-origin behaviour
between the real GitHub Pages site and the real deployed Worker, and the deploy workflow's own
first run. Those are smoke-test items for after the user has been through the setup checklist
above, not things this plan can claim to have already confirmed.
