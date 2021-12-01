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
# More Complex Queries

## Introduction

SHOULD THIS ONE GET FOLDED INTO EARLIER ONE?

The queries represented in the following tutorial are as follows:
* [**All the Stops and Arrival Times for an Operator on a Given Day*](stop-arrivals-operator)
* [**Assemble a Route Shapefile**](#assemble-a-route-shapefile)

(stop-arrivals-operator)
### All the Stops and Arrival Times for an Operator on a Given Day

As a simple example, we will filter to just the San Diego Metropolitan Transit System and grab 1 day's worth of data. We want all the trips, stops, arrival times, and stop geometry (lat/lon).

Tables used:
1. `tbl.views.gtfs_schedule_dim_stop_times()`: all stop arrival times for all operators, need to subset to particular date
1. `tbl.views.gtfs_schedule_fact_daily_trips()`: all trips for all operators, need to subset to particular date
1. `tbl.views.gtfs_schedule_dim_stops()`: lat/lon for all stops, need to subset to interested stops

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
```


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

### Assemble a Route Shapefile

Transit stops are given as lat/lon (point geometry), but what if we want to get the line geometry? We will demonstrate on one route for San Diego Metropolitan Transit System.

all_routes = gpd.GeoDataFrame()
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
single_route = gpd.GeoDataFrame(single_route, crs="EPSG:4326")


glue("single_route", single_route)

```
