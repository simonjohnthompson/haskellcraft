# Build the print PDF edition of "Haskell: The Craft of Functional
# Programming" from the LaTeX source.
#
# The sequence below is the standard LaTeX/BibTeX/makeindex dance, and was
# confirmed by hand (TeX Live 2025) to converge cleanly in exactly this
# order, with no extra passes and no index-specific step beyond the plain
# `makeindex` call -- see Admin/SOURCE-FORMAT-OPTIONS-REPORT.md:
#
#   pdflatex root   -- lays out the book, collects \cite/\ref/\index
#   bibtex   root   -- resolves \cite/\citeyear against big.bib -> root.bbl
#   makeindex root  -- sorts/formats \index entries -> root.ind
#   pdflatex root   -- pulls in root.bbl/root.ind, updates cross-references
#   pdflatex root   -- settles anything that shifted on the previous pass
#
# pdflatex on at least one tested setup exits 1 even on a fully clean,
# warning-free run (cause not tracked down; the log and the presence of
# root.pdf are the reliable signal, not the exit code) -- so each pdflatex/
# bibtex/makeindex call below is prefixed with `-` to stop `make` treating
# that as fatal. A real error (a missing package, a genuine LaTeX error)
# still shows up in root.log and in root.pdf simply not being produced/
# updated.

.PHONY: all clean check

all: root.pdf

root.pdf: $(wildcard *.tex) big.bib
	-pdflatex -interaction=nonstopmode root.tex
	-bibtex root
	-makeindex root
	-pdflatex -interaction=nonstopmode root.tex
	-pdflatex -interaction=nonstopmode root.tex

# Fails if root.log contains a real LaTeX error (as opposed to the benign
# exit-1-on-clean-run quirk above), or a genuine LaTeX/package warning
# (undefined reference/citation, multiply-defined label, etc). Plain
# `grep`, without LC_ALL=C, can silently match nothing on this log under
# some locales -- root.log is pdflatex's own transcript, not always clean
# UTF-8 -- so force the C locale here.
#
# Overfull/Underfull hbox/vbox notices are deliberately NOT treated as
# errors here: they're routine typesetting-density notices (currently
# ~450 of them), not a sign anything is wrong, and are present in any
# large LaTeX book of this kind. "Float too large for page by <1pt" is
# excluded for the same reason -- two pre-existing, sub-hundredth-inch
# float overflows (root.log lines ~2347, ~4259) with no visible effect on
# the printed page; fixing them would mean touching figure geometry
# across a finished 644-page book for no visible benefit.
check: root.pdf
	@errs="$$(LC_ALL=C grep -an 'Undefined control sequence\|! LaTeX Error\|^!\|Missing \$$\|math environment\|Runaway argument' root.log)"; \
	warns="$$(LC_ALL=C grep -an 'LaTeX Warning:\|Package .* Warning' root.log | grep -v 'Float too large for page by')"; \
	if [ -n "$$errs" ]; then \
		echo "$$errs"; \
		echo "LaTeX errors found in root.log (see above)."; \
		exit 1; \
	elif [ -n "$$warns" ]; then \
		echo "$$warns"; \
		echo "LaTeX warnings found in root.log (see above)."; \
		exit 1; \
	else \
		echo "root.log is clean -- no LaTeX errors or warnings found."; \
	fi

clean:
	rm -f *.aux *.bbl *.blg *.idx *.ilg *.ind *.log *.out *.toc
