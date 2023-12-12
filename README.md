# rgee Tutorial
`rgee` is a [powerful R-package](https://github.com/r-spatial/rgee) that allows
you to access and manipulate data from [Google Earth
Engine](https://earthengine.google.com/). Google Earth Engine hosts a massive number of
spatial datasets and offers the possiblity of processing huge amounts of data
online, without the need for local processing power. To get a feeling for the
different datasets, check out the
[catalog](https://developers.google.com/earth-engine/datasets). In this
repository, I compiled a few R-scripts that exemplify how you can use the
`rgee` package to access, manipulate, and download data from Google Earth
Engine. The repository comprises three files:
- `00_GettingStarted.r`: A simple introduction to the basic syntax of `rgee`
  and how you can specify an area of interest, access a dataset, filter to a
  desired range of dates, and download the respective data.
- `01_Precipitation.r`: Example where we access and download precipitation data
  from the [CHIRPS](https://www.chc.ucsb.edu/data/chirps) dataset.
- `02_Temperature.r`: Example where we access and download temperature data
  from the
  [ERA5](https://cds.climate.copernicus.eu/cdsapp#!/dataset/reanalysis-era5-single-levels?tab=overview)
  dataset.
- `03_DigitalElevationModel.r`: Example where we access and visualize a digital
  elevation model.

