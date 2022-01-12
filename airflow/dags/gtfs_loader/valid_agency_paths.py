# ---
# python_callable: main
# provide_context: true
# external_dependencies:
#   - gtfs_downloader: validate_gcs_bucket
# ---

from calitp import read_gcfs, save_to_gcfs
import json
import pandas as pd

from utils import get_successfully_downloaded_feeds

ERROR_MISSING_FILE = "missing_required_file"
VALIDATION_FILE = "validation.json"


def get_notice_codes(validation):
    code_entries = validation["data"]["report"]["notices"]
    return set([entry["code"] for entry in code_entries])


def main(execution_date, **kwargs):
    in_path = f"schedule/{execution_date}"
    print(in_path)

    successes = get_successfully_downloaded_feeds(execution_date)

    agency_errors = []
    loadable_agencies = []
    for ii, row in successes.iterrows():
        path_agency = f"{in_path}/{row['itp_id']}_{row['url_number']}"
        path_validation = f"{path_agency}/{VALIDATION_FILE}"

        print(f"reading validation file: {path_validation}")
        validation = json.load(read_gcfs(path_validation))

        unique_codes = get_notice_codes(validation)

        if ERROR_MISSING_FILE not in unique_codes:
            loadable_agencies.append(path_agency)
        else:
            agency = dict(itp_id=row["itp_id"], url_number=row["url_number"])
            agency_errors.append(agency)

    errors_df = pd.DataFrame(agency_errors)
    errors_str = errors_df.to_csv(index=False).encode()
    save_to_gcfs(
        errors_str, f"{in_path}/processed/agency_load_errors.csv", use_pipe=True
    )

    return loadable_agencies
