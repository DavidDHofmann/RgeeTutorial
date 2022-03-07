################################################################################
#### Rgee Tutorial 01 - Precipitation Data
################################################################################
# Assume we are interested in daily rainfall estimates across a certain region,
# for instance for the wild dog study area in Bots.

# Clean environment
rm(list = ls())

# Load required packages
library(rgee)       # Interface to google earth engine
library(tidyverse)  # For data wrangling
library(lubridate)  # To handle dates
library(viridis)    # For nice colors

# We first need to initialize rgee to log into our google account etc.
ee_Initialize()

# Make sure all python dependencies are installed
ee_check()

# Define an area of interest, this time in Bots :)
aoi <- ee$Geometry$Polygon(
  list(
      c(21, -21)
    , c(21, -17)
    , c(28, -17)
    , c(28, -21)
  )
)

# Visualize it
Map$centerObject(aoi, zoom = 6)
Map$addLayer(aoi, opacity = 0.2, name = "AOI")

# We will use the CHIRPS daily dataset for this. This is an image collection
# with daily images collected over multiple years
# (https://developers.google.com/earth-engine/datasets/catalog/UCSB-CHG_CHIRPS_DAILY?hl=en)
chirps <- ee$ImageCollection("UCSB-CHG/CHIRPS/DAILY")
ee_print(chirps)

# Check the spatial resolution (in meters)
metadata <- ee_print(chirps)
metadata$band_nominal_scale

# We can see that the collection contains several thousand images, as it spans
# several years. Let's subset the data by year
chirps <- ee$ImageCollection("UCSB-CHG/CHIRPS/DAILY")$
  filterDate("2020", "2022")$
  filterBounds(aoi)

# Check again
ee_print(chirps)

# Note that by default the image metadata is derived from the first of all
# images (index = 0). However, we could also request the metadata of a specific
# image by providing its index.
ee_print(chirps, img_index = 10)

# We can visualize one of the layers
Map$centerObject(aoi)
Map$addLayer(chirps$first()
  , visParams = list(min = 1, max = 20, palette = turbo(12))
  , name      = "CHIRPS"
)

# It's now quite easy to compute the average rainfall across all dates. We
# simply need to apply the appropriate "reducer" function
precip_mean <- chirps$mean()

# Visualize the resulting image (this might be a bit slow)
Map$centerObject(aoi, zoom = 5)
Map$addLayer(precip_mean, visParams = list(min = 1, max = 10, palette = turbo(12)), name = "CHIRPS Mean")

# Anyways, let's come back to our initial goal and figure out daily rainfalls
# across our area of interest. We can find out the exact numbers by "extracting"
# precipitation values below the polygon "aoi" polygon. This will take a few
# seconds though. Also note that we need to provide a function which determines
# how extracted numbers across a polygon are treated.
precip <- ee_extract(
    x     = chirps
  , y     = aoi
  , fun   = ee$Reducer$mean()
  , scale = metadata$band_nominal_scale
)

# Let's take a glimpse at the resulting data
precip[1:10]

# The data is a bit messy so we need to clean up. Most importantly, we need to
# parse the dates which are currently stored as names!
precip <- precip %>%
  t() %>%
  as.data.frame() %>%
  setNames("Precipitation") %>%
  mutate(Layername = rownames(.)) %>%
  mutate(Date = substr(Layername, start = 2, stop = 9)) %>%
  mutate(Date = ymd(Date)) %>%
  dplyr::select(Date, Precipitation)

# Now we can plot it
ggplot(precip, aes(x = Date, y = Precipitation)) +
  geom_point(alpha = 0.5, col = "cornflowerblue") +
  theme_minimal()
