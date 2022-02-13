################################################################################
#### Rgee Tutorial 02 - Temperature Data
################################################################################
# Assume we are interested in monthly temperature estimates across a certain
# region, for instance for Madagaskar.

# Clean environment
rm(list = ls())

# Load required packages
library(rgee)       # Interface to google earth engine
library(tidyverse)  # For data wrangling
library(lubridate)  # To handle dates
library(raster)     # To handle spatial data

# We first need to initialize rgee to log into our google account etc.
ee_Initialize()

# Define the location of the study site
loc <- ee$Geometry$Point(c(44.674922, -20.074504))

# Visualize the location on an interactive map
Map$centerObject(loc, zoom = 6)
Map$addLayer(loc, name = "Study Site")

# Query the data and subset to our study location and specify the daterange
dat <- ee$ImageCollection("ECMWF/ERA5/MONTHLY")$
  filterBounds(loc)$
  filterDate("2010-01-01", "2021-01-01")

# Check out the available data
ee_print(dat)

# What is the spatial resolution of the data?
metadata <- ee_print(dat)
metadata$band_nominal_scale

# Let's check the available bands (each of them contains a different type of
# data). We could also check them here:
# https://developers.google.com/earth-engine/datasets/catalog/ECMWF_ERA5_MONTHLY
metadata$img_bands_names %>%
  str_split(pattern = " ") %>%
  unlist() %>%
  print()

# Select the data we are interested in
dat <- dat$select(
    "mean_2m_air_temperature"
  , "minimum_2m_air_temperature"
  , "maximum_2m_air_temperature"
  , "total_precipitation"
)

# Check again (there are only 4 bands per image now)
ee_print(dat)

# Extract values at the study location
extracted <- ee_extract(
    x     = dat
  , y     = loc
  , sf    = F
  , fun   = ee$Reducer$mean()
  , scale = metadata$band_nominal_scale
)
  
# Do some cleaning
clim <- extracted %>%
  t() %>%
  as.data.frame() %>%
  setNames(c("Value")) %>%
  mutate(BandName = rownames(.)) %>%
  as_tibble() %>%
  mutate(Date = substr(BandName, start = 2, stop = 10) %>% ym()) %>%
  mutate(Variable = substr(BandName, start = 9, stop = nchar(BandName))) %>%
  dplyr::select(c(Date, Variable, Value)) %>%
  pivot_wider(names_from = Variable, values_from = Value) %>%
  rename(
      MaxTemperature  = maximum_2m_air_temperature
    , MinTemperature  = minimum_2m_air_temperature
    , MeanTemperature = mean_2m_air_temperature
    , Precipitation   = total_precipitation
  ) %>%
  mutate(
      MaxTemperature  = MaxTemperature - 273.15    # From kelvin to celsius
    , MinTemperature  = MinTemperature - 273.15    # From kelvin to celsius
    , MeanTemperature = MeanTemperature - 273.15   # From kelvin to celsius
  )

# Check out the cleaned data
head(extracted)
  
# Plot the data by month
clim %>%
  pivot_longer(MaxTemperature:Precipitation, names_to = "Variable", values_to = "Value") %>%
  ggplot(aes(x = month(Date), y = Value, col = year(Date), group = year(Date))) +
  geom_point(size = 0.1) +
  geom_line(size = 0.1) +
  facet_wrap("Variable", scales = "free") +
  scale_color_viridis_c(option = "magma", name = "Year") +
  scale_x_continuous(breaks = seq(0, 12, 1)) +
  theme_minimal() +
  xlab("Month") +
  ylab("Value")
