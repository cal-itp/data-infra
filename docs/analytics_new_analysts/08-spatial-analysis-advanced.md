(geo-advanced)=

# Working with Geospatial Data: Advanced

Place matters. After covering the [intermediate tutorial](geo-intermediate), you're ready to cover some advanced spatial analysis topics.

Below are more detailed explanations for dealing with geometry in Python.

- [Types of geometric shapes](#types-of-geometric-shapes)
- [Geometry in-memory and in databases](#geometry-in-memory-and-in-databases)

## Getting Started

```
# Import Python packages
import pandas as pd
import geopandas as gpd
from shapely.geometry import Point
from geoalchemy2 import WKTElement
```

## Types of Geometric Shapes

There are six possible geometric shapes that are represented in geospatial data. [More description here.](http://postgis.net/workshops/postgis-intro/geometries.html#representing-real-world-objects)

- `Point`
- `MultiPoint`: collection of points
- `LineString`
- `MultiLineString`: collection of linestrings, which are disconnected from each other
- `Polygon`
- `MultiPolygon`: collection of polygons, which can be disconnected or overlapping from each other

The ArcGIS equivalent of these are just points, lines, and polygons.

## Geometry In-Memory and in Databases

If you're loading a GeoDataFrame (gdf), having the `geometry` column is necessary to do spatial operations in your Python session. The `geometry` column is composed of Shapely objects, such as Point or MultiPoint, LineString or MultiLineString, and Polygon or MultiPolygon.

Databases often store geospatial information as well-known text (WKT) or its binary equivalent, well-known binary (WKB). These are well-specified interchange formats for the importing and exporting of geospatial data. Often, querying a database (PostGIS, SpatiaLite, etc) or writing data to the database requires converting the `geometry` column to/from WKT/WKB.

The spatial referencing system identifier (SRID) is the **geographic coordinate system** of the latitude and longitude coordinates. As you are writing the coordinates into WKT/WKB, don't forget to set the SRID. WGS84 is a commonly used geographic coordinate system; it provides latitude and longitude in decimal degrees. The SRID for WGS84 is 4326. [Refresher on geographic coordinated system vs projected coordinated system.](geo-basics)

*Shapely* is the Python package used to create the `geometry` column when you're working with the gdf in-memory. *Geoalchemy* is the Python package used to write the `geometry` column into geospatial databases. Unless you're writing the geospatial data into a database, you're most likely sticking with *shapely* rather than *geoalchemy*.

To summarize:

| Data is used / sourced from...      | Python Package | Geometry column                                                  | SRID/EPSG                                                                             |
| ----------------------------------- | -------------- | ---------------------------------------------------------------- | ------------------------------------------------------------------------------------- |
| Local Python session, in-memory     | shapely        | shapely object: Point, LineString, Polygon and Multi equivalents | CRS is usually set, but most likely will still need to re-project your CRS using EPSG |
| Database (PostGIS, SpatiaLite, etc) | geoalchemy     | WKT or WKB                                                       | define the SRID                                                                       |

```
# Set the SRID
srid = 4326
df = df.dropna(subset=['lat', 'lon'])
df['geometry'] = df.apply(
    lambda x: WKTElement(Point(x.lon, x.lat).wkt, srid=srid), axis = 1)
```

<br>
