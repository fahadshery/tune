% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/tune_Bayes.R
\name{tune_Bayes}
\alias{tune_Bayes}
\alias{tune_Bayes.default}
\alias{tune_Bayes.recipe}
\alias{tune_Bayes.formula}
\alias{tune_Bayes.workflow}
\title{Bayesian optimization of model parameters.}
\usage{
tune_Bayes(object, ...)

\method{tune_Bayes}{default}(object, ...)

\method{tune_Bayes}{recipe}(object, model, rs, iter = 10,
  param_info = NULL, perf = NULL, objective = exp_improve(),
  initial = NULL, control = Bayes_control(), ...)

\method{tune_Bayes}{formula}(formula, model, rs, iter = 10,
  param_info = NULL, perf = NULL, objective = exp_improve(),
  initial = NULL, control = Bayes_control(), ...)

\method{tune_Bayes}{workflow}(object, model = NULL, rs, iter = 10,
  param_info = NULL, perf = NULL, objective = exp_improve(),
  initial = NULL, control = Bayes_control(), ...)
}
\arguments{
\item{object}{A model workflow, R formula or recipe object.}

\item{...}{Not currently used.}

\item{model}{A \code{parsnip} model specification (or \code{NULL} when \code{object} is a
workflow).}

\item{rs}{An \code{rset()} object. This argument \strong{should be named}.}

\item{iter}{The maximum number of search iterations.}

\item{param_info}{A \code{dials::parameters()} object or \code{NULL}. If none is given,
a parameters set is derived from other arguments.}

\item{perf}{A \code{yardstick::metric_set()} object containing information on how
models will be evaluated for performance. The first metric in \code{perf} is the
one that will be optimized.}

\item{objective}{A character string for what metric should be optimized or
an acquisition function object.}

\item{initial}{An initial set of results in a tidy format.}

\item{control}{A control object created by \code{Bayes_control()}}

\item{formula}{A traditional model formula.}
}
\value{
A tibble of results that mirror those generated by \code{tune_grid()}.
However, these results contain an \code{.iter} column and replicate the \code{rset}
object multiple times over iterations (at limited additional memory costs).
}
\description{
\code{tune_Bayes()} uses models to generate new candidate tuning parameter
combinations based on previous results.
}
\details{
The optimization starts with a set of initial results, such as those
generated by \code{tune_grid()}. If none exist, the function will create several
combinations and obtain their performance estimates.

Using one of the performance estimates as the \emph{model outcome}, a Gaussian
process (GP) model is created where the previous tuning parameter combinations
are used as the predictors.

A large grid of potential hyperparameter combinations is predicted using
the model and scored using an \emph{acquisition function}. These functions
usually combine the predicted mean and variance of the GP to decide the best
parameter combination to try next. For more information, see the
documentation for \code{exp_improve()} and the corresponding package vignette.

The best combination is evaluated using resampling and the process continues.

TODO notes on when to use, pluses and minuses.
}
