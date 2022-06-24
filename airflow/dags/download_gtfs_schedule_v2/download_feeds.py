# ---
# python_callable: download_all
# provide_context: true
# ---
import logging
import traceback

import os
import pendulum
import re
from airflow.models import Variable
from airflow.utils.db import create_session
from pydantic.networks import HttpUrl
from pydantic.tools import parse_obj_as
from requests import Session
from typing import List, Dict
from calitp.storage import get_fs
from utils import (
    AirtableGTFSDataExtract,
    AirtableGTFSDataRecord,
    AirtableGTFSDataRecordProcessingOutcome,
    GTFSFeedExtractInfo,
    GTFSFeedType,
)

GTFS_FEED_LIST_ERROR_THRESHOLD = 0.95


def download_feed(
    record: AirtableGTFSDataRecord, auth_dict: Dict
) -> AirtableGTFSDataRecordProcessingOutcome:
    if not record.uri:
        raise ValueError("")

    parse_obj_as(HttpUrl, record.uri)

    s = Session()
    r = s.prepare_request(record.build_request(auth_dict))
    resp = s.send(r)
    resp.raise_for_status()

    # we can try a few different locations for the filename
    disp1 = re.search('filename="(.+)"', resp.headers.get("content-disposition", ""))
    disp2 = re.search('filename="(.+)"', resp.headers.get("Content-Disposition", ""))

    filename = (
        (disp1.group(0) if disp1 else None)
        or (disp2.group(0) if disp1 else None)
        or (os.path.basename(resp.url) if resp.url.endswith(".zip") else None)
        or "feed.zip"
    )

    extract = GTFSFeedExtractInfo(
        filename=filename,
        config=record,
        response_code=resp.status_code,
        response_headers=resp.headers,
        download_time=pendulum.now(),
    )

    extract.save_content(fs=get_fs(), content=resp.content)

    return AirtableGTFSDataRecordProcessingOutcome(
        success=True,
        input_record=record,
        extract=extract,
    )


def download_all(task_instance, execution_date, **kwargs):
    start = pendulum.now()
    # TODO: use laurie's method for this
    # https://stackoverflow.com/a/61808755
    with create_session() as session:
        auth_dict = {var.key: var.val for var in session.query(Variable)}

    records = [
        record
        for record in AirtableGTFSDataExtract.get_latest().records
        if record.data == GTFSFeedType.schedule
    ]
    outcomes: List[AirtableGTFSDataRecordProcessingOutcome] = []

    logging.info(f"processing {len(records)} records")

    for i, record in enumerate(records, start=1):
        logging.info(f"attempting to fetch {i}/{len(records)} {record.uri}")

        try:
            # this is a bit hacky but we need this until we split off auth query params from the URI itself
            jinja_pattern = r"(?P<param_name>\w+)={{\s*(?P<param_lookup_key>\w+)\s*}}"
            match = re.search(jinja_pattern, record.uri)
            if match:
                record.auth_query_param = {
                    match.group("param_name"): match.group("param_lookup_key")
                }
                record.uri = re.sub(jinja_pattern, "", record.uri)
            outcomes.append(download_feed(record, auth_dict=auth_dict))
        except Exception as e:
            logging.error(
                f"exception occurred while attempting to download feed {record.uri}: {str(e)}\n{traceback.format_exc()}"
            )
            outcomes.append(
                AirtableGTFSDataRecordProcessingOutcome(
                    success=False,
                    exception=e,
                    input_record=record,
                )
            )

    # TODO: save the outcomes somewhere

    print(f"took {pendulum.now() - start} to process {len(records)} records")

    assert len(records) == len(
        outcomes
    ), f"we somehow ended up with {len(outcomes)} from {len(records)}"

    successes = len([outcome for outcome in outcomes if outcome.success])
    print(f"successfully fetched {successes} of {len(records)}")
    success_rate = successes / len(records)
    if success_rate < GTFS_FEED_LIST_ERROR_THRESHOLD:
        raise RuntimeError(
            f"Success rate: {success_rate:.3f} was below error threshold: {GTFS_FEED_LIST_ERROR_THRESHOLD}"
        )
