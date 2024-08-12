# Pandoc boilerplate
Boilerplate for Markdown to LaTeX and PDF conversion using `pandoc`. The Markdown language is relatively simple, see the essentials on their 
[website](https://www.markdownguide.org/cheat-sheet/). Using `pandoc`, the more complex LaTeX file format can be generated and further compiled 
with your preferred LaTeX to PDF converter. With Markdown we achieve almost the same results as with LaTeX, though much less writing is required.

## Requirements

The following tools are used and need to be installed in order to use this boilerplate.
- [GNU Make](https://www.gnu.org/software/make/)
- [Pandoc](https://pandoc.org/)
- [Pandoc Crossref](https://archlinux.org/packages/extra/x86_64/pandoc-crossref/)
- [TexLive](https://www.tug.org/texlive/)

## Compilation

For easy compilation, e.g. conversion from a `.md` to a `.tex` and `.pdf` file, we use a `Makefile`. Simply run:
```
$ make
```
To clean reproducible files, i.e. the generated `.tex` and `.pdf` file run:
```
$ make clean
```

## Files

The two files that should be edited are the `main.md` and `main.bib` files, the former for writing the document in the Markdown language and 
the latter for `bibtex` references.

## Figures

Figures are assumed to be placed in the `figures` folder. For pixel based graphics, it is recommended to use PNG files (300 dpi). For vector 
graphics, use PDF files.

## Citations

Citations should be contained in the `main.bib` file following the `bibtex` format, which is readily available for most research papers listed on 
[Google scholar](https://scholar.google.be/).

## Notes

- To create labels for sections, equations, figures, etc. use \{\#sec:foo\}, and to reference said label use \[\@sec:foo\], naturally,
replace 'sec' with 'eq' for equations, 'fig' for figures, etc.
- Citations follow the same format, \[@foo\] where 'foo' is the name given to the citation in the `main.bib` file.
- Images can be includes with \!\[caption\]\(path/to/image\)\{\#fig:foo .class width=50\% height=50\%\}. The first brackets
give a caption to the image. The second contains the file path to the image we want to display and the last brackets define the
label for the figure used to refer to it, along with `css` type styling, for instance, to size the image.

## Makefile documentation

- Quick reference to [Automatic variables](https://www.gnu.org/software/make/manual/make.html#Automatic-Variables)
- Quick reference to [Text Functions](https://www.gnu.org/software/make/manual/html_node/Text-Functions.html)
