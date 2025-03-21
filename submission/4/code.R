## -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#| include: false
#' ---
#' title: "Replication code for 'Making, Updating, and Querying Causal Models using CausalQueries'"
#' date: February 2025
#' author: Till Tietz, Lily Medina, Georgiy Syunyaev, and Macartan Humphreys
#' ---
#' 
#' Generated by `knitr::spin()` from `code.R`.
#' 
#' Note: final section of code for microbenchmarking is slow

#' ## Set up


## -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#| label: preamble
#| include: false

# knitr::purl("paper.qmd",  "code.R")
# knitr::spin("code.R")  
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



## -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#| echo: true

data("lipids_data")

lipids_data



## -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#| include: false
#' # Motivating example


## -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#| echo: true
#| eval: true
#| purl: true
#| message: false


lipids_model <-  make_model("Z -> X -> Y; X <-> Y") 



## -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#| echo: true
#| eval: true
#| purl: true
#| message: false

lipids_model <- update_model(lipids_model, lipids_data)



## -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#| echo: true
#| eval: true
#| purl: true

lipids_queries <-
  query_model(
    lipids_model,
    queries = list(
      ATE  = "Y[X=1] - Y[X=0]",
      PoC  = "Y[X=1] - Y[X=0] :|: X==0 & Y==0",
      LATE = "Y[X=1] - Y[X=0] :|: X[Z=1] > X[Z=0]"),
    using = "posteriors"
  )



## -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#| label: tbl-lipids
#| tbl-cap: "Replication of \\citet{chickering_clinicians_1996}."
#| echo: false

lipids_queries |>
  dplyr::select(label, query, given, mean, sd, starts_with("cred")) |>
  knitr::kable(
    digits = 2,
    booktabs = TRUE,
    align = "c",
    escape = TRUE, 
    linesep = "") |> 
  kableExtra::kable_classic_2(latex_options = c("scale_down"))

#' 


## -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#| fig-cap: "Illustration of queries plotted"
#| label: queryplot
#| fig-width: 8
#| fig-height: 3

lipids_queries |> plot()



## -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#| echo: true
#| eval: true
#| purl: true
#| message: false
#| output: false

make_model("Z -> X -> Y; X <-> Y") |>
  update_model(lipids_data) |>
  query_model(
    queries = list(
      ATE  = "Y[X=1] - Y[X=0]",
      PoC  = "Y[X=1] - Y[X=0] :|: X==0 & Y==0",
      LATE = "Y[X=1] - Y[X=0] :|: X[Z=1] > X[Z=0]"),
    using = "posteriors") |>
  plot()



## -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#| label: tbl-lipidspar
#| tbl-cap: "Nodal types and parameters for Lipids model."
#| echo: false

with_pars <- 
  lipids_model |>
  set_parameters(param_type = "prior_draw") 

with_pars |> grab("parameters_df") |>
  dplyr::select(node,  nodal_type, param_set, param_names, param_value, priors) |> 
  knitr::kable(
    digits = 2,
    booktabs = TRUE,
    align = "c",
    escape = TRUE,
    longtable = TRUE,
    linesep = "") |> 
  kableExtra::kable_classic_2(latex_options = c("hold_position"))



## -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#| include: false

#' # Making models


## -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#| echo: true
#| results: markup

model <- make_model("X -> M -> Y <- X")



## -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#| label: fig-plots
#| echo: true
#| out-width: 60%
#| fig-height: 6
#| fig-width: 4
#| fig-cap: "Examples of model graphs. For help on options see `?plot_model`"
#| fig-subcap:
#|   - "Without options"
#|   - "With options"
#| fig-pos: 'h'
#| layout-ncol: 2
#| results: hold
#| purl: true

lipids_model |> plot()

lipids_model |>
  plot(x_coord = 1:3,
       y_coord = 3:1,
       textcol = "black",
       textsize = 3,
       shape = c(15, 16, 16),
       nodecol = "lightgrey",
       nodesize = 10)



## -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#| include: false

#' ## Tailoring models


## -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#| label: tbl-dof
#| tbl-cap: "Number of different independent parameters (degrees of freedom) for different three-node models."
#| echo: false
#| eval: true

statements <- list("X -> Y <- W", 
                   "X -> Y <- W; X <-> W", 
                   "X -> Y <- W; X <-> Y; W <-> Y",
                   "X -> Y <- W; X <-> Y; W <-> Y; X <-> W", 
                   "X -> W -> Y <- X",
                   "X -> W -> Y <- X; W <-> Y",
                   "X -> W -> Y <- X; X <-> W; W <-> Y", 
                   "X -> W -> Y <- X; X <-> W; W <-> Y; X <-> Y")

dof <- function(statement) {
  make_model(statement, add_causal_types = FALSE) |>
  grab("parameters_df")  |>
  group_by(param_set) |>
  summarize(n  = n() - 1) |>
  pull(n) |>
  sum()
}
  

statements |> 
  lapply(function(s) paste0("`", s, "`")) |> 
  unlist() |> 
  data.frame(
    Model = _,
    dof = unlist(lapply(statements, dof))) |>
  knitr::kable(
    digits = 2,
    booktabs = TRUE,
    align = c("l", "c"),
    escape = TRUE, 
    linesep = "",
    col.names = c("Model", "Degrees of freedom")) 



## -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#| echo: true
#| eval: true

model_restricted <- 
  lipids_model |> 
  set_restrictions("X[Z=1] < X[Z=0]")



## -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#| label: set-restrictions1
#| echo: true
#| purl: true

model <- 
  lipids_model |>
  set_restrictions(labels = list(X = "01", Y = c("00", "01", "11")), 
                   keep = TRUE)



## -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#| label: set-restrictions2
#| echo: true
#| purl: true

model <- lipids_model |>
  set_restrictions(labels = list(Y = "?0"))



## -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#| label: set-restrictions3
#| echo: true
#| purl: true

model <- lipids_model |>
  set_restrictions(labels = list(Y = c('00', '11')), given = 'X.00')



## -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#| label: get-priors
#| echo: true
#| eval: true

lipids_model |> 
  inspect("prior_hyperparameters", nodes = "X") 



## -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#| label: set-priors
#| echo: true
#| purl: true

model <- lipids_model |> 
  set_priors(distribution = "jeffreys")



## -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#| label: set-priors-custom
#| echo: true
#| eval: true
#| message: false

lipids_model |> 
  set_priors(param_names = c("X.10", "X.01"), alphas = 3:4) |> 
  inspect("prior_hyperparameters", nodes = "X")



## -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#| label: set-priors-statement
#| echo: true
#| eval: true

lipids_model |>
  set_priors(statement = "X[Z=1] > X[Z=0]", alphas = 3) |>
  inspect("prior_hyperparameters", nodes = "X")



## -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#| label: set-priors-flat

query <- 
  make_model("X -> Y") |>
  set_restrictions(decreasing("X", "Y")) |>
  query_model("Y[X=1] - Y[X=0]", using = "priors")



## -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#| label: get-parameters
#| echo: true
#| eval: true

make_model("X -> Y") |> 
  inspect("parameters")



## -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#| label: set-parameters
#| echo: true
#| eval: true

make_model("X -> Y") |>
  set_parameters(statement = "Y[X=1] > Y[X=0]", parameters = .7) |>
  inspect("parameters")



## -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#| include: false

#' ## Drawing data


## -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#| label: make-data
#| echo: true
#| eval: true

lipids_model |> 
  make_data(n = 4)



## -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#| label: make-data-incomplete
#| echo: true
#| eval: true
#| message: false

sample_data <-
  lipids_model |>
  make_data(n = 8,
            nodes = list(c("Z", "Y"), "X"),
            probs = list(1, .5),
            subsets = list(TRUE, "Z==1 & Y==0"))



## -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#| label: collapse-data
#| echo: true
#| eval: true

sample_data |> 
  collapse_data(lipids_model)



## -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#| include: false

#' # Updating models


## -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#| echo: true
#| eval: true
#| purl: true

make_model("X -> Y") |> 
  inspect("parameter_mapping") 



## -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#| echo: true
#| eval: true
#| purl: true

data <- data.frame(X = rep(0:1, 5), Y = rep(0:1, 5))

list(
  uncensored = 
    update_model(make_model("X -> Y"),
                 data),
  censored = 
    update_model(make_model("X -> Y"), 
                 data, 
                 censored_types = c("X1Y0",  "X0Y1"))
  ) |>
  query_model("Y[X=1] - Y[X=0]", using = "posteriors")



## -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#| echo: true
#| purl: true

model <-
  make_model("X -> Y")  |> 
  update_model()

posterior <- inspect(model, "posterior_distribution")  



## -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#| echo: true
#| purl: true

lipids_model <- 
  lipids_model |> 
  update_model(keep_fit = TRUE,
               keep_event_probabilities = TRUE)



## -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#| eval: true
#| echo: true
#| purl: true

make_model("X -> Y")  |> 
  update_model(keep_type_distribution = FALSE) |>
  inspect("stan_summary") 



## -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#| label: preservewwarning
#| warning: false
model <- 
  make_model("X -> M -> Y") |>
  update_model(data = data.frame(X = rep(0:1, 10000), Y = rep(0:1, 10000)), 
               iter = 5000,
               refresh = 0)


## -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
model


## -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#| eval: true
#| echo: true
#| purl: true

model <- 
  make_model("X -> Y") |> 
  update_model(refresh = 0, keep_fit = TRUE)



## -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#| eval: true
#| echo: true
#| purl: true

model |> 
  inspect("stanfit")



## -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#| include: false

#' # Querying models


## -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#| label: realise-outcomes
#| echo: true

make_model("X -> Y") |> 
  realise_outcomes()



## -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#| label: realise-outcomes-do
#| echo: true

make_model("X -> Y") |> 
  realise_outcomes(dos = list(X = 1))



## -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

make_model("X -> Y")  |> 
  get_query_types("Y==1")



## -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

make_model("X -> Y")  |> 
  get_query_types("Y[X=1]==1")



## -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#| eval: true
#| echo: true

make_model("X1 -> Y <- X2")  |>
  get_query_types("X1==1 & X2==1 & (Y[X1=1, X2=1] > Y[X1=0, X2=0])")



## -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
make_model("X -> Y") |> 
  get_query_types("Y[X=1] - Y[X=0]")



## -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#| label: fig-posterior-dist
#| fig-cap: 'Posterior on "Probability $Y$ is increasing in $X$".'
#| fig-pos: "t"
#| fig-align: center
#| out-width: "60%"
#| purl: true

data  <- data.frame(X = rep(0:1, 50), Y = rep(0:1, 50))

model <- 
  make_model("X -> Y") |>
  update_model(data, iter  = 4000, refresh = 0)

model |> 
  grab("posterior_distribution")  |> 
  ggplot(aes(Y.01 - Y.10)) + geom_histogram() 



## -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#| echo: true

queries <- 
  make_model("X -> Y") |> 
  query_distribution(
    query = list(increasing = "(Y[X=1] > Y[X=0])",
                 ATE = "(Y[X=1] - Y[X=0])"), 
    using = "priors")



## -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#| label: case-level-query
#| echo: true
#| eval: true
#| purl: true
#| fig-height: 2
#| fig-width: 8

lipids_model |>
  query_model(
    query = "Y[X=1] - Y[X=0] :|: X==1 & Y==1 & Z==1",
    using = "posteriors") |>
  plot()



## -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#| echo: true
#| eval: true
#| purl: true
#| fig-height: 2.5
#| fig-width: 8

make_model("X -> M -> Y") |>
  update_model(data.frame(X = rep(0:1, 8), Y = rep(0:1, 8)), iter = 4000) |>
  query_model("Y[X=1] > Y[X=0] :|: X==1 & Y==1 & M==1", 
            using = "posteriors",
            case_level = c(TRUE, FALSE)) |>
  plot()



## -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#| label: batch-query
#| echo: true
#| eval: true

models <- list(
  Unrestricted = lipids_model |>
    update_model(data = lipids_data, refresh = 0),
  
  Restricted = lipids_model |>
    set_restrictions("X[Z=1] < X[Z=0]") |>
    update_model(data = lipids_data, refresh = 0)
)


## -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#| label: batch-query-fig
#| echo: true
#| eval: true

queries <- 
  query_model(
    models,  
    query = list(ATE = "Y[X=1] - Y[X=0]", 
                 POS = "Y[X=1] > Y[X=0] :|: Y==1 & X==1"),
    case_level = c(FALSE, TRUE),
    using = c("priors", "posteriors"),
    expand_grid = TRUE)



## -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#| label: tbl-batch-query
#| tbl-cap: "Results for two queries on two models."
#| echo: false
#| eval: true
#| message: false

queries |>
  dplyr::select(-starts_with("cred")) |> 
  knitr::kable(
    digits = 2,
    booktabs = TRUE,
    align = "c",
    escape = TRUE,
    longtable = TRUE,
    linesep = "") |> 
  kableExtra::kable_classic_2(latex_options = c("hold_position"))



## -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#| include: false
#' default plot associated with this query:


## -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#| label: fig-batch
#| fig-cap: "Default plotting for a a set of queries over multiple models."
#| fig-width: 8
#| fig-height: 4
#| echo: false
#| eval: true
#| message: false

queries |> plot()



## -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#| include: false

#' # Appendix


## -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#| include: false
#' ## illustrative code for parallelization


## -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
library(parallel)

options(mc.cores = parallel::detectCores())


## -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#| echo: true
library(future)
library(future.apply)

chains <- 3
cores <- 8

future::plan(list(
      future::tweak(future::multisession, 
                    workers = floor(cores/(chains + 1))),
      future::tweak(future::multisession, 
                    workers = chains)
    ))

model <- make_model("X -> Y")
data <- list(data_1 = data.frame(X=0:1, Y=0:1), 
             data_2 = data.frame(X=0:1, Y=1:0))

results <-
future.apply::future_lapply(
  data,
  function(d) {
    update_model(
      model = model,
      data = d,
      chains = chains,
      refresh = 0
    )},
 future.seed = TRUE)


## -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#| include: false
#' ## stan code


## -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#| echo: false
#| results: markup
#| comment: ""

CausalQueries:::stanmodels$simplexes



## -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#| include: false
#' ## benchmarking (slow)


## -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#| label: tbl-bench1
#| echo: false
#| warning: false
#| message: false
#| include:  true
#| eval: true

iter  <- 4000
times <- 5

#  effect of model complexity on run-time
model <- list(
  CausalQueries::make_model("X -> Y"),
  CausalQueries::make_model("X1 -> Y <- X2"),
  CausalQueries::make_model("X1 -> Y; X2 -> Y; X3 -> Y")
)

data <- expand_grid(X1 = 0:1, X2 = 0:1, X3 = 0:1) |>
  uncount(20) |>
  mutate(Y = 1*(X1 - X2*X3 + rnorm(n()) > 0))

options(mc.cores = parallel::detectCores())

benchmark_model <- microbenchmark::microbenchmark(
  m1 = CausalQueries::update_model(model[[1]], data, iter = iter),
  m2 = CausalQueries::update_model(model[[2]], data, iter = iter),
  m3 = CausalQueries::update_model(model[[3]], data, iter = iter),
  times = times
)

# Output
data.frame(
  Model = c("$X1 \\rightarrow Y$", 
            "$X1 \\rightarrow Y; X2 \\rightarrow Y$", 
            "$X1\\rightarrow Y;X2\\rightarrow Y;X3\\rightarrow Y$"),
  x = c(6, 20, 262),
  t = (benchmark_model |> summary() |> pull(mean))
) |> 
kable(escape = FALSE, digits = 2, 
  col.names= c("Model", "Number of parameters", "Runtime (seconds)"), 
  caption = "Benchmarking 1")



## -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#| label: tbl-bench2
#| echo: false
#| warning: false
#| message: false
#| include:  true
#| eval: true

# effect of data size on run-time
model <- CausalQueries::make_model("X -> Y")

data <- lapply(10^c(1:4), function(n) {
  CausalQueries::make_data(model, n)
})

benchmark_data <- microbenchmark::microbenchmark(
  d0 = CausalQueries::update_model(model, data[[1]], iter = iter),
  d1 = CausalQueries::update_model(model, data[[2]], iter = iter),
  d2 = CausalQueries::update_model(model, data[[3]], iter = iter),
  d3 = CausalQueries::update_model(model, data[[4]], iter = iter),
  times = times
)

# Output
data.frame(
  Model = c("$X1 \\rightarrow Y$", 
            "$X1 \\rightarrow Y$", 
            "$X1 \\rightarrow Y$", 
            "$X1 \\rightarrow Y$"),
  x = c(10, 100, 1000, 10000),
  t = (benchmark_data |> summary() |> pull(mean))
) |>
kable(escape = FALSE, digits = 2, 
  col.names= c("Model", "Number of observations", "Runtime (seconds)"), 
  caption = "Benchmarking 2")



