#' Title: correct_coordinates is a function that will detect those occurrences georreferenced outside their country different coordinate transformation
#'
#' @param data 
#' @param x 
#' @param y 
#' @param sp 
#' @param id 
#' @param cntr_iso2 
#' @param world_poly 
#' @param world_poly_iso 
#'
#' @return
#' @export
#'
#' @examples
bdc_correct_coordinates <-
  function(data,
           x,
           y,
           sp,
           id,
           cntr_iso2,
           world_poly,
           world_poly_iso) {
    
    x_mod <- paste0(x, "_modified")
    y_mod <- paste0(y, "_modified")
    
    occ_country <- data %>% dplyr::filter(!is.na(data[cntr_iso2]))
    
    # Filter occurrences database to avoid error in clean_coordinates errors
    occ_country <-
      occ_country %>%
      dplyr::filter(.missing_xy == TRUE & .invalid_xy == TRUE) %>% 
      dplyr::mutate(decimalLatitude = as.numeric(decimalLatitude),
             decimalLongitude = as.numeric(decimalLongitude))
 
    # Detect records outside a country
    occ_country <- CoordinateCleaner::clean_coordinates(
      x =  occ_country,
      lon = x,
      lat = y,
      species = sp,
      countries = cntr_iso2,
      # iso2 code column of our database
      tests = c("seas", "countries"),
      #Will be tested records located in the see and outside georeferenced countries
      country_ref = world_poly,
      #Here we are using a high resolution countries border database
      country_refcol = world_poly_iso,
      #iso2 code column of country polygon database
      seas_ref = world_poly,
      #Here we are using a high resolution countries border database
      value = "spatialvalid"
    )
    
    summary(occ_country)
    
    # Separate those records outside their countries
    occ_country <- 
      occ_country %>%
      as_tibble() %>%
      dplyr::filter(!.summary,!is.na(occ_country[cntr_iso2]))
    
    message(occ_country %>% nrow, " ocurrences will be tested") #now this database have all those records with potential error that will try to correct
    
    # Split database
    occ_country <-
      occ_country %>% dplyr::group_by_(cntr_iso2) %>% group_split()
    
    
    # bdc_coord_trans() function will try different coordinate transformations to correct georeferenced occurrences
    coord_test <- list()
    
    for (i in 1:length(occ_country)) {
      message('Processing occurrence from: ',
              occ_country[[i]][cntr_iso2] %>% unique,
              paste0(" (", nrow(occ_country[[i]]), ")"))
      try(coord_test[[i]] <-
            bdc_coord_trans(
              data = occ_country[[i]],
              x = x,
              y = y,
              country_code = cntr_iso2,
              id = id,
              worldmap = world_poly,
              worldmap_cntr_code = world_poly_iso
            ))
    }
    
    filt <- sapply(coord_test, function(x)
      nrow(x) > 0)
    coord_test <-
      coord_test[filt] # elimination from the list those countries without correction
    
    # Elimination of those records near to country border (to avoid flip coordinates or sign that fall too close to country border)
    
    for (i in 1:length(coord_test)) {
      n <- 
        coord_test[[i]] %>%
        dplyr::select_(cntr_iso2) %>% 
        unique %>% 
        pull
      
      my_country <-
        world_poly[which(world_poly@data[, world_poly_iso] == n),] #Here filter polygon based on your country iso2c code
      my_country2 <-
        raster::buffer(my_country, width = 0.5) #0.5 degree ~50km near to equator
      
      coord_sp <- sp::SpatialPoints(coord_test[[i]] %>%
                                      dplyr::select_(x, y))
      
      coord_sp@proj4string <- my_country2@proj4string
      over_occ <- sp::over(coord_sp, my_country2)
      
      # plot(my_country)
      # plot(my_country2, add = T)
      # coord_test[[i]] %>%
      #   dplyr::filter(over_occ == 1) %>%
      #   dplyr::select_(x, y) %>%
      #   points(., pch = 19, col = 'red')
      
      # Eliminate as corrected those records too close to country border
      coord_test[[i]] <-
        coord_test[[i]] %>% dplyr::filter(is.na(over_occ))
    }
    
    # Elimination of those records with more than two possible correction
    coord_test <-
      dplyr::bind_rows(coord_test) %>% 
      as_tibble() # binding dataframes allocated in the list in a single one
    
    coord_test <-
      coord_test %>%
      dplyr::distinct_(., id, .keep_all = T) %>%
      as_tibble %>%
      dplyr::relocate(id, x, y)
    
    # Merge coord_test with other columns of occurrence database
    coord_test <-
      left_join(coord_test,
                data %>% dplyr::select(-c(x, y, cntr_iso2)),
                by = id)
    
    return(coord_test)
  }

