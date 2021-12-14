---
jupytext:
  cell_metadata_filter: -all
  formats: md:myst
  text_representation:
    extension: .md
    format_name: myst
    format_version: 0.13
    jupytext_version: 1.10.3
kernelspec:
  display_name: Python 3 (ipykernel)
  language: python
  name: python3
---
(storing-new-data)=
# Storing New Data

Our team uses Google Cloud Storage (GCS) buckets, specifically the `calitp-analytics-data` bucket, to store other datasets for analyses. GCS can store anything, of arbitrary object size and shape. It’s like a giant folder in the cloud. You can use it to store CSVs, parquets, pickles, videos, etc. Within the bucket, the `data-analyses` folder with its sub-folders corresponds to the `data-analyses`  GitHub repo with its sub-folders. Versioned data for a task should live within the correct folders.

To access GCS, make sure you have your authentication set up in JupyterHub.

```python
import geopandas as gpd
import gcsfs
import pandas as pd

from calitp.storage import get_fs
fs = get_fs()
```

## Table of Contents
1. [Introduction](#introduction)
1. [Storing New Data - Screencast](storing-new-data-screencast)
1. [Uploading Data from a Notebook](uploading-from-notebook)
<br> - [Tabular Data](#tabular-data)
  <br> - [Parquet](#parquet)
  <br>- [CSV](#csv)
<br> -[Geospatial Data](#geospatial-data)
  <br> - [Geoparquet](#geoparquet)
  <br> - [Zipped shapefile](#zipped-shapefile)
  <br> - [GeoJSON](#geojson)
1. [Uploading data in Google Cloud Storage](in-gcs)


## Introduction

Currently, report data can be stored in the `calitp-analytics-data` bucket.

In order to save data being used in a report, you can use two methods:

* Using code in your notebook to upload the data.
* Using the Google Cloud Storage web UI to manually upload.

Watch the screencast below and read the additional information to begin.

Note: You will need to have set up your Google authentication in order to push a dataset with code from a Jupyter Notebook or script. If you have yet to do so, [follow these instructions](connecting-to-warehouse).

(storing-new-data-screencast)=
## Storing New Data - Screencast

<div style="position: relative; padding-bottom: 62.5%; height: 0;"><iframe src="https://www.loom.com/embed/51d22876ab6d4d35a39f18e8f6d5f11d" frameborder="0" webkitallowfullscreen mozallowfullscreen allowfullscreen style="position: absolute; top: 0; left: 0; width: 100%; height: 100%;"></iframe></div>

(uploading-from-notebook)=
## Uploading Data from a Notebook

### Tabular Data

While GCS can store CSVs, parquets, Excel spreadsheets, etc, parquets are the preferred file type. Interacting with tabular datasets in GCS is fairly straightforward and is handled well by `pandas`.

#### Parquet

Parquet is an “open source columnar storage format for use in data analysis systems.” Columnar storage is more efficient as it is easily compressed and the data is more homogenous. CSV files utilize a row-based storage format which is harder to compress, a reason why Parquets files are preferable for larger datasets. Parquet files are faster to read than CSVs, as they have a higher querying speed and preserve datatypes (ie, Number, Timestamps, Points). They are best for intermediate data storage and large datasets (1GB+) on most any on-disk storage. This file format is also good for passing dataframes between Python and R. A similar option is feather.

One of the downsides to Parquet files is the inability to quickly look at the dataset in GUI based (Excel, QGIS, etc.) programs. Parquet files also lack built-in support for categorical data.

```python
df = pd.read_parquet('gs://calitp-analytics-data/data-analyses/task-subfolder/test.parquet')

df.to_parquet('gs://calitp-analytics-data/data-analyses/task-subfolder/test.parquet')
```

#### CSV

```python
df = pd.read_csv('gs://calitp-analytics-data/data-analyses/task-subfolder/test.csv')

df.to_csv('gs://calitp-analytics-data/data-analyses/task-subfolder/test.parquet')
```

### Geospatial Data

Geospatial data may require a little extra work, due to how `geopandas` and GCS interacts.

#### Geoparquet

Importing geoparquets directly from GCS works with `geopandas`, but exporting geoparquets into GCS requires an extra step of uploading.

```python

gdf = gpd.read_parquet("gs://calitp-analytics-data/data-analyses/task-subfolder/my-geoparquet.parquet")

# Save the geodataframe to your local filesystem
gdf.to_parquet("./my-geoparqet.parquet")

# Put the local file into the GCS bucket
fs.put("./my-geoparquet.parquet", "gs://calitp-analytics-data/data-analyses/task-subfolder/my-geoparquet.parquet")
```

Or, use the `shared_utils` package.

```python
import shared_utils

shared_utils.utils.geoparquet_gcs_export(gdf, "my-geoparquet")
```

#### Zipped Shapefile

Refer to the [data catalogs doc](./08_data_catalogs.md#google-cloud-storage) to list a zipped shapefile, and read in the zipped shapefile with the `intake` method. Zipped shapefiles saved in GCS cannot be read in directly using `geopandas`.

#### GeoJSON

Refer to the [data catalogs doc](./08_data_catalogs.md#google-cloud-storage) to list a GeoJSON, and read in the GeoJSON with the `intake` method. GeoJSONs saved in GCS cannot be read in directly using `geopandas`.

(in-gcs)=
## Uploading data in Google Cloud Storage

You can access the cloud bucket from the web from https://console.cloud.google.com/storage/browser/calitp-analytics-data.

See the above screencast for a walkthrough of using the bucket.
