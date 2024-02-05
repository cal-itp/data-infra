(geo-intro)=

# Working with Geospatial Data: Intro

Place matters. That's why data analysis often includes a geospatial or geographic component. Data analysts are called upon to merge tabular and geospatial data, count the number of points within given boundaries, and create a map illustrating the results.

Below are short demos of common techniques to help get you started with exploring your geospatial data.

- [Merge tabular and geospatial data](#merge-tabular-and-geospatial-data)
- [Attach geographic characteristics to all points or lines that fall within a boundary (spatial join and dissolve)](#attach-geographic-characteristics-to-all-points-or-lines-that-fall-within-a-boundary)
- [Aggregate and calculate summary statistics](#aggregate-and-calculate-summary-statistics)
- [Buffers](#buffers)

## Getting Started

```python
# Import Python packages
import pandas as pd
import geopandas as gpd
```

(merge-tabular-and-geospatial-data)=

## Merge Tabular and Geospatial Data

We have two files: Council District boundaries (geospatial) and population values (tabular). Through visual inspection, we know that `CD` and `District` are columns that help us make this match.

`df`: population by council district

| CD  | Council_Member  | Population |
| --- | --------------- | ---------- |
| 1   | Leslie Knope    | 1,500      |
| 2   | Jeremy Jamm     | 2,000      |
| 3   | Douglass Howser | 2,250      |

`gdf`: council district boundaries

| District | Geometry |
| -------- | -------- |
| 1        | polygon  |
| 2        | polygon  |
| 3        | polygon  |

We could merge these two dfs using the District and CD columns. If our left df is a geodataframe (gdf), then our merged df will also be a gdf.

```python
merge = pd.merge(gdf, df, left_on = 'District', right_on = 'CD')
merge
```

| District | Geometry | CD  | Council_Member  | Population |
| -------- | -------- | --- | --------------- | ---------- |
| 1        | polygon  | 1   | Leslie Knope    | 1,500      |
| 2        | polygon  | 2   | Jeremy Jamm     | 2,000      |
| 3        | polygon  | 3   | Douglass Howser | 2,250      |

(attach-geographic-characteristics-to-all-points-or-lines-that-fall-within-a-boundary)=

## Attach Geographic Characteristics to All Points or Lines That Fall Within a Boundary

Sometimes with a point shapefile (list of lat/lon points), we want to count how many points fall within the boundary. Unlike the previous example, these points aren't attached with Council District information, so we need to generate that ourselves.

The ArcGIS equivalent of this is a **spatial join** between the point and polygon shapefiles, then **dissolving** to calculate summary statistics.

```python
locations = gpd.read_file('../folder/paunch_burger_locations.geojson')
gdf = gpd.read_file('../folder/council_boundaries.geojson')

# Make sure both our gdfs are projected to the same coordinate reference system
# (EPSG:4326 = WGS84)
locations = locations.to_crs('EPSG:4326')
gdf = gdf.to_crs('EPSG:4326')

```

`locations` lists the Paunch Burgers locations and their annual sales.

| Store | City         | Sales_millions | Geometry |
| ----- | ------------ | -------------- | -------- |
| 1     | Pawnee       | $5             | (x1,y1)  |
| 2     | Pawnee       | $2.5           | (x2, y2) |
| 3     | Pawnee       | $2.5           | (x3, y3) |
| 4     | Eagleton     | $2             | (x4, y4) |
| 5     | Pawnee       | $4             | (x5, y5) |
| 6     | Pawnee       | $6             | (x6, y6) |
| 7     | Indianapolis | $7             | (x7, y7) |

`gdf` is the Council District boundaries.

| District | Geometry |
| -------- | -------- |
| 1        | polygon  |
| 2        | polygon  |
| 3        | polygon  |

A spatial join finds the Council District the location falls within and attaches that information.

```python
join = gpd.sjoin(locations, gdf, how = 'inner', predicate = 'intersects')

# how = 'inner' means that we only want to keep observations that matched,
# i.e locations that were within the council district boundaries.
# predicate = 'intersects' means that we are joining based on whether or not the location
# intersects with the council district.
```

The `join` gdf looks like this. We lost Stores 4 (Eagleton) and 7 (Indianapolis) because they were outside of Pawnee City Council boundaries.

| Store | City   | Sales_millions | Geometry_x | District | Geometry_y |
| ----- | ------ | -------------- | ---------- | -------- | ---------- |
| 1     | Pawnee | $5             | (x1,y1)    | 1        | polygon    |
| 2     | Pawnee | $2.5           | (x2, y2)   | 2        | polygon    |
| 3     | Pawnee | $2.5           | (x3, y3)   | 3        | polygon    |
| 5     | Pawnee | $4             | (x5, y5)   | 1        | polygon    |
| 6     | Pawnee | $6             | (x6, y6)   | 2        | polygon    |

(aggregate-and-calculate-summary-statistics)=

## Aggregate and Calculate Summary Statistics

We want to count the number of Paunch Burger locations and their total sales within each District.

```python

summary = join.pivot_table(
    index = ['District'],
    values = ['Store', 'Sales_millions'],
    aggfunc = {'Store': 'count', 'Sales_millions': 'sum'}
).reset_index()

OR

summary = (join.groupby(['District'])
            .agg({
                'Store': 'count',
                'Sales_millions': 'sum'}
            ).reset_index()
          )

# Make sure to merge in district geometry again
summary = pd.merge(
    gdf,
    summary,
    on = 'District',
    how = 'inner'
)

summary
```

| District | Store | Sales_millions | Geometry |
| -------- | ----- | -------------- | -------- |
| 1        | 2     | $9             | polygon  |
| 2        | 2     | $8.5           | polygon  |
| 3        | 1     | $2.5           | polygon  |

By keeping the `Geometry` column, we're able to export this as a GeoJSON or shapefile.

```python
summary.to_file(driver = 'GeoJSON',
    filename = '../folder/pawnee_sales_by_district.geojson')

summary.to_file(driver = 'ESRI Shapefile',
    filename = '../folder/pawnee_sales_by_district.shp')
```

(buffers)=

## Buffers

Buffers are areas of a certain distance around a given point, line, or polygon. Buffers are used to determine <i> proximity</i>. A 5 mile buffer around a point would be a circle of 5 mile radius centered at the point. This [ESRI page](http://desktop.arcgis.com/en/arcmap/10.3/tools/analysis-toolbox/buffer.htm) shows how buffers for points, lines, and polygons look.

Some examples of questions that buffers help answer are:

- How many stores are within 1 mile of my house?
- Which streets are within 5 miles of the mall?
- Which census tracts or neighborhoods are within a half mile from the rail station?

Small buffers can also be used to determine whether 2 points are located in the same place. A shopping mall or the park might sit on a large property. If points are geocoded to various areas of the mall/park, they would show up as 2 distinct locations, when in reality, we consider them the same location.

We start with two point shapefiles: `locations` (Paunch Burger locations) and `homes` (home addresses for my 2 friends). The goal is to find out how many Paunch Burgers are located within a 2 miles of my friends.

`locations`: Paunch Burger locations

| Store | City         | Sales_millions | Geometry |
| ----- | ------------ | -------------- | -------- |
| 1     | Pawnee       | $5             | (x1,y1)  |
| 2     | Pawnee       | $2.5           | (x2, y2) |
| 3     | Pawnee       | $2.5           | (x3, y3) |
| 4     | Eagleton     | $2             | (x4, y4) |
| 5     | Pawnee       | $4             | (x5, y5) |
| 6     | Pawnee       | $6             | (x6, y6) |
| 7     | Indianapolis | $7             | (x7, y7) |

`homes`: friends' addresses

| Name         | Geometry |
| ------------ | -------- |
| Leslie Knope | (x8, y8) |
| Ann Perkins  | (x9, y9) |

First, prepare our point gdf and change it to the right projection. Pawnee is in Indiana, so we'll use EPSG:2965.

```python
# Use NAD83/Indiana East projection (units are in feet)
homes = homes.to_crs('EPSG:2965')
locations = locations.to_crs('EPSG:2965')
```

Next, draw a 2 mile buffer around `homes`.

```python
# Make a copy of the homes gdf
homes_buffer = homes.copy()

# Overwrite the existing geometry and change it from point to polygon
miles_to_feet = 5280
two_miles = 2 * miles_to_feet
homes_buffer['geometry'] = homes.geometry.buffer(two_miles)
```

### **Select Points Within a Buffer**

Do a spatial join between `locations` and `homes_buffer`. Repeat the process of spatial join and aggregation in Python as illustrated in the previous section (spatial join and dissolve in ArcGIS).

```python
sjoin = gpd.sjoin(
    locations,
    homes_buffer,
    how = 'inner',
    predicate = 'intersects'
)

sjoin
```

`sjoin` looks like this (without `Geometry_y` column). Using `how='left' or how='inner'` will show `Geometry_x` as the resulting geometry column, while using `how = 'right'` would show `Geometry_y` as the resulting geometry column. Only one geometry column is returned in a spatial join, but you have the flexibility in determining which one it is by changing `how=`.

- Geometry_x is the point geometry from our left df `locations`.
- Geometry_y is the polygon geometry from our right df `homes_buffer`.

| Store | Geometry_x | Name         | Geometry_y |
| ----- | ---------- | ------------ | ---------- |
| 1     | (x1,y1)    | Leslie Knope | polygon    |
| 3     | (x3, y3)   | Ann Perkins  | polygon    |
| 5     | (x5, y5)   | Leslie Knope | polygon    |
| 6     | (x6, y6)   | Leslie Knope | polygon    |

Count the number of Paunch Burger locations for each friend.

```python
count = sjoin.pivot_table(index = 'Name',
    values = 'Store', aggfunc = 'count').reset_index()

OR

count = sjoin.groupby('Name').agg({'Store':'count'}).reset_index()
```

The final `count`:

| Name         | Store |
| ------------ | ----- |
| Leslie Knope | 3     |
| Ann Perkins  | 1     |

<br>
