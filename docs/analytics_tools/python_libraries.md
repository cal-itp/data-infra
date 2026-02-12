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

(python-libraries)=

# Useful Python Libraries

The following libraries are available and recommended for use by Cal-ITP data analysts. Our JupyterHub environment comes with all of these installed already, except for `calitp-data-infra`. A full list of the packages included in the system image that underpins our JupyterHub environment can be found (and updated when needed) [here](https://github.com/cal-itp/data-infra/blob/main/images/jupyter-singleuser/pyproject.toml).

## Table of Contents

1. [shared utils](#shared-utils)
2. [calitp-data-analysis](#calitp-data-analysis)
   <br> - [Query SQL](#query-sql)
   <br> - [Accessing Google Cloud Storage Data](#accessing-google-cloud-storage-data)
3. [Querying Data in BigQuery](#querying-data-in-bigquery)
   <br> - [SQLAlchemy](#sqlalchemy)
   <br> - [pandas](#pandas-resources)
   <br> - [siuba](#siuba)
   <br> - [Basic Queries](#basic-queries)
   <br> - [Advanced Queries](#advanced-queries)
4. [Add New Packages](#add-new-packages)
5. [Updating calitp-data-analysis](#updating-calitp-data-analysis)
6. [Appendix: calitp-data-infra](#appendix)

(shared-utils)=

## shared utils

A set of shared utility functions can also be installed, similarly to any Python library. The `shared_utils` are stored in two places: [here](https://github.com/cal-itp/data-analyses/shared_utils) in `data-analyses`, which houses functions that are more likely to be updated. Shared functions that are updated less frequently are housed [here](https://github.com/cal-itp/data-infra/tree/main/packages/calitp-data-analysis/calitp_data_analysis) in the `calitp_data_analysis` package in `data-infra`. Generalized functions for analysis are added as collaborative work evolves so we aren't constantly reinventing the wheel.

### In terminal

- Navigate to the package folder: `cd data-analyses/_shared_utils`
- Use the make command to run through conda install and pip install: `make setup_env`
  - Note: you may need to select Kernel -> Restart Kernel from the top menu after make setup_env in order to successfully import shared_utils
- Alternative: add an `alias` to your `.bash_profile`:
  - In terminal use `cd` to navigate to the home directory (not a repository)
  - Type `nano .bash_profile` to open the .bash_profile in a text editor
  - Add a line at end: `alias go='cd ~/data-analyses/portfolio && pip install -r requirements.txt && cd ../_shared_utils && make setup_env && cd ..'`
  - Exit with Ctrl+X, hit yes, then hit enter at the filename prompt
  - Restart your server; you can check your changes with `cat .bash_profile`

### In notebook

```python
from calitp_data_analysis import geography_utils

geography_utils.WGS84
```

See [data-analyses/starter_kit](https://github.com/cal-itp/data-analyses/tree/main/starter_kit) for examples on how to use `shared_utils` for general functions, charts, and maps.

(calitp-data-analysis)=

## calitp-data-analysis

`calitp-data-analysis` is an internal library of utility functions used to access our warehouse data for analysis purposes.

### import tbls

__DEPRECATED:__ `tbls` will be removed after `calitp_data_analysis` version 2025.8.10. Instead of `AutoTable` or the `tbls`
instance, use `query_sql()` from `calitp_data_analysis.sql` to connect to and query a SQL database. See the [`query_sql()`
section](#query-sql) below.

Most notably, you can include `import tbls` at the top of your notebook to import a table from the warehouse in the form of a `tbls`:

```python
from calitp_data_analysis.tables import tbls
```

Example:

```python
from calitp_data_analysis.tables import tbls

tbls.mart_gtfs.dim_agency()
```

(query-sql)=

### Query SQL

#### query_sql

`query_sql()` is useful for simple queries against BigQuery datasets. You can optionally pass `as_df=True`
to turn a SQL query result into a pandas DataFrame. If you need to construct a more detailed query or are implementing
a query builder that has multiple usecases, you should probably use [SQLAlchemy query building](#advanced-queries) instead.

As an example, in a notebook:

```{code-cell}
from calitp_data_analysis.sql import query_sql

df_dim_agency = query_sql("""
SELECT
    *
FROM cal-itp-data-infra-staging.mart_gtfs.dim_agency
LIMIT 10""", as_df=True)

df_dim_agency.head()
```

(accessing-google-cloud-storage-data)=

### Accessing Google Cloud Storage Data

#### GCSPandas

The GCSPandas class fetches the Google Cloud Storage (GCS) filesystem and surfaces functions to provide analysts a
clear and consistent way of accessing data on GCS.

It's recommended to memoize initialization of the class so that the GCS filesystem is fetched and cached the first time
you call it and subsequent calls can reuse that cached filesystem.

```python
from functools import cache

from calitp_data_analysis.gcs_pandas import GCSPandas

@cache
def gcs_pandas():
    return GCSPandas()
```

##### _read_parquet_

Delegates to pandas.read_parquet, providing GCS Filesystem

```python
gcs_pandas().read_parquet("gs://path/to/your/file.parquet")
```

##### _read_csv_

Delegates to pandas.read_csv with the file at the path specified in the GCS filesystem

```python
gcs_pandas().read_csv("gs://path/to/your/file.csv")
```

##### _read_excel_

Delegates to pandas.read_excel with the file at the path specified in the GCS filesystem

```python
gcs_pandas().read_excel("gs://path/to/your/file.xlsx")
```

##### _data_frame_to_parquet_

Delegates to DataFrame.to_parquet, providing the GCS filesystem

```python
import pandas as pd

data_frame = pd.DataFrame({'col1': ['name1', 'name2']})
gcs_pandas().data_frame_to_parquet(data_frame, "gs://path/to/your/file.parquet")
```

#### GCSGeoPandas

The GCSGeoPandas class fetches the Google Cloud Storage (GCS) filesystem and surfaces functions to provide analysts a
clear and consistent way of accessing geospatial resources.

It's recommended to memoize initialization of the class so that the GCS filesystem is fetched and cached the first time
you call it and subsequent calls can reuse that cached filesystem.

```python
from functools import cache

from calitp_data_analysis.gcs_geopandas import GCSGeoPandas

@cache
def gcs_geopandas():
    return GCSGeoPandas()
```

##### _read_parquet_

Delegates to geopandas.read_parquet, providing GCS Filesystem

```python
gcs_geopandas().read_parquet("gs://path/to/your/file.parquet")
```

##### _read_file_

Delegates to geopandas.read_file with the file at the path specified in the GCS filesystem

```python
gcs_geopandas().read_file("gs://path/to/your/file.geojson")
```

##### _geo_data_frame_to_parquet_

Delegates to GeoDataFrame.to_parquet, providing the GCS filesystem

```python
import geopandas as gpd

data = {'col1': ['name1', 'name2'], 'geometry': [...]}
geo_data_frame = gpd.GeoDataFrame(data, crs="EPSG:4326")
gcs_geopandas().geo_data_frame_to_parquet(geo_data_frame, "gs://path/to/your/file.parquet")
```

(querying-data-in-bigquery)=

## Querying Data in BigQuery

(sqlalchemy)=

### SQLAlchemy

For more detailed queries or where a query builder pattern is needed for multiple use cases of the same base query, you can use SQLAlchemy's ORM
functionality. One of the biggest benefits of using an ORM like SQLAlchemy is its security features that mitigate risks common to writing raw SQL.
Accidentally introducing [SQL injection vulnerabilities](https://owasp.org/www-community/attacks/SQL_Injection) is one of the most common issues
that ORMs help prevent. Other benefits include more manageable and testable code and that ORM models provide an easy-to-reference resource
collocated with your code.

Steps to querying with the ORM

- [Declare a model](https://docs.sqlalchemy.org/en/14/orm/quickstart.html). For each of the tables you need to query, you will need to define a model if there isn't one already.

- [Construct a query](https://docs.sqlalchemy.org/en/14/orm/loading_objects.html). Full documentation on query construction here.

- Establish a DB connection and send the query.

  ```python
  from calitp_data_analysis.sql import get_engine
  from sqlalchemy.orm import sessionmaker

  db_engine = get_engine(project="cal-itp-data-infra-staging")
  DBSession = sessionmaker(db_engine)

  ...

  statement = select(YourModel).where(YourModel.service_date == "2025-12-01")

  with DBSession() as session:
      return pd.read_sql(statement, session.bind)
  ```

  See SQLAlchemy [Session Basics](https://docs.sqlalchemy.org/en/14/orm/session_basics.html) for more info.

(pandas-resources)=

### pandas

The library pandas is very commonly used in data analysis. See this [Pandas Cheat Sheet](https://pandas.pydata.org/Pandas_Cheat_Sheet.pdf) for more inspiration.

(siuba)=

### siuba (DEPRECATED)

__DEPRECATED:__ siuba will be removed from `calitp_data_analysis` after version 2025.8.10 and other shared code within the
next few months. Use SQLAlchemy and Pandas or GeoPandas functions directly instead. siuba uses these under the hood.

`siuba` is a tool that allows the same analysis code to run on a pandas DataFrame,
as well as generate SQL for different databases.
It supports most [pandas Series methods](https://pandas.pydata.org/pandas-docs/stable/reference/series.html) analysts use. See the [siuba docs](https://siuba.readthedocs.io) for more information.

The examples below go through the basics of using siuba, collecting a database query to a local DataFrame,
and showing SQL test queries that siuba code generates.

(basic-queries)=

### Basic Queries

#### query_sql

```python
from calitp_data_analysis.sql import query_sql

# query agency information, then filter for a single gtfs feed,
# and then count how often each feed key occurs
query_sql(
    """
    SELECT feed_key, COUNT(*) AS n
    FROM mart_gtfs.dim_agency
    WHERE agency_id = 'BA' AND base64_url = 'aHR0cHM6Ly9hcGkuNTExLm9yZy90cmFuc2l0L2RhdGFmZWVkcz9vcGVyYXRvcl9pZD1SRw=='
    GROUP BY feed_key
    ORDER BY n DESC
    LIMIT 5
    """
)
```

#### siuba equivalent (DEPRECATED)

__DEPRECATED:__ We are removing siuba from the codebase. This is only here for illustration. Please do not introduce new siuba code.

```python
from calitp_data_analysis.tables import tbls
from siuba import _, filter, count, collect, show_query

# query agency information, then filter for a single gtfs feed,
# and then count how often each feed key occurs
(tbls.mart_gtfs.dim_agency()
    >> filter(_.agency_id == 'BA', _.base64_url == 'aHR0cHM6Ly9hcGkuNTExLm9yZy90cmFuc2l0L2RhdGFmZWVkcz9vcGVyYXRvcl9pZD1SRw==')
    >> count(_.feed_key)
)
```

### _filter & collect_

#### query_sql

Use SQL with `SELECT` and `WHERE` clauses for filtering

```python
from calitp_data_analysis.sql import query_sql

agencies = query_sql(
    """
    SELECT * 
    FROM cal-itp-data-infra.mart_ntd.dim_annual_service_agencies
    WHERE state = 'CA' AND report_year = 2023
    """,
    as_df=True
)

# Use pandas `head()` method to show first 5 rows of data
agencies.head()
```

#### siuba equivalent (DEPRECATED)

Note that siuba by default prints out a preview of the SQL query results.
In order to fetch the results of the query as a pandas DataFrame, run `collect()`.

```python
from calitp_data_analysis.tables import tbls
from siuba import _, collect, filter

annnual_service_agencies = (
    tbls.mart_ntd.dim_annual_service_agencies()
    >> filter(_.state == "CA", _.report_year == 2023)
    >> collect()
)
```

### _select_

#### pandas/geopandas

```python
import geopandas as gpd

blocks = gpd.read_file('./tl_2020_06_tabblock20.zip')
blocks = blocks[['GEOID20', 'POP20', 'HOUSING20', 'geometry']]
```

#### siuba equivalent (DEPRECATED)

```python
import geopandas as gpd
from siuba import _, select


blocks = gpd.read_file('./tl_2020_06_tabblock20.zip')
blocks = blocks >> select(_.GEOID20, _.POP20, _.HOUSING20, _.geometry)
```

### _rename_

#### pandas/geopandas

```python
import geopandas as gpd

blocks = gpd.read_file('./tl_2020_06_tabblock20.zip')
blocks = blocks.rename(columns={'GEOID20': 'GEO_ID'})
```

#### siuba equivalent (DEPRECATED)

```python
import geopandas as gpd
from siuba import _, rename

blocks = gpd.read_file('./tl_2020_06_tabblock20.zip')
blocks = blocks >> rename(GEO_ID = _.GEOID20)
```

### _inner_join_

#### pandas/geopandas

The below code will result in table having both `GEO_ID` and `w_geocode` columns with redundant data.
To avoid this, you could either (a) first rename one of the columns to match the other and
do a simpler merge using just the `on` parameter (no need then for `left_on` and
`right_on`) or (b) do as show below and subsequently drop one of the redundant columns.

```python
# df and df2 are both DataFrame
joined = df2.merge(df, left_on='GEO_ID', right_on='w_geocode')
```

#### siuba equivalent (DEPRECATED)

```python
# df and df2 are both DataFrame
joined = df2 >> inner_join(_, df, on={'GEO_ID':'w_geocode'})
```

(advanced-queries)=

### Advanced Queries

If you need to construct a more detailed query or are implementing a query builder that has multiple use cases, you should
probably use SQLAlchemy ORM's query building features.

#### Reusable base query

Here's an example adapted from `shared_utils.schedule_rt_utils.filter_dim_gtfs_datasets`

```python
# Simplied from shared_utils.schedule_rt_utils.filter_dim_gtfs_datasets

def filter_dim_gtfs_datasets(
    keep_cols: list[str] = ["key", "name", "type", "regional_feed_type", "uri", "base64_url"],
    custom_filtering: dict = None,
    get_df: bool = True,
) -> Union[pd.DataFrame, sqlalchemy.sql.selectable.Select]:
    """
    Filter mart_transit_database.dim_gtfs_dataset table
    and keep only the valid rows that passed data quality checks.
    """
    dim_gtfs_dataset_columns = []

    for column in keep_cols:
        new_column = getattr(DimGtfsDataset, column)
        dim_gtfs_dataset_columns.append(new_column)

    search_conditions = [DimGtfsDataset.data_quality_pipeline == True]

    for k, v in (custom_filtering or {}).items():
        search_conditions.append(getattr(DimGtfsDataset, k).in_(v))

    statement = select(*dim_gtfs_dataset_columns).where(and_(*search_conditions))

    if get_df:
        with DBSession() as session:
            return pd.read_sql(statement, session.bind)
    else:
        return statement
```

Use of this function for query building

```python
# Simplied from shared_utils.gtfs_utils_v2.schedule_daily_feed_to_gtfs_dataset_name

dim_gtfs_datasets = schedule_rt_utils.filter_dim_gtfs_datasets(
    keep_cols=["key", "name", "type", "regional_feed_type"],
    custom_filtering={"type": ["schedule"]},
    get_df=False, # return a SQLAlchemy statement so that you can continue to build the query
)

statement = (
    dim_gtfs_datasets.with_only_columns(
        DimGtfsDataset.regional_feed_type,
        DimGtfsDataset.type,
        FctDailyScheduleFeed.date,
        FctDailyScheduleFeed.feed_key,
        FctDailyScheduleFeed.gtfs_dataset_key,
        FctDailyScheduleFeed.gtfs_dataset_name,
    )
    .join(
        FctDailyScheduleFeed,
        and_(
            FctDailyScheduleFeed.gtfs_dataset_key == DimGtfsDataset.key,
            FctDailyScheduleFeed.gtfs_dataset_name == DimGtfsDataset.name,
        ),
    )
    .where(FctDailyScheduleFeed.date == selected_date)
)

with DBSession() as session:
    return pd.read_sql(statement, session.bind)
```

#### Useful functions for query building

- [`Select.add_columns`](https://docs.sqlalchemy.org/en/14/core/selectable.html#sqlalchemy.sql.expression.Select.add_columns) - Add columns to existing Select clause
- [`Select.with_only_columns`](https://docs.sqlalchemy.org/en/14/core/selectable.html#sqlalchemy.sql.expression.Select.with_only_columns) - Replace columns in an existing Select clause
- [`Column.label`](https://docs.sqlalchemy.org/en/14/core/metadata.html#sqlalchemy.schema.Column.label) - Provide an alias for a column you're selecting. Results in SQL like `<columnname> AS <name>`.
- [`expression.func`](https://docs.sqlalchemy.org/en/14/core/sqlelement.html#sqlalchemy.sql.expression.func) - Generate SQL function expressions. This is useful for when you need to use a BigQuery-specific expression that is not generically supported in SQLAlchemy.
  For example:
  ```python
  from sqlalchemy import String, select, func

  ...

  select(
     # Produces column like {"caltrans_district": "07 - Los Angeles / Ventura"}  
    func.concat(
        func.lpad(cast(DimCountyGeography.caltrans_district, String), 2, "0"),
        " - ",
        DimCountyGeography.caltrans_district_name,
    ).label("caltrans_district"),
  ).where(...)
  ```

(add-new-packages)=

## Add New Packages

While most Python packages an analyst uses come in JupyterHub, there may be additional packages you'll want to use in your analysis.

- Install [shared utility functions](#shared-utils),
- Change directory into the project task's subfolder and add `requirements.txt` and/or `conda-requirements.txt`
- Run `pip install -r requirements.txt` and/or `conda install --yes -c conda-forge --file conda-requirements.txt`

(updating-calitp-data-analysis)=

## Updating calitp-data-analysis

`calitp-data-analysis` is a [package](https://pypi.org/project/calitp-data-analysis/) that lives [here](https://github.com/cal-itp/data-infra/tree/main/packages/calitp-data-analysis/calitp_data_analysis) in the `data-infra` repo. Follow the steps below update to the package.

<b>Steps </b>

Adapted from [this](https://cal-itp.slack.com/archives/C02KH3DGZL7/p1694470040574809) and [this Slack thread](https://cal-itp.slack.com/archives/C02KH3DGZL7/p1707252389227829).

1. Make the changes you want in the `calitp-data-analysis` folder inside `packages` [here](https://github.com/cal-itp/data-infra/tree/main/packages/calitp-data-analysis). If you are only changing package metadata (author information, package description, etc.) without changing the function of the package itself, that information lives in `pyproject.toml` rather than in the `calitp-data-analysis` subfolder.

   - If you are adding a new function that relies on a package that isn't already a dependency, run `poetry add <package name>` after changing directories to `data-infra/packages/calitp_data_analysis`. Check this [Jupyter image file](https://github.com/cal-itp/data-infra/blob/main/images/jupyter-singleuser/pyproject.toml) for the version number associated with the package, because you should specify the version.
   - For example, your function relies on `dask`. In the Jupyter image file, the version is `dask = "~2022.8"` so run `poetry add dask==~2022.8` in the terminal.
   - You may also have run `poetry install mypy`. `mypy` is a package that audits Python files for information related to data types, and you can [read more about it here](https://mypy-lang.org/).
   - `mypy` is a package that audits Python files for information related to data types, and you can [read more about it here](https://mypy-lang.org/). `mypy` is one of the standard development dependencies for the `calitp-data-analysis package`, defined in the `pyproject.toml` file for the package, so to install it you can run `poetry install` in `packages/calitp-data-analysis/` (which will also install the other package dependencies). To use `mypy`, run `poetry run mypy [file or directory name you're interested in checking]`.
   - `mypy` is generally run in CI when a PR is opened, as part of build tasks. You can see it called [here](https://github.com/cal-itp/data-infra/blob/main/.github/workflows/build-calitp-data-analysis.yml#L40) for this package in `build-calitp-data-analysis.yml`. Within the PR, the "Test, visualize, and build calitp-data-analysis" CI workflow will fail if problems are found.
   - More helpful hints for [passing mypy in our repo](https://github.com/cal-itp/data-infra/blob/main/README.md#mypy).

2. Each time you update the package, you must also update the version number. We use dates to reflect which version we are on. Update the version in [pyproject.toml](https://github.com/cal-itp/data-infra/blob/main/packages/calitp-data-analysis/pyproject.toml#L3) that lives in `calitp-data-analysis` to either today's date or a future date.

3. Open a new pull request and make sure the new version date appears on the [test version page](https://test.pypi.org/project/calitp-data-analysis/).

   - The new version date may not show up on the test page due to errors. Check the GitHub Action page of your pull request to see the errors that have occurred.
   - If you run into the error message like this, `error: Skipping analyzing "dask_geopandas": module is installed, but missing library stubs or py.typed marker  [import]` go to your `.py` file and add `# type: ignore` behind the package import.
   - To fix the error above, change `import dask_geopandas as dg` to `import dask_geopandas as dg  # type: ignore`.
   - It is encouraged to make changes in a set of smaller commits. For example, add all the necessary packages with `poetry run <package` first, fix any issues flagged by `mypy`, and finally address any additional issues.

4. Merge the PR. Once it is merged in, the [actual package](https://pypi.org/project/calitp-data-analysis/) will display the new version number. To make sure everything works as expected, run `pip install calitp-data-analysis==<new version here>` in a cell of Jupyter notebook and import a package (or two) such as `from calitp_data_analysis import styleguide`.

5. Update the new version number in the `data-infra` repository [here](https://github.com/cal-itp/data-infra/blob/main/images/dask/requirements.txt#L30), [here](https://github.com/cal-itp/data-infra/blob/main/images/jupyter-singleuser/pyproject.toml#L48), [here](https://github.com/cal-itp/data-infra/blob/main/docs/requirements.txt), and anywhere else you find a reference to the old version of the package. You'll also want to do the same for any other Cal-ITP repositories that reference the `calitp-data-analysis` package.

   - When yu update the [jupyter-singleuser toml](https://github.com/cal-itp/data-infra/blob/main/images/jupyter-singleuser/pyproject.toml#L48), make sure to run `poetry add calitp-data-analysis==<new version here>` and commit the updated `poetry.lock` file.
   - As of writing, the only other repository that references to the package version is [reports](https://github.com/cal-itp/reports).

<b>Resources</b>

- [Issue #870](https://github.com/cal-itp/data-analyses/issues/870)
- [Pull Request #2994](https://github.com/cal-itp/data-infra/pull/2944)
- [Slack thread](https://cal-itp.slack.com/archives/C02KH3DGZL7/p1694470040574809)

(appendix)=

## Appendix: calitp-data-infra

The [calitp-data-infra](https://pypi.org/project/calitp-data-infra/) package, used primarily by warehouse mainainers and data pipeline developers, includes utilities that analysts will likely not need need to interact with directly (and therefore generally won't need to install), but which may be helpful to be aware of. For instance, the `get_secret_by_name()` and `get_secrets_by_label()` functions in [the package's `auth` module](https://github.com/cal-itp/data-infra/blob/main/packages/calitp-data-infra/calitp_data_infra/auth.py) are used to interact with Google's [Secret Manager](https://console.cloud.google.com/security/secret-manager), the service that securely stores API keys and other sensitive information that underpins many of our data syncs.

You can read more about the `calitp-data-infra` Python package [here](https://github.com/cal-itp/data-infra/tree/main/packages/calitp-data-infra#readme).
