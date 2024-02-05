(pandas-intro)=

# Data Analysis: Intro

Below are Python tutorials covering the basics of data cleaning and wrangling. [Chris Albon's guide](https://chrisalbon.com/#python) is particularly helpful. Rather than reinventing the wheel, this tutorial instead highlights specific methods and operations that might make your life easier as a data analyst.

- [Import and export data in Python](#data-analysis-import-and-export-data-in-python)
- [Merge tabular and geospatial data](#data-analysis-merge-tabular-and-geospatial-data)
- [Functions](#functions)
- [Grouping](#grouping)
- [Aggregating](#aggregating)
- [Export aggregated output](#export-aggregated-output)

## Getting Started

```python
import numpy as np
import pandas as pd
import geopandas as gpd
```

(data-analysis-import-and-export-data-in-python)=

## Import and Export Data in Python for Data Analysis

### **Local files**

We import a tabular dataframe `my_csv.csv` and an Excel spreadsheet `my_excel.xlsx`.

```python
df = pd.read_csv('./folder/my_csv.csv')

df = pd.read_excel('./folder/my_excel.xlsx', sheet_name = 'Sheet1')
```

### **GCS**

The data we use outside of the warehouse can be stored in GCS buckets.

```python
# Read from GCS
df = pd.read_csv('gs://calitp-analytics-data/data-analyses/bucket-name/df_csv.csv')

#Write to GCS
df.to_csv('gs://calitp-analytics-data/data-analyses/bucket-name/df_csv.csv')
```

Refer to the [Data Management best practices](data-management-page) and [Basics of Working with Geospatial Data](geo-intro) for additional information on importing various file types.

(data-analysis-merge-tabular-and-geospatial-data)=

## Merge Tabular and Geospatial Data for Data Analysis

Merging data from multiple sources creates one large dataframe (df) to perform data analysis. Let's say there are 3 sources of data that need to be merged:

Dataframe #1: `council_population` (tabular)

| CD  | Council_Member  | Population |
| --- | --------------- | ---------- |
| 1   | Leslie Knope    | 1,500      |
| 2   | Jeremy Jamm     | 2,000      |
| 3   | Douglass Howser | 2,250      |

Dataframe #2: `paunch_locations` (geospatial)

| Store | City         | Sales_millions | CD  | Geometry |
| ----- | ------------ | -------------- | --- | -------- |
| 1     | Pawnee       | $5             | 1   | (x1,y1)  |
| 2     | Pawnee       | $2.5           | 2   | (x2, y2) |
| 3     | Pawnee       | $2.5           | 3   | (x3, y3) |
| 4     | Eagleton     | $2             |     | (x4, y4) |
| 5     | Pawnee       | $4             | 1   | (x5, y5) |
| 6     | Pawnee       | $6             | 2   | (x6, y6) |
| 7     | Indianapolis | $7             |     | (x7, y7) |

If `paunch_locations` did not come with the council district information, use a spatial join to attach the council district within which the store falls. More on spatial joins [here](geo-intro).

Dataframe #3: `council_boundaries` (geospatial)

| District | Geometry |
| -------- | -------- |
| 1        | polygon  |
| 2        | polygon  |
| 3        | polygon  |

First, merge `paunch_locations` with `council_population` using the `CD` column, which they have in common.

```python
merge1 = pd.merge(
    paunch_locations,
    council_population,
    on = 'CD',
    how = 'inner',
    validate = 'm:1'
)

# m:1 many-to-1 merge means that CD appears multiple times in
# paunch_locations, but only once in council_population.
```

Next, merge `merge1` and `council_boundaries`. Columns don't have to have the same names to be matched on, as long as they hold the same values.

```python
merge2 = pd.merge(
    merge1,
    council_boundaries,
    left_on = 'CD',
    right_on = 'District',
    how = 'left',
    validate = 'm:1'
)
```

Here are some things to know about `merge2`:

- `merge2` is a geodataframe (gdf) because the ***base,*** `paunch_locations`, is a gdf.
- Pandas allows the merge to take place even if the `Geometry` column appears in both dfs. The resulting df contains 2 renamed `Geometry` columns;  `Geometry_x` corresponds to the left df `Geometry` and `Geometry_y` for the right df.
- Geopandas still designates a geometry to use. To see what which geometry column is set, type `merge2.geometry.name`. To change the geometry to a different column, type `merge2 = merge2.set_geometry('new_column')`.

`merge2` looks like this:

| Store | City   | Sales_millions | CD  | Geometry_x | Council_Member  | Population | Geometry_y |
| ----- | ------ | -------------- | --- | ---------- | --------------- | ---------- | ---------- |
| 1     | Pawnee | $5             | 1   | (x1,y1)    | Leslie Knope    | 1,500      | polygon    |
| 2     | Pawnee | $2.5           | 2   | (x2, y2)   | Jeremy Jamm     | 2,000      | polygon    |
| 3     | Pawnee | $2.5           | 3   | (x3, y3)   | Douglass Howser | 2,250      | polygon    |
| 5     | Pawnee | $4             | 1   | (x5, y5)   | Leslie Knope    | 1,500      | polygon    |
| 6     | Pawnee | $6             | 2   | (x6, y6)   | Jeremy Jamm     | 2,000      | polygon    |

(functions)=

## Functions

A function is a set of instructions to *do something*. It can be as simple as changing values in a column or as complicated as a series of steps to clean, group, aggregate, and plot the data.

### **Lambda Functions**

Lambda functions are quick and dirty. You don't even have to name the function! These are used for one-off functions that you don't need to save for repeated use within the script or notebook. You can use it for any simple function (e.g., if-else statements, etc) you want to apply to all rows of the df.

`df`: Andy Dwyer's band names and number of songs played under that name

| Band                       | Songs |
| -------------------------- | ----- |
| Mouse Rat                  | 30    |
| Scarecrow Boat             | 15    |
| Jet Black Pope             | 4     |
| Nothing Rhymes with Orange | 6     |

### **If-Else Statements**

```python
# Create column called duration. If Songs > 10, duration is 'long'.
# Otherwise, duration is 'short'.
df['duration'] = df.apply(lambda row: 'long' if row.Songs > 10
                else 'short', axis = 1)

# Create column called famous. If Band is 'Mouse Rat', famous is 1,
# otherwise 0.
df['famous'] = df.apply(lambda row: 1 if row.Band == 'Mouse Rat'
                else 0, axis = 1)

# An equivalent full function would be:
def tag_famous(row):
    if row.Band == 'Mouse Rat':
        return 1
    else:
        return 0

df['famous'] = df.apply(tag_famous, axis = 1)

df
```

| Band                       | Songs | duration | famous |
| -------------------------- | ----- | -------- | ------ |
| Mouse Rat                  | 30    | long     | 1      |
| Scarecrow Boat             | 15    | long     | 0      |
| Jet Black Pope             | 4     | short    | 0      |
| Nothing Rhymes with Orange | 6     | short    | 0      |

### **Other Lambda Functions**

```python
# Split the band name at the spaces
# [1] means we want to extract the second word
# [0:2] means we want to start at the first character
# and stop at (but not include) the 3rd character
df['word2_start'] = df.apply(lambda x:
                    x.Band.split(" ")[1][0:2], axis = 1)
df
```

| Band                       | Songs | word2_start |
| -------------------------- | ----- | ----------- |
| Mouse Rat                  | 30    | Ra          |
| Scarecrow Boat             | 15    | Bo          |
| Jet Black Pope             | 4     | Po          |
| Nothing Rhymes with Orange | 6     | Or          |

### **Apply over Dataframe**

You should use a full function when a function is too complicated to be a lambda function. These functions are defined by a name and are called upon to operate on the rows of a dataframe. You can also write more complex functions that bundle together all the steps (including nesting more functions) you want to execute over the dataframe.

`df.apply` is one common usage of a function.

```python
def years_active(row):
    if row.Band == 'Mouse Rat':
        return '2009-2014'
    elif row.Band == 'Scarecrow Boat':
        return '2009'
    elif (row.Band == 'Jet Black Pope') or (row.Band ==
    'Nothing Rhymes with Orange'):
        return '2008'

df['Active'] = df.apply(years_active, axis = 1)
df
```

| Band                       | Songs | Active    |
| -------------------------- | ----- | --------- |
| Mouse Rat                  | 30    | 2009-2014 |
| Scarecrow Boat             | 15    | 2009      |
| Jet Black Pope             | 4     | 2008      |
| Nothing Rhymes with Orange | 6     | 2008      |

(grouping)=

## Grouping

Sometimes it's necessary to create a new column to group together certain values of a column. Here are two ways to accomplish this:

<b>Method #1</b>: Write a function using if-else statement and apply it using a lambda function.

```python
# The function is called elected_year, and it operates on every row.
def elected_year(row):
    # For each row, if Council_Member says 'Leslie Knope', then return 2012
    # as the value.
    if row.Council_Member == 'Leslie Knope':
        return 2012
    elif row.Council_Member == 'Jeremy Jamm':
        return 2008
    elif row.Council_Member == 'Douglass Howser':
        return 2006

# Use a lambda function to apply the elected_year function to all rows in the df.
# Don't forget axis = 1 (apply function to all rows)!
council_population['Elected'] = council_population.apply(lambda row:
    elected_year(row), axis = 1)

council_population
```

| CD  | Council_Member  | Population | Elected |
| --- | --------------- | ---------- | ------- |
| 1   | Leslie Knope    | 1,500      | 2012    |
| 2   | Jeremy Jamm     | 2,000      | 2008    |
| 3   | Douglass Howser | 2,250      | 2006    |

<b>Method #2</b>: Loop over every value, fill in the new column value, then attach that new column.

```python
# Create a list to store the new column
sales_group = []

for row in paunch_locations['Sales_millions']:
    # If sales are more than $3M, but less than $5M, tag as moderate.
    if (row >= 3) and (row <= 5):
        sales_group.append('moderate')
    # If sales are more than $5M, tag as high.
    elif row >=5:
        sales_group.append('high')
    # Anything else, aka, if sales are less than $3M, tag as low.
    else:
        sales_group.append('low')


paunch_locations['sales_group'] = sales_group

paunch_locations
```

| Store | City         | Sales_millions | CD  | Geometry | sales_group |
| ----- | ------------ | -------------- | --- | -------- | ----------- |
| 1     | Pawnee       | $5             | 1   | (x1,y1)  | moderate    |
| 2     | Pawnee       | $2.5           | 2   | (x2, y2) | low         |
| 3     | Pawnee       | $2.5           | 3   | (x3, y3) | low         |
| 4     | Eagleton     | $2             |     | (x4, y4) | low         |
| 5     | Pawnee       | $4             | 1   | (x5, y5) | moderate    |
| 6     | Pawnee       | $6             | 2   | (x6, y6) | high        |
| 7     | Indianapolis | $7             |     | (x7, y7) | high        |

(aggregating)=

## Aggregating

One of the most common form of summary statistics is aggregating by groups. In Excel, it's called a pivot table. In ArcGIS, it's doing a dissolve and calculating summary statistics. There are two ways to do it in Python: `groupby` and `agg` or `pivot_table`.

To answer the question of how many Paunch Burger locations there are per Council District and the sales generated per resident,

```python
# Method #1: groupby and agg
pivot = (merge2.groupby(['CD'])
        .agg({'Sales_millions': 'sum',
              'Store': 'count',
              'Population': 'mean'}
             ).reset_index()
        )

# Method #2: pivot table
pivot = merge2.pivot_table(
        index= ['CD'],
        values = ['Sales_millions', 'Store', 'Population'],
        aggfunc= {
            'Sales_millions': 'sum',
            'Store': 'count',
            'Population': 'mean'}
       ).reset_index()

    # to only find one type of summary statistic, use aggfunc = 'sum'

# reset_index() will compress the headers of the table, forcing them to appear
# in 1 row rather than 2 separate rows
```

`pivot` looks like this:

| CD  | Sales_millions | Store | Council_Member  | Population |
| --- | -------------- | ----- | --------------- | ---------- |
| 1   | $9             | 2     | Leslie Knope    | 1,500      |
| 2   | $8.5           | 2     | Jeremy Jamm     | 2,000      |
| 3   | $2.5           | 1     | Douglass Howser | 2,250      |

(export-aggregated-output)=

## Export Aggregated Output

Python can do most of the heavy lifting for data cleaning, transformations, and general wrangling. But, for charts or tables, it might be preferable to finish in Excel so that visualizations conform to the corporate style guide.

Dataframes can be exported into Excel and written into multiple sheets.

```python
import xlsxwriter

# initiate a writer
writer = pd.ExcelWriter('../outputs/filename.xlsx', engine='xlsxwriter')

council_population.to_excel(writer, sheet_name = 'council_pop')
paunch_locations.to_excel(writer, sheet_name = 'paunch_locations')
merge2.to_excel(writer, sheet_name = 'merged_data')
pivot.to_excel(writer, sheet_name = 'pivot')

# Close the Pandas Excel writer and output the Excel file.
writer.save()
```

Geodataframes can be exported as a shapefile or GeoJSON to visualize in ArcGIS/QGIS.

```python
gdf.to_file(driver = 'ESRI Shapefile', filename = '../folder/my_shapefile.shp' )

gdf.to_file(driver = 'GeoJSON', filename = '../folder/my_geojson.geojson')
```

<br>
