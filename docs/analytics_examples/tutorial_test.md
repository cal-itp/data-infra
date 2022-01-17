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
:tags: [remove-cell]
import geopandas as gpd
import os
import pandas as pd
import shapely

os.environ["CALITP_BQ_MAX_BYTES"] = str(100_000_000_000)

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
## Get trips for operator for one day and join with stop times for all trips

# Grab the stop times for a given date for just 1 agency
df_tbl_stop_times = (
    tbl.views.gtfs_schedule_dim_stop_times()
    >> filter(_.calitp_extracted_at <= SELECTED_DATE,
              _.calitp_deleted_at > SELECTED_DATE,
              _.calitp_itp_id == ITP_ID
             )
)

glue("df_tbl_stop_times_output", df_tbl_stop_times)
```
