// AI feedback widget for book exercises. Each numbered exercise's
// rendered page has an empty <div class="exercise-feedback"
// data-exercise-id="5.3"></div> (see tex2md.py's EXERCISEOPEN sentinel) --
// this script finds every one of those and fills it in.
//
// Fill these in once the Worker is deployed and the Turnstile widget is
// registered (see Admin/AI-EXERCISE-FEEDBACK-IMPLEMENTATION-PLAN-REPORT.md).
const WORKER_URL = "https://haskellcraft-exercise-feedback.thompsonsimonuk.workers.dev";
const TURNSTILE_SITE_KEY = "0x4AAAAAAFUgs8ubXD-pXXCP";
const MAX_CODE_LENGTH = 4000;

let turnstileLoadPromise = null;
function loadTurnstile() {
    if (!turnstileLoadPromise) {
        turnstileLoadPromise = new Promise((resolve, reject) => {
            if (window.turnstile) {
                resolve(window.turnstile);
                return;
            }
            const script = document.createElement("script");
            script.src = "https://challenges.cloudflare.com/turnstile/v0/api.js";
            script.async = true;
            script.onload = () => resolve(window.turnstile);
            script.onerror = () => reject(new Error("failed to load Turnstile"));
            document.head.appendChild(script);
        });
    }
    return turnstileLoadPromise;
}

function escapeHtml(s) {
    return s.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
}

// Gemini's feedback comes back as Markdown-ish text (bold, inline code,
// fenced code blocks, bullet lists). Render it for readability without
// ever trusting the model's output as HTML: escape the whole string
// first, then only ever wrap that already-escaped, inert text in a
// fixed, hardcoded set of tags. A literal "<script>" in the feedback
// becomes the harmless text "&lt;script&gt;" before any of the markup
// rules below ever run, so there's no way for model output to introduce
// a real tag.
function renderFeedback(markdown) {
    const codeBlocks = [];
    let html = escapeHtml(markdown);

    // Fenced code blocks first, and stashed out, so a later rule (inline
    // code, bold) can't reach inside one and mangle code that itself
    // contains a backtick or asterisk (e.g. Haskell's infix `div`).
    html = html.replace(/```[^\n]*\n([\s\S]*?)```/g, (_, code) => {
        codeBlocks.push(`<pre><code>${code}</code></pre>`);
        return `\x00${codeBlocks.length - 1}\x00`;
    });

    const inline = (text) =>
        text
            .replace(/`([^`\n]+)`/g, "<code>$1</code>")
            .replace(/\*\*([^*\n]+)\*\*/g, "<strong>$1</strong>");

    // Within one blank-line-separated block, a run of "- "/"* " lines
    // becomes a <ul>, even directly following a lead-in line with no
    // blank line between them -- how feedback text commonly reads.
    function renderBlock(block) {
        const lines = block.split("\n");
        const parts = [];
        let buffer = [];
        let bufferIsList = null;
        const flush = () => {
            if (buffer.length === 0) return;
            if (bufferIsList) {
                const items = buffer.map((line) => inline(line.replace(/^[-*]\s+/, "")));
                parts.push(`<ul>${items.map((i) => `<li>${i}</li>`).join("")}</ul>`);
            } else {
                parts.push(`<p>${buffer.map(inline).join("<br>")}</p>`);
            }
            buffer = [];
        };
        for (const line of lines) {
            const isListLine = /^[-*]\s+/.test(line);
            if (bufferIsList !== null && isListLine !== bufferIsList) flush();
            bufferIsList = isListLine;
            buffer.push(line);
        }
        flush();
        return parts.join("\n");
    }

    html = html
        .split(/\n{2,}/)
        .map((block) => {
            const trimmed = block.trim();
            return /^\x00\d+\x00$/.test(trimmed) ? trimmed : renderBlock(trimmed);
        })
        .join("\n");

    return html.replace(/\x00(\d+)\x00/g, (_, i) => codeBlocks[Number(i)]);
}

function statusMessage(status) {
    switch (status) {
        case 403:
            return "Verification failed -- please try again.";
        case 413:
            return "That's too long -- try a shorter solution.";
        case 429:
            return "Too many requests right now -- please try again later.";
        default:
            return "Sorry, feedback isn't available right now. Please try again later.";
    }
}

function setupWidget(container) {
    const exerciseId = container.dataset.exerciseId;

    const toggle = document.createElement("button");
    toggle.type = "button";
    toggle.className = "exercise-feedback-toggle";
    toggle.textContent = "Get AI feedback on your answer";

    const panel = document.createElement("div");
    panel.className = "exercise-feedback-panel";
    panel.hidden = true;

    const textarea = document.createElement("textarea");
    textarea.className = "exercise-feedback-code";
    textarea.placeholder = "Paste your Haskell code here";

    const turnstileMount = document.createElement("div");
    turnstileMount.className = "cf-turnstile";

    const submit = document.createElement("button");
    submit.type = "button";
    submit.className = "exercise-feedback-submit";
    submit.textContent = "Get feedback";

    const result = document.createElement("div");
    result.className = "exercise-feedback-result";
    result.hidden = true;
    result.setAttribute("aria-live", "polite");

    panel.append(textarea, turnstileMount, submit, result);
    container.append(toggle, panel);

    let widgetId = null;

    toggle.addEventListener("click", async () => {
        const opening = panel.hidden;
        panel.hidden = !opening;
        if (opening && widgetId === null) {
            try {
                const turnstile = await loadTurnstile();
                widgetId = turnstile.render(turnstileMount, { sitekey: TURNSTILE_SITE_KEY });
            } catch {
                result.hidden = false;
                result.classList.add("is-error");
                result.textContent = "Couldn't load verification -- please reload the page and try again.";
            }
        }
    });

    submit.addEventListener("click", async () => {
        const code = textarea.value;
        result.classList.remove("is-error");
        if (code.length === 0) {
            result.hidden = false;
            result.textContent = "Paste your code above first.";
            return;
        }
        if (code.length > MAX_CODE_LENGTH) {
            result.hidden = false;
            result.classList.add("is-error");
            result.textContent = statusMessage(413);
            return;
        }
        const turnstileToken = window.turnstile && widgetId !== null
            ? window.turnstile.getResponse(widgetId)
            : null;
        if (!turnstileToken) {
            result.hidden = false;
            result.classList.add("is-error");
            result.textContent = "Please complete the verification above first.";
            return;
        }

        submit.disabled = true;
        result.hidden = false;
        result.classList.remove("is-error");
        result.textContent = "Getting feedback...";

        try {
            const response = await fetch(WORKER_URL, {
                method: "POST",
                headers: { "Content-Type": "application/json" },
                body: JSON.stringify({ exerciseId, code, turnstileToken }),
            });
            if (!response.ok) {
                result.classList.add("is-error");
                result.textContent = statusMessage(response.status);
            } else {
                const data = await response.json();
                result.innerHTML = renderFeedback(data.feedback);
            }
        } catch {
            result.classList.add("is-error");
            result.textContent = statusMessage(0);
        } finally {
            submit.disabled = false;
            if (window.turnstile && widgetId !== null) {
                window.turnstile.reset(widgetId);
            }
        }
    });
}

document.querySelectorAll(".exercise-feedback").forEach(setupWidget);
