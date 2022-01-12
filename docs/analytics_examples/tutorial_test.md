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

# Tutorial Test

```{code-cell}
import geopandas as gpd
import os
import pandas as pd
import shapely

os.environ["CALITP_BQ_MAX_BYTES"] = str(50_000_000_000)

import calitp
from calitp.tables import tbl
from siuba import *

pd.set_option("display.max_rows", 10)

SELECTED_DATE = "2021-09-01"
ITP_ID = 278 # San Diego Metropolitan Transit System
from myst_nb import glue
import calitp.magics
```

```{code-cell}
:tags: [remove-cell]
## Get trips for operator for one day and join with stop times for all trips

# Grab the stop times for a given date for just 1 agency
tbl_stop_times = (
    tbl.views.gtfs_schedule_dim_stop_times()
    >> filter(_.calitp_extracted_at <= SELECTED_DATE,
              _.calitp_deleted_at > SELECTED_DATE,
              _.calitp_itp_id == ITP_ID
             )
)

# Grab the trips done on that day, for that agency
daily_stops = (
    tbl.views.gtfs_schedule_fact_daily_trips()
    >> filter(_.calitp_itp_id == ITP_ID,
              _.service_date == SELECTED_DATE,
              _.is_in_service == True)
    # Join the trip to the stop time
    # For a given bus route (left df), attach all the stops (right df)
    >> left_join(_, tbl_stop_times,
              # also added url number to the join keys ----
             ["calitp_itp_id", "calitp_url_number", "trip_id"])
    >> inner_join(_, tbl.views.gtfs_schedule_dim_stops(),
                 ["calitp_itp_id", "stop_id"])
    >> select(_.itp_id == _.calitp_itp_id,
              _.date == _.service_date,
              _.trip_key, _.trip_id, _.stop_id, _.arrival_time,
              _.stop_lat, _.stop_lon, _.stop_name,
             )
    >> collect()
    )

glue("daily_stops_output", daily_stops)
```

````{tabbed} Metabase
*You can view this query in Metabase [using this link](https://dashboards.calitp.org/question/223-5-find-the-trip-with-the-most-number-of-stops-per-agency/notebook)*

![Collection Matrix](assets/most_stops_per_trip_by_agency.png)
````

````{tabbed} SQL
```python
# Allows us to query SQL in the JupyterLab notebook
# Use this in combination with '%%sql', as seen below
import calitp.magics
```
````

````{tabbed} siuba
```python
# Allows us to query tables in the warehouse
from calitp.tables import tbl

# The data analysis library used
from siuba import *
```
```python
## Get trips for operator for one day and join with stop times for all trips

# Grab the stop times for a given date for just 1 agency
tbl_stop_times = (
    tbl.views.gtfs_schedule_dim_stop_times()
    >> filter(_.calitp_extracted_at <= SELECTED_DATE,
              _.calitp_deleted_at > SELECTED_DATE,
              _.calitp_itp_id == ITP_ID
             )
)

# Grab the trips done on that day, for that agency
daily_stops = (
    tbl.views.gtfs_schedule_fact_daily_trips()
    >> filter(_.calitp_itp_id == ITP_ID,
              _.service_date == SELECTED_DATE,
              _.is_in_service == True)
    # Join the trip to the stop time
    # For a given bus route (left df), attach all the stops (right df)
    >> left_join(_, tbl_stop_times,
              # also added url number to the join keys ----
             ["calitp_itp_id", "calitp_url_number", "trip_id"])
    >> inner_join(_, tbl.views.gtfs_schedule_dim_stops(),
                 ["calitp_itp_id", "stop_id"])
    >> select(_.itp_id == _.calitp_itp_id,
              _.date == _.service_date,
              _.trip_key, _.trip_id, _.stop_id, _.arrival_time,
              _.stop_lat, _.stop_lon, _.stop_name,
             )
    >> collect()
    )
```

```{glue:figure} daily_stops_output
```

````
