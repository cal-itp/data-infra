(publishing-geoportal)=

# Publishing data to California State Geoportal

Spatial data cannot be directly published to CKAN. The Geoportal runs on the ESRI ArcGIS Online Hub platform. The Geoportal is synced to the CA open data portal for spatial datasets, and users are able to find the same spatial dataset via [data.ca.gov](https://data.ca.gov) or [gis.data.ca.gov](https://gis.data.ca.gov).

## What is the California State Geoportal?

The California State Geoportal is a centralized geographic open data portal, which includes authoritative data and applications from a multitude of California state entities. The ESRI ArcGIS Online Hub platform provides many tools to access and view data and maps. It also enables users to tap into the broader ESRI ArcGIS Online suite of tools, either with a free public account or with a paid subscription account.

The state of California's ESRI ArcGIS instance is called the [California State Geoportal](https://gis.data.ca.gov)
Data is published through the enterprise geodatabase and made available in a variety of formats, including as ArcGIS Hub datasets, geoservices, geojsons, CSVs, KMLs, and shapefiles.

### General Process

1. Submit the required metadata and data dictionary to the Caltrans GIS team.
2. Set up permissions related to the enterprise geodatabase. Learn more about the ArcGIS Pro [file geodatabase](https://pro.arcgis.com/en/pro-app/latest/help/data/geodatabases/overview/what-is-a-geodatabase-.htm) structure.
3. Create the metadata XML to use with each layer of the file geodatabase and update that at the time of each publishing.
4. Sync your local file geodatabase to the enterprise file geodatabase.
5. Open a ticket and the GIS team will sync your latest update to the Geoportal.

### Cal-ITP data sets

1. CA transit [routes](https://gis.data.ca.gov/datasets/dd7cb74665a14859a59b8c31d3bc5a3e_0) / [stops](https://gis.data.ca.gov/datasets/900992cc94ab49dbbb906d8f147c2a72_0) - simple transformation of GTFS schedule `shapes` and `stops` from tabular to geospatial with minimum data cleaning
2. High quality transit [areas](https://gis.data.ca.gov/datasets/863e61eacbf3463ab239beb3cee4a2c3_0) and [stops](https://gis.data.ca.gov/datasets/f6c30480f0e84be699383192c099a6a4_0) - using GTFS schedule to determine whether corridors are high quality or not according to the California Public Resources Code

### Sample Workflow

Work in our `data-analyses` repository related to [publishing monthly to the Geoportal](https://github.com/cal-itp/data-analyses/tree/main/open_data/README.md)
