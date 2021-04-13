# ---
# python_callable: main
# provide_context: true
# external_dependencies:
#   - gtfs_downloader: validate_gcs_bucket
# ---

from calitp import read_gcfs
import json
import pandas

ERROR_MISSING_FILE = "missing_required_file"
VALIDATION_FILE = "validation.json"


def get_notice_codes(validation):
    code_entries = validation["data"]["report"]["notices"]
    return set([entry["code"] for entry in code_entries])


def main(execution_date, **kwargs):
    in_path = f"schedule/{execution_date}"
    print(in_path)

    status = pandas.read_csv(read_gcfs(f"{in_path}/status.csv"))
    success = status[status.status == "success"]

    loadable_agencies = []
    for ii, row in success.iterrows():
        path_agency = f"{in_path}/{row['itp_id']}_{row['url_number']}"
        path_validation = f"{path_agency}/{VALIDATION_FILE}"

        print(f"reading validation file: {path_validation}")
        validation = json.load(read_gcfs(path_validation))

        unique_codes = get_notice_codes(validation)

        if ERROR_MISSING_FILE not in unique_codes:
            loadable_agencies.append(path_agency)

    return loadable_agencies
