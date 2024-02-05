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

(data-catalogs)=

# Using Data Catalogs

One major difficulty with conducting reproducible analyses is the location of data. If a data analyst downloads a CSV on their local system, but does not document its provenance or access, the analysis becomes very difficult to reproduce.

One strategy to deal with this is to create data catalogs for projects, which describe the data sources used and how to access them. Our team uses open data sources, database, and any other dataset that needs to be versioned must be stored in Google Cloud Storage (GCS) buckets. A data catalog that documents these heterogeneous sources simplifies and streamlines the "read" side of reading and writing data.

Each task sub-folder within the `data-analyses` repo should come with its own data catalog, documenting the data sources used within the notebooks and scripts.

## Table of Contents

1. Data Catalogs with [Intake](#intake)
2. [Open Data Portals](#open-data-portals)
3. [Google Cloud Storage](#google-cloud-storage) (GCS) Buckets
4. [Sample Data Catalog](#sample-data-catalog)

(intake)=

### Intake

Data analysts tend to load their data from many heterogeneous sources (Databases, CSVs, JSON, etc), but at the end of the day, they often end up with the data in dataframes or numpy arrays. One tool for managing that in Python is the relatively new project `intake`. Intake provides a way to make data catalogs can then be used load sources into dataframes and arrays. These catalogs are plain text and can then be versioned and published, allowing for more ergonomic documentation of the data sources used for a project.

`intake-dcat` is a tool for allowing intake to more easily interact with DCAT catalogs commonly found on open data portals.

Refer to this [sample-catalog.yml](sample-catalog) to see how various data sources and file types are documented. Each dataset is given a human-readable name, with optional metadata associated.

File types that work within GCS buckets, URLs, or DCATs (open data catalogs):

- Tabular: CSV, parquet
- Geospatial: zipped shapefile, GeoJSON, geoparquet

To open the catalog in a Jupyter Notebook:

```python
import intake

catalog = intake.open_catalog("./sample-catalog.yml")

# To open multiple catalog YML files
catalog = intake.open_catalog("./*.yml")
```

(open-data-portals)=

### Open Data Portals

Open data portals (such as the CA Open Data Portal and CA Geoportal) usually provide a DCAT catalog for their datasets, including links for downloading them and metadata describing them. Many civic data analysis projects end up using these open datasets. When they do, it should be clearly documented.

- To input a dataset from an open data portal, find the dataset's identifier for the `catalog.yml`.
- Ex: The URL for CA Open Data Portal is: [https://data.ca.gov](https://data.ca.gov).
- Navigate to the corresponding `data.json` file at [https://data.ca.gov/data.json](https://data.ca.gov/data.json).
- Each dataset has associated metadata, including `accessURL`, `landingPage`, etc. Find the dataset's `identifier`, and input that as the catalog item.

```yaml
# Catalog item
ca_open_data:
driver: dcat
args:
  url: https://data.ca.gov/data.json
  items:
      cdcr_population_covid_tracking: 4a9a896a-e64e-48c2-bb35-5589f80e7c52
```

To import this dataset as a dataframe within the notebook:

```python
df = catalog.ca_open_data.cdcr_population_covid_tracking.read()
```

(google-cloud-storage)=

### Google Cloud Storage

When putting GCS files into the catalog, note that geospatial datasets (zipped shapefiles, GeoJSONs) require the additional `use_fsspec: true` argument compared to tabular datasets (parquets, CSVs). Geoparquets, the exception, are catalogued like tabular datasets.

Opening geospatial datasets through `intake` is the easiest way to import these datasets within a Jupyter Notebook. Otherwise, `geopandas` can read the geospatial datasets that are locally saved or downloaded first from the bucket, but not directly with a GCS file path. Refer to \[storing data\](Connecting to the Warehouse) to set up your Google authentication.

```yaml
lehd_federal_jobs_by_tract:
    driver: parquet
    description: LEHD Workplace Area Characteristics (WAC) federal jobs by census tract.
    args:
      urlpath: gs://calitp-analytics-data/data-analyses/bus_service_increase/wac_fed_tract.parquet
      engine: pyarrow
test_csv:
    driver: csv
    description: Description
    args:
      urlpath: https://raw.githubusercontent.com/CityOfLosAngeles/covid19-indicators/master/data/ca_county_pop_crosswalk.csv
test_zipped_shapefile:
    driver: shapefile
    description: LA Metro rail lines
    args:
      urlpath: gs://calitp-analytics-data/test_zipped_shapefile.zip
      use_fsspec: true
test_geoparquet:
    driver: geoparquet
    description: Description
    args:
      urlpath: gs://calitp-analytics-data/test_geoparquet.parquet
```

To import each of these files as dataframes or geodataframes:

```python
df1 = catalog.lehd_federal_jobs_by_tract.read()

df2 = catalog.test_csv.read()

gdf1 = catalog.test_zipped_shapefile.read()

gdf2 = catalog.test_geoparquet.read()
```

(sample-data-catalog)=

# Sample Data Catalog

```{literalinclude} sample-catalog.yml
```
