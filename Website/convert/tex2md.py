#!/usr/bin/env python3
"""LaTeX -> Markdown converter for the Haskell Craft book.

Preprocesses the book's custom LaTeX macros into something Pandoc's LaTeX
reader can parse cleanly, shells out to Pandoc for the actual conversion,
then post-processes the resulting Markdown (fenced code blocks, image
paths).

Usage:
    python3 tex2md.py <output-dir> <chapter.tex> [<chapter.tex> ...]

Requires pandoc on PATH. Figures referenced from Pictures/*.pdf need to be
converted to web-friendly images separately (e.g. via `sips` on macOS or
`pdftoppm`/`pdftocairo` from poppler) -- this script only rewrites the
Markdown to point at Pictures/<name>.png, it doesn't render them.
"""
import re
import subprocess
import sys
from pathlib import Path

BOOK_DIR = Path(__file__).resolve().parent.parent.parent / "Book"


def _find_matching_brace(s, open_pos):
    """Given the index of a real '{' in s, return the index just past its
    matching '}'. Skips escaped \\{ and \\} (e.g. inside \\minx{\\{-} for
    Haskell's `{-` comment delimiter) -- those are two-character literal
    tokens, not real grouping braces, even though the second character is
    itself a brace glyph.
    """
    assert s[open_pos] == "{"
    depth = 1
    j = open_pos + 1
    while depth > 0 and j < len(s):
        if s[j] == "\\" and j + 1 < len(s) and s[j + 1] in "{}":
            j += 2
            continue
        if s[j] == "{":
            depth += 1
        elif s[j] == "}":
            depth -= 1
        j += 1
    return j


def strip_balanced_macro(text, macro, replacement=lambda arg: ""):
    """Remove \\macro{...} where {...} may contain nested (and escaped)
    braces."""
    pattern = re.compile(r"\\" + re.escape(macro) + r"\{")
    while True:
        m = pattern.search(text)
        if not m:
            break
        start = m.start()
        j = _find_matching_brace(text, m.end() - 1)
        arg = text[m.end():j - 1]
        text = text[:start] + replacement(arg) + text[j:]
    return text


def strip_two_arg_macro(text, macro, fmt):
    """Remove \\macro{a}{b}, replacing with fmt(a, b). Each arg may itself
    contain balanced (and escaped) braces."""
    pattern = re.compile(r"\\" + re.escape(macro) + r"\{")

    def read_group(s, start):
        assert s[start] == "{"
        j = _find_matching_brace(s, start)
        return s[start + 1:j - 1], j

    while True:
        m = pattern.search(text)
        if not m:
            break
        start = m.start()
        arg1, after1 = read_group(text, m.end() - 1)
        if after1 >= len(text) or text[after1] != "{":
            break  # malformed use; bail rather than loop forever
        arg2, after2 = read_group(text, after1)
        text = text[:start] + fmt(arg1, arg2) + text[after2:]
    return text


def _load_subscript_shorthands():
    """miradefs.tex defines ~35 shorthand macros like \\vone, \\gtwo, \\ei
    as pre-filled \\subscr{letter}{index} calls (v1, v2, ..., vn, g1, g2,
    ... used in the book's generic-pattern pseudocode listings, e.g.
    `f v1 v2 ... vn`). Parse them from the source instead of hand-copying,
    so a future edit to miradefs.tex doesn't silently go stale here.
    """
    path = BOOK_DIR / "miradefs.tex"
    table = {}
    if not path.exists():
        return table
    for m in re.finditer(
        r"\\newcommand\{\\([a-zA-Z]+)\}\{\\(sub|super)scr\{([^{}]*)\}\{([^{}]*)\}\}",
        path.read_text(),
    ):
        name, kind, base, idx = m.groups()
        sep = "^" if kind == "super" else "_"
        table[name] = f"{base}{sep}{idx}"
    return table


SUBSCRIPT_SHORTHANDS = _load_subscript_shorthands()

# Plain LaTeX text-mode escapes that survive into code listings; only
# meaningful once we're inside a verbatim block (elsewhere pandoc's LaTeX
# reader already converts these on its own).
ESCAPED_CHARS = {
    r"\#": "#", r"\$": "$", r"\%": "%", r"\&": "&",
    r"\@": "@", r"\_": "_",
    r"\^{}": "^",
}

# \{ and \} (literal brace characters, e.g. \minx{\{-} for Haskell's `{-`
# comment delimiter) can't be unescaped to real '{'/'}' this early: the
# code block they're in is about to be spliced back into the full chapter
# text, which then goes through several more balanced-brace macro strips
# (\index, \minx, \ref, ...) scanning the *whole* document. A bare '}'
# sitting in what's now plain code-block text would be misread as closing
# some later, unrelated group. Placeholder now, swap back to real
# characters only once (in preprocess(), after all of that has run).
BRACE_PLACEHOLDER_OPEN = "\uE000"
BRACE_PLACEHOLDER_CLOSE = "\uE001"

# Bare zero-argument symbol/logic macros that show up inside code listings
# (mostly in the proof/property exercises, e.g. `\all{}x (square x = x*x)`).
SYMBOL_MACROS = {
    "dag": "†", "dagger": "†", "ddag": "‡",
    "geqq": "≥", "leqq": "≤", "lll": "≪", "eqq": "≡",
    "geq": "≥", "leq": "≤", "neq": "≠", "times": "×", "cdot": "·",
    "cup": "∪", "cap": "∩", "in": "∈", "notin": "∉", "subseteq": "⊆", "subset": "⊂",
    "Th": "Θ",
    "all": "∀", "allv": "∀", "exi": "∃", "forall": "∀", "exists": "∃",
    "ou": "∨", "an": "∧", "imp": "⇒", "no": "¬",
    "bi": "⇔", "turn": "⊢", "bo": "⊥", "se": "≡",
}

# Bare font/typeface declarations with no argument -- meaningless in a
# code block that's monospace already, so just drop the token.
FONT_DECLARATIONS = (
    "ttfamily", "itshape", "slshape", "bfseries", "rmfamily", "normalfont",
    "mi", "latt", "mytt", "smtt", "em", "tt", "bf", "rm", "it", "sl",
)


def simplify_alltt_body(body: str) -> str:
    """alltt lets LaTeX commands appear inside literal code (unlike
    verbatim); the book leans on that for right-aligned annotations
    (\\hfill\\textrm{...}), underlining a rewritten sub-term
    (\\underline{...}), literal backslashes in string literals (\\bs{n}
    for "\\n"), and subscript/superscript pseudocode notation (\\vone,
    \\subscr{g}{i}, ...) in generic function-pattern listings. verbatim
    won't interpret any of that, so flatten it all to plain text before
    the env swap.
    """
    # A couple of listings \input{} an external file (e.g. FirstScript.hs,
    # Pictures.tex) rather than duplicating its source in the chapter --
    # splice the real file in so the listing isn't left as a literal
    # "\input{...}" line. Those files are themselves pre-escaped for
    # direct inclusion in an alltt block (e.g. FirstScript.hs opens with
    # \{- ... -\} for Haskell's `{-` comment), so this must run first and
    # let the rest of this function process the splice normally.
    def _resolve_input(m):
        path = BOOK_DIR / m.group(1)
        if not path.exists():
            return m.group(0)
        return path.read_text()
    body = re.sub(r"\\input\{([^{}]+)\}", _resolve_input, body)

    # \\  (LaTeX hard linebreak) shows up inside \begin{tabbing} blocks used
    # for a couple of nested "scope box" diagrams (e.g. Chapter 4's boxed
    # where-clause trace) -- turn it into a real newline before anything
    # else touches single backslashes.
    body = body.replace("\\\\", "\n")

    # Inline/display math delimiters -- keep the content, drop the wrapper.
    # Must run before \bs{...} below: \bs{}\bs{}[x] (Haskell's \\ operator,
    # written as two separate literal-backslash macros because a raw "\\"
    # inside alltt would be read as a LaTeX linebreak) expands to two real
    # backslashes immediately followed by "[" -- if this math-delimiter
    # pass ran after that, it would misparse the second backslash + "[" as
    # a "\[" display-math opener and eat it.
    body = re.sub(r"\\\(|\\\)|\\\[|\\\]", "", body)
    body = re.sub(r"(?<!\\)\$([^$]*)\$", r"\1", body)

    body = re.sub(r"\\hfill\s*", "  -- ", body)

    if SUBSCRIPT_SHORTHANDS:
        shorthand_pat = re.compile(
            r"\\(" + "|".join(re.escape(k) for k in SUBSCRIPT_SHORTHANDS) + r")(?![a-zA-Z])"
        )
        body = shorthand_pat.sub(lambda m: SUBSCRIPT_SHORTHANDS[m.group(1)], body)

    body = strip_two_arg_macro(body, "subscr", lambda a, b: f"{a}_{b}")
    body = strip_two_arg_macro(body, "smsubscr", lambda a, b: f"{a}_{b}")
    body = strip_two_arg_macro(body, "superscr", lambda a, b: f"{a}^{b}")
    body = strip_two_arg_macro(body, "rule", lambda a, b: "")  # decorative spacer rule

    body = strip_balanced_macro(body, "bs", lambda arg: "\\" + arg)
    body = strip_balanced_macro(body, "up", lambda arg: "^" + arg)  # Chapter 20's local \up{n}
    body = strip_balanced_macro(body, "symbol", lambda arg: chr(int(arg)))
    body = strip_balanced_macro(body, "hspace", lambda arg: "    ")
    body = strip_balanced_macro(body, "hspace*", lambda arg: "    ")
    body = strip_balanced_macro(body, "vertline", lambda arg: "")  # decorative connector line
    body = strip_balanced_macro(body, "ensuremath", lambda arg: arg)

    # \begin{minipage}{1in}\begin{tabbing} ... \end{tabbing}\end{minipage}:
    # a boxed sub-diagram nested inside a code listing. We can't draw the
    # box in plain text, so drop the environment scaffolding and keep the
    # (now newline-broken, see above) content.
    body = re.sub(r"\\begin\{minipage\}(?:\{[^}]*\})?", "", body)
    body = re.sub(r"\\end\{minipage\}", "", body)
    body = re.sub(r"\\begin\{tabbing\}", "", body)
    body = re.sub(r"\\end\{tabbing\}", "", body)

    # {\rm text} / {\it text} / ... -- old-style bare font-switch group.
    # Requires a word boundary + real separator (space, or {} as in
    # `{\rm{}or}`) after the command name so this can't misfire on a
    # longer command sharing the same prefix, e.g. \ttfamily starting
    # with \tt.
    body = re.sub(r"\{\\(?:rm|it|sl|bf)(?![a-zA-Z])(?:\{\}|\s+)([^{}]*)\}", r"\1", body)

    body = body.replace(r"\ldots", "...")
    body = body.replace(r"\twid", "~")
    body = re.sub(r"\\bl(?![a-zA-Z])", "", body)  # forces a blank line in the listing
    body = re.sub(r"\\hrulefill", "", body)

    for name, symbol in SYMBOL_MACROS.items():
        body = re.sub(r"\\" + name + r"(?![a-zA-Z])(\{\})?", symbol, body)

    # A couple of spots in the book write \texttt[x] (square brackets) by
    # typo instead of \texttt{x}; strip_balanced_macro only handles the
    # brace form, so drop the bare command name and leave "[x]" as-is.
    body = re.sub(r"\\texttt(?=\[)", "", body)

    for macro in ("texttt", "textrm", "textbf", "textsl", "underline", "minx",
                  "mbox", "framebox"):
        body = strip_balanced_macro(body, macro, lambda arg: arg)

    for name in FONT_DECLARATIONS:
        body = re.sub(r"\\" + name + r"(?![a-zA-Z])", "", body)

    for esc, plain in ESCAPED_CHARS.items():
        body = body.replace(esc, plain)

    # See BRACE_PLACEHOLDER_OPEN/_CLOSE comment: don't unescape \{ / \}
    # to real brace characters yet, or they'd corrupt brace-depth counting
    # in the macro strips preprocess() still has to run over the whole
    # document (\index, \minx, \ref, ...). Swapped back to real braces at
    # the very end of preprocess().
    body = body.replace(r"\{", BRACE_PLACEHOLDER_OPEN).replace(r"\}", BRACE_PLACEHOLDER_CLOSE)

    return body


def strip_newcommand_defs(text):
    """A couple of chapters define their own local macro right in the
    chapter body (e.g. Chapter 20 opens with
    \\newcommand{\\up}[1]{\\ensuremath{{}^{\\mbox{\\footnotesize\\texttt #1}}}}).
    Left in, pandoc parses the \\newcommand fine but its own expansion of
    the resulting macro is unreliable and leaks raw LaTeX into inline code
    spans -- so drop the definition itself; usages are handled by our own
    rules below (e.g. \\up{X} -> "^X") instead of relying on pandoc to
    expand them.
    """
    pattern = re.compile(r"\\newcommand\{\\[a-zA-Z]+\}(?:\[[0-9]+\])?\{")
    while True:
        m = pattern.search(text)
        if not m:
            break
        depth = 1
        j = m.end()
        while depth > 0 and j < len(text):
            if text[j] == "{":
                depth += 1
            elif text[j] == "}":
                depth -= 1
            j += 1
        text = text[:m.start()] + text[j:]
    return text


def escape_bare_underscores_in_texttt(text):
    """A bare `_` outside math mode is invalid LaTeX (needs `\\_`), but a
    handful of \\texttt{...} calls in the book have one anyway -- real
    LaTeX seems to tolerate it, pandoc's reader does not ("unexpected _"),
    so escape it before pandoc ever sees it. We edit the argument in
    place (don't remove \\texttt{...} itself), so track position rather
    than repeatedly re-searching from the start.
    """
    pattern = re.compile(r"\\texttt\{")
    pos = 0
    while True:
        m = pattern.search(text, pos)
        if not m:
            break
        j = _find_matching_brace(text, m.end() - 1)
        arg = text[m.end():j - 1]
        fixed = re.sub(r"(?<!\\)_", r"\\_", arg)
        text = text[:m.end()] + fixed + text[j - 1:]
        pos = m.end() + len(fixed) + 1
    return text


def preprocess(tex):
    tex = strip_newcommand_defs(tex)
    tex = escape_bare_underscores_in_texttt(tex)

    # Code listings: \begin{alltt}...\end{alltt} -> \begin{minted}{haskell}...\end{minted}.
    # Two reasons this beats \verbatim: (1) pandoc's alltt reader chokes on
    # literal underscores, and a literal environment sidesteps that; (2) a
    # bare \verbatim produces an *indented* CodeBlock with no language, and
    # when one of those sits inside a list item pandoc indents its
    # continuation prose by the same 4 spaces as the code -- our own
    # indent-based fence detection couldn't tell them apart (see the
    # Chapter 19 "(Note that equation ...)" false-positive leak warning).
    # \minted{haskell} carries an explicit language class, so pandoc always
    # emits a real ``` fence for it, list-nesting or not.
    tex = re.sub(
        r"\\begin\{alltt\}(.*?)\\end\{alltt\}",
        lambda m: r"\begin{minted}{haskell}" + simplify_alltt_body(m.group(1)) + r"\end{minted}",
        tex,
        flags=re.DOTALL,
    )

    # Chapter 20's local \up{X} (mathematical superscript, e.g. n\up{2})
    # used inline in prose, not just inside code listings.
    tex = strip_balanced_macro(tex, "up", lambda arg: "^" + arg)

    # Index entries carry no reader-visible content -> drop entirely.
    tex = strip_balanced_macro(tex, "index", lambda arg: "")
    tex = strip_balanced_macro(tex, "minx", lambda arg: "")

    # Cross references: placeholder until we build a book-wide label map.
    tex = strip_balanced_macro(tex, "label", lambda arg: "")
    tex = strip_balanced_macro(tex, "ref", lambda arg: f"[REF:{arg}]")
    tex = strip_balanced_macro(tex, "pageref", lambda arg: f"[PAGEREF:{arg}]")
    tex = strip_balanced_macro(tex, "cite", lambda arg: f"[CITE:{arg}]")
    tex = strip_balanced_macro(tex, "citeyear", lambda arg: f"[CITE:{arg}]")

    # Book-specific glyphs/commands with no args.
    tex = tex.replace(r"\step", "~>")
    tex = tex.replace(r"\chapstart", "")
    tex = tex.replace(r"\ddag", "\u2021")  # double dagger

    # \parbox{width}{text} or \parbox\textwidth{text} (bare-macro width,
    # no braces -- valid LaTeX, but pandoc's reader doesn't handle it) is
    # a fixed-width box; for plain text we only want its content. Strip
    # "\parbox" plus its width arg (braced or a bare \command); the
    # remaining bare {text} group is just local scoping to pandoc, which
    # renders its content directly with no wrapper left behind.
    tex = re.sub(r"\\parbox(?:\\[a-zA-Z]+|\{[^{}]*\})(?=\{)", "", tex)
    tex = re.sub(r"\\leftskip\s*-?[0-9.]+[a-z]+\s*", "", tex)
    tex = re.sub(r"\\par(?![a-zA-Z])", "", tex)

    # Environments defined in root.tex that pandoc doesn't know about.
    tex = re.sub(r"\\begin\{titemize\}", r"\\begin{itemize}", tex)
    tex = re.sub(r"\\end\{titemize\}", r"\\end{itemize}", tex)
    tex = re.sub(r"\\begin\{summary\}", r"\\section*{Summary}", tex)
    tex = re.sub(r"\\end\{summary\}", r"", tex)
    tex = re.sub(r"\\begin\{(?:exercises|exerciseone)\}", r"\\textbf{Exercises}\n\\begin{enumerate}", tex)
    tex = re.sub(r"\\end\{(?:exercises|exerciseone)\}", r"\\end{enumerate}", tex)

    # Now safe to swap in real brace characters -- every pass above that
    # depends on brace-depth counting has already run.
    tex = tex.replace(BRACE_PLACEHOLDER_OPEN, "{").replace(BRACE_PLACEHOLDER_CLOSE, "}")

    return tex


WRAPPER = r"""\documentclass{book}
\usepackage{latexsym}
\usepackage{graphicx}
\begin{document}
%s
\end{document}
"""


def convert_chapter(src_path: Path, out_dir: Path):
    raw = src_path.read_text()
    cleaned = preprocess(raw)
    wrapped = WRAPPER % cleaned

    tmp_tex = out_dir / (src_path.stem + "_wrapped.tex")
    tmp_tex.write_text(wrapped)

    out_md = out_dir / (src_path.stem + ".md")
    result = subprocess.run(
        [
            "pandoc",
            "-f", "latex",
            "-t", "markdown-raw_tex",
            "--wrap=none",
            str(tmp_tex),
            "-o", str(out_md),
        ],
        cwd=BOOK_DIR,
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        print(result.stderr, file=sys.stderr)
        sys.exit(1)

    md = out_md.read_text()
    md = postprocess(md)
    out_md.write_text(md)
    warn_on_leaked_tex(src_path.name, md)
    return out_md


LEAK_PATTERN = re.compile(r"\\([a-zA-Z]+)")
# Legitimate Haskell uses backslash too: \x -> ... (lambda) and escape
# codes like \n, \t, \\ inside string literals. [a-zA-Z]+ greedily grabs
# any letters immediately following (e.g. "\nhippo" -> "nhippo"), so check
# just the first character against the single-char escape codes.
HASKELL_ESCAPE_FIRST_CHARS = set("ntrabfv0")
# Haskell's Show/Read for Char also spells out non-printable ASCII
# characters by their control-code mnemonic, e.g. "\EOT", "\DC3", "\FS"
# (a GHCi sample-output listing in Chapter 6 is full of these).
HASKELL_CONTROL_CODE_NAMES = {
    "NUL", "SOH", "STX", "ETX", "EOT", "ENQ", "ACK", "BEL", "BS", "HT",
    "LF", "VT", "FF", "CR", "SO", "SI", "DLE", "DC1", "DC2", "DC3", "DC4",
    "NAK", "SYN", "ETB", "CAN", "EM", "SUB", "ESC", "FS", "GS", "RS",
    "US", "SP", "DEL",
}


def warn_on_leaked_tex(chapter_name, md):
    """Fenced ```haskell blocks should be plain code; a stray backslash
    command in one means some alltt macro wasn't unwrapped by
    simplify_alltt_body, and will show up as broken syntax highlighting
    (and garbled text) instead of Haskell.
    """
    in_block = False
    for i, line in enumerate(md.split("\n"), start=1):
        if line.lstrip().startswith("```"):
            in_block = not in_block
            continue
        if not in_block:
            continue
        for m in LEAK_PATTERN.finditer(line):
            word = m.group(1)
            if word[0] in HASKELL_ESCAPE_FIRST_CHARS:
                continue
            # DC1..DC4 have a trailing digit LEAK_PATTERN's [a-zA-Z]+
            # won't capture, so "DC3" shows up here as just "DC".
            if word in HASKELL_CONTROL_CODE_NAMES or word == "DC":
                continue
            if "->" in line[m.end():]:
                continue  # \x -> ... lambda
            print(
                f"WARNING [{chapter_name}] possible leaked LaTeX in code block, line {i}: {line.strip()!r}",
                file=sys.stderr,
            )
            break


def postprocess(md: str) -> str:
    # \minted{haskell} makes pandoc emit ``` {.haskell} (its own attribute
    # syntax) -- normalize to the plain ```haskell info-string that GitHub
    # /Docusaurus/mdBook/VitePress's highlighters all key off of. Handles
    # blocks indented under a list item too (leading whitespace kept).
    md = re.sub(r"^(\s*)``` \{\.haskell\}\s*$", r"\1```haskell", md, flags=re.MULTILINE)

    # Pandoc's [text]{.underline} bracketed-span syntax isn't plain
    # CommonMark and can trip up MDX-based site generators -> plain HTML.
    md = re.sub(r"\[([^\[\]]*)\]\{\.underline\}", r"<u>\1</u>", md)

    # Bare \includegraphics (no \caption) gets pandoc's placeholder alt
    # text "image" -> drop it so html/mdx writers don't turn it into a
    # <figure><figcaption>image</figcaption></figure>.
    md = re.sub(r"!\[image\]\(", "![](", md)

    # Point image references at a web-friendly extension. This script
    # doesn't render the images itself -- convert Pictures/*.pdf to
    # Pictures/*.png separately (e.g. `sips -s format png` on macOS, or
    # `pdftoppm`/`pdftocairo` from poppler elsewhere) before publishing.
    md = re.sub(r"(Pictures/[A-Za-z0-9_.\-]+)\.pdf", r"\1.png", md)

    return md


if __name__ == "__main__":
    out_dir = Path(sys.argv[1]).resolve() if len(sys.argv) > 1 else Path(".").resolve()
    out_dir.mkdir(parents=True, exist_ok=True)
    for chapter in sys.argv[2:]:
        src = BOOK_DIR / chapter
        result = convert_chapter(src, out_dir)
        print(f"{src} -> {result}")
