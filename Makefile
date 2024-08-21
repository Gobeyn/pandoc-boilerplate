# Variables
MD_DIR=markdown
BIB_FILE=references.bib
TEX_FILE=main.tex
PDF_FILE=main.pdf
PDF_COMPILER=latexmk
AUX_DIR=/tmp/latexmk/

# Targets
all: $(TEX_FILE) $(PDF_FILE)

# $@: Automatic Variable: Filename of rule target
# $<: Automatic Variable: Filename of first prerequisite
# $^: Automatic Variable: Filename of all prerequisites separated by spaces
# word: Text Function: $(word n, text) extracts the nth word from the text
$(TEX_FILE): $(MD_DIR) $(BIB_FILE)
	pandoc $</*.md -o $@ --filter=pandoc-crossref --standalone --natbib --bibliography=$(word 2, $^)
# Create directory for auxiliary files and remove it afterwards, compile with provided .tex to .pdf compiler
$(PDF_FILE): $(TEX_FILE)
	mkdir -p '$(AUX_DIR)'
	$(PDF_COMPILER) $< -quiet -aux-directory='$(AUX_DIR)' -pdf -interaction=nonstopmode -f -time
	rm -r '$(AUX_DIR)'
# Remove reproducible files
clean:
	rm $(TEX_FILE) $(PDF_FILE)
# Phony targets
.PHONY: all clean
