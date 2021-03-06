
\name{plot.longiPenal}
\Rdversion{1.1}
\alias{plot.longiPenal}
\alias{lines.longiPenal}


\title{Plot Method for a joint model for longitudinal data and a terminal event.}

\description{
  Plots estimated baseline survival and hazard functions for a terminal outcome from an object of class 'longiPenal'. Confidence bands are allowed.
}

\usage{

\method{plot}{longiPenal}(x, type.plot = "Hazard", conf.bands=TRUE, pos.legend=
	"topright", cex.legend=0.7, main, color, Xlab = "Time", 
	Ylab = "Hazard function", ...)

}

\arguments{
  \item{x}{ A joint model for longitudinal outcome and a terminal event, i.e. a \code{longiPenal} class object (output from calling \code{longiPenal}
    function).}
  \item{type.plot}{ a character string specifying the type of curve for the terminal event. Possible
                   value are "Hazard", or "Survival". The default
                   is "Hazard". Only the first words are required, e.g "Haz", "Su"}
  \item{conf.bands}{ Logical value. Determines whether confidence bands will be plotted.  The default is to do so.}
 \item{pos.legend}{The location of the legend can be specified by setting this argument to a single keyword from the list '"bottomright"', '"bottom"', '"bottomleft"', '"left"', '"topleft"', '"top"', '"topright"', '"right"' and
     '"center"'. The default is '"topright"'}
  \item{cex.legend}{character expansion factor *relative* to current
          'par("cex")'. Default is 0.7}
  \item{main}{title of plot}
  \item{color}{color of the curve (integer)} 
  \item{Xlab}{Label of x-axis. Default is '"Time"'}  
  \item{Ylab}{Label of y-axis. Default is '"Hazard function"'}
  \item{...}{other unused arguments}
}

\value{
     Print a plot for the terminal event of the joint model for a longitudinal and survival data.
}

\seealso{
 \code{\link{longiPenal}}
}

\examples{

\dontrun{
###--- Joint model for longitudinal data and a terminal event ---###

data(colorectal)
data(colorectalLongi)

# Survival data preparation - only terminal events 
colorectalSurv <- subset(colorectal, new.lesions == 0)

# Baseline hazard function approximated with splines
# Random effects as the link function

model.spli.RE <- longiPenal(Surv(time1, state) ~ age + treatment + who.PS 
+ prev.resection, tumor.size ~  year * treatment + age + who.PS ,
colorectalSurv,	data.Longi = colorectalLongi, random = c("1", "year"),
id = "id", link = "Random-effects", left.censoring = -3.33, 
n.knots = 7, kappa = 2)
pdf(file = "/home/agareb1/etudiants/al10/newpack/test/plot_longi.pdf")

# Plot the estimated baseline hazard function with the confidence intervals
plot(model.spli.RE)	

# Plot the estimated baseline hazard function with the confidence intervals
plot(model.spli.RE, type = "Survival")	
}

}

\keyword{ file }
