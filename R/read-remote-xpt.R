#' @param remote remote data file
#' @param cache_dir local cache folder
#' @param ... args to pass to read.xport
#' @export
read_remote_xpt <- function(remote, cache_dir, ...) {
  prefix <- substr(digest::sha1(remote), 1, 15) # hopefully 15 should be unique enough
  # worried about making the file name too large and windows complaining about too long
  # of paths
  file_name <- tools::file_path_sans_ext(basename(remote))
  cache_filename <- paste(prefix, paste0(file_name, ".feather"), sep = "_")
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

    data <- SASxport::read.xport(remote, ...)
    message("Data read in, creating cache at: ", cache_file)
    feather::write_feather(data, cache_file)

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
    data <- feather::read_feather(cache_file)
  }

  return(data)
}
