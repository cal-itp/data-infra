(geo-intermediate)=

# Working with Geospatial Data: Intermediate

After breezing through the [intro tutorial](geo-intro), you're ready to take your spatial analysis to the next level.

Below are short demos of other common manipulations of geospatial data.

- [Create geometry column from latitude and longitude coordinates](#create-geometry-column-from-latitude-and-longitude-coordinates)
- [Create geometry column from text](#create-geometry-column-from-text)
- [Use a loop to do spatial joins and aggregations over different boundaries](#use-a-loop-to-do-spatial-joins-and-aggregations-over-different-boundaries)
- [Multiple geometry columns](#multiple-geometry-columns)

## Getting Started

```
# Import Python packages
import pandas as pd
import geopandas as gpd
from shapely.geometry import Point

df = pd.read_csv('../folder/pawnee_businesses.csv')
```

| Business      | X   | Y   | Sales_millions |
| ------------- | --- | --- | -------------- |
| Paunch Burger | x1  | y1  | 5              |
| Sweetums      | x2  | y2  | 30             |
| Jurassic Fork | x3  | y3  | 2              |
| Gryzzl        | x4  | y4  | 40             |

## Create Geometry Column from Latitude and Longitude Coordinates

Sometimes, latitude and longitude coordinates are given in a tabular form. The file is read in as a dataframe (df), but it needs to be converted into a geodataframe (gdf). The `geometry` column contains a Shapely object (point, line, or polygon), and is what makes it a <b>geo</b>dataframe. A gdf can be exported as GeoJSON, parquet, or shapefile.

In ArcGIS/QGIS, this is equivalent to adding XY data, selecting the columns that correspond to latitude and longitude, and exporting the layer as a shapefile.

First, drop all the points that are potentially problematic (NAs or zeroes).

```
# Drop NAs
df = df.dropna(subset=['X', 'Y'])

# Keep non-zero values for X, Y
df = df[(df.X != 0) & (df.Y != 0)]
```

Then, create the `geometry` column.  We use a lambda function and apply it to all rows in our df. For every row, take the XY coordinates and make it Point(X,Y). Make sure you set the projection (coordinate reference system)!

```
# Rename columns
df.rename(columns = {'X': 'longitude', 'Y':'latitude'}, inplace=True)

# Create geometry column
geom_col = gpd.points_from_xy(df.longitude, df.latitude, crs="EPSG:4326")
gdf = gpd.GeoDataFrame(df, geometry=geom_col, crs = "EPSG:4326")

# Project to different CRS. Pawnee is in Indiana, so we'll use EPSG:2965.
# In Southern California, use EPSG:2229.
gdf = gdf.to_crs('EPSG:2965')

gdf
```

| Business      | longitude | latitude | Sales_millions | geometry      |
| ------------- | --------- | -------- | -------------- | ------------- |
| Paunch Burger | x1        | y1       | 5              | Point(x1, y1) |
| Sweetums      | x2        | y2       | 30             | Point(x2, y2) |
| Jurassic Fork | x3        | y3       | 2              | Point(x3, y3) |
| Gryzzl        | x4        | y4       | 40             | Point(x4, y4) |

## Create Geometry Column from Text

If you are importing your df directly from a CSV or database, the geometry information might be stored as as text. To create our geometry column, we extract the latitude and longitude information and use these components to create a Shapely object.

`df` starts off this way, with column `Coord` stored as text:

| Business      | Coord    | Sales_millions |
| ------------- | -------- | -------------- |
| Paunch Burger | (x1, y1) | 5              |
| Sweetums      | (x2, y2) | 30             |
| Jurassic Fork | (x3, y3) | 2              |
| Gryzzl        | (x4, y4) | 40             |

First, we split `Coord` at the comma.

```
# We want to expand the result into multiple columns.
# Save the result and call it new.
new = df.Coord.str.split(", ", expand = True)
```

Then, extract our X, Y components. Put lat, lon into a Shapely object as demonstrated [in the prior section.](#create-geometry-column-from-latitude-and-longitude-coordinates)

```
# Make sure only numbers, not parentheses, are captured. Cast it as float.

# 0 corresponds to the portion before the comma. [1:] means starting from
# the 2nd character, right after the opening parenthesis, to the comma.
df['lat'] = new[0].str[1:].astype(float)

# 1 corresponds to the portion after the comma. [:-1] means starting from
# right after the comma to the 2nd to last character from the end, which
# is right before the closing parenthesis.
df['lon'] = new[1].str[:-1].astype(float)
```

Or, do it in one swift move:

```
df['geometry'] = df.dropna(subset=['Coord']).apply(
    lambda x: Point(
        float(str(x.Coord).split(",")[0][1:]),
        float(str(x.Coord).split(",")[1][:-1])
        ), axis = 1)


# Now that you have a geometry column, convert to gdf.
gdf = gpd.GeoDataFrame(df)

# Set the coordinate reference system. You must set it first before you
# can project.
gdf = df.set_crs('EPSG:4326')
```

## Use a Loop to Do Spatial Joins and Aggregations Over Different Boundaries

Let's say we want to do a spatial join between `df` to 2 different boundaries. Different government departments often use different boundaries for their operations (i.e. city planning districts, water districts, transportation districts, etc). Looping over dictionary items would be an efficient way to do this.

We want to count the number of stores and total sales within each Council District and Planning District.

`df`: list of Pawnee stores

| Business      | longitude | latitude | Sales_millions | geometry      |
| ------------- | --------- | -------- | -------------- | ------------- |
| Paunch Burger | x1        | y1       | 5              | Point(x1, y1) |
| Sweetums      | x2        | y2       | 30             | Point(x2, y2) |
| Jurassic Fork | x3        | y3       | 2              | Point(x3, y3) |
| Gryzzl        | x4        | y4       | 40             | Point(x4, y4) |

`council_district` and `planning_district` are polygon shapefiles while `df` is a point shapefile. For simplicity, `council_district` and `planning_district` both use column `ID` as the unique identifier.

```
# Save the dataframes into dictionaries
boundaries = {'council': council_district, 'planning': planning_district}

# Create empty dictionaries to hold our results
results = {}


# Loop over different boundaries (council, planning)
for key, value in boundaries.items():
    # Define new variables using f string
    join_df = f"{key}_join"
    agg_df = f"{key}_summary"

    # Spatial join, but don't save it into the results dictionary
    join_df = gpd.sjoin(df, value, how = 'inner', predicate = 'intersects')

    # Aggregate and save results into results dictionary
    results[agg_df] = join_df.groupby('ID').agg(
        {'Business': 'count', 'Sales_millions': 'sum'})
```

Our results dictionary contains 2 dataframes: `council_summary` and `planning_summary`. We can see the contents of the results dictionary using this:

```
for key, value in results.items():
    display(key)
    display(value.head())


# To access the "dataframe", write this:
results["council_summary"].head()
results["planning_summary"].head()
```

`council_summary` would look like this, with the total count of Business and sum of Sales_millions within the council district:

| ID  | Business | Sales_millions |
| --- | -------- | -------------- |
| 1   | 2        | 45             |
| 2   | 1        | 2              |
| 3   | 1        | 30             |

## Multiple Geometry Columns

Sometimes we want to iterate over different options, and we want to see the results side-by-side. Here, we draw multiple buffers around `df`, specifically, 100 ft and 200 ft buffers.

```
# Make sure our projection has US feet as its units
df.to_crs('EPSG:2965')

# Add other columns for the different buffers
df['geometry100'] = df.geometry.buffer(100)
df['geometry200'] = df.geometry.buffer(200)

df
```

| Business      | Sales_millions | geometry      | geometry100 | geometry200 |
| ------------- | -------------- | ------------- | ----------- | ----------- |
| Paunch Burger | 5              | Point(x1, y1) | polygon     | polygon     |
| Sweetums      | 30             | Point(x2, y2) | polygon     | polygon     |
| Jurassic Fork | 2              | Point(x3, y3) | polygon     | polygon     |
| Gryzzl        | 40             | Point(x4, y4) | polygon     | polygon     |

To create a new gdf with just 100 ft buffers, select the relevant geometry column, `geometry100`, and set it as the geometry of the gdf.

```
df100 = df[['Business', 'Sales_millions',
    'geometry100']].set_geometry('geometry100')
```

<br>
