# ---
# python_callable: main
# ---

import pandas as pd
from calitp import get_project_id, format_table_name


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
            # optional tables ----
            ("transfers", ".txt", False),
            ("feed_info", ".txt", False),
        ],
        columns=["table_name", "ext", "is_required"],
    )

    df["file_name"] = df.table_name + df.ext

    df.to_gbq(
        format_table_name("gtfs_schedule_history.calitp_included_gtfs_tables"),
        project_id=get_project_id(),
        if_exists="replace",
    )
