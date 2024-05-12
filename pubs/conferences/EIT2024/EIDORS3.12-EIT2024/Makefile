pdflatex:=pdflatex -file-line-error -halt-on-error -shell-escape
latexmk:=latexmk -pdf -f -pdflatex="$(pdflatex)" -bibtex

eidors3p12-eit2024.pdf: horse-3D.pdf

horse-3D.pdf: horse-3D.pptx 
	soffice --convert-to pdf $<
	pdfcrop $@ $@

all: eidors3p12-eit2024.pdf

%.pdf: %.tex
	$(latexmk) $<

# Graph is generated as follows
#   Get a git svn clone of eidors
#   run git-loc.sh (. git-loc.sh)
#   in matlab, run graph_loc.m
