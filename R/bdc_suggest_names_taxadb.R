#' Title: Suggest valid names based on taxadb R package.
#'
#' This function is a modification of suggest_name function (flora package) accessing taxadb database for fuzzy matching.
#'
#' @param sci_name character, containing scientific to be searched in taxadb database. The function does not clean names (eg.: infraspecific names), so this procedure should be done previously.
#' @param max_distance numeric,  a value between 0 and 1 specifying the minimum distance between the scientific names and names suggested by a fuzzy matching. Values close to 1 indicate that only a few differences between scientific names and name suggested are allowed. Default is 0.9.
#' @param provider A database where the valid and suggest names should be searched. The options are those provided by taxadb package.
#' @param rank_name a character string of taxonomic scientific name (e.g. "Plantae"). Default is NULL
#' @param rank a character string containing a taxonomic rank name (e.g. "kingdom"). Default is NULL
#' @param parallel logical, whether running in parallel. By default, it is TRUE
#' @param ncores integer, number of cores to be used for parallel processing. By default, it is 2
#' @return This function returns a data.frame whose first column is the suggested name and the second column is the distance between the sci_name and the suggested name.
#' It is worth to note that if there are two names with equal distances, only the first one is returned.
#' @export
#'
#' @examples
#' bdc_suggest_names_taxadb(c("Cebus apela", "Puma concolar"), provider = "gbif")
#'
bdc_suggest_names_taxadb <-
  function(sci_name,
           max_distance = suggestion_distance,
           provider = db,
           rank_name = NULL,
           rank = NULL,
           parallel = TRUE,
           ncores = 2) {
    
    # Get first letter of all scientific names
    first_letter <-
      unique(sapply(sci_name, function(i) {
        strsplit(i, "")[[1]][1]
      },
      USE.NAMES = FALSE
      ))

    first_letter <- base::toupper(first_letter)

    # Should taxonomic database be filter according to a taxonomic rank name?
    if (!is.null(rank_name) & !is.null(rank)) {
      species_first_letter <-
        taxadb::taxa_tbl(provider) %>%
        dplyr::filter(., .data[[rank]] == rank_name) %>%
        dplyr::pull(scientificName) %>%
        grep(paste0("^", first_letter, collapse = "|"), ., value = TRUE)
    } else if (is.null(rank_name) & !is.null(rank)) {
      message("Please, provide both 'rank_name' and 'rank' arguments")
    } else if (!is.null(rank_name) & is.null(rank)) {
      message("Please, provide both 'rank_name' and 'rank' arguments")
    } else {
      species_first_letter <-
        taxadb::taxa_tbl(provider) %>%
        pull(scientificName) %>%
        grep(paste0("^", first_letter, collapse = "|"), ., value = TRUE)
    }


    # Should parallel processing be used?
    if (parallel == TRUE) {
      # setup parallel backend to use many processors
      cl <- parallel::makeCluster(ncores) # not to overload your computer
      doParallel::registerDoParallel(cl)

      sug_dat <-
        foreach(i = sci_name,
                .combine = rbind, .export = "bdc_return_names") %dopar% {
          bdc_return_names(i, max_distance, species_first_letter)
        } # end foreach
      parallel::stopCluster(cl) # stop cluster
    } else {
      sug_dat <-
        data.frame(
          original = character(length(sci_name)),
          suggested = character(length(sci_name)),
          distance = numeric(length(sci_name))
        )

      for (i in seq_along(sci_name)) {
        sug_dat[i, ] <-
          bdc_return_names(sci_name[i], max_distance, species_first_letter)
      }
    }
    return(sug_dat)
  }