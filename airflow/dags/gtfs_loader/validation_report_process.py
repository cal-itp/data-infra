# ---
# python_callable: validator_process
# provide_context: true
# external_dependencies:
#   - gtfs_downloader: validate_gcs_bucket
# ---

import pandas as pd
import json

from calitp import save_to_gcfs, read_gcfs

from utils import get_successfully_downloaded_feeds

PANDAS_TYPES_TO_BIGQUERY = {"O": "STRING", "i": "INTEGER", "f": "NUMERIC"}

COERCE_TO_STRING = {
    "fieldValue",
}


def process_notices(itp_id, url_number, validation):
    raw_codes = validation["data"]["report"]["notices"]

    # one row per code. includes a notices column with nested details
    df_codes = pd.DataFrame(raw_codes)
    df_codes.insert(0, "calitp_itp_id", itp_id)
    df_codes.insert(1, "calitp_url_number", url_number)

    return df_codes

    return df_codes.explode("notices")


def infer_notice_schema(notice_entries):
    # note that convert_dtypes enables integer cols w/ missing values
    wide = pd.DataFrame(notice_entries).convert_dtypes()
    schema = []
    for k in wide:
        schema.append(dict(name=k, type=PANDAS_TYPES_TO_BIGQUERY[wide[k].dtype.kind]))

    return schema


def coerce_notice_values_to_str(raw_codes, str_fields):
    for code in raw_codes["notices"]:
        for detail in code["notices"]:
            for field in detail:
                if field in str_fields:
                    detail[field] = str(detail[field])


def validator_process(execution_date, **kwargs):
    base_path = f"schedule/{execution_date}"
    successes = get_successfully_downloaded_feeds(execution_date)

    # hold on to notices, so we can infer schema after
    # note that I've commented out the code for inferring schema below,
    # but it was usefule for generating, then hand-tweaking to load
    # into bigquery
    # notice_entries = []
    for k, row in successes.iterrows():
        agency_path = f"{base_path}/{row['itp_id']}_{row['url_number']}"
        url = f"{agency_path}/validation.json"
        dst_path = f"{agency_path}/processed/validation_report.json"

        validation = json.load(read_gcfs(url))

        # copy code-level notices, and add internal ids
        raw_codes = {**validation["data"]["report"]}
        raw_codes["calitp_itp_id"] = row["itp_id"]
        raw_codes["calitp_url_number"] = row["url_number"]
        raw_codes["calitp_extracted_at"] = execution_date.to_date_string()
        raw_codes["calitp_gtfs_validated_by"] = validation["version"]

        # coerce types labeled "string" to a string
        coerce_notice_values_to_str(raw_codes, COERCE_TO_STRING)

        json_codes = json.dumps(raw_codes).encode()
        # df_notices = process_notices(row["itp_id"], row["url_number"], validation)
        # csv_string = df_notices.to_csv(index=None).encode()
        # notice_entries.extend(df_notices.notices.tolist())

        save_to_gcfs(json_codes, dst_path, use_pipe=True)

    # schema = infer_notice_schema(notice_entries)


# infer schema
