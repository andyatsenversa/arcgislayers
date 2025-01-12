#' Utility functions
#'
#' @inheritParams arc_select
#' @details
#'
#' `r lifecycle::badge("experimental")`
#'
#' - `list_fields()` returns a data.frame of the fields in a `FeatureLayer` or `Table`
#' - `list_items()` returns a data.frame containing the layers or tables in a `FeatureServer` or `MapServer`
#' - `clear_query()` removes any saved query in a `FeatureLayer` or `Table` object
#' - `refresh_layer()` syncs a `FeatureLayer` or `Table` with the remote
#'    resource picking up any changes that may have been made upstream.
#'    Returns an object of class `x`.
#'
#' @returns See Details.
#' @export
#' @rdname utils
#' @examples
#' if (interactive()) {
#'   furl <- paste0(
#'     "https://services3.arcgis.com/ZvidGQkLaDJxRSJ2/arcgis/rest/services/",
#'     "PLACES_LocalData_for_BetterHealth/FeatureServer/0"
#'   )
#'
#'   flayer <- arc_open(furl)
#'
#'   # list fields available in a layer
#'   list_fields(flayer)
#'
#'   # remove any queries stored in the query attribute
#'   clear_query(update_params(flayer, outFields = "*"))
#'
#'   # refresh metadata of an object
#'   refresh_layer(flayer)
#'
#'   map_url <- paste0(
#'     "https://services.arcgisonline.com/ArcGIS/rest/services/",
#'     "World_Imagery/MapServer"
#'   )
#'
#'   # list all items in a server object
#'   list_items(arc_open(map_url))
#'
#' }
clear_query <- function(x) {
  attr(x, "query") <- list()
  x
}

#' @export
#' @rdname utils
list_fields <- function(x) {
  res <- x[["fields"]]

  if (is.null(res)) {
    res <- infer_esri_type(data.frame())
  }

  res
}

#' @export
#' @rdname utils
list_items <- function(x) {
  rbind(x[["layers"]], x[["tables"]])
}

#' @export
#' @rdname utils
refresh_layer <- function(x) {
  query <- attr(x, "query")
  xurl <- x[["url"]]
  x <- switch(
    class(x)[1],
    FeatureLayer = arc_open(xurl),
    Table = arc_open(xurl)
  )

  attr(x, "query") <- query
  x
}



#' Get chunk indices
#'
#' For a given number of items and a chunk size, determine the start and end
#' positions of each chunk.
#'
#' @param n the number of rows
#' @param m the chunk size
#' @keywords internal
#' @noRd
chunk_indices <- function(n, m) {
  n_chunks <- ceiling(n/m)
  chunk_starts <- seq(1, n, by = m)
  chunk_ends <- seq_len(n_chunks) * m
  chunk_ends[n_chunks] <- n
  list(start = chunk_starts, end = chunk_ends)
}

#' Pick first non-missing CRS
#'
#' @param x an object of class `crs`
#' @param y an object of class `crs`
#'
#' @examples
#'
#' x <- sf::st_crs(27572)
#' y <- sf::st_crs(NA)
#'
#' coalesce_crs(x, y)
#' @noRd
coalesce_crs <- function(x, y) {
  # DEVELOPER NOTE: there is no inheritance check for CRS class
  # I don't know how we would provide an informative error here.
  # dont mess up!
  x_na <- is.na(x)
  y_na <- is.na(y)

  if (x_na && y_na) {
    return(x)
  } else if (y_na) {
    return(x)
  } else if (x_na) {
    return(y)
  } else {
    x
  }
}


#' Useful for when an argument must either be NULL or a scalar
#' value. This is most useful when ensuring that values passed
#' to `httr2::req_body_multiform()` are scalars. Multiple length
#' values are not permitted.
#' @keywords internal
#' @noRd
check_null_or_scalar <- function(
    x,
    arg = rlang::caller_arg(x),
    error_call = rlang::caller_env()
) {
  if (!is.null(x)) {
    if (length(x) > 1) {
      cli::cli_abort(
        "{.arg {arg}} argument must be a scalar or {.val NULL}",
        call = error_call
      )
    }
  }
}


