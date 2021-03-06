

#' Array subset by expression
#'
#' Filter arguments must be named as per the dimensions in the variable. This is a restrictive variant of `dplyr::filter`, 
#' with a syntax more like `dplyr::mutate`. This ensures that each element is named, so we know which dimension to 
#' apply this to, but also that the expression evaluated against can do some extra work for a nuanced test. 
#' 
#' There are special columns provided with each axis, one is 'index' so that exact matching can be
#' done by position, or to ignore the actual value of the coordinate. 
#' @param .x NetCDF file, connection object, or `tidync` object
#' @param ... currently ignored
#'
#' @return data frame
#' @export
#' @importFrom purrr map
#' @importFrom dplyr group_by mutate summarize
#' @examples
#' f <- "S20092742009304.L3m_MO_CHL_chlor_a_9km.nc"
#' l3file <- system.file("extdata/oceandata", f, package= "tidync")
#' ## filter by value
#' tidync(l3file) %>% hyper_filter(lon = lon < 100)
#' ## filter by index
#' tidync(l3file) %>% hyper_filter(lon = index < 100)
#' 
#' ## filter in combination/s
#' tidync(l3file) %>% hyper_filter(lat = abs(lat) < 10, lon = index < 100)
hyper_filter <- function(.x, ...) {
  UseMethod("hyper_filter")
}
#' @name hyper_filter
#' @export
#' @importFrom dplyr %>% mutate 
#' @importFrom forcats as_factor
#' @importFrom tibble as_tibble
hyper_filter.tidync <- function(.x, ...) {
  quo_named <- rlang::quos(...)
  trans0 <- active_axis_transforms(.x)
  if (any(nchar(names(quo_named)) < 1)) stop("subexpressions must be in 'mutate' form, i.e. 'lon = lon > 100' or 'lat = index > 10'")
  quo_noname <- unname(quo_named)

  for (i in seq_along(quo_named)) {
    iname <- names(quo_named)[i]
    if (!iname %in% names(trans0)) {
      warning(sprintf("'%s' not found in active grid, ignoring", iname))
      next
    }
    SELECTION <- dplyr::filter(trans0[[iname]], !!!quo_noname[i])
    if (nrow(SELECTION) < 1L) stop(sprintf("subexpression for [%s] results in empty slice, no intersection specified", 
                                                 iname))
    
    trans0[[iname]]$selected <- trans0[[iname]]$index %in% SELECTION$index
  }

  .x[["transforms"]][names(trans0)] <- trans0

  out <- update_slices(.x)
  
out
}

update_slices <- function(x) {
  
  transforms <- x[["transforms"]]
  starts <- unlist(lapply(transforms, function(axis) head(which(axis$selected), 1L)))
  ends <- unlist(lapply(transforms, function(axis) utils::tail(which(axis$selected), 1L)))
  actual_counts <- unlist(lapply(transforms, function(axis) length(which(axis$selected))))
  counts <- ends - starts + 1L
  ## todo make this more informative
  if (!all(counts == actual_counts)) warning("arbitrary indexing within dimension is not yet supported")
                        
 idx <- match(names(starts), x[["dimension"]][["name"]])
 x[["dimension"]][["start"]][idx] <- starts
 x[["dimension"]][["count"]][idx] <- counts
 
#  x[["dimension"]] <- dplyr::inner_join(x[["dimension"]], tibble(name = names(starts), start = starts, count = counts), "name")
x
}
