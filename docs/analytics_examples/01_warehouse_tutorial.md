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
(warehouse-tutorial)=
# Tutorial - Querying the Data Warehouse (WIP)

## Introduction

The following content represents a tutorial introduction to simple queries that can be made to the calitp data warehouse, and the methods that can be used to perform them.

### Example Queries

The queries represented in the following tutorial are as follows:
* [**Number of Routes for a Given Agency Over Time**](routes-agency-time)
* [**Number of Stops for a Given Agency Over Time**](stops-agency-time)
* [**Number of Stops Made Across all Trips for an Agency**](stops-all-trips)
* [**For a Given Agency, on Each Day, Days Until the Feed Expires**](days-feed-expires)
* [**Max Number of Stops a Trip Can Have, Per Agency**](max-number-stops)

### Available Tools

The tools that we can use to answer them are:
* [**Metabase**](metabase) - our business insights and dashboarding tool
* **SQL** - using JupyterHub cloud notebooks
* [**Python**](jupyterhub) - using JupyterHub cloud notebooks
    * *siuba* - a Cal-ITP recommended data analysis library in Python
    * *cal-itp* - Cal-ITP's internal Python library
    * *pandas* - a commonly used data analysis library in Python (used sparsely in the examples below)

### Relevant Tables

#### Fact Tables
These tables contain measurements, metrics, and facts used to answer the questions from the following perspectives:

| Table Type | Location |
| -------- | -------- |
| **Feeds** | views.**gtfs_schedule_fact_daily_feeds** <br/> (in Metabase: **Gtfs Schedule Fact Daily Feeds**) |
| **Routes** | views.**gtfs_schedule_fact_daily_feed_routes** <br/> (in Metabase: **Gtfs Schedule Fact Daily Feed Routes**) |
| **Stops** | views.**gtfs_schedule_fact_daily_feed_stops** <br/> (in Metabase: **Gtfs Schedule Fact Daily Feed Stops**) |
| **Trips** | views.**gtfs_schedule_data_feed_trip_stops_latest** <br/> (in Metabase: **Gtfs Schedule Data Feed Trip Stops Latest**) |

#### Dimensional Tables
These tables compliment the fact tables by providing additional descriptive attributes:

| Table | Location | Description |
| -------- | -------- | -------- |
| **Dim Feeds** | views.**gtfs_schedule_dim_feeds** <br/> (in Metabase: **Gtfs Schedule Dim Feeds**) | Joining with this table is the most common way to append calitp_feed_name (our primary agency identifier) to fact tables. |

### Important Column Types

| Column Type | Notable Columns | Description |
| -------- | -------- | -------- |
| **Agency** | **calitp_feed_name** <br/> (in Metabase: **Calitp Feed Name**) | Our primary agency identifier <br/> In most of the examples below, this is gathered from the table: views.**gtfs_schedule_dim_feeds** <br/> (in Metabase: **Gtfs Schedule Dim Feeds**) |
| **Time** | | |
| **Geography** | | |

### Python Libraries to Import

```{code-cell}
from calitp.tables import tbl
from calitp import query_sql
from siuba import *
import pandas as pd
import calitp.magics
pd.set_option("display.max_rows", 20)
```

```{code-cell}
:tags: [remove-cell]
from myst_nb import glue
```

## Query Examples

(routes-agency-time)=
### 1. Number of Routes for a Given Agency Over Time

```{code-cell}
:tags: [remove-cell]
%%sql
joshua =
SELECT
    calitp_feed_name,
    date,
    count(*) AS count_feeds
FROM `views.gtfs_schedule_fact_daily_feed_routes`
JOIN `views.gtfs_schedule_dim_feeds` USING (feed_key)
WHERE
    calitp_feed_name = "Unitrans (0)"
GROUP BY
    1, 2
ORDER BY
    date DESC
LIMIT 10

```

```{code-cell}
:tags: [remove-cell]
pythonroutesexample = (
    tbl.views.gtfs_schedule_fact_daily_feed_routes()
    >> left_join(_, tbl.views.gtfs_schedule_dim_feeds(), "feed_key")
    >> filter(_.calitp_feed_name == "Unitrans (0)")
    >> count(_.date)
    >> arrange(_.date)
)

glue("examplep1", pythonroutesexample)
```

````{tabbed} Metabase
**Primary Fact Table** → Gtfs Schedule Fact Daily Feed Routes

**Secondary Table** → Gtfs Schedule Dim Feeds

*Time* → **Date** (*FILTER*)

*Geography* → **Route Key** (the unique identifier for each record, to *COUNT* by)

*Agency* → Metabase automatically joins with table **Gtfs Schedule Dim Feeds** on variable **Feed Key** to get **Calitp Feed Name** (*FILTER*)

![Collection Matrix](assets/routes_agency_over_time.png)
````
````{tabbed} SQL
**Primary Fact Table** → views.gtfs_schedule_fact_daily_feed_routes

**Secondary Table** →  views.gtfs_schedule_dim_feeds

*Time* → **date** (*GROUP BY*)

*Geography* → **route_key** (the unique identifier for each record, to *COUNT* by)

*Agency* → Join with table **views.gtfs_schedule_dim_feeds** on variable **feed_key** for **calitp_feed_name** (*GROUP BY*)

```sql
SELECT
    calitp_feed_name,
    date,
    count(*) AS count_feeds
FROM `views.gtfs_schedule_fact_daily_feed_routes`
JOIN `views.gtfs_schedule_dim_feeds` USING (feed_key)
WHERE
    calitp_feed_name = "Unitrans (0)"
GROUP BY
    1, 2
ORDER BY
    date DESC
LIMIT 10
```

````
````{tabbed} siuba
**Primary Fact Table** → views.gtfs_schedule_fact_daily_feed_routes

**Secondary Table** →  views.gtfs_schedule_dim_feeds

*Time* → **date** (*COUNT* by)

*Geography* → **route_key** (the unique identifier for each record)

*Agency* → Join with table **views.gtfs_schedule_dim_feeds** on variable **feed_key** for **calitp_feed_name** (*FILTER* by)

```python
# Join to get CalITP Feed Names
# Count routes by date and CalITP Feed Names, order by date, filter by specific calitp_feed_name
(
    tbl.views.gtfs_schedule_fact_daily_feed_routes()
    >> left_join(_, tbl.views.gtfs_schedule_dim_feeds(), "feed_key")
    >> filter(_.calitp_feed_name == "Unitrans (0)")
    >> count(_.date)
    >> arrange(_.date)
)
```
```{glue:figure} examplep1
```
````

(stops-agency-time)=
### 2. Number of Stops for a Given Agency Over Time

#### Metabase
**Primary Fact Table** → Gtfs Schedule Fact Daily Feed Stops

**Secondary Table** → Gtfs Schedule Dim Feeds

*Time* → **Date** (*COUNT* by)

*Geography* → **Stop Key** (the unique identifier for each record, to *COUNT* by)

*Agency* → Metabase automatically joins with table **Gtfs Schedule Dim Feeds** on variable **Feed Key** to get **Calitp Feed Name** (*FILTER* by)

![Collection Matrix](assets/stops_agency_over_time.png)

#### SQL
**Primary Fact Table** → views.gtfs_schedule_fact_daily_feed_stops

**Secondary Table** →  views.gtfs_schedule_dim_feeds

*Time* → **date** (*GROUP BY*)

*Geography* → **stop_key** (the unique identifier for each record, to *COUNT* by)

*Agency* → Join with table **views.gtfs_schedule_dim_feeds** on variable **feed_key** for **calitp_feed_name** (*GROUP BY*)

```{code-cell}
:tags: [remove-input]
%%sql -m
    SELECT
        calitp_feed_name,
        date,
        count(*) AS count_stops
    FROM `views.gtfs_schedule_fact_daily_feed_stops`
    JOIN `views.gtfs_schedule_dim_feeds` USING (feed_key)
    WHERE
        calitp_feed_name = "Unitrans (0)"
    GROUP BY
        1, 2
    ORDER BY
        date
    LIMIT 10
```

#### siuba
**Primary Fact Table** → views.gtfs_schedule_fact_daily_feed_stops

**Secondary Table** →  views.gtfs_schedule_dim_feeds

*Time* → **date** (*GROUP BY*)

*Geography* → **stop_key** (the unique identifier for each record, to *COUNT* by)

*Agency* → Join with table **views.gtfs_schedule_dim_feeds** on variable **feed_key** for **calitp_feed_name** (*GROUP BY*)

```{code-cell}
## Join to get CalITP Feed Names
## Count stops by date and CalITP Feed Names, order by date, filter by specific calitp_feed_name
(
    tbl.views.gtfs_schedule_fact_daily_feed_stops()
    >> left_join(_, tbl.views.gtfs_schedule_dim_feeds(), "feed_key")
    >> count(_.date, _.calitp_feed_name)
    >> filter(_.calitp_feed_name == "Unitrans (0)")
    >> arrange(_.date)
)
```

(stops-all-trips)=
### 3. Number of Stops Made Across all Trips for an Agency

#### Metabase
**Primary Fact Table** → Gtfs Schedule Data Feed Trip Stops Latest

**Secondary Table** → Gtfs Schedule Dim Feeds

*Time* → **no variable** - this table only has information for the current day

*Geography* → **Stop Time Key** (the unique identifier for each record, to *COUNT* by)

*Agency* → Metabase automatically joins with table **Gtfs Schedule Dim Feeds** on variable **Feed Key** to get **Calitp Feed Name** (*FILTER* by)

***Count of Trip Stops Made Across all Trips for an Agency***

![Collection Matrix](assets/count_trip_stops.png)

***Distinct Trips in Trip Stops***

![Collection Matrix](assets/distinct_trips_in_trip_stops.png)

***Distinct Stops in Trip Stops***

![Collection Matrix](assets/distinct_stops_in_trip_stops.png)

#### SQL
**Primary Fact Table** → views.gtfs_schedule_data_feed_trip_stops_latest

*Time* → **no variable** - this table only has information for the current day

*Geography* → **stop_time_key** (the unique identifier for each record, to *COUNT* by)

*Agency* → **calitp_feed_name** (*GROUP BY*)

```{code-cell}
:tags: [remove-input]
%%sql -m

SELECT
    calitp_feed_name,

    count(*) AS n_trip_stops,
    count(distinct(trip_id)) AS n_trips,
    count(distinct(stop_id)) AS n_stops
FROM `views.gtfs_schedule_data_feed_trip_stops_latest`
WHERE
    calitp_feed_name = "Unitrans (0)"
GROUP BY
    calitp_feed_name
```

#### siuba
**Primary Fact Table** → views.gtfs_schedule_data_feed_trip_stops_latest

*Time* → **no variable** - this table only has information for the current day

*Geography* → **stop_time_key** (the unique identifier for each record, to *COUNT* by)

*Agency* → **calitp_feed_name** (*GROUP BY*)

```{code-cell}
(
    tbl.views.gtfs_schedule_data_feed_trip_stops_latest()
    >> filter(_.calitp_feed_name == "Unitrans (0)")
    >> summarize(
        n_trips=_.trip_id.nunique(), n_stops=_.stop_id.nunique(), n=_.trip_id.size()
    )
)
```

(days-feed-expires)=
### 4. For a Given Agency, on Each Day, Days Until the Feed Expires

#### Metabase
**Primary Fact Table** → Gtfs Schedule Fact Daily Feeds

**Secondary Table** → Join: Gtfs Schedule Dim Feeds

*Time* → **Date**, **Feed End Date**

*Measure* → **Days Until Feed End Date**

*Agency* → Join with table **Gtfs Schedule Dim Feeds** on variable **feed_key** for **Calitp Feed Name** (*FILTER* by) and **Feed End Date**

**Columns to Select:**
* Gtfs Schedule Fact Daily Feeds
    * Date
    * Days Until Feed End Date
* Gtfs Schedule Dim Feeds
    * Calitp Feed Name
    * Feed End Date

![Collection Matrix](assets/days_until_agency_feed_expires.png)

#### SQL
**Primary Fact Table** → views.gtfs_schedule_fact_daily_feeds

**Secondary Table** → views.gtfs_schedule_dim_feeds

*Time* → **date**, **feed_end_date**

*Measure* → **days_until_feed_end_date**

*Agency* → Join with table **views.gtfs_schedule_dim_feeds** on variable **feed_key** for **calitp_feed_name** (*GROUP BY*)

```{code-cell}
:tags: [remove-input]
%%sql -m

SELECT
    calitp_feed_name,
    date,
    days_until_feed_end_date,
    feed_end_date
FROM views.gtfs_schedule_fact_daily_feeds
JOIN views.gtfs_schedule_dim_feeds USING (feed_key)
WHERE
    date = "2021-09-01" AND calitp_feed_name = "Unitrans (0)"
```

#### siuba

**Primary Fact Table** → views.gtfs_schedule_fact_daily_feeds

**Secondary Table** → views.gtfs_schedule_dim_feeds

*Time* → **date** (*FILTER* by), **feed_end_date**

*Measure* → **days_until_feed_end_date**

*Agency* → Join with table **views.gtfs_schedule_dim_feeds** on variable **feed_key** for **calitp_feed_name** (*FILTER* by)

```{code-cell}
(
    tbl.views.gtfs_schedule_fact_daily_feeds()
    >> left_join(_, tbl.views.gtfs_schedule_dim_feeds(), "feed_key")
    >> select(_.calitp_feed_name, _.date, _.days_until_feed_end_date, _.feed_end_date)
    >> filter(_.date == "2021-09-01", _.calitp_feed_name == "Unitrans (0)")
)
```

### 5. Max Number of Stops a Trip Can Have, Per Agency

(max-number-stops)=
#### Metabase
**Primary Fact Table** → Gtfs Schedule Data Feed Trip Stops Latest

**Secondary Table** → Gtfs Schedule Dim Feeds

*Time* → **no variable**, finding max across all days

*Geography* → **Trip ID** (the unique identifier for each record, to *COUNT* by)

*Agency* → Metabase automatically joins with table **Gtfs Schedule Dim Feeds** on variable **Feed Key** to get **Calitp Feed Name** (*COUNT* by)


![Collection Matrix](assets/max_stops_per_trip_by_agency.png)

#### SQL
**Primary Fact Table** →  views.gtfs_schedule_data_feed_trip_stops_latest

**Secondary Table** →  views.gtfs_schedule_dim_feeds

*Time* → **no variable**, finding max across all days

*Geography* → **trip_id** (the unique identifier for each record, to *GROUP BY*)

*Agency* → Join with table **views.gtfs_schedule_dim_feeds** on variable **feed_key** for **calitp_feed_name** (*GROUP BY*)

```{code-cell}
:tags: [remove-input]
%%sql -m
WITH

counting_stop_times AS (

    -- count the number of stops each trip in each feed makes
    SELECT
        trip_id,
        calitp_feed_name,
        COUNT(*) AS n_trip_stop_times
    FROM `views.gtfs_schedule_data_feed_trip_stops_latest`
    GROUP BY
        1, 2
)

-- calculate the max number of stops made by a feed's trip
-- we filter to keep only the Unitrans feed for this example
SELECT
    calitp_feed_name,
    MAX(n_trip_stop_times) AS max_n_trip_stop_times
FROM
    counting_stop_times
WHERE
     calitp_feed_name = "Unitrans (0)"
GROUP BY
    calitp_feed_name

```

#### siuba
**Primary Fact Table** →  views.gtfs_schedule_data_feed_trip_stops_latest

**Secondary Table** →  views.gtfs_schedule_dim_feeds

*Time* → **no variable**, finding max across all days

*Geography* → **trip_id** (the unique identifier for each record, to *GROUP BY*)

*Agency* → Join with table **views.gtfs_schedule_dim_feeds** on variable **feed_key** for **calitp_feed_name** (*GROUP BY*)

```{code-cell}
(
    tbl.views.gtfs_schedule_data_feed_trip_stops_latest()
    >> count(_.trip_id, _.calitp_feed_name)
    >> filter(_.calitp_feed_name == "Unitrans (0)")
    >> summarize(n_max=_.n.max())
)
```
