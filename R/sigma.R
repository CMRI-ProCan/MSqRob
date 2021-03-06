
#Method to calculate sigma for lm models, based on summary, so you don't have to call summary all the time
#Use MSqRob::sigma(test) for linear models if lme4 is loaded!


setGeneric (
  name= "getSigma",
  def=function(object,...){standardGeneric("getSigma")}
)

.getSigmaMermod <- function(object){
  
  sigma <- attr(object,"MSqRob_sigma")
  
  if(is.null(sigma)){
    # With the newest version of lme4, "sigma" is now part of the "stats" package
    # For some reason, "sigma" alone does not always work
    sigma <- try(stats::sigma(object), silent = TRUE)
    if(class(sigma) == "try-error"){
    sigma <- try(lme4::sigma(object), silent = TRUE)
  }
}
  
  return(sigma)
}

#' @export
setMethod("getSigma", "lmerMod", .getSigmaMermod)

.getSigmaLm <- function(object){

  sigma <- attr(object,"MSqRob_sigma")

  if(is.null(sigma)){
    z <- object
    p <- z$rank
    rdf <- z$df.residual
    if (p == 0) {
      r <- z$residuals
      n <- length(r)
      w <- z$weights
      if (is.null(w)) {
        rss <- sum(r^2)
      }
      else {
        rss <- sum(w * r^2)
        #r <- sqrt(w) * r
      }
      resvar <- rss/rdf
      sigma <- sqrt(resvar)
      return(sigma)
    }
    if (is.null(z$terms))
      stop("invalid 'lm' object:  no 'terms' component")
    if (!inherits(object, "lm"))
      warning("calling summary.lm(<fake-lm-object>) ...")

    r <- z$residuals
    f <- z$fitted.values
    w <- z$weights
    if (is.null(w)) {
      mss <- if (attr(z$terms, "intercept"))
        sum((f - mean(f))^2)
      else sum(f^2)
      rss <- sum(r^2)
    }
    else {
      mss <- if (attr(z$terms, "intercept")) {
        m <- sum(w * f/sum(w))
        sum(w * (f - m)^2)
      }
      else sum(w * f^2)
      rss <- sum(w * r^2)
      #r <- sqrt(w) * r
    }
    resvar <- rss/rdf
    if (is.finite(resvar) && resvar < (mean(f)^2 + var(f)) *
        1e-30)
      warning("essentially perfect fit: summary may be unreliable")

    sigma <- sqrt(resvar)
  }
  return(sigma)


}

#' @export
setMethod("getSigma", "lm", .getSigmaLm)

setGeneric (
  name= "getDf",
  def=function(object,...){standardGeneric("getDf")}
)

.getDfMermod <- function(object){
  df <- attr(object,"MSqRob_df_sigma")
  if(is.null(df)){
    if(is.null(object@frame$"(weights)")){gew <- rep(1,lme4::getME(object, "devcomp")$dims["N"])} else{
      gew <- sqrt(object@frame$"(weights)")}
    sigma <- getSigma(object)
    df <- sum((resid(object)*gew)^2)/sigma^2
  }
  return(df)
}

#' @export
setMethod("getDf", "lmerMod", .getDfMermod)

.getDfLm <- function(object){

  df <- attr(object,"MSqRob_df_sigma")

  if(is.null(df)){
    df <- object$df.residual
  }
  return(df)


}

#' @export
setMethod("getDf", "lm", .getDfLm)


