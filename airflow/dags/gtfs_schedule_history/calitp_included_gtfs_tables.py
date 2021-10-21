# ---
# python_callable: main
# ---

import pandas as pd
from calitp.config import get_project_id, format_table_name


# TODO: this could be data in the data folder
def main():
    df = pd.DataFrame(
        [
            # required tables ----
            ("agency", ".txt", True),
            ("routes", ".txt", True),
            ("stop_times", ".txt", True),
            ("stops", ".txt", True),
            ("trips", ".txt", True),
            ("validation_report", ".json", True),
            # conditional tables ----
            ("calendar", ".txt", False),
            ("calendar_dates", ".txt", False),
            # optional tables ----
            ("transfers", ".txt", False),
            ("feed_info", ".txt", False),
            ("frequencies", ".txt", False),
            ("fare_rules", ".txt", False),
            ("fare_attributes", ".txt", False),
            ("shapes", ".txt", False),
            ("attributions", ".txt", False),
            ("levels", ".txt", False),
            ("pathways", ".txt", False),
            ("translations", ".txt", False),
        ],
        columns=["table_name", "ext", "is_required"],
    )

    df["file_name"] = df.table_name + df.ext

    df.to_gbq(
        format_table_name("gtfs_schedule_history.calitp_included_gtfs_tables"),
        project_id=get_project_id(),
        if_exists="replace",
    )
