# 02 - Querying large amounts of data ----

library(comtradr)
library(dplyr)
library(ggplot2)

## The limits ----

# When you are on the free API tieer, you will encounter two limits when
# wanting to calculate on large datasets:

# 1. You can only make 500 calls per day

# 2. Each call can only take up to 100,000 rows.

# These limits may change and are documented at
# https://unstats.un.org/wiki/display/comtrade/New+Comtrade+FAQ+for+First+Time+Users#NewComtradeFAQforFirstTimeUsers-WhichsubscriptionscanIchoosefrom?

# When you try to fetch the maximum amount of data in the 
# minimal amount of days, you want to minimize the amount of
# requests you need by making them as comprehensive as possible,
# without exceeding the 100k row limit.


## The example - Imports of the EU ----

# Let's say we want to know which is the top exporter of the 
# EU in each product class of the Harmonic System.

# This could be useful when thinking about dependencies between
# countries, e.g. when evaluating the usefulness or impact
# or regulation such as the EUDR regulation
# (Regulation on Deforestation-free products)
# https://environment.ec.europa.eu/topics/forests/deforestation/regulation-deforestation-free-products_en

# Quoting from the ITC Trade Briefs
# https://tradebriefs.intracen.org/2023/11/spotlight
# "Under the regulation that entered into force on 29
# June 2023, any operator or trader placing [specific]
# commodities on the EU market or exporting them from
# the EU has to be able to prove that the goods do not 
# originate from deforested land (cutoff date 31 December 2020)
# or contribute to forest degradation".

# A question that arises is which are the impacts of this regulation
# on other countries and which of these are particularly important 
# to the EU?

# We want to replicate some of their numbers, e.g., the
# relevance to the EU indicator form the map of the ITC spotlight
# cited above.

# - What is the share of one country in the EU's imports of a product?

# Remember, to get Comtrade data, we need the Commodity Codes,
# the respective ISO3 codes for the country names
# and a time frame.


## 1. What are the commodity codes? ----

# First we need to find the Harmonized System (HS) codes
# for the affected goods.

# Annex 1 of the regulation
# https://eur-lex.europa.eu/legal-content/EN/TXT/?uri=CELEX%3A32023R1115&qid=1687867231461
# provides a list of the commodities in the
# product class "Wood".

wood <- c(
  "4401", "4402", "4403", "4404", "4405",
  "4406", "4407", "4408", "4409", "4410",
  "4411", "4412", "4413", "4414", "4415",
  "4416", "4417", "4418", "4419", "4420",
  "4421",
  "940330", "940340", "940350", "940360",
  "940391",
  "940610",
  "4701", "4702", "4703", "4704", "4705",
  "470610", 
  "470691", "470692", "470693",
  "48", "49",
  "9401"
  )

wood_df <- data.frame(
  cmd_code    = wood, 
  product_cat = "wood"
)

print(wood_df)


## 2. Which are the countries? ----

# We need a list of the EU-27 countries as ISO-3 codes.

# The "giscoR" package includes this information.
head(giscoR::gisco_countrycode)

eu_countries <- giscoR::gisco_countrycode |> 
  filter(eu == TRUE) |> 
  pull(ISO3_CODE)

print(eu_countries)


# Next we need a vector for all other countries, which we
# create by specifying "all_countries" in the "partner"
# argument.


## Getting the data ----

# To calculate the relevance of a product category to the EU,
# we need to know how much of a given product comes from one
# country and which share of total imports it has.


## EU imports from all countries ----

# The following query will return an object containing
# exactly 100,000 rows and a warning, that if you did not
# intend to get exactly 100,000 rows, you have most likely
# hit the limit already.


# We are trying to get data on about 39 commodity classes for
# 27 EU countries as reporters and about 190 partners,
# in 4 years.
# This potentially equals 800,000 rows (!)

if(FALSE) {
  data_eu_imports <- ct_get_data(
    commodity_code = wood,
    reporter = eu_countries,
    partner  = "all_countries",
    flow_direction = "import",
    start_date = 2018,
    end_date   = 2022
  )
}


# We break this down into a simple loop.

# We could iterate over years, but that would only get us
# down to about 200,000 rows for each year.

# Since we have 250 calls per day,
# we iterate over each EU country 
# and get the data seperately.


# initiate a new instance of an empty tibble()
library(tibble)

data_eu_imports <- tibble()

for(reporter in eu_countries) {
  # for a simple status, print the country we are at
  # the `progress` package has fancier progress bars
  print(reporter)
  
  # assign the result into a temporary object
  temp <- ct_get_data(
    commodity_code = wood,
    reporter = reporter,
    partner  = "all_countries",
    flow_direction = "import",
    start_date = 2018,
    end_date   = 2022
  )
  
  # bind the subset to the complete data
  data_eu_imports <- rbind(data_eu_imports, temp)
  
  # We do not include a sleep() command here since the
  # package already keeps track of that for you
  # and backs off when needed.
}

nrow(data_eu_imports)
# 173363

# This should be about 170,000 rows of data.


# Next we want the data for imports from the whole world
data_eu_imports_world <- ct_get_data(
  commodity_code = wood,
  reporter = eu_countries,
  partner  = "World",
  flow_direction = "import",
  start_date = 2018,
  end_date   = 2022
)

nrow(data_eu_imports_world)
# 5004

# This should be about 5,000 rows of data


## Data cleaning ----

# We merge the product category as a variable and size
# down our data 
data_eu_imports_clean <- data_eu_imports |> 
  left_join(wood_df, by = "cmd_code") |> 
  select(
    reporter_iso,
    reporter_desc,
    flow_desc,
    partner_iso,
    partner_desc,
    cmd_code,
    cmd_desc,
    product_cat,
    primary_value,
    ref_year
  ) |> 
  # we aggregate the imports by product category,
  # year and partners
  group_by(partner_iso, partner_desc, flow_desc, product_cat, ref_year) |> 
  summarise(eu_import_product_cat = sum(primary_value)) |> 
  ungroup()


data_eu_imports_world_clean <- data_eu_imports_world |> 
  left_join(wood_df, by = "cmd_code") |> 
  select(
    reporter_iso,
    reporter_desc,
    flow_desc,
    partner_iso,
    partner_desc,
    cmd_code,
    cmd_desc,
    product_cat,
    primary_value,
    ref_year
  ) |> 
  # we now aggregate the imports by the product category
  # and year over all reporters since we care about the
  # the imports of the whole EU
  group_by(product_cat, ref_year) |> 
  summarise(eu_import_product_cat_world = sum(primary_value)) |> 
  ungroup()


head(data_eu_imports_world_clean)


# relevance to the EU
relevance <- data_eu_imports_clean  |> 
  # join the two data sets
  left_join(data_eu_imports_world_clean) |> 
  # calculate the ration between world imports and imports 
  # from one partner
  mutate(
    relevance_eu = eu_import_product_cat / eu_import_product_cat_world * 100
  ) |> 
  select(-flow_desc) |> 
  ungroup()


head(relevance)


# Now we can check who has the biggest share in the 
# EU import market for wood (excluding EU countries)
top_10 <- relevance |> 
  filter(!partner_iso %in% eu_countries) |> 
  group_by(ref_year) |> 
  slice_max(order_by = relevance_eu, n = 10) |> 
  select(partner_desc, relevance_eu, ref_year) |> 
  arrange(desc(ref_year))


head(top_10, n = 10)


# We do a sanity check: 
# When summing up all the shares over one year,
# we should get to 100%.
relevance |> 
  ungroup() |> 
  group_by(ref_year) |> 
  summarise(sum = sum(relevance_eu))

# This seems to hold.


# Maybe the last year was an outlier?

# Calculate the mean relevance a country had in the
# past 5 years and get the most important countries
average_share <- relevance |> 
  filter(!partner_iso %in% eu_countries) |> 
  group_by(partner_iso, partner_desc) |> 
  summarise(mean_relevance_eu = mean(relevance_eu)) |> 
  ungroup() |> 
  slice_max(order_by = mean_relevance_eu, n = 10)


head(average_share)


ggplot(data = average_share) +
  geom_col(mapping = aes(x = reorder(partner_desc, mean_relevance_eu), y = mean_relevance_eu), fill = "brown") +
  coord_flip() +
  theme_minimal() +
  labs(
    title = "Share of EU imports",
    subtitle = "as average over last 4 years"
  ) +
  xlab("average relevance in %") +
  ylab("")

ggsave(filename = "import-share.png", width = 8, height = 4)
graphics.off()


# END