# 03 - Function reference ----

## Get data ----

### ct_get_data() ----

# Workhorse function of the package

# Get trade data from the UN Comtrade API

# Default type is "goods".
# Options are "goods" and "services".

# Default "frequency" is "A" for annual.
# Possible are "A" for annual and "M" for monthly.

# The commodity_classification scheme is
# "HS" for harmonised system by default.
# For goods, the options are
# HS, S1, S2, S3, S4, SS, B4, B5

# For services
# EB02, EB10, EB10S, EB

# commodity_code is "TOTAL" by default.
# Options are listed in
head(comtradr::ct_get_ref_table("HS"))

# flow_direction is
# c("Import", "Export", "Re-export", "Re-import")
# by default
# These are case insensitive.

# reporter is "all_countries" by default.
# See
head(comtradr::country_codes)
# for possible values

# same holds for "partner"


### Examples ----

# Query goods data for China's trade with Argentina and Germany in 2019
ct_get_data(
  type = "goods",
  commodity_classification = "HS",
  commodity_code = "TOTAL",
  reporter = "CHN",
  partner  = c("ARG", "DEU"),
  start_date = "2019",
  end_date   = "2019",
  flow_direction = "Import",
  partner_2      = "World",
  verbose = TRUE
)


# Query all commodity codes for China's imports from Germany in 2019
ct_get_data(
  commodity_code = "everything",
  reporter = "CHN",
  partner  = "DEU",
  start_date = "2019",
  end_date = "2019",
  flow_direction = "Import"
)


# Query all commodity codes for China's imports from Germany
# from January to June of 2019
ct_get_data(
  commodity_code = "everything",
  reporter = "CHN",
  partner  = "DEU",
  start_date = "2019",
  end_date = "2019",
  flow_direction = "import"
)


## Access package data ----

### country_codes() ----

# Country codes
head(comtradr::country_codes)


### ct_commodity_lookup() ----

# UN Comtrade commodities database query
head(comtradr::ct_commodity_lookup("wine"))


### ct_get_ref_table() ----

# Get reference table from package data

# get HS commodity table
head(ct_get_ref_table("HS"))


# get reporter table
head(ct_get_ref_table("reporter"))

# END