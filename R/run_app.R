#' Launch the Shiny App
#'
#' @importFrom shiny runApp
#' @importFrom readr read_csv
#' @importFrom dplyr mutate
#' @importFrom tibble tibble
#' @export
run_app <- function() {
  app_dir <- system.file("shiny", "evalstratified", package = "evalstratified")

  if (app_dir == "") {
    app_dir <- "./inst/shiny/evalstratified"
  }

  if (!file.exists(app_dir)) {
    stop("Could not find app directory.", call. = FALSE)
  }

  shiny::runApp(app_dir, display.mode = "normal")
}
