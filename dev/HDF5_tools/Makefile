## This makefile builds the documentation 
## published at the EIT Conference, June 2023, Aachen, Germany

OUT= HDF5-format.pdf
all: $(OUT)

FIGLOC= https://docs.google.com/presentation/d/12R-ZI4NQ_jZgp0ehc_6n95pHN2EpzGdq8CS3XzD9b9M/export/pdf

$(OUT): figures.pdf

figures.pdf:
	wget -O $@ $(FIGLOC)
	pdfcrop $@ $@

$(OUT): %.pdf: %.tex
	latexmk -pdf --halt-on-error $<
