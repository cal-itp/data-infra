from calitp.tables import tbl
from myst_nb import glue
from calitp import query_sql
from siuba import *
import pandas as pd
import calitp.magics
pd.set_option("display.max_rows", 20)

# Join to get CalITP Feed Names
# Count routes by date and CalITP Feed Names, order by date, filter by specific calitp_feed_name
routes = (
    tbl.views.gtfs_schedule_fact_daily_feed_routes()
    >> left_join(_, tbl.views.gtfs_schedule_dim_feeds(), "feed_key")
    >> filter(_.calitp_feed_name == "Unitrans (0)")
    >> count(_.date)
    >> arrange(_.date)
)

glue("what_are_names", routes)
