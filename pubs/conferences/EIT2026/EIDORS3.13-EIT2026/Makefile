pdflatex:=pdflatex -file-line-error -halt-on-error -shell-escape
latexmk:=latexmk -pdf -f -pdflatex="$(pdflatex)" -bibtex

FIGURES=figures-EIDORS-v3.13.pdf

all: eidors3p13-eit2026.pdf $(FIGURES)

%.pdf: %.tex
	$(latexmk) $<

$(FIGURES): %.pdf: %.pptx
	soffice --convert-to pdf $<
	pdfcrop $@ $@

# Graph is generated as follows
#   Get a git svn clone of eidors
#   run git-loc.sh (. git-loc.sh)
#   in matlab, run graph_loc.m
