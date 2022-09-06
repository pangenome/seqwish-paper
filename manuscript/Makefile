all: fig_induction.pdf main.pdf

fig_induction.pdf: fig_induction.tex
	pdflatex fig_induction.tex </dev/null

main.pdf: main.tex document.bib fig/* *.tex
	pdflatex main </dev/null
	bibtex main </dev/null
	pdflatex main.tex </dev/null
	pdflatex main.tex </dev/null

clean:
	rm -f main.aux main.toc main.pdf main.log main.bbl main.blg fig_induction.aux fig_induction.pdf fig_induction.log
