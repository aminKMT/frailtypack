
% --- Source file: plot.jointPenal.Rd ---
\name{plot.jointPenal}
\Rdversion{1.1}
\alias{plot.jointPenal}
\alias{lines.jointPenal}


\title{Plot Method for a Joint frailty model.}

\description{
  Plots estimated baseline survival and hazard functions of a joint frailty model (output from an object of class 'frailtyPenal' for joint frailty models ) for each type of event (terminal or recurrent). Confidence bands are allowed. 
}

\usage{

\method{plot}{jointPenal}(x, event = "both", type.plot = "hazard", conf.bands
                 = FALSE, pos.legend="topright", cex.legend=0.7, ylim, main, ...)


}

\arguments{
  \item{x}{ A joint model, or more generaly an object of class \code{frailyPenal for Joint frailty model} (output from calling \code{frailtyPenal}
    function).}
 \item{event}{ a character string specifying the type of curve. Possible
                   value are "terminal", "recurrent", or "both". The default
                   is "both".}
  \item{type.plot}{ a character string specifying the type of curve. Possible
                   value are "hazard", or "survival". The default
                   is "hazard". Only the first words are required, e.g "haz", "su"}
  \item{conf.bands}{ logical value. Determines whether confidence bands will be plotted. The default is to do so.}
 \item{pos.legend}{The location of the legend can be specified by setting this argument to a single keyword from the list '"bottomright"', '"bottom"', '"bottomleft"', '"left"', '"topleft"', '"top"', '"topright"', '"right"' and
     '"center"'. The default is '"topright"'}
  \item{cex.legend}{character expansion factor *relative* to current
          'par("cex")'. Default is 0.7}
  \item{ylim}{y-axis limits}
  \item{main}{plot title}
  \item{\dots}{ Other graphical parameters}
}

\value{
     Print a plot of the baseline survival or hazard functions for each type of event or both with the confidence bands or not (conf.bands argument)
}

\seealso{\code{\link{print.jointPenal}},\code{\link{summary.jointPenal}},\code{\link{frailtyPenal for Joint frailty models}}

}


\examples{


\dontrun{

  data(readmission)

## Gap-time ##
modJoint_gap<-frailtyPenal(Surv(time,event)~cluster(id)+sex+as.factor(dukes)
		+as.factor(charlson)+terminal(death),
		formula.terminalEvent=~sex+as.factor(dukes)+as.factor(charlson),
		data=readmission,n.knots=14,kappa1=9550000000,
		kappa2=1410000000000,Frailty=TRUE,joint=TRUE,recurrentAG=FALSE)


# It takes around 1 minute to converge. #


plot(modJoint_gap,type.plot="haz",event="recurrent",conf.bands=TRUE)
plot(modJoint_gap,type.plot="haz",event="terminal",conf.bands=TRUE)
plot(modJoint_gap,type.plot="haz",event="both",conf.bands=TRUE))
plot(modJoint_gap,type.plot="su",event="recurrent",conf.bands=TRUE))
plot(modJoint_gap,type.plot="su",event="terminal",conf.bands=TRUE))
plot(modJoint_gap, event="terminal",type.plot="su",conf.bands=TRUE))
plot(modJoint_gap,type.plot="su","terminal",conf.bands=TRUE))

}


}

\keyword{methods}