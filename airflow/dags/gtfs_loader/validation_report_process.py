# ---
# python_callable: validator_process
# provide_context: true
# external_dependencies:
#   - gtfs_downloader: validate_gcs_bucket
# ---

import pandas as pd
import json

from calitp import save_to_gcfs, read_gcfs

PANDAS_TYPES_TO_BIGQUERY = {"O": "STRING", "i": "INTEGER", "f": "NUMERIC"}


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


def validator_process(execution_date, **kwargs):
    base_path = f"schedule/{execution_date}"

    status = pd.read_csv(read_gcfs(f"{base_path}/status.csv"))
    success = status[lambda d: d.status == "success"]

    # hold on to notices, so we can infer schema after
    # notice_entries = []
    for k, row in success.iterrows():
        agency_path = f"{base_path}/{row['itp_id']}_{row['url_number']}"
        url = f"{agency_path}/validation.json"
        dst_path = f"{agency_path}/processed/validation_report.json"

        validation = json.load(read_gcfs(url))

        # copy code-level notices, and add internal ids
        raw_codes = {**validation["data"]["report"]}
        raw_codes["calitp_itp_id"] = row["itp_id"]
        raw_codes["calitp_url_number"] = row["url_number"]

        json_codes = json.dumps(raw_codes).encode()
        # df_notices = process_notices(row["itp_id"], row["url_number"], validation)
        # csv_string = df_notices.to_csv(index=None).encode()
        # notice_entries.extend(df_notices.notices.tolist())

        save_to_gcfs(json_codes, dst_path, use_pipe=True)

    # schema = infer_notice_schema(notice_entries)


# infer schema
