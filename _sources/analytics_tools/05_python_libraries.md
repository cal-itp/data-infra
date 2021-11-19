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
# Python Libraries (WIP)
The following libraries are available and recommended for use by Cal-ITP data analysts.
(calitp)=
## cal-itp
(siuba)=
## siuba
Siuba is a tool that allows the same analysis code to run on a pandas DataFrame,
as well as generate SQL for different databases.
It supports most [pandas Series methods](https://pandas.pydata.org/pandas-docs/stable/reference/series.html) analysts use.
See the [siuba docs](https://siuba.readthedocs.io) for more information.

The examples below go through the basics of using siuba, collecting a database query to a local DataFrame,
and showing SQL test queries that siuba code generates.

### Basic query
```{code-cell}
from myst_nb import glue
from calitp.tables import tbl
from siuba import _, filter, count, collect, show_query

# query lastest validation notices, then filter for a single gtfs feed,
# and then count how often each code occurs
(tbl.views.validation_notices()
    >> filter(_.calitp_itp_id == 10, _.calitp_url_number==0)
    >> count(_.code)
)
```



### Collect query results
Note that siuba by default prints out a preview of the SQL query results.
In order to fetch the results of the query as a pandas DataFrame, run `collect()`.

```{code-cell}
tbl_agency_names = tbl.views.gtfs_agency_names() >> collect()

# Use pandas .head() method to show first 5 rows of data
tbl_agency_names.head()

```



### Show query SQL

While `collect()` fetches query results, `show_query()` prints out the SQL code that siuba generates.

```{code-cell}
(tbl.views.gtfs_agency_names()
  >> filter(_.agency_name.str.contains("Metro"))
  >> show_query(simplify=True)
)

```
Note that here the pandas Series method `str.contains` corresponds to `regexp_contains` in Google BigQuery.
## plotnine
## mapping

## shared utils
A set of shared utility functions can also be installed, similarly to any Python library. The [shared_utils](https://github.com/cal-itp/data-analyses/shared_utils) are stored here. Generalized functions for analysis are added as collaborative work evolves so we aren't constantly reinventing the wheel.

```python
# In terminal:
python setup.py install

# In notebook:
import shared_utils

shared_utils.geography_utils.WGS84
```
