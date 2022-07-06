# ---
# python_callable: download_all
# provide_context: true
# ---
import cgi
import datetime
import logging
import traceback

import os

import humanize
import pandas as pd
import pendulum
import re
from airflow.models import Variable
from airflow.utils.db import create_session
from airflow.utils.email import send_email
from calitp.config import is_development
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
    DownloadFeedsResult,
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

    disposition_header = resp.headers.get(
        "content-disposition", resp.headers.get("Content-Disposition")
    )

    if disposition_header:
        if disposition_header.startswith("filename="):
            # sorry; cgi won't parse unless it's prefixed with the disposition type
            disposition_header = f"attachment; {disposition_header}"
        _, params = cgi.parse_header(disposition_header)
        disposition_filename = params.get("filename")
    else:
        disposition_filename = None

    filename = (
        disposition_filename
        or (os.path.basename(resp.url) if resp.url.endswith(".zip") else None)
        or "feed.zip"
    )

    extract = GTFSFeedExtractInfo(
        # TODO: handle this in pydantic?
        filename=filename.strip('"'),
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
    # https://stackoverflow.com/a/61808755
    with create_session() as session:
        auth_dict = {var.key: var.val for var in session.query(Variable)}

    records = [
        record
        for record in AirtableGTFSDataExtract.get_latest().records
        if record.data_quality_pipeline and record.data == GTFSFeedType.schedule
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

    print(
        f"took {humanize.naturaltime(pendulum.now() - start)} to process {len(records)} records"
    )

    assert len(records) == len(
        outcomes
    ), f"we somehow ended up with {len(outcomes)} outcomes from {len(records)} records"

    result = DownloadFeedsResult(
        start_time=start,
        end_time=pendulum.now(),
        outcomes=outcomes,
        filename="results.jsonl",
    )

    result.save(get_fs())

    print(f"successfully fetched {len(result.successes)} of {len(records)}")

    if result.failures:
        print(
            "Failures:",
            "\n".join(
                str(f.exception) or str(type(f.exception)) for f in result.failures
            ),
        )
        # use pandas begrudgingly for email HTML since the old task used it
        html_report = pd.DataFrame(f.dict() for f in result.failures).to_html(
            border=False
        )

        html_content = f"""\
    The following agency GTFS feeds could not be extracted on {start.to_iso8601_string()}:

    {html_report}
    """
    else:
        html_content = "All feeds were downloaded successfully!"

    if is_development():
        print(
            f"Skipping since in development mode! Would have emailed {len(result.failures)} failures."
        )
    else:
        send_email(
            to=[
                "aaron@trilliumtransit.com",
                "blake.f@jarv.us",
                "evan.siroky@dot.ca.gov",
                "hunter.owens@dot.ca.gov",
                "jameelah.y@jarv.us",
                "juliet@trilliumtransit.com",
                "olivia.ramacier@dot.ca.gov",
                "laurie.m@jarv.us",
                "andrew.v@jarv.us",
            ],
            html_content=html_content,
            subject=(
                f"Operator GTFS Errors for {datetime.datetime.now().strftime('%Y-%m-%d')}"
            ),
        )

    success_rate = len(result.successes) / len(records)
    if success_rate < GTFS_FEED_LIST_ERROR_THRESHOLD:
        raise RuntimeError(
            f"Success rate: {success_rate:.3f} was below error threshold: {GTFS_FEED_LIST_ERROR_THRESHOLD}"
        )


if __name__ == "__main__":
    download_all(None, pendulum.now())
