# ---
# python_callable: convert_gtfs_datasets_to_download_configs
# provide_context: true
# dependencies:
#   - california_transit_gtfs_datasets
# ---
import gzip
import json
import logging
from typing import List, Tuple

import pendulum
import sentry_sdk
from calitp_data_infra.storage import (
    AirtableGTFSDataExtract,
    AirtableGTFSDataRecord,
    GCSFileInfo,
    GTFSDownloadConfig,
    GTFSDownloadConfigExtract,
    get_fs,
)
from pydantic import ValidationError


def gtfs_datasets_to_extract_configs(
    extract: AirtableGTFSDataExtract,
) -> Tuple[
    List[GTFSDownloadConfig],
    List[Tuple[AirtableGTFSDataRecord, ValidationError]],
    List[AirtableGTFSDataRecord],
]:
    valid = {}
    invalid = []
    skipped = []

    for record in extract.records:
        if not record.data_quality_pipeline:
            skipped.append(record)
            continue
        with sentry_sdk.push_scope() as scope:
            scope.set_tag("record_id", record.id)
            scope.set_tag("record_name", record.name)
            scope.set_context("record", record.dict())
            try:
                valid[record.id] = (
                    record.schedule_to_use_for_rt_validation,
                    GTFSDownloadConfig(
                        extracted_at=extract.ts,
                        name=record.name,
                        url=record.pipeline_url,
                        feed_type=record.data,
                        auth_query_params=(
                            {
                                record.authorization_url_parameter_name: record.url_secret_key_name
                            }
                            if record.authorization_url_parameter_name
                            and record.url_secret_key_name
                            else {}
                        ),
                        auth_headers=(
                            {
                                record.authorization_header_parameter_name: record.header_secret_key_name
                            }
                            if record.authorization_header_parameter_name
                            and record.header_secret_key_name
                            else {}
                        ),
                    ),
                )
            except ValidationError as e:
                scope.fingerprint = [record.id, record.name, str(e)]
                sentry_sdk.capture_exception(e, scope=scope)
                logging.warning(
                    f'validation error for record id="{record.id}" name="{record.name}": {e}'
                )
                invalid.append((record, e))

    # schedule_record_ids is a list... also this is kinda ugly
    for schedule_record_ids, config in valid.values():
        if schedule_record_ids and len(schedule_record_ids) == 1:
            first = schedule_record_ids[0]
            if first in valid:
                config.schedule_url_for_validation = valid[first][1].url

    return list(valid[1] for valid in valid.values()), invalid, skipped


def convert_gtfs_datasets_to_download_configs(task_instance, execution_date, **kwargs):
    sentry_sdk.init()
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

    valid, invalid, skipped = gtfs_datasets_to_extract_configs(extract)

    msg = f"{len(extract.records)=} {len(valid)=} {len(skipped)=} {len(invalid)=}"  # noqa: E225
    print(msg)

    print("Invalid records:")
    for record, error in invalid:
        print(record.name, record.pipeline_url, error)

    print("Skipped records:")
    for record in skipped:
        print(record.name, record.pipeline_url)

    # TODO: we should probably be configuring these alerts via Grafana but we need Pushgateway for that

    invalid_threshold_pct = 0.05
    if len(invalid) / len(extract.records) > invalid_threshold_pct:
        raise RuntimeError(f"more than {invalid_threshold_pct}% invalid records")

    # should update this if we end up with lots of historical records
    # as of 2023-03-29 we're at 5%
    skipped_threshold_pct = 0.15
    if len(skipped) / len(extract.records) > skipped_threshold_pct:
        raise RuntimeError(f"more than {skipped_threshold_pct}% skipped records")

    jsonl_content = gzip.compress("\n".join(record.json() for record in valid).encode())
    GTFSDownloadConfigExtract(
        filename="configs.jsonl.gz",
        ts=extract.ts,
        records=valid,
    ).save_content(content=jsonl_content, fs=fs)


if __name__ == "__main__":
    convert_gtfs_datasets_to_download_configs(None, None)
