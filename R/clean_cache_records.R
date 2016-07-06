#' clean up cache records
#' @details
#' cleans up the cache record to only include files that currently exist in the cache, useful to run
#' if manually deleting files in the cache
#' @param cache_dir cache folder location
#' @export
clean_cache_records <- function(cache_dir = ".") {
  cache_record <- file.path(cache_dir, "cache_record.csv")
  if (!file.exists(cache_record)) {
    stop("Could not fine cache_record.csv in the supplied folder, are you sure that is the cache directory?")
  }
  cache <- read.csv(cache_record)
  cached_files <- order(list.files(cache_dir, pattern = "*.feather"))
  cached_records <- order(cache$cache_name)
  cleaned_cache <- dplyr::filter(cache, cache_name %in% cached_files)
  if (isTRUE(all.equal(cached_files, cached_records))) {
    message("Cache records match cache record")
  } else {
    # do something for files present in cache_record but not on disk
    # do something for files present on disk but not in cache_record
  }
}
