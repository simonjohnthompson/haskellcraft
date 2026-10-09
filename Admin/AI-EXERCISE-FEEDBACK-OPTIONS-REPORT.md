# Options for AI-generated feedback on exercise solutions

Prepared ahead of adding a feature to the website that lets a student submit
their own solution to a book exercise and get AI-generated feedback on it,
free to the student. No files have been changed to produce this report --
it records the options considered and the architecture sketched out in
conversation, for review before any of it gets built.

## What the feature has to satisfy

- **Free to students.** Whatever this costs has to be absorbed by the site,
  not charged to or paid for by whoever is reading the book.
- **Fits a static site.** `Website/` is an mdBook site deployed to GitHub
  Pages via `.github/workflows/deploy-book.yml` -- there is no server today,
  and introducing one (even a tiny serverless one) is new infrastructure for
  this project, not an extension of something already running.
- **Fits the book's own exercise structure.** Every exercise already has a
  stable, derivable address: `number_exercises()` in
  `Website/convert/tex2md.py` computes `chapter.exercise` numbers (e.g.
  "5.3") deterministically from each exercise's position inside its
  `\begin{exercises}` block, purely to render the "Exercise 5.3" label
  already printed in the book. That same number is the natural key for a
  feedback widget -- no separate ID scheme needs inventing.
- **Fits the pattern already chosen for web-only content.** The
  `\webvideo`/`\begin{webvideos}` mechanism (`Book/webdefs.tex`, shipped
  across the whole book, see `Admin/VIDEO-CHAPTER-MAPPING-REPORT.md`) is a
  typed LaTeX macro that renders as plain text in the PDF and is
  special-cased by `tex2md.py` into a real interactive widget for the
  website. `Admin/SOURCE-FORMAT-OPTIONS-REPORT.md`'s "Option (ii) and
  web-only content" section recommended exactly this shape -- a stable ID in
  the macro, with the actual payload living in a web-only manifest -- for
  web-only features in general, AI exercise feedback specifically included.
  This feature should be built the same way, not as a one-off.

## Option A: a serverless proxy in front of a free-tier hosted model (recommended)

### Architecture

```
Student's browser (mdBook page)
      │ fetch() POST { exerciseId, code }
      ▼
Cloudflare Worker (free tier, 100k requests/day)
      │ 1. verify a Turnstile token (blocks scripted abuse, free)
      │ 2. rate-limit by IP (a counter in Workers KV)
      │ 3. look up exercise context by ID
      │ 4. build a prompt, call Gemini
      ▼
Gemini API (free tier, key held as a Worker secret, never shipped to the browser)
      │ feedback text
      ▼
back to the browser, rendered under the student's answer
```

The Worker is the only new piece of infrastructure. It holds the Gemini API
key as a secret (so it's never visible in page source or dev tools the way
a client-side call to Gemini would have to expose it), and it's the natural
place to put every cost and abuse control, since those all need to happen
before a request reaches Gemini, not after.

### The Worker itself

Small and stateless apart from the rate-limit counters:

```js
export default {
  async fetch(req, env) {
    const { exerciseId, code, turnstileToken } = await req.json();

    if (!(await verifyTurnstile(turnstileToken, env.TURNSTILE_SECRET))) {
      return new Response("verification failed", { status: 403 });
    }
    if (await isRateLimited(req, env.RATE_KV)) {
      return new Response("rate limit exceeded, try later", { status: 429 });
    }
    if (code.length > 4000) {
      return new Response("solution too long", { status: 413 });
    }

    const exercise = EXERCISES[exerciseId]; // bundled JSON, built from the book
    if (!exercise) return new Response("unknown exercise", { status: 404 });

    const prompt = buildPrompt(exercise, code);
    const reply = await callGemini(prompt, env.GEMINI_API_KEY);
    return Response.json({ feedback: reply });
  }
};
```

### Cost and abuse controls, all free-tier

- **Cloudflare Turnstile** -- a free, invisible CAPTCHA that blocks scripted
  abuse before it burns any quota.
- **Per-IP rate limiting** via a Workers KV counter (e.g. 10 requests/hour) --
  cheap, no paid Cloudflare add-on needed.
- **An input length cap**, so the endpoint can't be used as a general-purpose
  free LLM proxy by pasting in arbitrary unrelated text.
- **An `Origin` check**, rejecting requests that don't come from the book's
  own domain.
- **No billing account attached to the Gemini API key.** On the free tier,
  over-quota requests are rejected outright rather than billed -- leaving
  billing disabled is what makes that a guarantee rather than an assumption
  that could quietly stop being true.

### Model choice

Gemini 2.0 or 2.5 Flash-Lite: fast, and the free tier's quota is generous
(order of tens of requests/minute, four figures/day as of writing -- these
numbers move, so worth checking current limits at ai.google.dev before
building against them) for feedback at the level this needs ("here's what's
off about your pattern match"), without being expensive if usage ever did
need to graduate off the free tier.

## Option B: a fully client-side, local model

Run a small open model (e.g. Phi-3, Gemma) directly in the browser via
WebGPU/WASM, using something like WebLLM or Transformers.js. No server, no
API key, no ongoing cost or quota ceiling, ever -- the strongest answer to
"free to students" there is, since there's no operator cost to bound in the
first place.

The cost is on the student's side instead: a multi-hundred-MB model download
on first use (cached afterwards, but still a real first-load tax on a
textbook site), real compute/battery load during inference, and
meaningfully weaker code-feedback quality than a frontier hosted model --
the gap matters more here than for many local-model use cases, since the
point of the feature is specifically *useful* feedback on Haskell code, not
feedback of any quality at zero infrastructure cost.

## Comparison

| | Option A: Worker + Gemini free tier | Option B: local in-browser model |
|---|---|---|
| Cost to student | None | None |
| Cost to site operator | None, while under free-tier quota | None, ever |
| New infrastructure | A Cloudflare Worker (new) | None |
| Feedback quality | Frontier-model quality | Noticeably weaker |
| First-load cost to student | None | Multi-hundred-MB model download |
| Failure mode under heavy use | Requests rejected once free quota is exhausted | None -- scales with each student's own device |
| Key/secret handling | Gemini key lives server-side, in the Worker | N/A -- no key |

## Open questions before building

1. **Does the prompt ever see the model solution?** Sending it would likely
   improve feedback quality; withholding it removes any risk, however small,
   of the model inadvertently surfacing the answer rather than feedback on
   the student's own attempt.
2. **Streamed response, or one-shot?** Streaming reads better but adds
   Worker complexity; a one-shot response is simpler to build and debug
   first.
3. **Is the exercise manifest hand-authored, or derived from the book?**
   `tex2md.py` already parses each exercise's text to compute its number;
   that parsing is a plausible base to extend into auto-building the
   feedback context, rather than maintaining a second, hand-written copy of
   every exercise's text that could drift from the book's own.

## Recommendation

Option A (Cloudflare Worker in front of Gemini's free tier). It's the only
one of the two that can give feedback good enough to be worth a student's
time, and every objection to it -- new infrastructure, a quota ceiling --
is bounded, well-understood, and entirely within Cloudflare's and Google's
own free tiers, not a cost this project would actually bear. Option B stays
worth naming because "zero infrastructure, zero ceiling, ever" is a genuine
property Option A doesn't have, not because it's a close second on feedback
quality.
