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
The following libraries are available and recommended for use by Cal-ITP data analysts.

## Table of Contents
1. [shared utils](#shared-utils)
1. [calitp](#calitp)
1. [siuba](#siuba)
<br> - [Basic Query](#basic-query)
<br> - [Collect Query Results](#collect-query-results)
<br> - [Show Query SQL](#show-query-sql)
<br> - [More siuba Resources](more-siuba-resources)
1. [pandas](pandas-resources)
1. [Add New Packages](#add-new-packages)

(shared-utils)=
## shared utils
A set of shared utility functions can also be installed, similarly to any Python library. The [shared_utils](https://github.com/cal-itp/data-analyses/shared_utils) are stored here. Generalized functions for analysis are added as collaborative work evolves so we aren't constantly reinventing the wheel.


### In terminal:
* Navigate to the package folder: `cd data-analyses/_shared_utils`
* Use the make command to run through conda install and pip install: `make setup_env`
    * Note: you may need to select Kernel -> Restart Kernel from the top menu after make setup_env in order to successfully import shared_utils
* Alternative: add an `alias` to your `.bash_profile`:
    * In terminal use `cd` to navigate to the home directory (not a repository)
    * Type `nano .bash_profile` to open the .bash_profile in a text editor
    * Add a line at end: `alias go='cd ~/data-analyses/portfolio && pip install -r requirements.txt && cd ../_shared_utils && make setup_env && cd ..'`
    * Exit with Ctrl+X, hit yes, then hit enter at the filename prompt
    * Restart your server; you can check your changes with `cat .bash_profile`


### In notebook:
```python
import shared_utils

#example of using shared_utils
shared_utils.geography_utils.WGS84
```

See [data-analyses/example_reports](https://github.com/cal-itp/data-analyses/tree/main/example_report) for examples on how to use `shared_utils` for general functions, charts, and maps.

(calitp)=
## calitp
`calitp` is an internal library of utility functions used to access our warehouse data.

### import tbl

Most notably, you can include `import tbl` at the top of your notebook to import a table from the warehouse in the form of a `tbl`:

```python
from calitp.tables import tbl
```

Example:
```{code-cell}
from calitp.tables import tbl

tbl.views.gtfs_schedule_fact_daily_feed_routes()
```

### query_sql

`query_sql` is another useful function to use inside of JupyterHub notebooks to turn a SQL query into a pandas DataFrame.

As an example, in a notebook:
```{code-cell}
from calitp import query_sql
```

```{code-cell}
df_dim_feeds = query_sql("""
SELECT
    *
FROM `views.gtfs_schedule_dim_feeds`
LIMIT 10""", as_df=True)
```

```{code-cell}
df_dim_feeds.head()
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
from myst_nb import glue
from calitp.tables import tbl
from siuba import _, filter, count, collect, show_query

# query lastest validation notices, then filter for a single gtfs feed,
# and then count how often each code occurs
(tbl.views.gtfs_schedule_dim_feeds()
    >> filter(_.calitp_itp_id == 10, _.calitp_url_number==0)
    >> count(_.feed_key)
)
```



### Collect query results
Note that siuba by default prints out a preview of the SQL query results.
In order to fetch the results of the query as a pandas DataFrame, run `collect()`.

```{code-cell}
tbl_agency_names = tbl.views.gtfs_schedule_dim_feeds() >> collect()

# Use pandas .head() method to show first 5 rows of data
tbl_agency_names.head()

```



### Show query SQL

While `collect()` fetches query results, `show_query()` prints out the SQL code that siuba generates.

```{code-cell}
(tbl.views.gtfs_schedule_dim_feeds()
  >> filter(_.calitp_agency_name.str.contains("Metro"))
  >> show_query(simplify=True)
)

```
Note that here the pandas Series method `str.contains` corresponds to `regexp_contains` in Google BigQuery.

(more-siuba-resources)=
### More siuba Resources:
* [siuba docs](https://siuba.readthedocs.io)
* ['Tidy Tuesday' live analyses with siuba](https://www.youtube.com/playlist?list=PLiQdjX20rXMHc43KqsdIowHI3ouFnP_Sf)


(pandas-resources)=
## pandas
The library pandas is very commonly used in data analysis, and the external resources below provide a brief overview of it's use.

* [Cheat Sheet - pandas](https://pandas.pydata.org/Pandas_Cheat_Sheet.pdf)

## Add New Packages

While most Python packages an analyst uses come in JupyterHub, there may be additional packages you'll want to use in your analysis.

* Install [shared utility functions](#shared-utils)
* Change directory into the project task's subfolder and add `requirements.txt` and/or `conda-requirements.txt`
* Run `pip install -r requirements.txt` and/or `conda install --yes -c conda-forge --file conda-requirements.txt`
