# comtradr - UN Comtrade Database ----

# UN Comtrade Database: https://unstats.un.org/wiki/display/comtrade
# R package: https://docs.ropensci.org/comtradr/index.html


## Installation ----

# install.packages("comtradr")
# The package is not yet on CRAN
devtools::install_github(repo = "ropensci/comtradr@main")

# Once it is on CRAN, use
# install.packages("comtradr")


## Usage ----

### Authentication ----

# Got to 
# https://unstats.un.org/wiki/display/comtrade/New+Comtrade+User+Guide#NewComtradeUserGuide-UNComtradeAPIManagement
# and create an account.

# Sign up to the free comtrade-v1 product.


### Storing the API key ---

# Store the API key in the .Renviron file by calling
usethis::edit_r_environ()
# restart the r session afterwards

library(comtradr)

# Check if the key is available
Sys.getenv("COMTRADE_PRIMARY")


## Making API calls ----

### Example 1 ----

# Country names passed to the API query function must be specified
# according to ISO 3166-1 alpha-3
# See: https://en.wikipedia.org/wiki/ISO_3166-1_alpha-3


# Query the total trade between China and Germany
# and Argentina, as reported by China.

# You can request a maximal interval of twelve years.
example1 <- comtradr::ct_get_data(
  reporter  = "CHN",
  partner    = c("ARG", "DEU"),
  start_date = 2010,
  end_date   = 2012
)

# Inspect the return data
str(example1)


### Example 2 ----

# Return all exports related to Wine from Argentina
# to all other countries for years 2007 through 2011.

# This vector will be passed to the API query.
wine_codes <- ct_commodity_lookup(
  search_terms = "wine", 
  return_code  = TRUE, 
  return_char  = TRUE
)

# API query
example2 <- ct_get_data(
  reporter = "ARG",
  flow_direction = "export",
  partner = "all_countries",
  start_date = 2007,
  end_date   = 2011,
  commodity_code = wine_codes
)

# Note: partner = "all" does not work. Use "all_countreis" instead.

# Inspect the output
str(example2)


### Example 3 ----

# Get total imports into the United States from
# Germany, France, and Mexico,
# for the last five years.
example_3 <- ct_get_data(
  reporter = "USA",
  partner  = c("DEU", "FRA", "JPN", "MEX"),
  commodity_code = "TOTAL",
  start_date = 2018,
  end_date   = 2023,
  flow_direction = "import"
)

# API calls return a tidy data frame
str(example_3)


### Example 4 ----

# By default, the return data is in yearly amounts.

# Pass "monthly" to the freq argument to return data in
# monthly amounts.

# The API limits each "monthly" query to a single year.

# all monthly data for a single year (API max of twelve months per call)
q <- ct_get_data(
  reporter = "USA",
  partner  = c("DEU", "FRA", "JPN", "MEX"),
  flow_direction = "import",
  start_date = 2012,
  end_date  = 2012,
  freq = "M"
)

str(q)

# monthly data, specific span of months (API max of twelve months per call)
q <- ct_get_data(
  reporter = "USA",
  partner  = c("DEU", "FRA", "JPN", "MEX"),
  flow_direction = "import",
  start_date = "2012-03",
  end_date   = "2012-07",
  freq = "M"
)

str(q)


### Example 5 ----

# Search trade related to specific commodities,
# say, tomatoes.
print(ct_commodity_lookup("tomato"))

# If we want to search for shipment data on all
# of the commodity descriptions listed,
# simply adjuste the parameters for ct_commodity_lookup()
# so that it will return only the codes passed along.

tomato_codes <- ct_commodity_lookup(
  search_terms = "tomato",
  return_code  = TRUE,
  return_char  = TRUE
)

print(tomato_codes)

q <- ct_get_data(
  reporter = "USA",
  partner  = c("DEU", "FRA", "JPN", "MEX"),
  commodity_code = tomato_codes,
  start_date = "2012",
  end_date   = "2013",
  flow_direction = "import"
)

str(q)


### Example 6 ----

# If we want to exclude juices and sauces from
# our search, we can pass a vector of the relevant codes 
# to the API call.
q <- ct_get_data(
  reporter = "USA",
  partner  = c("DEU", "FRA", "JPN", "MEX"),
  commodity_code = c("0702", "070200", "2002", "200210", "200290"),
  start_date = "2012",
  end_date   = "2013",
  flow_direction = "import"
)

str(q)


## API search metadata ----

# In addition to the trade data, each API call
# return object contains metadata as attributes.

attributes(q)
# names, class, row.names, url, time


# The URL of the API call
attributes(q)$url

# The date-time of the API call
attributes(q)$time


## More on the lookup functions ----

### Example 1 ----

# The function ct_commodity_lookup() can take
# multiple search terms as input arguments.
ct_lookup <- ct_commodity_lookup(
  search_terms = c("tomato", "orange"), 
  return_char  = TRUE
)

head(ct_lookup)


### Example 2 ----

# ct_commodity_lookup() can return a vector 
# or a named list, depending on the parameter
# return_char
ct_lookup <- ct_commodity_lookup(
  search_terms = c("tomato", "orange"), 
  return_char  = FALSE
)

names(ct_lookup)
# "tomato" "organge"
ct_lookup$tomato
ct_lookup$orange


### Example 3 ----

# If any input search terms return zero results
# and the parameter verbose is set to TRUE in
# ct_commodity_lookup(), a warning will be printed
# to the console.

ct_lookup <- ct_commodity_lookup(
  search_terms = c("tomato", "fjdklasf"),
  verbose = TRUE
)

# Warning:
# There were no matching results found for inputs:
# fjdklasf



## API rate limits ----

# The UN Comtrade API imposes rate limits on users.

# comtradr features automated throttling of API calls to
# ensure the user stays within the limits defined by Comtrade.

# Below is a breakdown of those limits.
# See the API documentation here:
# https://unstats.un.org/wiki/display/comtrade/New+Comtrade+FAQ+for+First+Time+Users

# - Without user token: unlimited calls per day,
#   up to 500 records per call
#   (no registration or API subscription key required).
#   This endpoint is NOT implemented in the comtradr package.

# - With a valid user token: 250 calls per day, up to 250,000 records per call
#   (free registration and API subscription key required).


# The API also limits the amount of times it can be queried per minute,
# but we could not find any documentation on this.

# Hence the function automatically responds to the parameters
# returned by each request to adjust to changing wait times.


# In addition to these rate limits, the API imposes
# some limits on parameter combinations.

# - The arguments reporter and partner do not have an
#   "All" value natively specified anymore.
#   It is implemented in R for convenience though.

# - For the date range the start_date and end_date must not 
#   span more than twelve months or twelve years.
#   There is no more "All" parameter to specify all years.
#   Use "all_countries" for this purpose.

# - For the argument commodity_codes, the maximum number of
#   input values depends on the maximum length of the reques.


## Package Data ----

# comtradr ships with a few package data objects
# and functions to interact and use this package data.


### Country/Commodity Reference Tables ----

# Making an API call with comtradr often requires the
# user to query the commodity reference table
# with ct_commodity_lookup.

# UN Comtrade generates these reference tables,
# and they are updated infrequently, roughly once a year.

# Because they are infrequently updated, the tables
# are saved as cached data objects within the comtradr package,
# and are referenced by the package functions when needed.


# The function ct_commodity_lookup() features an
# update argument that will check for updated reference tables,
# download the new tables and make them available during the
# R session.

# It will print a message indicating whether any updates are found.
ct_lookup <- ct_commodity_lookup(
  search_terms = "tomato",
  update = TRUE
)


# If any updates are found, a message will state which
# reference tables were updated.


# The Comtrade API also features a number of different
# commodity reference tables, based on different 
# trade data classification schemes.

# These are shown here: 
# https://unstats.un.org/wiki/display/comtrade/New+Comtrade+FAQ+for+Advanced+Users?preview=/135004494/135004492/Picture1.png

# The comtradr package ships with all available
# commodity reference tables.

# The user may return and access any of the available
# commodity tables by specifying the argument
# commodity_type within the function
# ct_get_ref_table(),
# e.g., 
# ct_get_ref_table(dataset_id = "S1")
# will return the commodity table that follows the 
# "S1" scheme.

# The dataset_id's are listed in the help page of the
# function ct_get_ref_table()
help("ct_get_ref_table")

# They are as follows:

# - Datasets that contain codes for the commodity_code
#   argument.
#   The name is the same as you would provide under
#   commodity_classification

# - "HS" This is the most common classification for goods.
# - "B4", "B5", "EB02", "EB10", "EB10S", "EB", "S1", "S2", "S3", "S4", "SS"
# - Datasets that are related to other arguments can
#   be queried directly with the name of the argument
#   in the ct_get_data() function
# - "reporter"
# - "partner"
# - "mode_of_transport"
# - "customs_code"


# Furthermore, there is a dataset available with the
# ISO3C codes for the respective partner and reporter 
# countries
country_codes$iso_3
# This allows you to update to the latest values on the fly.


## Visualize ----

# Once the data is collected, you can create some
# basic visualizations.


### Plot 1 ----

# Comtrade API query
example2 <- ct_get_data(
  reporter = "CHN",
  partner = c("KOR", "USA", "MEX"),
  commodity_code = "TOTAL",
  start_date = 2012,
  end_date = 2023,
  flow_direction = "export"
)

library(ggplot2)

# Apply polished column headers and create the plot
ggplot(
  data = example2, 
  mapping = aes(
    x = period, 
    y = primary_value/10^9, 
    color = partner_desc,
    group = partner_desc
    )
  ) +
  geom_point(linewidth = 2) +
  geom_line(linewidth = 1) +
  scale_color_manual(
    values = c("darkgreen", "red", "grey30"),
    name = "Destination\nCountry"
  ) +
  ylab("Export value in billions") +
  xlab("Year") +
  labs(
    title = "Total Value (USD) of Chinese Exports",
    subtitle = "by year"
  ) +
  theme(
    axis.text.x = element_text(angle = 45, vjust = 1, hjust = 1)
  ) +
  theme_minimal()

ggsave(filename = "china-exports.png", width = 8, height = 4)
graphics.off()


### Plot 2 ----

# Plot the top eight destination countries / areas
# of Thai shrimp exports, by weight (kg), for 2007 to 2011.

# Collect the commodity codes related to shrimp.
shrimp_codes <- ct_commodity_lookup(
  search_terms = "shrimp",
  return_code  = TRUE,
  return_char  = TRUE
)

# Comtrade API query
example_3 <- ct_get_data(
  reporter = "THA",
  partner  = "all_countries",
  flow_direction = "export",
  start_date = 2007,
  end_date   = 2011,
  commodity_code = shrimp_codes
)

library(dplyr)

# Create a country specific data frame called
# "total weight per year"
plotdf <- example_3 |> 
  group_by(partner_desc, period) |> 
  summarise(kg = as.numeric(sum(net_wgt, na.rm = TRUE)))

head(plotdf)
tail(plotdf)


# Get a vector of the top 8 destination countries/areas
# by total weight shipped across all years
top8 <- plotdf |> 
  group_by(partner_desc) |> 
  summarise(kg = as.numeric(sum(kg, na.rm = TRUE))) |> 
  slice_max(n = 8, order_by = kg) |> 
  arrange(desc(kg)) |> 
  pull(partner_desc)

print(top8)

# then subset plotdf to only include observations
# related to those countries/areas.
plotdf <- plotdf |> 
  filter(partner_desc %in% top8)

head(plotdf)
tail(plotdf)


# Create plots (y-axis is NOT fixed across panels,
# this will allow ous to identify trends over time
# within each country/area individually).
ggplot(
  data = plotdf,
  mapping = aes(
    x = period, 
    y = kg/1000, 
    group = partner_desc)
  ) +
  geom_line() +
  geom_point() +
  facet_wrap(
    facets = .~partner_desc,
    nrow = 2,
    ncol = 4,
    scales = "free_y"
  ) +
  labs(
    title = "Weight (in tons) of Thai shrimp exports",
    subtitle = "by destination area, 2007 - 2011"
  ) + 
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1, vjust = 1)
  ) +
  theme_minimal()

ggsave(filename = "thailand-exports.png", width = 8, height = 4)

graphics.off()


## Handling large amounts of Parameters ----

# Several function parameters in the comtradr package
# can accept "everything" as an input.

# Internally, these values are set to NULL and the
# parameter is omitted in the API request, since
# the API will return all possible values by default.


# Here is a breakdown of how "everything" is handled 
# for different parameters.


### commodity_code ----

# Setting commodity_code to "everything"
# will query all possible commodity values.

# This can be useful if you want to retrieve data
# for all commodities without specifying individual codes.


### flow_direction -----

# If flow_direction is set to "everything", all 
# possible values for trade flow directions are queried.

# This includes
# - imports
# - exports
# - re-imports
# - others, specified in
ct_get_ref_table("flow_direction")
# id  text
# M   Import
# X   Export
# DX  Domestic Export
# FM  Foreign Import
# MIP Import of goods for inward processing
# MOP Import of goods after outward processing
# RM  Re-import
# RX  Re-export
# XIP Export of goods after inward processing
# XOP Export of goods for outward processing


### reporter and partner ----

# Using "everything" for reporter or partner will
# query all possible values for reporter and partner
# countries, but also includes aggregates like
# "World" or some miscellaneous like "ASEAN".

# Be careful when aggregating these values,
# so as not to count trades multiple times
# in different aggregates.

# Alternatively, specifically for these values,
# use "all_countries", which allows you to
# query all countries which are not aggregates
# of some kind.

# These values can usually be safely aggregated.


### mode_of_transport, partner_2, and customs_code ----

# Setting these parameters to "everything" will query
# all possible values related to the mode of transport,
# secondary partner, and customs procedures.

# This provides a comprehensive view of the data
# across different transportation modes and customs 
# categories.


## Example usage ----

# An example of how you might use "everything" 
# parameters to query comprehensive data.

# Query all commodities and flow directions for 
# the USA and Germany between 2010 and 2011
dt <- ct_get_data(
  reporter = c("USA", "DEU"),
  commodity_code = "everything",
  flow_direction = "everything",
  start_date = "2010",
  end_date  = "2011"
)

# Using "everything" parameters leads to large
# datasets, as they remove specific filters on the
#data.

# Be mindful of the size of the data queried,
# especially when using multiple "everything"
# parameters simultaneously.
dim(dt)
# 78398 x 47
object.size(dt)
# 24605160 bytes

# END