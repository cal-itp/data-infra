(geo-basics)=

# Working with Geospatial Data: Basics

Place matters. That's why data analysis often includes a geospatial or geographic component. Before we wrangle with our data, let's go over the basics and make sure we're properly set up.

Below are short demos for getting started:

- [Import and export data in Python](#import-and-export-data-in-python)
- [Setting and projecting coordinate reference system](#setting-and-projecting-coordinate-reference-system)

## Getting Started

```python
# Import Python packages
import pandas as pd
import geopandas as gpd
```

(import-and-export-data-in-python)=

## Import and Export Data in Python

### **Local files**

We import a tabular dataframe `my_csv.csv` and a geodataframe `my_geojson.geojson` or `my_shapefile.shp`.

```python
df = pd.read_csv('../folder/my_csv.csv')

# GeoJSON
gdf = gpd.read_file('../folder/my_geojson.geojson')
gdf.to_file(driver = 'GeoJSON', filename = '../folder/my_geojson.geojson' )


# Shapefile (collection of files: .shx, .shp, .prj, .dbf, etc)
# The collection files must be put into a folder before importing
gdf = gpd.read_file('../folder/my_shapefile/')
gdf.to_file(driver = 'ESRI Shapefile', filename = '../folder/my_shapefile.shp' )
```

### **GCS**

To read in our dataframe (df) and geodataframe (gdf) from GCS:

```python
GCS_BUCKET = 'gs://calitp-analytics-data/data-analyses/bucket_name/'

df = pd.read_csv(f'{GCS_BUCKET}my-csv.csv')
gdf = gpd.read_file(f'{GCS_BUCKET}my-geojson.geojson')
gdf = gpd.read_parquet(f'{GCS_BUCKET}my-geoparquet.parquet')
gdf = gpd.read_file(f'{GCS_BUCKET}my-shapefile.zip')

# Write a file to GCS
gdf.to_file(f'{GCS_BUCKET}my-geojson.geojson', driver='GeoJSON')

# Using calitp_data_analysis
GCS_FILE_PATH = "gs://calitp-analytics-data/data-analyses/"
FILE_NAME = "test_geoparquet"
utils.geoparquet_gcs_export(gdf, GCS_FILE_PATH, FILE_NAME)

```

Additional general information about various file types can be found in the [Data Management section](data-management-page).

## Setting and Projecting Coordinate Reference System

A coordinate reference system (CRS) tells geopandas how to plot the coordinates on the Earth. Starting with a shapefile usually means that the CRS is already set. In that case, we are interested in re-projecting the gdf to a different CRS. The CRS is chosen specific to a region (i.e., USA, Southern California, New York, etc) or for its map units (i.e., decimal degrees, US feet, meters, etc). Map units that are US feet or meters are easier to work when it comes to defining distances (100 ft buffer, etc).

In Python, there are 2 related concepts:

1. Setting the CRS \<--> corresponds to geographic coordinate system in ArcGIS
2. Re-projecting the CRS \<--> corresponds to datum transformation and projected coordinated system in ArcGIS

The ArcGIS equivalent of this is in [3 related concepts](https://pro.arcgis.com/en/pro-app/help/mapping/properties/coordinate-systems-and-projections.htm):

1. geographic coordinate system
2. datum transformation
3. projected coordinate system

The **geographic coordinate system** is the coordinate system of the latitude and longitude points. Common ones are WGS84, NAD83, and NAD27.

**Datum transformation** is needed when the geographic coordinate systems of two layers do not match. A datum transformation is needed to convert NAD1983 into WGS84.

The **projected coordinate system** projects the coordinates onto the map. ArcGIS projects "on the fly", and applies the first layer's projection to all subsequent layers. The projection does not change the coordinates from WGS84, but displays the points from a 3D sphere onto a 2D map. The projection determines how the Earth's sphere is unfolded and flattened.

In ArcGIS, layers must have the same geographic coordinate system and projected coordinate system before spatial analysis can occur. Since ArcGIS allows you to choose the map units (i.e., feet, miles, meters) for proximity analysis, projections are chosen primarily for the region to be mapped.

In Python, the `geometry` column holds information about the geographic coordinate system and its projection. All gdfs must be set to the same CRS before performing any spatial operations between them. Changing `geometry` from WGS84 to CA State Plane is a datum transformation (WGS84 to NAD83) and projection to CA State Plane Zone 5.

```python
# Check to see what the CRS is
gdf.crs

# If there is a CRS set, you can change the projection
# Here, change to CA State Plane (units = US feet)
gdf = gdf.to_crs('EPSG:2229')
```

Sometimes, the gdf does not have a CRS set and you will need to be manually set it. This might occur if you create the `geometry` column from latitude and longitude points. More on this in the [intermediate tutorial](geo-intermediate).

There are [lots of different CRS available](https://epsg.io). The most common ones used for California are:

| EPSG | Name                  | Map Units       |
| ---- | --------------------- | --------------- |
| 4326 | WGS84                 | decimal degrees |
| 2229 | CA State Plane Zone 5 | US feet         |
| 3310 | CA Albers             | meters          |

```python
# If the CRS is not set after checking it with gdf.crs

gdf = gdf.set_crs('EPSG:4326')

```

<br>
