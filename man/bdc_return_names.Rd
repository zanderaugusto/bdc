% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/bdc_return_names.R
\name{bdc_return_names}
\alias{bdc_return_names}
\title{Title: Return the closest name in a vector of names.}
\usage{
bdc_return_names(sci_name, max.distance, species.first.letter)
}
\arguments{
\item{sci_name}{A character vector with a single name.}

\item{max.distance}{A numeric value specifying the minimum distance between the sci_name and the names in species.first.letter.}

\item{species.first.letter}{A character vector whose distances will be calculated from sci_name.}
}
\value{
This function returns a data.frame whose first column is the closest name and the second column is the distance between the sci_name and the closest name.
}
\description{
This function looks for the closest name in a vector of names and returns the string distances calculated by fuzzy matching.
}
\examples{
bdc_return_names("Cebus apela", max.distance = 0.75, species.first.letter = c("Cebus apella", "Puma concolar"))

}
