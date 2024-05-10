OUT =  $(patsubst %.tex,%.pdf, $(wildcard *.tex))
all: $(OUT)

GSOUT= -sDEVICE=pdfwrite -dCompatibilityLevel=1.5 -dNOPAUSE -dQUIET -dBATCH -sOutputFile=out-gsshrink.pdf


FIGNUM=1baOZDPVuhdqgLA-Nj4clVQkoNmhFKIOuyrqy0bQ7fTU
FIGLOC= https://docs.google.com/presentation/d/$(FIGNUM)/export/pdf

figures.pdf:
	wget -O $@ $(FIGLOC)
	pdfcrop $@ $@

$(OUT): figures.pdf

$(OUT): %.pdf: %.tex
	latexmk -pdf --halt-on-error $<
	gs $(GSOUT) $@ && mv out-gsshrink.pdf $@

