% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/tune.R
\name{tune}
\alias{tune}
\title{A placeholder function for argument values that are to be tuned.}
\usage{
tune(id = "")
}
\arguments{
\item{id}{A single character value that can be used to differentiate
parameters that are used in multiple places but have the same name, or if
the user wants a note associated with the parameter.}
}
\value{
A call object that echos the user input.
}
\description{
\code{tune()} is used when a parameter will be specified at a later date.
}
\examples{
tune()
class(tune())
tune("your name here")

}
