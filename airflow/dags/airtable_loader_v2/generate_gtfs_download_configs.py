# ---
# python_callable: convert_gtfs_datasets_to_download_configs
# provide_context: true
# dependencies:
#   - california_transit_gtfs_datasets
# ---
import gzip
import json
from typing import List, Tuple

import pendulum
from calitp.storage import (
    get_fs,
    GTFSDownloadConfig,
    AirtableGTFSDataExtract,
    AirtableGTFSDataRecord,
    GCSFileInfo,
    GTFSDownloadConfigExtract,
)
from pydantic import ValidationError


def gtfs_datasets_to_extract_configs(
    extract: AirtableGTFSDataExtract,
) -> Tuple[
    List[GTFSDownloadConfig], List[Tuple[AirtableGTFSDataRecord, ValidationError]]
]:
    valid = {}
    invalid = []

    for record in extract.records:
        if not record.data_quality_pipeline:
            continue
        try:
            valid[record.id] = (
                record.schedule_to_use_for_rt_validation,
                GTFSDownloadConfig(
                    extracted_at=extract.ts,
                    name=record.name,
                    url=record.pipeline_url,
                    feed_type=record.data,
                    auth_query_params={
                        record.authorization_url_parameter_name: record.url_secret_key_name
                    }
                    if record.authorization_url_parameter_name
                    and record.url_secret_key_name
                    else {},
                    auth_headers={
                        record.authorization_header_parameter_name: record.header_secret_key_name
                    }
                    if record.authorization_header_parameter_name
                    and record.header_secret_key_name
                    else {},
                ),
            )
        except ValidationError as e:
            invalid.append((record, e))

    # schedule_record_ids is a list... also this is kinda ugly
    for schedule_record_ids, config in valid.values():
        if schedule_record_ids and len(schedule_record_ids) == 1:
            first = schedule_record_ids[0]
            if first in valid:
                config.schedule_url_for_validation = valid[first][1].url

    return list(valid[1] for valid in valid.values()), invalid


def convert_gtfs_datasets_to_download_configs(task_instance, execution_date, **kwargs):
    extract_path = task_instance.xcom_pull(task_ids="california_transit_gtfs_datasets")
    print(f"loading raw airtable records from {extract_path}")

    fs = get_fs()
    file = GCSFileInfo(**fs.info(extract_path))

    with fs.open(extract_path, "rb") as f:
        content = gzip.decompress(f.read())

    # I don't love this; this should be handled via metadata
    extract = AirtableGTFSDataExtract(
        filename=file.filename,
        ts=pendulum.parse(file.partition["ts"], exact=True),
        records=[
            AirtableGTFSDataRecord(**json.loads(row))
            for row in content.decode().splitlines()
        ],
    )

    valid, invalid = gtfs_datasets_to_extract_configs(extract)

    msg = f"got {len(valid)} configs out of {len(extract.records)} total records"
    print(msg)

    for record, error in invalid:
        print(record.name, record.pipeline_url, error)

    if len(valid) / len(extract.records) < 0.95:
        raise RuntimeError(msg)

    jsonl_content = gzip.compress("\n".join(record.json() for record in valid).encode())
    GTFSDownloadConfigExtract(
        filename="configs.jsonl.gz",
        ts=extract.ts,
        records=valid,
    ).save_content(content=jsonl_content, fs=fs)


if __name__ == "__main__":
    convert_gtfs_datasets_to_download_configs(None, None)
