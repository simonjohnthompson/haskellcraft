// Cloudflare Worker behind the book's "AI feedback on your exercise
// solution" widget. See Admin/AI-EXERCISE-FEEDBACK-OPTIONS-REPORT.md and
// Admin/AI-EXERCISE-FEEDBACK-IMPLEMENTATION-PLAN-REPORT.md for the full
// design. Imported directly from the book's own build output, so there's
// exactly one source of truth for exercise text and no copy step to forget.
import EXERCISES from "../../Website/chapters/exercises.json";

const MAX_CODE_LENGTH = 4000;
const GEMINI_MODEL = "gemini-2.0-flash-lite";
const GEMINI_URL = `https://generativelanguage.googleapis.com/v1beta/models/${GEMINI_MODEL}:generateContent`;

function corsHeaders(env) {
  return {
    "Access-Control-Allow-Origin": env.ALLOWED_ORIGIN,
    "Access-Control-Allow-Methods": "POST, OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type",
  };
}

function jsonResponse(body, status, env) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json", ...corsHeaders(env) },
  });
}

function buildPrompt(exerciseId, exercise, code) {
  return `You are a teaching assistant for a Haskell textbook. A student is attempting
the following exercise. Give feedback on their code -- point out bugs, style
issues, and whether it solves the exercise -- but do NOT provide a corrected
or complete solution, and do not rewrite their code for them. If their code
is already correct, say so and suggest one possible improvement or
alternative approach, without just doing it for them.

Exercise ${exerciseId}:
${exercise.text}

Student's submitted code:
\`\`\`haskell
${code}
\`\`\`

Feedback:`;
}

// Checking only `success` confirms the token is a real, unused Turnstile
// token -- not that it was issued for this site's own widget. Checking
// `hostname` too ties the verification to the book's actual domain.
async function verifyTurnstile(token, env) {
  // Fail closed: a network hiccup or a non-JSON response from Cloudflare's
  // own endpoint means "not verified", not an unhandled exception that
  // surfaces to the client as a generic platform error page instead of a
  // proper response.
  try {
    const resp = await fetch("https://challenges.cloudflare.com/turnstile/siteverify", {
      method: "POST",
      headers: { "Content-Type": "application/x-www-form-urlencoded" },
      body: new URLSearchParams({ secret: env.TURNSTILE_SECRET_KEY, response: token }),
    });
    const result = await resp.json();
    const expectedHost = new URL(env.ALLOWED_ORIGIN).hostname;
    return result.success === true && result.hostname === expectedHost;
  } catch {
    return false;
  }
}

// Workers KV has no atomic increment, so a tight concurrent burst from one
// IP can land slightly over the limit -- accepted, not fixed: Turnstile,
// the Origin check, and the length cap already bound the realistic worst
// case well inside what this feature's abuse-control bar needs.
async function checkAndIncrementRateLimit(ip, env) {
  const bucket = Math.floor(Date.now() / 3600000);
  const key = `rl:${ip}:${bucket}`;
  const limit = parseInt(env.RATE_LIMIT_PER_HOUR, 10);
  const current = parseInt(await env.RATE_KV.get(key), 10) || 0;
  if (current >= limit) return false;
  await env.RATE_KV.put(key, String(current + 1), { expirationTtl: 3600 });
  return true;
}

async function callGemini(prompt, env) {
  const resp = await fetch(`${GEMINI_URL}?key=${env.GEMINI_API_KEY}`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ contents: [{ parts: [{ text: prompt }] }] }),
  });
  if (!resp.ok) {
    throw new Error(`Gemini request failed: ${resp.status}`);
  }
  const data = await resp.json();
  const text = data?.candidates?.[0]?.content?.parts?.[0]?.text;
  if (!text) {
    throw new Error("Gemini returned no feedback text");
  }
  return text;
}

export default {
  async fetch(request, env) {
    if (request.method === "OPTIONS") {
      return new Response(null, { headers: corsHeaders(env) });
    }
    if (request.method !== "POST") {
      return jsonResponse({ error: "method not allowed" }, 405, env);
    }

    // The Origin header is a weak signal -- trivially forged by a
    // non-browser client -- but it's free and blocks the laziest
    // cross-site abuse; Turnstile below is the real gate. Exact match
    // only, never a substring/`.includes()` check.
    if (request.headers.get("Origin") !== env.ALLOWED_ORIGIN) {
      return jsonResponse({ error: "forbidden" }, 403, env);
    }

    let body;
    try {
      body = await request.json();
    } catch {
      return jsonResponse({ error: "malformed request body" }, 400, env);
    }
    const { exerciseId, code, turnstileToken } = body ?? {};
    if (
      typeof exerciseId !== "string" ||
      typeof code !== "string" ||
      typeof turnstileToken !== "string"
    ) {
      return jsonResponse({ error: "missing exerciseId, code, or turnstileToken" }, 400, env);
    }

    if (code.length > MAX_CODE_LENGTH) {
      return jsonResponse({ error: "code too long" }, 413, env);
    }

    // Object.hasOwn, never a bare EXERCISES[exerciseId] lookup -- indexing
    // a plain object with an untrusted string resolves prototype-chain
    // properties (e.g. "constructor", "__proto__") to a truthy value,
    // which would silently bypass this check for those specific ids.
    if (!Object.hasOwn(EXERCISES, exerciseId)) {
      return jsonResponse({ error: "unknown exercise" }, 404, env);
    }
    const exercise = EXERCISES[exerciseId];

    const ip = request.headers.get("CF-Connecting-IP") ?? "unknown";
    const withinLimit = await checkAndIncrementRateLimit(ip, env);
    if (!withinLimit) {
      return jsonResponse({ error: "rate limit exceeded, try again later" }, 429, env);
    }

    const turnstileOk = await verifyTurnstile(turnstileToken, env);
    if (!turnstileOk) {
      return jsonResponse({ error: "verification failed" }, 403, env);
    }

    try {
      const feedback = await callGemini(buildPrompt(exerciseId, exercise, code), env);
      return jsonResponse({ feedback }, 200, env);
    } catch {
      // Never leak the API key or the raw upstream error body.
      return jsonResponse({ error: "feedback service unavailable" }, 502, env);
    }
  },
};
