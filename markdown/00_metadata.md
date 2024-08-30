---
title: Pandoc Boilerplate
subtitle: Markdown file that will be converted
author: Aaron Gobeyn
abstract: |
  Lorem ipsum dolor sit amet, officia excepteur ex fugiat reprehenderit
  enim labore culpa sint ad nisi Lorem pariatur mollit ex esse
  exercitation amet. Nisi anim cupidatat excepteur officia. Reprehenderit
  nostrud nostrud ipsum Lorem est aliquip amet voluptate voluptate dolor
  minim nulla est proident. Nostrud officia pariatur ut officia. Sit irure
  elit esse ea nulla sunt ex occaecat reprehenderit commodo officia dolor
  Lorem duis laboris cupidatat officia voluptate. Culpa proident
  adipisicing id nulla nisi laboris ex in Lorem sunt duis officia eiusmod.
  Aliqua reprehenderit commodo ex non excepteur duis sunt velit enim.
  Voluptate laboris sint cupidatat ullamco ut ea consectetur et est culpa
  et culpa duis.
geometry:
- top=30mm
- left=20mm
- right=20mm
- bottom=30mm
numbersections: true
autoEqnLabels: true
natbiboptions: |
    ```{=latex}
    numbers,square,sort&compress
    ```
biblio-style: unsrtnat
header-includes: |
    ```{=latex}
    % Macros
    \newcommand{\br}[1]{{\left(#1\right)}}
    \newcommand{\brc}[1]{{\left\{#1\right\}}}
    \newcommand{\brs}[1]{{\left[#1\right]}}
    \newcommand{\etal}[1]{#1~\emph{et~al.}}

    % Force figure to location where specified in text
    \usepackage{float}
    \let\origfigure\figure
    \let\endorigfigure\endfigure
    \renewenvironment{figure}[1][2] {
        \expandafter\origfigure\expandafter[H]
    } {
        \endorigfigure
    }
    ```
---
