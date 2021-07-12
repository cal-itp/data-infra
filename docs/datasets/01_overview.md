# Overview

| page | description | datasets |
| ---- | ----------- | -------- |
| [GTFS Schedule](../gtfs_schedule/) | GTFS Schedule data for the current day | `gtfs_schedule`, `gtfs_schedule_history`, `gtfs_schedule_type2` |
| [MST Payments](../mst_payments/) | TODO | TODO |
| [Transitstacks](../transitstacks/) | TODO | `transitstacks`, `views.transitstacks` |
| [Views](../views/) | End-user friendly data for dashboards and metrics | E.g. `views.validation_*`, `views.gtfs_schedule_*` |

## Querying data

### Using metabase dashboards

<div style="position: relative; padding-bottom: 62.5%; height: 0;"><iframe src="https://www.loom.com/embed/1dc0c085b12b4848a52523ef34397f71" frameborder="0" webkitallowfullscreen mozallowfullscreen allowfullscreen style="position: absolute; top: 0; left: 0; width: 100%; height: 100%;"></iframe></div>

### Using siuba

Siuba is a tool that allows the same analysis code to run on a pandas DataFrame,
as well as generate SQL for different databases.
It supports most [pandas Series methods](https://pandas.pydata.org/pandas-docs/stable/reference/series.html) analysts use.
See the [siuba docs](siuba.readthedocs.io) for more information.

The examples below go through the basics of using siuba, collecting a database query to a local DataFrame,
and showing SQL queries that siuba code generates.

#### Basic query

```python
from calitp.tables import tbl
from siuba import _, filter, count, collect, show_query

# query lastest validation notices, then filter for a single gtfs feed,
# and then count how often each code occurs
(tbl.views.validation_notices()
    >> filter(_.calitp_itp_id == 10, _.calitp_url_number==0)
    >> count(_.code)
)
```

<!-- CODE OUTPUT -->
```pycon
# Source: lazy query
# DB Conn: Engine(bigquery://cal-itp-data-infra/?maximum_bytes_billed=5000000000)
# Preview:
   calitp_itp_id  calitp_url_number                 agency_name
0            256                  0         Porterville Transit
1            257                  0                   PresidiGo
2            259                  0  Redding Area Bus Authority
3              4                  0                  AC Transit
4            260                  0        Beach Cities Transit
# .. may have more rows
```
<!-- END CODE OUTPUT -->

#### Collect query results

Note that siuba by default prints out a preview of the SQL query results.
In order to fetch the results of the query as a pandas DataFrame, run `collect()`.

```python
tbl_agency_names = tbl.views.gtfs_agency_names() >> collect()

# Use pandas .head() method to show first 5 rows of data
tbl_agency_names.head()
```

<!-- CODE OUTPUT -->
```pycon
   calitp_itp_id  calitp_url_number                 agency_name
0            256                  0         Porterville Transit
1            257                  0                   PresidiGo
2            259                  0  Redding Area Bus Authority
3              4                  0                  AC Transit
4            260                  0        Beach Cities Transit
```

#### Show query SQL

While `collect()` fetches query results, `show_query()` prints out the
SQL code that siuba generates.

```python
(tbl.views.gtfs_agency_names()
  >> filter(_.agency_name.str.contains("Metro"))
  >> show_query(simplify=True)
)

```

<!-- CODE OUTPUT -->
```SQL
SELECT `anon_1`.`calitp_itp_id`, `anon_1`.`calitp_url_number`, `anon_1`.`agency_name`
FROM (SELECT calitp_itp_id, calitp_url_number, agency_name
FROM `views.gtfs_agency_names`) AS `anon_1`
WHERE regexp_contains(`anon_1`.`agency_name`, 'Metro')
```

Note that here the pandas Series method `str.contains` corresponds to `regexp_contains` in Google BigQuery.
