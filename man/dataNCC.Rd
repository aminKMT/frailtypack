
\name{dataNCC}
\docType{data}
\alias{dataNCC}

\title{Simulated data for recurrent events and a terminal event with weigths using nested case-control design}

\usage{data(dataNCC)}

\description{
This contains a simulated sample of of 819 subjects and 1510 observations. This dataset can be used to illustrate how to fit a joint frailty model for data from nested case-control studies.

}

\format{
  This data frame contains the following columns:
  \describe{
    \item{id}{identification of patient}
    \item{cov1}{dichotomous covariate (0,1)}
    \item{cov2}{dichotomous covariate (0,1)}
    \item{t.start}{start of interval}
    \item{t.stop}{end of interval (death or censoring time)}
    \item{gaptime}{time to event}
    \item{event}{recurrent event status (0:no, 1:yes)}
    \item{deathdays}{time of terminal event (death or right-censoring)}
    \item{death}{censoring status (0:alive, 1:death)}
    \item{ncc.wts}{weights for NCC design}
  }
}

\keyword{datasets}
