we_are_raady <- function() {
  fp <- getOption("default.datadir")
  #print(fp)
  stat <- FALSE
  if (!is.null(fp) && file.exists(file.path(fp, "data"))) stat <- TRUE
 stat
}

# 
# print_bytes <- function (x, digits = 3, ...) 
# {
#   power <- min(floor(log(abs(x), 1000)), 4)
#   if (power < 1) {
#     unit <- "B"
#   }
#   else {
#     unit <- c("kB", "MB", "GB", "TB")[[power]]
#     x <- x/(1000^power)
#   }
#   formatted <- format(signif(x, digits = digits), big.mark = ",", 
#                       scientific = FALSE)
#   paste0(formatted, " ", unit, "\n")
# }

