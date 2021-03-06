#' hyper slice
#' 
#' Extract the raw array data for the active grid, as a list of arrays. This can be the
#' entire array/s or after dimension-slicing using `hyper_filter` expressions. 
#' 
#' By default all variables in the active grid are returned, use `select_var` to limit. 
#' @param x tidync object
#' @param ... ignored
#' @param select_var optional vector of variable names to select
#' @param raw_datavals logical to control whether scaling in the NetCDF is applied or not
#' @param force ignore caveats about large extraction and just do it
#'
#' @export
#' @examples 
#' f <- "S20092742009304.L3m_MO_CHL_chlor_a_9km.nc"
#' l3file <- system.file("extdata/oceandata", f, package= "tidync")
#' 
#' ## extract a raw list by filtered dimension
#' araw <- tidync(l3file) %>% hyper_filter(lat = abs(lat) < 10, lon = index < 100) %>% 
#'   hyper_slice()
#' ## hyper_slice will pass the expressions to hyper_filter
#' braw <- tidync(l3file) %>% hyper_slice(lat = abs(lat) < 10, lon = index < 100) 
hyper_slice <- function(x, select_var = NULL, ..., raw_datavals = FALSE, force = FALSE) {
  UseMethod("hyper_slice")
}


#' @name hyper_slice
#' @export
hyper_slice.tidync <- function(x, select_var = NULL, ..., raw_datavals = FALSE, force = FALSE) {
  variable <- x[["variable"]] %>% dplyr::filter(active)
  varname <- unique(variable[["name"]])
  ## hack to get the order of the indices of the dimension
  ordhack <- 1 + as.integer(unlist(strsplit(gsub("D", "", 
                                                 dplyr::filter(x$grid, .data$grid == active(x)) %>% 
                                                   dplyr::slice(1L) %>% 
                                                   dplyr::pull(.data$grid)), ",")))
  dimension <- x[["dimension"]] %>% dplyr::slice(ordhack)
  ## ensure dimension is in order of the dims in these vars
  axis <- x[["axis"]] %>% dplyr::filter(variable %in% varname)
  ## dimension order must be same as axis
  START <- dimension$start
  COUNT <- dimension$count
 # browser()
  if (is.null(select_var))   {
    varnames <- variable %>% dplyr::pull(.data$name)
  } else {
    if (!any(select_var %in% variable[["name"]])) {
      print("available variables: ")
      print(paste(variable$name, collapse = ", "))
      stop(sprintf("some select_var variables not found %s", select_var))
    }
    ## todo, make this quosic?
    varnames <- select_var
  }
  get_vara <- function(vara)  {
    con <- ncdf4::nc_open(x$source$source[1])
    on.exit(ncdf4::nc_close(con), add =   TRUE)
    ncdf4::ncvar_get(con, vara, 
                     start = START, count = COUNT, 
                     raw_datavals = raw_datavals)
  }
  mess <- sprintf("pretty big extraction here with (%i*%i values [%s]*%i", 
                  as.integer(prod( COUNT)), length(varnames), 
                  paste( COUNT, collapse = ", "), 
                  length(varnames))
  #if (prod(x$count) > 1e8) warning(mess)
  if ((prod(dimension[["count"]]) * length(varnames)) > 1.2e9 & interactive() & !force) {
    yes <- yesno::yesno(mess, "\nProceed?")
    if (!yes) return(invisible(NULL))
  }
  
  stats::setNames(lapply(varnames, get_vara), varnames)
}
#' @name hyper_slice
#' @export
hyper_slice.character <- function(x,  ..., select_var = NULL, raw_datavals = FALSE) {
  tidync(x) %>% hyper_filter(...) %>%  hyper_slice(select_var = select_var, raw_datavals = raw_datavals)
}
