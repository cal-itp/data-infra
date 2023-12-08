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
3. [siuba](#siuba)
   <br> - [Basic Query](#basic-query)
   <br> - [Collect Query Results](#collect-query-results)
   <br> - [Show Query SQL](#show-query-sql)
   <br> - [More siuba Resources](more-siuba-resources)
4. [pandas](pandas-resources)
5. [Add New Packages](#add-new-packages)
6. [Appendix: calitp-data-infra](appendix)

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

Most notably, you can include `import tbls` at the top of your notebook to import a table from the warehouse in the form of a `tbls`:

```python
from calitp_data_analysis.tables import tbls
```

Example:

```{code-cell}
from calitp_data_analysis.tables import tbls

tbls.mart_gtfs.dim_agency()
```

### query_sql

`query_sql` is another useful function to use inside of JupyterHub notebooks to turn a SQL query into a pandas DataFrame.

As an example, in a notebook:

```{code-cell}
from calitp_data_analysis.sql import query_sql
```

```{code-cell}
df_dim_agency = query_sql("""
SELECT
    *
FROM `mart_gtfs.dim_agency`
LIMIT 10""", as_df=True)
```

```{code-cell}
df_dim_agency.head()
```

(siuba)=

## siuba

`siuba` is a tool that allows the same analysis code to run on a pandas DataFrame,
as well as generate SQL for different databases.
It supports most [pandas Series methods](https://pandas.pydata.org/pandas-docs/stable/reference/series.html) analysts use. See the [siuba docs](https://siuba.readthedocs.io) for more information.

The examples below go through the basics of using siuba, collecting a database query to a local DataFrame,
and showing SQL test queries that siuba code generates.

### Basic query

```{code-cell}
from calitp_data_analysis.tables import tbls
from siuba import _, filter, count, collect, show_query

# query agency information, then filter for a single gtfs feed,
# and then count how often each feed key occurs
(tbls.mart_gtfs.dim_agency()
    >> filter(_.agency_id == 'BA', _.base64_url == 'aHR0cHM6Ly9hcGkuNTExLm9yZy90cmFuc2l0L2RhdGFmZWVkcz9vcGVyYXRvcl9pZD1SRw==')
    >> count(_.feed_key)
)
```

### Collect query results

Note that siuba by default prints out a preview of the SQL query results.
In order to fetch the results of the query as a pandas DataFrame, run `collect()`.

```{code-cell}
tbl_agency_names = tbls.mart_gtfs.dim_agency() >> collect()

# Use pandas .head() method to show first 5 rows of data
tbl_agency_names.head()

```

### Show query SQL

While `collect()` fetches query results, `show_query()` prints out the SQL code that siuba generates.

```{code-cell}
(tbls.mart_gtfs.dim_agency()
  >> filter(_.agency_name.str.contains("Metro"))
  >> show_query(simplify=True)
)

```

Note that here the pandas Series method `str.contains` corresponds to `regexp_contains` in Google BigQuery.

(more-siuba-resources)=

### More siuba Resources

- [siuba docs](https://siuba.readthedocs.io)
- ['Tidy Tuesday' live analyses with siuba](https://www.youtube.com/playlist?list=PLiQdjX20rXMHc43KqsdIowHI3ouFnP_Sf)

(pandas-resources)=

## pandas

The library pandas is very commonly used in data analysis, and the external resources below provide a brief overview of it's use.

- [Cheat Sheet - pandas](https://pandas.pydata.org/Pandas_Cheat_Sheet.pdf)

## Add New Packages

While most Python packages an analyst uses come in JupyterHub, there may be additional packages you'll want to use in your analysis.

- Install [shared utility functions](#shared-utils)
- Change directory into the project task's subfolder and add `requirements.txt` and/or `conda-requirements.txt`
- Run `pip install -r requirements.txt` and/or `conda install --yes -c conda-forge --file conda-requirements.txt`

(appendix)=

## Appendix: calitp-data-infra

The [calitp-data-infra](https://pypi.org/project/calitp-data-infra/) package, used primarily by warehouse mainainers and data pipeline developers, includes utilities that analysts will likely not need need to interact with directly (and therefore generally won't need to install), but which may be helpful to be aware of. For instance, the `get_secret_by_name()` and `get_secrets_by_label()` functions in [the package's `auth` module](https://github.com/cal-itp/data-infra/blob/main/packages/calitp-data-infra/calitp_data_infra/auth.py) are used to interact with Google's [Secret Manager](https://console.cloud.google.com/security/secret-manager), the service that securely stores API keys and other sensitive information that underpins many of our data syncs.

You can read more about the `calitp-data-infra` Python package [here](https://github.com/cal-itp/data-infra/tree/main/packages/calitp-data-infra#readme).
