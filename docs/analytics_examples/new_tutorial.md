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

SHOULD THIS ONE GET FOLDED INTO EARLIER ONE..BUT NEED SQL AND METABASE EQUIVALENT?

The queries represented in the following tutorial are as follows:
* [**All the Stops and Arrival Times for an Operator on a Given Day**](stop-arrivals-operator)
* [**Assemble a Route Shapefile**](#assemble-a-route-shapefile)
* [**Filter with Lists and Unpacking**](#filter-with-lists-and-unpacking)

## Python Libraries to Import

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

(stop-arrivals-operator)=
### All the Stops and Arrival Times for an Operator on a Given Day

As a simple example, we will filter to just the San Diego Metropolitan Transit System and grab 1 day's worth of data. We want all the trips, stops, arrival times, and stop geometry (lat/lon).

Tables used:
1. `views.gtfs_schedule_dim_stop_times`: all stop arrival times for all operators, need to subset to particular date
1. `views.gtfs_schedule_fact_daily_trips`: all trips for all operators, need to subset to particular date
1. `views.gtfs_schedule_dim_stops`: lat/lon for all stops, need to subset to interested stops

Here, all the trips for one operator, for a particular day, is joined with all the stops that occur on all the trips. Then, the stops have their lat/lon information attached.

**CODE CELL HERE**

### Assemble a Route Shapefile

Transit stops are given as lat/lon (point geometry), but what if we want to get the line geometry? We will demonstrate on one route for San Diego Metropolitan Transit System.

Tables used:
1. `gtfs_schedule.shapes`: stops with stop sequence, lat/lon, and associated `shape_id`

**CODE CELL HERE**

### Filter with Lists and Unpacking

Queries can use the `isin` and take lists, as well as unpack lists. This nifty trick can keep the code clean.

Tables used:
1. `view.transitstacks`: some NTD related data, with each row being an operator
1. `gtfs_schedule_fact_daily_feed_stops`: stops associated with daily feed, subset to a particular date
1. `views.gtfs_schedule_dim_stops`: lat/lon for all stops, need to subset to interested stops

Here, the `transitstacks` table is filtered down to interested counties and certain columns. Using `isin` and unpacking a list (asterisk) is a quick way to do this.

**CODE CELL HERE**

Next, we can query the `gtfs_schedule_fat_daily_feed_stops` to grab the stops for a particular day's feed. Those stops are then joined to `gtfs_schedule_dim_stops` to get the lat/lon attached. Use `isin` to further filter the dataframe and only keep operators in the counties of interest.

**CODE CELL HERE**
