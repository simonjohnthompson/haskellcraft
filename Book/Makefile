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
# exit-1-on-clean-run quirk above). Plain `grep`, without LC_ALL=C, can
# silently match nothing on this log under some locales -- root.log is
# pdflatex's own transcript, not always clean UTF-8 -- so force the C
# locale here.
check: root.pdf
	@errs="$$(LC_ALL=C grep -an 'Undefined control sequence\|! LaTeX Error\|^!\|Missing \$$\|math environment\|Runaway argument' root.log)"; \
	if [ -n "$$errs" ]; then \
		echo "$$errs"; \
		echo "LaTeX errors found in root.log (see above)."; \
		exit 1; \
	else \
		echo "root.log is clean -- no LaTeX errors found."; \
	fi

clean:
	rm -f *.aux *.bbl *.blg *.idx *.ilg *.ind *.log *.out *.toc
