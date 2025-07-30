library(quarto)
library(knitr)
library(tinytex)

quarto::quarto_render("paper.qmd", output_format = "all")

# generate replication R code
knitr::purl("paper.qmd",  "code.R")

# run formating fixes
source("paper_fix_format.R")

# compile CQ_JSS.tex
tinytex::latexmk("CQ_JSS.tex", engine = "xelatex")

# spin the original replicate code into HTML
knitr::spin("code.R", precious = TRUE, format = "qmd")
