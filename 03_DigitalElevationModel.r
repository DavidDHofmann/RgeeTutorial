################################################################################
#### Rgee Tutorial 03 - Digital Elevation Model
################################################################################
# Let's say we are interested in a digital elevation model (DEM) of Switzerland

# Clean environment
rm(list = ls())

# Load required packages
library(rgee)       # Interface to google earth engine
library(tidyverse)  # For data wrangling
library(lubridate)  # To handle dates
library(raster)     # To handle spatial data

# We first need to initialize rgee to log into our google account etc.
ee_Initialize()

# Define an aoi
aoi <- ee$Geometry$Polygon(list(
    c(5, 45)
  , c(5, 48)
  , c(11, 48)
  , c(11, 45)
))

# Plot the area of interest
Map$centerObject(aoi)
Map$addLayer(aoi, name = "AOI")

# Access the data of interest:
# https://developers.google.com/earth-engine/datasets/catalog/CGIAR_SRTM90_V4?hl=en
dem <- ee$Image("CGIAR/SRTM90_V4")

# To check the content of the image, run the command "ee_print"
ee_print(dem)

# Check out the resolution of the dataset
metadata <- ee_print(dem)
metadata$band_nominal_scale

# We can try to visualize it, but it will look a bit bland at first
Map$addLayer(dem, name = "DEM")

# The problem is, that we need to tell the visualizer how it needs to color
# different values
Map$centerObject(aoi)
Map$addLayer(dem, visParams = list(min = 0, max = 4000), name = "DEM")

# The plot still looks a bit dull. Instead of visualizing the elevation itself,
# let's calculate the hillshade and visualize this instead!
Radians <- function(img) {
  img$toFloat()$multiply(base::pi)$divide(180)
}
Hillshade <- function(az, ze, slope, aspect) {
  azimuth <- Radians(ee$Image(az))
  zenith <- Radians(ee$Image(ze))
  azimuth$subtract(aspect)$cos()$
    multiply(slope$sin())$
    multiply(zenith$sin())$
    add(zenith$cos()$multiply(slope$cos()))
}

# Apply the function to our dem
terrain    <- ee$Algorithms$Terrain(dem)
slope_img  <- Radians(terrain$select("slope"))
aspect_img <- Radians(terrain$select("aspect"))
hillshade_img <- Hillshade(0, 60, slope_img, aspect_img)

# Visualize the hillshade
Map$addLayer(hillshade_img, name = "Hillshade")

# If we're only interested in a specific region, we can also clip the data
Map$centerObject(aoi)
Map$addLayer(hillshade_img$clip(aoi), name = "Hillshade")

# Let's add some cool colors
Map$centerObject(aoi)
Map$addLayer(dem, visParams = list(min = 0, max = 2000, palette = terrain.colors(12)), name = "DEM") +
  Map$addLayer(hillshade_img, visParams = list(opacity = 0.6), name = "Hillshade")

# What if we want to add a layer indicating water? EASY!
water <- ee$Image("MODIS/MOD44W/MOD44W_005_2000_02_24")
ee_print(water)

# This contains more then one band, yet we only need the watermask
water <- water$select("water_mask")
ee_print(water)

# The image is 0 for dryland and 1 for water. Let's create a mask for everything
# that is water
mask <- water$eq(1)

# Remove anything that is not covered by the mask
water <- water$updateMask(mask)

# Visualize again
Map$centerObject(aoi)
Map$addLayer(dem, visParams = list(min = 0, max = 2000, palette = terrain.colors(12)), name = "DEM") +
  Map$addLayer(hillshade_img, visParams = list(opacity = 0.6), name = "Hillshade") +
  Map$addLayer(water, visParams = list(min = 1, max = 1, palette = c("cornflowerblue")), name = "Watermask")
