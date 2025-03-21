#' ---
#' title: "Replication code for 'Making, Updating, and Querying Causal Models using CausalQueries'"
#' date: November 2024
#' author: Till Tietz, Lily Medina, Georgiy Syunyaev, and Macartan Humphreys
#' ---
#'
#' Generated by `knitr::spin()`.
#'


#' ## Set up

## ----------------------------------------------------------------------------------------------------------------------------------------------------
#| label: preamble
#| include: true
#| warning: false

library(tidyverse)
library(CausalQueries)
library(microbenchmark)
library(parallel)
library(future)
library(future.apply)
library(knitr)
library(rstan)

options(kableExtra.latex.load_packages = FALSE)
library(kableExtra)
options(mc.cores = parallel::detectCores())

set.seed(1, "L'Ecuyer-CMRG")
theme_set(theme_bw())

#+ include=TRUE, eval = TRUE

data <- data.frame(Y = rnorm(10), X = rnorm(10))
benchmark_model <- microbenchmark::microbenchmark(
  m1 = lm(Y~X,  data = data),
  m2= lm(Y~X,  data = data),
  times = 5
)

benchmark_model

print(summary(benchmark_model))


kable(summary(benchmark_model), digits = 2)
