% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/bdc_parse_date.R
\name{bdc_parse_date}
\alias{bdc_parse_date}
\title{Extract and flag year from date}
\usage{
bdc_parse_date(x, column_to_test, year_threshold = NULL)
}
\arguments{
\item{x:}{data.frame. Containing column of event date.}

\item{column_to_test:}{Numeric or date. The column with event date information.}

\item{year_threshold:}{Numeric. Four digit year used as a threshold to flag od records. Default = NULL.}
}
\description{
Extract and flag year from date
}
