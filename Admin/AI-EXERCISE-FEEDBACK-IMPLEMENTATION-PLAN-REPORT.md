# Implementation of AI-generated exercise feedback

Prepared as a record of what was actually built, following
`Admin/AI-EXERCISE-FEEDBACK-OPTIONS-REPORT.md`'s approved architecture: a Cloudflare Worker (free
tier) in front of Gemini's free tier, gated by Turnstile, per-IP rate limiting, a length cap, and
an Origin check, so the feature costs students nothing and the site operator nothing beyond
free-tier limits. The feature is now live on the website -- this report was originally written as
a forward-looking implementation plan before any of it existed; it has since been updated to
describe what was actually built, deployed, and fixed after live testing surfaced a handful of
real bugs the planning stage couldn't have caught.

## Why this shape

The website had no JavaScript at all, no per-exercise anchor or wrapper in the rendered page, and
no Cloudflare infrastructure anywhere in the repository. Two existing precedents were reused
rather than inventing something new:

- **The `\webvideo`/`webvideos` mechanism** (`Book/webdefs.tex`, and the matching
  preprocessing/postprocessing in `tex2md.py`) is the established pattern for a web-only widget: a
  LaTeX macro is swapped for a plain-text sentinel token before Pandoc ever sees it (so Pandoc's
  LaTeX reader can't misinterpret it), and the sentinel is resolved into real HTML afterwards, once
  Pandoc has produced Markdown. The exercise feedback widget reuses that idiom, with one
  difference: the video mechanism *discards* whatever Pandoc rendered for its inner content and
  rebuilds HTML from scratch, whereas an exercise's rendered text (paragraphs, inline code, code
  blocks) had to be *preserved*, just wrapped in a container -- so the sentinel scheme here carries
  the exercise's rendered content through untouched, rather than throwing it away.
- **`Website/chapters/Pictures/`** was already a non-Markdown directory living inside mdBook's
  `src` tree that gets copied straight into the built site by `mdbook build`, with no `book.toml`
  changes. The generated `exercises.json` manifest sits alongside it the same way.

## A. `Website/convert/tex2md.py`: exercise anchors and the manifest

All of this lives in one file. Nothing in `Book/` changed, so `Book/root.pdf` is unaffected.

**A stable ID and anchor for each exercise.** `number_exercises()` already computed a cumulative
`chapter.exercise` number (e.g. "5.3") for every real numbered exercise, skipping the
`\item[label]` entries used for unnumbered intro prose, but that number only ever became bold
run-in text with no wrapper at all. Each numbered exercise's content is now wrapped in a sentinel
pair, `EXERCISEOPEN<id>EXERCISEMID...EXERCISECLOSE`, the same two-part-sentinel idiom already
shipping as `CODELINKOPEN/MID/CLOSE` and `WEBVIDEOOPEN/MID/CLOSE`. A postprocessing step resolves
that into `<div class="exercise" id="exercise-5.3" data-exercise-id="5.3">...<div
class="exercise-feedback" data-exercise-id="5.3"></div></div>`, with Pandoc's own rendering of the
exercise's content preserved exactly rather than rebuilt. The feedback div is left empty --
the button, textarea, Turnstile mount point, and result area are all built client-side, so the
widget's markup isn't duplicated into each of the 612 numbered exercises in the book.

**The manifest.** `number_exercises()`'s own closure captures each exercise's text into a
module-level `EXERCISE_MANIFEST` dict as it assigns the id, rather than re-extracting it from the
rendered Markdown in a second pass that could drift out of step with the numbering. A cleanup
helper resolves the `\ref`/`\cite` sentinels already present at that point in the pipeline, turns
`\begin{minted}{haskell}...\end{minted}` into fenced code, and strips the remaining LaTeX
formatting macros and escapes -- with fenced code blocks protected from that cleanup (stashed out
and restored verbatim) so real Haskell syntax survives untouched, including constructs that would
otherwise be mistaken for LaTeX (a lambda `\x ->`, the infix list-difference operator `` \\ ``).
The result, `Website/chapters/exercises.json`, holds all 612 exercises as `{"5.3": {"chapter": 5,
"text": "..."}, ...}`.

## B. The Cloudflare Worker (`Worker/`)

A new top-level directory, alongside `Book/`, `Website/`, and `Admin/`. `Worker/src/index.js`
imports `Website/chapters/exercises.json` directly by relative path, so the manifest has exactly
one source of truth.

The request handler runs its checks cheapest-first: reject anything that isn't a POST from the
book's own origin; reject malformed bodies; reject code submissions over 4000 characters; reject
unknown exercise IDs (via `Object.hasOwn`, not a bare `EXERCISES[exerciseId]` lookup -- indexing a
plain object with an untrusted string can resolve prototype-chain properties like `"constructor"`
to a truthy value, which would otherwise bypass this check); check a per-IP rate limit held in
Workers KV; verify the Turnstile token (checking the siteverify response's `hostname`, not just
`success`, so a token solved somewhere else with the same sitekey wouldn't verify here); and only
then build a prompt from the exercise's manifest text and the student's code -- never the book's
model solution, which the manifest doesn't contain in the first place -- and call Gemini once,
without streaming.

The rate limiter is a documented approximation, not a fully atomic counter: Workers KV has no
atomic increment, so a tight concurrent burst from one IP could land slightly over its hourly cap.
That's accepted rather than engineered around, since Turnstile, the Origin check, and the length
cap already bound the realistic worst case well inside what this feature's abuse-control bar
needs.

## C. Frontend wiring

`Website/book.toml` gained its first `additional-js` entry, pointing at
`Website/theme/exercise-feedback.js`. It finds each exercise's feedback container, wires up a
toggle button and a hidden panel, and lazy-loads Cloudflare's Turnstile script only the first time
a panel is actually opened. Submitting posts the exercise ID, the student's code, and the
Turnstile token to the Worker.

Gemini's response comes back as Markdown-ish text (bold, inline code, fenced code blocks, bullet
lists). It's rendered through a small hand-rolled renderer rather than shown as raw text or
trusted as HTML: the whole string is escaped first (so a literal `<script>` in the feedback
becomes inert text before anything else runs), and only that already-escaped text is ever wrapped
in a fixed, hardcoded set of tags (`<p>`, `<strong>`, `<code>`, `<pre><code>`, `<ul><li>`) --
there is no path by which the model's own output could introduce a real tag. `Website/theme/custom.css`
styles the widget and the rendered feedback (including nested code blocks and lists) using
mdBook's own theme variables, so light and dark mode are handled for free.

## D. Deployment

`.github/workflows/deploy-worker.yml`, path-filtered to `Worker/**` and the exercise manifest the
same way the two existing workflows are each filtered to `Book/**` and `Website/**`, deploys the
Worker via Cloudflare's `wrangler-action`, using the `CLOUDFLARE_API_TOKEN` repository secret.

## Account setup

Completed: a Cloudflare account with the `thompsonsimonuk` Workers subdomain; a Turnstile site
registered against `simonjohnthompson.github.io` (site key `0x4AAAAAAFUgs8ubXD-pXXCP`, public and
safe to have in client-side JS; the secret key lives only as a Worker secret); a Workers KV
namespace for rate limiting; a Gemini API key from `ai.google.dev`, in a project with no billing
account attached; and `CLOUDFLARE_API_TOKEN` added as a GitHub Actions secret. The Worker is live
at `https://haskellcraft-exercise-feedback.thompsonsimonuk.workers.dev`.

## Bugs found and fixed during live verification

Four real issues surfaced only once the feature was actually exercised end-to-end, each diagnosed
against the live Worker (via `wrangler tail` and, where that didn't show enough detail, a
temporary debug field in the HTTP response, removed again once resolved) rather than guessed at:

1. **An unhandled exception on a bad Turnstile response.** `resp.json()` on Cloudflare's
   siteverify response could throw (it did, immediately, since the secret wasn't configured yet at
   first test), surfacing Cloudflare's generic platform error page instead of a proper response.
   Fixed to fail closed -- any parse or network failure now means "not verified," not a crash.
2. **The wrong siteverify URL.** The Worker called
   `https://challenges.cloudflare.com/turnstile/siteverify` (404, empty body) instead of the real
   `https://challenges.cloudflare.com/turnstile/v0/siteverify` -- every verification attempt was
   hitting the fail-closed path above rather than actually verifying anything, even after fix (1).
3. **A retired Gemini model.** `gemini-2.0-flash-lite`, the model named in the original options
   report, had been retired; Gemini's own 404 response named `gemini-3.5-flash-lite` as the
   replacement, now in use.
4. **Raw markdown in the rendered feedback.** The response was shown via `textContent`, so
   Gemini's own Markdown syntax (`**bold**`, `` `code` ``, fenced blocks) was visible literally
   rather than formatted -- fixed by the escape-first renderer described in section C.

Also adjusted after real use: the per-IP rate limit, originally 10 requests/hour, proved too tight
for legitimate iteration on one exercise and was raised to 30/hour.

## Verification

Confirmed without live credentials, before deployment: full-corpus `tex2md.py` regeneration,
diffed chapter-by-chapter against the previously-committed Markdown, showed the only changes were
the intended exercise wrapping; the manifest's 612 entries were spot-checked for clean, sentinel-free
text; `wrangler deploy --dry-run` confirmed the Worker bundled correctly with all three bindings
resolving; and a local `mdbook build` plus headless-Chrome screenshots confirmed the widget
rendered and toggled correctly in both light and dark theme. `git diff --stat` confirmed no file
under `Book/` ever changed.

Confirmed live, after deployment and the account setup above: the Origin check, the
prototype-pollution guard on exercise lookup, and CORS headers were all exercised directly against
the deployed Worker with `curl`; the four bugs above were each found and re-verified fixed against
the real endpoint; and the full flow -- Turnstile, rate limiting, the Gemini call, and the rendered
response -- was confirmed working end-to-end on the live site.
