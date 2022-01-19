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
# File for Glue

## Python Libraries to Import

```{code-cell}
from myst_nb import glue
import calitp.magics
from calitp import query_sql

import geopandas as gpd
import os
import pandas as pd
import shapely

os.environ["CALITP_BQ_MAX_BYTES"] = str(500_000_000_000)

import calitp
from calitp.tables import tbl
from siuba import *

pd.set_option("display.max_rows", 10)

SELECTED_DATE = "2021-09-01"
ITP_ID = 278 # San Diego Metropolitan Transit System
```

### 1. All the Stops and Arrival Times for an Operator on a Given Day

```{code-cell}
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
siuba_daily_stops = (
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
    )

glue("siuba_daily_stops_output", siuba_daily_stops)
```

```{code-cell}
:tags: [remove-cell]
sql_stops_table = query_sql("""
WITH
  tbl_stop_times AS (
  SELECT
    *
  FROM
    `views.gtfs_schedule_dim_stop_times`
  WHERE
    `calitp_extracted_at` <= '2021-09-01'
    AND `calitp_deleted_at` > '2021-09-01'
    AND `calitp_itp_id` = 278),

trips_table AS (
SELECT
  *
FROM
  `views.gtfs_schedule_fact_daily_trips` AS table1
LEFT JOIN
  tbl_stop_times AS table2
USING (calitp_itp_id, calitp_url_number, trip_id)
WHERE
  `calitp_itp_id` = 278
  AND `service_date` = '2021-09-01'),

stops_table AS (
SELECT
*
FROM
trips_table AS table3
INNER JOIN
`views.gtfs_schedule_dim_stops`
USING (calitp_itp_id, stop_id)
)

SELECT
calitp_itp_id,
service_date,
trip_key,
trip_id,
stop_id,
arrival_time,
stop_lat,
stop_lon,
stop_name
FROM
stops_table""", as_df=True)
glue("sql_stops_table_output", sql_stops_table)
```

### 2. Assemble a Route Shapefile

```{code-cell}
# Grab the shapes for this operator
shapes = (tbl.gtfs_schedule.shapes()
          >> filter(_.calitp_itp_id == int(ITP_ID))
          >> collect()
)

# Make a gdf
shapes = (gpd.GeoDataFrame(shapes,
                      geometry = gpd.points_from_xy
                      (shapes.shape_pt_lon, shapes.shape_pt_lat),
                      crs = 'EPSG:4326')
     )

MY_ROUTE = "1_2_156"

# Now, combine all the stops by stop sequence, and create linestring
single_shape = (shapes
                >> filter(_.shape_id == MY_ROUTE)
                >> mutate(shape_pt_sequence = _.shape_pt_sequence.astype(int))
                # arrange in the order of stop sequence
                >> arrange(_.shape_pt_sequence)
)

# Convert from a bunch of points to a line (for a route, there are multiple points)
route_line = shapely.geometry.LineString(list(single_shape['geometry']))

# Create a df that will hold this new line geometry
single_route = (single_shape
               [['calitp_itp_id', 'shape_id', 'calitp_extracted_at']]
               .iloc[[0]]
              ) ##preserve info cols

# Set the geometry column values
single_route['geometry'] = route_line

# Convert to gdf
siuba_single_route = gpd.GeoDataFrame(single_route, crs="EPSG:4326")


glue("single_route_output", siuba_single_route)
```

### 3. Filter with Lists and Unpacking

```{code-cell}
# Subset to counties of interest
lossan_counties = ['San Luis Obispo', 'Santa Barbara', 'Ventura',
                  'Los Angeles', 'San Diego', 'Orange']

# List the columns to keep
info_cols = ['itp_id', 'transit_provider', 'ntd_id',
             'modes', 'county', 'legacy_ntd_id']

vehicle_cols = ['bus', 'articulated_bus', 'over_the_road_bus',
                'school_bus', 'trolleybus', 'vintage_historic_trolley',
                'streetcar']

paratransit_cols = ['van', 'cutaway', 'automobile',
                     'minivan', 'sport_utility_vehicle']

# transitstacks has a lot of columns, and we want to keep a fairly large subset of them
lossan_df = (tbl.views.transitstacks()
             # Collect to turn into pandas.DataFrame earlier for isin to work
             >> collect()
             >> filter(_.county.isin(lossan_counties))
             # Nifty way to unpack large list of columns
             >> select(*(info_cols + vehicle_cols + paratransit_cols))
            )

lossan_df.head()
```

Next, we can query the `gtfs_schedule_fat_daily_feed_stops` to grab the stops for a particular day's feed. Those stops are then joined to `gtfs_schedule_dim_stops` to get the lat/lon attached. Use `isin` to further filter the dataframe and only keep operators in the counties of interest.

```{code-cell}
# Grab stops for that day
siuba_lossan_stops = (tbl.views.gtfs_schedule_fact_daily_feed_stops()
                >> filter(_.date == SELECTED_DATE)
                >> select(_.stop_key, _.date)
                # Merge with stop geom using stop_key
                >> inner_join(_,
                              (tbl.views.gtfs_schedule_dim_stops()
                               >> select(_.calitp_itp_id, _.stop_key, _.stop_id,
                                         _.stop_lat, _.stop_lon)
                              ), on='stop_key')
                >> collect()
                # Only grab the ITP IDs we're interested in
                >> filter(_.calitp_itp_id.isin(lossan_df.itp_id))
                # This is to sort in order for ITP_ID and stop_id
                >> arrange(_.calitp_itp_id, _.stop_id)
               ).reset_index(drop=True)

glue("siuba_lossan_stops_output", siuba_lossan_stops)
```
