pdflatex:=pdflatex -file-line-error -halt-on-error -shell-escape
latexmk:=latexmk -pdf -f -pdflatex="$(pdflatex)" -bibtex

FIGURES=figures-EIDORS-v3.13
#https://zenodo.org/records/19702540/files/figures-EIDORS-v3.13.pptx?download=1

all: eidors3p13-eit2026.pdf

eidors3p13-eit2026.pdf: $(FIGURES).pdf

%.pdf: %.tex
	$(latexmk) $<
	gs -sDEVICE=pdfwrite -dPrinted=false -dCompatibilityLevel=1.8 -dNOPAUSE -dQUIET -dBATCH -sOutputFile=$@-- $@
	mv $@-- $@

$(FIGURES).pptx:
	wget https://zenodo.org/records/19702540/files/$(FIGURES).pptx?download=1 -O $(FIGURES).pptx

$(FIGURES).pdf: %.pdf: %.pptx
	soffice --convert-to pdf $<
	pdfcrop $@ $@

# Graph is generated as follows
#   Get a git svn clone of eidors
#   run git-loc.sh (. git-loc.sh)
#   in matlab, run graph_loc.m
