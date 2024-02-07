(data-management-page)=

# Data Management

Data Management is hard, and before you know it, you end up with `final_final_final_project_data-2019.csv.bak` as the source of your project's data.

Below is a series of tips, tricks and use-cases for managing data throughout the lifecycle of a projects.

- [Reading and Writing Data](#reading-and-writing-data)
  - [GCS](#gcs)
  - [Local Folders](#local-folders)
- [Formats and Use-Cases](#formats-and-use-cases)
  - [CSVs](#csvs)
  - [Excel / XLSX](#excel)
  - [Parquet](#parquet)
  - [Feather Files](#feather-files)
  - [GeoJSON](#geojson)
  - [Shapefiles](#shapefiles)
  - [PBF (Protocolbuffer Binary Format)](#pbf-protocolbuffer-binary-format)
  - [Databases](#databases)
  - [Pickles](#pickles)

(reading-and-writing-data)=

## Reading and Writing Data

(gcs)=

### GCS

Our team often uses Google Cloud Storage (GCS) for object storage. If you haven't set up your Google authentication, go [here](https://docs.calitp.org/data-infra/analytics_tools/notebooks.html#connecting-to-warehouse) for the instructions. For a walkthrough on how to use GCS buckets, go [here](https://docs.calitp.org/data-infra/analytics_tools/storing_data.html#in-gcs).

By putting data on GCS, anybody on the team can use/access/replicate the data without having to transfer data files between machines.

To write and read a pandas dataframe as a CSV to GCS:

```python
import pandas as pd

df.to_csv('gs://calitp-analytics-data/data-analyses/bucket-name/my_csv.csv')

pd.read_csv('gs://calitp-analytics-data/data-analyses/bucket-name/my_csv.csv')

```

(local-folders)=

### Local Folders

Sometimes, it is easiest to simply use your local file system to store data.

```python
import pandas as pd

df.to_csv('./my_csv.csv')

pd.read_csv('./my_csv.csv')

```

(formats-and-use-cases)=

## Formats and Use-cases

Data Interchange: Where everything can be broken.

(csvs)=

### CSVs

CSVs are the lowest common denominator of data files. They are plain text files that contain a list of data. They are best for getting raw data from SQL and storing large blobs on cloud services. For interchange, it is better to use Parquet or even Excel as they preserve datatypes.

Benefits to CSVs include their readability and ease of use for users. Unlike Parquet files, they are stored as plain text, making them human readable.

The downsides to CSVs are that their sizes can easily get out of hand, making Parquet files a preferable alternative in that regard. CSVs also don't store data types for columns. If there are different data types within a single column, this can lead to numerous issues. For example, if there are  strings and integers mixed within a single column, the process of analyzing that CSV becomes extremely difficult and even impossible at times. Finally, another key issue with CSVs is the ability to only store a single sheet in a file without any formatting or formulas. Excel files do a better job of allowing for formulas and different formats.

(excel)=

### Excel

Excel/XLSX is a binary file format that holds information about all the worksheets in a file, including both content and formatting. This means Excel files are capable of holding formatting, images, charts, formulas, etc. CSVs are more limited in this respect. A downside to Excel files is that they aren't commonly readable by data analysis platforms. Every data analysis platform is capable of processing CSVs, but Excel files are a proprietary format that often require extensions in order to be processed. The ease of processing CSVs makes it easier to move data between different platforms, compared with Excel files. Excel files are best for sharing with other teams, except for geographic info (use Shapefiles or GeoJSON instead), if the Excel format is the only available and accessible format.

You often might want to write multiple dataframes to a single excel files as sheets. Here's a guide:

```python
## init a writer
writer = pd.ExcelWriter('../outputs/filename.xlsx', engine='xlsxwriter')

## assume district_dfs is a dictionary of dataframes by council district
Write each dataframe to a different worksheet.
for key, value in district_dfs.items():
    value.to_excel(writer, sheet_name=key)

# Close the Pandas Excel writer and output the Excel file.
writer.save()
```

(parquet)=

### Parquet

Parquet is an "open source columnar storage format for use in data analysis systems." Columnar storage is more efficient as it is  easily compressed and the data is more homogenous. CSV files utilize a row-based storage format which is harder to compress, a reason why Parquets files are preferable for larger datasets. Parquet files are faster to read than CSVs, as they have a higher querying speed and preserve datatypes (i.e. Number,  Timestamps, Points). They are best for intermediate data storage and large datasets (1GB+) on most any on-disk storage. This file format is also good for passing dataframes between Python and R. A similar option is [feather](https://blog.rstudio.com/2016/03/29/feather/).

One of the downsides to Parquet files is the inability to quickly look at the dataset in GUI based (Excel, QGIS, etc.) programs. Parquet files also lack built-in support for categorical data.

Here is a way to use pandas to convert a local CSV file to a Parquet file:

```python
import pandas as pd

df = pd.read_csv('my_csv_name.csv')
df2 = df.to_parquet('my_parquet_name.parquet')
```

(feather-files)=

### Feather Files

Feather provides a lightweight binary columnar serialization format for data frames. It is designed to make reading and writing data frames more efficient, as well as to make sharing data across languages easier. Just like Parquet, Feather is also capable of passing dataframes between Python and R, as well as storing column data types.

The Feather format is not compressed, allowing for faster input/output so it works well with solid-state drives. Similarly, Feather doesn't need unpacking in order to load it back into RAM.

Feather is not be the ideal file format if you're looking for long-term data storage. It is really only equipped for short-term data storage. The Feather files themselves are also smaller than CSVs and have a higher input/output speed, but they don't necessarily have the same level of compression as Parquet files.

Once you install the feather package with `$ pip install feather-format` then you can easily write a dataframe.

```python
import feather
path = 'my_data.feather'
feather.write_dataframe(df, path)
df = feather.read_dataframe(path)
```

(geojson)=

### GeoJSON

GeoJSON is an [open-standard format](https://geojson.org/) for encoding a variety of geographic data structures using JavaScript Object Notation (JSON).  A GeoJSON object may represent a region of space (a Geometry), a spatially bounded entity (a Feature), or a list of Features (a FeatureCollection). It supports geometry types: Point, LineString, Polygon, MultiPoint, MultiLineString, MultiPolygon, and GeometryCollection. JSON is light and easier to read than most geospatial formats, but GeoJSON files can quickly get too large to handle. The upside is that a GeoJSON file is often easier to work with than a Shapefile.

```python
import geopandas as gpd

gdf = gpd.read_file('https://data.cityofnewyork.us/api/geospatial/tqmj-j8zm?method=export&format=GeoJSON')
```

(shapefiles)=

### Shapefiles

Shapefiles are a geospatial vector data format for geographic information system software and the original file format for geospatial data. They are capable of spatially describing vector features: points, lines, and polygons. Geopandas has good support for reading / writing shapefiles.

One weird thing, however, is that a shapefile isn't a _file_, it's a _folder_, containing multiple subfiles (such as .dbf, .shpx, etc). To properly read/write shapefiles, make sure to read the entire folder or write to a folder each time. This can cause issues especially as most shapefiles are compressed into a zip file with isn't always easily decompressed.

It is often better to use `geojson` vs `shapefiles` since the former is easier to render on the web. The latter is better when you have a bespoke projection. A few downsides to shapefiles include their inability to store topological information and the file size restriction of 2GB. Similarly, shapefiles can only contain one geometry type per file.

Here is a template for one way to read and write shapefiles using pandas:

```python
import geopandas as gpd
import os

# read shapefile
gpd.read_file('./my_folder/')

# write shapefile
if not os.path.exists('./outputs/my_dir_name'):
    os.mkdirs('./outputs/my_dir_name')
gdf.to_file('./outputs/my_dir_name')
```

(pbf-protocolbuffer-binary-format)=

### PBF (Protocolbuffer Binary Format)

Protocol Buffers is a method of serializing structured data. It is used for storing and interchanging structured information of all types. PBF involves an interface description language that describes the structure of some data and a program that generates source code from that description for generating or parsing a stream of bytes that represents the structured data. As compared to XML, it is designed to be simpler and quicker. A benefit of using PBF is that you can define how you want your data to be structured once and then use special generated source code to easily write and read your structured data to and from a variety of data streams. It is also possible to update the defined data structure without breaking deployed programs that are compiled against the older structure/format. Although PBF was designed as a better medium for communication between systems than XML, it only has some marginal advantages when compared to JSON.

(databases)=

### Databases

A whole field of study, it is often useful to use a DB for analytics and aggregated queries, rather than just your production datastore.

(pickles)=

### Pickles

A way of serializing arbitrary python objects into a byte stream with the intent of storing it in a file/database. Danger lives here.
