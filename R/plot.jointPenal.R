"plot.jointPenal" <-
function (x, event="both", type.plot="hazard", conf.bands=FALSE, pos.legend="topright", cex.legend=0.7, ylim, main, ...) 
{
  
   event.type <- charmatch(event, c("both", "recurrent", "terminal"), nomatch = 0)
    if (event.type == 0) {
        stop("event must be 'both', 'recurrent' or 'terminal'")
    }


   plot.type <- charmatch(type.plot, c("hazard", "survival"), 
        nomatch = 0)
    if (plot.type == 0) {
        stop("estimator must be 'hazard' or 'survival'")
    }


  if(missing(main))
   main<-"" 

  if (event.type==1)
    {
     if(plot.type==1)
      {
       if (missing(ylim))
        {
         yymax<-max(c(x$lam, x$lam2),na.rm=TRUE)
         yymin<-min(c(x$lam, x$lam2),na.rm=TRUE)
        }
       else
        {
         yymax<-ylim[2] 
         yymin<-ylim[1]
        }

        if (conf.bands)
          {
            matplot(x$x1, x$lam, col="red", type="l", lty=c(1,2,2), xlab="Time",
                ylab="Hazard function", ylim=c(yymin,yymax), main=main, ...)
            matlines(x$x2, x$lam2, col="blue", type="l", lty=c(1,2,2), ...)
           }

        else
          {
            plot(x$x1, x$lam[,1], col="red", type="l", lty=c(1,2,2), xlab="Time",
                ylab="Hazard function", ylim=c(yymin,yymax), main=main,...)

            lines(x$x2, x$lam2[,1], col="blue", type="l", lty=c(1,2,2), xlab="Time",
                ylab="Hazard function", ...)
          } 
      }        
    
     else
      {

       if (missing(ylim))
        {
         yymax<-1
         yymin<-0
        }
       else
        {
         yymax<-ylim[2] 
         yymin<-ylim[1]
        }

        if (conf.bands)
         {
           matplot(x$x1, x$surv, col="red", type="l", lty=c(1,2,2), xlab="Time",
                ylab="Baseline survival function", ylim=c(yymin,yymax), main=main,...)
           matlines(x$x2, x$surv2, col="blue", type="l", lty=c(1,2,2), ...)
         } 
        
        else
         {        
           plot(x$x1, x$surv[,1], col="red", type="l", lty=c(1,2,2), xlab="Time",
                ylab="Baseline survival function", ylim=c(yymin,yymax), main=main,...)
           lines(x$x2, x$surv2[,1], col="blue", type="l", lty=c(1,2,2), ...)
         }

      }        
        legend(pos.legend, c("recurrent events", "terminal event"), lty=c(1,1),col=c("red","blue"), xjust=1, cex=cex.legend, ...)

   }


  if (event.type==2)
    {

     if (missing(ylim))
      ylim <- c(0,1)

     if(plot.type==1)
      {

        if (conf.bands)
          {
            matplot(x$x1, x$lam, col="red", type="l", lty=c(1,2,2), xlab="Time",
                ylab="Hazard function", ylim=ylim, main=main,...)
           }

        else
          {
            plot(x$x1, x$lam[,1], col="red", type="l", lty=c(1,2,2), xlab="Time",
                ylab="Hazard function", ylim=ylim, main=main,...)
          } 
      }        
    
     else
      {
        if (conf.bands)
         {
           matplot(x$x1, x$surv, col="red", type="l", lty=c(1,2,2), xlab="Time",
                ylab="Baseline survival function", ylim=ylim, main=main,...)
         } 
        
        else
         {        
           plot(x$x1, x$surv[,1], col="red", type="l", lty=c(1,2,2), xlab="Time",
                ylab="Baseline survival function", ylim=ylim, main=main,...)
         }

      }        
        legend(pos.legend, c("recurrent events"), lty=c(1),col=c("red"), xjust=1, cex=cex.legend, ...)
   }




  if (event.type==3)
    {

     if (missing(ylim))
      ylim <- c(0,1)

     if(plot.type==1)
      {

        if (conf.bands)
          {
            matplot(x$x1, x$lam2, col="red", type="l", lty=c(1,2,2), xlab="Time",
                ylab="Hazard function", ylim=ylim, main=main,...)
           }

        else
          {
            plot(x$x1, x$lam2[,1], col="red", type="l", lty=c(1,2,2), xlab="Time",
                ylab="Hazard function", ylim=ylim, main=main,...)
          } 
      }        
    
     else
      {
        if (conf.bands)
         {
           matplot(x$x1, x$surv2, col="red", type="l", lty=c(1,2,2), xlab="Time",
                ylab="Baseline survival function", ylim=ylim, main=main,...)
         } 
        
        else
         {        
           plot(x$x1, x$surv2[,1], col="red", type="l", lty=c(1,2,2), xlab="Time",
                ylab="Baseline survival function", ylim=ylim, main=main,...)
         }

      }        
        legend(pos.legend, c("terminal event"), lty=c(1), col=c("red"), xjust=1, cex=cex.legend,...)
   }


    return(invisible())
}