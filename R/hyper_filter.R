
hyper_filter_Spatial <- function(x, y, ...) {
  #stop("nothing to see here")
  #warning("assuming first two dimensions are longitude-latitude ...")
  #dim_tabs <- hyper_filter(x)
  #xy_names <- names(dim_tabs)[1:2]
  #xy_grid <- as.matrix(expand.grid(x = dim_tabs[[1]][[xy_names[1]]], 
  #                        y = dim_tabs[[1]][[xy_names[1]]]))
  #over(y, SpatialPoints(xy_grid, proj4string = crs(y)))
}


#' Array subset by nse
#'
#' NSE arguments must be named as per the dimensions in the variable. This is a restrictive variant of `dplyr::filter`, 
#' with a syntax more like `dplyr::mutate`. This ensures that each element is named, so we know which dimension to 
#' apply this to, but also that the expression evaluated against can do some extra work for a nuanced test. 
#' @param x NetCDF object
#' @param ... currently ignored
#'
#' @return data frame
#' @export
#' @importFrom purrr map
#' @importFrom dplyr group_by mutate summarize
#' @examples
#' ## inst/dev/filtrate_early.R
#' ##http://rpubs.com/cyclemumner/tidyslab
#' # 
hyper_filter <- function(x, ...) {
  UseMethod("hyper_filter")
}
#' @name hyper_filter
#' @export
#' @importFrom dplyr %>% mutate 
#' @importFrom forcats as_factor
hyper_filter.tidync <- function(x, ...) {
  
  dimvals <- dimension_values(x) #%>% 
  dimvals$step <- unlist(lapply(split(dimvals, forcats::as_factor(dimvals$name)), function(x) seq_len(nrow(x))))
  trans <-  split(dimvals, forcats::as_factor(dimvals$name)) 
  
  ## hack attack
  for (i in seq_along(trans)) names(trans[[i]]) <- gsub("^vals$", trans[[i]]$name[1], names(trans[[i]]))
  
  quo_named <- rlang::quos(...)
  if (any(nchar(names(quo_named)) < 1)) stop("subexpressions must be in 'mutate' form, i.e. 'lon = lon > 100'")
  quo_noname <- unname(quo_named)
  for (i in seq_along(quo_named)) {
    iname <- names(quo_named)[i]
    trans[[iname]] <- dplyr::filter(trans[[iname]], !!!quo_noname[i])
    if (nrow(trans[[iname]]) < 1L) stop(sprintf("subexpression for [%s] results in empty slice, no intersection specified", 
                                                iname))
  }
  trans <- lapply(trans, function(ax) {ax$filename <- x$file$filename; ax})
  hyper_filter(trans) %>% activate(active(x))
  
}

#' @name hyper_filter
#' @export
hyper_filter.default <- function(x, ...) {
  structure(x, class = c("hyperfilter", class(x)))
}
#' @name hyper_filter
#' @export
hyper_filter.character <- function(x, ...) {
  tidync(x) %>% hyper_filter(...)
}
#' @name hyper_filter
#' @export
hyper_filter.hyperfilter <- function(x, ...) {
  stop("too many filters in the chain, you can't (yet) 'hyper_filter' a hyperfilter")
}
#' @name hyper_filter
#' @importFrom dplyr bind_rows funs group_by select summarize_all
#' @export
print.hyperfilter <- function(x, ...) {
  x <- dplyr::bind_rows(lapply(x,  function(a) dplyr::summarize_all(a %>% 
                                                                      dplyr::select(-.data$filename, -.data$.dimension_, -.data$id, -.data$step) %>% 
                                                                      group_by(.data$name), dplyr::funs(min, max, length))))
  print("filtered dimension summary: ")
  print(x)
  invisible(x)
}