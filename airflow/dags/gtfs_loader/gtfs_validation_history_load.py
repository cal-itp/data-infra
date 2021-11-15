# ---
# python_callable: main
# provide_context: true
# dependencies:
#   - validation_report_process
# ---

from calitp.config import get_bucket
from calitp.storage import get_fs

import constants
from utils import get_successfully_downloaded_feeds


def main(execution_date, ti, **kwargs):
    fs = get_fs()
    bucket = get_bucket()
    successes = get_successfully_downloaded_feeds(execution_date)

    ttl_feeds_copied = 0
    for k, row in successes.iterrows():
        date_string = execution_date.to_date_string()

        # only handle today's updated data (backfill dag to run all) ----

        # copy processed validator results ----
        id_and_url = f"{row['itp_id']}_{row['url_number']}"
        src_validator = "/".join(
            [
                bucket,
                "schedule",
                str(execution_date),
                id_and_url,
                "processed",
                constants.VALIDATION_REPORT,
            ]
        )
        dst_validator = "/".join(
            [
                bucket,
                "schedule",
                "processed",
                f"{date_string}_{id_and_url}",
                constants.VALIDATION_REPORT,
            ]
        )

        print(f"Copying from {src_validator} to {dst_validator}")

        fs.copy(src_validator, dst_validator)

        ttl_feeds_copied += 1

    print("total feeds copied:", ttl_feeds_copied)
