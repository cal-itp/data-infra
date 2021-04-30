# ---
# python_callable: main
# ---

import pandas as pd
from calitp import get_project_id


# TODO: this could be data in the data folder
def main():
    df = pd.DataFrame(
        {
            "table_name": [
                "agency",
                "routes",
                "stop_times",
                "stops",
                "trips",
                "validation_report",
            ],
            "ext": [".txt"] * 5 + [".json"],
        }
    )

    df["file_name"] = df.table_name + df.ext

    df.to_gbq(
        "test_gtfs_schedule_history.calitp_included_gtfs_tables",
        project_id=get_project_id(),
    )
