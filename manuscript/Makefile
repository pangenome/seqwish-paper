all: main.pdf

main.pdf: main.tex main.bbl fig/* *.tex
	pdflatex main.tex </dev/null
	pdflatex main.tex </dev/null

main.bbl: document.bib
	pdflatex main </dev/null
	bibtex main </dev/null

clean:
	rm -f main.aux main.toc main.pdf main.log main.bbl main.blg
