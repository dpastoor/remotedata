#' create remote reader functions
#' @param cb callback function that is applied to read the remote data
#' @param cache_method caching method, either rds or feather
#' @param compression whether to compress files if saving as rds, default to false
#' @examples \dontrun{
#' read_remote_csv <- read_remote_factory(readr::read_csv)
#' data <- read_remote_csv("<remote_dir/remote_file.csv>", "~/.cache")
#' }
#'
#' @export
read_remote_factory <- function(cb, cache_method = "rds", compression=FALSE) {
  if (!cache_method %in% c("rds", "feather")) {
    stop("cache_method must be either rds or feather")
  }
  if (cache_method=="rds" & !compression) {
    cache_method <- "rds_nocompression"
  }
  method <- switch(cache_method,
                   rds = list(
                     read = readRDS,
                     write = saveRDS,
                     ext = ".rds"
                     ),
                   rds_nocompression = list(
                     read = readRDS,
                     write = function(object, file) {
                       saveRDS(object, file, compress = FALSE)
                     },
                     ext = ".rds"
                   ),
                   feather = list(
                     read = feather::read_feather,
                     write = feather::write_feather,
                     ext = ".feather"
                     )
                   )
  return(function(remote, cache_dir, ...) {
  prefix <- substr(digest::sha1(remote), 1, 15) # hopefully 15 should be unique enough
  # worried about making the file name too large and windows complaining about too long
  # of paths
  file_name <- tools::file_path_sans_ext(basename(remote))
  cache_filename <- paste(prefix, paste0(file_name, method$ext), sep = "_")
  cache_file <- suppressWarnings(
    normalizePath(
      file.path(cache_dir, cache_filename
      )
    )
  )
  cache_record <- suppressWarnings(
    normalizePath(
      file.path(cache_dir, "cache_record.csv")
    )
  )

  if (!file.exists(cache_file)) {
    message("Cached file not found corresponding to remote dataset, ",
            "this first load will take (much) longer as reading from the remote")
    if (!dir.exists(cache_dir)) {
      warning("cache directory does not currently exist, initializing...")
      dir.create(cache_dir, recursive = T)
    }
    if (file.size(remote) > 50000000) {
      warning("This file is larger than 50MB and therefore may take a while to read, hold tight...")
      #TODO: copy file to tempdir, maybe in separate process, then load locally from tempdir
    }

    data <- cb(remote, ...)
    message("Data read in, creating cache at: ", cache_file)
    method$write(data, cache_file)

    # this will currently fail if the file is open, however the cache will still be written to
    # so will 'lose' the fact that a file was cached as such
    if (!file.exists(cache_record)) {
      write.table(data.frame(
        remote_file = remote,
        cache_name = cache_filename,
        time_cached = Sys.time()
      ), cache_record, row.names=FALSE, quote = FALSE, sep = ",")
    } else {
      # don't want to add col names again
      write.table(data.frame(
        remote_file = remote,
        cache_name = cache_filename,
        time_cached = Sys.time()
      ), cache_record, append = TRUE, row.names=FALSE, quote = FALSE, sep = ",", col.names=FALSE)
    }


  } else {
    message("Cache file found at: ", cache_file)
    data <- method$read(cache_file)
  }

  return(data)
})
}

#' read remote files
#' @param remote remote data file
#' @param cache_dir local cache folder
#' @param ... args to pass to read function
#' @examples \dontrun{
#' example_data <- read_remote_xpt("\\cdsnas\PHARMACOMETRICS\Fellows\Devin\example.xpt", ".cache")
#' }
#' @export
read_remote_xpt <- read_remote_factory(SASxport::read.xport, cache_method = "feather")

#' @export
#' @rdname read_remote_xpt
read_remote_csv <- read_remote_factory(readr::read_csv, cache_method = "feather")

#' @export
#' @rdname read_remote_xpt
read_remote_xlsx <- read_remote_factory(readxl::read_excel, cache_method = "feather")

#' @export
#' @rdname read_remote_xpt
read_remote_sas <- read_remote_factory(haven::read_sas, cache_method = "feather")

#' read remote files with compression
#' @param remote remote data file
#' @param cache_dir local cache folder
#' @param ... args to pass to read function
#' @export
read_remote_xptc <- read_remote_factory(SASxport::read.xport, compression = TRUE)
#' @export
#' @rdname read_remote_xptc
read_remote_csvc <- read_remote_factory(readr::read_csv, compression = TRUE)

#' @export
#' @rdname read_remote_xptc
read_remote_xlsxc <- read_remote_factory(readxl::read_excel, compression = TRUE)

#' @export
#' @rdname read_remote_xptc
read_remote_sasc <- read_remote_factory(haven::read_sas, compression = TRUE)
