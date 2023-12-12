################################################################################
#### Rgee Tutorial 00 - Getting Started
################################################################################
# Clean environment
rm(list = ls())

# Load required packages
library(rgee)       # Interface to google earth engine
library(tidyverse)  # For data wrangling
library(lubridate)  # To handle dates
library(raster)     # To handle spatial data
library(viridis)    # For nice colors

# We first need to initialize rgee to log into our google account etc.
ee_Initialize()

# We should also verify that the python environment is setup correctly
ee_check()

# The easiest way to get access to a Google Earth Engine product is to search
# the online catalog (https://developers.google.com/earth-engine/datasets) and
# then to copy the link of the product into our r-script.
data <- ee$Image("CGIAR/SRTM90_V4")

<<<<<<< HEAD
# Alternatively, we could also access the same dataset as follows
data <- ee$Image$Dataset$CGIAR_SRTM90_V4

=======
>>>>>>> 6be14ed77c3b1ba24100bcf35ec77dd8f812b358
# Note that R does not load any data at this point, but merely opens a
# connection to the Google Earth Engine API. Unless data is specifically needed
# for a task, Earth Engine will not need to compute anything. This is called
# "lazy evaluation" and enables us to easily subset the data before
# computationally heavier tasks are done.

# Once the connection is open, we can get an overview of the data using the
# command "ee_print()".
ee_print(data)

# We can see that this dataset contains an "Image". While this image contains
# only one band, many images will contain multiple bands, each storing different
# information. Aside from the "Image" class, Earth Engine also uses
# "ImageCollections". This is basically a list of images and might contain
# images from different dates or spatial extents. For example, let's take a look
# at the following dataset, it contains 5221 images!
data <- ee$ImageCollection("WorldPop/GP/100m/pop")
ee_print(data)

# Sometimes the "ee_print" function does not show you all the interesting
# metadata. In this case, you can print all information as follows:
meta <- ee_print(data)
names(meta)

# Usually you will want to restrict your search to a certain area of interest.
# Let us define such an area.
aoi <- ee$Geometry$Polygon(list(
    c(8.5, 47.3)
  , c(8.5, 47.4)
  , c(8.7, 47.4)
  , c(8.7, 47.3)
))

# Instead of an area of interest, one can also define a point of interest
poi <- ee$Geometry$Point(
  c(8.6, 47.35)
)

# The "rgee" package allows us to visualize pretty much everything on a map. For
# example, we could visualize the area of interest to make sure we specified the
# coordinates correctly.
Map$centerObject(aoi, zoom = 8)
Map$addLayer(aoi) +
Map$addLayer(poi)

# One can adjust the colors of visualized objects using the "visParams"
# parameter.
Map$centerObject(aoi, zoom = 8)
Map$addLayer(aoi, visParams = list(color = "red")) +
Map$addLayer(poi, visParams = list(color = "blue"))

# If you have many objects in a plot, it also makes sense to name each object
# when visualizing
Map$centerObject(aoi, zoom = 8)
Map$addLayer(aoi, visParams = list(color = "red"), name = "AOI") +
Map$addLayer(poi, visParams = list(color = "blue"), name = "POI")
  
# Now we can use the area of interest to subset our data accordingly
data <- data$filterBounds(aoi)

# If we check again, we can see that only 105 images are left in the collection
ee_print(data)

# Similarly, we typically want to restrict our search to a specific temporal
# range. However, one needs to be careful; when you specify a daterange
# 2020-01-01 to 2020-01-02, Google Earth Engine will only return data from the
# 2020-01-01! Anyways, let's subset our data to a specific year.
data <- data$filterDate("2019-01-01", "2021-01-01")

# Again, we can see that this reduces the number of images to 10
ee_print(data)

# We could also filter the collection by the image properties. Now there are
# only two two images left, one for each year
data$first()$getInfo()
data <- data$filter(ee$Filter$eq("country", "CHE"))
ee_print(data)

# The entire process can of course be chained into a much cleaner "piped"
# workflow.
data <- ee$ImageCollection("WorldPop/GP/100m/pop")$
  filterBounds(aoi)$
  filterDate("2019-01-01", "2021-01-01")$
  filter(ee$Filter$eq("country", "CHE"))
ee_print(data)

# Let's visualize one of the layers. Note that we can only plot an image, but
# not an image collection. Thus, we'll select the first image of the collection
Map$addLayer(data$first())

# We can provide a nicer color palette as follows:
Map$centerObject(poi, zoom = 7)
Map$addLayer(data$first(), visParams = list(palette = magma(20)))

<<<<<<< HEAD
# Finally, we can stretch the colors by specifying a new minimum and maximum
# value
Map$centerObject(poi, zoom = 7)
Map$addLayer(data$first(), visParams = list(palette = magma(20), min = 0, max = 10))

=======
>>>>>>> 6be14ed77c3b1ba24100bcf35ec77dd8f812b358
# It is also pretty easy to apply a function to each image in an ImageCollection
img_sqrt <- function(img) {
  img$sqrt()
}
data_sqrt <- data$map(img_sqrt)

# Let's visualize again
Map$centerObject(poi, zoom = 7)
Map$addLayer(data_sqrt$first(), visParams = list(palette = magma(20), min = 0, max = 5))

# We can also "reduce" an ImageCollection using a summarizing function
average <- data$mean()

# Note that this turns the ImageCollection into an Image
ee_print(average)

# Let's visualize again
Map$centerObject(poi, zoom = 7)
Map$addLayer(average, visParams = list(palette = magma(20), min = 0, max = 20))

# We can even download the data (either a single Image or the entire
# ImageCollection)

# 1) For single Image
filename <- tempfile(fileext = ".tif")
ee_as_raster(data$first()
  , dsn    = filename
  , region = aoi
  , scale  = 100
)

# Load the file and plot it
pop <- raster(filename)
plot(pop, col = magma(20), main = "Population Density", horizontal = T, axes = F, box = F)

# 2) For the entire collection
dirname <- tempdir()
ee_imagecollection_to_local(data
  , dsn    = file.path(dirname, "CHE_Population")
  , region = aoi
  , scale  = 100
)

# Load the files and plot them
pop <- stack(dir(dirname, pattern = "CHE_Population.*.tif", full.names = T))
plot(pop, col = magma(20), main = "Population Density", horizontal = T, axes = F, box = F)

# Instead of downloading an Image or ImageCollection, we can also use our area
# of interest or our point of interest to extract values from the prepared
# layers
extracted_aoi <- ee_extract(data, aoi, fun = ee$Reducer$mean())
extracted_poi <- ee_extract(data, poi, fun = ee$Reducer$mean())

# Check them
extracted_aoi
extracted_poi

